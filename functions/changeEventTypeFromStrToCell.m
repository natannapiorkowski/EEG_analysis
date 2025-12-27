function EEG = changeEventTypeFromStrToCell(EEG)
    if isfield(EEG.event, 'type')
        events = {EEG.event.type};
        for i =1:length(events)
            if ischar(EEG.event(i).type)
                if ~isequal(EEG.event(i).type, 'boundary')
                    EEG.event(i).type = str2double(EEG.event(i).type);
                end
            end

        end
    end
end