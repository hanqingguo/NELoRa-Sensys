function symb = chirp_gen_cr(code_word, SF)
    
    Fs = param_configs(3);         % default sample rate
    BW = param_configs(2);         % LoRa bandwidth
    nsamp = Fs * 2^SF / BW;        % number of samples of a chirp
    t = (0:nsamp-1)/Fs;            % time vector a chirp
    
    % I/Q traces
    f0 = -BW/2; % start freq
    f1 = BW/2;  % end freq
    chirpI = chirp(t, f0, 2^SF/BW, f1, 'linear', 90);
    chirpQ = chirp(t, f0, 2^SF/BW, f1, 'linear', 0);
    mchirp = complex(chirpI, chirpQ);
    mchirp = repmat(mchirp,1,2);
    clear chirpI chirpQ

    % Shift for encoding
    time_shift = round((2^SF - code_word) / 2^SF * nsamp);
    symb = mchirp(time_shift+(1:nsamp));
end