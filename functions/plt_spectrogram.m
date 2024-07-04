function [fig] = plt_spectrogram(fs, wmat)
%PLT_SPECTROGRAM Plot spectrogram (time-frequency representation)
%   Time (in seconds) is on x-axis and Frequency (in Herz) on y-axis
%   with logarithmic scale
figure
grid off

siglen = size(wmat, 2);
level = size(wmat, 1) - 1;

t = 0:1/fs:siglen/fs-1/fs;
f = [1,level+1];
f_nyq = fs / 2;

for i = 1:level
    f(i) = f_nyq ./ (2.^i);
end
% as subtraend I cannot put zero because, on log scale, is undefined
% so, I just put a smaller value than minuend
f(level+1) = 0.5*f(level);

% the plot is reversed (the lower frequency are at the top),
% so both the matrix and the y-axis coordinates needs to be reversed
f = flip(f);
matrix = flip(wmat, 1);

s = pcolor(t,f,abs(matrix));
s.EdgeColor = 'none'; % remove the ugly thin black lines near bands
colorbar;
yscale('log')
title("Spectrogram")
xlabel("Time [s]")
ylabel("Frequency [Hz]")
fig = gcf;
end

