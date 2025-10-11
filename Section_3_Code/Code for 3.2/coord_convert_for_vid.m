clc; clear; close all
load box_coordinates-paper2_703-vid.mat
load data_cal-cir+band_vid.mat
% load data_cal-cir_vid.mat
% 初始化排序后的结果容器
sorted_box_coordinates = zeros(size(box_coordinates)); % 601x3x2
sorted_coord_cell = cell(size(coord_cell));            % 1x601 cell

% 遍历每一帧
for frame = 1:size(box_coordinates, 1)
    % 提取当前帧的3个区域坐标 (3x2 矩阵)
    current_boxes = squeeze(box_coordinates(frame, :, :));

    % 按 x 坐标排序并获取索引
    [~, sorted_idx] = sort(current_boxes(:, 1));  % 按第1列(x坐标)排序

    % 对监测框坐标排序
    sorted_boxes = current_boxes(sorted_idx, :);
    sorted_box_coordinates(frame, :, :) = sorted_boxes;

    % 对局部中心坐标同步排序
    current_centers = coord_cell{frame};
    sorted_centers = current_centers(sorted_idx, :);
    sorted_coord_cell{frame} = sorted_centers;
end

% 排序完成后替换原变量
box_coordinates = sorted_box_coordinates;
coord_cell = sorted_coord_cell;

for i=1:size(box_coordinates,1)
    coordinat_best=coord_cell{i};
    box_coordinate=squeeze(box_coordinates(i,:,:));
    coordinat_best_global(:,:,i)=box_coordinate+coordinat_best;
end

for i=1:size(box_coordinates,1)
    for j=1:3
        coord_y(i,j)= coordinat_best_global(j,2,i);
    end
end

% camera_norm=coord_y(:,1); %提取的CCT标号
camera_norm=coord_y; %提取的CCT标号
% plot(camera_norm)

%% cir+band
camera_norm_cir_band_vid=camera_norm-mean(camera_norm);
save camera_norm_cir_band_vid.mat camera_norm_cir_band_vid

%% cir
% camera_norm_cir_vid=camera_norm-mean(camera_norm);
% save camera_norm_cir_vid.mat camera_norm_cir_vid
 
% run Simulation_motion_cal.m



