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

%% SETTINGS
channel = "B16";
maxShift_ms = 150;

%% ===== Select files =====
[EEG_files, location] = uigetfile("*.set", "MultiSelect", "on");
if ischar(EEG_files)
    EEG_files={EEG_files};
end

%%
clc


for subjectNo = 1:length(EEG_files)
    fprintf("\n\n\n")
    fprintf("============================================================\n")
    fprintf("Loading subject %d out of %d \n", subjectNo, length(EEG_files))

    % Load EEG data
    EEG = loadEEGfile(location, EEG_files{subjectNo});
    chan_num = find_channel_by_label(EEG, channel);
    data = squeeze(EEG.data(chan_num, :, :));
    numSamples = size(data, 1);
    numTrials = size(data, 2);
    time = EEG.times;
    maxShift = round(maxShift_ms/1000 * EEG.srate);
    % Normal average
    normal_average = mean(data, 2);

    % Add random number of nans at the beginning of each row
    shuffled_data = nan(size(data));
    % Random shift for each trial
    N = randi([0, maxShift], 1, numTrials);
    average_shift = round(mean(N));
    for i = 1:numTrials
        n = N(i);
        shuffled_data(:, i) = [nan(n, 1); data(1:numSamples-n, i)];
    end

    shuffled_average = mean(shuffled_data, 2, 'omitnan');
    shuffled_average  = [shuffled_average(average_shift+1:end); nan(average_shift, 1)];


    %% Plot!
    figure()
    hold on
    ax = gca;          
    title(sprintf("%s      channel: %s", EEG_files{subjectNo}, channel), 'Interpreter', 'none')
    ax.XAxisLocation = "origin";
    ax.YAxisLocation = "origin";

    % plot normal average
    plot(time, normal_average, 'blue', 'LineWidth', 5, 'DisplayName', 'Normal average')
    line(ax, [min(time(:)) 0], [mean(normal_average) mean(normal_average)], ...
        'LineStyle', '--', 'Color', 'b', 'LineWidth', 1, ...
        'DisplayName', 'normal baseline mean');

    % Plot shuffled average
    plot(time, shuffled_average, "r", 'DisplayName', 'Shuffled average')
    line(ax, [min(time(:)) 0], [mean(shuffled_average, 'omitnan') mean(shuffled_average, 'omitnan')], ...
        'LineStyle', '--', 'Color', 'r', 'LineWidth', 1, ...
        'DisplayName', 'normal baseline mean');
    
    yLimits = ylim(ax); % Returns [lowerLimit upperLimit]
    % [x y width height]
    rectangle('Position', [min(time), yLimits(1), maxShift_ms, yLimits(2)-yLimits(1)], 'EdgeColor', 'black', 'LineWidth', 1.5) 
    legend
    hold off
    
end