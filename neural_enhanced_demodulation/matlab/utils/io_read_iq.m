function [iq_stream,iq_len] = io_read_iq(filename, samples)
    %RFILE read row signal from files
    %   [Data,N] = rfile(filename) returns the signal array and the number of samples
    %   [Data,N] = rfile(filename,samples) returns the first samples signal points
    fileID = fopen(filename, 'r');
    if fileID == -1, error('Cannot open file: %s', filename); end
    % gr_complex<float> is composed of two float32
    format = 'float';
    row = fread(fileID, Inf, format);
    fclose(fileID);

    if nargin < 2 || isempty(samples)
        iq_len = floor(size(row,1)/2);
    else
        iq_len = min(samples,floor(size(row,1)/2));
    end
    iq_stream = zeros(1,iq_len);
    iq_stream(1:iq_len) = row(1:2:2*iq_len) + row(2:2:2*iq_len)*1i;
end