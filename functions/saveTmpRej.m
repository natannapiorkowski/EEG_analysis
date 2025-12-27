function saveTmpRej(subjectID, tmprej, pathname)
% saveTmpRej Save rejection vector tmprej for subjectID into filename (.mat)
%   saveTmpRej('subj01', tmprej)              % saves to 'tmprej_store.mat'
%   saveTmpRej('subj01', tmprej, 'file.mat') % custom filename
    mkdir(pathname)
    filename = fullfile(pathname, 'tmprej_store.mat');
    
    validateattributes(tmprej, {'numeric','logical'}, {'vector'}, mfilename, 'tmprej', 2);
    validateattributes(subjectID, {'char','string'}, {'scalartext'}, mfilename, 'subjectID', 1);

    fld = matlab.lang.makeValidName(char(subjectID));

    S = struct();
    S.(fld) = tmprej;               % create structure with field = subject id
    disp(filename)
    if exist(filename,'file')
        save(filename, '-struct', 'S', '-append');
    else
        save(filename, '-struct', 'S');
    end
end