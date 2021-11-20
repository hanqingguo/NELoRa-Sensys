function io_write_iq(filename, data)
    % write binary file
    fid = fopen(filename, 'wb');
    if fid == -1, error('Cannot open file: %s', filename); end
    % gr_complex<float> is composed of two float32
%     fid=fopen(filename,'wb');
    for idx = 1:size(data,2)
        real_part = real(data(1,idx));
        im_part = imag(data(1,idx));
        fwrite(fid,single(real_part),'single');
        fwrite(fid,single(im_part),'single');
    end
    disp('File Write Finish!');
    fclose(fid);
end