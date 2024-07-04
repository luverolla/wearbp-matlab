%% Define signal and wavelet parameters
data_dir = "../dataset_dl/dataset";
rec_name = "p000618-2117-12-10-19-00";
rec_start = 168616; % starting second
fs = 125; % sampling frequency [Hz]
fn = fs/2; % Nyquist frequency [Hz]
lvls = 10; % number of wavelet levels (number of detcoef vectors)
%% Load signal and clean missing values
sig_path = fullfile(data_dir, rec_name + ".mat");
load(sig_path, "abp_raw");

% remove NaN/missing samples (due to conversion from Python to Matlab) 
abp_raw = rmmissing(abp_raw);
% consider only 10 seconds window
p_start = (rec_start - 1)*fs + 1;
p_end = p_start + 60*fs;
abp_raw = abp_raw(p_start:p_end);
%% Perform wavelet decomposition and check reconstruction
% wavelet decomposition
[c,l] = wavedec(abp_raw,10,'db8');
mra = get_wavelet_matrix(abp_raw, 10, "db8");

% check difference between sum of components and original signal
% to ensure that reconstruction is performed correctly
mraSum = sum(mra,1);
max(abs(mraSum-abp_raw))
%% Plot projection on all components (vertically-stacked)
fig = plt_wavelet_projs(mra, fs);
% save to PDF with vectorial graphics
% optimal for presentation and embedding in LaTeX
save_graphics(fig, "images/wavelet_levels_1");
%% Plot single pair plots signal-vs-component
for k = 1:lvls
    fig = plt_signal_vs_proj(abp_raw, fs, mra, 'd', k);
    save_graphics(fig, sprintf("images/signaleeee_vs_wvdetail_%d", k));
end
%% Plot spectrogram
fig = plt_spectrogram(fs, mra);
save_graphics(fig, "images/spectrogram_1");
%% Plot original signal vs sum of slice 6 (heartbeat) and slice 5 (notch)
figure
ax = gca;
signals = [abp_raw; mra(6,:)+mra(5,:)+mean(abp_raw)];
colors = ["blue", "red"];
names = ["Original signal", "Sum of slices 5 and 6"];
setup_signals_plot(ax, signals, fs, names, colors);
title("Band 5 added to band 6 makes the dicrotic notches more prominent")
save_graphics(gcf, "images/signal_vs_sumof_5_6");