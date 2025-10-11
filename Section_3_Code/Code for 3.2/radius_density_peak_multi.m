function f = radius_density_peak_multi(coordinat_opt, contour, delta, top_k)
% 多峰扫描线目标函数：适用于多个同心圆的情况
% 输入：
%   coordinat_opt: 候选中心点 [x, y]
%   contour: 轮廓点 N×2
%   delta: 扫描线区间宽度
%   top_k: 取前几个出现频次最高的区间作为累加目标
% 输出：
%   f: 目标函数值（负值用于最小化）

    x = coordinat_opt(1);
    y = coordinat_opt(2);
    num_points = size(contour, 1);

    % 计算距离
    distances = sqrt((contour(:,1) - x).^2 + (contour(:,2) - y).^2);

    % 扫描分段
    min_len = min(distances);
    max_len = max(distances);
    edges = min_len:delta:max_len;

    % 统计每段数量
    counts = histcounts(distances, edges);

    % 取前 top_k 个最大值
    sorted_counts = sort(counts, 'descend');
    peak_sum = sum(sorted_counts(1:min(top_k, length(sorted_counts))));

    f = -peak_sum;  % 最小化目标
end
