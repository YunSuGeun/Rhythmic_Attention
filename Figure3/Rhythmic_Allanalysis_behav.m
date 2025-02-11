%% To use these scripts
% (0) At first, Choose CombiningDATA(one subject mat file including all blocks)
%    -Yon can choose more than one combining_data: DATA
% (1) You should choose one of analysis  
%    -Drag the analysis and run. 
% (2) You can manipulate the parameters for the analysis. The parameters that you can manipulate are written in each analysis explanations
% (3) analysis 
%       0. Select data 
%       1-1. Behavioral waveform (50ms ~ 1500ms) 
%       1-2. Behavioral waveform (75ms ~ 1475ms)
%       1-3. Behavior Analysis for graph
%       1-4. Behavior Analysis for graph  ver 02 (Pre +Pos in One graph)
%       2. Behavior Analysis+ visi Trials number
%       3-1. Performance (y axis) per Visibility (x axis)
%       3-2. Proportion(The number of Trials)  (y axis) per Visibility (x axis)
%       4. Behavior Analysis collaps time Bar graph
%       5-1.A generalized linear model (GLM) analysis
%       5-2. Calculate effect size with Jackknife simulation


%% 0 Select data 
for iiii = 1:1
    clear all; clc; close all
   

%-------setting rawdata path 
    t = datetime('now');
    genDir = 'C:/Users/user/Desktop/Rhythmic_Attention/';
    rawDir = fullfile(genDir,'Data','2_PreprocessedData','Rhythm_Perception'); %%분석할 데이터
    oldDir = pwd;
    cd(rawDir);
%-------select rawdata 
    disp('** 1. Select behavior data(Double data)**')
    data_name = uigetfile('', '*.*', 'MultiSelect', 'on');  % Select behavior rawdata_anl file. 
%     cd(oldDir);
    NoS = length(data_name);
%     outDir = fullfile(genDir,'data');

    if iscell(data_name) == 0
        num_data = 1;
        subjName{1} = data_name(1:3);
    elseif iscell(data_name) ==1
        num_data = size(data_name,2);
    end

 %% ------------- 0. DATA setting from raw data
%data{subj}(:,2)  = trial
%data{subj}(:,8)  = ACC
%data{subj}(:,7)  = timepoint
%data{subj}(:,3)  = Validity
%data{subj}(:,9)  = absent or not
%data{subj}(:,10) = EndSaccad
%data{subj}(:,11) = Visi
%data{subj}(:,1)  = Block
%data{subj}(:,5) = Right or Left

    for i = 1:num_data
        if iscell(data_name) == 1
            subjName{i}= data_name{1,i}(1:3);
        elseif iscell(data_name) == 0
            data_name1 = data_name;
            clear data_name;
            data_name{1}= data_name1;  %%%%%%%%%%% WTF!!!!!!!
        end
        %for i = 1:size(DATA,1);
        DATA = [];
        DATA_sub=load(data_name{1,i});
        %%
        DATA1 = [DATA_sub.cleaned_data];
        data{1,i} = DATA1;
    end
  % setting bacis parameter
    Error = 1;
    Visi_start  =1;
    Visi_End  = 8;
    Block_First=1;
    Block_Last=6;
    a= 0;
    band = [0.1 14];%[0.1 14];
    saveDir = fullfile(genDir,'Data/3_BehavioralData');
end
%% --------------------------------Analysis start------------------------------------------------------
    %% 1-1. Behavioral waveform Analysis
    % data length : 50ms ~ 1500ms 
    % This script is for making behavioral oscillaion of each conditions
    % Method(performance or visibility) x Cue condition(pre or post cue) x Cue position to eye(left,right, or both) / Validity(valid, invalid) x Block (1~6) 
    % When you make "Wave forms", you can manipulate  

Det = 2;     
Binsize =100;
Save = 0; 
Group = 1;
Visi_Trials =0 ;
fft_data_length = 146;%
Save_data4_kyj =1;
NaNerror =1;
save_folder = saveDir;
if exist(save_folder) == 0
    mkdir(save_folder)
end
cd(save_folder); % Save dir
for iiiiiii = 1:1
    aaa = 0;
    for Block_Last =6:6
        for Method = 1:2 %% perf, visi
            for Cue_Cond =1:2 %% pre, post
%                 close all;
                for LR = 0:0 %% Cue를 기준으로 할지 Target 기준으로 할지? %% 당연히 타겟 기준으로 congruent, incongruent cue를 봐야하지 않나
                    for LR_c =1:2 %% 어차피 both cue가 없는데?
                        if LR >=1 && LR_c >=1
                            msg = '****Warning**** Please set which stimulus location you want analyze: Target location?(LR_c =0) or Cue location?(LR =0)';
                            error(msg) ;
                        end 
                        if LR ==1 && LR_c ==0
                            Side{1} = 'Right';
                        elseif LR ==2 && LR_c ==0
                            Side{1} = 'Left';
                        elseif LR ==0 && LR_c ==0
                            Side{1}= 'Both';
                        end
                        if LR_c ==1 && LR ==0
                            Side{1} = 'Right-C';
                        elseif LR_c ==2 && LR ==0
                            Side{1} = 'Left-C';
                        end
                        a = a+1;
                        data_pooled=[];
%------------ setting data again
                        for subj=1:num_data
                            data_subj=[];
                            data_subj(:,1)= data{subj}(:,2); %data{subj}(:,2) = trial
                            data_subj(:,2)= data{subj}(:,8); %data{subj}(:,8) = ACC
                            data_subj(:,3)= data{subj}(:,7);  %data{subj}(:,7) = timepoint
                            data_subj(:,4) = data{subj}(:,3);%data{subj}(:,3) = Validity
                            data_subj(:,5) = data{subj}(:,9);%data{subj}(:,9) = absent or not
                            data_subj(:,6) = data{subj}(:,12);%data{subj}(:,10) = EndSaccad
                            data_subj(:,7) = data{subj}(:,11);%data{subj}(:,11) = Visi %% 원래는 data{subj}(:,11)-1 이었는데 '-1'부분 빼버림 - 수근
                            data_subj(:,8) = data{subj}(:,1); %data{subj}(:,1) Block
                            data_subj(:,9) = data{subj}(:,5); % data{subj}(:,5)Right or Left
                            data_pooled=data_subj;
                            %mean(data_pooled(find(data_pooled(:,5) == 0),2))
%------------- binning paramaters
                            if Cue_Cond ==1
                                binning_param.BINSIZE=(-1)*Binsize; % [ms]
                                binning_param.STEP=-10; % [ms]
                                binning_param.min_lat = -50; % Gabor presentation time with respect to movement onset [ms]
                                binning_param.max_lat = -1500;
                            elseif Cue_Cond ==2
                                binning_param.BINSIZE=Binsize; % [ms]
                                binning_param.STEP=10; % [ms]
                                binning_param.min_lat = 50; % Gabor presentation time with respect to movement onset [ms]
                                binning_param.max_lat = 1500;
                            end
                            Valid = 1;
                            Invalid= 2;
                            V = Valid;
                            %V= Invalid;
% ------------This is optional for confirming the number of each visibility
                            for visi = 1:8
                                Visi_Tri_number(subj,visi) = size(data_pooled(find(data_pooled(:,7) ==visi & data_pooled(:,5) ==0 &  data_pooled(:,6) ==0)),1);
                            end
% ------------Making wave forms for valid and invalid condition---------                           
                            for iii = 1:2
                                Validity = iii;
                                if Method == 2 
                                    M_name{1} = 'Visi';
                                    [RESULTS_Behavior]= Mov_Visi_YL_Cueresetting(data_pooled,Validity,binning_param,Visi_start,Visi_End, Block_First,Block_Last,LR,LR_c);
 		                                        % RESULTS_Visi = center bin / Mean Visibility / Nan/ N trials in Timewindow %                             
                                elseif Method == 1 
                                    M_name{1} = 'Perf';
                                    [RESULTS_Behavior]= MovAverage_Performance_YL_Cueresetting(data_pooled,Validity,binning_param,Visi_start,Visi_End, Block_First,Block_Last,LR,LR_c);
 		                                % Result_Behavior array= time window 중앙값/평균 ACC/Standard Error/ n trials in time window / confidence interval                                
                                end
%                                 mean(data_pooled(data_pooled(:,4) ==1  & data_pooled(:,3) > 0 & data_pooled(:,5) ==0 & data_pooled(:,6) ==0 ));
                                Behav_data{subj,iii} = RESULTS_Behavior([1:1:fft_data_length] ,:);
                                Behav_SD{subj,iii} = std(RESULTS_Behavior([1:1:fft_data_length],2),0,1,'omitnan');
                                
                                if Visi_Trials == 1
                                    [RESULTS_Visi]= MovSum_VisiTrials_YL(data_pooled,Validity,binning_param,Visi_start,Visi_End, Block_First,Block_Last);
                                    Behav_Trials{subj,iii} = RESULTS_Visi;
                                end
                                
                                
                                if Cue_Cond ==1
                                    C = 'Pre';
                                else
                                    C = 'Pos';
                                end
                                if Validity ==1
                                    VV{1} = 'valid';
                                elseif Validity ==2
                                    VV{1} = 'invalid';
                                end
                                %% -------Data
                                bd = Behav_data{subj,iii};
                                sd = Behav_SD{subj,iii};
                                if Method==1  % Basic Average
                                    Transbd{subj,iii} =  Behav_data{subj,iii}(:,2);
                                    M_name{1} = 'Perf';
                                    y_name{1} = 'Correct Accuracy';
                                    y_range = [50 100];%  [60 95] ;%[0, 100]; %
                                    Center = [80 80];
                                elseif Method== 2
                                    Transbd{subj,iii} =  Behav_data{subj,iii}(:,2);
                                    M_name{1} = 'Visi';
                                    y_name{1} = 'Visibility';
                                    y_range =[2.5 5.5];%[2.5, 5.5]; % [0 8];% [1 8]
                                    Center = [4.5 4.5]; %% 원래 3.5 3.5 였는데 평균인 4.5로 바꿈
                                end
                                
                                if Visi_Trials == 1
                                    %                                 sd = Behav_SD{subj,iii};
                                    Transbd_Trials{subj,iii} =  Behav_Trials{subj,iii};
                                    TransTrials_Valid = Transbd_Trials{subj,Valid} ;
                                    TransTrials_Invalid = Transbd_Trials{subj,Invalid} ;
% %%%
% Transbd_Trials = 2X8 array
% 1, 2, 3, 4, 5, 6, 7, 8
% 각 visibility가 몇 trial씩 있는지
% 각 Validity마다 다름
% %%%                                    
                                    
                                end
                            end
                        end
                        %%
                        if Group == 1
                            for subj=1:num_data
                                Transbd_Valid(:,subj) = Transbd{subj,Valid} ;
                                Transbd_Invalid(:,subj) = Transbd{subj,Invalid};
                                %                                 Transbd_att_effect(:,subj) = Transbd{subj,3};
                            end
                            % ----------- NaN alram  --------------------
                            if NaNerror ==1
                                if sum(sum(isnan(Transbd_Valid))) >=1
                                    errmessage=  sprintf('****%d NaN has occurred in Valid condition %d ms %s %s V (%s)****',sum(sum(isnan(Transbd_Valid))),Binsize,C,M_name{1},Side{1});
                                    disp(errmessage);
                                    
                                end
                                if sum(sum(isnan(Transbd_Invalid))) >=1
                                    errmessage=  sprintf('****%d NaN has occurred in Invalid condition %d ms %s %s V (%s)****',sum(sum(isnan(Transbd_Invalid))),Binsize,C,M_name{1},Side{1});
                                    disp(errmessage);
                                    
                                end
                            end
                            % -----------Visi trials mean---------
                            if Visi_Trials ==1
                                meanTri_Valid = mean(TransTrials_Valid,2);
                                meanTri_Invalid = mean(TransTrials_Invalid,2);
                            end
                            % ----------Detrend or not? 
                            if Det == 2 % no detrend
                                mean_Valid = nanmean(Transbd_Valid,2);
                                mean_Invalid = nanmean(Transbd_Invalid,2);
%                                  mean_att_effect = nanmean(Transbd_att_effect,2);
                                sd_Valid =nanstd(Transbd_Valid,0,2)/sqrt(num_data);
                                sd_Invalid = nanstd(Transbd_Invalid,0,2)/sqrt(num_data);
%                                  sd_att_effect =std(Transbd_att_effect,0,2)/sqrt(num_data);
                            end

                            if LR_c ==2  %%왜 left cue만 Lalpha = 0.5? 겹쳐뒀을 때 잘 보이게
                                Lalpha = 0.5;
                            else 
                                Lalpha = 1;
                            end 
                            
                            %visi Trial
                            mean_visi_Trials = mean(Visi_Trials,1);
              %--------------------Group graph-----------------------
                            figure1= figure;
                            if Error ==1
                                axe_X  = [NaN NaN NaN NaN Behav_data{1,1}(:,1)'];
                                %set(groot,'defaultLineLineWidth',2.0)
%                                 Plot_V = plot(axe_X, [NaN NaN NaN NaN mean_Valid'],'b','DisplayName','Valid')
%                                 hold on;
%                                 Plot_I = plot(axe_X, [NaN NaN NaN NaN mean_Invalid'],'r','DisplayName','Invalid')
%                                 legend('Valid', 'Invalid','');
                                l2=shadedErrorBar(axe_X, [NaN NaN NaN NaN mean_Valid'],[NaN NaN NaN NaN sd_Valid'],'b',0.5,0.05,2.5,Lalpha);
                                hold on
                                l1=shadedErrorBar(axe_X,[NaN NaN NaN NaN mean_Invalid'],[NaN NaN NaN NaN sd_Invalid'],'r',0.5,0.05,2.5,Lalpha);
                            elseif Error ==2
                                plot(Behav_data{1,1}(:,1), mean_Valid', 'b');
                                hold on;
                                plot(Behav_data{1,1}(:,1), mean_Invalid', 'r');
                            end
                            if Cue_Cond == 2
                                xlim([0 Behav_data{1,1}(end,1)]);
                            elseif Cue_Cond ==1
                                xlim([Behav_data{1,1}(end,1) 0]);
                            end
                            box off 
                            line(xlim,[0,0],'Color',[0.5,0.5,0.5],'LineWidth', 1.5, 'LineStyle', '-.')
                            line(xlim,Center,'Color',[0.5,0.5,0.5],'LineWidth', 1.5, 'LineStyle', '-.')
                            line([50 50], y_range,'Color','k','LineWidth', 1.5, 'LineStyle' ,':')
                            line([-50 -50], y_range,'Color','k','LineWidth', 1.5, 'LineStyle' ,':')                            
                            ylim(y_range);
                            x = [0 50 50 0];
                            y = [-3 -3 3 3];
                            xlabel('Cue-to-target Interval')
                            ylabel(y_name{1})
                            GG =gca;
                            GG.FontSize = 11;

                            if Cue_Cond ==1
                                C = 'Precue';
                            else
                                C = 'Postcue';
                            end
                            TiT =  sprintf('%s %d-%d %s Group %d ms %d tp (%d-%d block) %s.png', M_name{1},Visi_start , Visi_End  ,C, Binsize,fft_data_length,Block_First,Block_Last,Side{1});
                            title( TiT);
                            if Save == 1
                                saveas(figure1, TiT);
                            end
                             if Save_data4_kyj ==1
                                Group_data = Transbd_Valid';
                                Title=  sprintf('%d ms %s %s V (%s).mat',Binsize,C,M_name{1},Side{1}); %% V = Valid
                                save(Title, 'Group_data');% save(TiT, 'RESULTS_Behavior');                                
                                Group_data = Transbd_Invalid';
                                Title=  sprintf('%d ms %s %s I (%s).mat',Binsize,C,M_name{1},Side{1}); %% I = Invalid
                                save(Title, 'Group_data');% save(TiT, 'RESULTS_Behavior');                                   
                             end  

                        end

                    end
                end
            end
            
        end
    end
end 
cd(oldDir);

                           