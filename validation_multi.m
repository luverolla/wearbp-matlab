fs = 125;
win_size = 30;
state = 0;
dev = serialport("COM8", 115200);
%%
rng(42);

data = readtable('generated/features_vitaldb.csv');
perc_train = 0.9;
%%
R = randperm(size(data, 1));
data = data(R, :);
%%
patients = unique(data.INFO_PATIENT);
train_pats = patients(1:floor(perc_train*numel(patients)));
test_pats = setdiff(patients, train_pats);

train_data = data(ismember(data.INFO_PATIENT, train_pats),:);
test_data = data(ismember(data.INFO_PATIENT, test_pats),:);

result = table();
%%
for i=1:height(test_data)
    %test_data(i,6:end)
    write(dev, uint32(i), 'uint32');
    %pause(1/10);

    while dev.NumBytesAvailable < 4
    end
    read(dev, 1, 'uint32');
    fprintf('Win-Ack received\n');

    load("datasets/vitaldb/_data/"+test_data{i, 'INFO_RECORD'});
    ppg_raw = downsample(ppg_raw, 4);
    ppg_raw(isnan(ppg_raw)) = 0;
    ppg_flt = filter(coefs, 1, ppg_raw);

    demog_vec = single(test_data{i, 6:10});
    write(dev, demog_vec, 'single');
    
    while dev.NumBytesAvailable < 4
    end
    read(dev, 1, 'uint32');
    fprintf('Demog-Ack received\n');

    start_sec = test_data{i, 'INFO_START'};
    %start_p = (start_sec-1)*fs+1;
    %end_p = start_p + win_size*fs;
    %sigwin = ppg_flt(start_p:end_p);
    %normwin = normalize(sigwin, 'range');
    %[stp,vls,dtp,nxs] = find_pv_thresh(normwin);
    %disp(sigwin)
    for s=start_sec:start_sec+win_size
        start_pt = (s-1)*fs+1;
        val = single(ppg_flt(start_pt:start_pt+fs-1));
        write(dev, val, 'single');
        while dev.NumBytesAvailable < 4
        end
        read(dev, 1, 'uint32');
    end

    %pause(1/10);
    while dev.NumBytesAvailable < 4
    end
    pred_emb = read(dev, 1, 'single');

    % prediction on Matlab
    feats_norm = (test_data{i,6:end} - ModelOffset) ./ ModelScale;
    pred_mtlb = feats_norm*ModelBeta+ModelBias;
    pred_err = 100*abs((pred_emb - pred_mtlb)/pred_mtlb);
    fprintf("[%d] - PC: %.2f | MCU: %.2f | ERR: %.2f%%\n", i, pred_mtlb, pred_emb, pred_err);

    result{i, 'TRUTH'} = test_data{i, 'GT_DBP'};
    result{i,'PRED_MLB'} = pred_mtlb;
    result{i,'PRED_EMB'} = pred_emb;
    result{i,'PRED_ERR'} = pred_err;
end
%%
writetable(result, "multival_dbp.csv");