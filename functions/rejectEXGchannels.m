function EEG = rejectEXGchannels(EEG)
% Remove EXG channels except EXG1 and EXG2 (case-insensitive)

% Validate chanlocs
if ~isfield(EEG,'chanlocs') || isempty(EEG.chanlocs) || ~isfield(EEG.chanlocs(1),'labels')
    warning('EEG.chanlocs.labels missing — returning EEG unchanged.');
    return
end

labels = {EEG.chanlocs.labels};
% find labels containing 'EXG' (case-insensitive)
isEXG = contains(labels,'EXG','IgnoreCase',true);
toRemove = find(isEXG);

if isempty(toRemove)
    % nothing to remove
    return
end

% remove channels via pop_select
EEG = pop_select(EEG, 'nochannel', toRemove);

EEG = addHistory(EEG, "rejectEXGchannels", strjoin(labels(toRemove), ", "));

end
