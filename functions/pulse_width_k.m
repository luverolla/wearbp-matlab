function pulse_width = pulse_width_k(signal, K, ref_zero)
    % Function to compute the signal width at K% amplitude
    % Input: 
    %   signal - the discrete signal (vector)
    %   K - the percentage (scalar in the range [0, 100])
    % Output:
    %   width - the pulse width at K% amplitude
    
    % Step 1: Find the maximum amplitude of the signal
    x_max = max(signal) - ref_zero;
    
    % Step 2: Calculate the K% amplitude threshold
    A_K = (K / 100) * x_max;
    
    % Step 3: Identify the indices where the signal crosses A_K
    above_threshold = find(signal >= ref_zero + A_K);
    
    if isempty(above_threshold)
        pulse_width = 0; % No crossing found
        return;
    end
    
    n1 = above_threshold(1);
    n2 = above_threshold(end);
    
    % Step 4: Compute the signal width
    pulse_width = n2 - n1;
end