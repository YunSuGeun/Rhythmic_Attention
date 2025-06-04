%% plot IPF aligned power spectrum

clear; clc

rawDir = 'C:\Users\user\Desktop\Rhythmic_Attention\Data\4_IRASAData';
cd(rawDir)
load('IPF_stats.mat')

saveDir = 'C:\Users\user\Desktop\Rhythmic_Attention\Figure\Figure4';

data_selected = uigetfile('', '*.*', 'MultiSelect', 'on');  % Select behavior rawdata_anl file. 

freqs = [2:0.1:10];
x_axis = -8:0.1:8; % Adjust range to fit -10 Hz to +10 Hz

indices = [1,2,5,6,9,10,13,14];

% Process each folder
for n = 1:length(indices)

    Invalid_ind = indices(n);
    Valid_ind = Invalid_ind +2;

    cd(rawDir)

    %% Valid
    data_name = data_selected{1,Valid_ind};
    load(data_name) %IRASA.info
    peaks = data_selected{1,Valid_ind+17};
    load(peaks) % all_subject_peaks

    ori = IRASA_info.ori;
    
    valid_subjects = logical(all_subject_peaks(:,1));

    % Update all related data to include only valid subjects
    filtered_all_subject_peaks = all_subject_peaks(valid_subjects, :);
    filtered_ori = ori(valid_subjects, :);

    % Update number of subjects after filtering
    num_subj = size(filtered_ori, 1);
    num_freq = size(filtered_ori, 2);
    
    IPF_align = NaN(num_subj,2*num_freq);
    
    for subj_n = 1:num_subj
        IPF = filtered_all_subject_peaks(subj_n,1);
        IPF_index = find(freqs == IPF);
        diff_index = 81 - IPF_index;
        MaxOri = max(filtered_ori(subj_n,:));
        normalized_ori = filtered_ori(subj_n,:) / MaxOri;
        
        IPF_align(subj_n,diff_index+1:diff_index + 81) = normalized_ori;
    end        
      
    % Remove NaN columns for accurate plotting
    valid_columns = ~all(isnan(IPF_align), 1);
    IPF_align = IPF_align(:, valid_columns);
    x_axis_valid = x_axis(valid_columns);
    
    mean_align = mean(IPF_align,1,'omitNaN');
    sd_align = std(IPF_align,1,'omitNaN') / sqrt(num_subj);
    
    
    
    figure1 = figure;
    axis square;
    shadedErrorBar(x_axis_valid, mean_align, sd_align, {'-b','DisplayName','IPF_align'},0,0.1,4,1); % Red color line

    % Add black dotted line at x = 0
    hold on;
    ylim([0 1]);
    y_lim =ylim; 
    plot([0, 0], y_lim, '--k', 'LineWidth', 1); % Dotted black line
    
    main_freq = stats{Valid_ind,2};
    main_sd = stats{Valid_ind,3};
    
    text(1.5, y_lim(2) * 0.9, sprintf('%.1f Hz ± %.1f Hz', main_freq, main_sd), ...
         'HorizontalAlignment', 'center', 'Color', 'b');
    text(4, y_lim(2) / 2, sprintf('n = %d', num_subj), ...
         'HorizontalAlignment', 'center', 'Color', 'b');  
     
    xticks([0, 4]); % Set ticks at 0 and 4
    xticklabels({main_freq, main_freq+4}); % Label the ticks as 'IPF' and '+4'
    v_main_freq = main_freq;


    %% Invalid
    data_name = data_selected{1,Invalid_ind};
    load(data_name) %IRASA.info
    peaks = data_selected{1,Invalid_ind+17};
    load(peaks) % all_subject_peaks

    ori = IRASA_info.ori;
    
    valid_subjects = logical(all_subject_peaks(:,1));

    % Update all related data to include only valid subjects
    filtered_all_subject_peaks = all_subject_peaks(valid_subjects, :);
    filtered_ori = ori(valid_subjects, :);

    % Update number of subjects after filtering
    num_subj = size(filtered_ori, 1);
    num_freq = size(filtered_ori, 2);
    
    IPF_align = NaN(num_subj,2*num_freq);
    
    for subj_n = 1:num_subj
        IPF = filtered_all_subject_peaks(subj_n,1);
        IPF_index = find(freqs == IPF);
        diff_index = 81 - IPF_index;
        MaxOri = max(filtered_ori(subj_n,:));
        normalized_ori = filtered_ori(subj_n,:) / MaxOri;
        
        IPF_align(subj_n,diff_index+1:diff_index + 81) = normalized_ori;
    end        
      
    main_freq = stats{Invalid_ind,2};
    main_sd = stats{Invalid_ind,3};

    freq_dif = main_freq - v_main_freq;

    % Remove NaN columns for accurate plotting
    valid_columns = ~all(isnan(IPF_align), 1);
    IPF_align = IPF_align(:, valid_columns);
    x_axis_invalid = x_axis(valid_columns)+freq_dif;
    
    mean_align = mean(IPF_align,1,'omitNaN');
    sd_align = std(IPF_align,1,'omitNaN') / sqrt(num_subj);
    
    shadedErrorBar(x_axis_invalid, mean_align, sd_align, {'-r','DisplayName','IPF_align'},0,0.1,4,1); % Red color line
   
    
    text(1.5, y_lim(2) * 0.9, sprintf('%.1f Hz ± %.1f Hz', main_freq, main_sd), ...
         'HorizontalAlignment', 'center', 'Color', 'r');
    text(4, y_lim(2) / 2, sprintf('n = %d', num_subj), ...
         'HorizontalAlignment', 'center', 'Color', 'r');  
     

    xlabel('Frequency (Hz)');
    ylabel('Norm.Power(a.u.)');
    title(['IPF Aligned Power Spectrum: ', data_name]);

    
    % figDir = fullfile(saveDir,data_name);
    % saveas(figure1, fullfile(figDir,'IPF_align.png'));
    
    cd(saveDir)
    xlim([-1.5 6]);
    % TiT = sprintf('%s.png',data_name);
    % saveas(figure1, TiT);
    exportgraphics(figure1, [data_name '0327.pdf'], "ContentType","vector")
    hold off
     
end