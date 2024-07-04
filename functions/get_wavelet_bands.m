function [freq_lows, freq_highs] = get_wavelet_bands(fn, ncoefs)
%GET_WAVELET_BANDS Summary of this function goes here
%   Detailed explanation goes here
exponent = flip(0:ncoefs-1);
freq_lows = fn ./ 2.^(exponent + 1);
freq_lows(1) = 0;
freq_highs = fn ./ 2.^exponent;
