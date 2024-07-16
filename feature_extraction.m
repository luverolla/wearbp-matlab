%% Feature extraction
% This script takes, in input, the signal windows given as output of the
% signal_selection script, and extract from them the features needed by
% the statistical inference model to be trained and tested.
%% Parameters
NUM_CORES = 8; % tune according to the PHYSICAL cores on your machine
FSAMPLE = 125; % sampling frequency [Hz]
WIN_SIZE = 30; % window size [s]
AVG_NWINS = 10; % number of windows to average
DATASET = 'vitaldb'; % name of the dataset
INPUT_PATH = 'passed_vitaldb_new.csv'; % output of signal_selection
OUTPUT_PATH = 'features_vitaldb_new.csv'; % where to write new output
%% Load data and identify record files
load('gendata/filter_coefs.mat'); % load filter coefficients

feature_table = table;
input_table = readtable(strcat('generated/',INPUT_PATH));
input_table_const = parallel.pool.Constant(input_table);

records = unique(input_table.RECORD);
n_recs = numel(records);
%% Process record files in parallel
parfor(r=1:size(records, 1),NUM_CORES)
    t = input_table_const.Value;
    record = records(r,:);
    avg_count = 0;
    avg_feats = [];

    record_path = sprintf('datasets/%s/_data/%s', DATASET, char(record));

    S = take_sigs(record_path);
    abp_raw = downsample(S.abp_raw,4);
    ppg_raw = downsample(S.ppg_raw,4);

    abp_raw(isnan(abp_raw)) = 0;
    ppg_raw(isnan(ppg_raw)) = 0;

    abp_flt = filter(coefs, 1, abp_raw);
    ppg_flt = filter(coefs, 1, ppg_raw);

    occs = t(strcmp(t.RECORD, record),:);
    win_proc = 0;
    win_disc = 0;

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

        % for MIMIC-II and MIMIC-III records are in the form
        %   {patient}-{shiftedDate}.mat
        % while for VitalDB, records are in the form
        %   {patient}.mat (one record per patient)
        % 
        % Splitting by dash (-) will be useless for VitalDB, but no error
        % will arise. Splitting a string by a separator that isn't 
        % contained in it, will just give in output the whole string.
        % 
        % This ensures that the correct substring is taken regardless of
        % the selected dataset.
        chunks = split(record, '-', 1);
        chunks = split(chunks(1,:), '.', 1);
        fr{1, 'INFO_PATIENT'} = chunks(1,:);

        % time starts from zero, but Matlab indexing starts from one.
        % So the first second (from second 0 to 1) 
        start_pos = (start-1)*FSAMPLE+1;
        end_pos = start_pos+WIN_SIZE*FSAMPLE;

        abp_mean = mean(abp_raw(start_pos:end_pos));
        ppg_mean = mean(ppg_raw(start_pos:end_pos));

        abp_win = abp_flt(start_pos:end_pos) + abp_mean;
        ppg_win = ppg_flt(start_pos:end_pos) / ppg_mean;
  
        abp_norm = normalize(abp_win, 'range');
        ppg_norm = normalize(ppg_win, 'range');
    
        [abp_pks, abp_vls, ~, ~] = get_fiducials(abp_norm, 0.65);
        [ppg_st_pks, ppg_vls,...
         ppg_dt_pks, ppg_notches] = get_fiducials(ppg_norm);

% =========================================================================
                        % SBP and DBP ground truths
% =========================================================================
        fr{1, 'GT_SBP'} = median(abp_win(abp_pks));
        fr{1, 'GT_DBP'} = median(abp_win(abp_vls));

% =========================================================================
                        % Height-related features
% =========================================================================
        % systolic peak
        acc = [];
        for k=1:length(ppg_vls)-1
            st_peak = next_fiducial(ppg_vls(k), ppg_vls(k+1), ppg_st_pks);
            if ~isempty(st_peak)
                acc = [acc ppg_win(st_peak)-ppg_win(ppg_vls(k))];
            end
        end
        fr{1,'PPG_X'} = prctile(acc, 50);

        % diastolic peak
        acc = [];
        for k=1:length(ppg_vls)-1
            dt_peak = next_fiducial(ppg_vls(k), ppg_vls(k+1), ppg_dt_pks);
            if ~isempty(dt_peak)
                acc = [acc ppg_win(dt_peak)-ppg_win(ppg_vls(k))];
            end
        end
        fr{1,'PPG_Y'} = prctile(acc, 50);

        % notch height
        acc = [];
        for k=1:length(ppg_vls)-1
            notch = next_fiducial(ppg_vls(k), ppg_vls(k+1), ppg_notches);
            if ~isempty(notch)
                acc = [acc ppg_win(notch)-ppg_win(ppg_vls(k))];
            end
        end
        fr{1,'PPG_Z'} = prctile(acc, 50);

% =========================================================================
                        % Time-related features
% =========================================================================
        % systolic peak time
        acc = [];
        for k=1:length(ppg_vls)-1
            st_peak = next_fiducial(ppg_vls(k), ppg_vls(k+1), ppg_st_pks);
            acc = [acc (st_peak - ppg_vls(k))*(1000/FSAMPLE)];
        end
        fr{1, 'PPG_T1'} = prctile(acc, 50);

        % diastolic peak time
        acc = [];
        for k=1:length(ppg_vls)-1
            dt_peak = next_fiducial(ppg_vls(k), ppg_vls(k+1), ppg_dt_pks);
            acc = [acc (dt_peak - ppg_vls(k))*(1000/FSAMPLE)];
        end
        fr{1, 'PPG_T3'} = prctile(acc, 50);

        % notch time
        acc = [];
        for k=1:length(ppg_vls)-1
            notch = next_fiducial(ppg_vls(k), ppg_vls(k+1), ppg_notches);
            if ~isempty(notch)
                acc = [acc (notch - ppg_vls(k))*(1000/FSAMPLE)];
            end
        end
        fr{1, 'PPG_T2'} = prctile(acc, 50);

        % deltaT (distance between diastolic and systolic peak)  
        acc = [];
        for k=1:length(ppg_st_pks)-1
            dt_pk = next_fiducial( ...
                ppg_st_pks(k), ppg_st_pks(k+1), ppg_dt_pks ...
            );
            if ~isempty(dt_pk)
                acc = [acc (dt_pk - ppg_st_pks(k))*(1000/FSAMPLE)];
            end
        end
        fr{1, 'PPG_DT'} = prctile(acc, 50);
        
        % pulse interval
        acc = zeros(size(ppg_vls)-1);
        for k=1:length(ppg_vls)-1
            acc(k) = (ppg_vls(k+1) - ppg_vls(k))*(1000/FSAMPLE);
        end
        fr{1, 'PPG_TPI'} = prctile(acc, 50);

        % peak-to-peak interval
        acc = zeros(size(ppg_st_pks)-1);
        for k=1:length(ppg_st_pks)-1
            acc(k) = (ppg_st_pks(k+1) - ppg_st_pks(k))*(1000/FSAMPLE);
        end
        fr{1, 'PPG_TPP'} = prctile(acc, 50);

        fr{1, 'PPG_HR'} = 60 / (fr{1, 'PPG_TPP'}/1000);

        % heart rate variability
        fr{1, 'PPG_HRV'} = std(60 ./ (acc./1000));

% =========================================================================
                     % Mixed height- and time-related
% =========================================================================
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
        fr{1, 'PPG_AGI'} = fr{1,'PPG_Y'}/fr{1,'PPG_X'};

        % alternative augmentation index
        fr{1, 'PPG_ALTAGI'} = (fr{1,'PPG_X'}-fr{1,'PPG_Y'})/fr{1,'PPG_X'};

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

        % diastolic over peak-to-peak time
        fr{1, 'PPG_T3_TPP'} = ...
            fr{1, 'PPG_T3'} / ...
            fr{1, 'PPG_TPP'};

        % notch over peak-to-peak time
        fr{1, 'PPG_T2_TPP'} = ...
            fr{1, 'PPG_T2'} / ...
            fr{1, 'PPG_TPP'};

        % DeltaT over peak-to-peak time
        fr{1, 'PPG_DT_TPP'} = ...
            fr{1, 'PPG_DT'} / ...
            fr{1, 'PPG_TPP'};

        % notch over systolic peak height
        fr{1, 'PPG_Z_X'} = fr{1,'PPG_Z'}/fr{1,'PPG_X'};

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

% =========================================================================
                        % Pulse width features
% =========================================================================
        % pulse width at 25%
        acc = [];
        for k=1:length(ppg_vls)-1
            pulse = ppg_win(ppg_vls(k):ppg_vls(k+1));
            pw25 = pulse_width_k(pulse, 25, ppg_win(ppg_vls(k)));
            if pw25 > 0
                acc = [acc pw25*(1000/FSAMPLE)];
            end
        end
        fr{1, 'PPG_W25'} = prctile(acc, 50);

        % pulse width 50%
        acc = [];
        for k=1:length(ppg_vls)-1
            pulse = ppg_win(ppg_vls(k):ppg_vls(k+1));
            pw50 = pulse_width_k(pulse, 50, ppg_win(ppg_vls(k)));
            if pw50 > 0
                acc = [acc pw50*(1000/FSAMPLE)];
            end
        end
        fr{1, 'PPG_W50'} = prctile(acc, 50);

        % pulse width at 75%
        acc = [];
        for k=1:length(ppg_vls)-1
            pulse = ppg_win(ppg_vls(k):ppg_vls(k+1));
            pw75 = pulse_width_k(pulse, 75, ppg_win(ppg_vls(k)));
            if pw75 > 0
                acc = [acc pw75*(1000/FSAMPLE)];
            end
        end
        fr{1, 'PPG_W75'} = prctile(acc, 50);

% =========================================================================
                % Mixed pulse width and time-related features
% =========================================================================
        % w25 related ratios
        fr{1, 'PPG_W25_T1'} = ...
            fr{1, 'PPG_W25'} / fr{1, 'PPG_T1'};
        fr{1, 'PPG_W25_T3'} = ...
            fr{1, 'PPG_W25'} / fr{1, 'PPG_T3'};
        fr{1, 'PPG_W25_T2'} = ...
            fr{1, 'PPG_W25'} / fr{1, 'PPG_T2'};
        fr{1, 'PPG_W25_DT'} = ...
            fr{1, 'PPG_W25'} / fr{1, 'PPG_DT'};
        fr{1, 'PPG_W25_TPI'} = ...
            fr{1, 'PPG_W25'} / fr{1, 'PPG_TPI'};

        % w50 related ratios
        fr{1, 'PPG_W50_T1'} = ...
            fr{1, 'PPG_W50'} / fr{1, 'PPG_T1'};
        fr{1, 'PPG_W50_T3'} = ...
            fr{1, 'PPG_W50'} / fr{1, 'PPG_T3'};
        fr{1, 'PPG_W50_T2'} = ...
            fr{1, 'PPG_W50'} / fr{1, 'PPG_T2'};
        fr{1, 'PPG_W50_DT'} = ...
            fr{1, 'PPG_W50'} / fr{1, 'PPG_DT'};
        fr{1, 'PPG_W50_TPI'} = ...
            fr{1, 'PPG_W50'} / fr{1, 'PPG_TPI'};

        % w75 related ratios
        fr{1, 'PPG_W75_T1'} = ...
            fr{1, 'PPG_W75'} / fr{1, 'PPG_T1'};
         fr{1, 'PPG_W75_T3'} = ...
            fr{1, 'PPG_W75'} / fr{1, 'PPG_T3'};
        fr{1, 'PPG_W75_T2'} = ...
            fr{1, 'PPG_W75'} / fr{1, 'PPG_T2'};
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
%% Adding demographic features (VitalDB only)
if strcmp(DATASET, 'vitaldb')
    demog_data = readtable('datasets/vitaldb/demog.csv');
    demog_table = table;
    for i=1:height(feature_table)
        patient_id = feature_table{i,'INFO_PATIENT'};
        patient_id_num = str2double(patient_id);
        demog_row = demog_data(demog_data.caseid == patient_id_num, :);
        demog_table{i, 'DEMG_AGE'} = demog_row{1, 'age'};
        demog_table{i, 'DEMG_BMI'} = demog_row{1, 'bmi'};
        demog_table{i, 'DEMG_SEX'} = demog_row{1, 'sex'};
        demog_table{i, 'DEMG_HEIGHT'} = demog_row{1, 'height'};
        demog_table{i, 'DEMG_WEIGHT'} = demog_row{1, 'weight'};
    end

    % place demographic features after ground truths
    until_gt = feature_table(:, 1:5);
    after_gt = feature_table(:, 6:end);
    feature_table = [until_gt demog_table after_gt];

    % alias for shortening
    fr = feature_table;
    for i=1:height(feature_table)
% =========================================================================
                % Mixed demographic and time-related features
% =========================================================================
        % stiffness index (height/deltaT)
        fr{i, 'MIX_STIFDX'} = fr{i, 'DEMG_HEIGHT'} / fr{i, 'PPG_DT'};
        fr{i, 'MIX_WEIGHT_DT'} = fr{i, 'DEMG_WEIGHT'} / fr{i, 'PPG_DT'};
        fr{i, 'MIX_BMI_DT'} = fr{i, 'DEMG_BMI'} / fr{i, 'PPG_DT'};

        fr{i, 'MIX_HEIGHT_T1'} = fr{i, 'DEMG_HEIGHT'} / fr{i, 'PPG_T1'};
        fr{i, 'MIX_WEIGHT_T1'} = fr{i, 'DEMG_WEIGHT'} / fr{i, 'PPG_T1'};
        fr{i, 'MIX_BMI_T1'} = fr{i, 'DEMG_BMI'} / fr{i, 'PPG_T1'};

        fr{i, 'MIX_HEIGHT_T2'} = fr{i, 'DEMG_HEIGHT'} / fr{i, 'PPG_T2'};
        fr{i, 'MIX_WEIGHT_T2'} = fr{i, 'DEMG_WEIGHT'} / fr{i, 'PPG_T2'};
        fr{i, 'MIX_BMI_T2'} = fr{i, 'DEMG_BMI'} / fr{i, 'PPG_T2'};

        fr{i, 'MIX_HEIGHT_T3'} = fr{i, 'DEMG_HEIGHT'} / fr{i, 'PPG_T3'};
        fr{i, 'MIX_WEIGHT_T3'} = fr{i, 'DEMG_WEIGHT'} / fr{i, 'PPG_T3'};
        fr{i, 'MIX_BMI_T3'} = fr{i, 'DEMG_BMI'} / fr{i, 'PPG_T3'};

        fr{i, 'MIX_HEIGHT_TPI'} = fr{i, 'DEMG_HEIGHT'} / fr{i, 'PPG_TPI'};
        fr{i, 'MIX_WEIGHT_TPI'} = fr{i, 'DEMG_WEIGHT'} / fr{i, 'PPG_TPI'};
        fr{i, 'MIX_BMI_TPI'} = fr{i, 'DEMG_BMI'} / fr{i, 'PPG_TPI'};

        fr{i, 'MIX_HEIGHT_TPP'} = fr{i, 'DEMG_HEIGHT'} / fr{i, 'PPG_TPP'};
        fr{i, 'MIX_WEIGHT_TPP'} = fr{i, 'DEMG_WEIGHT'} / fr{i, 'PPG_TPP'};
        fr{i, 'MIX_BMI_TPP'} = fr{i, 'DEMG_BMI'} / fr{i, 'PPG_TPP'};
    end
end
%% Remove NaN/missing values
nrcols = feature_table.Properties.VariableNames(5:end);
prev_height = height(feature_table);
for c=nrcols
    col = char(c);
    if ~strcmp(col, 'DEMG_SEX')
        feature_table.(col)(isinf(feature_table.(col))) = NaN;
    end
end
feature_table = rmmissing(feature_table);
new_height = height(feature_table);
writetable(feature_table, sprintf("generated/%s", OUTPUT_PATH));
fprintf("Retained %d out of %d rows\n", new_height, prev_height);
fprintf( ...
    "There are %d patients in the dataset\n", ...
    numel(unique(feature_table.INFO_PATIENT)) ...
);