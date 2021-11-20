% accumulate energy of all preamble chirp
function [frame_sign, frame_st] = frame_detect(datain)
    % parameters
    Fs = param_configs(3);         % sample rate        
    BW = param_configs(2);         % LoRa bandwidth
    SF = param_configs(1);         % LoRa spreading factor
    nsamp = Fs * 2^SF / BW;
    prb_len = 4;
    
    % if datain too short
    frame_sign = false;
    frame_st = -1;
    if length(datain) < 8 * nsamp
        return;
    end
    
    nfft = nsamp;
    nwins = floor(length(datain) / nsamp);
    res_ft = zeros(nwins, nfft);
    for i = 1:nwins
%         fprintf('--- window%d ---\n',i);
        symb = datain((i-1)*nsamp + (1:nsamp));
        dcp_symb = symb .* Utils.gen_symbol(0,true);
        res_ft(i,:) = fft(dcp_symb, nfft);
        % detect a frame with at least 4 symbols
        if i < prb_len
            continue;
        end
        
        % accumulate energy of preambles by searching init phase
        step = 0.1;
        pk_mx = -1;   % search for the highest peak
        pk_min = Inf; % search for the lowest peak as threshold
        for ii = 0:step:1-step
            acc_ft = zeros(1,nfft);
            for win_idx = i-prb_len+1:i
%                 acc_ft = acc_ft + res_ft(win_idx,:) * exp(1i*2*pi*ii*win_idx);
                  acc_ft = acc_ft + res_ft(win_idx,:) * exp(1i*2*pi*(BW/(1+ii)*win_idx^2 + 480e6*ii*win_idx));
            end
            [ma, I] = max(abs(acc_ft));
%             fprintf("[phase %.1f * 2pi] peak at %.0f, with height of %.0f\n",ii, I, ma);
            
            if ma > pk_mx
                pk_mx = ma;
                pk_idx = I;
            end
            
            if ma < pk_min
                pk_min = ma;
                threshold = max(ma * 2, 10); % dynamic threshold
            end
        end
        
%         fprintf("frame detect: threshold is %.0f\n",threshold);
        if pk_mx > threshold
            frame_sign = true;
            frame_st = pk_idx + nsamp*(win_idx-1);
            figure;
                plot(abs(acc_ft));
            return;
        end
    end
    
end