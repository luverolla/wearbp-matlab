function [next_notch] = next_notch(peak_idx, sig_notches)
%NEXT_VALLEY Summary of this function goes here
%   Detailed explanation goes here
notches_after_peak = sig_notches(sig_notches > peak_idx);
[next_notch, ~] = min(notches_after_peak);
end

