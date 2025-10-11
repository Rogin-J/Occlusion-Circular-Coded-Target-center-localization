clc;clear;close all;
tic
load contours-paper2-703-vid.mat
load central_contour-paper2_703-vid.mat
% load central_contour-paper2_703-vid.mat
threshold = 0.5; % 设定相近距离的阈值
top_k=2;
wait_hand = waitbar(0,'Runing……', 'tag', 'TMWWaitbar');
for ii=1:size(contours,1)
    waitbar(ii/size(contours,1),wait_hand);
    for i=1:3 %CCCT标签数
        % 提取轮廓数据
        contour_data = squeeze(contours(ii, :, :, i));  % 得到 size 为 3000×2
        % 找出非零行的索引
        non_zero_rows = any(contour_data, 2);  % 检查每行是否包含非零值
        % 删除全零行
        clean_contour = contour_data(non_zero_rows, :);
        contour_data = clean_contour;
        center_pts = double(cell2mat(contour_opt(ii, i)));
        band_pts = extractOuterRing(contour_data, center_pts);
        %% 系统优化算法PSO
        popmax=max(max(center_pts));     %￥即自变量的取值范围
        popmin=min(min(center_pts));
        % 使用匿名函数适配粒子群等优化器
%         obj_fun = @(xy) radius_density_peak_multi(xy, contour_data,threshold,3); %论文中使用
        % 粒子群搜索
        obj_fun = @(xy) radius_density_peak_fusion(xy, [], center_pts, band_pts, threshold, top_k); %radius_density_peak_fusion_ava效果更好

        options = optimoptions('particleswarm', 'Display', 'off'); % 关闭所有迭代信息
        [coordinat_best(i,:), best_val] = particleswarm(obj_fun, 2, [popmin, popmin], [popmax, popmax],options);
    end
    coord_cell{ii}=coordinat_best;
end
delete(wait_hand);
t=toc
save data_cal-cir+band_vid.mat coord_cell

% run coord_convert.m
