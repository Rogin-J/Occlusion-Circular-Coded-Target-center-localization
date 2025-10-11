clear;clc;
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
   
%% 误差图
figure('Position',[0 0 800 600])
plot(X-Y1,'-','Color',"#D95319",'DisplayName','Error: Proposed vs Simulation'); hold on
% plot(X-Y2,'--','Color',"#0072BD",'DisplayName','Error: Baseline vs Simulation');
xlabel('Frames','Interpreter', 'latex','FontSize',30,'fontname','Times New Roman','FontWeight','bold')
ylabel('Displacemet ($px$)','Interpreter', 'latex','FontSize',30,'fontname','Times New Roman','FontWeight','bold')
% legend('MPRAF','Previous method','Interpreter', 'latex','NumColumns', 2)
% legend('boxoff')
xlim([0 120])
set(gca,'FontSize',20,'fontname','Times New Roman','FontWeight','bold');
grid on

%% 误差计算
% 或针对向量：
mae_adaptive_cir_band(i) = mean(abs(X - Y1));       % 若 X 和 Y 是列向量或行向量
rmse_adaptive_cir_band(i) = sqrt(mean((X - Y1).^2));        % 若 X 和 Y 是列向量或行向量
correlation_cir_band(i) = corr(X , Y1);


%% 误差计算
% 或针对向量：
% mae_adaptive_cir(i) = mean(abs(X - Y2));       % 若 X 和 Y 是列向量或行向量
% rmse_adaptive_cir(i) = sqrt(mean((X - Y2).^2));        % 若 X 和 Y 是列向量或行向量
% correlation_cir(i) = corr(X , Y2);

end
% a1=107.391/12.4303;
% a2=107.387/12.2256;
% a3=107.541/12.2256;
