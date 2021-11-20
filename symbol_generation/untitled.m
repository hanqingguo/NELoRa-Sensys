sig = io_read_iq('input/pt1');
sig = Utils.add_noise(sig,-10);
sig = sig(1:round(end/3));
figure;
    plot(real(sig));
io_write_iq('input/pt2', sig);