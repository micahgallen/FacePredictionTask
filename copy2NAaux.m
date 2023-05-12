function copy2NAaux(subID, visitID)
% copy behavioural data from 3_VMP_NiiaTasks/data/subID  or 2_VMP_RestingState/data to 1_VMP_aux
%
%  Project Visceral mind project cohrot 1 / study summer 2020
%
% To include at the end of CWTwrapper and runRestingState
%
% Niia Nikolova
% 30 July 2020

subIDstring = sprintf('%04d', subID);
visitIDstring = sprintf('%04d', visitID);
% dataDirectory = fullfile('..', '1_VMP_aux', ['sub_', subIDstring]); % From NiiaTasks

try
    % First try saving to /aux/ drive. If that fails, save locally
    dataDirectory = fullfile('X:', filesep, 'MINDLAB2023_MEG-NA-Prediction', ['sub_', subIDstring], ['visit_', visitIDstring]); % From NiiaTasks
    altDataDirectory = fullfile('..', filesep, '..', ['sub_', subIDstring]);
    if ~exist(dataDirectory, 'dir')
        mkdir(dataDirectory)
    end
    
    targetFolder = dataDirectory;
    files2move = fullfile('.', 'data', ['sub_', subIDstring], ['visit_', visitIDstring]);
    files2movePath = fullfile(files2move, ['*', subIDstring,'*']);
    copyfile(files2movePath, targetFolder)
    
    disp('---- FILES COPIED TO AUX ------')
    
catch
    disp('==========================================================================================');
    disp('WARNING: Could not copy to /aux/. Data are saved locally in /dataBackup/sub_stormDB. Copy data to /aux/ manually.');
    disp('==========================================================================================');

end

end