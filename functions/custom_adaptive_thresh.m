function [thresh] = custom_adaptive_thresh(sig, n, w_th, w_yn, last_tr)
%ADAPTIVE_THRESH Summary of this function goes here
%   Detailed explanation goes here
arguments
    sig (1,:) double
    n (1,1) {mustBeInteger}
    w_th (1,1) double
    w_yn (1,1) double
    last_tr (1,1) = sig(1)
end

if n == 1 || n >= length(sig)
    if ~isempty(sig)
        thresh = sig(1);
    else
        thresh = 0;
    end
else
    prev = last_tr;
    thresh = w_th * prev + w_yn * sig(n);
end
end

