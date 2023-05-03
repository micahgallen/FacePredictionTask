function main(vars, scr)
%function main(vars, scr)
%
% Project: Face Affect Discrimination (FAD) Task, part of CWT
%
% Main experimental script. Uses Psi bayesian adaptive staircase (doi:https://doi.org/10.1167/13.7.3)
%
% Input:
%   vars        struct with key parameters (most are deifne in loadParams.m)
%   scr         struct with screen / display settings
%
% 16.07.2020        NN changed to only use a single staircase, interleaved
% M and F average faces
%
% Niia Nikolova
% Last edit: 16/07/2020


% Load the parameters
loadParams;

% Results struct
DummyDouble = ones(vars.NTrialsTotal,1).*NaN;
DummyString = strings(vars.NTrialsTotal,1);
Results = struct('trialN',{DummyDouble},'EmoResp',{DummyDouble}, 'ConfResp', {DummyDouble},...
    'EmoRT',{DummyDouble}, 'ConfRT', {DummyDouble},'trialSuccess', {DummyDouble}, 'StimFile', {DummyString},...
    'MorphLevel', {DummyDouble}, 'Indiv', {DummyString}, 'SubID', {DummyDouble},...
    'SOT_trial', {DummyDouble},'SOT_face', {DummyDouble}, 'SOT_EmoResp', {DummyDouble},...
    'SOT_ConfResp', {DummyDouble},'SOT_ITI', {DummyDouble}, 'TrialDuration', {DummyDouble});
% col_trialN = 1;
% col_EmoResp = 2;
% col_ConfResp = 3;
% col_EmoRT = 4;
% col_ConfRT = 5;
% col_trialSuccess = 6;
% col_StimFile = 7;
% col_MorphLevel = 8;
% col_Indiv = 9;            M or F for PsiAdaptive
% col_subID = 10;
% SOTs

% Keyboard & keys configuration
[keys] = keyConfig();

% Reseed the random-number generator
SetupRand;


global tutorialAbort

%% Prepare to start
try
    %% Open screen window (check if window is already open)
     if ~exist('scr','var')
        if ~isfield(scr, 'win')
            % Diplay configuration
            [scr] = displayConfig(scr);
            AssertOpenGL;
            [scr.win, scr.winRect] = PsychImaging('OpenWindow', scr.screenID, scr.BackgroundGray); %,[0 0 1920 1080] mr screen dim
            PsychColorCorrection('SetEncodingGamma', scr.win, 1/scr.GammaGuess);
            
            % Set text size, dependent on screen resolution
            if any(logical(scr.winRect(:)>3000))       % 4K resolution
                scr.TextSize = 65;
            else
                scr.TextSize = textSize;
            end
            Screen('TextSize', scr.win, scr.TextSize);
            
            % Set priority for script execution to realtime priority:
            scr.priorityLevel = MaxPriority(scr.win);
            Priority(scr.priorityLevel);
            
            % Determine stim size in pixels
            scr.dist = scr.ViewDist;
            scr.width  = scr.MonitorWidth;
            scr.resolution = scr.winRect(3);                    % number of pixels of display in horizontal direction
        end
    end
    
    StimSizePix     = angle2pix(scr, vars.StimSize);
    vars.StimSizePix   = StimSizePix;
    scr.bkColor     = scr.BackgroundGray;
    scr.hz          = Screen('NominalFrameRate', scr.win); 
    scr.pluxDurSec  =  scr.pluxDur / scr.hz;
    
    % Dummy calls to prevent delays
    vars.ValidTrial = zeros(1,2);
    vars.RunSuccessfull = 0;
    vars.Aborted = 0;
    vars.Error = 0;
    WaitSecs(0.1);
    GetSecs;
    vars.Resp = 888;
    vars.ConfResp = 888;
    vars.abortFlag = 0;
    tutorialAbort = 0;
    WaitSecs(0.500);
    [~, ~, keys.KeyCode] = KbCheck;
    
    %% Initialise EyeLink
    if useEyeLink
        vars.EyeLink = 1;
        
        % check for eyelink data dir
        if ~exist('./data/eyelink', 'dir')
            mkdir('./data/eyelink')
        end
        
        [vars] = ELsetup(scr, vars);
    end
    
    if vars.runFADtutorial
        fadTutorial(scr, keys, vars)
        % If Esc was pressed, abort
        if tutorialAbort == 1
            return
        end
    end

   
    %% Show task instructions
    Screen('FillRect', scr.win, scr.BackgroundGray, scr.winRect);
    DrawFormattedText(scr.win, [vars.InstructionTask], 'center', 'center', scr.TextColour);
    Screen('FillRect', scr.win, scr.pluxBlack, scr.pluxRect);           % Ashley added plux
    [~, ~] = Screen('Flip', scr.win);
    
    new_line;
    disp('Thresholding task ready. Press SPACE to start.'); new_line;
    
    while keys.KeyCode(keys.Space) == 0                                    % Wait for trigger
        [~, ~, keys.KeyCode] = KbCheck;
        WaitSecs(0.001);
    end

    Results.SessionStartT = GetSecs;            % session start = trigger 1 + dummy vols
    disp('Session started.');

    if vars.pptrigger
        sendTrigger = intialiseParallelPort();
        sendTrigger(1) % 1 = start of experiment trigger
        disp('Trigger received')
    end

    if useEyeLink
        Eyelink('message','STARTEXP');
    end

    if vars.pptrigger
        sendTrigger(0) % remember to manually pull down triggers
    end

    tic

    %% Run through trials
    WaitSecs(0.500);            % pause before experiment start
    thisTrial = 1;              % trial counter
    endOfExpt = 0;
    trialReps = 0;
    
    while endOfExpt ~= 1       % General stop flag for the loop
        
        Results.SOT_trial(thisTrial) = GetSecs;

        if vars.pptrigger
            sendTrigger(10) % 10 = start of trial trigger
            disp('Trigger received')
        end

        if useEyeLink
            % EyeLink:  this trial
            startStimText = ['Trial ' num2str(thisTrial) ' starts now'];
            Eyelink('message', startStimText); % Send message
        end
        
        if vars.pptrigger
            sendTrigger(0) % remember to manually pull down triggers
        end

        %% Determine which stimulus to present, read in the image, adjust size and show stimulus
        % Which gender face to present on this trial?
        switch vars.faceGenderSwitch(thisTrial)
            case 0
                thisTrialGender = 'F_';
            case 1
                thisTrialGender = 'M_';
        end
        
        thisTrialStim = stair.PM.xCurrent;
        
        thisTrialFileName = [thisTrialGender, sprintf('%03d', thisTrialStim), '.tif'];
        disp(['Trial # ', num2str(thisTrial), '. Stim: ', thisTrialFileName]);
        
        % Read stim image for this trial into matrix 'imdata'
        StimFilePath = strcat(vars.StimFolder, thisTrialFileName);
        ImDataOrig = imread(char(StimFilePath));
        StimFileName = thisTrialFileName;
        ImData = imresize(ImDataOrig, [StimSizePix NaN]);           % Adjust image size to StimSize dva in Y dir
        
        % Make texture image out of image matrix 'imdata'
        ImTex = Screen('MakeTexture', scr.win, ImData);
        
        % Draw texture image to backbuffer
        Screen('DrawTexture', scr.win, ImTex);
        Screen('FillRect', scr.win, scr.pluxBlack, scr.pluxRect);
        [~, StimOn] = Screen('Flip', scr.win);
        
        Results.SOT_face(thisTrial) = GetSecs;

        if vars.pptrigger
            if thisTrialStim <= 100
                sendTrigger(120) %  = ANGRY face trigger
                disp('Trigger received')
            elseif thisTrialStim > 100
                sendTrigger(125) %  = HAPPY face trigger
                disp('Trigger received')
            end
        end

        if useEyeLink
            % EyeLink:  face on
            startStimText = ['Trial ' num2str(thisTrial) ' face stim on'];
            Eyelink('message', startStimText); % Send message
        end

        if vars.pptrigger
            sendTrigger(0) % remember to manually pull down triggers
        end

        % While loop to show stimulus until StimT seconds elapsed.
        while (GetSecs - StimOn) <= vars.StimT

            Screen('FillRect', scr.win, scr.BackgroundGray, scr.winRect);
            Screen('FillRect', scr.win, scr.pluxBlack, scr.pluxRect);
            Screen('DrawTexture', scr.win, ImTex);
            
            % Draw plux trigger -- STIM
            if vars.pluxSynch
                % if were in the first pluxDurationSec seconds, draw the rectangle
                % Angry
                if thisTrialStim <= 100 && ((GetSecs - StimOn) <= scr.pluxDurSec(2)) 
                    Screen('FillRect', scr.win, scr.pluxWhite, scr.pluxRect);
                % Happy
                elseif thisTrialStim > 100 && ((GetSecs - StimOn) <= scr.pluxDurSec(2))
                    Screen('FillRect', scr.win, scr.pluxWhite, scr.pluxRect);
                end
            end
            
            Screen('Flip', scr.win);
            
            % KbCheck for Esc key
            if keys.KeyCode(keys.Escape)==1
                % Save, mark the run
                vars.RunSuccessfull = 0;
                vars.Aborted = 1;
                experimentEnd(vars, scr, keys, Results, stair);
                return
            end
            [~, ~, keys.KeyCode] = KbCheck;
            WaitSecs(0.001);
            
        end
        
        Screen('FillRect', scr.win, scr.pluxBlack, scr.pluxRect);
        [~, ~] = Screen('Flip', scr.win);            % clear screen

        if vars.pptrigger
            sendTrigger(123) % 123 = face stim off trigger
            disp('Trigger received')
        end

        if useEyeLink
            % EyeLink:  face off
            startStimText = ['Trial ' num2str(thisTrial) ' face stim off'];
            Eyelink('message', startStimText); % Send message
        end

        if vars.pptrigger
            sendTrigger(0) % remember to manually pull down triggers
        end

        %% Show emotion prompt screen
        % Angry (L arrow) or Happy (R arrow)?
        Screen('FillRect', scr.win, scr.BackgroundGray, scr.winRect);
        Screen('FillRect', scr.win, scr.pluxBlack, scr.pluxRect);
        DrawFormattedText(scr.win, [vars.InstructionQ], 'center', 'center', scr.TextColour);
        
        [~, vars.StartRT] = Screen('Flip', scr.win);
        
        if vars.pptrigger
            sendTrigger(70) % 70 = emotion prompt trigger
            disp('Trigger received')
        end

        if useEyeLink
            % EyeLink:  face response
            startStimText = ['Trial ' num2str(thisTrial) ' face response screen on'];
            Eyelink('message', startStimText); % Send message
        end

        if vars.pptrigger
            sendTrigger(0) % remember to manually pull down triggers
        end

        % Fetch the participant's response, via keyboard or mouse
        [vars] = getResponse(keys, scr, vars);
        
        Results.SOT_EmoResp(thisTrial) = vars.EndRT;
        
        if vars.abortFlag               % Esc was pressed
            Results.EmoResp(thisTrial) = 9;
            % Save, mark the run
            vars.RunSuccessfull = 0;
            vars.Aborted = 1;
            experimentEnd(vars, scr, keys, Results, stair);
            return
        end
        
        % Update staircase, if valid response
        if vars.ValidTrial(1)
            
            stair.PM = PAL_AMPM_updatePM(stair.PM, vars.Resp);
            % Time to stop?
            if (stair.PM.stop ~= 1)
                endOfExpt = 0;
            else
                endOfExpt = 1;
            end
        end
        
        % Compute response time
        RT = (vars.EndRT - vars.StartRT);
        
        % Write trial result to file
        Results.EmoResp(thisTrial) = vars.Resp;
        Results.EmoRT(thisTrial) = RT;
        
        
        
        %% Confidence rating
        if vars.ConfRating
            
            if useEyeLink
                % EyeLink:  conf rating
                startStimText = ['Trial ' num2str(thisTrial) ' confidence screen on'];
                Eyelink('message', startStimText);
            end
            
            % Fetch the participant's confidence rating
            [vars] = getConfidence(keys, scr, vars);
            Results.SOT_ConfResp(thisTrial) = vars.ConfRatingT;
            
            if vars.abortFlag       % Esc was pressed
                Results.ConfResp(thisTrial) = 9;
                % Save, mark the run
                vars.RunSuccessfull = 0;
                vars.Aborted = 1;
                experimentEnd(vars, scr, keys, Results, stair);
                return
            end
            
            % If this trial was successfull, move on...
            if(vars.ValidTrial(2)), WaitSecs(0.2); end
            
            % Write trial result to file
            Results.ConfResp(thisTrial) = vars.ConfResp;
            Results.ConfRT(thisTrial) = vars.ConfRatingT;
            
            % Was this a successfull trial? (both emotion and confidence rating valid)
            % 1-success, 0-fail
            Results.trialSuccess(thisTrial) = logical(sum(vars.ValidTrial) == 2);
            
        else % no Confidence rating
            
            % Was this a successfull trial? (emotion rating valid)
            % 1-success, 0-fail
            Results.trialSuccess(thisTrial) = logical(sum(vars.ValidTrial(1)) == 1);
            
        end
        
        %% Update Results
        Results.trialN(thisTrial) = thisTrial;
        Results.StimFile(thisTrial) = StimFileName;
        Results.SubID(thisTrial) = vars.subNo;
        Results.Indiv(thisTrial) = StimFileName(1);
        Results.MorphLevel(thisTrial) = str2double(StimFileName(3:5));
        
        
        %% ITI / prepare for next trial
        Screen('FillRect', scr.win, scr.BackgroundGray, scr.winRect);
        Screen('FillRect', scr.win, scr.pluxBlack, scr.pluxRect);
        [~, StartITI] = Screen('Flip', scr.win);
        
        Results.SOT_ITI(thisTrial) = GetSecs;

        if vars.pptrigger
            sendTrigger(80) % 80 = ITI start trigger
            disp('Trigger received')
        end

        if useEyeLink
            % EyeLink:  ITI
            startStimText = ['Trial ' num2str(thisTrial) ' ITI start'];
            Eyelink('message', startStimText); % Send message
        end
        
        if vars.pptrigger
            sendTrigger(0) % remember to manually pull down triggers
        end

        % Present the gray screen for ITI duration
        while (GetSecs - StartITI) <= vars.ITI(thisTrial)
            
            if keys.KeyCode(keys.Escape)==1
                % Save, mark the run
                vars.RunSuccessfull = 0;
                vars.Aborted = 1;
                experimentEnd(vars, scr, keys, Results, stair);
                return
            end
        end
        
        [~, ~, keys.KeyCode] = KbCheck;
        WaitSecs(0.001);
        
        Results.TrialDuration(thisTrial) = GetSecs - Results.SOT_trial(thisTrial);
        
        % If the trial was missed, repeat it or go on...
        if vars.RepeatMissedTrials
            % if this was a valid trial, advance one. Else, repeat it.
            if vars.ValidTrial(1)            % face affect rating
                thisTrial = thisTrial + 1;
            else        % Repeat the trial...
                
                if trialReps > 4        % if a trial was repeated 5 times, go on
                    thisTrial = thisTrial + 1;
                    trialReps = 0;
                else                    % otherwise, repeat it
                    trialReps = trialReps + 1;
                    disp('Invalid response. Repeating trial.');
                end
                
            end
        else
            % Advance one trial
            thisTrial = thisTrial + 1;
        end
        
        % Reset Texture, ValidTrial, Resp
        vars.ValidTrial = zeros(1,2);
        vars.Resp = NaN;
        vars.ConfResp = NaN;
        Screen('Close', ImTex);
        
        if vars.pptrigger
            sendTrigger(180) % 180 = end of trial trigger
            disp('Trigger received')
        end

        if useEyeLink
            % EyeLink:  trial end
            startStimText = ['Trial ' num2str(thisTrial) ' ends now'];
            Eyelink('message', startStimText);          % Send message
        end
        
        if vars.pptrigger
            sendTrigger(0) % remember to manually pull down triggers
        end

    end%thisTrial
    
    Results.SessionEndT = GetSecs - Results.SessionStartT;
    vars.RunSuccessfull = 1;
    
    % Save, mark the run
    experimentEnd(vars, scr, keys, Results, stair);
    
    toc
    
    %% EyeLink: experiment end
    if useEyeLink
        ELshutdown(vars)
    end
    
    % Cleanup at end of experiment - Close window, show mouse cursor, close
    % result file, switch back to priority 0
    %     sca;
    ShowCursor;
    %     fclose('all');
    %     Priority(0);
    
    %% Show summary of results
    new_line;
    
    % Get the stim levels at which participant performane is .3 .5 and .7
    pptPMFvals = [stair.PM.threshold(length(stair.PM.threshold)) 10.^stair.PM.slope(length(stair.PM.threshold)) 0 stair.PM.lapse(length(stair.PM.threshold))];
    inversePMFvals = [0.25, 0.5, 0.75];
    inversePMFstims = stair.PF(pptPMFvals, inversePMFvals, 'inverse');
    inversePMFstims = round(inversePMFstims,2);
    
    disp('Calculating threshold and slope estimates. This will take a few seconds...');
    % Print thresh & slope estimates
    disp(['Threshold estimate: ', num2str(inversePMFstims(2))]);
    disp(['Slope estimate: ', num2str(10.^stair.PM.slope(end))]);         % PM.slope is in log10 units of beta parameter
    
    %% Plot the threshold estimate over trials (visual check for convergence)
    if plotStaircase
        % Plot threshold estimate by trial # and pmf fit
        simplePMFplot(stair)
    end
    
catch ME% Error. Clean up...
    
    % Save, mark the run
    vars.RunSuccessfull = 0;
    vars.Error = 1;
    experimentEnd(vars, scr, keys, Results, stair);
    rethrow(ME)
end
