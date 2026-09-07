clearvars -except; close all; clc
eeglab;
close all

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

%% ===== Select files =====
[EEG_files, location] = uigetfile("*.set", "MultiSelect", "on");

% Force EEG_files to always be a cell array, even if only 1 file is selected
if ischar(EEG_files)
    EEG_files = {EEG_files};
elseif isequal(EEG_files, 0)
    error('No files selected.');
end

csvFile = 'Component_Latencies.csv';
writeHeader = ~isfile(csvFile);

for subjectNo = 1:length(EEG_files)
    fprintf("\nLoading subject %d out of %d\n", subjectNo, length(EEG_files))
    
    % Load EEG data
    EEG = loadEEGfile(location, EEG_files{subjectNo});
    
    if ~isfield(EEG, 'Cumulative_ERP_averaging')
        fprintf('Subject: %s. Missing Cumulative_ERP_averaging', EEG_files{subjectNo})
        continue
    end

    % Extract data from the EEG struct
    subject_name = strrep(EEG.filename, ".set", "");
    channels     = {EEG.chanlocs.labels};
    components   = EEG.Cumulative_ERP_averaging.ComponentNames;
    latencies    = EEG.Cumulative_ERP_averaging.ERP_latencies; 
    % Note: Assumed shape of latencies is [nCh x nComp x nT]
    
    nCh   = numel(channels);
    nComp = numel(components);
    nT    = size(latencies, 3);

    % --- FIXING THE INDEXING LOGIC ---
    % MATLAB's reshape loops through dimensions in order: Dim 1 (Ch), then Dim 2 (Comp), then Dim 3 (Trial).
    % We use ndgrid to perfectly replicate this exact extraction order.
    [ch_grid, comp_grid, t_grid] = ndgrid(1:nCh, 1:nComp, 1:nT);

    % Flatten the grids into columns matching the reshaped data
    channel_col   = channels(ch_grid(:)).';
    component_col = components(comp_grid(:)).';
    N_trials      = t_grid(:);
    
    % Linearize the latency matrix using default column-major order
    latency_col   = latencies(:); 
    
    % Build subject column
    nRows = numel(latency_col);
    subject_col = repmat({subject_name}, nRows, 1);

    % Create the table
    T = table(subject_col, channel_col, component_col, N_trials, latency_col, ...
        'VariableNames', {'subject_id', 'channel', 'component', 'N_trials', 'latency'});

    % Write / Append to CSV
    if writeHeader
        writetable(T, csvFile);
        writeHeader = false;
    else
        writetable(T, csvFile, 'WriteMode', 'Append', 'WriteVariableNames', false);
    end

    % Clear variables to free memory
    clear EEG channels components latencies T channel_col component_col ...
          subject_col ch_grid comp_grid t_grid latency_col N_trials
      
    drawnow; pause(0.01);
end



%% ===== TESTS =====
%% ===== CONFIGURATION =====
M = 1000; % Number of random rows to sample and validate
if ~isfile(csvFile)
    error('The file %s does not exist. Run the preprocessing script first.', csvFile);
end

%% ===== 1) LOAD CSV & SELECT M RANDOM ROWS =====
opts = detectImportOptions(csvFile);
opts.VariableNamingRule = 'preserve'; 
mainTable = readtable(csvFile, opts);

if height(mainTable) < M
    M = height(mainTable);
    warning('M is larger than the table height. Testing all %d rows.', M);
end

% Pick random rows and sort them by subject_id
randIdx = randperm(height(mainTable), M);
testTable = mainTable(randIdx, :);
testTable = sortrows(testTable, 'subject_id');

fprintf('--- Validating %d random rows ---\n', M);

%% ===== RUN VALIDATION =====
% Find unique subjects in our sample so we only load each file once
uniqueSubjects = unique(testTable.subject_id);

totalMatches = 0;
totalMismatches = 0;

for i = 1:numel(uniqueSubjects)
    subName = uniqueSubjects{i};
    subRows = testTable(strcmp(testTable.subject_id, subName), :);
    
    % 2) Load the set file for this subject
    setFileName = [subName, '.set'];
    fprintf('\nLoading source file for validation: %s\n', setFileName);
    
    try
        EEG = pop_loadset('filename', setFileName, 'filepath', location);
    catch ME
        warning('Could not load %s. Skipping these rows. Error: %s', setFileName, ME.message);
        continue;
    end
    
    % 3) Extract ground-truth arrays
    channels   = {EEG.chanlocs.labels};
    components = EEG.Cumulative_ERP_averaging.ComponentNames;
    latencies  = EEG.Cumulative_ERP_averaging.ERP_latencies;
    
    % 4) Compare each sampled row for this subject
    for r = 1:height(subRows)
        csvChan = subRows.channel{r};
        csvComp = subRows.component{r};
        csvTrial = subRows.N_trials(r);
        csvLatency = subRows.latency(r);
        
        % Find corresponding 3D indices in the original EEG matrix
        chIdx = find(strcmp(channels, csvChan));
        compIdx = find(strcmp(components, csvComp));
        
        if isempty(chIdx) || isempty(compIdx)
            fprintf('❌ [FAIL] CSV labels "%s" or "%s" not found in EEG struct.\n', csvChan, csvComp);
            totalMismatches = totalMismatches + 1;
            continue;
        end
        
        % Pull value from the 3D matrix: [Channel, Component, Trial]
        trueLatency = latencies(chIdx, compIdx, csvTrial);
        
        % Check for matches (accounting for floating-point precision and NaN values)
        isMatch = (isnan(csvLatency) && isnan(trueLatency)) || ...
                  (abs(csvLatency - trueLatency) < 1e-5);
        
        if isMatch
            fprintf('   ✓ [MATCH] Ch: %s, Comp: %s, Trial: %d -> CSV: %g == Struct: %g\n', ...
                csvChan, csvComp, csvTrial, csvLatency, trueLatency);
            totalMatches = totalMatches + 1;
        else
            fprintf('   ❌ [MISMATCH] Ch: %s, Comp: %s, Trial: %d -> CSV: %g != Struct: %g\n', ...
                csvChan, csvComp, csvTrial, csvLatency, trueLatency);
            totalMismatches = totalMismatches + 1;
        end
    end
end

%% ===== FINAL REPORT =====
fprintf('\n--- VALIDATION SUMMARY ---\n');
fprintf('Total rows tested: %d\n', M);
fprintf('Matches:           %d\n', totalMatches);
fprintf('Mismatches:        %d\n', totalMismatches);

if totalMismatches == 0 && totalMatches > 0
    fprintf('🎉 Success! The CSV mapping perfectly preserves the 3D matrix structural order.\n');
else
    fprintf('⚠️ Warning: Indexing mismatch detected. Re-check matrix dimension shapes.\n');
end