function [noThreshFlag, thresh, PMFstims] = getParticipantThreshold(vars)
%function [noThreshFlag, thresh, PMFstims] = getParticipantThreshold(vars)
%
% Project: CWT task, for fMRI
%
% For a given subject ID, goes into FAD_PsiAdaptive data folder and gets
% the participants threshold estimate
%
%
% Niia Nikolova
% Last edit: 16/07/2020         Changed to return PMFstims, stim levels at [.3 .5 .7] correct

NJitterLevels = 4;          % Number of jitter for H and A together, so number of jitter levels for each stim  = NJitterLevels/2

% subIDstring = '005';
noThreshFlag = 0;
dataFolder = vars.OutputFolder;
% dataFolder = ['..', filesep, 'FADtask_2_Psi_MR', filesep, 'data', filesep];       % ####on aux: FADtask_2_Psi_MR

if strcmp(vars.subIDstring, '9999')   % if we're testing, set a default thresh
    thresh = 100;
    PMFstims = [1 70 130 199];
else

    % Find files in folder
    searchString = ['Threshold_',vars.subIDstring, '*'];
    dataSpec = [dataFolder, searchString];
    files = dir(dataSpec);
    
    if length(files) > 1        % if there are more than one files, ask experimenter to pick which one
        disp('More than one file found for this participant. Using the most recent threshold file... ');
        thisFilePath = [dataFolder, files(end).name];
    elseif length(files) == 1
        thisFilePath = [dataFolder, files(end).name];
    else                        % if there are no data files for this participant, set default threhsold
        ListenChar(0);          % turn on keyboard
        useDefaultThresh = input('No threshold file found! Use default threshold of 50%? (Enter 1 for YES or 0 for NO ) ');
        
        if useDefaultThresh     % set default
            thresh = 100;
            PMFstims = [1 70 130 199];
            return
        else
            disp('You chose not to use a default threshold value. Get the participant to do the FAD thresholding task!!!');
            thresh = 0;
            noThreshFlag = 1;
            ShowCursor;
            return;
        end
    end
    
    new_line;
    disp('Calculating participant threhshold...'); new_line;
    
    thisFileResults = load(thisFilePath, 'stair');        % load struct
    stair = thisFileResults.stair;
    
    %% Find the threshold and other stim levels
    % Get the stim levels at which participant performane is .3 .5 and .7
    thresholdLevel = 0.5;
    pptPMFvals = [stair.PM.threshold(length(stair.PM.threshold)) 10.^stair.PM.slope(length(stair.PM.threshold)) 0 stair.PM.lapse(length(stair.PM.threshold))];
    stimMidPtA = thresholdLevel - vars.PMFptsForStimuli;
    stimMidPtH = thresholdLevel + vars.PMFptsForStimuli;
    inversePMFvals = [stimMidPtA, thresholdLevel, stimMidPtH];               % Performance level (i.e. p(response "Happy"))
    jitterStimsBy = vars.jitterStimsBy;
    
    if NJitterLevels == 8
        % A. 4 jitter levels around A & 4 jitters around H
        stimJitter(1) = inversePMFvals(1)-(2*jitterStimsBy);
        stimJitter(2) = inversePMFvals(1)-(jitterStimsBy);
        stimJitter(3) = inversePMFvals(1)+(jitterStimsBy);
        stimJitter(4) = inversePMFvals(1)+(2*jitterStimsBy);
        stimJitter(5) = inversePMFvals(3)-(2*jitterStimsBy);
        stimJitter(6) = inversePMFvals(3)-(jitterStimsBy);
        stimJitter(7) = inversePMFvals(3)+(jitterStimsBy);
        stimJitter(8) = inversePMFvals(3)+(2*jitterStimsBy);
        
    elseif NJitterLevels == 4
        % B. 2 jitter levels around A & 2 jitters around H
        stimJitter(1) = inversePMFvals(1)-(jitterStimsBy);
        stimJitter(2) = inversePMFvals(1);%+(jitterStimsBy);
        stimJitter(3) = inversePMFvals(3);%-(jitterStimsBy);
        stimJitter(4) = inversePMFvals(3)+(jitterStimsBy);
        
    end
    
    % find threshold
    thresh = stair.PF(pptPMFvals, thresholdLevel, 'inverse');
    thresh = round(thresh);
    
    % find jittered face stimuli
    inversePMFstims = stair.PF(pptPMFvals, stimJitter, 'inverse');
    inversePMFstims = round(inversePMFstims);
    
    %% Make sure that the jitter levels dont result in identical stimuli & dont overlap with threshold
    % Divide into morph levels to use for the happy and angry stimuli,
    % adding thresh so that we make sure that the stimuli cannot overlap
    % with the threshold
    stimJitterA = fliplr([inversePMFstims(1:(NJitterLevels/2)), thresh]);            % flip to that sequential stimuli are 'moving out' from the threshold
    stimJitterH = [thresh, inversePMFstims((NJitterLevels/2)+1:NJitterLevels)];
    
    % Check is PMFstims are adjacent & spread them out by 1 stim if
    % necessary
    for repeat = 1: length(inversePMFstims)/2
        toMove = (diff([0 stimJitterA])==0);
        stimJitterA(toMove) = stimJitterA(toMove)-1;
        toMove = (diff([0 stimJitterH])==0);
        stimJitterH(toMove) = stimJitterH(toMove)+1;
    end
    
    PMFstims = [fliplr(stimJitterA(2:(NJitterLevels/2)+1)),stimJitterH(2:(NJitterLevels/2)+1)];     % remove the threshold value again
    PMFstims(1, [1 4]) = [0 200];
    
end

disp(['Using threshold of: ', num2str(thresh)]);
disp(['Angry morphs: ', num2str(PMFstims(1:NJitterLevels/2))]);
disp(['Happy morphs: ', num2str(PMFstims((NJitterLevels/2)+1:end))]);
ListenChar(0);                      % turn on keyboard

end