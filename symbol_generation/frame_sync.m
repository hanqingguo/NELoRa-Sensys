function [outsig, t_offset,f_offset] = frame_sync(frame_sig, DEBUG)
    %
    % parameter
    %
    Fs = param_configs(3);         % sample rate        
    BW = param_configs(2);         % LoRa bandwidth
    SF = param_configs(1);         % LoRa spreading factor
    nsamp = Fs * 2^SF / BW;
    nfft = nsamp * 10;
    
    if nargin == 1
        DEBUG = false;
    end
    
    % extract the up-chirp and the down-chirp
    up_pre = frame_sig(5*nsamp + (1:nsamp));
    down_pre = frame_sig(11*nsamp + (1:nsamp));
    over_rate = Fs / BW;
    
    % % dechirp
    [~,rz] = chirp_dchirp_fft(up_pre,nfft);
    rz = chirp_comp_alias(rz, over_rate);
    up_az = abs(rz);
    [~,peak_i] = max(up_az);
    up_freq = peak_i/nfft * Fs;
    
    dcp = down_pre .* Utils.gen_symbol(0);
    rz = fft(dcp, nfft);
    rz = chirp_comp_alias(rz, over_rate);
    down_az = abs(rz);
    [~,peak_i] = max(down_az);
    down_freq = peak_i/nfft * Fs;
    
    if DEBUG
        fprintf('[up-chirp] freq = %.2f\n[down-chirp] freq = %.2f\n', up_freq, down_freq);
        figure;
        subplot(2,2,1);
            Utils.spectrum(up_pre);title('spectrum of up');
        subplot(2,2,2);
            Utils.spectrum(down_pre);title('spectrum of down');
            
        f_idx = (0:nfft-1)/nfft*Fs;
        subplot(2,2,3);
            plot(f_idx(1:numel(up_az)), up_az); title('FFT of up'); xlim([0 BW]);
        subplot(2,2,4);
            plot(f_idx(1:numel(down_az)), down_az); title('FFT of down'); xlim([0 BW]);
    end
    
    % % calculate CFO
    f_offset = (up_freq + down_freq) / 2;
    if abs(f_offset) > 50e3
        if f_offset < 0
            f_offset = f_offset + BW/2;
        else
            f_offset = f_offset - BW/2;
        end
    end
    
    % % calculate Time Offset
    t_offset = round((up_freq - f_offset) / BW * nsamp);
    if t_offset > nsamp/2
        t_offset = t_offset - nsamp;
    end
    
    sig_st = t_offset;
    if sig_st < 0
        frame_sig = frame_sig(-sig_st:end);
%         frame_sig = [zeros(1, -sig_st), frame_sig];
        sig_st = 0;
    end
    
    outsig = frame_sig(sig_st+1:end);
    
%     figure;
%         plot(real(frame_sig));
%         hold on
%         plot(sig_st+1:length(frame_sig), real(outsig));
end