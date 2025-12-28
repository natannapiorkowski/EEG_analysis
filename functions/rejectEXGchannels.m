function EEG = rejectEXGchannels(EEG, channels_to_keep)
    % Remove EXG channels except those specified in channels_to_keep (case-insensitive)
    
    % Validate chanlocs
    if ~isfield(EEG,'chanlocs') || isempty(EEG.chanlocs) || ~isfield(EEG.chanlocs(1),'labels')
        warning('EEG.chanlocs.labels missing — returning EEG unchanged.');
        return
    end
    
    labels = {EEG.chanlocs.labels};
    % find labels containing 'EXG' (case-insensitive)
    isEXG = contains(labels,'EXG','IgnoreCase',true);
    toRemove = find(isEXG);
    
    % Identify channels to keep
    channels_to_keep = lower(channels_to_keep); % Convert to lower case for case-insensitive comparison
    keepIndices = find(ismember(lower(labels), channels_to_keep));
    
    % Remove EXG channels that are not in channels_to_keep
    toRemove = setdiff(toRemove, keepIndices);
    
    if isempty(toRemove)
        % nothing to remove
        return
    end
    
    % remove channels via pop_select
    EEG = pop_select(EEG, 'nochannel', toRemove);
    
    EEG = addHistory(EEG, "rejectEXGchannels", strjoin(labels(toRemove), ", "));

end
