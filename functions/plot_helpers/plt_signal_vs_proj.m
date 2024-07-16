function [fig] = plt_signal_vs_proj(sig, fs, wmat, type, k)
%PLOT_SIGNAL_VS_PROJ Plots signal and its k-th wavelet band projection
%   This function creates a figure and plots a given signal and its k-th
%   projection on a band resulting from a wavelet transform.
%   
%   This function is independent on the particular wavelet used, and the
%   result of GET_WAVELET_MATRIX must be passed as the argument wmat
figure('Visible','off'); % only save to file
hold on
grid on

basetitle = "PPG signal and projection onto %s subspace (%.2f-%.2f) Hz";
t = 0:1/fs:length(sig)/fs-1/fs;
f_nyq = fs / 2;

plot(t, wmat(k,:), 'Color','r', 'LineWidth',1);
plot(t, sig, 'Color','b', 'LineWidth',1);
legend("Wavelet projection", "Original signal", "FontSize", 11);
xlabel("Time [s]");
ylabel("Value [NU]");

if type == 'a'
    high = f_nyq ./ (2.^lvls);
    figtitle = sprintf(basetitle, "approximation", 0, high);
elseif type == 'd'
    low = f_nyq ./ (2.^k);
    high = f_nyq ./ (2.^(k-1));
    title_part = sprintf("detail %d", k);
    figtitle = sprintf(basetitle, title_part, low, high);
end

title(figtitle);
fig = gcf;
end

