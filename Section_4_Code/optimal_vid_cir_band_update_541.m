clc;clear;close all;
tic
load filteredData_541.mat
load central_contour-paper2-901_541-vid.mat
load box_coordinates-paper2-901_541-vid.mat
[contour_opt, sortedBoxCoords] = sortContoursByX(contour_opt, box_coordinates);% 排序轮廓

filteredData_all=filteredData_1464_all;
frames=size(filteredData_all{1},1);
threshold = 1; % 设定相近距离的阈值
top_k=1;
wait_hand = waitbar(0,'Runing……', 'tag', 'TMWWaitbar');
for ii=1:frames
    waitbar(ii/frames,wait_hand);
    for i=1:size(filteredData_all,2) %CCCT标签数
        % 提取轮廓数据
        contour_data = filteredData_all{i}{ii};  % 得到 size 为 3000×2
        contour_data=double(contour_data);
        %% 系统优化算法PSO

        % 使用匿名函数适配粒子群等优化器
        % 提取轮廓数据
        center_pts = double(cell2mat(contour_opt(ii, i)));
        band_pts = extractOuterRing(contour_data, center_pts);
        all_pts=contour_data;
%         obj_fun = @(p) radius_density_peak_fusion(p, all_pts, [], [], threshold, top_k, 'all');
%           obj_fun = @(p) radius_density_peak_fusion(p, [], center_pts, band_pts, threshold, top_k, 'auto');
        %         obj_fun = @(p) radius_density_peak_single(p, center_pts,threshold); %论文中使用
%         obj_fun = @(p) radius_density_peak_fusion(p, [], [], band_pts, threshold, top_k, 'band');
        %                 obj_fun = @(p) radius_density_peak_fusion(p, [], center_pts, [], threshold, top_k, 'center');
        %         obj_fun = radius_density_peak_multi(xy, contour_data,threshold,top_k); %论文中使用
obj_fun = @(xy) radius_density_peak_fusion(xy, [], center_pts, band_pts, threshold, top_k); %radius_density_peak_fusion_ava效果更好

% obj_fun = @(xy) object_function_old(center_pts, xy, threshold); %radius_density_peak_fusion_ava效果更好
% [coordinat_best(i,:),yy]=PSO_algorithm(center_pts,10,50,threshold);
        % 粒子群搜索
        popmax=max(max(center_pts));     %￥即自变量的取值范围
        popmin=min(min(center_pts));
        options = optimoptions('particleswarm', 'Display', 'off'); % 关闭所有迭代信息
        [coordinat_best(i,:), best_val] = particleswarm(obj_fun, 2, [popmin, popmin], [popmax, popmax],options);
    end
    coord_cell{ii}=coordinat_best;
end
delete(wait_hand);
t=toc
save data_cal-cir+band_vid_541_fusion5.mat coord_cell

