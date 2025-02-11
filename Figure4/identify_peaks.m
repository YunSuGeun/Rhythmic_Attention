function [peak_freqs, peak_indices] = identify_peaks(freqs, original, mean_fractal)
    % Find local maxima in the original signal
    % Criteria for peaks:
    % 1. Local maximum
    % 2. Original signal higher than mean fractal
    % 3. Significant change in local slope

    % Compute first derivative to analyze slope changes
    diff_original = diff(original);
    
    % Find local maxima
    [peaks, peak_indices] = findpeaks(original);
    
    % Initialize arrays to store validated peaks
    valid_peak_indices = [];
    valid_peak_freqs = [];
    
    % Validate peaks based on multiple criteria
    for i = 1:length(peak_indices)
        % Check if original peak is higher than mean fractal
        if original(peak_indices(i)) > mean_fractal(peak_indices(i))
            % Check slope change (peak of positive to negative slope)
            if peak_indices(i) > 1 && peak_indices(i) < length(diff_original)
                % Ensure slope changes from positive to negative around the peak
                if diff_original(peak_indices(i)-1) > 0 && diff_original(peak_indices(i)) <= 0
                    valid_peak_indices = [valid_peak_indices, peak_indices(i)];
                    valid_peak_freqs = [valid_peak_freqs, freqs(peak_indices(i))];
                end
            end
        end
    end
    
    % Outputs
    peak_freqs = valid_peak_freqs;
    peak_indices = valid_peak_indices;
end