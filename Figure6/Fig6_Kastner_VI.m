%% Draw Valid and Invalid model at same plot

close all; clear; clc; 

rawDir = 'C:\Users\user\Desktop\Rhythmic_Attention\Data\5_CurvefittingData';
cd(rawDir)
figDir = 'C:\Users\user\Desktop\Rhythmic_Attention\Figure\Figure6';
dataDir = 'C:\Users\user\Desktop\Rhythmic_Attention\Data\6_ModelAlign';

cd(rawDir)

data_selected = uigetfile('', '*.*', 'MultiSelect', 'on');  % Select behavior rawdata_anl file.

func0 = @(params, t) params(1) * t.^2 + params(2) * t + params(3);

func2 = @(params,t,omega_true) (params(1) - params(4)*t) .* cos(omega_true * t + params(3)) + (params(2) - params(4)*t) .* sin(omega_true * t + params(3));

indices = [1,2,5,6,9,10,13,14];
freq_differences = [];

for n = 1:length(indices)
    Invalid_ind = indices(n);
    Valid_ind = Invalid_ind +2;

    for s = 1:19
        close all
        %% Invalid model plot    
        Invalid_name = data_selected{1,Invalid_ind};        
    
        load(Invalid_name);

        if size(fitted_data, 1) < s
            continue;
        end          
        if isempty(fitted_data{s,1})
            continue;
        end     

        Invalid_popt0 = fitted_data{s,3};
        Invalid_popt2 = fitted_data{s,7};
        Invalid_omega = fitted_data{s,8};
        Invalid_freq = Invalid_omega / (2*pi);

        conds = split(Invalid_name); 

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

        Invalid_model = func0(Invalid_popt0,t) + func2(Invalid_popt2,t,Invalid_omega);
        Invalid_phase = Invalid_popt2(3)*180/pi;

        Figure1 = figure();
        subplot(2,1,1)
        plot(t,Invalid_model);

        title(sprintf('%s\n Peak frequency = %1.2f\n Phase = %1.2f',Invalid_name, Invalid_freq,Invalid_phase ));


        %% Valid model plot
        Valid_name = data_selected{1,Valid_ind};        

        load(Valid_name);
        if size(fitted_data, 1) < s
            continue;
        end        
        if isempty(fitted_data{s,1})
            continue;
        end         

        Valid_popt0 = fitted_data{s,3};
        Valid_popt2 = fitted_data{s,7};
        Valid_omega = fitted_data{s,8};
        Valid_freq = Valid_omega / (2*pi);

        Valid_model = func0(Valid_popt0,t) + func2(Valid_popt2,t,Valid_omega);
        Valid_phase = Valid_popt2(3) * 180/pi;

        subplot(2,1,2)
        plot(t,Valid_model);
        title(sprintf('%s\n Peak frequency = %1.2f\n Phase = %1.2f',Valid_name, Valid_freq,Valid_phase));

        TiT = sprintf('%s %s %s', conds{3}, conds{4}, conds{6});


        saveDir = fullfile(figDir, sprintf('Model align/VI/%s',TiT)); 

        if (~exist(saveDir,'dir'))
            mkdir(saveDir) ;
        end

        saveas(Figure1, fullfile(saveDir, sprintf('%d.png', s)));
        
        freqDiff = Valid_freq - Invalid_freq;        
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
xticklabels('Valid freq - Invalid freq')
xlim([0.5 1.5])
plot(xlim,[0 0], 'k--')
ylim([y_min - 0.2 * y_range, y_max + 0.2 * y_range]);
TiT = 'Frequency difference between Valid and Invalid condition';
title(TiT);

cd(figDir)
saveas(figure2,'VI_freq.png');
cd(dataDir);
save('VI_freq_differences.mat','freq_differences');