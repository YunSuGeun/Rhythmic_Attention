    clear all; clc;
    
    t = datetime('now');

% input_folder = 'C:/Users/user/Desktop/Rhythmic_Attention/data/Preprocessed_TC_50_300_2_30 20240619/Ex2_Perc'
% input_folder = 'C:/Users/user/Desktop/Rhythmic_Attention/data/Preprocessed_TC_50_300_2_30 20240619/Ex1_WM'
input_folder = 'C:/Users/user/Desktop/Rhythmic_Attention/data/Combined rawdata/Ex2_Perc'


    output_folder = 'C:/Users/user/Desktop/Rhythmic_Attention/data/clean-rawdata' 

    files = dir(fullfile(input_folder, '*.mat'));  % Assuming the files are .mat files

    % Ensure the output folder exists
    if ~exist(output_folder, 'dir')
        mkdir(output_folder);
    end

    % Process each file
    for i = 1:length(files)
        % Load the data from the file
        file_path = fullfile(input_folder, files(i).name);
        data_struct = load(file_path);
        
        % Assuming the data is stored in a variable named 'DATA' in the .mat file
        if isfield(data_struct, 'DATA')
            DATA = data_struct.DATA;
            
            % Clean the data
            cleaned_data = clean_raw_data(DATA);

            % Save the cleaned data to the output folder
            [~, name, ~] = fileparts(files(i).name);
            name = name(14:16)
            name = sprintf('%s_%d_%d_%d', name, t.Year, t.Month, t.Day)
            output_file_path = fullfile(output_folder, [name '_cleaned.mat']);
            save(output_file_path, 'cleaned_data');
        else
            warning('File %s does not contain a variable named DATA', files(i).name);
        end
    end