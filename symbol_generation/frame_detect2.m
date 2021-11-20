% searching for repeated peaks for preamble detecting
function [frame_sign, frame_st] = frame_detect2(datain, prb_len)
    % parameters
    Fs = param_configs(3);         % sample rate        
    BW = param_configs(2);         % LoRa bandwidth
    SF = param_configs(1);         % LoRa spreading factor
    nsamp = Fs * 2^SF / BW;
    
    % datain short than a frame
    frame_sign = false;
    frame_st = -1;
    if length(datain) < prb_len * nsamp
        return;
    end
    
    nfft = nsamp * 4;
    nwins = floor(length(datain) / nsamp);
    res_ft = zeros(1, nwins);
    
    % find the highest peak in each window
    for i = 1:nwins
%         fprintf('--- window%d ---\n',i);
        symb = datain((i-1)*nsamp + (1:nsamp));
        rz = chirp_dchirp_fft(symb, nfft);
        rz = chirp_comp_alias(rz, Fs/BW);
        
        fidx = (0:numel(rz)-1) / numel(rz) * 2^SF;
        [ma, I] = max(abs(rz));
        res_ft(i) = fidx(I);
        
        fprintf("window[%d] peak at %.1f, with height of %d\n", i, fidx(I), ma);
    end

    % search for repeated peaks
    for i = 1 : nwins-prb_len
        pks = res_ft(i:i+prb_len-1);
        disp(round(pks));
        if prb_len == 8
            [~, I] = max(abs(pks - mean(pks)));
            if I == 1 || I == 8
                tmp = pks;
            else
                tmp = [pks(1:I-1), pks(I+1:end)];
            end
        else
            tmp = pks;
        end
        if max(abs(tmp - mean(tmp))) < 2
            fprintf("frame detected!\n");
            frame_sign = true;
            frame_st = round(nsamp - mean(pks)/2^SF * nsamp) + (i-1)*nsamp;
            return;
        end
    end
end