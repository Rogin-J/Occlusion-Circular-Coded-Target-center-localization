function [MAE, RMSE, correlation] = calculateErrors(actual, measured)
    % 检查输入向量长度是否一致
    if length(actual) ~= length(measured)
        error('输入向量长度必须一致');
    end
    
    % 移除可能存在的NaN值（确保数据完整性）
    validIdx = ~isnan(actual) & ~isnan(measured);
    actual_clean = actual(validIdx);
    measured_clean = measured(validIdx);
    
    % 计算平均绝对误差 (MAE)
    MAE = mean(abs(actual_clean - measured_clean));
    
    % 计算均方根误差 (RMSE)
    RMSE = sqrt(mean((actual_clean - measured_clean).^2));
    
    % 计算相关系数
    correlation = corr(actual_clean(:), measured_clean(:));
end