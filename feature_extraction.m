%% parameters
fs = 125;
win_size = 60;
passed_path = 'passed_mimic3.csv';
gen_path = 'features_mimic3.csv';
%%
feature_table = table;
prevOutcome = readtable(sprintf('generated/%s',passed_path));
ct = parallel.pool.Constant(prevOutcome);

records = unique(prevOutcome.RECORD);
n_recs = numel(records);
parfor(r=1:size(records, 1),8)
    t = ct.Value;
    record = records(r,:);

    record_path = sprintf('../dataset_dl/dataset/%s', char(record));
    S = take_sigs(record_path);
   
    abp_raw = S.abp_raw;
    ppg_raw = S.ppg_raw;

    abp_raw(isnan(abp_raw)) = 0;
    ppg_raw(isnan(ppg_raw)) = 0;

    abp_flt = filter(coefs, 1, abp_raw);
    ppg_flt = filter(coefs, 1, ppg_raw);

    occs = t(strcmp(t.RECORD, record),:);
    win_proc = 0;
    win_disc = 0;

    fprintf("[Record %s (%d/%d)] - start\n", char(record), r, n_recs);
    for oc = 1:size(occs, 1)
        try
        
        if win_proc > 0 && rem(win_proc, 10) == 0
            fprintf("[Record %s (%d/%d)] - %d/%d windows\n",...
                char(record), r, n_recs, win_proc, size(occs, 1));
        end
    
        start = occs{oc, 'START'};
        fr = table;
        fr{1, 'INFO_RECORD'} = record;
        fr{1, 'INFO_START'} = start;

        chunks = split(record, '-', 1);
        fr{1, 'INFO_PATIENT'} = chunks(1,:);

        start_pos = (start-1)*fs+1;
        end_pos = start_pos+win_size*fs;

        abp_mean = mean(abp_raw(start_pos:end_pos));
        ppg_mean = mean(ppg_raw(start_pos:end_pos));

        abp_win = abp_flt(start_pos:end_pos) + abp_mean;
        ppg_win = ppg_flt(start_pos:end_pos) / ppg_mean;

        abp_norm = normalize(abp_win, 'range');
        ppg_norm = normalize(ppg_win, 'range');
    
        [abp_pks, abp_vls, ~, ~] = find_pv_thresh(abp_norm, 0.65);
        [ppg_st_pks, ppg_vls, ppg_dt_pks, ppg_notches] = find_pv_thresh(ppg_norm);

        % ground truths
        fr{1, 'GT_SBP'} = prctile(abp_win(abp_pks), 50);
        fr{1, 'GT_DBP'} = prctile(abp_win(abp_vls), 50);

        % === TIME FEATURES ===
        % systolic peak
        acc = [];
        for k=1:length(ppg_vls)-1
            st_peak = next_fiducial(ppg_vls(k), ppg_vls(k+1), ppg_st_pks);
            if ~isempty(st_peak)
                acc = [acc ppg_win(st_peak)-ppg_win(ppg_vls(k))];
            end
        end
        fr{1, 'PPG_X'} = prctile(acc, 50);

        % diastolic peak
        acc = [];
        for k=1:length(ppg_vls)-1
            dt_peak = next_fiducial(ppg_vls(k), ppg_vls(k+1), ppg_dt_pks);
            if ~isempty(dt_peak)
                acc = [acc ppg_win(dt_peak)-ppg_win(ppg_vls(k))];
            end
        end
        fr{1, 'PPG_Y'} = prctile(acc, 50);

        % notch height
        acc = [];
        for k=1:length(ppg_vls)-1
            notch = next_fiducial(ppg_vls(k), ppg_vls(k+1), ppg_notches);
            if ~isempty(notch)
                acc = [acc ppg_win(notch)-ppg_win(ppg_vls(k))];
            end
        end
        fr{1, 'PPG_Z'} = prctile(acc, 50);

        % systolic peak time
        acc = [];
        for k=1:length(ppg_vls)-1
            st_peak = next_fiducial(ppg_vls(k), ppg_vls(k+1), ppg_st_pks);
            acc = [acc (st_peak - ppg_vls(k))*(1000/fs)];
        end
        fr{1, 'PPG_T1'} = prctile(acc, 50);

        % diastolic peak time
        acc = [];
        for k=1:length(ppg_vls)-1
            dt_peak = next_fiducial(ppg_vls(k), ppg_vls(k+1), ppg_dt_pks);
            acc = [acc (dt_peak - ppg_vls(k))*(1000/fs)];
        end
        fr{1, 'PPG_T3'} = prctile(acc, 50);

        % notch time
        acc = [];
        for k=1:length(ppg_vls)-1
            notch = next_fiducial(ppg_vls(k), ppg_vls(k+1), ppg_notches);
            if ~isempty(notch)
                acc = [acc (notch - ppg_vls(k))*(1000/fs)];
            end
        end
        fr{1, 'PPG_T2'} = prctile(acc, 50);

        % deltaT (distance between diastolic and systolic peak)  
        acc = [];
        for k=1:length(ppg_st_pks)-1
            dt_pk = next_fiducial(ppg_st_pks(k), ppg_st_pks(k+1), ppg_dt_pks);
            if ~isempty(dt_pk)
                acc = [acc (dt_pk - ppg_st_pks(k))*(1000/fs)];
            end
        end
        fr{1, 'PPG_DT'} = prctile(acc, 50);
        
        % pulse interval
        acc = zeros(size(ppg_vls)-1);
        for k=1:length(ppg_vls)-1
            acc(k) = (ppg_vls(k+1) - ppg_vls(k))*(1000/fs);
        end
        fr{1, 'PPG_TPI'} = prctile(acc, 50);

        % peak-to-peak interval
        acc = zeros(size(ppg_st_pks)-1);
        for k=1:length(ppg_st_pks)-1
            acc(k) = (ppg_st_pks(k+1) - ppg_st_pks(k))*(1000/fs);
        end
        fr{1, 'PPG_TPP'} = prctile(acc, 50);

        fr{1, 'PPG_HR'} = 60 / (fr{1, 'PPG_TPP'}/1000);
        % heart rate variability
        fr{1, 'PPG_HRV'} = std(60 ./ (acc./1000));

        % inflection point area
        acc = [];
        for k=1:length(ppg_vls)-1
            notch = next_fiducial(ppg_vls(k), ppg_vls(k+1), ppg_notches);
            if ~isempty(notch)
                part_1 = ppg_vls(k):notch-1;
                part_2 = notch:ppg_vls(k+1)-1;
                area_1 = sum(abs(ppg_win(part_1+1) - ppg_win(part_1)));
                area_2 = sum(abs(ppg_win(part_2+1) - ppg_win(part_2)));
                acc = [acc (area_1 / area_2)];
            end
        end
        fr{1, 'PPG_IPA'} = prctile(acc, 50);
    
        % augmentation index
        fr{1, 'PPG_AGI'} = ...
            fr{1, 'PPG_Y'} /...
            fr{1, 'PPG_X'};

        % alternative augmentation index
        fr{1, 'PPG_ALTAGI'} = ...
            (fr{1, 'PPG_X'} - ...
             fr{1, 'PPG_Y'}) / ...
             fr{1, 'PPG_X'};
        

        % systolic output curve
        fr{1, 'PPG_SOC'} = ...
            fr{1, 'PPG_T1'} / ...
            fr{1, 'PPG_X'};

        % diastolic downward curve
        fr{1, 'PPG_DDC'} = ...
            fr{1, 'PPG_Y'} / ...
            (fr{1, 'PPG_TPI'} - ...
             fr{1, 'PPG_T2'});
        

        % sistolic over peak-to-peak time
        fr{1, 'PPG_T1_TPP'} = ...
            fr{1, 'PPG_T1'} / ...
            fr{1, 'PPG_TPP'};

        % notch over peak-to-peak time
        fr{1, 'PPG_T2_TPP'} = ...
            fr{1, 'PPG_T2'} / ...
            fr{1, 'PPG_TPP'};

        % diastolic over peak-to-peak time
        fr{1, 'PPG_T3_TPP'} = ...
            fr{1, 'PPG_T3'} / ...
            fr{1, 'PPG_TPP'};

        % DeltaT over peak-to-peak time
        fr{1, 'PPG_DT_TPP'} = ...
            fr{1, 'PPG_DT'} / ...
            fr{1, 'PPG_TPP'};

        % notch over systolic peak height
        fr{1, 'PPG_Z_X'} = ...
            fr{1, 'PPG_Z'} / ...
            fr{1, 'PPG_X'};

        % notch time/height ratio
        fr{1, 'PPG_T2_Z'} = ...
            fr{1, 'PPG_T2'} / ...
            fr{1, 'PPG_Z'};

        % diastolic time/height ratio
        fr{1, 'PPG_T3_Y'} = ...
            fr{1, 'PPG_T3'} / ...
            fr{1, 'PPG_Y'};
        

        % systolic height over difference of pulse interval and 
        % systolic time
        fr{1, 'PPG_X_TPI_T1'} = ...
            fr{1, 'PPG_X'} / ...
            (fr{1, 'PPG_TPI'} - ...
             fr{1, 'PPG_T1'});

        % notch height over difference of pulse interval and 
        % notch time
        fr{1, 'PPG_Z_TPI_T2'} = ...
            fr{1, 'PPG_Z'} / ...
            (fr{1, 'PPG_TPI'} - ...
             fr{1, 'PPG_T2'});

        % === WIDTH FEATURES ===
        % pulse width at 25%
        acc = [];
        for k=1:length(ppg_vls)-1
            pulse = ppg_win(ppg_vls(k):ppg_vls(k+1));
            pw25 = pulse_width_k(pulse, 25, ppg_win(ppg_vls(k)));
            if pw25 > 0
                acc = [acc pw25*(1000/fs)];
            end
        end
        fr{1, 'PPG_W25'} = prctile(acc, 50);

        % pulse width at 75%
        acc = [];
        for k=1:length(ppg_vls)-1
            pulse = ppg_win(ppg_vls(k):ppg_vls(k+1));
            pw75 = pulse_width_k(pulse, 75, ppg_win(ppg_vls(k)));
            if pw75 > 0
                acc = [acc pw75*(1000/fs)];
            end
        end
        fr{1, 'PPG_W75'} = prctile(acc, 50);

        % pulse width 50%
        acc = [];
        for k=1:length(ppg_vls)-1
            pulse = ppg_win(ppg_vls(k):ppg_vls(k+1));
            pw50 = pulse_width_k(pulse, 50, ppg_win(ppg_vls(k)));
            if pw50 > 0
                acc = [acc pw50*(1000/fs)];
            end
        end
        fr{1, 'PPG_W50'} = prctile(acc, 50);

        % w25 related ratios
        fr{1, 'PPG_W25_T1'} = ...
            fr{1, 'PPG_W25'} / fr{1, 'PPG_T1'};
        fr{1, 'PPG_W25_T2'} = ...
            fr{1, 'PPG_W25'} / fr{1, 'PPG_T2'};
        fr{1, 'PPG_W25_T3'} = ...
            fr{1, 'PPG_W25'} / fr{1, 'PPG_T3'};
        fr{1, 'PPG_W25_DT'} = ...
            fr{1, 'PPG_W25'} / fr{1, 'PPG_DT'};
        fr{1, 'PPG_W25_TPI'} = ...
            fr{1, 'PPG_W25'} / fr{1, 'PPG_TPI'};

        % w50 related ratios
        fr{1, 'PPG_W50_T1'} = ...
            fr{1, 'PPG_W50'} / fr{1, 'PPG_T1'};
        fr{1, 'PPG_W50_T2'} = ...
            fr{1, 'PPG_W50'} / fr{1, 'PPG_T2'};
        fr{1, 'PPG_W50_T3'} = ...
            fr{1, 'PPG_W50'} / fr{1, 'PPG_T3'};
        fr{1, 'PPG_W50_DT'} = ...
            fr{1, 'PPG_W50'} / fr{1, 'PPG_DT'};
        fr{1, 'PPG_W50_TPI'} = ...
            fr{1, 'PPG_W50'} / fr{1, 'PPG_TPI'};

        % w75 related ratios
        fr{1, 'PPG_W75_T1'} = ...
            fr{1, 'PPG_W75'} / fr{1, 'PPG_T1'};
        fr{1, 'PPG_W75_T2'} = ...
            fr{1, 'PPG_W75'} / fr{1, 'PPG_T2'};
        fr{1, 'PPG_W75_T3'} = ...
            fr{1, 'PPG_W75'} / fr{1, 'PPG_T3'};
        fr{1, 'PPG_W75_DT'} = ...
            fr{1, 'PPG_W75'} / fr{1, 'PPG_DT'};
        fr{1, 'PPG_W75_TPI'} = ...
            fr{1, 'PPG_W75'} / fr{1, 'PPG_TPI'};
        
        feature_table = [feature_table; fr];
        win_proc = win_proc + 1;
        catch le
            getReport(le)
        end
    end
end

%%
nrcols = feature_table.Properties.VariableNames(5:end);
prev_height = height(feature_table);
for c=nrcols
    col = char(c);
    feature_table.(col)(isinf(feature_table.(col))) = NaN;
end
feature_table = rmmissing(feature_table);
new_height = height(feature_table);
writetable(feature_table, sprintf("generated/%s", gen_path));
fprintf("Retained %d out of %d rows\n", new_height, prev_height);