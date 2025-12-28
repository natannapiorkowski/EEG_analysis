function EEG = loadEEGfile(pathname, filename, ElectrodesLocations_path)
    % import data to eeglab. If data in bdf format import also channels locations
    if contains(filename, '.bdf')
        EEG = pop_biosig(fullfile(pathname,filename));
        if EEG.nbchan > 100
            EEG = pop_chanedit(EEG, 'lookup',fullfile(ElectrodesLocations_path, 'Biosemi128.elp'));
            EEG = addHistory(EEG, 'ElectrodesLocations', fullfile(curr_path, 'ElectrodesLocations', 'Biosemi128.elp'));
        else
            EEG = pop_chanedit(EEG, 'lookup',fullfile(ElectrodesLocations_path', 'Biosemi64.elp'));
            EEG = addHistory(EEG, 'ElectrodesLocations', fullfile(curr_path, 'ElectrodesLocations', 'Biosemi64.elp'));
        end
    else
        EEG = pop_loadset('filename',filename,'filepath', pathname);              
    end

end