dev = serialport("COM9", 9600, 'ByteOrder','little-endian');

sigs = readtable("generated/features_all.csv");
load("svm_coefs.mat");
%%
send_sig(dev, sigs, 15);
feats = sigs{15,13:end};
(feats./Scale)*Beta
pred = (feats./Scale)*Beta + Bias;
%%
function [] = send_sig(dev, sigs, idx)
    load(sprintf("data_matlab/%s", char(sigs{idx,"INFO_RECORD"})), "ppg_raw");
    start = sigs{idx,"INFO_START"};
    ppg_win = ppg_raw(125*start:125*(start+30));

    for i=1:numel(ppg_win)
        s = typecast(single(ppg_win(i)), "uint32");
        write(dev, s, "uint32");
    end
    fprintf("signal sent\n");
end