%% statistic for IPF 

clear; clc

rawDir = 'C:\Users\user\Desktop\Rhythmic_Attention\Data\4_IRASAData';
cd(rawDir)

data_selected = uigetfile('', '*.*', 'MultiSelect', 'on');  % Select behavior rawdata_anl file. 

stats = cell(16,3);

% Process each folder
for i = 1:16
    
    data_name = data_selected{1,i};
    

    load(data_name)
    
    valid_subjects = all_subject_peaks(:,1) ~= 0;

    % Compute statistics only for valid subjects
    mean_freq = mean(all_subject_peaks(valid_subjects, 1));
    sd_freq = std(all_subject_peaks(valid_subjects, 1), 0);

    stats{i,1} = data_name;
    stats{i,2} = mean_freq;
    stats{i,3} = sd_freq;
    
end
cd(rawDir)
save('IPF_stats.mat','stats')
    