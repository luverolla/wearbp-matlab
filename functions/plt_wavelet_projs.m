function [fig] = plt_wavelet_projs(wmat, fs)
%PLT_WAVELET_PROJS Plots wavelet projections of signal by given matrix
%   The matrix wmat is obtained by calling get_wavelet_matrix
%   The parameter fs [Hz] is the sampling frequency of the original signal

level = size(wmat, 1) - 1;
siglen = size(wmat, 2);
f_nyq = fs / 2;

figure
t = 0:1/fs:siglen/fs-1/fs;
tcl = tiledlayout(level+1, 1, 'Padding', 'none', 'TileSpacing', 'compact');
for i=1:level
    nexttile
    low = f_nyq ./ (2.^i);
    high = f_nyq ./ (2.^(i-1));
    plot(t, wmat(i,:), 'LineWidth',1);
    title(sprintf("detail %d (%.2f-%.2f Hz)", i, low, high));
end
nexttile
plot(t, wmat(i,:), 'LineWidth',1);
high = f_nyq ./ 2^level;
title(sprintf("approx (0-%.2f)", high));
title(tcl, "Projections of PPG signal onto detail and approximation subspaces");
xlabel(tcl, "Time [s]")
fig = gcf;
end

