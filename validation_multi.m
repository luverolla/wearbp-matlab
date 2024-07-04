fs = 125;
wsize = 30;
state = 0;
%dev = serialport("COM8", 115200);
load("svm_coefs_sbp_new.mat");
%%
rng(42);

data = readtable('generated/features_all.csv'); % Update 'your_dataset.csv' with your file name
win_size = 30;
win_ovlp = floor(win_size/4);
perc_train = 0.95;
%%
chks = split(data.INFO_RECORD, '-');
data.INFO_PATIENT = chks(:, 1);
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
for i=uint32(1):uint32(height(test_data))
    write(dev, uint32(i), 'uint32');
    pause(1/10);
    read(dev, 1, 'uint32');
    load("data_matlab/"+test_data{i, 'INFO_RECORD'});
    sp = (test_data{i, 'INFO_START'}-1)*fs+1;
    ep = sp + fs*wsize - 1;
    ppg_win = ppg_raw(sp:ep);
    for j=0:wsize-1
        chunks = ppg_win(j*fs+1:(j+1)*fs);
        write(dev, chunks, 'single');
        pause(1/10);
    end
    pause(1/10);
    if dev.NumBytesAvailable == 4
        pred_emb = read(dev, 1, 'single');
        feats_norm = (test_data{i,13:end-1} - ScfMin) ./ (ScfMax - ScfMin);
        pred_mtlb = feats_norm*Beta+Bias;
        pred_err = 100*abs((pred_emb - pred_mtlb)/pred_mtlb);
        fprintf("[%d] - PC: %.2f | MCU: %.2f | ERR: %.2f%%\n", i, pred_mtlb, pred_emb, pred_err);
        result{i, 'TRUTH'} = test_data{i, 'GT_DBP'};
        result{i,'PRED_MLB'} = pred_mtlb;
        result{i,'PRED_EMB'} = pred_emb;
        result{i,'PRED_ERR'} = pred_err;
    end
end
%%
writetable(result, "res_sbp_new.csv");