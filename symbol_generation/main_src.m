clc;
clear;
close all;

% LoRa modulation & sampling parameters
Fs = param_configs(3);         % sample rate        
BW = param_configs(2);         % LoRa bandwidth
SF = param_configs(1);         % LoRa spreading factor
nsamp = Fs * 2^SF/BW;
DEBUG = true;  

frame_len = 26 * nsamp;

fileID = fopen('input/pt2', 'r');
pre_data = io_read_line(fileID, 8*nsamp); % read 8 chirps 


ex = 1;         % number of packets 
instance = 1;

while ~isempty(pre_data) && ex < 2
    % % Combining with pre_data for detection
    data = [pre_data, io_read_line(fileID, frame_len)];
    
    % % Packet Detection
    % %---detecting by concentrating energy of preamble chirps---
    [frame_sign, frame_st] = frame_detect(data);
    % %---detecting by searching repeated peaks of preamble chirps---
    % [frame_sign, frame_st] = frame_detect2(data, 8);
    
    if frame_sign
        raw = [data(frame_st:end), io_read_line(fileID, frame_st + nsamp)];
        pre_data = raw(end - 8*nsamp + 1 : end);
    
        [sig_raw, to, cfo] = frame_sync(raw);
        t = (0:numel(sig_raw)-1)/Fs;
        sig = sig_raw .* exp(-1i*2*pi* cfo * t);
        sig = sig(1:frame_len);
    
        head_len = 12.25;
        upayload = [sig(1:(head_len-2.25)*nsamp), sig(head_len*nsamp+1:end)];
        rpayload = [sig_raw(1:(head_len-2.25)*nsamp), sig_raw(head_len*nsamp+1:end)];

        if DEBUG
            figure;subplot(3,1,1);
                plot(real(sig));
                xlim([1, numel(sig)]);
            subplot(3,1,2);
                Utils.spectrum(sig);
            subplot(3,1,3);
                Utils.spectrum(upayload, 512, 256, 1024, Fs);
            % saveas(gcf,'Spectrum.png')
        end

        % write out cutted symbols
        filepath = ['output/LoRa_db/ins', num2str(instance), '/', num2str(ex), '/'];
        mkdir([filepath, 'wCFO/']);
        mkdir([filepath, 'woCFO/']);
        
        % demodulating with standard LoRa
        frame_decoder_comp(sig, [filepath, num2str(ex), '_wCFO.csv']);
        frame_decoder_comp(sig, [filepath, num2str(ex), '_woCFO.csv']);
        
        for i = 1 : floor(numel(upayload)/nsamp)
            symb = upayload((i-1)*nsamp + (1:nsamp));
            symb_r = rpayload((i-1)*nsamp + (1:nsamp));
            
            % without CFO
            dcp = chirp_dchirp_fft(symb, nsamp * 10);
            z = chirp_comp_alias(dcp, Fs/BW);        
            fidx = (0:numel(z)-1)/numel(z) * BW;
            [ma, I] = max(abs(z));
            value = mod((I / numel(z) * 2^SF), 2^SF);
            fprintf("Window[%d] freq = %.2f, value = %.2f, peak = %.2f\n", i, fidx(I), value, ma);
            % write file
            filename = [num2str(i),'_',num2str(value),'_',num2str(SF),'_',num2str(BW),'_',num2str(instance)];
            io_write_iq([filepath,'woCFO/',filename], symb);

            % with CFO
            dcp = chirp_dchirp_fft(symb_r, nsamp * 10);
            z = chirp_comp_alias(dcp, Fs/BW);        
            [ma, I] = max(abs(z));
            value = mod((I / numel(z) * 2^SF), 2^SF);
            fprintf("Window[%d] freq = %.2f, value = %.2f, peak = %.2f\n", i, fidx(I), value, ma);
            filename = [num2str(i),'_',num2str(value),'_',num2str(SF),'_',num2str(BW),'_',num2str(instance)];
            io_write_iq([filepath,'wCFO/',filename], symb_r);         
        end
        ex = ex + 1;
    else
        pre_data = data(end - 8*nsamp + 1 : end);
    end
end