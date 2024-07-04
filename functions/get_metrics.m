function [row] = get_metrics(sig_name, sigwin, fs)
%GET_METRICS Computes metrics for signal selection by given signal sigwin
% and sampling frequency.
%   Signal name (ABP or PPG) must be also given, a single-row table is
%   returned
arguments
    sig_name (1,1) string
    sigwin (1,:) double
    fs (1,1) double
end

normwin = normalize(sigwin, 'range');
[sig_peaks, sig_valleys, sig_dt_peaks, sig_notches] = find_pv_thresh(normwin);

% signal is so malformed that either one of the following happened
% - no peaks (and thus no valleys) can be found
% - just one peak found and thus no valleys
% as result, just return an empty set of metrics
if isempty(sig_peaks) || isempty(sig_valleys)
    row = table;
    return;
end

if strcmp(sig_name, 'PPG') && (isempty(sig_dt_peaks) || isempty(sig_notches))
    row = table;
    return;
end

pvd = []; % peak-to-valley distance
pvh = []; % peak-to-valley height
vpd = []; % valley-to-peak distance
vph = []; % valley-to-peak height
ppd = []; % peak-to-peak distance
pph = []; % peak-to-peak height
vvd = []; % valley-to-valley distance
vvh = []; % valley-to-valley height

for i = 1:length(sig_peaks)-1
    curr_p = sig_peaks(i); % current peak
    next_p = sig_peaks(i+1); % next peak
    next_v = next_valley(sig_peaks(i), sig_valleys); % valley next to peak

    if ~isempty(next_v) && next_v > 0
        pvd = [pvd (next_v-curr_p)/fs];
        pvh = [pvh abs(normwin(next_v)-normwin(curr_p))];
    end
    ppd = [ppd (next_p-curr_p)/fs];
    pph = [pph abs(normwin(next_p)-normwin(curr_p))];
end

for i = 1:length(sig_valleys)-1
    curr_v = sig_valleys(i); % current valley
    next_v = sig_valleys(i+1); % next valley
    next_p = next_peak(sig_valleys(i), sig_peaks); % peak after valley

    vpd = [vvd (next_p-curr_v)/fs];
    vph = [vph abs(normwin(next_p)-normwin(curr_v))];
    vvd = [vvd (next_v-curr_v)/fs];
    vvh = [vvh abs(normwin(next_v)-normwin(curr_v))];
end

% if the check against empty peak/valley set passed, the condition chain
% below should evaluate to False, but it is checked anyway
if isempty(pvd) || isempty(vpd) || isempty(ppd) || isempty(vvd)
    row = table;
    return;
end

row(1, sprintf('%s_MIN', sig_name)) = table(prctile(sigwin(sig_valleys), 50));
row(1, sprintf('%s_MAX', sig_name)) = table(prctile(sigwin(sig_peaks), 50));

row(1, sprintf('%s_NPK_ST', sig_name)) = table(numel(sig_peaks));
row(1, sprintf('%s_NPK_DT', sig_name)) = table(numel(sig_dt_peaks));

row(1, sprintf('%s_PVD', sig_name)) = table(prctile(pvd, 50));
row(1, sprintf('%s_PVH', sig_name)) = table(prctile(pvh, 50));
row(1, sprintf('%s_PPD', sig_name)) = table(prctile(ppd, 50));
row(1, sprintf('%s_PPH', sig_name)) = table(prctile(pph, 50));

row(1, sprintf('%s_VVD', sig_name)) = table(prctile(vvd, 50));
row(1, sprintf('%s_VVH', sig_name)) = table(prctile(vvh, 50));
row(1, sprintf('%s_VPD', sig_name)) = table(prctile(vpd, 50));
row(1, sprintf('%s_VPH', sig_name)) = table(prctile(vph, 50));

end

