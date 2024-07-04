function [next_peak] = next_peak(valley_idx, sig_peaks)
%NEXT_PEAK Summary of this function goes here
%   Detailed explanation goes here
peaks_after_valley = sig_peaks(sig_peaks > valley_idx);
[next_peak, ~] = min(peaks_after_valley);
end

