function [out_rst, comp] = chirp_comp_alias(rz, over_rate)
    % over_rate = Fs / BW;
    nfft = numel(rz);
    target_nfft = round(nfft / over_rate);
    cut1 = rz(1:target_nfft);
    cut2 = rz(end-target_nfft+1:end);
    
    comp = 0;
    mx_pk = -1;
    step = 0.01;
    for i = 0:step:1-step            
        tmp = cut1 + cut2 * exp(1i*2*pi*i);
        if max(abs(tmp)) > mx_pk
            mx_pk = max(abs(tmp));
            out_rst = tmp;
            comp = 2*pi*i;
        end
    end
    
    fprintf('compensation:%.2f\n',comp);
end
