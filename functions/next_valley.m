function [next_valley] = next_valley(peak_idx, sig_valleys)
%NEXT_VALLEY Summary of this function goes here
%   Detailed explanation goes here
valleys_after_peak = sig_valleys(sig_valleys > peak_idx);
[next_valley, ~] = min(valleys_after_peak);
end

