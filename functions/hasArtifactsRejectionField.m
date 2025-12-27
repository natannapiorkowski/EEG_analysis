function [tf, matches] = hasArtifactsRejectionField(EEG)
% hasArtifactsRejectionField Check for field containing "artifactsRejection"
%   [tf, matches] = hasArtifactsRejectionField(EEG)
%
%   Inputs:
%     EEG - struct expected to contain field 'processing_steps'
%
%   Outputs:
%     tf      - true if any field name contains "artifactsRejection" (case-insensitive)
%     matches - cell array of matching field names ({} if none)
%
%   Example:
%     [tf, m] = hasArtifactsRejectionField(EEG);

    % Defaults
    tf = false;
    matches = {};

    if ~isstruct(EEG) || ~isfield(EEG, 'processing_steps')
        return
    end

    ps = EEG.processing_steps;

    % If processing_steps is a struct or struct array: gather field names
    if isstruct(ps)
        % For struct array, combine fieldnames from all elements
        fn = fieldnames(ps);
        % If struct array with different fields, include unique across elements
        if numel(ps) > 1
            allFn = {};
            for k = 1:numel(ps)
                allFn = [allFn; fieldnames(ps(k))]; %#ok<AGROW>
            end
            fn = unique(allFn);
        end
        names = fn;
    elseif iscell(ps)
        % Cell array of strings (names)
        names = ps(:);
    elseif ischar(ps) || isstring(ps)
        % Single string or char vector (possibly newline separated) -> split
        if isstring(ps)
            ps = char(ps);
        end
        % Split on whitespace/commas/semicolons
        names = regexp(ps, '[^\s,;]+', 'match');
    else
        % Unsupported type
        return
    end

    % Ensure names are cellstr
    names = cellfun(@char, names, 'UniformOutput', false);

    % Find matches (case-insensitive substring)
    mask = contains(names, 'artifactsRejection', 'IgnoreCase', true);
    matches = names(mask);
    tf = any(mask);
end
