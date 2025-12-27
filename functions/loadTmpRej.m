function tmprej = loadTmpRej(subjectID, pathname)
% loadTmpRej Load rejection vector for subjectID from filename (.mat)
%   v = loadTmpRej('subj01')
    filename = fullfile(pathname, 'tmprej_store.mat');

    validateattributes(subjectID, {'char','string'}, {'scalartext'}, mfilename, 'subjectID', 1);
    if ~exist(filename,'file')
        error('File "%s" does not exist.', filename);
    end

    fld = matlab.lang.makeValidName(char(subjectID));
    S = load(filename, fld);        % load only that field (if present)

    if ~isfield(S, fld)
        error('Subject "%s" not found in file "%s".', subjectID, filename);
    end
    tmprej = S.(fld);
end
