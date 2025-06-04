%% Draw Perf model and Visi model at same plot

close all; clear; clc; 

rawDir = 'C:\Users\user\Desktop\Rhythmic_Attention\Data\5_CurvefittingData';
cd(rawDir)
figDir = 'C:\Users\user\Desktop\Rhythmic_Attention\Figure\Figure6';
dataDir = 'C:\Users\user\Desktop\Rhythmic_Attention\Data\6_ModelAlign';

data_selected = uigetfile('', '*.*', 'MultiSelect', 'on');  % Select behavior rawdata_anl file.

func0 = @(params, t) params(1) * t.^2 + params(2) * t + params(3);
func2 = @(params,t,omega_true) (params(1) - params(4)*t) .* cos(omega_true * t + params(3)) + (params(2) - params(4)*t) .* sin(omega_true * t + params(3));

indices = [1,2,3,4,9,10,11,12];

freq_differences = [];

for n = 1:length(indices)
    Perf_ind = indices(n);
    Visi_ind = Perf_ind +4;
    
    for s = 1:19
        close all
        %% Perf model plot    
 
        Perf_name = data_selected{1,Perf_ind};

        load(Perf_name);

        if size(fitted_data, 1) < s
            continue;
        end          
        if isempty(fitted_data{s,1})
            continue
        end     

        Perf_popt0 = fitted_data{s,3};
        Perf_popt2 = fitted_data{s,7};
        Perf_omega = fitted_data{s,8};
        Perf_freq = Perf_omega / (2*pi);

        conds = split(Perf_name); 

        cue_conds = conds{3}; 

        if strcmp(cue_conds, 'Precue')
            Cue_Cond = 1;
        elseif strcmp(cue_conds, 'Postcue')
            Cue_Cond = 2;
        end

        if Cue_Cond == 1
            t = (-1.500: 0.010: -0.050);
        elseif Cue_Cond == 2
            t = (0.050: 0.010: 1.500);
        end

        Perf_model = func0(Perf_popt0,t) + func2(Perf_popt2,t,Perf_omega);
        Perf_phase = Perf_popt2(3)*180/pi;

        Figure1 = figure();
        subplot(2,1,1)
        plot(t,Perf_model);

        title(sprintf('%s\n Peak frequency = %1.2f\n Phase = %1.2f',Perf_name, Perf_freq,Perf_phase ));


        %% Visi model plot

        Visi_name = data_selected{1,Visi_ind};
        load(Visi_name);

        if size(fitted_data, 1) < s
            continue;
        end        
        if isempty(fitted_data{s,1})
            continue
        end         
        
        Visi_popt0 = fitted_data{s,3};
        Visi_popt2 = fitted_data{s,7};
        Visi_omega = fitted_data{s,8};
        Visi_freq = Visi_omega / (2*pi);
                
        Visi_model = func0(Visi_popt0,t) + func2(Visi_popt2,t,Visi_omega);
        Visi_phase = Visi_popt2(3) * 180/pi;

        subplot(2,1,2)
        plot(t,Visi_model);
        title(sprintf('%s\n Peak frequency = %1.2f\n Phase = %1.2f',Visi_name, Visi_freq,Visi_phase));

        TiT = sprintf('%s %s %s', conds{3}, conds{5}, conds{6});

        saveDir = fullfile(figDir, sprintf('Model align/PV/%s',TiT)); 

        if (~exist(saveDir,'dir'))
            mkdir(saveDir) ;
        end

        saveas(Figure1, fullfile(saveDir, sprintf('%d.png', s)));
        
        freqDiff = Perf_freq - Visi_freq;        
        freq_differences = [freq_differences freqDiff];
    end        
end

%% statistical testing for Frequency difference
[~, p_diff_freq] = swtest(freq_differences, 0.05);
if p_diff_freq > 0.05
    % Normal, perform paired t-test
    [~, p_freq] = ttest(freq_differences);
    fprintf('Paired t-test Model 1 vs Model 2: p = %.3g\n', p_freq);
else
    % Non-normal, perform Wilcoxon signed-rank test
    p_freq = signrank(freq_differences);
    fprintf('Wilcoxon test Model 1 vs Model 2: p = %.3g\n', p_freq);
end

figure2 = figure();
set(figure2, 'Position', [100, 100, 500, 500]);
hold on

num_freqs = length(freq_differences);
boxplot(freq_differences, 'Positions', 1, 'Widths', 0.3, 'BoxStyle', 'outline', 'Colors', 'k');
% scatter(ones(num_freqs, 1) , freq_differences, 50, 'filled', ...
%     'MarkerEdgeColor', 'k', 'MarkerFaceColor', 'k', 'MarkerFaceAlpha', 0.5);

% Histogram (distribution next to the boxplot)
bin_width = 0.2; % Width of the histogram
edges = linspace(min(freq_differences), max(freq_differences),30); % Adjust number of bins
hist_counts = histcounts(freq_differences, edges);

% Normalize histogram counts for visualization next to the boxplot
hist_max = max(hist_counts);
norm_hist_counts = (hist_counts / hist_max) * bin_width;

% Draw histogram
for i = 1:length(hist_counts)
    patch([1.2 1.2 + norm_hist_counts(i) 1.2 + norm_hist_counts(i) 1.2], ...
        [edges(i) edges(i) edges(i+1) edges(i+1)], ...
        'b', 'FaceAlpha', 0.5, 'EdgeColor', 'none');
end

y_max = max(max(freq_differences));
y_min = min(min(freq_differences));
y_range = y_max - y_min;
offset = 0.1 * y_range;  % Vertical offset for annotations, proportional to y_range


if p_freq < 0.005
    sig_text = '***';
elseif p_freq < 0.01
    sig_text = '**';
elseif p_freq < 0.05
    sig_text = '*';
else
    sig_text = 'n.s.';
end

% Display significance text between models
text(1, y_max + offset, ...
    sprintf('%s (p = %.3g)', sig_text, p_freq), ...
    'HorizontalAlignment', 'center', 'FontSize', 10);

ylabel('Frequency(Hz)')
xticklabels('Perf freq - Visi freq')
plot([0.5 1.5],[0 0], 'k--')
xlim([0.5 1.5])
ylim([y_min - 0.2 * y_range, y_max + 0.2 * y_range]);
TiT = 'Frequency difference between Performance and Accuracy waveform';
title(TiT);

cd(figDir)
saveas(figure2,'PV_freq.png');
cd(dataDir);
save('PV_freq_differences.mat','freq_differences');