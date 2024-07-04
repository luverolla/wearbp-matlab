%% Parameters
fs = 125;
win_size = 60;
win_ovlp = 15;
data_dir = '../dataset_dl/dataset/';
gen_path = 'passed_mimic3.csv';
%% Get record names
elems = dir(fullfile(data_dir, '*.mat'));
numels = size(elems, 1);
c = cell(1, numels);
for i=1:numels
    c{i} = elems(i).name;
end
records = char(c{:});
%% Create table and compute measures
passed_table = table;

parfor(r = 1:numels, 8)
    try
    record = records(r,:);
    win_proc = 0;
    win_count = 0;
    fprintf("[Record %s (%d/%d)] - start\n", record, r, numels);
    S = take_sigs(strcat(data_dir, record));
   
    abp_raw = S.abp_raw;
    ppg_raw = S.ppg_raw;

    abp_raw(isnan(abp_raw)) = 0;
    ppg_raw(isnan(ppg_raw)) = 0;

    abp_flt = filter(coefs, 1, abp_raw);
    ppg_flt = filter(coefs, 1, ppg_raw);

    siglen = min(length(abp_raw), length(ppg_raw)) / fs;

    win_step = win_size - win_ovlp;
    tot_wins = ceil((siglen - win_size)/win_step + 1);

    i = 1.0;
    while (i + win_size) <= (siglen - 1)

        perc_win = 100 * win_proc / tot_wins;
        
        if rem(win_proc, 100) == 0
            fprintf("[Record %s (%d/%d)] - %d/%d windows, %d good\n",...
                record, r, numels, win_proc, tot_wins, win_count);
        end

        % segmentation
        start_pos = (i-1)*fs+1;
        end_pos = start_pos+win_size*fs;

        abp_mean = mean(abp_raw(start_pos:end_pos));
        ppg_mean = mean(ppg_raw(start_pos:end_pos));

        ppg_win = ppg_flt(start_pos:end_pos);
        abp_win = abp_flt(start_pos:end_pos) + abp_mean;
    
        % individual metrics
        curr_row = table;
        abp_metrics = get_metrics("ABP", abp_win, fs);
        ppg_metrics = get_metrics("PPG", ppg_win, fs);

        if isempty(abp_metrics) || isempty(ppg_metrics)
            win_proc = win_proc + 1;
            i = i + win_size - win_ovlp;
            continue;
        end

        curr_row = [curr_row abp_metrics ppg_metrics];
        result = check_window(curr_row, win_size);
        if result
            passed_row = table;
            passed_row(1, ["RECORD", "START"]) = table(convertCharsToStrings(record), i);
            passed_table = [passed_table; passed_row];
            win_count = win_count + 1;
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

