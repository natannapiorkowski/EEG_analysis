function recursivelySaveFile(EEG, currResultsPath, saveFolder, filename, varargin)
    % function recursively builds up a path to save files with results of current analysis step
    
    p = inputParser;
    p.addParamValue('FileNameSuffix', {});
    p.parse(varargin{:});

    toSavePath = fullfile(currResultsPath, saveFolder);
    
    % Add suffix to the filename    
    if ~isempty(p.Results.FileNameSuffix)
        if ~isempty(strfind(filename, '.set'))
            filename = strrep(filename, '.set', ['_', p.Results.FileNameSuffix]);
        elseif ~isempty(strfind(filename, '.bdf'))
            filename = strrep(filename, '.bdf', ['_', p.Results.FileNameSuffix]);
        else
            filename = sprintf('%s_%s)', filename, p.Results.FileNameSuffix);
        end
    end

    % saving file
    mkdir(toSavePath)
    pop_saveset( EEG, 'filename',filename,'filepath',toSavePath, 'savemode','twofiles');
    
    
    
end