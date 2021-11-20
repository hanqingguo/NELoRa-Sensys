clc;
clear;
close all;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Description: Decode noisy chirp symbols with the baseline method: the dechirp
% Author: Chenning Li, Hanqing Guo
% Input: Noisy chirp symbols
% Output: The SNR-SER data
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Set your own paths
data_root = '';
data_dir='/data/Lora/sf7_125k/';
% generate multi-path signal
Fs = param_configs(3);         % sample rate
upsamping_factor = param_configs(4);   
feature_dir = [data_root,data_dir];
abs_decode = 0;

feature_data_list=dir(fullfile(feature_dir));
n_feature_data_list=size(feature_data_list,1);

SNR_minimal=-30;
SNR_list=SNR_minimal:0;

BW_list=[125000];
SF_list=[7];
batch_list=4:7;

for BW=BW_list
    for SF=SF_list
        chirp_down = Utils.gen_symbol(0,true,Fs,BW,SF);
        error_matrix=zeros(length(SNR_list),1);
        error_matrix_count=zeros(length(SNR_list),1);
        nsamp = Fs * 2^SF / BW;
        for feature_data_index=1:n_feature_data_list
            feature_data_name=feature_data_list(feature_data_index).name;
            if strcmp(feature_data_name,'.')==1||strcmp(feature_data_name,'..')==1
                continue;
            end
            raw_data_name_components = strsplit(feature_data_name(1:end-4),'_');
            
            if (( ~ismember(str2num(raw_data_name_components{2}), SNR_list) || ~ismember(str2num(raw_data_name_components{5}), batch_list))
                continue;
            end
            
            SNR_index=str2num(raw_data_name_components{2})-SNR_minimal+1;
            load([feature_dir,feature_data_name]);
            chirp_dechirp = chirp .* chirp_down;
            
            chirp_fft_raw =(fft(chirp_dechirp, nsamp*upsamping_factor));
            
            if abs_decode
                chirp_peak_overlap=abs(chirp_abs_alias(chirp_fft_raw, Fs/BW));
            else
                chirp_peak_overlap = abs(chirp_comp_alias(chirp_fft_raw, Fs / BW));
            end

            [pk_height_overlap,pk_index_overlap]=max(chirp_peak_overlap);
            code_estimated=mod(2^SF-round(pk_index_overlap/upsamping_factor),2^SF);
            
            code_label=str2num(raw_data_name_components{6});
            
            error_matrix(SNR_index,1)=  error_matrix(SNR_index,1)+(code_estimated==code_label);
            error_matrix_count(SNR_index,1)=error_matrix_count(SNR_index,1)+1;
        end
        error_matrix=error_matrix./error_matrix_count;
        feature_path = [data_root, 'matlab/evaluation/','baseline_error_matrix_',num2str(SF),'_',num2str(BW),'.mat'];
        save(feature_path, 'error_matrix','SNR_list');
    end
end