function EEG = changeEventTypeFromStrToCell(EEG)
    % if isfield(EEG.event, 'type')
    %     events = {EEG.event.type};
    %     for i = 1:length(events)
    %         if ischar(EEG.event(i).type)
    %             if ~isequal(EEG.event(i).type, 'boundary')
    %                 EEG.event(i).type = str2double(EEG.event(i).type);
    %             end
    %         end
    % 
    %     end
    % end
    if isfield(EEG.event, 'type')
        % 1. Extract all types into a cell array
        allTypes = {EEG.event.type};
        
        % 2. Identify indices that are strings and NOT 'boundary'
        % We use cellfun for a quick logical mask
        isString = cellfun(@ischar, allTypes);
        isNotBoundary = ~strcmp(allTypes, 'boundary');
        targetIdx = isString & isNotBoundary;
        
        if any(targetIdx)
            % 3. Extract target strings
            stringsToConvert = allTypes(targetIdx);
            
            % 4. Remove underscores (e.g., '255_1' -> '2551')
            stringsToConvert = strrep(stringsToConvert, '_', '');
            
            % 5. Convert to doubles and place back into a cell array
            convertedValues = num2cell(str2double(stringsToConvert));
            
            % 6. Assign back to the structure in one bulk operation
            [EEG.event(targetIdx).type] = convertedValues{:};
        end
    end
end