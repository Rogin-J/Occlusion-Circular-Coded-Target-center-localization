# -*- coding: utf-8 -*-
"""
基于真实树叶的CCT遮挡图像生成器 - 圆形区域定义

@author: DeepSeek
"""

import os
import argparse
import math
import random
import numpy as np
from PIL import Image, ImageDraw, ImageTk
import tkinter as tk
from tkinter import ttk
import json
import time
import glob
from tqdm import tqdm  # 导入进度条库
# === 可配置常量 ===
MAX_ITERATIONS = 500000  # 默认最大迭代次数
ERROR_THRESHOLD = 1.0  # 默认允许的最大误差百分比
DEFAULT_CIRCLE = [500, 500, 170]  # 默认中心区域 [圆心x, 圆心y, 半径]
LEAVES_DIR = "./leaves"  # 树叶图片目录


# 加载树叶图片
def load_leaves(leaves_dir):
    """加载所有树叶图片"""
    leaf_paths = glob.glob(os.path.join(leaves_dir, "*.png"))
    leaves = []
    for path in leaf_paths:
        try:
            img = Image.open(path).convert("RGBA")
            leaves.append(img)
            print(f"成功加载树叶: {os.path.basename(path)}")
        except Exception as e:
            print(f"无法加载树叶 {path}: {str(e)}")

    if not leaves:
        raise FileNotFoundError(f"在目录 {leaves_dir} 中未找到树叶图片")

    return leaves


# === 交互式圆形选择 ===
class CircleSelector:
    def __init__(self, image_path):
        self.root = tk.Tk()
        self.root.title("选择中心区域 - 拖动圆心并调整半径")

        # 加载图像
        self.img = Image.open(image_path)
        self.tk_img = ImageTk.PhotoImage(self.img)

        # 创建画布
        self.canvas = tk.Canvas(self.root, width=self.img.width, height=self.img.height)
        self.canvas.pack()
        self.canvas.create_image(0, 0, anchor=tk.NW, image=self.tk_img)

        # 初始化圆形
        self.center = None
        self.radius = None
        self.circle_id = None
        self.dragging = False

        # 绑定事件
        self.canvas.bind("<ButtonPress-1>", self.on_press)
        self.canvas.bind("<B1-Motion>", self.on_drag)
        self.canvas.bind("<ButtonRelease-1>", self.on_release)
        self.canvas.bind("<MouseWheel>", self.on_scroll)  # Windows
        self.canvas.bind("<Button-4>", self.on_scroll)  # Linux
        self.canvas.bind("<Button-5>", self.on_scroll)  # Linux

        # 提示标签
        self.label = ttk.Label(self.root, text="拖动圆心位置 | 滚轮调整半径 | 双击确认")
        self.label.pack(pady=10)

        # 确认按钮
        self.btn_frame = ttk.Frame(self.root)
        self.btn_frame.pack(pady=10)
        ttk.Button(self.btn_frame, text="确认选择", command=self.confirm).pack(side=tk.LEFT, padx=5)
        ttk.Button(self.btn_frame, text="使用默认", command=self.use_default).pack(side=tk.LEFT, padx=5)

        # 存储结果
        self.result = None

    def on_press(self, event):
        self.center = (event.x, event.y)
        self.radius = 50  # 默认半径
        self.update_circle()
        self.dragging = True

    def on_drag(self, event):
        if self.dragging and self.center:
            self.center = (event.x, event.y)
            self.update_circle()

    def on_release(self, event):
        self.dragging = False

    def on_scroll(self, event):
        if not self.center:
            return

        # 计算滚动方向
        delta = 0
        if event.num == 5 or (hasattr(event, 'delta') and event.delta < 0):  # 向下滚动
            delta = -10
        elif event.num == 4 or (hasattr(event, 'delta') and event.delta > 0):  # 向上滚动
            delta = 10

        # 更新半径
        self.radius = max(10, self.radius + delta)
        self.update_circle()

    def update_circle(self):
        if self.circle_id:
            self.canvas.delete(self.circle_id)

        if self.center and self.radius:
            x, y = self.center
            self.circle_id = self.canvas.create_oval(
                x - self.radius, y - self.radius,
                x + self.radius, y + self.radius,
                outline="red", width=2
            )

    def confirm(self):
        if self.center and self.radius:
            self.result = [self.center[0], self.center[1], self.radius]
            self.root.destroy()

    def use_default(self):
        self.result = DEFAULT_CIRCLE.copy()
        self.root.destroy()

    def get_circle(self):
        self.root.mainloop()
        return self.result


# === 精确CCT绘制函数 ===
def create_cct_base(size=1000):
    """创建1911号CCT基础图像"""
    # 创建黑色背景
    img = Image.new('L', (size, size), 0)
    draw = ImageDraw.Draw(img)
    center = (size // 2, size // 2)

    # 定义几何参数
    outer_radius = size * 0.375
    inner_radius = size * 0.25
    center_radius = size * 0.125

    # 绘制编码带 (111011101110)
    unit_angle = 30  # 360/12
    white_sectors = [0, 1, 2, 4, 5, 6, 8, 9, 10]  # 111011101110对应的白色扇区

    for i in white_sectors:
        start_angle = i * unit_angle
        end_angle = (i + 1) * unit_angle
        draw.pieslice(
            [center[0] - outer_radius, center[1] - outer_radius,
             center[0] + outer_radius, center[1] + outer_radius],
            start_angle, end_angle, fill=255
        )

    # 绘制内圆 (黑色)
    draw.ellipse(
        [center[0] - inner_radius, center[1] - inner_radius,
         center[0] + inner_radius, center[1] + inner_radius],
        fill=0
    )

    # 绘制中心白色圆
    draw.ellipse(
        [center[0] - center_radius, center[1] - center_radius,
         center[0] + center_radius, center[1] + center_radius],
        fill=255
    )

    return img


# === 遮挡率计算函数 ===
def calculate_occlusion_rate(base_img, occ_img, circle_pos):
    """计算遮挡率 - 基于圆形区域定义"""
    # 转换为numpy数组
    base_arr = np.array(base_img)
    occ_arr = np.array(occ_img.convert('L'))  # 转换为灰度计算遮挡

    # 创建圆形掩膜
    cx, cy, r = circle_pos
    y, x = np.ogrid[:base_arr.shape[0], :base_arr.shape[1]]
    mask_center = (x - cx) ** 2 + (y - cy) ** 2 <= r ** 2
    mask_ring = ~mask_center

    # 二值化 (使用128作为阈值)
    bw_ref = (base_arr > 128).astype(np.uint8) * 255
    bw_occ = (occ_arr > 128).astype(np.uint8) * 255

    # 计算中心区域遮挡
    center_white_total = np.sum(bw_ref[mask_center] == 255)
    center_white_occ = np.sum(bw_occ[mask_center] == 255)
    center_occluded = center_white_total - center_white_occ
    center_ratio = center_occluded / center_white_total * 100 if center_white_total > 0 else 0

    # 计算编码带遮挡
    ring_white_total = np.sum(bw_ref[mask_ring] == 255)
    ring_white_occ = np.sum(bw_occ[mask_ring] == 255)
    ring_occluded = ring_white_total - ring_white_occ
    ring_ratio = ring_occluded / ring_white_total * 100 if ring_white_total > 0 else 0

    return center_ratio, ring_ratio


# === 区域检查函数 ===
def is_leaf_in_target_region(leaf_img, position, circle_pos, is_center):
    """检查树叶是否完全位于目标区域内"""
    cx, cy, r = circle_pos
    leaf_width, leaf_height = leaf_img.size
    leaf_x, leaf_y = position

    # 获取树叶的四个角点
    corners = [
        (leaf_x, leaf_y),
        (leaf_x + leaf_width, leaf_y),
        (leaf_x + leaf_width, leaf_y + leaf_height),
        (leaf_x, leaf_y + leaf_height)
    ]

    for px, py in corners:
        # 计算点到圆心的距离
        distance = math.sqrt((px - cx) ** 2 + (py - cy) ** 2)

        if is_center:  # 对于中心区域，要求所有点都在圆内
            if distance > r:
                return False
        else:  # 对于编码带区域，要求所有点都在圆外
            if distance <= r:
                return False

    return True


# === 应用树叶遮挡 ===
# === 应用树叶遮挡 ===
def apply_leaf_occlusion(base_img, circle_pos, leaves, center_occ=0, band_occ=0,
                         max_iterations=MAX_ITERATIONS, error_threshold=ERROR_THRESHOLD):
    """应用真实树叶精确遮挡 - 分参数独立穷举优化"""
    # 转换为RGB模式以支持彩色树叶
    if base_img.mode != 'RGB':
        base_rgb = base_img.convert('RGB')
    else:
        base_rgb = base_img.copy()

    img = base_rgb.copy()
    size = base_img.size[0]
    cx, cy, r = circle_pos

    # 计算区域内的白色像素总数
    base_arr = np.array(base_img)
    y_grid, x_grid = np.ogrid[:base_img.size[1], :base_img.size[0]]
    mask_center = (x_grid - cx) ** 2 + (y_grid - cy) ** 2 <= r ** 2
    mask_ring = ~mask_center

    center_white_total = np.sum((base_arr > 128) & mask_center)
    ring_white_total = np.sum((base_arr > 128) & mask_ring)

    # 遮挡结果图像 - 使用同一个occ_img变量
    occ_img = img.copy()

    def calculate_occlusion(leaf_img, position, angle, scale_factor, is_center):
        """计算给定参数的遮挡率"""
        # 调整树叶大小
        orig_width, orig_height = leaf_img.size
        new_width = int(orig_width * scale_factor)
        new_height = int(orig_height * scale_factor)

        if new_width == 0 or new_height == 0:
            return 0.0

        scaled_leaf = leaf_img.resize((new_width, new_height), Image.LANCZOS)

        # 旋转树叶
        rotated_leaf = scaled_leaf.rotate(angle, expand=True)
        leaf_width, leaf_height = rotated_leaf.size

        # 计算位置（确保中心点不变）
        leaf_center_x, leaf_center_y = position
        leaf_x = int(leaf_center_x - leaf_width / 2)
        leaf_y = int(leaf_center_y - leaf_height / 2)
        position_adj = (leaf_x, leaf_y)

        # 创建临时图像
        temp_img = occ_img.copy()  # 使用当前遮挡结果作为基础
        temp_img.paste(rotated_leaf, position_adj, rotated_leaf)
        temp_gray = temp_img.convert('L')
        temp_arr = np.array(temp_gray)

        # 计算遮挡率
        if is_center:
            occluded = np.sum((base_arr > 128) & (temp_arr <= 128) & mask_center)
            total = center_white_total
        else:
            occluded = np.sum((base_arr > 128) & (temp_arr <= 128) & mask_ring)
            total = ring_white_total

        return occluded / total * 100.0 if total > 0 else 0.0

    # === 中心区域遮挡 ===
    # === 中心区域遮挡 ===
    # === 中心区域遮挡 ===
    if center_occ > 0:
        start_time = time.time()

        # 最大重试次数
        max_retries = 5
        retry_count = 0
        applied = False

        while retry_count < max_retries and not applied:
            best_global = None
            min_global_error = float('inf')

            # 对每片树叶进行优化
            for leaf_idx, leaf_img in enumerate(leaves):
                # 复制树叶，避免修改原始
                leaf_img = leaf_img.copy()

                # 阶段1: 随机初始位置和角度
                while True:
                    # 随机位置角度和距离
                    pos_angle = random.uniform(0, 2 * math.pi)
                    distance = random.uniform(0, r * 0.8)
                    leaf_center_x = cx + distance * math.cos(pos_angle)
                    leaf_center_y = cy + distance * math.sin(pos_angle)
                    position = (leaf_center_x, leaf_center_y)
                    if (leaf_center_x - cx) ** 2 + (leaf_center_y - cy) ** 2 <= r ** 2:
                        break

                initial_angle = random.uniform(0, 360)

                # 阶段2: 优化缩放比例 (1%到200%，步长0.01%)
                best_scale = 1.0
                best_scale_occ = 0.0
                min_scale_error = float('inf')
                scales = np.arange(0.01, 2.5, 0.0001)  # 1%到200%，步长0.01%
                pbar = tqdm(total=36000+25000, desc=f"中心区域遮挡")
                for scale in scales:
                    occ_ratio = calculate_occlusion(leaf_img, position, initial_angle, scale, True)
                    error = abs(occ_ratio - center_occ)
                    if error < min_scale_error:
                        min_scale_error = error
                        best_scale = scale
                        best_scale_occ = occ_ratio

                    pbar.update(1)

                # 阶段3: 优化旋转角度 (0-360度，步长0.01度)
                best_angle = initial_angle
                best_angle_occ = best_scale_occ
                min_angle_error = min_scale_error
                angles = np.arange(0, 360.0, 0.01)  # 0-360度，步长0.01度
                for angle in angles:
                    occ_ratio = calculate_occlusion(leaf_img, position, angle, best_scale, True)
                    error = abs(occ_ratio - center_occ)
                    if error < min_angle_error:
                        min_angle_error = error
                        best_angle = angle
                        best_angle_occ = occ_ratio
                    pbar.update(1)
                # 阶段4: 优化位置距离 (0到R，步长R/100)
                best_distance = distance
                best_pos_occ = best_angle_occ
                min_pos_error = min_angle_error
                distances = np.linspace(0, r * 0.8, 101)  # 101个点，包括0和r*0.8
                for dist in distances:
                    # 沿原方向
                    new_x = cx + dist * math.cos(pos_angle)
                    new_y = cy + dist * math.sin(pos_angle)
                    new_position = (new_x, new_y)
                    occ_ratio = calculate_occlusion(leaf_img, new_position, best_angle, best_scale, True)
                    error = abs(occ_ratio - center_occ)
                    if error < min_pos_error:
                        min_pos_error = error
                        best_distance = dist
                        best_pos_occ = occ_ratio
                    pbar.update(1)
                pbar.close()
                # 计算最佳位置
                best_position = (
                    cx + best_distance * math.cos(pos_angle),
                    cy + best_distance * math.sin(pos_angle)
                )

                # 更新全局最佳
                if min_pos_error < min_global_error:
                    min_global_error = min_pos_error
                    best_global = {
                        'leaf': leaf_img,
                        'position': best_position,
                        'angle': best_angle,
                        'scale': best_scale,
                        'occ_ratio': best_pos_occ
                    }

                # 如果全局误差已经很小，提前结束
                if min_global_error <= error_threshold:
                    break

            # 应用最佳结果
            if best_global:
                leaf_img = best_global['leaf']
                position = best_global['position']
                angle = best_global['angle']
                scale_factor = best_global['scale']

                orig_width, orig_height = leaf_img.size
                new_width = int(orig_width * scale_factor)
                new_height = int(orig_height * scale_factor)
                scaled_leaf = leaf_img.resize((new_width, new_height), Image.LANCZOS)
                rotated_leaf = scaled_leaf.rotate(angle, expand=True)
                leaf_width, leaf_height = rotated_leaf.size
                leaf_x = int(position[0] - leaf_width / 2)
                leaf_y = int(position[1] - leaf_height / 2)
                position_final = (leaf_x, leaf_y)

                # 创建临时副本用于检查编码带遮挡
                temp_check = occ_img.copy()
                temp_check.paste(rotated_leaf, position_final, rotated_leaf)

                # 检查编码带是否被遮挡
                _, ring_ratio = calculate_occlusion_rate(base_img, temp_check, circle_pos)
                if ring_ratio > 0.5:  # 编码带被遮挡超过0.5%
                    print(f"中心遮挡: 编码带被遮挡({ring_ratio:.2f}%)，重试 {retry_count + 1}/{max_retries}")
                    retry_count += 1
                    continue  # 继续重试
                else:
                    # 应用树叶到最终图像
                    occ_img.paste(rotated_leaf, position_final, rotated_leaf)

                    # 计算实际遮挡率
                    center_ratio, ring_ratio = calculate_occlusion_rate(base_img, occ_img, circle_pos)
                    error = abs(center_ratio - center_occ)

                    elapsed = time.time() - start_time
                    print(
                        f"中心遮挡: 设定={center_occ}% 实际={center_ratio:.2f}% 误差={error:.2f}% | 时间={elapsed:.1f}s | 树叶={leaf_idx + 1}")
                    applied = True
                    break  # 成功应用，跳出重试循环
            else:
                print(f"中心遮挡: 未找到合适遮挡物")
                break  # 没有找到合适树叶，跳出重试循环

        if not applied:
            print(f"中心遮挡: 达到最大重试次数({max_retries})，无法找到不遮挡编码带的树叶")


    # === 编码带遮挡 ===
    # === 编码带遮挡 ===
    if band_occ > 0:
        start_time = time.time()
        # 使用相同的occ_img图像，而不是创建新的临时图像
        temp_img = occ_img.copy()  # 使用当前遮挡结果作为基础

        # 计算当前的中心遮挡率（用于区分新旧遮挡）
        current_center_ratio, _ = calculate_occlusion_rate(base_img, temp_img, circle_pos)
        current_ring_ratio = 0  # 初始化当前编码带遮挡率

        # 根据遮挡率确定树叶数量
        if band_occ <= 30:
            num_leaves = 1
        elif band_occ <= 60:
            num_leaves = 2
        else:  # 75%,90%,100%使用3片树叶
            num_leaves = 3

        print(f"编码带遮挡 {band_occ}%: 使用 {num_leaves} 片树叶")

        # 定义编码带的三个白色扇环区域（实际编码带区域）
        sector_angles = [
            (0, 90),  # 第一个扇区
            (120, 210),  # 第二个扇区
            (240, 330)  # 第三个扇区
        ]

        # 固定距离：编码带中间位置
        mid_radius = (0.25 * size + 0.375 * size) / 2
        # mid_radius = 0.375 * size

        # 遍历每片树叶
        for leaf_num in range(num_leaves):
            # 选择当前树叶的扇区
            sector_idx = leaf_num % 3
            sector_start, sector_end = sector_angles[sector_idx]

            # 计算扇区中心角度
            sector_center_angle = (sector_start + sector_end) / 2

            # 固定位置：扇区中心点
            pos_angle = math.radians(sector_center_angle)
            position = (
                size // 2 + mid_radius * math.cos(pos_angle),
                size // 2 + mid_radius * math.sin(pos_angle)
            )

            best_leaf = None
            best_angle = 0
            best_scale = 1.0
            min_error = float('inf')

            # 为每片树叶创建进度条
            max_iterations = 36000 + 19900  # 角度步数 + 缩放步数
            pbar = tqdm(total=max_iterations, desc=f"编码带遮挡({band_occ}%) - 树叶{leaf_num + 1}")

            # 优化角度
            best_angle_temp = 0
            min_angle_error = float('inf')
            for angle in np.arange(0, 360, 0.01):
                # 计算当前角度下的遮挡率
                occ_ratio = calculate_occlusion(leaves[0], position, angle, 1.0, False)
                # 目标增量 = (总目标 - 当前累计) / 剩余树叶数
                target_increment = (band_occ - current_ring_ratio) / (num_leaves - leaf_num)
                error = abs(occ_ratio - target_increment)

                if error < min_angle_error:
                    min_angle_error = error
                    best_angle_temp = angle

                pbar.update(1)

            # 优化缩放比例
            best_scale_temp = 1.0
            min_scale_error = float('inf')
            for scale in np.arange(0.01, 3, 0.001):
                # 计算当前缩放比例下的遮挡率
                occ_ratio = calculate_occlusion(leaves[0], position, best_angle_temp, scale, False)
                # 目标增量 = (总目标 - 当前累计) / 剩余树叶数
                target_increment = (band_occ - current_ring_ratio) / (num_leaves - leaf_num)
                error = abs(occ_ratio - target_increment)

                if error < min_scale_error:
                    min_scale_error = error
                    best_scale_temp = scale

                pbar.update(1)

            pbar.close()

            # 应用最佳参数
            leaf_img = leaves[0].copy()
            position_fixed = position
            angle_fixed = best_angle_temp
            scale_fixed = best_scale_temp

            # 调整大小和旋转
            orig_width, orig_height = leaf_img.size
            new_width = int(orig_width * scale_fixed)
            new_height = int(orig_height * scale_fixed)
            scaled_leaf = leaf_img.resize((new_width, new_height), Image.LANCZOS)
            rotated_leaf = scaled_leaf.rotate(angle_fixed, expand=True)
            leaf_width, leaf_height = rotated_leaf.size
            leaf_x = int(position_fixed[0] - leaf_width / 2)
            leaf_y = int(position_fixed[1] - leaf_height / 2)
            position_final = (leaf_x, leaf_y)

            # 创建临时副本用于检查中心遮挡
            temp_check = temp_img.copy()
            temp_check.paste(rotated_leaf, position_final, rotated_leaf)

            # 检查中心区域是否被遮挡（只关心新增遮挡）
            new_center_ratio, _ = calculate_occlusion_rate(base_img, temp_check, circle_pos)
            center_change = abs(new_center_ratio - current_center_ratio)

            # 修改：允许中心区域已有遮挡，只关心新增遮挡
            if center_change > 1:  # 中心区域新增遮挡超过0.5%
                print(f"  树叶 {leaf_num + 1}: 中心区域新增遮挡({center_change:.2f}%)，跳过该树叶")
                # 跳过该树叶，不添加到图像中
                continue

            # 应用到临时图像
            temp_img.paste(rotated_leaf, position_final, rotated_leaf)

            # 计算当前累计遮挡率
            _, new_ring_ratio = calculate_occlusion_rate(base_img, temp_img, circle_pos)
            ring_increment = new_ring_ratio - current_ring_ratio
            current_ring_ratio = new_ring_ratio

            print(f"  树叶 {leaf_num + 1} (扇区 {sector_idx + 1}): "
                  f"角度={angle_fixed:.2f}°, 缩放={scale_fixed:.4f} "
                  f"遮挡增量={ring_increment:.2f}% 累计={current_ring_ratio:.2f}%")

        # 更新最终图像
        occ_img = temp_img.copy()

        # 计算最终遮挡率
        center_ratio, ring_ratio = calculate_occlusion_rate(base_img, occ_img, circle_pos)
        error = abs(ring_ratio - band_occ)

        elapsed = time.time() - start_time
        print(f"编码带遮挡完成: 设定={band_occ}% 实际={ring_ratio:.2f}% 误差={error:.2f}% | 总耗时={elapsed:.1f}s")
    else:
        print("编码带遮挡: 0% - 无需添加遮挡")

    return occ_img

# === 图像生成主函数 ===
# === 图像生成主函数 ===
def generate_occluded_images(size, output_dir, leaves, circle_pos=None,
                             max_iterations=MAX_ITERATIONS, error_threshold=ERROR_THRESHOLD,
                             scenarios="all",
                             center_occlusions="all",
                             band_occlusions="all",
                             orth_pairs="all"):
    """生成指定遮挡工况的图像
    scenarios: 选择要生成的工况类型 ("center", "band", "orth", "all")
    center_occlusions: 中心遮挡率列表 (如 [0, 15, 30] 或 "all")
    band_occlusions: 编码带遮挡率列表 (如 [0, 15, 30] 或 "all")
    orth_pairs: 正交组合列表 (如 [(15,15), (15,45)] 或 "all")
    """
    # 确保输出目录存在
    os.makedirs(output_dir, exist_ok=True)

    # 创建基础图像（只保存一次）
    base_img = create_cct_base(size)
    base_path = os.path.join(output_dir, 'base_reference.png')
    base_img.save(base_path)
    print(f"基础参考图像已保存至: {base_path}")

    # 如果没有提供圆形位置，则启动交互式选择
    if circle_pos is None:
        # 保存临时基础图像用于选择
        temp_base_path = os.path.join(output_dir, 'temp_base.png')
        base_img.save(temp_base_path)

        # 启动交互式选择
        selector = CircleSelector(temp_base_path)
        circle_pos = selector.get_circle()

        # 删除临时文件
        os.remove(temp_base_path)

        if circle_pos is None:
            print("未选择区域，使用默认圆形")
            circle_pos = DEFAULT_CIRCLE.copy()

    print(f"使用圆形区域: 圆心({circle_pos[0]}, {circle_pos[1]}), 半径={circle_pos[2]}")
    print(f"配置参数: 最大迭代次数={max_iterations}, 误差阈值={error_threshold}%")

    # 保存圆形位置
    with open(os.path.join(output_dir, 'mask_coords.json'), 'w') as f:
        json.dump({'circle_pos': circle_pos}, f)

    results = []
    total_start = time.time()

    # 1. 仅中心圆遮挡
    if scenarios in ["all", "center"]:
        center_start = time.time()
        occ_list = center_occlusions if center_occlusions != "all" else [0, 15, 30, 45, 60, 75, 90, 100]

        for occ in occ_list:
            name = f"center_occ_{occ}"
            occ_path = os.path.join(output_dir, f"{name}.png")

            # 创建遮挡图像
            start_time = time.time()
            occ_img = apply_leaf_occlusion(
                base_img, circle_pos, leaves, occ, 0,
                max_iterations, error_threshold
            )
            elapsed = time.time() - start_time

            # 保存图像
            occ_img.save(occ_path)

            # 计算实际遮挡率
            center_ratio, ring_ratio = calculate_occlusion_rate(base_img, occ_img, circle_pos)
            results.append(('center', occ, center_ratio, ring_ratio))

            print(
                f"中心遮挡 {occ}% -> 实际中心: {center_ratio:.2f}% | 实际编码带: {ring_ratio:.2f}% | 耗时: {elapsed:.2f}s")

        print(f"中心遮挡完成! 总耗时: {time.time() - center_start:.2f}s\n")

    # 2. 仅编码带遮挡
    if scenarios in ["all", "band"]:
        band_start = time.time()
        occ_list = band_occlusions if band_occlusions != "all" else [0, 15, 30, 45, 60, 75, 90, 100]

        for occ in occ_list:
            name = f"band_occ_{occ}"
            occ_path = os.path.join(output_dir, f"{name}.png")

            # 创建遮挡图像
            start_time = time.time()
            occ_img = apply_leaf_occlusion(
                base_img, circle_pos, leaves, 0, occ,
                max_iterations, error_threshold
            )
            elapsed = time.time() - start_time

            # 保存图像
            occ_img.save(occ_path)

            # 计算实际遮挡率
            center_ratio, ring_ratio = calculate_occlusion_rate(base_img, occ_img, circle_pos)
            results.append(('band', occ, center_ratio, ring_ratio))

            print(
                f"编码带遮挡 {occ}% -> 实际中心: {center_ratio:.2f}% | 实际编码带: {ring_ratio:.2f}% | 耗时: {elapsed:.2f}s")

        print(f"编码带遮挡完成! 总耗时: {time.time() - band_start:.2f}s\n")

    # 3. 正交试验组合
    if scenarios in ["all", "orth"]:
        orth_start = time.time()
        pairs = orth_pairs if orth_pairs != "all" else [
            (15, 15), (15, 45), (15, 75),
            (45, 15), (45, 45), (45, 75),
            (75, 15), (75, 45), (75, 75)
        ]

        for i, (center_occ, band_occ) in enumerate(pairs):
            name = f"orthogonal_{i + 1}_center_{center_occ}_band_{band_occ}"
            occ_path = os.path.join(output_dir, f"{name}.png")

            # 创建遮挡图像
            start_time = time.time()
            occ_img = apply_leaf_occlusion(
                base_img, circle_pos, leaves, center_occ, band_occ,
                max_iterations, error_threshold
            )
            elapsed = time.time() - start_time

            # 保存图像
            occ_img.save(occ_path)

            # 计算实际遮挡率
            center_ratio, ring_ratio = calculate_occlusion_rate(base_img, occ_img, circle_pos)
            results.append(('orth', center_occ, band_occ, center_ratio, ring_ratio))

            print(
                f"正交组合 {i + 1}: 中心设定={center_occ}% 实际={center_ratio:.2f}% | 编码带设定={band_occ}% 实际={ring_ratio:.2f}% | 耗时: {elapsed:.2f}s")

        print(f"正交组合完成! 总耗时: {time.time() - orth_start:.2f}s\n")

    # 保存结果报告
    if results:  # 只有生成图像时才保存报告
        report_path = os.path.join(output_dir, 'occlusion_report.txt')
        with open(report_path, 'w') as f:
            f.write("遮挡率测试报告\n")
            f.write("=" * 50 + "\n")
            f.write(f"总耗时: {time.time() - total_start:.2f}秒\n")
            f.write(f"圆形区域: 圆心({circle_pos[0]}, {circle_pos[1]}), 半径={circle_pos[2]}\n")
            f.write(f"配置参数: 最大迭代次数={max_iterations}, 误差阈值={error_threshold}%\n\n")

            if scenarios in ["all", "center"]:
                f.write("中心遮挡测试:\n")
                for r in results:
                    if r[0] == 'center':
                        f.write(f"设定: {r[1]}% -> 实际: {r[2]:.2f}% | 误差: {abs(r[1] - r[2]):.2f}%\n")

            if scenarios in ["all", "band"]:
                f.write("\n编码带遮挡测试:\n")
                for r in results:
                    if r[0] == 'band':
                        f.write(f"设定: {r[1]}% -> 实际: {r[3]:.2f}% | 误差: {abs(r[1] - r[3]):.2f}%\n")

            if scenarios in ["all", "orth"]:
                f.write("\n正交组合测试:\n")
                for r in results:
                    if r[0] == 'orth':
                        f.write(f"组合 {r[1]},{r[2]}: 中心({r[3]:.2f}%) | 编码带({r[4]:.2f}%)\n")

        print("=" * 50)
        print(f"所有图像生成完成! 总耗时: {time.time() - total_start:.2f}秒")
        print(f"结果报告已保存至: {report_path}")
        print(f"掩模坐标已保存至: {os.path.join(output_dir, 'mask_coords.json')}")
    else:
        print("未生成任何图像，请检查工况选择设置")


# === 主程序 ===
# === 主程序 ===
if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='基于真实树叶的CCT遮挡图像生成器')
    parser.add_argument('--size', type=int, default=1000, help='图像尺寸')
    parser.add_argument('--output', type=str, default='./leaf_occlusions', help='输出目录')
    parser.add_argument('--leaves', type=str, default=LEAVES_DIR, help='树叶图片目录')
    parser.add_argument('--circle', type=str, help='圆形坐标 [圆心x,圆心y,半径] (可选)')
    parser.add_argument('--max_iter', type=int, default=MAX_ITERATIONS, help='最大迭代次数')
    parser.add_argument('--error_threshold', type=float, default=ERROR_THRESHOLD, help='允许的最大误差百分比')

    # 添加工况选择参数
    parser.add_argument('--scenarios', type=str, default='all',
                        help='选择要生成的工况类型 (all, center, band, orth)')
    parser.add_argument('--center_occlusions', type=str, default='all',
                        help='中心遮挡率列表 (如 "0,15,30" 或 "all")')
    parser.add_argument('--band_occlusions', type=str, default='all',
                        help='编码带遮挡率列表 (如 "0,15,30" 或 "all")')
    parser.add_argument('--orth_pairs', type=str, default='all',
                        help='正交组合列表 (如 "15,15;15,45" 或 "all")')

    args = parser.parse_args()

    # 加载树叶图片
    try:
        leaves = load_leaves(args.leaves)
        print(f"成功加载 {len(leaves)} 张树叶图片")
    except Exception as e:
        print(f"树叶加载失败: {str(e)}")
        exit(1)

    # 解析圆形坐标
    circle_pos = None
    if args.circle:
        try:
            circle_pos = [int(x) for x in args.circle.split(',')]
            if len(circle_pos) != 3:
                raise ValueError
        except:
            print("警告: 无效的圆形坐标，使用交互式选择")
            circle_pos = None

    # 解析工况参数
    # 中心遮挡率
    if args.center_occlusions == 'all':
        center_occlusions = 'all'
    else:
        center_occlusions = [int(x) for x in args.center_occlusions.split(',')]

    # 编码带遮挡率
    if args.band_occlusions == 'all':
        band_occlusions = 'all'
    else:
        band_occlusions = [int(x) for x in args.band_occlusions.split(',')]

    # 正交组合
    if args.orth_pairs == 'all':
        orth_pairs = 'all'
    else:
        pairs = []
        for pair_str in args.orth_pairs.split(';'):
            parts = pair_str.split(',')
            if len(parts) == 2:
                pairs.append((int(parts[0]), int(parts[1])))
        orth_pairs = pairs

    print(f"开始生成精确树叶遮挡图像 (尺寸: {args.size}px)")
    print(f"配置参数: 最大迭代次数={args.max_iter}, 误差阈值={args.error_threshold}%")
    print(f"工况选择: scenarios={args.scenarios}, center_occlusions={center_occlusions}, "
          f"band_occlusions={band_occlusions}, orth_pairs={orth_pairs}")
    print("=" * 50)

    generate_occluded_images(
        args.size,
        args.output,
        leaves,
        circle_pos,
        max_iterations=args.max_iter,
        error_threshold=args.error_threshold,
        scenarios=args.scenarios,
        center_occlusions=center_occlusions,
        band_occlusions=band_occlusions,
        orth_pairs=orth_pairs
    )