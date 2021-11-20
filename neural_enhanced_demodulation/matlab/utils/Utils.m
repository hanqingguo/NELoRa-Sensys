classdef Utils < handle
    
    methods (Static = true)
        function dataout = add_noise(datain,snr,Fs,BW,SF)
            if nargin < 3
                Fs = param_configs(3);         % sample rate
                BW = param_configs(2);         % LoRa bandwidth
                SF = param_configs(1);         % LoRa spreading factor
            end
            datain = Utils.frame_amp_cut(datain,Fs,BW,SF);
            amp_sig = mean(abs(datain));
            amp_noise = amp_sig/10^(snr/20);
            dlen = length(datain);
            dataout  = datain + (amp_noise/sqrt(2) * randn([1 dlen]) + 1i*amp_noise/sqrt(2) * randn([1 dlen]));
        end
        
        function symb = gen_symbol(code_word,down,Fs,BW,SF)
            if nargin < 3 || isempty(Fs) || Fs < 0
                Fs = param_configs(3);         % default sample rate
                BW = param_configs(2);         % LoRa bandwidth
                SF = param_configs(1);         % LoRa spreading factor
            end
            org_Fs = Fs;
            if Fs < BW
                Fs = BW;
            end
            T = 0:1/Fs:2^SF/BW-1/Fs;       % time vector a chirp
            num_samp = Fs * 2^SF / BW;     % number of samples of a chirp
            
            % I/Q traces
            f0 = -BW/2; % start freq
            f1 = BW/2;  % end freq
            chirpI = chirp(T, f0, 2^SF/BW, f1, 'linear', 90);
            chirpQ = chirp(T, f0, 2^SF/BW, f1, 'linear', 0);
            baseline = complex(chirpI, chirpQ);
            if nargin >= 2 && down
                baseline = conj(baseline);
            end
            baseline = repmat(baseline,1,2);
            %             baseline =
            %             [baseline,
            %             baseline*exp(1i*(0))];
            clear chirpI chirpQ
            
            % Shift for
            % encoding
            offset = round((2^SF - code_word) / 2^SF * num_samp);
            symb = baseline(offset+(1:num_samp));
            
            if org_Fs ~= Fs
                overSamp = Fs/org_Fs;
                symb = symb(1:overSamp:end);
            end
        end
        
        function [real_sig,len] = gen_packet(codeArray, invert, Fs,BW,SF)
            %GENPAKCKET
            %generate raw
            %signal data
            %   Detailed
            %   explanation
            %   goes here
            if nargin < 3 || isempty(Fs) || Fs < 0
                Fs = param_configs(3);         % default sample rate
                BW = param_configs(2);         % LoRa bandwidth
                SF = param_configs(1);         % LoRa spreading factor
            end
            if nargin < 2 || isempty(invert)
                invert = 0;
            end
            
            codeChirp = Utils.gen_symbol(0,invert,Fs);
            syncChirp = Utils.gen_symbol(0,~invert,Fs);
            
            
            real_sig = repmat(codeChirp,1,8);
            real_sig = [real_sig,Utils.gen_symbol(2^SF-24,invert,Fs),Utils.gen_symbol(2^SF-32,invert,Fs)];
            real_sig = [real_sig,syncChirp,syncChirp,syncChirp(1:end/4)];
            for i = codeArray(1:end)
                %                 tmp_symb
                %                 =
                %                 Utils.gen_symbol(2^SF-i,invert,Fs);
                tmp_symb = Utils.gen_symbol(i,invert,Fs,BW,SF);
                real_sig = [real_sig,tmp_symb];
            end
            len = length(real_sig);
        end
        
        function y = spectrum(fig_switch,data,angle_switch,window,overlap,nfft,Fs)
            if nargin < 3
                angle_switch=0;
                window = 512;
                overlap = 256;
                nfft = 2048;
            end
            if isa(data,'double')
                data = data + 1e-10*1i;
            end
            
            % Param
            if nargin < 4
                Fs = param_configs(3);         % sample rate
            end
            BW = param_configs(2);         % LoRa bandwidth
            SF = param_configs(1);         % LoRa spreading factor
            num_samp = Fs * 2^SF / BW;     % number of samples of a chirp
            
            if Fs <= BW*2 || SF < 8
                window = 64;
                overlap = 60;
                nfft = 2048;
            end
            
            % STFT
            s = spectrogram(data,window,overlap,nfft,'yaxis');
            
            % Cut target
            % band
            if Fs > BW
                nvalid = floor(BW / Fs * nfft);
                % Add up
                y = s(1:nvalid,:);
                for i = 1:floor(nfft/nvalid)-1
                    y = y + s(nvalid*i+(1:nvalid),:);
                end
                y = [y(ceil(nvalid/2):end,:); y(1:floor(nvalid/2),:)];
            else
                y = zeros(floor(BW/Fs * nfft), size(s,2));
                
                base = round(size(y,1) /2 );
                h1 = ceil(nfft/2);
                h2 = nfft-h1;
                y(base+1:base+h1,:) = s(1:h1,:);
                y(base-h2+1:base,:) = s(h1+1:end,:);
                %                 y(flength/2+(0:floor(nfft/2)-1))
                %                 =
                %                 s(1:floor(nfft/2),:);
                %                 y(1:nfft,:)
                %                 =
                %                 s(1:nfft,:);
            end
            if fig_switch
                if angle_switch
                    imagesc([1 num_samp],[-BW/2 BW/2]/1e3,angle(y));
                    %                     surf(0:126,0:256,angle(y),'edgecolor','none');view(2)
                else
                    imagesc([1 num_samp],[-BW/2 BW/2]/1e3,abs(y)*20-40);
                    %                     surf(0:126,0:256,abs(y),'edgecolor','none');view(2)
                end
                %                 surf(0:num_samp-1,0:BW-1,abs(y),'edgecolor',
                %                 'none');view(2)
                set(gca,'YDir','normal');
                title('Spectrogram');
                xlabel('PHY sample #');
                ylabel('Frequency (kHz)');
                set (gcf,'position',[500,300,500,270] );
            end
        end
        
        function B = frame_amp_cut(datain,Fs,BW,SF)
            %AMPCUT
            %extract the
            %useful
            %signal based
            %on the
            %amplitude
            
            % parameters
            % Param
            if nargin < 3
                Fs = param_configs(3);         % sample rate
                BW = param_configs(2);         % LoRa bandwidth
                SF = param_configs(1);         % LoRa spreading factor
            end
            nsamp = Fs * 2^SF / BW;
            
            mwin = nsamp/2;
            A = movmean(abs(datain),mwin);
            B = datain(A >= max(A)/2);
        end
    end
end