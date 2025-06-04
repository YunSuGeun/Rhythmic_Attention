%% perform hilbert transformation
clear;clc;close all;

addpath('C:/Users/user/Desktop/fieldtrip-20240916')
ft_defaults

%% Data loading

rawDir = 'C:\Users\user\Desktop\Rhythmic_Attention\Data\3_BehavioralData';    
figDir = 'C:\Users\user\Desktop\Rhythmic_Attention\Figure\Figure6\Hilbert';
dataDir = 'C:\Users\user\Desktop\Rhythmic_Attention\Data\6_ModelAlign\Hilbert';
if (~exist(figDir,'dir'))
    mkdir(figDir)
end
if (~exist(dataDir,'dir'))
    mkdir(dataDir)
end

cd(rawDir)

data_selected = uigetfile('', '*.*', 'MultiSelect', 'on');  % Select behavior rawdata_anl file.


for i = 1: length(data_selected)
    cd(rawDir)

    data_name = data_selected{i};
    load(data_name);


    %% Hilbert
    [nSubj, nTimepoint] = size(Group_data);
    padding_length = nTimepoint;
    time = 1:nTimepoint; % Adjust time axis based on actual sampling frequency

    % Initialize storage for instantaneous phase
    instantaneous_phase = zeros(size(Group_data));

    % Loop through each subject
    for subj = 1:nSubj
        % Extract the signal for the current subject        
        signal = Group_data(subj, :);
        p = polyfit(time, signal, 2);
        trend = polyval(p, time);
        signal = signal - trend;        
        flip_signal = flip(signal);
        
        % Add zero-padding to the signal
        padded_signal = [flip_signal signal flip_signal signal flip_signal signal flip_signal];

        % Apply bandpass filter using ft_preproc_bandpassfilter
        filtered_padded_signal = ft_preproc_bandpassfilter(padded_signal, 100, [2.6989 6.3323]);
    
        % Remove the padding after filtering
        filtered_signal = filtered_padded_signal(padding_length*3 +1:end-padding_length*3);

    
        % Compute the analytic signal using ft_preproc_hilbert
        analytic_padded_signal = ft_preproc_hilbert(filtered_padded_signal, 'complex');
        
        analytic_signal = analytic_padded_signal(padding_length*3 +1:end-padding_length*3);


        % Compute the instantaneous phase
        instantaneous_phase(subj, :) = angle(analytic_signal);
        
        %% Plot the signals
        Figure1 = figure;

        % Plot original signal
        subplot(3, 1, 1);
        plot(time, signal, 'b');
        title('Original Signal');
        xlabel('Time');
        ylabel('Amplitude');

        % Plot filtered signal
        subplot(3, 1, 2);
        plot(time, filtered_signal, 'r');
        title('Filtered Signal');
        xlabel('Time');
        ylabel('Amplitude');

        % Plot instantaneous phase
        subplot(3, 1, 3);
        plot(time, instantaneous_phase(subj,:), 'k');
        title('Instantaneous Phase');
        xlabel('Time');
        ylabel('Phase (radians)');           


        figsaveDir = fullfile(figDir, data_name);
        if ~exist(figsaveDir, 'dir')
            mkdir(figsaveDir);
        end
        saveas(Figure1, fullfile(figsaveDir, [num2str(subj) '.png']));
    end
    close all
    save(fullfile(dataDir,data_name),'instantaneous_phase');
end

