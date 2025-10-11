clear;clc;close all
% 计算理论位移
    fps = 30;
    frame = 301;
  
    L = 1000.0;
    A = 50.0;
    f = 1.0;
    omega = 2 * pi * f;

for k = 1:frame
    % 计算当前时间
    time = (k-1) / fps;

    x = linspace(-L/2, L/2, 100);  % 梁的长度方向上的点

        x_norm = (x  + L * 0.5) / L;
        y_disp = A * sin(omega * time) * (x_norm - x_norm.^2);
        
Y(:,k)=y_disp;
end
save Y_Simulation.mat Y