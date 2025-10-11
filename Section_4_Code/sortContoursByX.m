function [sortedContours, sortedBoxCoords] = sortContoursByX(contoursCell, boxCoordinates)
    % 根据检测框的X坐标对轮廓数据进行排序
    %
    % 输入参数:
    %   contoursCell - 150×5的单元格数组，每个单元格包含轮廓点坐标
    %   boxCoordinates - 150×5×2的矩阵，包含每个轮廓的检测框坐标
    %
    % 输出参数:
    %   sortedContours - 排序后的轮廓数据
    %   sortedBoxCoords - 排序后的检测框坐标
    
    % 获取数据尺寸
    [numFrames, numRegions] = size(contoursCell);
    
    % 初始化输出变量
    sortedContours = cell(numFrames, numRegions);
    sortedBoxCoords = zeros(size(boxCoordinates));
    
    % 对每一帧进行处理
    for frame = 1:numFrames
        % 获取当前帧的所有检测框X坐标
        frameBoxes = squeeze(boxCoordinates(frame, :, :));
        xCoords = frameBoxes(:, 1);
        
        % 对X坐标进行排序并获取排序索引
        [~, sortIdx] = sort(xCoords);
        
        % 按照排序索引重新排列轮廓和检测框
        for region = 1:numRegions
            sortedContours{frame, region} = contoursCell{frame, sortIdx(region)};
            sortedBoxCoords(frame, region, :) = boxCoordinates(frame, sortIdx(region), :);
        end
    end
    
    % 验证排序结果
    disp('排序完成，验证前几帧的X坐标顺序:');
    for frame = 1:min(3, numFrames)
        frameBoxes = squeeze(sortedBoxCoords(frame, :, :));
        xCoords = frameBoxes(:, 1);
        disp(['帧 ', num2str(frame), ' 的X坐标: ', num2str(xCoords')]);
    end
end