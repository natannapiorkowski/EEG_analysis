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


eeglab('nogui');
close all

%% SETTINGS
global SETTINGS;
SETTINGS = GUI_preprocessing();



%% SETTINGS
%global SETTINGS;
%SETTINGS = preprocessing_main_gui().getOutput();


%% Run analysis
for subjectNo = 1:length(SETTINGS.filenames)
    % import data to eeglab. If data in bdf format import also channels locations
    if ~isempty(strfind(SETTINGS.filenames{subjectNo}, '.bdf'))
        EEG = pop_biosig(fullfile(SETTINGS.pathname,SETTINGS.filenames{subjectNo}));
        if EEG.nbchan > 100
            EEG = pop_chanedit(EEG, 'lookup',fullfile(curr_path, 'ElectrodesLocations', 'Biosemi128.elp'));
            EEG = addHistory(EEG, 'ElectrodesLocations', fullfile(curr_path, 'ElectrodesLocations', 'Biosemi128.elp'));
        else
            EEG = pop_chanedit(EEG, 'lookup',fullfile(curr_path, 'ElectrodesLocations', 'Biosemi64.elp'));
            EEG = addHistory(EEG, 'ElectrodesLocations', fullfile(curr_path, 'ElectrodesLocations', 'Biosemi64.elp'));
        end
    else
        EEG = pop_loadset('filename',SETTINGS.filenames{subjectNo},'filepath',SETTINGS.pathname);              
    end
    %%
    switch SETTINGS.analysisStep        
        
        case 'rereference'
            EEG = pop_reref( EEG, find(ismember({EEG.chanlocs.labels}, SETTINGS.newReference)), 'keepref', 'on');
            EEG = addHistory(EEG, "rereference", SETTINGS.newReference);
            EEG = rejectEXGchannels(EEG, SETTINGS.newReference);       
            recursivelySaveFile(EEG, SETTINGS.pathname, 'ReReferenced', SETTINGS.filenames{subjectNo});
            
        case 'resample'
            original_fs = EEG.srate;
            EEG = pop_resample(EEG, SETTINGS.newFS);
            EEG = addHistory(EEG, "resample", [original_fs, SETTINGS.newFS]);
            recursivelySaveFile(EEG, SETTINGS.pathname, 'Resampled', SETTINGS.filenames{subjectNo});
            
        case 'lowPassFilter'
            EEG  = pop_basicfilter(EEG, ...
                                   [1:size(EEG.data,1)], ...
                                   'Cutoff', SETTINGS.lowPassFreq, ...
                                   'Design','butter', ...
                                   'Filter','lowpass', ...
                                   'Order',6); 
            EEG = addHistory(EEG, "lowPassFilter", sprintf("Cutoff: %g ,Design: %s, filter_type: %s, order: %g", SETTINGS.lowPassFreq, "butter", "lowpass", 6));
            recursivelySaveFile(EEG, SETTINGS.pathname, 'LowPassFilter', SETTINGS.filenames{subjectNo});

        case 'highPassFilter'
            EEG  = pop_basicfilter(EEG, ...
                                   [1:size(EEG.data,1)], ...
                                   'Cutoff', SETTINGS.highPassFreq, ...
                                   'Design','butter', ...
                                   'Filter','highpass', ...
                                   'Order',6); 
            EEG = addHistory(EEG, "highPassFilter", sprintf("Cutoff: %g ,Design: %s, filter_type: %s, order: %g", SETTINGS.highPassFreq, "butter", "highpass", 6));
            recursivelySaveFile(EEG, SETTINGS.pathname, 'HighPassFilter', SETTINGS.filenames{subjectNo});
            
        case 'dataInspection'
            EEG = rejectEXGchannels(EEG);
            cmd = ['[tmprej] = eegplot2event(TMPREJ); [EEG LASTCOM] = eeg_eegrej(EEG, tmprej);'];
%             cmd = ['[tmprej] = eegplot2event(TMPREJ); [EEG.data EEG.xmax tmpalllatencies boundevents] = eegrej(EEG.data, tmprej(:, 3:4),EEG.xmax-EEG.xmin, [EEG.event.latency]); EEG.pnts =size(EEG.data,2); EEG.xmax = EEG.xmax+EEG.xmin; EEG.times = linspace(EEG.xmin, EEG.xmax, size(EEG.data, 2));'];
            
            eegplot(EEG.data,  'eloc_file',EEG.chanlocs,...
                               'butlabel','Reject', ...
                               'command', cmd,...
                               'wincolor', [1, 0.7, 0.7],...
                               'spacing',   SETTINGS.amplitudeToDisplay, ...
                               'winlength', SETTINGS.timeRangeToDisplay,...
                               'events', EEG.event, ...
                               'srate', EEG.srate);
           input(sprintf('\n =============== \n Visual inspection done? Press ENTER \n ===============  \n')) 
           
           if SETTINGS.removeChannels
                RMchan = removeChannels_gui(EEG);
                channelsToRemove = RMchan.channelsToRemove;
                EEG.data(channelsToRemove, :) = NaN;
           end
           EEG = addHistory(EEG, "dataInspection", TMPREJ);
           recursivelySaveFile(EEG, SETTINGS.pathname, 'VisualInspection', SETTINGS.filenames{subjectNo});
                
        case 'runICA'
            %includedChannelsForICA = channels_selection_gui(EEG, "Select channels to perform ICA");
            EEG = performICA(EEG);
            EEG = addHistory(EEG, "ICA_calculation_channels", includedChannelsForICA);
            recursivelySaveFile(EEG, SETTINGS.pathname, 'CalculatedICA', SETTINGS.filenames{subjectNo});

        case 'removeICA'
            pop_topoplot(EEG,0, [1:size(EEG.icaweights, 1)] ,'ICA COMPONENTS' ,0,'electrodes','on');
            EEG = ICA_GUI(EEG, 'channelsOfInterest', SETTINGS.ICAchans);
            close(gcf)
            EEG = addHistory(EEG, "ICA_components_removed", "");
            recursivelySaveFile(EEG, SETTINGS.pathname, 'ICAcomponentsRemoved', SETTINGS.filenames{subjectNo});
        
        case 'notch'
            EEG = pop_basicfilter(EEG,  [1:size(EEG.data, 1)] , ...
                                 'Cutoff',  SETTINGS.notchFreq, ...
                                 'Design', 'notch', ...
                                 'Filter', 'PMnotch', ...
                                 'Order',  180, ...
                                 'RemoveDC', 'on' ); 
            EEG = addHistory(EEG, "notchFilter", sprintf("Cutoff: %g , Design: notch, filter_type: PMnotch, order: %g", SETTINGS.notchFreq, 180));
            recursivelySaveFile(EEG, SETTINGS.pathname, 'NotchFilter', SETTINGS.filenames{subjectNo});
        
        
        case 'removeSpikes'
            [EEGspikesRemoved, isOK] = removeSpikes( ...
                                    EEG, ...
                                    'lookForSpikeRange', SETTINGS.spikeRange, ...
                                    'lookForSpikeRange_shift', SETTINGS.rangeShift, ...
                                    'spikeWidth', SETTINGS.spikeLen, ...
                                    'interpolationTimeRage', SETTINGS.interpolationTimeRange, ...
                                    'SD_crit', 1, ...
                                    'showResults', SETTINGS.plotSpikeRemovalResults);
            lookForSpikeRange = SETTINGS.spikeRange;
            lookForSpikeRange_shift = SETTINGS.rangeShift;
            spikeWidth = SETTINGS.spikeLen;
            interpolationTimeRage = SETTINGS.interpolationTimeRange;
            while ~isOK
                close all
                lookForSpikeRange = input(sprintf('What should be time range for potential spike? Currently %g ms \n', lookForSpikeRange));
                lookForSpikeRange_shift =  input(sprintf('What should be time range shift? Currently %g ms \n', lookForSpikeRange_shift));
                spikeWidth = input(sprintf('What should be the spike width? Currently %g ms \n', spikeWidth));
                interpolationTimeRage = input(sprintf('What should be the time range used for signal interpolation? Currently %g ms \n', interpolationTimeRage));                
                plotSpikeRemovalResults = input(sprintf('Plot ERPs? Yes[1] No[0] \n'));
                [EEGspikesRemoved, isOK] = removeSpikes(EEG, 'lookForSpikeRange', lookForSpikeRange, ...
                                        'lookForSpikeRange_shift', lookForSpikeRange_shift, ...
                                        'spikeWidth', spikeWidth, ...
                                        'interpolationTimeRage', interpolationTimeRage, ...
                                        'SD_crit', 1, ...
                                        'showResults', SETTINGS.plotSpikeRemovalResults);          
            end
            
            EEG = EEGspikesRemoved;
            clear EEGspikesRemoved; close all
            EEG = addHistory(EEG, "Removed stimulation spikes", "");
            recursivelySaveFile(EEG, SETTINGS.pathname, 'Spikes Removed', SETTINGS.filenames{subjectNo},'information','Stimulation spikes removed');
                    
        case 'epoch'
            % read correct eventlist files for given conditions
            EEG = changeEventTypeFromStrToCell(EEG);
            conditions = unique(cell2mat({EEG.event.type}));
            if ismember(2, conditions) 
                eventlistFile = fullfile(curr_path,'Eventlists/eventlist_Stim2.txt');
                toSaveFolder = 'Epoched_Stim2';
                filenameSuffix = 'Stim2';            
            end
            
            if ismember(3, conditions)
                eventlistFile = fullfile(curr_path,'Eventlists/eventlist_Stim3.txt');
                toSaveFolder = 'Epoched_Stim3';
                filenameSuffix = 'Stim3';
            end
            
            if ismember(41, conditions)
                eventlistFile = fullfile(curr_path,'Eventlists/eventlist_Stim41.txt');
                toSaveFolder = 'Epoched_1Hz';
                filenameSuffix = '1HzStim';  
            end
            
            if ismember(42, conditions)      
                eventlistFile = fullfile(curr_path,'Eventlists/eventlist_Stim42.txt');
                toSaveFolder = 'Epoched_9Hz';
                filenameSuffix = '9HzStim';                 
            end    
            
            if ismember(255, conditions)      
                eventlistFile = fullfile(curr_path,'Eventlists/eventlist_Tactile.txt');
                toSaveFolder = 'Epoched_PES';
                filenameSuffix = '0,5Hz';
            end

            EEG_Stim1 = pop_editeventlist(EEG, ...
                    'AlphanumericCleaning', 'on', ...
                    'BoundaryNumeric', { -99}, ...
                    'BoundaryString', { 'boundary' }, ...
                    'List',eventlistFile, ...
                    'SendEL2', 'EEG', ...
                    'UpdateEEG', 'binlabel', ...
                    'Warning', 'off'); 

            EEG_Stim1 = pop_epochbin(EEG_Stim1 , ...
                    [-abs(SETTINGS.prestimDur) SETTINGS.poststimDur],'pre', ...
                    'warning', 'off');    
            EEG_Stim1 = addHistory(EEG_Stim1, "epoch", sprintf("tmin: %g , tmax: %g, eventlistFile: %s", -abs(SETTINGS.prestimDur), SETTINGS.poststimDur, eventlistFile));
            recursivelySaveFile(EEG_Stim1, SETTINGS.pathname, toSaveFolder, SETTINGS.filenames{subjectNo}, 'FileNameSuffix',filenameSuffix);
            clear EEG_Stim1    

        case 'epochSelectively'
            EEG = selectiveEpoching(EEG);
            EEG_STD_PRE  = pop_editeventlist( EEG , 'AlphanumericCleaning', 'on','BoundaryNumeric', { -99},'BoundaryString', { 'boundary' },'List',fullfile(curr_path,'Eventlists/eventlist_STD_PRE.txt'),'SendEL2', 'EEG','UpdateEEG', 'on','Warning', 'off' ); 
                EEG_STD_PRE = pop_epochbin(EEG_STD_PRE , [-abs(SETTINGS.prestimDur) SETTINGS.poststimDur],'pre','warning', 'off');    
                recursivelySaveFile(EEG_STD_PRE, SETTINGS.pathname, 'Standard_PRE_Epoched', SETTINGS.filenames{subjectNo}, 'FileNameSuffix', 'STD_PRE');
                clear EEG_STD_PRE
                                        
            EEG_DEVIANT  = pop_editeventlist( EEG , 'AlphanumericCleaning', 'on','BoundaryNumeric', { -99},'BoundaryString', { 'boundary' }, 'List',fullfile(curr_path,'Eventlists/eventlist_DEVIANT.txt'),'SendEL2', 'EEG','UpdateEEG', 'on','Warning', 'off' ); 
                EEG_DEVIANT = pop_epochbin(EEG_DEVIANT , [-abs(SETTINGS.prestimDur) SETTINGS.poststimDur],'pre','warning', 'off');    
                recursivelySaveFile(EEG_DEVIANT, SETTINGS.pathname, 'DEVIANT_Epoched', SETTINGS.filenames{subjectNo}, 'FileNameSuffix', 'DEVIANT');
                clear EEG_DEVIANT
            
            EEG_STD_POST  = pop_editeventlist( EEG , 'AlphanumericCleaning', 'on','BoundaryNumeric', { -99},'BoundaryString', { 'boundary' },'List',fullfile(curr_path,'Eventlists/eventlist_STD_POST.txt'),'SendEL2', 'EEG','UpdateEEG', 'on','Warning', 'off' ); 
                EEG_STD_POST = pop_epochbin(EEG_STD_POST , [-abs(SETTINGS.prestimDur) SETTINGS.poststimDur],'pre','warning', 'off');    
                recursivelySaveFile(EEG_STD_POST, SETTINGS.pathname,'Standard_POST_Epoched', SETTINGS.filenames{subjectNo}, 'FileNameSuffix', 'STD_POST');
                clear EEG_STD_POST
                                  
        case 'artifactsRejection'
           rejepochcol =  [.95, .75, .7];
           if SETTINGS.usePrevRejEpochs
               [tmprej_file, tmprej_path] = uigetfile(curr_path);               
               tmprej = loadTmpRej(SETTINGS.filenames{subjectNo}, tmprej_path);
               EEG.reject.tmprej = tmprej;
               winrej = trial2eegplot( ...
                   tmprej, ...
                   repmat(tmprej, EEG.nbchan),... %electrode rejection array (size nb_elec x trials)
                   EEG.pnts, ...
                   rejepochcol);
           else
               %exclude trials with too large amplitude
               EEG  = pop_artextval(EEG, ...
                   'Channel',1:EEG.nbchan, ...
                   'Flag',1, ...
                   'Threshold',[SETTINGS.lowAmplitudeThreshold SETTINGS.highAmplitudeThreshold], ...
                   'Twindow', [SETTINGS.minTimeWindowArtifacts SETTINGS.maxTimeWindowArtifacts] );
               %exclude trial with too large sample-to sample amplitude
               EEG  = pop_artdiff(EEG,'Channel',1:EEG.nbchan,'Flag',1,'Threshold',SETTINGS.sampleToSample,'Twindow', [SETTINGS.minTimeWindowArtifacts SETTINGS.maxTimeWindowArtifacts] ); 
               %exclude trials with too low amplitude )flat electrodes)
               EEG  = pop_artflatline(EEG,'Channel', 1:EEG.nbchan, 'Duration',  SETTINGS.noActivityDuration, 'Flag',  1, 'Threshold', [-1*SETTINGS.noActivity SETTINGS.noActivity], 'Twindow', [SETTINGS.minTimeWindowArtifacts SETTINGS.maxTimeWindowArtifacts] ); 
     
               EEG = eeg_rejsuperpose( EEG, 1, 1, 1, 1, 1, 1, 1, 1);
               winrej=trial2eegplot(EEG.reject.rejmanual, EEG.reject.rejmanualE, EEG.pnts,rejepochcol);

               %EEG = eeg_rejsuperpose( EEG, 1, 1, 1, 1, 1, 1, 1, 1);
               %EEG.reject.tmprej = EEG.reject.rejglobal;
               %winrej=trial2eegplot(EEG.reject.rejmanual, EEG.reject.rejmanualE, EEG.pnts, rejepochcol);
           end
            
           % Create a lightweight 'display' version of the EEG (e.g., decimated to ~128Hz)
           % This speeds up rendering significantly without affecting the actual data quality.
           disp_srate = 32; % Hz - sufficient for visual inspection
           EEG_disp = pop_resample(EEG, disp_srate); 
           current_rej = EEG.reject.rejmanual;
           current_rejE = repmat(current_rej, EEG.nbchan, 1)*0;
           winrej_disp = trial2eegplot(current_rej, current_rejE, EEG_disp.pnts, rejepochcol);
           cmd = ['[tmprej, ~] = eegplot2trial(TMPREJ, ' num2str(EEG_disp.pnts) ', ' num2str(EEG_disp.trials) '); [EEG, LASTCOM] = pop_rejepoch(EEG, tmprej, 0);'];
           
           %cmd = ['[tmprej tmprejE] = eegplot2trial( TMPREJ, EEG.pnts, EEG.trials); [EEG LASTCOM] = pop_rejepoch(EEG, tmprej, 0);'];
            
           eegplot(EEG_disp.data, ...
                   'eloc_file',EEG_disp.chanlocs,...
                   'butlabel','Reject', ...
                   'command', cmd,...
                   'wincolor', [1, 0.7, 0.7],...
                   'winrej',winrej_disp, ...
                   'spacing', 100, ...
                   'winlength', 10, ...
                   'events', EEG_disp.event, ...
                   'srate',  EEG_disp.srate ...
                   );
           uiwait(gcf)
       
           saveTmpRej(SETTINGS.filenames{subjectNo}, tmprej, fullfile(SETTINGS.pathname, 'ArtifactsRejected'))
           EEG = addHistory(EEG, "artifactsRejection", tmprej);
           recursivelySaveFile(EEG, SETTINGS.pathname, 'ArtifactsRejected', SETTINGS.filenames{subjectNo});

        case 'importChansLocs'  
            % Import channels locations for 64 or 128 electrodes
            if EEG.nbchan > 100
                cprintf([1 0 0], '\n\n\n\n ! ACHTUNG ! \n128 electrodes found! \nApplying magic and converting to 64 electrodes...  \n\n\n\n')
                EEG = change128To64Electrodes(EEG, curr_path, SETTINGS.interpolationMethod);                
            else
                EEG = pop_chanedit(EEG, 'lookup',fullfile(curr_path, 'ElectrodesLocations', 'Biosemi64.elp'));
                EEG = changeBIOSEMIlabels(EEG);
            end
            recursivelySaveFile(EEG, SETTINGS.pathname, 'ChannelsLocationsChanged', SETTINGS.filenames{subjectNo})

        case 'average'
           fName = strrep(SETTINGS.filenames{subjectNo}, '.set','');
           mkdir(fullfile(SETTINGS.pathname, 'Averaged_ERP'))
           ERP = pop_averager( EEG , 'Criterion', 'good', 'ExcludeBoundary', 'on', 'SEM', 'on' );
           ERP = pop_savemyerp(ERP, 'erpname', 'ERP', 'filename', sprintf('%s_ERP.erp', fName), 'filepath', fullfile(SETTINGS.pathname, 'Averaged_ERP'));
            
    end
    
    



end
%% TODO:
% - wczytywanie usunietych epok z poprzednio zrobionego artifact rejection
% - scalic sygnal z jednego dziecka dla roznych stymulacji przed ICA
