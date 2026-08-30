clearvars -except; close all; clc
eeglab;
close all


%% ===== SETTINGS ===== 
% window within which ERP amplitude is calculated: mean(peak-window : peak+window)
AMPLITUDE_WINDOW_mSEC = 5; 

% METHODS USED TO CALCULATE PEAK AMPLITUDE:
%  abs_value: Absolute peak height above 0
METHOD = 'abs(P1-N1)'; % 'abs_value'; % 'abs(P1-N1)'

GENERATE_FIGURES = true; % or false

% FIGURES
COMPONENTS_TO_PLOT = {'P1'};




%% ===== CONFIGURE PATHS =====
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
addpath(fullfile(curr_path, 'functions'));

% Get eeg files
[EEG_files, pathname] = uigetfile('*.set','Select Files', 'MultiSelect', 'on');
if ischar(EEG_files)
    EEG_files={EEG_files};
end

%%
amplitude_window_sample = round(EEG.srate * AMPLITUDE_WINDOW_mSEC / 1000);
for subjectNo = 1:length(EEG_files)
    fprintf("\nLoading subject %d out of %d\n", subjectNo, length(EEG_files))
    
    % Load EEG data
    EEG = loadEEGfile(pathname, EEG_files{subjectNo});
    
    if ~isfield(EEG, 'Cumulative_ERP_averaging')
        fprintf('Subject: %s. Missing Cumulative_ERP_averaging', EEG_files{subjectNo})
        continue
    end

    switch METHOD
        case 'abs_value'
            EEG = ERP_amplitude_method_abs_value(EEG, amplitude_window_sample, METHOD);
        
        case 'abs(P1-N1)'
            EEG = ERP_amplitude_method_P1N1difference(EEG, amplitude_window_sample, METHOD);
    end
    

    EEG = addHistory(EEG, sprintf("Amplitude detection. Method: %s", METHOD), []);
    recursivelySaveFile(EEG, ...
                        pathname, ...
                        sprintf("Amplitude_detection__%s", METHOD), ...
                        EEG_files{subjectNo});
   
    plot_amplitudes_as_a_function_of_stimulation_number(EEG, COMPONENTS_TO_PLOT, METHOD, pathname)

    clear EEG
end



