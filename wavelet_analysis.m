%% Wavelet analysis
% This script extract a signal from one of the dataset, performs discrete
% wavelet transform on it and plots the results, to show which are the
% frequency bands that actually brings the signal's information content
%% Define signal and wavelet parameters
data_dir = '../dataset_dl/dataset';
rec_name = 'p000618-2117-12-10-19-00';
rec_start = 168616; % starting second
fs = 125; % sampling frequency [Hz]
fn = fs/2; % Nyquist frequency [Hz]
lvls = 10; % number of wavelet levels (number of detcoef vectors)
winsize = 10; % window size [s]
signame = 'abp'; % either abp or ppg
wavelet_name = 'db8'; % wavelet type
%% Load signal and clean missing values
sig_path = fullfile(data_dir, rec_name + '.mat');
load(sig_path, strcat(sig_name, '_raw'));
sig = eval(strcat(signame, '_raw'));

% remove NaN/missing samples (due to conversion from Python to Matlab) 
sig = rmmissing(sig);
% consider only fixed-size windows
p_start = (rec_start - 1)*fs + 1;
p_end = p_start + winsize*fs;
sig = sig(p_start:p_end);
%% Perform wavelet decomposition and check reconstruction
% wavelet decomposition
[c,l] = wavedec(sig,lvls,wavelet_name);
mra = get_wavelet_matrix(sig, lvls, wavelet_name);

% check difference between sum of components and original signal
% to ensure that reconstruction is performed correctly
mraSum = sum(mra,1);
max(abs(mraSum-sig))
%% Plot projection on all components (vertically-stacked)
fig = plt_wavelet_projs(mra, fs);
% save to PDF (for LaTeX) and SVG (for Powerpoint or other tools)
save_graphics(fig, strcat('images/wavelet_levels_', signame));
%% Plot single pair plots signal-vs-component
% Since there will be a lot of figures, the function plt_signal_vs_proj
% will only save them to files without showing them on screen
for k = 1:lvls
    fig = plt_signal_vs_proj(sig, fs, mra, 'd', k);
    save_graphics(fig, sprintf('images/signaleeee_vs_wvdetail_%d', k));
end
%% Plot original signal vs sum of slice 6 (heartbeat) and slice 5 (notch)
% This part has been made to show how the two bands contains what for my 
% thesis was the desired information, namely heartbeats and dicrotic
% notches. If your study is about a different information content, 
% change the mra indices in the sum below.
%
% I also added the median to keep the original range of amplitude values.
figure
ax = gca;
signals = [sig; mra(6,:)+mra(5,:)+mean(abp_raw)];
colors = ['blue', 'red'];
names = ['Original signal', 'Sum of slices 5 and 6'];
setup_signals_plot(ax, signals, fs, names, colors);
title('Band 5 added to band 6 makes the dicrotic notches more prominent')
save_graphics(gcf, 'images/signal_vs_sumof_5_6');