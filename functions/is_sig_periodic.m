function [result] = is_sig_periodic(sig, fs)
%IS_SIG_PERIODIC Performs autocorrelation to check if a signal is periodic.
%   The signal is normalized in the range [0,1], and then only peaks whose
%   height is greater than the half of the signal are considered.
arguments
    sig (1,:) double
    fs (1,1) double
end
[acf,~] = xcorr(sig);
acf = normalize(acf, 'range');
% Determine the periodicity
[~, locs] = findpeaks(acf, 'MinPeakHeight', 0.5); % find peaks above 0.5
periods = diff(locs)/fs; % compute periods between peaks

% Check if the periods are consistent
result = std(periods) < 0.01; % threshold for determining consistency
end