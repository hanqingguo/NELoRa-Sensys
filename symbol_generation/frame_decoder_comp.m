function code_array = frame_decoder_comp(sig, outfile)
    
    %
    % parameter
    %
    Fs = param_configs(3);         % sample rate        
    BW = param_configs(2);         % LoRa bandwidth
    SF = param_configs(1);         % LoRa spreading factor
    DEBUG = param_configs(5);
    nsamp = Fs * 2^SF / BW;
    nfft = nsamp*10;
    
    % % signal should be oversampled
    if Fs < 2*BW
        fprintf('SAMPLE RATE TOO LOW!\n');
        return;
    end
    
    if nargin > 1 && ~isempty(outfile)
        fid = fopen(outfile,'w');
        fprintf(fid,'%s\n','win,peak,freq,bin,value,phase,compensation');
    end
    
    %
    % synchronization
    %   
%     sig = frame_sync_zero(sig);
    
    %
    % decode
    %
    sig = [sig(1:10*nsamp),sig(floor(12.25*nsamp)+1:end)];
    nsymb = floor(numel(sig) / nsamp);
    code_array = zeros(1,nsymb);    

    for lp = 0:nsymb-1
        target = sig(lp*nsamp + (1:nsamp));
        
        rz_o = chirp_dchirp_fft(target,nfft);
        target_nfft = round(BW/Fs*nfft);
        
        comp = 0;
        step = 0.01;
        pk_tp = -1;
        for pc = 0:step:1-step            
            tmp = rz_o(1:target_nfft) + rz_o(end-target_nfft+1:end) * exp(1i*2*pi*pc);
            if max(abs(tmp)) > pk_tp
                pk_tp = max(abs(tmp));
                rz =tmp;
                az = abs(tmp);
                comp = 2*pi*pc;
            end
        end
        
        [peak_h,I] = max(az);
        peak_p = angle(rz(I));
        peak_i = I/(nfft/nsamp);
        peak_f = peak_i/2^SF*BW;
        
        if DEBUG
            pk_phase(lp+1) = peak_p;
            init_phase(lp+1) = angle(target(1));
            comp_phase(lp+1) = comp;
%             figure;
%                 subplot(3,1,1);
%                     plot(abs(rz_o(1:target_nfft)));
%                     title(['win ',num2str(lp+1)]);
%                 subplot(3,1,2);
%                     plot(abs(rz_o(end-target_nfft+1:end)));
%                     title(['comp ',num2str(comp)]);
%                 subplot(3,1,3);
%                   plot(az);
%                   title(['win ',num2str(lp+1)]);
%                   xlim([I-300 I+300]);
        end
        
%         code_array(lp+1) = floor(peak_i);
        code_array(lp+1) = mod(round(peak_i),2^SF);
        fprintf('\n window %d\n',lp+1);
        fprintf("peak=%d,  freq=%d,  bin=%.2f[%d], phase=%.2f, comp=%.2f\n",...
            peak_h,peak_f,peak_i,mod(round(peak_i),2^SF), peak_p, comp);
        
        if nargin > 1 && ~isempty(outfile)
            fprintf(fid,'%s\n',[num2str(lp+1),',',num2str(peak_h),','...
                ,num2str(peak_f),',',num2str(peak_i),','...
                ,num2str(mod(round(peak_i),2^SF)),','...
                ,num2str(peak_p),',',num2str(comp)]);
        end
    end
    
    if DEBUG
        idx = [1:10, 13.25:nsymb+2.25];
        figure;
            plot(idx, pk_phase,'p-','LineWidth',1);
            title('Peak Phase');
            grid on; box on;
            
        figure;
            plot(idx, unwrap(pk_phase),'p-','LineWidth',1);
            title('Unwrap--Peak Phase');
            grid on; box on;
            
        figure;
            plot(idx, init_phase,'p-','LineWidth',1);
            title('Initial Phase');
            grid on; box on;
            
        figure;
            comp_phase(comp_phase > pi) = comp_phase(comp_phase > pi) - 2*pi;
            plot(idx, comp_phase,'p-','LineWidth',1);
            title('Compensation Phase');
            ylim([-pi pi]);
            grid on; box on;
    end
    
    if nargin > 1 && ~isempty(outfile)
        fclose(fid);
    end
end