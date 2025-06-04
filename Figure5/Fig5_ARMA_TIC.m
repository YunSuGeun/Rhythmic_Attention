%% Curevfitting for individual peak frequency acquired with kastner method sds

close all;clear;clc; 


behavDir = 'C:\Users\Sugeun\Desktop\Rhythmic_Attention\Data\3_BehavioralData';
freqDir = 'C:\Users\Sugeun\Desktop\Rhythmic_Attention\Data\4_IRASAData';
saveDir = 'C:\Users\Sugeun\Desktop\Rhythmic_Attention\Figure\Figure5\Curvefitting';   
dataDir = 'C:\Users\Sugeun\Desktop\Rhythmic_Attention\Data\5_CurvefittingData';

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

    data_name = data_selected{1,i};
    data_path = fullfile(behavDir, data_name);
    load(data_path); %Group_data loaded
    
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

    t = t(:);

    if strcmp(method_conds, 'Perf')
        Method = 1;
    elseif strcmp(method_conds, 'Visi')
        Method = 2;
    end

    num_subj = size(Group_data,1);
    
    %% load IPF
    IPF_name = ['subject_peaks_', data_name '.mat'];
    IPF_path = fullfile(freqDir, IPF_name);
    load(IPF_path) % all_subject_peaks loaded
    
    %% fit individual peak frequency 
    
    fitted_data = cell(num_subj,7);
    
    for s = 1:num_subj
    % for s = 1:num_subj

        y = Group_data(s,:);
        y= y(:);
        N     = numel(y);

        %% ARMA fitting
        % lsq fitting
        A0 = 0.0; % quadratic term
        B0 = 0.0; % linear term
        C0 = 0.0; % constant term

        initial_guess0 = [A0, B0, C0];
        lb0 = [-Inf, -Inf, -Inf]; % Lower bounds
        ub0 = [Inf, Inf, Inf]; % Upper bounds

        % Second-order polynomial function
        func1 = @(params, t) params(1) * t.^2 + params(2) * t + params(3);

        % Fit second-order polynomial model
        [popt0, resnorm0] = lsqcurvefit(func1, initial_guess0, t, y, lb0, ub0);

        residuals = y - func1(popt0,t);


        maxP = 3;  % 최대 AR 차수
        maxQ = 3;  % 최대 MA 차수
        
        residuals = residuals(:);  % ensure column vector
        best_aic = Inf;
        best_model = [];
        best_p = NaN;
        best_q = NaN;

        for p = 0:maxP
            for q = 0:maxQ
                try

                    mdl = arima(p, 0, q);  % ARMA(p,q)
                    [est,~,logL] = estimate(mdl, residuals, 'Display', 'off');
                    maCoefs = cell2mat(est.MA);                     % 1×q_order 벡터
                    if ~isempty(maCoefs)
                      rts = roots([1; -maCoefs(:)]);                % MA(z) = 1 - θ₁z - … - θq z^q
                      if any(abs(rts) <= 1)                         % 단위원 내부 뿌리만 허용
                        continue;                                   % 비가역 모델은 건너뛰기
                      end
                    end                    
                    numParams = p+q+1+1;
                    this_aic = -2*logL + 2*numParams;
                    if this_aic < best_aic
                        best_aic = this_aic;
                        best_model = est;
                        best_p = p;
                        best_q = q;
                    end
                catch
                    continue;
                end
            end
        end

        p = best_p;
        q = best_q;
        
        %% Second-order polynomial fitting 

        Mdl1 = regARIMA('ARLags',1:best_p,'MALags',1:best_q,'Intercept',0);
        X1  = [t.^2  ,  t  ,  ones(size(t))];   % [β₁  β₂  β₃] 에 대응
       
        [EstMdl1, EstParamCov,logL,~] = estimate( ...
                Mdl1 , y , 'X',X1 , ...
                'Display','off');

        Beta1 = num2cell(EstMdl1.Beta);
        theta1 = [EstMdl1.AR EstMdl1.MA  Beta1 EstMdl1.Variance];        % 추정된 β 벡터 (k×1)
        theta1 = cell2mat(theta1)';
        k     = numel(theta1);

        % 2) presample 길이 계산
        m = max(best_p,best_q);           % presample 필요 길이

        % presample 응답·잔차를 지정 (reverse chronological order)
        Y0 = y(m:-1:1);                   % [ y(m); y(m-1); …; y(1) ]
        E0 = zeros(m,1);                  % residuals 초기값 (0으로)
        
        % 3) t = m+1 부터 시작해서 score 계산
        eps0   = 1e-6;
        min_eps = 1e-12;
        Tstart = m + 1;
        Tcnt   = N - m;
        scores = nan(Tcnt, k);
        idx    = 0;
        
        for t0 = Tstart : N
            idx = idx + 1;
            % t0 시점까지의 로그우도 함수
            fun_t = @(b) singleLogLik(t0, y, X1, EstMdl1, b);
            for j = 1:k
                h = eps0;
                % success = false;
                % while ~success && h > min_eps
                %   try
                    b_f = theta1;  b_f(j) = b_f(j) + h;
                    b_b = theta1;  b_b(j) = b_b(j) - h;

                    % ma_f = b_f(p+1:p+q);
                    % ma_b = b_b(p+1:p+q);
                    % ma_f = enforceInvertibleMA(ma_f);
                    % ma_b = enforceInvertibleMA(ma_b);
                    % b_f(p+1:p+q)=ma_f;
                    % b_b(p+1:p+q)=ma_b;
                    % 
                    scores(idx,j) = (fun_t(b_f) - fun_t(b_b)) / (2*h);
                %     success = true;            % 성공하면 while 탈출
                %   catch ME
                %     if contains(ME.message,'noninvertible')
                %       h = h/10;                % h를 줄이고 while 재시도
                %     else
                %       break;                   % invertible 외 에러면 포기
                %     end
                %   end
                % end           
            end
        end
        
        
        J = (scores' * scores) / Tcnt;
        CovBeta_valid = EstParamCov([2:end], [2:end]);        
        
        % 4) TIC 계산 (EstParamCov = I^{-1} 이므로 penalty = 2·tr(J·I^{-1}) = 2·tr(J·Vbeta))
        penalty = 2 * trace(J * CovBeta_valid);
        TIC1 = -2*logL + penalty;


        % 임시 변수에 저장
        temp_TIC = TIC1;
        temp_Beta = EstMdl1.Beta;
        
        % 루프의 마지막에 한꺼번에 저장 (같은 인덱스 패턴 사용)
        fitted_data{s,1} = temp_TIC;
        fitted_data{s,2} = temp_Beta;



        %% no damping fitting

        freq_true = all_subject_peaks(s,1);
        omega_true = 2*pi*freq_true;

        X2 = [ X1 , cos(omega_true*t) , sin(omega_true*t) ];
        
        Mdl2 = regARIMA(...
            'ARLags',1:best_p, 'MALags',1:best_q, 'Intercept',0, ...
            'Beta',   [ EstMdl1.Beta, NaN, NaN ]);

        [EstMdl2,EstParamCov,logL,~] = estimate( ...
                Mdl2 , y , 'X',X2 , ...
                'Display','off');

        Beta2 = num2cell(EstMdl2.Beta);
        theta2 = [EstMdl2.AR EstMdl2.MA  Beta2 EstMdl2.Variance];        % 추정된 β 벡터 (k×1)
        theta2 = cell2mat(theta2);
        k     = numel(theta2);

        scores = nan(Tcnt, k);
        idx    = 0;

        for t0 = Tstart : N
            idx = idx + 1;
            % t0 시점까지의 로그우도 함수
            fun_t = @(b) singleLogLik(t0, y, X2, EstMdl2, b);
            for j = 1:k
                h = eps0;
                % success = false;
                % while ~success && h > min_eps
                %   try
                    b_f = theta2;  b_f(j) = b_f(j) + h;
                    b_b = theta2;  b_b(j) = b_b(j) - h;

                    % ma_f = b_f(p+1:p+q);
                    % ma_b = b_b(p+1:p+q);
                    % ma_f = enforceInvertibleMA(ma_f);
                    % ma_b = enforceInvertibleMA(ma_b);
                    % b_f(p+1:p+q)=ma_f;
                    % b_b(p+1:p+q)=ma_b;

                    scores(idx,j) = (fun_t(b_f) - fun_t(b_b)) / (2*h);
                    success = true;            % 성공하면 while 탈출
                %   catch ME
                %     if contains(ME.message,'noninvertible')
                %       h = h/10;                % h를 줄이고 while 재시도
                %     else
                %       break;                   % invertible 외 에러면 포기
                %     end
                %   end
                % end           
            end
        end

        J = (scores' * scores) / Tcnt;
        CovBeta_valid = EstParamCov([2:end], [2:end]);        
        
        % 4) TIC 계산 (EstParamCov = I^{-1} 이므로 penalty = 2·tr(J·I^{-1}) = 2·tr(J·Vbeta))
        penalty = 2 * trace( J * CovBeta_valid );
        TIC2 = -2*logL + penalty;

        % 임시 변수에 저장
        temp_TIC = TIC2;
        temp_Beta = EstMdl2.Beta;
        
        % 루프의 마지막에 한꺼번에 저장 (같은 인덱스 패턴 사용)
        fitted_data{s,3} = temp_TIC;
        fitted_data{s,4} = temp_Beta;

        %% linear damping amplitude
        X3 = [ X1 , ...
               cos(omega_true*t) , sin(omega_true*t) , ...
               t.*cos(omega_true*t),  t.*sin(omega_true*t) ];

        Mdl3 = regARIMA(...
            'ARLags',1:best_p, 'MALags',1:best_q, 'Intercept',0, ...
            'Beta',   [ EstMdl1.Beta , NaN , NaN, NaN, NaN]);

        [EstMdl3,EstParamCov,logL,~] = estimate( ...
                Mdl3 , y , 'X',X3 , ...
                'Display','off');

        Beta3 = num2cell(EstMdl3.Beta);
        theta3 = [EstMdl3.AR EstMdl3.MA  Beta3 EstMdl3.Variance];        % 추정된 β 벡터 (k×1)
        theta3 = cell2mat(theta3);
        k     = numel(theta3);        
        
        scores = nan(Tcnt, k);
        idx    = 0;        
        for t0 = Tstart : N
            idx = idx + 1;
            % t0 시점까지의 로그우도 함수
            fun_t = @(b) singleLogLik(t0, y, X3, EstMdl3, b);
            for j = 1:k
                h = eps0;
                % success = false;
                % while ~success && h > min_eps
                %   try
                    b_f = theta3;  b_f(j) = b_f(j) + h;
                    b_b = theta3;  b_b(j) = b_b(j) - h;

                    % ma_f = b_f(p+1:p+q);
                    % ma_b = b_b(p+1:p+q);
                    % ma_f = enforceInvertibleMA(ma_f);
                    % ma_b = enforceInvertibleMA(ma_b);
                    % b_f(p+1:p+q)=ma_f;
                    % b_b(p+1:p+q)=ma_b;
                    % 
                    scores(idx,j) = (fun_t(b_f) - fun_t(b_b)) / (2*h);
                  %   success = true;            % 성공하면 while 탈출
                  % catch ME
                  %   if contains(ME.message,'noninvertible')
                  %     h = h/10;                % h를 줄이고 while 재시도
                  %   else
                  %     break;                   % invertible 외 에러면 포기
                  %   end
                  % end
                % end           
            end
        end
        

        J = (scores' * scores) / Tcnt;
        CovBeta_valid = EstParamCov([2:end], [2:end]);        

        
        % 4) TIC 계산 (EstParamCov = I^{-1} 이므로 penalty = 2·tr(J·I^{-1}) = 2·tr(J·Vbeta))
        penalty = 2 * trace( J * CovBeta_valid );
        TIC3 = -2*logL + penalty;

        % 임시 변수에 저장
        temp_TIC = TIC3;
        temp_Beta = EstMdl3.Beta;
        
        % 루프의 마지막에 한꺼번에 저장 (같은 인덱스 패턴 사용)
        fitted_data{s,5} = temp_TIC;
        fitted_data{s,6} = temp_Beta;
        fitted_data{s, 7} = freq_true;

        %% Plot the data and the fit
        func1 = @(params, t) params(1) * t.^2 + params(2) * t + params(3);

        func2 = @(params,t) params(1) * t.^2 + params(2) * t + params(3)+...
        params(4)* cos(omega_true * t) + params(5)*sin(omega_true * t);

        func3 = @(params,t) params(1) * t.^2 + params(2) * t + params(3)+...
        params(4)* cos(omega_true * t) + params(5)*sin(omega_true * t) + params(6) * (t.*cos(omega_true*t)) + params(7) * (t.*sin(omega_true*t));

        funcs = {func1, func2, func3};
        popts = {fitted_data{s, 2},fitted_data{s, 4},fitted_data{s, 6}};
        TICs = [TIC1, TIC2, TIC3];

        figure1=figure();
        set(figure1, 'Position', [100, 100, 1200, 300]); % [left, bottom, width, height]

        % Add 'data_name' as the title for the entire figure
        sgTiT = sprintf('%s %d freq=%.1f',data_name,s, fitted_data{s,7});
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

            TiT = sprintf('TIC = %.4f',TICs(ii));
            title(TiT);       
        end
           
        save_Dir = fullfile(saveDir,data_name);

        if (~exist(save_Dir,'dir'))
            mkdir(save_Dir) ;
        end
        cd(save_Dir)
        saveas(figure1,[num2str(s) '.png']);
        exportgraphics(figure1,[num2str(s) '.pdf']);
        hold off;
    end

    save(fullfile(dataDir, data_name), 'fitted_data');
end
