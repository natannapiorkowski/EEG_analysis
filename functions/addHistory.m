function EEG = addHistoryEntry(EEG, key, val)
%ADDHISTORYENTRY Add a key-value entry to EEG.history with processing step prefix
%   EEG = addHistoryEntry(EEG, key, val)
%   The effective stored field name becomes: 'mi XX_key' where XX is EEG.processing_steps_n formatted '%02d'.
%   Example: key='filtering', EEG.processing_steps_n=1 -> stored under field 'mi_01_filtering' (valid MATLAB name).

% Basic input checks
if ~isstruct(EEG)
    error('First argument must be the EEG struct.');
end
if ~(ischar(key) || isstring(key))
    error('Key must be a char vector or string scalar.');
end

% Normalize key to char
key = char(key);

% Get processing step number (default 0)
if ~isfield(EEG, 'processing_steps_n')
    EEG.processing_steps_n = 1; % Initialize processing step number if not present
end
n = round(EEG.processing_steps_n);

% Build prefixed key: "XX_key"
prefixedKey = sprintf('%02d_%s', n, key);

% Convert to a valid field name (removes/changes illegal chars, spaces -> _)
field = matlab.lang.makeValidName(prefixedKey);

% Ensure history exists and is a struct
if ~isfield(EEG, 'processing_steps') || isempty(EEG.processing_steps)
    EEG.processing_steps = struct();
elseif ~isstruct(EEG.processing_steps)
    prev = EEG.processing_steps;
    EEG.processing_steps = struct();
    EEG.processing_steps.legacy = {prev};
end

% Prepare value to append
toAppend = {val};

% Append or create field
if isfield(EEG.processing_steps, field)
    cur = EEG.processing_steps.(field);
    if iscell(cur)
        EEG.processing_steps.(field) = [cur, toAppend];
    else
        EEG.processing_steps.(field) = [{cur}, toAppend];
    end
else
    EEG.processing_steps.(field) = toAppend;
    EEG.processing_steps_n = EEG.processing_steps_n + 1;
end
end
