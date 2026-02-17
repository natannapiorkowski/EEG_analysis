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

%    !!!! APP SETTINGS !!!!
Settings = {};
Settings.min_number_of_epochs = 50;
Settings.ERP_search_window = 0.01;
Settings.xlim = [-0.5, 0.5];
% -------------------------------



[filenames, pathname] = uigetfile('*.set','Select Files', 'MultiSelect', 'on');
if ischar(filenames)
    filenames={filenames};
end

%% Run analysis
for subjectNo = 1:length(filenames)
    % Load EEG data
    EEG = loadEEGfile(pathname, ...
                      filenames{subjectNo}, ...
                      fullfile(curr_path, 'ElectrodesLocations'));


    EEG = Average_epochs_GUI.run_app(EEG, Settings);
    EEG = addHistory(EEG, "Cumulative ERP averaging", []);
    recursivelySaveFile(EEG, ...
                        pathname, ...
                        'Cumulative_ERP_averaging', ...
                        filenames{subjectNo});

end
    
