%==========================================================================
% SCRIPT: Split_eeg_by_epoch_label
%
% DESCRIPTION:
%   This script automatically processes pre-epoched EEGLAB dataset (.set) files 
%   and splits them into separate, distinct datasets based on their event bin 
%   labels (e.g., 'B1(Tactile_2)', 'B2(Auditory)', etc.). 
%
%   It features a robust label-cleaning workaround to handle instances where 
%   an individual epoch is accidentally tagged with multiple event labels or 
%   empty marker remnants (e.g., a 1x2 nested cell array like {'B1(Tactile_2)', '42'}). 
%   The script filters these anomalies out by evaluating string character 
%   lengths, prioritizing and isolating the primary, informative description.
%
%   Furthermore, the script cuts down tracking parameters stored within your custom 
%   `Cumulative_ERP_averaging` structure to ensure the custom trial metrics 
%   remain aligned with the freshly subsetted data, cross-checking alignments 
%   via rigorous assertion tests.
%
% WHAT THIS SCRIPT DOES STEP-BY-STEP:
%   1. Configures working folder paths dynamically and initializes EEGLAB.
%   2. Opens a GUI file selector allowing you to select one or multiple .set files.
%   3. Loops through each selected subject file.
%   4. Cleans mixed/multi-labeled epoch identifiers by resolving cell arrays 
%      and keeping exclusively the longest text label.
%   5. Identifies the complete set of unique condition labels present in the file.
%   6. Subsets the main EEG data matrix to isolate only the trials matching 
%      a given condition label.
%   7. Slices corresponding custom tracking metrics (`averaged_data`, `ERP_latencies`, 
%      and `ERP_is_component`) along the 3rd dimension (trials).
%   8. Asserts that the trial numbers between the data matrices and structural 
%      tracking fields perfectly match to guarantee structural integrity.
%   9. Updates the EEGLAB history log and saves the new conditions as clean, 
%      split `.set`/`.fdt` datasets inside a newly targeted subfolder.
%
% HOW TO USE IT:
%   1. Open MATLAB and navigate to the directory holding this script.
%   2. Run the script (`F5` or type its name in the Command Window).
%   3. A file selection dialogue window will pop up. Highlight the dataset 
%      or multiple datasets you want to split and press 'Open'.
%      (Note: You can use Ctrl+Click or Shift+Click to select multiple files).
%   4. Watch the progress outputs printed to the Command Window.
%   5. Check your output files. The script creates a new folder named 
%      'Stimulation_series_split_<stimulation label>' inside your original data path, 
%
% REQUIREMENTS / DEPENDENCIES:
%   - EEGLAB toolbox installed and accessible in the MATLAB path.
%   - Custom functions: `loadEEGfile.m`, `addHistory.m`, and `recursivelySaveFile.m` 
%     must be located in the relative subdirectories ('gui', 'functions', etc.).
%
% AUTHOR: PhD EEG Pipeline Project
% DATE: January 2026
%==========================================================================

clearvars -except; close all; clc


%% ===== CONFIGURE PATHS =====
% Determine curr_path robustly
mf = mfilename('fullpath');
if ~isempty(mf)
    curr_path = fileparts(mf);
else
    w = which('MAIN_ERP_preprocessing');
    if ~isempty(w)
        curr_path = fileparts(w);
    else
        curr_path = pwd;
    end
end
% Add only required code folders (adjust names as necessary)
addpath(fullfile(curr_path, 'gui'));
addpath(fullfile(curr_path, 'functions'));
addpath(fullfile(curr_path, 'ElectrodesLocations'));
addpath(fullfile(curr_path, 'Eventlists'));

eeglab;
close all


%% ===== Select files =====
[EEG_files, location] = uigetfile("*.set", "MultiSelect", "on");

for subjectNo = 1:length(EEG_files)
    fprintf("\nLoading subject %d out of %d\n", subjectNo, length(EEG_files))
    
  
    % Load EEG data
    EEG = loadEEGfile(location, EEG_files{subjectNo});

    % Get epochs labels. The problem is that sometimes there is more than
    % one label in the epoch (for example there are empty events)
    % this is why we need the following workaround:

    all_epoch_labels = {EEG.epoch.eventbinlabel};
    
    % Loop through each epoch's labels
    for i = 1:numel(all_epoch_labels)
        current_item = all_epoch_labels{i};
        
        % Check if this epoch has multiple labels (e.g., 1x2 cell)
        if iscell(current_item) && numel(current_item) > 1
            % Calculate the character length of each label inside this cell
            lengths = cellfun(@strlength, current_item);
            
            % Find the index of the longest string
            [~, max_idx] = max(lengths);
            
            % Replace the 1x2 cell with just that single longest string
            all_epoch_labels{i} = current_item{max_idx};
            
        elseif iscell(current_item) && numel(current_item) == 1
            % If it's a 1x1 cell, unwrap it to a regular string/char vector
            all_epoch_labels{i} = current_item{1};
        end
    end

    % Sometimes there are more than one label per epoch, so this is a
    % workarounf to get unique labels:
    % raw_labels = {EEG.epoch.eventbinlabel};
    % flat_strings = string([raw_labels{:}]);
    % unique_epoch_labels = unique(flat_strings);
    % unique_epoch_labels = unique_epoch_labels((strlength(strtrim(unique_epoch_labels)) > 4));
    unique_epoch_labels = unique(all_epoch_labels);

    % Process each unique epoch
    for epochNo = 1:length(unique_epoch_labels)
        epoch_label = unique_epoch_labels{epochNo};
        fprintf("Processing epochs: %s \n", epoch_label);
        
        new_filename = strcat(strrep(EEG.filename, ".set", ""), "_", epoch_label);
        new_filename = strrep(new_filename, "(", "");
        new_filename = strrep(new_filename, ")", "");
        new_foldername = sprintf('Stimulation_series_split_%s', epoch_label);
        matching_positions = find(strcmp(all_epoch_labels, epoch_label));

        EEG_epoch = pop_epoch(EEG, ...
                              unique_epoch_labels{epochNo}, ...
                              [EEG.xmin  EEG.xmax], ...
                              'newname', new_filename,...
                              'epochinfo', 'yes');
        EEG_epoch.filename = new_filename;
        EEG_epoch.filepath = fullfile(location, new_foldername);

        % Select epochs from EEG_epoch.Cumulative_ERP_averaging
        EEG_epoch.Cumulative_ERP_averaging.averaged_data = EEG_epoch.Cumulative_ERP_averaging.averaged_data(:, :, matching_positions);
        EEG_epoch.Cumulative_ERP_averaging.ERP_latencies = EEG_epoch.Cumulative_ERP_averaging.ERP_latencies(:, :, matching_positions);
        EEG_epoch.Cumulative_ERP_averaging.ERP_is_component = EEG_epoch.Cumulative_ERP_averaging.ERP_is_component(:, :, matching_positions);

        assert(size(EEG_epoch.Cumulative_ERP_averaging.averaged_data, 3) == EEG_epoch.trials, 'Mismatch! EEG_epoch.Cumulative_ERP_averaging.averaged_data vs EEG_epoch.trials');
        assert(size(EEG_epoch.Cumulative_ERP_averaging.ERP_latencies, 3) == EEG_epoch.trials, 'Mismatch! EEG_epoch.Cumulative_ERP_averaging.ERP_latencies vs EEG_epoch.trials');
        assert(size(EEG_epoch.Cumulative_ERP_averaging.ERP_is_component, 3) == EEG_epoch.trials, 'Mismatch! EEG_epoch.Cumulative_ERP_averaging.ERP_is_component vs EEG_epoch.trials');
    

        % Save to a file
        EEG_epoch = addHistory(EEG_epoch, sprintf("Selected ony epochs labeled: %s", epoch_label), []);
        recursivelySaveFile(EEG_epoch, ...
                            location, ...
                            new_foldername, ...
                            new_filename);
    end



end


