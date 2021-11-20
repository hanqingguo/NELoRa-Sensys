function [fft_res,freq_pwr] = chirp_dchirp_fft(symb, nfft)

    %
    % parameter
    DEBUG = param_configs(5);         % DEBUG
    dn_chirp = Utils.gen_symbol(0, true);
    if nargin < 2 || isempty(nfft) || nfft < 0
        nfft = numel(dn_chirp);
    end
    
    target = zeros(1, numel(dn_chirp));
    sig_ed = numel(target);
    if (sig_ed > numel(symb))
        sig_ed = numel(symb);
    end
    target(1:sig_ed) = symb(1:sig_ed);
    
    % dechirp
    de_samples = target .* dn_chirp;
    
    if DEBUG
%         fprintf('\ninit phase %.2f', angle(de_samples(100)));
%         figure;plot(real(de_samples));
    end

    % FFT on the first chirp len    
    fft_res = fft(de_samples, nfft);
    
    freq_pwr = abs(fft_res);
end