%% Parameters
fs = 125;
win_size = 30;
win_ovlp = 7;
data_dir = 'datasets/vitaldb/_data/';
gen_path = 'passed_vitaldb_new.csv';
%% Get record names
elems = dir(fullfile(data_dir, '*.mat'));
numels = size(elems, 1);
c = cell(1, numels);
for i=1:numels
    c{i} = elems(i).name;
end
records = char(c{:});
%% loads
load('gendata/filter_coefs.mat');
load('gendata/filt_coef_beats.mat');
%% Create table and compute measures
passed_table = table;

parfor(r = 1:numels, 8)
    try
    record = records(r,:);

    win_proc = 0;
    win_count = 0;

    S = take_sigs(strcat(data_dir, record));
    
    abp_raw = downsample(S.abp_raw, 4);
    ppg_raw = downsample(S.ppg_raw, 4);

    abp_raw(isnan(abp_raw)) = 0;
    ppg_raw(isnan(ppg_raw)) = 0;

    abp_flt = filter(coefs, 1, abp_raw);
    ppg_flt = filter(coefs, 1, ppg_raw);
    abp_bts = filter(coefs_beats, 1, abp_raw);
    ppg_bts = filter(coefs_beats, 1, ppg_raw);

    siglen = min(length(abp_raw), length(ppg_raw)) / fs;

    win_step = win_size - win_ovlp;
    tot_wins = ceil((siglen - win_size)/win_step + 1);

    i = 1.0;
    while (i + win_size) <= (siglen - 1)
        
        if rem(win_proc, 100) == 0 || i >= (siglen-1) - win_size - 1
            fprintf("[Record %s (%d/%d)] - %d/%d windows, %d good\n",...
                record, r, numels, win_proc, tot_wins, win_count);
        end

        % segmentation
        start_pos = (i-1)*fs+1;
        end_pos = start_pos+win_size*fs;

        abp_mean = mean(abp_raw(start_pos:end_pos));
        ppg_mean = mean(ppg_raw(start_pos:end_pos));

        ppg_win = ppg_flt(start_pos:end_pos) / ppg_mean;
        abp_win = abp_flt(start_pos:end_pos) + abp_mean;

        abp_bts_win = abp_bts(start_pos:end_pos);
        ppg_bts_win = ppg_bts(start_pos:end_pos);

        if is_sig_periodic(abp_bts_win, fs) && is_sig_periodic(ppg_bts_win, fs)
            metrics_abp = get_metrics('ABP', abp_win, fs);
            metrics_ppg = get_metrics('PPG', ppg_win, fs);
    
            if ~isempty(metrics_abp) && ~isempty(metrics_ppg)
                metrics = [metrics_abp metrics_ppg];
                if check_window(metrics, win_size)
                    passed_row = table;
                    passed_row(1, ["RECORD", "START"]) = table(convertCharsToStrings(record), i);
                    passed_table = [passed_table; passed_row];
                    win_count = win_count + 1;
                end
            end
        end
        win_proc = win_proc + 1;
        i = i + win_size - win_ovlp;
    end
    catch le
        getReport(le)
    end
end
%%
writetable(passed_table, sprintf("generated/%s", gen_path));

