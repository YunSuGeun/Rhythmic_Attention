%% Curevfitting for individual peak frequency acquired with kastner method

close all;clear;clc; 


behavDir = 'C:\Users\user\Desktop\Rhythmic_Attention\Data\3_BehavioralData';
freqDir = 'C:\Users\user\Desktop\Rhythmic_Attention\Data\4_IRASAData';
saveDir = 'C:\Users\user\Desktop\Rhythmic_Attention\Figure\Figure5\Curvefitting';   
dataDir = 'C:\Users\user\Desktop\Rhythmic_Attention\Data\5_CurvefittingData';

if (~exist(saveDir,'dir'))
    mkdir(saveDir) ;
end
if (~exist(dataDir,'dir'))
    mkdir(dataDir) ;
end

cd(behavDir)

% Load or initialize your data
data_selected = uigetfile('', '*.*', 'MultiSelect', 'on');  % Select behavior rawdata_anl file. 

for i = 1: length(data_selected)
    close all;
    
    %% load behavior data
    cd(behavDir);
    
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


    if strcmp(method_conds, 'Perf')
        Method = 1;
    elseif strcmp(method_conds, 'Visi')
        Method = 2;
    end

    num_subj = size(Group_data,1);
    
    %% load IPF
    cd(freqDir)    
    IPF_name = ['subject_peaks_', data_name '.mat'];
    load(IPF_name) % all_subject_peaks loaded
    
    %% fit individual peak frequency 
    
    clear fitted_data
    
    for s = 1:num_subj
        y = Group_data(s,:);
        
        if all_subject_peaks(s,1) == 0
            continue;       % Skip to the next subject
        end  

        %% second order polynomial detrend
        % Second-order polynomial fitting code
        A0 = 0.0; % quadratic term
        B0 = 0.0; % linear term
        C0 = 0.0; % constant term

        initial_guess3 = [A0, B0, C0];
        lb0 = [-Inf, -Inf, -Inf]; % Lower bounds
        ub0 = [Inf, Inf, Inf]; % Upper bounds

        % Second-order polynomial function
        func0 = @(params, t) params(1) * t.^2 + params(2) * t + params(3);

        % Fit second-order polynomial model
        [popt0, resnorm0] = lsqcurvefit(func0, initial_guess3, t, y, lb0, ub0);

        %calculate AIC
        AIC0 = 2*length(popt0) +n*log(resnorm0/n);

        % save fitting parameters
        fitted_data{s, 1} = s;
        fitted_data{s, 2} = AIC0;
        fitted_data{s, 3} = popt0;

        %% no damping fitting

        freq_true = all_subject_peaks(s,1);
        omega_true = 2*pi*freq_true;

        % oscillation parameters
        A1 = 0.0; % initial amplitude(the highest peak) for cosine
        B1 = 0.0; % initial amplitude(the highest peak) for sine
        P1 = 0.0; %phase angle (at t = 0)

        % Initial guess for the parameters
        initial_guess1 = [A1,B1,P1];

        lb1 = [-Inf, -Inf, 0]; % Lower bounds
        ub1 = [Inf, Inf, 2*pi]; % Upper bounds

        func1 = @(params,t)func0(popt0, t) +...
        params(1)* cos(omega_true * t + params(3)) + params(2)*sin(omega_true * t + params(3));

        % Define the options for lsqcurvefit
        options = optimoptions('lsqcurvefit','Display', 'final', 'TolFun', 1e-6, 'TolX', 1e-6, 'Algorithm','levenberg-marquardt');

        % Fit the data to the model
        [popt1, resnorm1] = lsqcurvefit(func1, initial_guess1, t, y, lb1, ub1, options);

        %calculate AIC
        AIC1 = 2*(length(popt1)+length(popt0)) +n*log(resnorm1/n);

        % save fitting parameters
        fitted_data{s, 4} = AIC1;
        fitted_data{s, 5} = popt1;

        %% linear damping amplitude

        % oscillation parameters
        A2 = 0.0; % initial amplitude(the highest peak) for cosine
        B2 = 0.0; % initial amplitude(the highest peak) for sine
        P2 = 0.0; %phase angle (at t = 0)
        lambda2 = 0.0; % decay parameter

        % Initial guess for the parameters
        initial_guess2 = [A2,B2,P2, lambda2];

        lb2 = [-Inf, -Inf, 0, -Inf]; % Lower bounds
        ub2 = [Inf, Inf, 2*pi, Inf]; % Upper bounds

        func2 = @(params,t)func0(popt0, t) +...
        (params(1) - params(4)*t) .* cos(omega_true * t + params(3)) + (params(2) - params(4)*t) .* sin(omega_true * t + params(3));

        % Fit the data to the model
        [popt2, resnorm2] = lsqcurvefit(func2, initial_guess2, t, y, lb2, ub2, options);

        %calculate AIC
        AIC2 = 2*(length(popt0)+length(popt2)) +n*log(resnorm2/n);

        % save fitting parameters
        fitted_data{s, 6} = AIC2;
        fitted_data{s, 7} = popt2;
        fitted_data{s, 8} = omega_true;

        %% Plot the data and the fit

        funcs = {func0, func1, func2};
        popts = {popt0, popt1, popt2};
        AICs = [AIC0, AIC1, AIC2];

        figure1=figure();
        set(figure1, 'Position', [100, 100, 1200, 300]); % [left, bottom, width, height]

        % Add 'data_name' as the title for the entire figure
        sgTiT = sprintf('%s %d',data_name,s);
        sgtitle(sgTiT);

        % Create subplots for each function
        for ii = 1:3
            subplot(1, 3, ii);

            l1=plot(t, y, 'b', 'DisplayName','Raw data');
            hold on;
            plot(t, funcs{ii}(popts{ii}, t), 'r-', 'DisplayName', 'Model','LineWidth',4);

            if Cue_Cond == 1
                set(gca,'xtick',-1.500:(1.500/3):0);
                xlim([-1.500,0]);
            elseif Cue_Cond == 2     
                set(gca,'xtick',0:1.500/3:1.500);
                xlim([0,1.500]);
            end

            if ii == 1
                if Method == 1
                    ylabel('Accuracy');
                elseif Method == 2
                    ylabel('Visibility');
                end
            end
            xlabel('Cue-to-Target Interval(sec)')

            box on;

            TiT = sprintf('AIC = %.4f',AICs(ii));
            title(TiT);       
        end
    
        % saveTiT = sprintf('Curvefittiing %s %d',data_name,s);
        
        save_Dir = fullfile(saveDir,data_name);

        if (~exist(save_Dir,'dir'))
            mkdir(save_Dir) ;
        end
        cd(save_Dir)
        saveas(figure1,[num2str(s) '.png']);

        hold off;
    end

    save(fullfile(dataDir, data_name), 'fitted_data');
end
