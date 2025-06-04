%% Instantaneous Phase Check between Perf and Visi
clear; clc; close all;

rawDir = 'C:\Users\sugeun\Desktop\Rhythmic_Attention\Data\6_ModelAlign\Hilbert';
cd(rawDir)
figDir = 'C:\Users\sugeun\Desktop\Rhythmic_Attention\Figure\Figure6\Phase';

data_selected = uigetfile('', '*.*', 'MultiSelect', 'on');  % Select behavior rawdata_anl file.
    
comparison = {'PV','VI'};
for v = 1:1
    ver = comparison{v}
        
    % Define indices and offset
    if strcmp(ver, 'PV')
        indices = [1, 2, 3, 4, 9, 10, 11, 12];
        offset = 4;
    elseif strcmp(ver, 'VI')
        indices = [1, 2, 5, 6, 9, 10, 13, 14];
        offset = 2;
    end
    
    
    % Loop through the indices
    for i = 1:length(indices)
        first_ind = indices(i);
        second_ind = first_ind + offset;
        
        first_name = data_selected{1,first_ind};
        conds = split(first_name); % Adjust delimiter as needed
    
        second_name = data_selected{1,second_ind};
    
        % Load the instantaneous phase data
        load(first_name);
        phase1 = instantaneous_phase; % Perf/Invalid
    
        load(second_name);
        phase2 = instantaneous_phase; % Visi/Valid
    
        % Compute phase difference
        phase_diff = phase1 - phase2;
        
        % Compute phase difference
        phase_diff = wrapToPi(phase1 - phase2);
        
        Figure1 = figure;
        polarplot(0, 0, 'k','HandleVisibility', 'off'); % Initialize polar plot
        hold on
    
        [nSubj, nTimepoint] = size(phase_diff);
        avg_angle_all = [];
        pvals = [];
        z_all = [];
        n = 0;
        
    
        for subj = 1:nSubj
            subj_phase_diff = phase_diff(subj,:);        
            % Run Rayleigh test for clustering
            [pval, z] = circ_rtest(subj_phase_diff);
            % Store the p-value
            pvals = [pvals; pval];
            z_all = [z_all, z];   
            % Angle mean
            avg_angle = circ_mean(subj_phase_diff, [], 2);
            avg_angle_all = [avg_angle_all, avg_angle];        
        end    



        % Step 2: Apply FDR BH correction
        alpha = 0.05;    
        [h, crit_p, adj_ci_cvrg, adj_pvals] = fdr_bh(pvals, alpha, 'pdep', 'no'); 
        
        sig_phase_all = [];
        sig_avg_angle = [];
        sig_z_all = [];
        
        % Plot significant angle
        for subj = 1:nSubj
            if h(subj)
                % Add average angle as a line on the polar plot
                compassplot(avg_angle_all(subj), z_all(subj), Color = 'black', LineWidth=1,HandleVisibility='off'); % Line for average angle
                sig_phase_all = [sig_phase_all phase_diff(subj,:)];
                sig_avg_angle = [sig_avg_angle avg_angle_all(subj)];
                sig_z_all = [sig_z_all z_all(subj)];
                n = n + 1;
            end
        end
    
        rl = rlim;
        
        % Mean angle only for significant
        [pval, z] = circ_vtest(sig_avg_angle, 0); 
        pval
        z
        mu = circ_mean(sig_avg_angle,[],2);
        mu = wrapToPi(mu);
        m2 = polarplot([0,mu], rl, Color = 'blue',LineWidth= 4, DisplayName='Mean significant');   
        
        
        if strcmp(ver, 'PV')
            TiT = sprintf('%s %s %s', conds{3}, conds{5}, conds{6});
        elseif strcmp(ver, 'VI')
            TiT = sprintf('%s %s %s', conds{3}, conds{4}, conds{6});
        end
        
        title(sprintf('%s\n n=%d', TiT,n));
        
        % legend();
        
        saveDir = fullfile(figDir, ver);
        if ~exist(saveDir, 'dir')
            mkdir(saveDir);
        end
        
        % saveas(Figure1, fullfile(saveDir, [ TiT '250325.pdf']));
        hold off
    end
    % close all
end