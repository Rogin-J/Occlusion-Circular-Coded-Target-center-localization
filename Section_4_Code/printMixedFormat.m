function printMixedFormat(data)
% PRINTMIXEDFORMAT 根据数字大小自动选择打印格式
%   对于小数点前有3位或更多数字的值使用科学计数法（保留3位小数）
%   对于小数点前只有1-2位数字的值使用常规小数格式（保留2位小数）
    
    for i = 1:length(data)
        value = data(i);
        
        % 计算小数点前的位数
        if value == 0
            num_digits = 0;
        else
            num_digits = floor(log10(abs(value))) + 1;
        end
        
        % 根据小数点前的位数选择格式
        if num_digits >= 3 || (value ~= 0 && abs(value) < 0.001)
            % 小数点前有3位或更多，或者绝对值小于0.001，使用科学计数法（保留3位小数）
            fprintf('%.3e\n', value);
        else
            % 小数点前有1-2位，使用常规小数格式（保留2位小数）
            fprintf('%.3f\n', value);
        end
    end
end