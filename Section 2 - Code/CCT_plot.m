clc; clear; close all;

% === 控制参数 ===
N_circle = 80;         % 中心圆点数
N_inner = 25;          % 每块扇形内环点数（更稀疏）
N_outer = 40;          % 每块扇形外环点数（更密集）
num_sectors = 6;       % 编码带总扇形数
sector_kept = [1 3 5]; % 保留哪些扇形（编号）

% === 实际比例半径 ===
r_c = 50;
r_in = r_c * (143.94 / 72.32);     % ≈ 99.48
r_out = r_c * (215.23 / 72.32);    % ≈ 148.79

% === 中心圆 ===
theta_c = linspace(0, 2*pi, N_circle + 1); %theta_c(end) = [];
circle_pts = [r_c * cos(theta_c)', r_c * sin(theta_c)'];

% === 初始化存储变量 ===
sector_contours = {};  % 每块扇形的闭合点序列

% === 生成扇形轮廓 ===
theta_sectors = linspace(0, 2*pi, num_sectors + 1);

for k = sector_kept
    % 角度范围
    t1 = theta_sectors(k);
    t2 = theta_sectors(k+1);

    % 内外角度数量不同（错开轮廓线）
    theta_in = linspace(t1, t2, N_inner);
    theta_out = linspace(t2, t1, N_outer);  % 反向连接

    % 内外边界点
    inner = [r_in * cos(theta_in)', r_in * sin(theta_in)'];
    outer = [r_out * cos(theta_out)', r_out * sin(theta_out)'];

    % 拼接闭合路径（顺时针）：内 → 外 → 回起点
    contour = [inner; outer; inner(1,:)];
    sector_contours{end+1} = contour;
end

%% -----------------------
% =======================
% === 图2：交互式选点连线图 ===
% =======================
figure; hold on; axis equal;
set(gcf, 'Color', 'w');

% 重新绘制轮廓结构（与图1一致）
plot(circle_pts(:,1), circle_pts(:,2), 'b-', 'LineWidth', 1.5);
for i = 1:length(sector_contours)
    contour = sector_contours{i};
    plot(contour(:,1), contour(:,2), 'b-', 'LineWidth', 1.5);
end
xlabel('线段编号（排序后）');
ylabel('线段长度');


title('图2：点击任意点并连接至所有轮廓点');
% axis off;

% === 点击一个点 ===
disp('请在图中点击一个点...');
[x_click, y_click] = ginput(1);
plot(x_click, y_click, 'r*', 'MarkerSize', 10, 'LineWidth', 1.5);
% x_click=0;
% y_click=0;
% === 连线到所有点（圆 + 编码带内外）===
% --- 1. 中心圆 ---
for i = 1:size(circle_pts,1)
    plot([x_click, circle_pts(i,1)], [y_click, circle_pts(i,2)], 'Color', [0.2 0.6 1], 'LineWidth', 0.5);
end
% --- 2. 扇形轮廓 ---
for i = 1:length(sector_contours)
    contour = sector_contours{i};
    % 拆分出内环和外环的点数量
    inner = contour(1:N_inner, :);
    outer = contour(N_inner+1:N_inner+N_outer, :);
    % 绘制轮廓线（封闭）
    plot(contour(:,1), contour(:,2), 'b-', 'LineWidth', 1.5);
    % --- 外环绘制（黑色） ---
    for j = 1:size(outer,1)
        plot([x_click, outer(j,1)], [y_click, outer(j,2)], 'Color', [0.2 0.2 0.2], 'LineWidth', 0.4);
    end
    % --- 内环绘制（红色） ---
    for j = 1:size(inner,1)
        plot([x_click, inner(j,1)], [y_click, inner(j,2)], 'Color', [1 0.4 0.4], 'LineWidth', 0.4);
    end
end

%% -----------------------
% === 收集点分类数据 ===
num_c = size(circle_pts,1);
all_inner = [];
all_outer = [];

for i = 1:length(sector_contours)
    contour = sector_contours{i};
    inner = contour(1:N_inner, :);
    outer = contour(N_inner+1:N_inner+N_outer, :);
    all_inner = [all_inner; inner];
    all_outer = [all_outer; outer];
end

num_i = size(all_inner, 1);
num_o = size(all_outer, 1);

% === 距离计算 ===
lengths_c = sqrt((circle_pts(:,1) - x_click).^2 + (circle_pts(:,2) - y_click).^2);
lengths_i = sqrt((all_inner(:,1) - x_click).^2 + (all_inner(:,2) - y_click).^2);
lengths_o = sqrt((all_outer(:,1) - x_click).^2 + (all_outer(:,2) - y_click).^2);

% === 图3：按类别绘制排序图 ===
[~, idx_c] = sort(lengths_c);
[~, idx_i] = sort(lengths_i);
[~, idx_o] = sort(lengths_o);

figure;
plot(1:num_c, lengths_c(idx_c), 'b.-', 'LineWidth', 1.2, 'MarkerSize', 10); hold on;
plot(num_c+(1:num_i), lengths_i(idx_i), 'r.-', 'LineWidth', 1.2, 'MarkerSize', 10);
plot(num_c+num_i+(1:num_o), lengths_o(idx_o), 'k.-', 'LineWidth', 1.2, 'MarkerSize', 10);
xlabel('线段编号（排序后）');
ylabel('线段长度');
title('图3：按轮廓分类的连线长度排序图');
legend('中心圆', '编码带内环', '编码带外环');
grid on;

% === 图4：多类线段的扫描线直方图 ===
delta = 1.0;

% 中心圆
edges_c = min(lengths_c):delta:max(lengths_c);
count_c = histcounts(lengths_c, edges_c);

% 内环
edges_i = min(lengths_i):delta:max(lengths_i);
count_i = histcounts(lengths_i, edges_i);

% 外环
edges_o = min(lengths_o):delta:max(lengths_o);
count_o = histcounts(lengths_o, edges_o);

% 合并统一横轴（取全体边界）
edges = min([lengths_c; lengths_i; lengths_o]):delta:max([lengths_c; lengths_i; lengths_o]);
centers = edges(1:end-1) + delta/2;

% 重新计算统一 bin 下的频数
count_c = histcounts(lengths_c, edges);
count_i = histcounts(lengths_i, edges);
count_o = histcounts(lengths_o, edges);

% 绘图
figure;
bar(centers, [count_c; count_i; count_o]', 1, 'stacked');
xlabel('半径长度区间中心');
ylabel('线段数量');
title('图4：各类线段的径向距离分布直方图');
legend('中心圆', '编码带内环', '编码带外环');
grid on;
