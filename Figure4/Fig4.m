%% IRASA using Kastner method

clear; clc;

addpath('C:/Users/user/Desktop/fieldtrip-20240916')
ft_defaults


rawDir = 'C:\Users\user\Desktop\Rhythmic_Attention\Data\3_BehavioralData';
    
cd(rawDir)

% Load or initialize your data
data_selected = uigetfile('', '*.*', 'MultiSelect', 'on');  % Select behavior rawdata_anl file. 


if isempty(gcp('nocreate'))
    parpool; % This opens the default number of workers
end
    
for i = 1: length(data_selected)
    close all;
    cd(rawDir);
    data_name = data_selected{1,i};
    load(data_name);
    data = Group_data;

    if data_name(8:10) == 'Pre'; Cue_Cond = 1; elseif data_name(8:10) == 'Pos'; Cue_Cond = 2; end
        
    %% IRASA setup
    timepoint = [0.05: 0.01: 1.5];
    if Cue_Cond ==1; timepoint = flip(timepoint) .* -1 ; end
    
    freqs= [2:0.1:10];

    %% IRASA
    num_data = size(data,1);
    fractal_n = zeros(8,81,num_data);; original_n =zeros(num_data,81); oscillatory_n=zeros(num_data,81);;

    parfor subj_n = 1:num_data
        
        data_redef =[];
        data_redef.label = {'chan001'};
        data_redef.time = timepoint;
        
        trial = data(subj_n,:);
        data_redef.trial = trial;

        
        cfg               = [];
        cfg.foilim        = [2 10];
        
        cfg.polyremoval = 2;
        
        cfg.taper = 'hanning';
        
        cfg.pad           = 10; % zero padding
        
        cfg.method        = 'irasa';

        cfg.output        = 'fractal';
        fractal = ft_freqanalysis(cfg, data_redef);

        cfg.output       = 'original';
        original = ft_freqanalysis(cfg, data_redef);

        % subtract the fractal component from the power spectrum
        cfg_math               = [];
        cfg_math.parameter     = 'powspctrm';
        cfg_math.operation     = 'x2-x1';
        oscillatory = ft_math(cfg_math, fractal, original);

        original_n(subj_n,:) = original.powspctrm;
        oscillatory_n(subj_n,:) = oscillatory.powspctrm;
        
        
        % Fractal computation by Kastner method
        for k = 1:8
            data_fractal =[];
            data_fractal.label = {'chan001'};
            data_fractal.time = timepoint(1:111);

            trial = data(subj_n,5*k - 4 : 5*k + 106 );
            data_fractal.trial = trial;


            cfg               = [];
            cfg.foilim        = [2 10];

            cfg.polyremoval = 2;

            cfg.taper = 'hanning';

            cfg.pad           = 10; % zero padding

            cfg.method        = 'irasa';

            cfg.output        = 'fractal';
            fractal = ft_freqanalysis(cfg, data_fractal);
            
            fractal_n(k,:,subj_n) = fractal.powspctrm;
        end
        

    end

    
    %% save info
        
    % Construct the title
    TiT = data_name;

    
    saveDir = 'C:/Users/user/Desktop/Rhythmic_Attention/Data/4_IRASAData';
    if (~exist(saveDir,'dir'))
        mkdir(saveDir) ;
    end
  
    cd(saveDir);
    
    IRASA_info = [];
    IRASA_info.name = TiT;
    IRASA_info.ori = original_n;
    IRASA_info.osc = oscillatory_n;
    IRASA_info.fra = fractal_n;
    
    save(TiT, 'IRASA_info');
    
    %% Plot individual
    all_subject_peaks = zeros(num_data,2);
    
    for subj_n = 1:num_data 
        
        figure1 = figure;
        
        ori = original_n(subj_n,:);
        MaxOri = max(ori);
        ori = ori / MaxOri;
        plot(freqs,ori,'-k', 'DisplayName','Original')
        hold on
        title('Original vs fractal')

        
        fra = fractal_n(:,:,subj_n);        
        fra = fra /  MaxOri;
        mean_fra = mean(fra,1);
        sem_fra = std(fra,0,1) / sqrt(size(fra,1));
        L1 = shadedErrorBar(freqs, mean_fra, sem_fra, {'-r','DisplayName','Fractal'},0,0.1,4,1); % Red color line
        
        %% Peak identification
        % identify peaks where Original is higher than mean Fractal
        % also should be peak where slope change from positive to negative
        % save peak freuencies at specific array and save to local saveDir
        % mark peak frequencies at figure and write the frequencies
        [peak_freqs, peak_indices] = identify_peaks(freqs, ori, mean_fra);
        
        freq_over_3_indices = find(peak_freqs >= 2.75);
        
        if isempty(freq_over_3_indices)
            close(figure1); % Close the figure
            continue;       % Skip to the next subject
        end       
        
        freq_over_3_freqs = peak_freqs(freq_over_3_indices);
        original_over_3 = ori(peak_indices(freq_over_3_indices));
        [sorted_powers, sorted_indices] = sort(original_over_3, 'descend');
        peak_freq_power = sorted_powers(1);
        peak_frequency = freq_over_3_freqs(find(original_over_3 == peak_freq_power));
        
        all_subject_peaks(subj_n,1) = peak_frequency;
        
         % Highlight peaks
        plot(freqs(peak_indices), ori(1,peak_indices), 'go', 'MarkerSize', 10, 'DisplayName', 'Peaks');
        
        for i = 1:length(peak_indices)
            text(freqs(peak_indices(i)), ori(1,peak_indices(i)), ...
                 sprintf(' %.2f Hz', freqs(peak_indices(i))), ...
                 'VerticalAlignment', 'bottom');
        end
        
        xlabel('Frequency');
        ylim([0 1.1]);
        grid on;
        ylabel('Power');

        figDir = sprintf('C:/Users/user/Desktop/Rhythmic_Attention/Figure/Figure4/%s',TiT);
        if (~exist(figDir,'dir'))
            mkdir(figDir) ;
        end

        cd(figDir)
        saveas(figure1, sprintf('%d.png', subj_n)); % Proper filename formatting
        hold off
    end
    cd(saveDir)
    save(['subject_peaks_' TiT '.mat'], 'all_subject_peaks');
    
end
