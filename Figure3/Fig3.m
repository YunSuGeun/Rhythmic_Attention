%% to create figure 2 Waves

clear; clc;


rawDir = 'C:\Users\user\Desktop\Rhythmic_Attention\Data\3_BehavioralData';
saveDir = 'C:\Users\user\Desktop\Rhythmic_Attention\Figure\Figure3';
if (~exist(saveDir,'dir'))
    mkdir(saveDir) ;
end

cd(rawDir)

% Load or initialize your data
disp('** 1. Select behavior data(Double data)**')
data_selected = uigetfile('', '*.*', 'MultiSelect', 'on');  % Select behavior rawdata_anl file. 

indices = [1,2,5,6,9,10,13,14];
Coeff = {'Data Name', 'Coeff Valid', 'Coeff Invalid'};
for k = 1: length(indices)
    close all;
    cd(rawDir);
    i = indices(k);
    data_name_i = data_selected{1,i};
    data_name_v = data_selected{1,i+2};
    load(data_name_i);
    data_i = Group_data;
    load(data_name_v);
    data_v = Group_data;

    
    % Extract parts from data_name_i
    parts = regexp(data_name_i, '\d+ ms (\w+) (\w+) . \(([^)]+)\)\.mat', 'tokens');
    if ~isempty(parts)
        part1 = parts{1}{1}; % Postcue
        part2 = parts{1}{2}; % Perf
        part3 = parts{1}{3}; % Left-C / Right-C

        % Construct the title
        TiT = sprintf('%s %s (%s) time course', part1, part2, part3);
    else
        % Fallback title if pattern matching fails
        TiT = sprintf('time course %s', data_name_i);
    end
    
    if part1 =="Precue"; Cue_Cond = 1; elseif part1 == "Postcue"; Cue_Cond = 2; end
    if part2 == "Perf";  Method=1; elseif part2 =="Visi"; Method=2;end

    if Method==1  % Performance
        y_range = [50 100];
        Center = [80 80];
        y_name = 'Accuracy';
    elseif Method== 2 %Visibility
        y_range =[2.5 5.5];
        Center = [4 4]; 
        y_name = 'Visibility';
    end
    
    num_data = size(data_i,1);    
    mean_Valid = mean(data_v,1);
    mean_Invalid = mean(data_i,1);
    sd_Valid =std(data_v,0,1)/sqrt(num_data);
    sd_Invalid = std(data_i,0,1)/sqrt(num_data);
     
    figure1=figure;
    if Cue_Cond == 1;
        axe_X = [[-1500:10:-50] NaN NaN NaN NaN];
        l1=shadedErrorBar(axe_X, [flip(mean_Valid) NaN NaN NaN NaN],[flip(sd_Valid) NaN NaN NaN NaN],'b',0,0.05,2.5,1);
        hold on;
        l2=shadedErrorBar(axe_X, [flip(mean_Invalid) NaN NaN NaN NaN],[flip(sd_Invalid) NaN NaN NaN NaN ],'r',1,0.05,2.5,1);
        set(gca,'xtick',-1500:(1500/3):0);
        set(gca,'xticklabel',{[-1500:(1500/3):-500] 'Target onset'});
        xlim([-1500,0]);
        line([-1500 -1500], y_range,'Color','k','LineWidth', 0.5, 'LineStyle' ,'-' )
        % Linear trend line for mean_Valid
        coeff_Valid = polyfit(axe_X(~isnan(axe_X)), flip(mean_Valid(~isnan(mean_Valid))), 1);
        trend_Valid = polyval(coeff_Valid, axe_X(~isnan(axe_X)));
        plot(axe_X, [trend_Valid NaN NaN NaN NaN], '--b', 'LineWidth', 2);
        % Linear trend line for mean_Invalid
        coeff_Invalid = polyfit(axe_X(~isnan(axe_X)), flip(mean_Invalid(~isnan(mean_Invalid))), 1);
        trend_Invalid = polyval(coeff_Invalid, axe_X(~isnan(axe_X)));
        plot(axe_X, [trend_Invalid NaN NaN NaN NaN], '--r', 'LineWidth', 2);
    
    elseif Cue_Cond == 2;     
        axe_X = [NaN NaN NaN NaN [50:10:1500]];
        l1=shadedErrorBar(axe_X, [NaN NaN NaN NaN mean_Valid],[NaN NaN NaN NaN sd_Valid],'b',0,0.05,2.5,1);
        hold on;
        l2=shadedErrorBar(axe_X, [NaN NaN NaN NaN mean_Invalid],[NaN NaN NaN NaN sd_Invalid],'r',1,0.05,2.5,1);
        set(gca,'xtick',0:1500/3:1500);
        set(gca,'xticklabel',{'Target offset' [500:1500/3:1500]});
        xlim([0,1500]);
        % Linear trend line for mean_Valid
        coeff_Valid = polyfit(axe_X(~isnan(axe_X)), mean_Valid(~isnan(mean_Valid)), 1);
        trend_Valid = polyval(coeff_Valid, axe_X(~isnan(axe_X)));
        plot(axe_X, [NaN NaN NaN NaN trend_Valid], '--b', 'LineWidth', 2);
        % Linear trend line for mean_Invalid
        coeff_Invalid = polyfit(axe_X(~isnan(axe_X)), mean_Invalid(~isnan(mean_Invalid)), 1);
        trend_Invalid = polyval(coeff_Invalid, axe_X(~isnan(axe_X)));
        plot(axe_X, [NaN NaN NaN NaN trend_Invalid], '--r', 'LineWidth', 2);        
    end
    
    box off;

    ylim(y_range);
    
    line(xlim,[0,0],'Color',[0.5,0.5,0.5],'LineWidth', 1.5, 'LineStyle', '-.');
    line([50 50], y_range,'Color','k','LineWidth', 1.5, 'LineStyle' ,':');
    line([-50 -50], y_range,'Color','k','LineWidth', 1.5, 'LineStyle' ,':');

    x = [0 50 50 0];
    y = [-3 -3 3 3];
    
    xlabel('Cue-to-target Interval');
    ylabel(y_name);
    GG =gca;
    GG.FontSize = 11;
    
%     if k == 4 | k == 8; legend '' '' 'Valid' '' '' 'Invalid'; end; %legend Çü¼º
       
    TiT =  sprintf('%s Group %s %s', part1, part3, y_name);
    title(TiT);
    
    cd(saveDir);
    saveas(figure1, [TiT '.png']);
    Coeff = [Coeff;
        {TiT,coeff_Valid,coeff_Invalid}];
    hold off;
 
end
save('Coeff','Coeff');
