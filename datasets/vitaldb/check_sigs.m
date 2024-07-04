%% Define signal and wavelet parameters
data_dir = "./vitaldb/data";
rec_name = "5290";
rec_start = 1; % starting second
fs = 125; % sampling frequency [Hz]
fn = fs/2; % Nyquist frequency [Hz]
lvls = 10; % number of wavelet levels (number of detcoef vectors)
%% Load signal and clean missing values
sig_path = fullfile(data_dir, rec_name + ".mat");
load(sig_path, "ppg_raw");
mysig = ppg_raw;
mysig = downsample(mysig, 4);
mysig(isnan(mysig)) = 0;
% consider only 10 seconds window
p_start = (rec_start - 1)*fs + 1;
p_end = p_start + 60*fs;
mysig = mysig(p_start:p_end);
%%
siglen = length(mysig);
t = 0:1/fs:siglen/fs-1/fs;
figure
hold on
grid on
plot(t, mysig, 'LineWidth',1)
hold off
%% Perform wavelet decomposition and check reconstruction
% wavelet decomposition
[c,l] = wavedec(mysig,lvls,'db8');
mra = get_wavelet_matrix(mysig, lvls, "db8");

% check difference between sum of components and original signal
% to ensure that reconstruction is performed correctly
mraSum = sum(mra,1);
max(abs(mraSum-mysig))
%% Plot projection on all components (vertically-stacked)
fig = plt_wavelet_projs(mra, fs);
% save to PDF with vectorial graphics
% optimal for presentation and embedding in LaTeX
save_graphics(fig, "images/wavelet_levels_1");
%% Plot single pair plots signal-vs-component
%{
for k = 1:lvls
    fig = plt_signal_vs_proj(mysig, fs, mra, 'd', k);
    save_graphics(fig, sprintf("images/signaleeee_vs_wvdetail_%d", k));
end
%}
%% Plot original signal vs sum of slice 6 (heartbeat) and slice 5 (notch)

figure
ax = gca;
signals = [mysig; mra(4,:)+mra(3,:)+mra(5,:)];
colors = ["blue", "red"];
names = ["Original signal", "Sum of slices 5 and 6"];
setup_signals_plot(ax, signals, fs, names, colors);
title("Band 5 added to band 6 makes the dicrotic notches more prominent")
save_graphics(gcf, "images/signal_vs_sumof_5_6");