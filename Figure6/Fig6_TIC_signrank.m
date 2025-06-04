%% to create Fig 6. Curvefitting
% Paired signrank test for each TIC value with separation of accuracy and visibility values
% with individual peak frequency fitting data

close all; clear; clc;
med = 0

rawDir = 'C:\Users\user\Desktop\Rhythmic_Attention\Data\5_CurvefittingData\tic';
saveDir = 'C:\Users\user\Desktop\Rhythmic_Attention\Figure\Figure6';

cd(rawDir)

data_selected = uigetfile('', '*.*', 'MultiSelect', 'on');  % Select TIC fitted data. 

AIC_matrix = {};

for i = 1:length(data_selected)
    
    data_name = data_selected{1,i};

    load(data_name)

%% compare AICs between functions
    AIC_matrix = [AIC_matrix;
        fitted_data(:, 1), fitted_data(:, 3), fitted_data(:, 5)];
end

cd(saveDir)

AIC_matrix = cell2mat(AIC_matrix);

num_datasets = size(AIC_matrix, 1);
num_models = size(AIC_matrix, 2);

% Separate positive and negative AIC values
AIC_Perf = AIC_matrix(1:76, :);
AIC_Visi = AIC_matrix(77:152, :);

% Model pair indices for comparison
model_pairs = [1 2; 2 3; 1 3];
model_names = {'Model 1', 'Model 2', 'Model 3'};

numPairs      = size(model_pairs,1);
nPerf         = size(AIC_Perf,1);
nVisi         = size(AIC_Visi,1);
diff_Perf     = zeros(nPerf,  numPairs);
diff_Visi     = zeros(nVisi,  numPairs);

% Initialize p-values arrays for positive and negative sets
p_values_pos = zeros(size(model_pairs, 1), 1);
p_values_neg = zeros(size(model_pairs, 1), 1);

W_values_pos = zeros(size(model_pairs, 1), 1);
W_values_neg = zeros(size(model_pairs, 1), 1);

% Perform tests for positive values
for i = 1:size(model_pairs, 1)
    m1 = model_pairs(i, 1);
    m2 = model_pairs(i, 2);

    % 1) compute and save the raw differences
    diff_Perf(:,i) = AIC_Perf(:,m1) - AIC_Perf(:,m2);
    diff_Visi(:,i) = AIC_Visi(:,m1) - AIC_Visi(:,m2);    
    
    [p_values_pos(i), h, stats_pos] = signrank(AIC_Perf(:,m1), AIC_Perf(:,m2), 'method', 'approximate', 'tail', 'both');
    
    % Perform Wilcoxon signed-rank test
    [p_values_neg(i), h, stats_neg] = signrank(AIC_Visi(:,m1), AIC_Visi(:,m2), 'method', 'approximate', 'tail', 'both');
    W_values_pos(i) = stats_pos.zval;
    W_values_neg(i) = stats_neg.zval;
end

% Apply Bonferroni correction
p_values_pos = min(p_values_pos * size(model_pairs,1), 1);  
p_values_neg = min(p_values_neg * size(model_pairs,1), 1);  

%% Plotting for Performance AIC Values
figure1 = figure();
set(figure1, 'Position', [100, 100, 680, 680]);
hold on;

% Define colors and markers for plotting
colors = lines(num_models);
markers = {'o', 's', 'd'};

% Adjust x positions with padding
x_positions = [1, 2, 3];


% Plot AIC values for each model (Positive)
for i = 1:num_models
    scatter(ones(size(AIC_Perf, 1), 1) .* x_positions(i), AIC_Perf(:, i), 20, 'filled', 'MarkerFaceColor', colors(i, :));
end

% Plot connecting lines for each condition (Positive)
for numd = 1:size(AIC_Perf, 1)
    plot(x_positions, AIC_Perf(numd, :), '--', 'Color', [0.5, 0.5, 0.5, 0.2], 'LineWidth', 1);
end

% Create violin plot at custom x position
v = violinplot(AIC_Perf, model_names, ...
               'Width', 0.1, ...
               'ShowWhisker', false, ...
               'ShowData', false, ...
               'ShowBox', false,...
               'EdgeColor', [0,0,0]);


% Annotate significance between model pairs (Positive)
y_max = max(AIC_Perf(:));
y_min = min(AIC_Perf(:));
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
xticklabels({'Model 1', 'Model 2', 'Model 3'});
xlim([0.5, 3.5]);
ylim([750,1350])
ylabel('TIC');
grid off;
hold off;

% Save the positive AIC figure
% saveas(figure1, '250521 TIC_Accuracy.png');
% exportgraphics(figure1, '250521 TIC_Accuracy.pdf', ContentType='vector')

%% Plotting for Visibility AIC Values
figure2 = figure();
set(figure2, 'Position', [600, 100, 680, 680]);
hold on;

% Plot AIC values for each model (Positive)
for i = 1:num_models
    scatter(ones(size(AIC_Visi, 1), 1) .* x_positions(i), AIC_Visi(:, i), 20, 'filled', 'MarkerFaceColor', colors(i, :));
end

% Plot connecting lines for each condition (Positive)
for numd = 1:size(AIC_Visi, 1)
    plot(x_positions, AIC_Visi(numd, :), '--', 'Color', [0.5, 0.5, 0.5, 0.2], 'LineWidth', 1);
end
  
% Create violin plot at custom x position
v = violinplot(AIC_Visi, model_names, ...
               'Width', 0.1, ...
               'ShowWhisker', false, ...
               'ShowData', false, ...
               'ShowBox', false,...
               'EdgeColor', [0,0,0]);
    
% Annotate significance between model pairs (Negative)
y_max = max(AIC_Visi(:));
y_min = min(AIC_Visi(:));

offset = 0.05;

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
xticklabels({'Model 1', 'Model 2', 'Model 3'});
xlim([0.5, 3.5]);
ylim([-60, 400])
ylabel('TIC');
grid off;
hold off;

% Save the negative AIC figure
% saveas(figure2, '250521 TIC_Visibility.png');
% exportgraphics(figure2, '250521 TIC_Visibility.pdf', ContentType='vector')
