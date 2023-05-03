function localizer_Launcher(scr, subNo, visitNo)
% function localizer_Launcher(scr, subNo)
%
% Localizer for cues and face stimuli in fMRI
%
% Project: CWT task, for fMRI. Part of Visceral Mind Project, summer 2020
% cohort
%
% Input: subNo      4-digit subject ID number
%
% Rapidly presents a few different types of cue image as well as happy and
% angry face stimuli to be used in the confidence weighing task.
%
% Attentional task: fixation cross changes color for 200ms, press LEFT button quickly to respond
% to when change is detected
%
%
% ### Use subID 9999 for testing ###
%
% Niia Nikolova
% Last edit: 21/07/2020     Enabled KbQueue checking for mouse responses

% Close existing workspace
% close all; clc;

%% Key flags
vars.emulate     = 0;                % 0 scanning, 1 testing (stims only presented for .5s)
vars.useEyeLink  = 0;                % 0 no, 1 yes
vars.pptrigger   = 0;                % 0 no, 1 yes



%% Setup
if nargin == 1
    vars.subNo = input('What is the subject number (e.g. 0001)?   ');
    vars.visitNo = input('What is the visit number (e.g. 0001)?   ');
    %     vars.subAge = input('What is your age (# in years, e.g. 35)?   ');
    %     vars.subGen = input('What is your gender (f or m)?   ', 's');
    
elseif nargin < 1
    addpath(genpath('helpers'));
    vars.subNo = input('What is the subject number (e.g. 0001)?   ');
    vars.visitNo = input('What is the visit number (e.g. 0001)?   ');
    %     vars.subAge = input('What is your age (# in years, e.g. 35)?   ');
    %     vars.subGen = input('What is your gender (f or m)?   ', 's');
    
    %% Set screen parameters and open a window
    scr.ViewDist = 56;
    [scr] = displayConfig(scr);
    AssertOpenGL;
    [scr.win, scr.winRect] = PsychImaging('OpenWindow', scr.screenID, scr.BackgroundGray); %,[0 0 1920 1080] mr screen dim
    PsychColorCorrection('SetEncodingGamma', scr.win, 1/scr.GammaGuess);
    
    % Set text size, dependent on screen resolution
    if any(logical(scr.winRect(:)>3000))       % 4K resolution
        scr.TextSize = 65;
    else
        scr.TextSize = 35;
    end
    Screen('TextSize', scr.win, scr.TextSize);
    
    % Set priority for script execution to realtime priority:
    scr.priorityLevel = MaxPriority(scr.win);
    Priority(scr.priorityLevel);
    
    % Determine stim size in pixels
    scr.dist = scr.ViewDist;
    scr.width  = scr.MonitorWidth;
    scr.resolution = scr.winRect(3:4);                    % number of pixels of display in horizontal direction
else
    vars.subNo = subNo;
    vars.visitNo = visitNo;
end
vars.subIDstring = sprintf('%04d', vars.subNo);
vars.visitNostr  = sprintf('%04d', vars.visitNo);

% % check for data dir
% if ~exist('data', 'dir')
%     mkdir('data')
% end
% setup path
addpath(genpath('helpers'));
% addpath(genpath('data'));
vars.exptName = 'LocalizerCWT';
% vars.DataFileName = [vars.exptName, vars.subIDstring];
vars.CBFolder = fullfile('..', '..', 'data', ['sub_',vars.subIDstring], filesep);
% addpath('C:\Users\stimuser.stimpc-08\Desktop\Ashley\CWT_behavioural');
% cbal = Counterbalance_img(vars.CBFolder);
cbal = Counterbalance_latinsq(vars.subIDstring, vars.visitNostr); %, vars.CBFolder);
cbal_str = num2str(cbal);
vars.DataFileName = strcat(vars.exptName, '_',vars.subIDstring, '_visit', vars.visitNostr, '_cbal', cbal_str);    % name of data file to write to
vars.OutputFolder = fullfile('..', '..', 'data', ['sub_',vars.subIDstring], ['visit_', vars.visitNostr], filesep);

% Check if folder already exists in data dir
if ~exist(vars.OutputFolder, 'dir')
    mkdir(vars.OutputFolder)
else
    %     disp('A folder already exists for this subject ID. Please enter a different ID.')
    %     return
end


% if isfile(strcat(vars.OutputFolder, vars.DataFileName, '.mat')) && (vars.subNo ~= 999)
%     disp('A datafile already exists for this subject ID. Please enter a different ID.')
%     return
% end

%% Stimuli
vars.TaskPath = fullfile('.');                  % from main task folder (ie. 'Pilot_2_PsiAdaptive')
vars.StimFolder = fullfile('..', '..', 'stimuli', filesep);   %fullfile('.', 'stimuli', filesep);
vars.StimSize = 9;                              % DVA

vars.CuesInDir = length(dir([vars.StimFolder, 'cue*']));
vars.NStims = vars.CuesInDir+2;                % number of cues + happy + angry 
vars.CuesInDir = length(dir([vars.StimFolder, 'cue*']));

% Face - find relative to ppt threshold
% Calculate morphs to use
% vars.PMFptsForStimuli = .05;
vars.PMFptsForStimuli           = .3;               % Percent below and above FAD threshold to use as Happy and Angry stimulus mid-points
vars.jitterStimsBy              = 0.02;             % Amount of jitter around A & H stims
% Percent below and above FAD threshold to use as Happy and Angry stimuli
% morphValsJump = 200 * vars.PMFptsForStimuli;
[noThreshFlag, thresh, PMFstims] = getParticipantThreshold(vars); % Get the participants threshold  
NJitterLevels = length(PMFstims);
vars.NMorphJitters = NJitterLevels;
stimJitterA = PMFstims(1:NJitterLevels/2);
stimJitterH = PMFstims((NJitterLevels/2)+1:end);


% Blocks
% at 2.2 sec SOA, 10 stim presentations/block
if vars.emulate
    vars.StimOn         = 0.5;      % secs
else
    vars.StimOn         = 2;        % secs
end
vars.ITI            = 0.2;      % secs
vars.StimReps       = 8;%10;  % 8*2.2 = 17.6sec
vars.BlockLength    = (vars.StimOn + vars.ITI)*vars.StimReps;
vars.BlockReps      = 4;

% vars.BlockOrder       = [1 3 2 4 1 3 2 4 1 3 2 4 1 3 2 4]; %repmat(1:vars.NStims,1,vars.BlockReps);%[1 3 2 4 1 3 2 4 1 3 2 4 1 3 2 4];        % cue-face-cue-face

tempBlockOrder1     = [1 3 2 4 1 3 2 4 1 3 2 4 1 3 2 4];
tempBlockOrder2     = [2 3 1 4 2 3 1 4 2 3 1 4 2 3 1 4];
tempBlockOrder3     = [1 4 2 3 1 4 2 3 1 4 2 3 1 4 2 3];
tempBlockOrder4     = [2 4 1 3 2 4 1 3 2 4 1 3 2 4 1 3];
blockOrderCoin      = randi([1,4], 1, 1);
switch blockOrderCoin
    case 1
        vars.BlockOrder = tempBlockOrder1;
    case 2
        vars.BlockOrder = tempBlockOrder2;
    case 3
        vars.BlockOrder = tempBlockOrder3;
    case 4
        vars.BlockOrder = tempBlockOrder4;
end

vars.duration       = vars.NStims * vars.BlockReps * vars.BlockLength;  % secs
tempMF              = [ones(1,5), zeros(1,5)];
vars.randMF         = [mixArray(tempMF); mixArray(tempMF)];             % row 1 Happy block, row 2 Angry block


%% MR params
vars.TR                 = 1.4;           % Seconds per volume
vars.Dummies            = 4;             % Dummy volumes at start
vars.Overrun            = 4;             % Dummy volumes at end
vars.VolsPerExpmt       = round(vars.duration/vars.TR) + vars.Dummies + vars.Overrun;

disp(['Desired number of volumes: ', num2str(vars.VolsPerExpmt)]);
% disp('Press any key to continue.');
% pause;

%% Task
vars.NStimsTotal    = (vars.NStims*vars.StimReps*vars.BlockReps);
vars.propTargets    = 0.12;         % proportion of fixation presentations that are targets
NTargetTrials       = round((vars.propTargets * vars.NStimsTotal));
targetTrials        = [ones(1, NTargetTrials) , zeros(1, vars.NStimsTotal-NTargetTrials)];
vars.targetTrialsArray  = [mixArray(targetTrials); zeros(1, vars.NStimsTotal);...
    zeros(1, vars.NStimsTotal); zeros(1, vars.NStimsTotal)];

%% setup results
DummyDouble = ones(vars.NStimsTotal,1).*NaN;
Results = struct('blockN',{DummyDouble},'blockType',{DummyDouble},'stimN',{DummyDouble}, 'Start', {DummyDouble}, 'SOT_cue', {DummyDouble},...
    'SOT_face', {DummyDouble}, 'SOT_ITI', {DummyDouble}, 'SOT_fix', {DummyDouble},'task_press', {DummyDouble},'task_hit', {DummyDouble},...
    'task_falseAlarm', {DummyDouble} ,'End', {DummyDouble});

%% Prepare
% % % Skip internal synch checks, suppress warnings
% % oldLevel = Screen('Preference', 'Verbosity', 0);
% % Screen('Preference', 'SkipSyncTests', 1);
% % Screen('Preference','VisualDebugLevel', 0);
%
% % Diplay configuration
% scr.ViewDist = 80;
% [scr] = displayConfig(scr);
% HideCursor;

% Keyboard & keys configuration
% [id,name] = GetKeyboardIndices; % to see available devices, & http://cbs.fas.harvard.edu/science/core-facilities/neuroimaging/information-investigators/matlabfaq#device_num
KbReleaseWait;                      % Wait for all keyboard buttons released
% Get first mouse device:
d = GetMouseIndices;
deviceIndex = d(1);
% KbQueueCreate(deviceIndex);
% KbQueueStart(deviceIndex);

% % For Keyboard...
% deviceIndex = [];
[keys] = keyConfigQueue();
KbQueueCreate(deviceIndex, keys.keysOfInterest);
KbQueueStart(deviceIndex);

try
    %% Open screen window, if one is not already open
    if ~exist('scr','var')
        if ~isfield(scr, 'win')
            % % Skip internal synch checks, suppress warnings
            % oldLevel = Screen('Preference', 'Verbosity', 0);
            % Screen('Preference', 'SkipSyncTests', 1);
            % Screen('Preference','VisualDebugLevel', 0);
            
            % Diplay configuration
            scr.ViewDist = 56;
            [scr] = displayConfig(scr);
            HideCursor;
            AssertOpenGL;
            [scr.win, scr.winRect] = PsychImaging('OpenWindow', scr.screenID, scr.BackgroundGray); %,[0 0 1920 1080] mr screen dim
            
            % Determine screen params
            scr.dist = scr.ViewDist;
            scr.width  = scr.MonitorWidth;
            scr.resolution = scr.winRect(3:4);
            
            % Set text size, dependent on screen resolution
            if any(logical(scr.winRect(:)>3000))       % 4K resolution
                scr.TextSize = 65;
            else
                scr.TextSize = 28;
            end
            Screen('TextSize', scr.win, scr.TextSize);
        end
    end
    
    
    % Determine stim size in pixels
    StimSizePix = angle2pix(scr, vars.StimSize);
    scr.bkColor = scr.BackgroundGray;
    
    WaitSecs(0.2);
    [~, ~, KeyCode] = KbCheck;
    
    %% Initialise EyeLink
    if vars.useEyeLink
        vars.exptName = 'LocCWT';
        
        % check for eyelink data dir
        if ~exist('./data/eyelink', 'dir')
            mkdir('./data/eyelink')
        end
        
        [vars] = ELsetup(scr, vars);
    end
    
    %% Show init screen
    Screen('FillRect', scr.win, scr.BackgroundGray, scr.winRect);
    DrawFormattedText(scr.win, 'The scan will begin soon...  Press BUTTON 3 when the fixation point changes colour.', 'center', 'center', scr.TextColour);
    [~, ~] = Screen('Flip', scr.win);
    new_line;
    disp('Waiting for experimenter to press SPACE.'); new_line;
    
    % Wait for trigger
    while KeyCode(keys.Space) == 0
        [~, ~, KeyCode] = KbCheck;
        WaitSecs(0.001);
    end
    Results.FirstTriggerT = GetSecs;
%     disp(['Trigger received. Waiting for ', num2str(vars.Dummies), ' dummy volumes.']); new_line;
    %     Results.Start(1)      = GetSecs;
    
    %     [ pressed, firstPress] = KbQueueCheck(deviceIndex);
    %     if pressed
    %         while ~firstPress(keys.Trigger)
    %             WaitSecs(0.001);
    %         end
    %     end
    %     KbQueueFlush();
    
    % If scanning, wait for dummy volumes
%     if ~vars.emulate
%         WaitSecs(vars.TR*vars.Dummies);end
    
    if vars.pptrigger
        sendTrigger = intialiseParallelPort();
        sendTrigger(1) % 1 = start of experiment trigger
        disp('Trigger received')
    end

    if vars.useEyeLink
        Eyelink('message','STARTEXP');
    end
    
    if vars.pptrigger
        sendTrigger(0) % remember to manually pull down triggers
    end
    
    %% Draw fixation screen - start
    scr = drawFixation(scr);
    [~, StartTime] = Screen('Flip', scr.win);
    Results.Start(1)      = StartTime;
    
    %% Main loop
    totalStimCounter = 1;
    tic
    for thisBlock = 1:length(vars.BlockOrder)
        
        %% Update the experimenter and send a message to EL
        startStimText = ['BlockStart_', num2str(thisBlock)];
        disp(startStimText);
        
        trigger_block = thisBlock + 20;

        if vars.pptrigger
            sendTrigger(trigger_block) % 20 + block_no = block start trigger
            disp('Trigger received')
        end
        
        if vars.useEyeLink
            % EyeLink:  message
            Eyelink('message', startStimText);
        end
       
        if vars.pptrigger
            sendTrigger(0) % remember to manually pull down triggers
        end

        %% Determine the stimulus
        % Which block is this?
        % 1-2 cues, 3-4 faces (happy, angry)[, 5 fixation]
        if ismember(vars.BlockOrder(thisBlock), [1, 2])  % Cue  [1, 2, 3]
            switch vars.BlockOrder(thisBlock)
                case 1
%                     thisTrialFileName = 'cue_0';
                    thisTrialFileName = ['cue_', cbal_str, '_', '0'];
                case 2
%                     thisTrialFileName = 'cue_1';
                    thisTrialFileName = ['cue_', cbal_str, '_', '1'];
            end
            
            StimFilePath = strcat(vars.StimFolder, thisTrialFileName,'.tif');
            ImDataOrig = imread(char(StimFilePath));
            StimFileName = thisTrialFileName;
            ImData = imresize(ImDataOrig, [StimSizePix NaN]);
            
            % Make texture image out of image matrix 'imdata'
            ImTex = Screen('MakeTexture', scr.win, ImData);
            
            %% Flash the stim
            for thisStim = 1:vars.StimReps          % loop over the stim reps
                KbQueueFlush([deviceIndex]);
                % Draw texture image to backbuffer
                Screen('FillRect', scr.win, scr.BackgroundGray, scr.winRect);
                Screen('DrawTexture', scr.win, ImTex);
                [~, StimOn] = Screen('Flip', scr.win);
                
                trigger_stimno = thisStim + 40;

                if vars.pptrigger
                    sendTrigger(trigger_stimno) % 40 + stimrep_no = stimulus trigger
                    disp('Trigger received')
                end

                if vars.useEyeLink
                    % EyeLink:  message
                    startStimText = ['StimStart_', num2str(thisStim)];
                    Eyelink('message', startStimText);
                end

                if vars.pptrigger
                    sendTrigger(0) % remember to manually pull down triggers
                end

                WaitSecs(vars.StimOn);
                %% 0.2s fixation
                % Is this a target?
                if vars.targetTrialsArray(1, totalStimCounter)
                    scr.fixation.color = {scr.TaskColours(Randi(3),:),[0,0,0]};
                else
                    scr.fixation.color = {[255,255,255],[0,0,0]};
                end
                scr = drawFixation(scr);
                [~, StimOff] = Screen('Flip', scr.win);
                WaitSecs(vars.ITI);
                
                % Check for keypress
                [ pressed, firstPress] = KbQueueCheck(deviceIndex);

                if pressed && (totalStimCounter ~= 1)
                    Results.task_press(totalStimCounter) = firstPress(keys.Left) - StartTime;

                    if firstPress(keys.Left) %firstPress(1)        %
                        vars.targetTrialsArray(2, totalStimCounter-1) = 1;
                        if vars.targetTrialsArray(1, totalStimCounter-1)
                            vars.targetTrialsArray(3, totalStimCounter-1) = 1;
                            if vars.pptrigger
                                sendTrigger(111) % 111 = target hit trigger
                                disp('Trigger received')
                            end
                            Results.task_hit(totalStimCounter) = firstPress(keys.Left) - StartTime;
                            disp('Target detected - hit');
                            if vars.pptrigger
                                sendTrigger(0) % remember to manually pull down triggers
                            end
                        else
                            vars.targetTrialsArray(4, totalStimCounter-1) = 1;
                            if vars.pptrigger
                                sendTrigger(222) % 222 = false alarm trigger
                                disp('Trigger received')
                            end
                            Results.task_falseAlarm(totalStimCounter) = firstPress(keys.Left) - StartTime;
                            disp('False alarm');
                            if vars.pptrigger
                                sendTrigger(0) % remember to manually pull down triggers
                            end
                        end
                    elseif firstPress(keys.Escape)
                        % Save results
                        save(strcat(vars.OutputFolder, ['Aborted_',vars.DataFileName]), 'Results', 'vars', 'scr', 'keys' );
                        disp(['Aborted! Results were saved as: ', ['Aborted_',vars.DataFileName]]);

                        % Clean up
                        KbQueueRelease(deviceIndex);
                        sca;
                        ShowCursor;
                        fclose('all');
                        Priority(0);
                        return
                    end
                end
                
                %% Update times
                Results.blockN(totalStimCounter)      = thisBlock;
                Results.blockType(totalStimCounter)   = vars.BlockOrder(thisBlock);
                Results.stimN(totalStimCounter)       = thisStim;
                Results.SOT_cue(totalStimCounter)     = StimOn - StartTime;
                Results.SOT_ITI(totalStimCounter)     = StimOff - StartTime;
                
                totalStimCounter = totalStimCounter + 1;
            end
            Screen('Close', ImTex);                      % Close the image texture
            
        elseif ismember(vars.BlockOrder(thisBlock), [3, 4]) % Face[4, 5]
            %% Flash the stim
            for thisStim = 1:vars.StimReps          % loop over the stim reps
                KbQueueFlush(deviceIndex);
                
                if vars.BlockOrder(thisBlock) == 3  % HAPPY
                    if vars.randMF(1,thisStim)      % 1 female
                        genderString = 'F_';
                    else                            % 0 male
                        genderString = 'M_';
                    end
                    thisTrialFileName = [genderString, sprintf('%03d', PMFstims(4))];
                    
                elseif vars.BlockOrder(thisBlock) == 4  %ANGRY
                    if vars.randMF(2,thisStim)      % 1 female
                        genderString = 'F_';
                    else                            % 0 male
                        genderString = 'M_';
                    end
                    thisTrialFileName = [genderString, sprintf('%03d', PMFstims(1))];
                end
                
                % Get the face to be presented
                StimFilePath = strcat(vars.StimFolder, thisTrialFileName,'.tif');
                ImDataOrig = imread(char(StimFilePath));
                StimFileName = thisTrialFileName;
                ImData = imresize(ImDataOrig, [StimSizePix NaN]);
                
                % Make texture image out of image matrix 'imdata'
                ImTex = Screen('MakeTexture', scr.win, ImData);
                % Draw texture image to backbuffer
                Screen('FillRect', scr.win, scr.BackgroundGray, scr.winRect);
                Screen('DrawTexture', scr.win, ImTex);
                [~, StimOn] = Screen('Flip', scr.win);

                trigger_stimno = thisStim + 40;

                if vars.pptrigger
                    sendTrigger(trigger_stimno) % 40 + stimrep_no = stimulus trigger
                    disp('Trigger received')
                end

                if vars.useEyeLink
                    % EyeLink:  message
                    startStimText = ['StimStart_', num2str(thisStim)];
                    Eyelink('message', startStimText);
                end

                if vars.pptrigger
                    sendTrigger(0) % remember to manually pull down triggers
                end

                WaitSecs(vars.StimOn);

                %% 0.2s fixation
                % Is this a target?
                if vars.targetTrialsArray(1, totalStimCounter)
                    scr.fixation.color = {scr.TaskColours(Randi(3),:),[0,0,0]};
                else
                    scr.fixation.color = {[255,255,255],[0,0,0]};
                end
                scr = drawFixation(scr);
                [~, StimOff] = Screen('Flip', scr.win);
                WaitSecs(vars.ITI);
                
                % Check for keypress
                [ pressed, firstPress] = KbQueueCheck(deviceIndex);
                if pressed (totalStimCounter ~= 1)
                    Results.task_press(totalStimCounter) = firstPress(keys.Left) - StartTime;
                    
                    if firstPress(keys.Left) %firstPress(1)
                        vars.targetTrialsArray(2, totalStimCounter-1) = 1;
                        if vars.targetTrialsArray(1, totalStimCounter-1)
                            vars.targetTrialsArray(3, totalStimCounter-1) = 1;
                            if vars.pptrigger
                                sendTrigger(111) % 111 = target hit trigger
                                disp('Trigger received')
                            end
                            Results.task_hit(totalStimCounter) = firstPress(keys.Left) - StartTime;
                            disp('Target detected - hit');
                            if vars.pptrigger
                                sendTrigger(0) % remember to manually pull down triggers
                            end
                        else
                            vars.targetTrialsArray(4, totalStimCounter-1) = 1;
                            if vars.pptrigger
                                sendTrigger(222) % 222 = false alarm trigger
                                disp('Trigger received')
                            end
                            Results.task_falseAlarm(totalStimCounter) = firstPress(keys.Left) - StartTime;
                            disp('False alarm');
                            if vars.pptrigger
                                sendTrigger(0) % remember to manually pull down triggers
                            end
                        end
                    elseif firstPress(keys.Escape)
                        % Save results
                        save(strcat(vars.OutputFolder, ['Aborted_',vars.DataFileName]), 'Results', 'vars', 'scr', 'keys' );
                        disp(['Aborted! Results were saved as: ', ['Aborted_',vars.DataFileName]]);
                        
                        % Clean up
                        KbQueueRelease(deviceIndex);
                        sca;
                        ShowCursor;
                        fclose('all');
                        Priority(0);
                        return
                    end
                end
                
                %% Update times
                Results.blockN(totalStimCounter)      = thisBlock;
                Results.blockType(totalStimCounter)   = vars.BlockOrder(thisBlock);
                Results.stimN(totalStimCounter)       = thisStim;
                Results.SOT_face(totalStimCounter)    = StimOn - StartTime;
                Results.SOT_ITI(totalStimCounter)     = StimOff - StartTime;
                
                totalStimCounter = totalStimCounter + 1;
            end
            
            Screen('Close', ImTex);                      % Close the image texture
            
        elseif vars.BlockOrder(thisBlock) == 5               % Fixation
            for thisStim = 1:vars.StimReps          % loop over the stim reps
                KbQueueFlush([deviceIndex]);
                
                scr.fixation.color = {[255,255,255],[0,0,0]};
                scr = drawFixation(scr);
                [~, StimOn] = Screen('Flip', scr.win);
                
                if vars.pptrigger
                    sendTrigger(60) % 60 = fixation trigger
                    disp('Trigger received')
                end

                if vars.useEyeLink
                    % EyeLink:  message
                    startStimText = ['FixStart'];
                    Eyelink('message', startStimText);
                end

                if vars.pptrigger
                    sendTrigger(0) % remember to manually pull down triggers
                end

                WaitSecs(vars.StimOn);

                %% 0.2s fixation
                % Is this a target?
                if vars.targetTrialsArray(1, thisStim)
                    scr.fixation.color = {scr.TaskColours(Randi(3),:),[0,0,0]};
                else
                    scr.fixation.color = {[255,255,255],[0,0,0]};
                end
                scr = drawFixation(scr);
                [~, StimOff] = Screen('Flip', scr.win);
                WaitSecs(vars.ITI);
                
                % Check for keypress
                [ pressed, firstPress] = KbQueueCheck(deviceIndex);
                if pressed (totalStimCounter ~= 1)
                    Results.task_press(totalStimCounter) = firstPress(keys.Left) - StartTime;
                    
                    if firstPress(keys.Left) %firstPress(1)
                        vars.targetTrialsArray(2, totalStimCounter-1) = 1;
                        if vars.targetTrialsArray(1, totalStimCounter-1)
                            vars.targetTrialsArray(3, totalStimCounter-1) = 1;
                            if vars.pptrigger
                                sendTrigger(111) % 111 = target hit trigger
                                disp('Trigger received')
                            end
                            Results.task_hit(totalStimCounter) = firstPress(keys.Left) - StartTime;
                            disp('Target detected - hit');
                            if vars.pptrigger
                                sendTrigger(0) % remember to manually pull down triggers
                            end
                        else
                            vars.targetTrialsArray(4, totalStimCounter-1) = 1;
                            if vars.pptrigger
                                sendTrigger(222) % 222 = false alarm trigger
                                disp('Trigger received')
                            end
                            Results.task_falseAlarm(totalStimCounter) = firstPress(keys.Left) - StartTime;
                            disp('False alarm');
                            if vars.pptrigger
                                sendTrigger(0) % remember to manually pull down triggers
                            end
                        end
                    elseif firstPress(keys.Escape)
                        % Save results
                        save(strcat(vars.OutputFolder, ['Aborted_',vars.DataFileName]), 'Results', 'vars', 'scr', 'keys' );
                        disp(['Aborted! Results were saved as: ', ['Aborted_',vars.DataFileName]]);
                        
                        % Clean up
                        KbQueueRelease(deviceIndex);
                        sca;
                        ShowCursor;
                        fclose('all');
                        Priority(0);
                        return
                    end
                end
                
                %% Update times
                Results.blockN(totalStimCounter)      = thisBlock;
                Results.blockType(totalStimCounter)   = vars.BlockOrder(thisBlock);
                Results.stimN(totalStimCounter)       = thisStim;
                Results.SOT_cue(totalStimCounter)     = StimOn - StartTime;
                Results.SOT_ITI(totalStimCounter)     = StimOff - StartTime;
                
                totalStimCounter = totalStimCounter + 1;
            end% stimReps
            
            Screen('Close', ImTex);                      % Close the image texture
            
        end% block type switch
        
    end% block loop
    
    %% Draw fixation screen - end
    toc
    [~, EndTime] = Screen('Flip', scr.win);
    Results.End(1)      = EndTime - StartTime;
    
    % If scanning, wait for dummy volumes
    if ~vars.emulate
        WaitSecs(vars.TR*vars.Overrun);end
    
    %% Show end screen
    % Calculate task performace
    totalTargets    = sum(vars.targetTrialsArray(1, :));
    totalHits       = sum(vars.targetTrialsArray(3, :));
    percentDetected = totalHits/totalTargets * 100;
%     feedbackText = ['End of session. Close your eyes and relax while we set up the next scan...'];
    feedbackText = ['End of session. The Learning Task will begin soon...'];
    feedbackTextExperimenter = ['End of session. Participant detected ', num2str(round(percentDetected)), '% of the targets!'];
    disp(feedbackTextExperimenter);

    if vars.pptrigger
        sendTrigger(250) % 250 = end of experiment trigger
        disp('Trigger received')

        sendTrigger(0) % remember to manually pull down triggers
    end

    WaitSecs(3);
    Screen('FillRect', scr.win, scr.BackgroundGray, scr.winRect);
    DrawFormattedText(scr.win, feedbackText, 'center', 'center', scr.TextColour);
    [~, ~] = Screen('Flip', scr.win);
    WaitSecs(3);
    
    %% EyeLink: experiment end
    if vars.useEyeLink
        ELshutdown(vars)
    end
    
    
    %% Save results
    save(strcat(vars.OutputFolder, vars.DataFileName), 'Results', 'vars', 'scr', 'keys' );
    save(strcat(vars.OutputFolder, 'visit_cbal'), 'cbal');
    disp(['Results were saved as: ', vars.DataFileName]);
    
    % Clean up
    KbQueueRelease(deviceIndex);
    %     sca;
    ShowCursor;
    %     fclose('all');
    %     Priority(0);
    %     Screen('Preference', 'Verbosity', oldLevel);
    
    %% Experiment duration
    new_line;
    vars.ExpmtDur = EndTime - StartTime;
    ExpmtDurMin = floor(vars.ExpmtDur/60);
    ExpmtDurSec = mod(vars.ExpmtDur, 60);
    disp(['Cycling lasted ' num2str(ExpmtDurMin) ' minutes, ' num2str(ExpmtDurSec) ' seconds.']);
    new_line;
    
    clearvars
    rmpath(genpath('helpers'));
    
catch ME
    
    % Save results
    save(strcat(vars.OutputFolder, ['Error_',vars.DataFileName]), 'Results', 'vars', 'scr', 'keys' );
    disp(['ERROR! Results were saved as: ', ['Error_',vars.DataFileName]]);
    
    %% EyeLink: experiment end
    if vars.useEyeLink
        ELshutdown(vars)
    end

    if vars.pptrigger
        sendTrigger(250) % 250 = end of experiment trigger
        disp('Trigger received')

        sendTrigger(0) % remember to manually pull down triggers
    end

    % Clean up
    KbQueueRelease(deviceIndex);
    rmpath(genpath('helpers'));
    %     sca;
    ShowCursor;
    %     fclose('all');
    %     Priority(0);
    %     Screen('Preference', 'Verbosity', oldLevel);
    
    rethrow(ME)
end

end