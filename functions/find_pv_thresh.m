function [st_peaks, valleys, dt_peaks, notches] = find_pv_thresh(sig, st_thres, dt_thres)
    %FIND_PEAKS_THRESH Summary of this function goes here
    %   Detailed explanation goes here
    arguments
        sig (1,:) double
        st_thres (1,1) double = 0.65
        dt_thres (1,1) double = 0.20
    end

    % normalize signal (if already normed it changes nothing)
    %sig = normalize(x, 'range');

    st_peaks = [];
    dt_peaks = [];
    
    for i = 4:length(sig)
        if sig(i-2) > sig(i-3) && sig(i-1) <= sig(i-2) && sig(i-1) > sig(i)
            if sig(i-2) >= st_thres
                st_peaks = [st_peaks i - 2];
            elseif sig(i-2) >= dt_thres
                dt_peaks = [dt_peaks i - 2];
            end
        end
    end
    
    valleys = zeros(1, numel(st_peaks)-1);
    notches = zeros(1, numel(st_peaks)-1);
    
    valley_idx = 1;
    notch_idx = 1;

    for i = 1:length(st_peaks)-1
        p1 = st_peaks(i);
        p2 = st_peaks(i+1);
        d1 = next_dt_peak(p1, dt_peaks);
    
        % valley
        min_idx = p1;
        for k=p1+1:p2
            if sig(k) < sig(min_idx)
                min_idx = k;
            end
        end
        valleys(valley_idx) = min_idx;
        valley_idx = valley_idx + 1;
    
        % notch
        min_idx = p1;
        for k=p1+1:d1
            if sig(k) < sig(min_idx)
                min_idx = k;
            end
        end
        if ~isempty(min_idx)
            notches(notch_idx) = min_idx;
            notch_idx = notch_idx + 1;
        end
    end
end
%%
function res = next_dt_peak(st_peak, dt_peaks)
    arguments
        st_peak (1,1) double 
        dt_peaks (1,:) double
    end

    res = 0.0;
    for i=1:numel(dt_peaks)
        if dt_peaks(i) > st_peak
            res = dt_peaks(i);
            break;
        end
    end
end

