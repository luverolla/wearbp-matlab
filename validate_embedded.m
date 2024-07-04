load("svm_coefs.mat");
%%
fs = 125;
wsize = 30;
state = 0;
dev = serialport("COM8", 115200);
%%
t = readtable("generated/features_all.csv");
recs = t{:, 'INFO_RECORD'};
starts = t{:, 'INFO_START'};
feats = t{:, 13:end};
truth = t{:, 11}; % for now SBP

result = table;
result(:, 'TRUTH') = table(truth);
%%
for i=544:height(t)
    write(dev, i, 'uint32');
    pause(1/100);
    ack = read(dev, 1, 'uint32');
    
    load("data_matlab/"+recs{i});
    sp = (starts(i)-1)*fs+1;
    ep = sp + fs*wsize - 1;
    ppg_win = ppg_raw(sp:ep);
    for j=0:wsize-1
        chunks = ppg_win(j*fs+1:(j+1)*fs);
        write(dev, chunks, 'single');
        pause(1/5);
    end
    pause(1/10);
    while dev.NumBytesAvailable < 4
        % pass
    end
    pred_emb = read(dev, 1, 'single');
    feats_norm = (feats(i,:) - ScfMin) ./ (ScfMax - ScfMin);
    pred_mtlb = feats_norm*Beta+Bias;
    pred_err = 100*abs((pred_emb - pred_mtlb)/pred_mtlb);
    fprintf("[%d] - PC: %.2f | MCU: %.2f | ERR: %.2f%%\n", i, pred_mtlb, pred_emb, pred_err);
    result{i,'PRED_MLB'} = pred_mtlb;
    result{i,'PRED_EMB'} = pred_emb;
    result{i,'PRED_ERR'} = pred_err;
end
%%
writetable(result, "res-part-3.csv");