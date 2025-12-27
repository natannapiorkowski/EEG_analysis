function out = getHistoryEntry(EEG, key, mode, idx)
%GETHISTORYENTRY Retrieve values stored under a key in EEG.history
%   out = getHistoryEntry(EEG, key)           % returns cell array (all entries) or {} if missing
%   out = getHistoryEntry(EEG, key, 'last')  % returns last entry (scalar, not cell) or '' if missing
%   out = getHistoryEntry(EEG, key, 'first') % returns first entry
%   out = getHistoryEntry(EEG, key, 'all')   % same as default, returns cell array
%   out = getHistoryEntry(EEG, key, 'idx', n) % returns nth entry
%
%   key  - char or string
%   mode - 'all' (default), 'last', 'first', 'idx'
%   idx  - numeric index when mode is 'idx'
%
%   Notes:
%   - If the stored field is not a cell, it will be returned wrapped in a cell
%   - Missing keys return {} for 'all' or '' for scalar-return modes

if nargin < 2
    error('Two arguments required: EEG and key.');
end
if nargin < 3 || isempty(mode)
    mode = 'all';
end

% Normalize key -> valid field name
if isstring(key), key = char(key); end
if ~ischar(key)
    error('Key must be char or string.');
end
field = matlab.lang.makeValidName(key);

% Validate history field
if ~isfield(EEG, 'history') || ~isstruct(EEG.history) || ~isfield(EEG.history, field)
    switch lower(mode)
        case 'all'
            out = {};
        otherwise
            out = '';
    end
    return
end

val = EEG.history.(field);

% Ensure cell
if ~iscell(val)
    val = {val};
end

switch lower(mode)
    case 'all'
        out = val;
    case 'last'
        if isempty(val), out = ''; else out = val{end}; end
    case 'first'
        if isempty(val), out = ''; else out = val{1}; end
    case 'idx'
        if nargin < 4 || ~isnumeric(idx) || idx < 1 || idx > numel(val)
            error('For mode ''idx'' provide a valid numeric index within range.');
        end
        out = val{idx};
    otherwise
        error('Unknown mode. Use ''all'',''last'',''first'', or ''idx''.');
end
end
