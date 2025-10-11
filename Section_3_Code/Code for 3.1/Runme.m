clc; clear; close all;
%这是PSO求解中心点的主程序
tic

% === 只需修改此处 ===
case_num = '03'; % 工况编号，如 '01-仅遮挡中心圆面', '02-仅遮挡编码带',...
% '03-正交组合'
% ========================

% 动态生成文件名
contour_file = sprintf('contour_data-pic-deletezeor801-%s.mat', case_num);
box_file = sprintf('box_coordinates-paper2_801-%s.mat', case_num);
real_coords_file = sprintf('real_coords_9pic_%s.mat', case_num);
save_file = sprintf('data_cal-cir+band_9pic-%s.mat', case_num);
center_file = sprintf('center_%s.mat', case_num);
% 加载数据
top_k=2;
threshold = 1; % 设定相近距离的阈值
load(contour_file);
contours_cleaned = contours_all;
load(real_coords_file);
load(center_file);
for i = 1:length(real_coords) % CCCT标签数
    contour_data = cell2mat(contours_cleaned(i));
    contour_data = double(contour_data);
    center_data =  double(cell2mat(center_pts(i)));
    band_data = extractOuterRing(contour_data, center_data);
    % PSO优化
    obj_fun = @(xy) radius_density_peak_fusion(xy, [], center_data, band_data, threshold, top_k); %radius_density_peak_fusion_ava效果更好
    popmax = max(max(contour_data));
    popmin = min(min(contour_data));
    % 提取 x 和 y 坐标的最小值和最大值
    x_min = min(contour_data(:,1));
    x_max = max(contour_data(:,1));
    y_min = min(contour_data(:,2));
    y_max = max(contour_data(:,2));

    % 设置下界和上界
    lb = [x_min, y_min]; % 下界 [x_min, y_min]
    ub = [x_max, y_max]; % 上界 [x_max, y_max]
    options = optimoptions('particleswarm', 'Display', 'off');
    [coordinat_best(i,:), best_val] = particleswarm(obj_fun, 2, lb, ub, options);

    % 加载并处理真实坐标，将真实坐标转换为局部坐标，便于作图对比
    load(box_file);
    box_coordinate = box_coordinates(i,:);
    box_coordinate = double(box_coordinate);
    real_coord = real_coords{i};
    real_coord_local(i,:) = real_coord - box_coordinate;
end
toc

%% 绘图
for i=1:length(coordinat_best)
    a=cell2mat(contours_cleaned(i));
    contour_data=double(a);
    %画图
    figure;
    axis equal;
    grid on;
    hold on
    scatter(contour_data(:,1),contour_data(:,2))
    set(gca,'ydir','reverse','xaxislocation','top');
    plot(real_coord_local(i,1),real_coord_local(i,2),'o', 'Linewidth', 2, 'MarkerSize', 16)%画剪切后的实际坐标
    plot(coordinat_best(i,1),coordinat_best(i,2),'r+', 'Linewidth', 2, 'MarkerSize', 16)%画优化算法坐标
    set(gca,'FontSize',15,'fontname','Times New Roman','FontWeight','bold');
    %     legend('Contour','The real center','Detected by the proposed method','fontsize',15,'Box','off');
    %     ylim([380,700]);
    hold off
    % 欧式误差求解
    X0=real_coord_local(i,1); Y0=real_coord_local(i,2);
    formatSpec = '%1.0fst Real center point: %4.2f, %8.3f \n';
    fprintf(formatSpec,i,X0,Y0);
    x=coordinat_best(i,1); y=coordinat_best(i,2);
    formatSpec = 'Identified center point: %4.2f, %8.3f \n';
    fprintf(formatSpec,x,y);
    eps_pixel(i) = sqrt((x - X0)^2 + (y - Y0)^2);
    formatSpec = 'Error: %4.2f \n';
    fprintf(formatSpec,eps_pixel(i));
end