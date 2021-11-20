classdef Utils < handle 

    methods (Static = true)  
        function dataout = add_noise(datain,snr)
%             datain = frame_amp_cut(datain);
            amp_sig = mean(abs(datain));
            amp_noise = amp_sig/10^(snr/20);
            dlen = length(datain);
            dataout  = datain + (amp_noise/sqrt(2) * randn([1 dlen]) + 1i*amp_noise/sqrt(2) * randn([1 dlen]));
        end
        
        function symb = gen_symbol(code_word,down,Fs)
            if nargin < 3 || isempty(Fs) || Fs < 0
                Fs = param_configs(3);         % default sample rate
            end      
            BW = param_configs(2);         % LoRa bandwidth
            SF = param_configs(1);         % LoRa spreading factor
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
%             baseline = [baseline, baseline*exp(1i*(0))];
            clear chirpI chirpQ
            
            % Shift for encoding
            offset = round((2^SF - code_word) / 2^SF * num_samp);
            symb = baseline(offset+(1:num_samp));
%             symb = symb * exp(-1i*angle(symb(1)));
                
            if org_Fs ~= Fs
                overSamp = Fs/org_Fs;
                symb = symb(1:overSamp:end);
            end
        end
        
        function [real_sig,len] = gen_packet(codeArray, invert, Fs)
            %GENPAKCKET generate raw signal data
            %   Detailed explanation goes here
            if nargin < 3 || isempty(Fs) || Fs < 0
                Fs = param_configs(3);         % default sample rate
            end    
            if nargin < 2 || isempty(invert)
                invert = 0;
            end
            BW = param_configs(2);         % LoRa bandwidth
            SF = param_configs(1);         % LoRa spreading factor

            codeChirp = Utils.gen_symbol(0,invert,Fs);
            syncChirp = Utils.gen_symbol(0,~invert,Fs);
            
            
            real_sig = repmat(codeChirp,1,8);
            real_sig = [real_sig,Utils.gen_symbol(2^SF-24,invert,Fs),Utils.gen_symbol(2^SF-32,invert,Fs)];
            real_sig = [real_sig,syncChirp,syncChirp,syncChirp(1:end/4)];
            for i = codeArray(1:end)
                tmp_symb = Utils.gen_symbol(2^SF-i,invert,Fs);
                real_sig = [real_sig,tmp_symb];
            end
            len = length(real_sig);
        end
        
        function y = spectrum(data,window,overlap,nfft,Fs)
            if nargin < 3
                window = 512;
                overlap = 256;
                nfft = 2048;
            end
            if isa(data,'double')
                data = data + 1e-10*1i;
            end
            
            % Param
            if nargin < 5
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
            
            % Cut target band
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
%                 y(flength/2+(0:floor(nfft/2)-1)) = s(1:floor(nfft/2),:);
%                 y(1:nfft,:) = s(1:nfft,:);
            end
            
                imagesc([1 num_samp],[-BW/2 BW/2]/1e3,abs(y)*20-40);
                set(gca,'YDir','normal');
%                 title('Spectrogram');
                xlabel('PHY sample #');
                ylabel('Frequency (kHz)');
                set (gcf,'position',[500,300,500,270] );
        end
        
        function [data,len] = mixPkt(pkt1, pkt2)
            len = max(length(pkt1),length(pkt2));
            if size(pkt1,2) < len
                pkt1 = [pkt1,zeros(1,len-length(pkt1))];
            else
                pkt2 = [pkt2,zeros(1,len-length(pkt2))];
            end
            data = pkt1 + pkt2;
        end
        
        function fg = showfft(f_idx, ft)
%             figure;
                fg = plot(f_idx, ft, 'k');
                set(fg,'Linewidth',2);
                ylabel('Magnitude');
                xlabel('#FFT bin');
                grid on;
                set(gca, 'XMinorGrid','on');
                set(gca, 'YMinorGrid','on');
                xlim([min(f_idx) max(f_idx)]);
                
                set(gcf, 'position', [600 500 500 320]);
                set(gca, 'FontSize', 18, 'FontName', 'Arial', 'FontWeight', 'normal');

                
                [ma, I] = max(abs(ft));
                hold on
%                 plot(f_idx(I), ma, 'p', 'MarkerSize', 16, 'LineWidth', 1.2, 'color', '#EE2C2C');
                if I > length(ft) / 2
                    xlb = f_idx(I) - 35;
                else
                    xlb = f_idx(I) + 5;
                end
%                 text(xlb, ma*1.1 ,['value = ',num2str(round(f_idx(I)*10)/10)] ,'FontSize',14);
                ylim([0 ma*1.2]);
                
                box on;
                grid on;
        end
        
        function symbols = get_symbols(bytes)
            Fs = param_configs(3);         % sample rate        
            BW = param_configs(2);         % LoRa bandwidth
            SF = param_configs(1);         % LoRa spreading factor
            phy = LoRaPHY(SF, BW, Fs);
            phy.has_header = 1;         % explicit header mode
            phy.cr = 1;                 % code rate = 4/8 (1:4/5 2:4/6 3:4/7 4:4/8)
            phy.crc = 1;                % enable payload CRC checksum
            phy.preamble_len = 8;       % preamble: 8 basic upchirps
            symbols = phy.encode(bytes');
        end
        
        function R = powerDetect(data, window, thresh)
            %AMPCUT extract the useful signal based on the amplitude
            %   Detailed explanation goes here 
            A = movmean(abs(data),window);
            if length(A) < 5
                R = false;
                return;
            end
            R = sum(A) > thresh*numel(A);
%             res = A(round(end/5):end) < thresh;
%             R = ~sum(res);
        end
        
        function d1 = genZeroFrame(len)
            Fs = param_configs(3);         % sample rate        
            BW = param_configs(2);         % LoRa bandwidth
            SF = param_configs(1);         % LoRa spreading factor

            phy = LoRaPHY(SF, BW, Fs);
            phy.has_header = 1;         % explicit header mode
            phy.cr = 1;                 % code rate = 4/8 (1:4/5 2:4/6 3:4/7 4:4/8)
            phy.crc = 1;                % enable payload CRC checksum
            phy.preamble_len = 8;       % preamble: 8 basic upchirps
            % symbols = phy.encode(bytes');

            d1 = phy.symbols_to_bytes(ones(len,1));
            fprintf("bytes d1:\n");
            disp(d1'); 
        end
    end
end