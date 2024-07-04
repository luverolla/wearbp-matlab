function [] = print_wavelet_bands(fn, ncoefs)
[lows, highs] = get_wavelet_bands(fn, ncoefs);
    for i = 1 : ncoefs
        fprintf("Slice #%d - from %.2f Hz to %.2f Hz\n", i-1, lows(i), highs(i));
    end
end

