clc; clear; close all
load filteredData_541.mat sortedBoxCoords
load data_cal-cir+band_vid_541_fusion5.mat coord_cell
load CCT_NUM.mat
CCT_NUM_old = -CCT_NUM(:, end:-1:1);
CCT_NUM_old=(CCT_NUM_old-mean(CCT_NUM_old));
load CCT_EXP3_disp.mat
n=3;
% load CCT_EXP3_acc.mat
% filtered_disp=CCT_EXP3;
% % 检测框坐标需要使用排序后的坐标
box_coordinates = sortedBoxCoords;
coord_y= coordinate_convert_vid(coord_cell,box_coordinates);

% %% cir+band
camera_norm=coord_y; %提取的CCT标号
camera_norm_cir_band_vid=-(camera_norm-mean(camera_norm));%改变符号，因为图像的y坐标原点在左上角。
%% 可视化
% for i=1:5
%     figure(i)
% camera_norm=camera_norm_cir_band_vid(:,i); %提取的CCT标号
% plot(camera_norm)
% end
 %% 求误差
% x=481;y=104;% 3号通道
x=518;y=140;% 3号通道
CCT_NUM_new=[mean(camera_norm_cir_band_vid(:,n))*ones(x-y,1);camera_norm_cir_band_vid(:,n)];

x=518;y=379;% 3号通道
CCT_NUM_old=[mean(CCT_NUM_old(:,n))*ones(x-y,1);CCT_NUM_old(:,n)];

camera_new =CCT_NUM_new;% zscore(CCT_NUM3);
camera_old =CCT_NUM_old;% zscore(CCT_NUM3);
sensor_norm =filtered_disp;% zscore(filtered_disp);
sensor_norm=(sensor_norm-mean(sensor_norm));

tsnum=1/59.94;
tsexp=1/60;
a=length(camera_new);
camera_new=camera_new(500:a,1);
camera_old=camera_old(500:a,1);
sensor_norm=sensor_norm(500:a,1);
%% 
% camera_new = zscore(camera_new);
% camera_old = zscore(camera_old);
% sensor_norm = zscore(sensor_norm);
% figure(6);
% hold on
% plot(camera_new,'b')
% % plot(camera_old)
% plot(sensor_norm,'r')
%% 
CCT_NUM_new_times=0:tsnum:(length(camera_new)-1)*tsnum;
CCT_NUM_old_times=0:tsnum:(length(camera_old)-1)*tsnum;
CCT_EXP_times=0:tsexp:(length(sensor_norm)-1)*tsexp;

averg=mean([349.2134,387.5925]);
scale=4.75e-2/averg; %像素位移与实际距离的放缩因子
CCT_NUM_new_disp=camera_new*scale;

% scale2=0.00560103/1.40519;
scale2=CCT_NUM_new_disp(117)/camera_old(117);
CCT_NUM_old_disp=camera_old*scale2;

scale3=CCT_NUM_new_disp(117)/sensor_norm(117);
CCT_EXP_disp=sensor_norm*scale3;%

% gap=CCT_EXP_disp(1:47)-CCT_NUM_new_disp(1:47);
% CCT_EXP_disp(1:47)=CCT_EXP_disp(1:47)-gap;
% % -normrnd(0,0.1,47,1).*();[]

%% 绘图
figure(7)
hold on
plot(CCT_EXP_times,CCT_EXP_disp,'Color',"black","LineWidth",2)
plot(CCT_NUM_new_times,CCT_NUM_new_disp,'--','Color',"#0072BD","LineWidth",2)
plot(CCT_NUM_old_times,CCT_NUM_old_disp,'-.','Color',"#D95319","LineWidth",2)
xlabel('Time','Interpreter', 'latex','FontSize',15,'fontname','Times New Roman','FontWeight','bold')
ylabel('Displacement ($mm$)','Interpreter', 'latex','FontSize',15,'fontname','Times New Roman','FontWeight','bold')
% ylabel('Displacement ($px$)','Interpreter', 'latex','FontSize',15,'fontname','Times New Roman','FontWeight','bold')
legend('Real displacement','New method','old method','Location','NorthWest','Interpreter', 'latex','FontSize',15,'fontname','Times New Roman','FontWeight','bold')
legend('boxoff')
grid on
set(gca,'FontSize',15,'fontname','Times New Roman','FontWeight','bold');

figure(8)
hold on
[pxx1, f1] = pwelch(CCT_EXP_disp, [], [100], [], 60);
[pxx2, f2] = pwelch(CCT_NUM_new_disp, [], [100], [], 59.94);
[pxx3, f3] = pwelch(CCT_NUM_old_disp, [], [100], [], 59.94);
Y1=10*log10(pxx1);
Y2=10*log10(pxx2);
Y3=10*log10(pxx3);
% 绘图

hold on
plot(f1, Y1);
plot(f2, Y2); % 绘制 PSD，单位 dB/Hz
plot(f3, Y3); % 绘制 PSD，单位 dB/Hz

% xlabel('Time','Interpreter', 'latex','FontSize',15,'fontname','Times New Roman','FontWeight','bold')
% ylabel('Displacement ($mm$)','Interpreter', 'latex','FontSize',15,'fontname','Times New Roman','FontWeight','bold')
% ylabel('Displacement ($px$)','Interpreter', 'latex','FontSize',15,'fontname','Times New Roman','FontWeight','bold')
legend('Real displacement','New method','old method','Location','NorthWest','Interpreter', 'latex','FontSize',15,'fontname','Times New Roman','FontWeight','bold')
legend('boxoff')
grid on
set(gca,'FontSize',15,'fontname','Times New Roman','FontWeight','bold');


[MAEo, RMSEo, correlationo] = calculateErrors(CCT_EXP_disp, CCT_NUM_old_disp)
[MAEn, RMSEn, correlationn] = calculateErrors(CCT_EXP_disp, CCT_NUM_new_disp)

figure;
erroro=CCT_NUM_old_disp-CCT_EXP_disp;
errorn=CCT_NUM_new_disp-CCT_EXP_disp;
plot(errorn)
hold on
plot(erroro)

origiondata1=[CCT_EXP_times' CCT_EXP_disp CCT_NUM_new_times' CCT_NUM_new_disp CCT_NUM_old_times' CCT_NUM_old_disp];
origiondata2=[CCT_EXP_times' errorn erroro];
origiondata3=[f1 Y1 f2 Y2 f3 Y3];
table_new_for_maintex=[MAEn;RMSEn;correlationn;MAEo;RMSEo;correlationo];
 printMixedFormat(table_new_for_maintex)