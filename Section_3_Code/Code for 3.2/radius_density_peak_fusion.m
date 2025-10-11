function f = radius_density_peak_fusion(xy, center_all, center_pts, band_pts, delta, top_k)
% 融合型目标函数（stab自适应 + 可选手动权重）
%
% 输入：
%   xy          : 候选中心点 [x, y]
%   center_all  : 所有轮廓点 (整体使用时传入)，否则 []
%   center_pts  : 中心圆轮廓点，否则 []
%   band_pts    : 编码带轮廓点，否则 []
%   delta       : 扫描半径区间宽度
%   top_k       : 取前几个峰
%   varargin    : 可选 [w_center, w_band]，若不给则用stab自适应
%
% 输出：
%   f           : 目标函数值（负值，适合最小化）

    x = xy(1);
    y = xy(2);

    f = 0;  % 默认输出

    %% 情况1：整体输入
    if ~isempty(center_all)
        d = sqrt((center_all(:,1)-x).^2 + (center_all(:,2)-y).^2);
        edges = min(d):delta:max(d);
        counts = histcounts(d, edges);

        peak_sum = sum(maxk(counts, min(top_k, numel(counts))));
        stab = peak_sum / (sum(counts)+eps);

        f = -stab;   % 负值（最小化）
        return;
    end

    %% 情况2：分别输入（融合或单独）
    f_c = 0; f_b = 0;
    stab_c = 0; stab_b = 0;

    % --- 中心圆 ---
    if ~isempty(center_pts)
        d_c = sqrt((center_pts(:,1)-x).^2 + (center_pts(:,2)-y).^2);
        edges_c = min(d_c):delta:max(d_c);
        counts_c = histcounts(d_c, edges_c);

        peak_c = sum(maxk(counts_c, min(top_k, numel(counts_c))));
        stab_c = peak_c / (sum(counts_c)+eps);

        f_c = -stab_c;  % 单独目标
    end

    % --- 编码带 ---
    if ~isempty(band_pts)
        d_b = sqrt((band_pts(:,1)-x).^2 + (band_pts(:,2)-y).^2);
        edges_b = min(d_b):delta:max(d_b);
        counts_b = histcounts(d_b, edges_b);

        peak_b = sum(maxk(counts_b, min(top_k, numel(counts_b))));
        stab_b = peak_b / (sum(counts_b)+eps);

        f_b = -stab_b;  % 单独目标
    end

    % --- 融合 ---
    if ~isempty(center_pts) && ~isempty(band_pts)
        f = -(peak_c* stab_c+peak_b*stab_b);
%         f = -( stab_c^2 + stab_b^2 ) / (stab_c + stab_b + eps);
    elseif ~isempty(center_pts)
        f = f_c;
    elseif ~isempty(band_pts)
        f = f_b;
    end
end
