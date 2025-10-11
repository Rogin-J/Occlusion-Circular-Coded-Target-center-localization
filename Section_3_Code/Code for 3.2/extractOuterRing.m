function outerRing = extractOuterRing(A, B, tolerance)
    % EXTRACTOUTERRING 从包含内外环的点集中提取外环点
    %
    % 输入参数：
    %   A - n×2矩阵，包含内外环的所有点坐标
    %   B - m×2矩阵，仅包含内环的点坐标
    %   tolerance - 可选，容差值，用于判断点是否相同（默认值：1e-5）
    %
    % 输出参数：
    %   outerRing - k×2矩阵，仅包含外环的点坐标
    
    % 设置默认容差值
    if nargin < 3
        tolerance = 1e-5;
    end
    
    % 检查输入数据维度
    if size(A, 2) ~= 2 || size(B, 2) ~= 2
        error('输入数据必须是二维点集（n×2矩阵）');
    end
    
    % 方法1：使用距离容差判断点是否相同（更适用于浮点数坐标）
    outerRing = [];
    
    for i = 1:size(A, 1)
        point = A(i, :);
        isInner = false;
        
        % 检查当前点是否在内环B中
        for j = 1:size(B, 1)
            if norm(point - B(j, :)) < tolerance
                isInner = true;
                break;
            end
        end
        
        % 如果点不在内环中，则添加到外环
        if ~isInner
            outerRing = [outerRing; point];
        end
    end
    
    % 方法2：如果坐标是精确整数，可以使用更高效的方法（取消注释以下代码）
    % 注意：此方法仅适用于精确匹配的情况，不适用于浮点数坐标
    %{
    % 将点转换为字符串表示以便比较
    A_str = string(A);
    B_str = string(B);
    
    % 使用ismember找到A中不在B中的点
    [~, idx] = ismember(A_str, B_str, 'rows');
    outerRing = A(idx == 0, :);
    %}
    
    % 可视化结果（可选，取消注释以下代码以查看可视化）
    %{
    figure;
    hold on;
    scatter(A(:,1), A(:,2), 'b', 'filled'); % 所有点（蓝色）
    scatter(B(:,1), B(:,2), 'g', 'filled'); % 内环点（绿色）
    scatter(outerRing(:,1), outerRing(:,2), 'r', 'filled'); % 外环点（红色）
    legend('所有点', '内环点', '外环点');
    title('点集分解结果');
    hold off;
    %}
end