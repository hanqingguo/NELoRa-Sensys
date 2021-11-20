clear;
% clc;
close all;

%% Set Parameters for Loading Data
fig=figure;
set(fig,'DefaultAxesFontSize',20);
set(fig,'DefaultAxesFontWeight','bold');

data_root = '';
color_list = linspecer(2);
BW=125000;
SF=7;

SNR_list=[-25:15];
nelora_file='evaluation/sf7_v1_';

SNR_list_baseline=-30:0;
baseline_file='evaluation/baseline_error_matrix_';

name_str=[nelora_file,num2str(SF),'_',num2str(BW),'.mat'];
error_path = [data_root,name_str];
a = load(error_path);
error_matrix = a.error_matrix;
% error_matrix_info = a.error_matrix_info;

plot(SNR_list,1-error_matrix,"-.*",'LineWidth',3,'color',color_list(1,:));
hold on;

name_str=[baseline_file,num2str(SF),'_',num2str(BW),'.mat'];
error_path = [data_root,name_str];
a = load(error_path);
error_matrix = a.error_matrix;
plot(SNR_list_baseline,1-error_matrix,"-.*",'LineWidth',2,'color',color_list(2,:));
hold on;

legend('abs baseline','phs baseline')

% legend('abs_baselineNELoRa','Baseline')
xlabel('SNR (dB)'); % x label
ylabel('SER'); % y label
title('Decode SER for SF=7')
xlim([-30,-10]);
set(gcf,'WindowStyle','normal','Position', [200,200,640,360]);
saveas(gcf,[data_root,'res/',num2str(SF),'_',num2str(BW),'.png'])
