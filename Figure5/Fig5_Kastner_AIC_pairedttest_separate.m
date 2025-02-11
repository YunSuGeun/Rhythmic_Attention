%% to create Fig 6. Curvefitting
% Paired t-test for each AIC value with separation of positive and negative values
% with individual peak frequency fitting data

close all; clear; clc; 

rawDir = 'C:\Users\user\Desktop\Rhythmic_Attention\Data\5_CurvefittingData';
saveDir = 'C:\Users\user\Desktop\Rhythmic_Attention\Figure\Figure5';

cd(rawDir)

data_selected = uigetfile('', '*.*', 'MultiSelect', 'on');  % Select behavior rawdata_anl file. 

AIC_matrix = {};

for i = 1:length(data_selected)
    
    data_name = data_selected{1,i};

    load(data_name)

%% compare AICs between functions
    AIC_matrix = [AIC_matrix;
        fitted_data(:, 2), fitted_data(:, 4), fitted_data(:, 6)];
end

cd(saveDir)

AIC_matrix = cell2mat(AIC_matrix);

num_datasets = size(AIC_matrix, 1);
num_models = size(AIC_matrix, 2);

% Separate positive and negative AIC values
% AIC_Perf = AIC_matrix([1:76, 153:226], :);
% AIC_Visi = AIC_matrix([77:152,227:end], :);
AIC_Perf = AIC_matrix(1:76, :);
AIC_Visi = AIC_matrix(77:152, :);

% Model pair indices for comparison
model_pairs = [1 2; 2 3; 1 3];
model_names = {'Model 1', 'Model 2', 'Model 3'};

% Initialize p-values arrays for positive and negative sets
p_values_pos = zeros(size(model_pairs, 1), 1);
p_values_neg = zeros(size(model_pairs, 1), 1);

% Perform tests for positive values
for i = 1:size(model_pairs, 1)
    m1 = model_pairs(i, 1);
    m2 = model_pairs(i, 2);
    
    if ~isempty(AIC_Perf)       
        % Perform Wilcoxon signed-rank test
        p_values_pos(i) = signrank(AIC_Perf(:, m1), AIC_Perf(:, m2), 'method', 'exact', 'tail', 'both');
    end
end

% Perform tests for negative values
for i = 1:size(model_pairs, 1)
    m1 = model_pairs(i, 1);
    m2 = model_pairs(i, 2);
    
    if ~isempty(AIC_Visi)
        % Perform Wilcoxon signed-rank test
        p_values_neg(i) = signrank(AIC_Visi(:, m1), AIC_Visi(:, m2), 'method', 'exact', 'tail', 'both');
    end
end

% Apply Bonferroni correction
p_values_pos = p_values_pos * length(AIC_Perf);
p_values_neg = p_values_neg * length(AIC_Visi);

%% Plotting for Performance AIC Values
figure1 = figure();
set(figure1, 'Position', [100, 100, 500, 500]);
hold on;

% Define colors and markers for plotting
colors = lines(num_models);
markers = {'o', 's', 'd'};

% Adjust x positions with padding
x_positions = [0.8, 2, 3.2];


% Plot AIC values for each model (Positive)
for i = 1:num_models
    scatter(ones(size(AIC_Perf, 1), 1) .* x_positions(i), AIC_Perf(:, i), 20, 'filled', ...
        'MarkerEdgeColor', colors(i, :), 'MarkerFaceColor', colors(i, :), 'MarkerFaceAlpha', 0.2, 'MarkerEdgeAlpha',0.2);
end

% Plot connecting lines for each condition (Positive)
for numd = 1:size(AIC_Perf, 1)
    plot(x_positions, AIC_Perf(numd, :), '--', 'Color', [0.5, 0.5, 0.5, 0.2], 'LineWidth', 0.8);
end

for i = 1:num_models 
    h = boxplot(AIC_Perf(:, i), 'Positions', x_positions(i), 'Widths', 0.2, 'Colors', colors(i, :)); 
    % Adjust line width 
    set(findobj(h, 'type', 'line'), 'LineWidth', 2); % Change '2' to desired line width 
end

% Annotate significance between model pairs (Positive)
y_max = max(AIC_Perf(:));
offset = 0.015;

for i = 1:size(model_pairs, 1)
    m1 = model_pairs(i, 1);
    m2 = model_pairs(i, 2);
    p_val = p_values_pos(i);

    % Determine significance level
    if p_val < 0.005
        sig_text = '***';
    elseif p_val < 0.01
        sig_text = '**';
    elseif p_val < 0.05
        sig_text = '*';
    else
        sig_text = 'n.s.';
    end

    % Display significance text between models
    text(mean([x_positions(m1), x_positions(m2)]), y_max * (1 + offset * 2*i + offset), ...
        sprintf('%s (p = %.3g)', sig_text, p_val), 'HorizontalAlignment', 'center', 'FontSize', 10);
    plot([x_positions(m1), x_positions(m2)], [y_max * (1 + offset * 2*i), y_max * (1 + offset * 2*i)],  '-', 'Color', [0.5, 0.5, 0.5], 'LineWidth', 1);
end

% Customize plot
xticks(x_positions);
xticklabels({'Second Order Polynomial', '+ Oscillation', '+ Linear Damping'});
xlim([0.5, 3.5]);
ylim([min(min(AIC_Perf))*0.9, y_max*1.15])
xlabel('Model');
ylabel('AIC');
title('AIC Values Across Models (Accuracy)');
grid off;
hold off;

% Save the positive AIC figure
saveas(figure1, '250110 Paired_AIC_Plot_Accuracy.png');

%% Plotting for Visibility AIC Values
figure2 = figure();
set(figure2, 'Position', [600, 100, 500, 500]);
hold on;

% Plot AIC values for each model (Positive)
for i = 1:num_models
    scatter(ones(size(AIC_Visi, 1), 1) .* x_positions(i), AIC_Visi(:, i), 20, 'filled', ...
        'MarkerEdgeColor', colors(i, :), 'MarkerFaceColor', colors(i, :), 'MarkerFaceAlpha', 0.2, 'MarkerEdgeAlpha',0.2);
end

% Plot connecting lines for each condition (Positive)
for numd = 1:size(AIC_Visi, 1)
    plot(x_positions, AIC_Visi(numd, :), '--', 'Color', [0.5, 0.5, 0.5, 0.2], 'LineWidth', 0.8);
end

for i = 1:num_models 
    h = boxplot(AIC_Visi(:, i), 'Positions', x_positions(i), 'Widths', 0.2, 'Colors', colors(i, :)); 
    % Adjust line width 
    set(findobj(h, 'type', 'line'), 'LineWidth', 2); % Change '2' to desired line width 
end

% Annotate significance between model pairs (Negative)
y_max = max(AIC_Visi(:));
offset = 0.25;

for i = 1:size(model_pairs, 1)
    m1 = model_pairs(i, 1);
    m2 = model_pairs(i, 2);
    p_val = p_values_neg(i);

    % Determine significance level
    if p_val < 0.005
        sig_text = '***';
    elseif p_val < 0.01
        sig_text = '**';
    elseif p_val < 0.05
        sig_text = '*';
    else
        sig_text = 'n.s.';
    end

    % Display significance text between models
    text(mean([x_positions(m1), x_positions(m2)]), y_max * (1 + offset * 2*i + offset), ...
        sprintf('%s (p = %.3g)', sig_text, p_val), 'HorizontalAlignment', 'center', 'FontSize', 10);
    plot([x_positions(m1), x_positions(m2)], [y_max * (1 + offset * 2*i), y_max * (1 + offset * 2*i)], '-', 'Color', [0.5, 0.5, 0.5], 'LineWidth', 1);
end

% Customize plot
xticks(x_positions);
xticklabels({'Second Order Polynomial', '+ Oscillation', '+ Linear Damping'});
xlim([0.5, 3.5]);
ylim([min(AIC_Visi(:))*1.1, y_max*3.5])
xlabel('Model');
ylabel('AIC');
title('AIC Values Across Models (Visibility)');
grid off;
hold off;

% Save the negative AIC figure
saveas(figure2, '250110 Paired_AIC_Plot_Visibility.png');
