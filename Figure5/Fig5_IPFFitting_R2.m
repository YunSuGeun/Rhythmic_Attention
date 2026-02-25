%% Curevfitting for individual peak frequency acquired with kastner method

close all;clear;clc;

behavDir = 'C:\Users\user\Desktop\Rhythmic_Attention\Data\3_BehavioralData';
paramsDir = 'C:\Users\user\Desktop\Rhythmic_Attention\Data\5_CurvefittingData\tic';
saveDir = 'C:\Users\user\Desktop\Rhythmic_Attention\Figure\Figure5\Curvefitting';
dataDir = 'C:\Users\user\Desktop\Rhythmic_Attention\Data\5_CurvefittingData\R2';

if (~exist(saveDir,'dir'))
    mkdir(saveDir) ;
end
if (~exist(dataDir,'dir'))
    mkdir(dataDir) ;
end

cd(behavDir)

% Load or initialize your data
data_selected = uigetfile('', '*.*', 'MultiSelect', 'on');  % Select behavior rawdata_anl file.

%% load behavior data

for i = 1: length(data_selected)
    close all;


    data_name = data_selected{1,i};
    load(data_name); %Group_data loaded

    conds = split(data_name);

    cue_conds = conds{3};
    method_conds = conds{4};

    if strcmp(cue_conds, 'Precue')
        Cue_Cond = 1;
    elseif strcmp(cue_conds, 'Postcue')
        Cue_Cond = 2;
    end

    if Cue_Cond == 1
        t = (-1.500: 0.010: -0.050);
        Group_data = flip(Group_data')';
    elseif Cue_Cond == 2
        t = (0.050: 0.010: 1.500);
    end

    n = length(t);
    t=t(:);


    if strcmp(method_conds, 'Perf')
        Method = 1;
    elseif strcmp(method_conds, 'Visi')
        Method = 2;
    end

    num_subj = size(Group_data,1);

    Rsquare = zeros(num_subj,3);
    Adj_Rsquare = zeros(num_subj,3);
    %% load params
    params_path = fullfile(paramsDir, data_name);
    load(params_path) % fitted_data loaded
    params_count = [3, 5, 7]; % func1: 3개, func2: 5개, func3: 7개
    %% get r2 for each behavior

    for s = 1:num_subj
        y = Group_data(s,:)';

        freq_true = fitted_data{s, 7};
        omega_true = 2*pi*freq_true;

        func1 = @(params, t) params(1) * t.^2 + params(2) * t + params(3);

        func2 = @(params,t) params(1) * t.^2 + params(2) * t + params(3)+...
        params(4)* cos(omega_true * t) + params(5)*sin(omega_true * t);

        func3 = @(params,t) params(1) * t.^2 + params(2) * t + params(3)+...
        params(4)* cos(omega_true * t) + params(5)*sin(omega_true * t) + params(6) * (t.*cos(omega_true*t)) + params(7) * (t.*sin(omega_true*t));

        funcs = {func1, func2, func3};
        popts = {fitted_data{s, 2},fitted_data{s, 4},fitted_data{s, 6}};

        for m = 1:3
            % 모델 예측값 계산
            y_pred = funcs{m}(popts{m}, t);
            
            % R-square 계산
            SSres = sum((y - y_pred).^2);
            SStot = sum((y - mean(y)).^2);
            Rsquare(s, m) = 1 - SSres/SStot;
            
            % 조정된 R-square 계산
            p = params_count(m); % 모델 m의 파라미터 수
            Adj_Rsquare(s, m) = 1 - ((1 - Rsquare(s, m)) * (n - 1) / (n - p - 1));
        end


    end

   save(fullfile(dataDir, data_name), 'Rsquare', 'Adj_Rsquare');
end
