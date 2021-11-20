function par = param_configs(p_id)

    % LoRa PHY transmitting parameters
    LORA_SF = 12;            % LoRa spreading factor
    LORA_BW = 125e3;        % LoRa bandwidth
    
    % Receiving device parameters
    RX_Sampl_Rate = 125e3*8;  % recerver's sampling rate 
    Dn_Samp_Factor = 8;       % down sampling factor
    DEBUG = false;
    
    % LoRa frame parameters
    FRM_PREAMBLE = 8;       % number of chirps in preamble
    FRM_SYNC = 2;           % number of up chirps for sync words
    FRM_SFD = 2.25;         % number of down chirps in SFD
    FRM_PAYLOAD = 58;       % number of payload symbols in the frame
    
    % freq track detecting configurations
    TRK_FFT_factor = 1;         % scale factor for FFT window size
    
    TRK_PWR_THRESHOLD = 0;      % (!!not use) threshold of FFT power for freq track detecting
    TRK_SPAN_RATIO = 0.6;       % threshold of track spanning ratio in ftrack detecting range
    TRK_LEN_THRESHOLD = floor(2*TRK_SPAN_RATIO*2^LORA_SF);    
                                % threshold of freq. track length
    SYNC_TRK_LEN_SCALE_FACTOR = 0.7;
                                % scale factor of sync word tracks, in
                                % relative to TRK_SPAN_RATIO
                                
    TRK_PREAMBLE_MIN = 6;       % minimum number of chirps for preamble detection
    TRK_PREAMBLE_MAX = 10;      % maximum number of chirps for preamble detection
    
    % freq track duplication detecting
    TRK_CLUSTER_FREQ_TOLERANCE = 2;     % the tolerance of fft bin width for freq track clusters 
    TRK_CLUSTER_EDGE_TOLERANCE = 4;     % the tolerance of symbol edge offset
    TRK_CLUSTER_OVERLAP_RATIO = 0.6;    % threshold of track overlapping for duplication detecting
    
    % preamble edge detecting
    EDGE_CORRELATION_THRESHOLD = 0.8;   % threshold of correlation coefficient for edge detecting
    EDGE_SEARCH_RANGE = 2;              % ranges (in number of chirps) for edge searching  
    EDGE_ERROR_TOLERANCE = -floor(0.01*2^(LORA_SF));     
                                        % the max tolerable error on edge detecting
    
    % frame header (sync words) identifying
    COLLIDE_HEADER_MODE = 1;            % enable recovery from header sync words collision (1) or not (0)
    
    % ftrack classifying/grouping
    FTRK_GROUP_ALPHA = 0.8;             % weight of track len (in relative to track power) for ftrack_grouping
    
    % !!automatic threshold detection
    AUTO_FBIN_WIN = 2^(LORA_SF-0);      % fft_bin window for adaptive threshold detecting
    AUTO_TIME_WIN = 40 * 2^LORA_SF;     % time window for threshold detecting
    AUTO_PEAK_SAMPLE_STEP = 2^(LORA_SF-4);          
                                        % peak power sampling steps, 
                                        % 2^4 samples every chirp len
    
    AUTO_HIGH_PEAK_RATIO = 0.7;         % ratio of higher peaks for power threshold detecting
    AUTO_PEAK_PWR_RATIO = 0.3;          % ratio of power in the target peak
    
    AUTO_PEAK_DIST = 2;                 % min distance between peaks for peak auto detecting
    AUTO_NOISE_FLOOR = 1.0;             % noise floor power
    
    % coarse locations of preamble in a signal segment
    PREAMBLE_ENDING_LOC = 0; %30 * 2^LORA_SF;   % the position after which preamble cannot appear 
                                            % at most 20 symbols
                                            % when = 0, do not use this
                                            % parameter
    
    switch(p_id)
        case 1,
            par = LORA_SF;
        case 2,
            par = LORA_BW;
            
        case 3,
            par = RX_Sampl_Rate;
            
        case 4,
            par = Dn_Samp_Factor;
        case 5,
            par = DEBUG;
        case 6,
            par = TRK_LEN_THRESHOLD;
        case 7,
            par = TRK_PREAMBLE_MIN;
            
        case 8,
            par = FRM_PREAMBLE;
        case 9,
            par = FRM_SYNC;
        case 10,
            par = FRM_SFD;
        case 11,
            par = FRM_PAYLOAD;
            
        case 12,
            par = TRK_PREAMBLE_MAX;
            
        case 13,
            par = FRM_SYNC_WORD_FREQ;
            
        case 14,
            par = TRK_CLUSTER_FREQ_TOLERANCE;
        case 15,
            par = TRK_SPAN_RATIO;
        case 16,
            par = TRK_CLUSTER_EDGE_TOLERANCE;
        case 17,
            par = TRK_CLUSTER_OVERLAP_RATIO;
            
        case 18,
            par = EDGE_CORRELATION_THRESHOLD;
        case 19,
            par = EDGE_SEARCH_RANGE;
            
        case 20,
            par = COLLIDE_HEADER_MODE;
            
        case 21,
            par = FTRK_GROUP_ALPHA;
            
        case 22,
            par = AUTO_FBIN_WIN;
        case 23,
            par = AUTO_TIME_WIN;
        case 24,
            par = AUTO_PEAK_SAMPLE_STEP;
        case 25,
            par = AUTO_HIGH_PEAK_RATIO;
        case 26,
            par = AUTO_PEAK_PWR_RATIO;
        case 27,
            par = AUTO_PEAK_DIST;
        case 28,
            par = AUTO_NOISE_FLOOR;
            
        case 29,
            par = EDGE_ERROR_TOLERANCE;
            
        case 30,
            par = PREAMBLE_ENDING_LOC;
            
        case 31,
            par = SYNC_TRK_LEN_SCALE_FACTOR;
        otherwise,
    end
end