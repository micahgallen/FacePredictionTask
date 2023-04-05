function [vars] = ELshutdown(vars)

Eyelink('message', 'ENDEXP');

% Stop recording
Eyelink('StopRecording');
Eyelink('CloseFile');

% Transfer data from the host PC and afterwards stop EyeLink

% Insert by Jamie 21/03/2023 
path2SaveEyelink = [vars.OutputFolder filesep 'EyeLinkData' filesep];
if ~isfolder(path2SaveEyelink)
    mkdir(path2SaveEyelink)
end

% Copy EDF file from Host computer to other directory for further analysis.
status = Eyelink('ReceiveFile', vars.eyelinkDataName, path2SaveEyelink, []); % 1);
if (status < -1)
    fprintf('Error transferring EDF file to local directory!');
end
Eyelink('ShutDown');

end