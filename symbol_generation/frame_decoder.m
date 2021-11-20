function code_array = frame_decoder(sig, outfile)

    if nargin > 1 && ~isempty(outfile)
        fid = fopen(outfile,'w');
        fprintf(fid,'%s\n','win,peak,freq,bin,value,phase');
    end
    
    %
    % parameter
    %
    Fs = param_configs(3);         % sample rate        
    BW = param_configs(2);         % LoRa bandwidth
    SF = param_configs(1);         % LoRa spreading factor
    nsamp = Fs * 2^SF / BW;
    nfft = nsamp*10;
    
    %
    % synchronization
    %   
%     sig = frame_sync_zero(sig);
    
    %
    % decode
    %
    nsymb = floor( (numel(sig) - 2.25*nsamp) / nsamp);
    code_array = zeros(1,nsymb);
    sig = [sig(1:10*nsamp),sig(floor(12.25*nsamp)+1:end)];
    
    for lp = 0:nsymb-1
        target = sig(lp*nsamp + (1:nsamp));
        
        rz = chirp_dchirp_fft(target,nfft);
        rz = chirp_comp_alias(rz, Fs/BW);
        [peak_h,I] = max(abs(rz));
        peak_p = angle(rz(I));
        peak_i = I/(nfft/nsamp);
        peak_f = peak_i/2^SF*BW;
        
%         figure;
%             plot(az);
%             title(['win ',num2str(lp+1)]);
%             xlim([I-300 I+300]);
        
        code_array(lp+1) = floor(peak_i);
        fprintf('\n window %d\n',lp+1);
        fprintf("peak=%d,  freq=%d,  bin=%.1f[%d]\n",peak_h,peak_f,peak_i,mod(round(peak_i),2^SF));
        
        if nargin > 1 && ~isempty(outfile)
            fprintf(fid,'%s\n',[num2str(lp+1),',',num2str(peak_h),','...
                ,num2str(peak_f),',',num2str(peak_i),','...
                ,num2str(mod(round(peak_i),2^SF)),',',num2str(peak_p)]);
        end
    end
    
    if nargin > 1 && ~isempty(outfile)
        fclose(fid);
    end
end