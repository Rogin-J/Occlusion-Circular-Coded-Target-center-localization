clear;clc;close all
load Y_Simulation.mat
load camera_norm_cir_band_vid.mat
% load camera_norm_cir_vid.mat
param=[8.6289 9.0080 8.6705]; %8.6289---cct1,9.0080---cct2,8.6705---cct3

for i=1:3
Y_Simulation = -Y(50,:)*param(i); 
Y_Simulation = Y_Simulation';
X  = Y_Simulation;
Y1 = camera_norm_cir_band_vid(:,i);  
% Y2 = camera_norm_cir_vid(:,i);      

%% 全局图形参数设置
set(groot,'defaultAxesFontName','Times New Roman'); 
set(groot,'defaultAxesFontSize',14); 
set(groot,'defaultLineLineWidth',2); 
set(groot,'defaultLineMarkerSize',6);
% 
%% 主图 + 局部放大
figure('Position',[0 0 800 600])

plot(X,'r-','DisplayName','Simulation',"LineWidth",2); hold on
plot(Y1,'b--','DisplayName','Proposed method',"LineWidth",2);
% plot(Y2,'g:','DisplayName','Baseline',"LineWidth",2);
xlabel('Frames','Interpreter', 'latex','FontSize',30,'fontname','Times New Roman','FontWeight','bold')
ylabel('Displacemet ($px$)','Interpreter', 'latex','FontSize',30,'fontname','Times New Roman','FontWeight','bold')
% legend('Reference','MPRAF','Previous method','Interpreter', 'latex','NumColumns', 3)
% legend('boxoff')
xlim([0 120])
set(gca,'FontSize',20,'fontname','Times New Roman','FontWeight','bold');
grid on
% 局部放大 (inset)
% %% 鼠标点击主图，获取 inset 左上角位置
% %% 点击大图，插入多个小图 (center based)
% disp('请在大图上点击要插入的小图中心，按 Enter 完成');
% 
% ax = gca;                   % 当前坐标轴
% ax_units = ax.Position;      % 主图在 figure 的归一化坐标 [x y w h]
% xlims = ax.XLim;             % 主图 X 数据范围
% ylims = ax.YLim;             % 主图 Y 数据范围
% 
% w = 0.1 * ax_units(3);       % inset 宽度 (归一化)
% h = 0.3 * ax_units(4);       % inset 高度 (归一化)
% 
% hold on
% while true
%     [xdata, ydata, button] = ginput(1);  % 点击一次
%     if isempty(button) || button==13      % 按 Enter 键结束
%         break
%     end
%     
%     % 数据坐标 -> 归一化坐标
%     x_norm = ax_units(1) + (xdata - xlims(1)) / (xlims(2)-xlims(1)) * ax_units(3);
%     y_norm = ax_units(2) + (ydata - ylims(1)) / (ylims(2)-ylims(1)) * ax_units(4);
%     
%     % 以点击位置为中心计算左下角
%     pos = [x_norm - w/2, y_norm - h/2, w, h];
%     disp(['插入小图归一化位置参数: [', num2str(pos), ']']);
%     
%     % 创建 inset
%     axes('Position', pos)
%     box on
%     plot(X,'r-'); hold on
%     plot(Y1,'b--');
%     plot(Y2,'g:');
%     xlim([xdata xdata+0.05])   % 放大区间（可改）
% set(gca,'LineWidth',1.0,'FontSize',15)
%     grid on
% end

end
