%% Get predictions
% This script listens to the serial port waiting that the WearDB firmware
% on the MCU platform sends computed blood pressure values.
%
% To make this script work, the firmware must be run with the 
% configuration parameter CFG_DEBUG set to 1.
dev = serialport("COM8", 115200);

fnh = @(src,evt) printPred(src,evt);
configureCallback(dev,"byte",2*4, fnh);

function [] = printPred(src, ~)
    vals = read(src, 2, "single");
    sbp = vals(1);
    dbp = vals(2);
    if sbp > 0 && dbp > 0
        fprintf("SBP: %.2f, DBP: %.2f\n", sbp, dbp);
    else
        fprintf("Invalid measure\n");
    end
end