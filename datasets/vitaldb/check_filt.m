data_dir = "vitaldb/data";
rec_name = "190";
rec_start = 1; % starting second
fs = 125; % sampling frequency [Hz]

load(fullfile(data_dir, rec_name + ".mat"))
ppg_raw = downsample(ppg_raw, 4);
ppg_flt = filter(coefs, 1, ppg_raw);

start_pos = (rec_start-1)*fs + 1;
end_pos = start_pos+60*fs;

ppg_win = ppg_flt(start_pos:end_pos);

figure
hold on
grid on
plot(ppg_win)