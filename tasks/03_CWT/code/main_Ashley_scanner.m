function main_Ashley_scanner(vars, scr, cbal)
%function main_Ashley(vars, scr, cbal)
%
% Project: CWT task, for fMRI
%
% Main experimental script. Waits for scanner trigger (5%) to start.
%
% Presents a cue, followed by a face, then queries whether the face was
% perceived as Happy or Angry, and Confidence. Face gender and affect are
% balanced accross probabilistic blocks.
%
% Happy and angry face morphs used are determined by the participants PMF,
% eg. morph at 25% & 75% happy response.
%
% Input:
%   vars        struct with key parameters (most are deifne in loadParams.m)
%   scr         struct with screen / display settings
%
%
% 16.06.2020        NN added useEyeLink flag to allow gaze recording
% 22.06.2020        NN adding cueing task, removed thresholding procedures
% 01.07.2020        NN updated to take cue & face stimulus on each trial
%                   from sequence set up by setupCueProbabilities
%                   ### change to read in from saved file ###
%                   ### Add command line indication for which block we're
%                   in & a break around the middle (after a Pred block)###
%
% Created by Niia Nikolova
% Edited by Ashley Tyrer
% Last edit: 01/02/2023


% Load the parameters
loadParams_Ashley;
disp(strcat('Main, cbal = ', num2str(cbal)))

vars.cat_slide = 1;

% Fill in Results structure
Results.outputMat           = vars.cueProbabilityOutput;
Results.conditionSequence  = vars.cueProbabilityOutput(:,2);            % conditions (1:5), % 1 cue_0 valid   2 cue_1 valid    3 cue_0 invalid    4 cue_1 invalid      5 non-predictive 
Results.faceSequence       = vars.cueProbabilityOutput(:,4);            % sequence of face genders [0|1]
Results.cueSequence        = vars.cueProbabilityOutput(:,5);            % sequence of cues [0|1]
Results.trialSequence      = vars.cueProbabilityOutput(:,6);            % 1 valid, 2 invalid
Results.FaceEmot           = vars.cueProbabilityOutput(:,10);           % 1 happy, 0 angry
Results.cue0Prediction     = vars.cueProbabilityOutput(:,12);           % %(is cue 0 predictive of Happy (1) or Angry (2) faces, on non-predictive(0)?)
Results.predictionTrialNext = vars.cueProbabilityOutput(:,13);          % 1 if there is a prediction trial after the ITI of this trial

Results.breaks                         = vars.breaks;                  	% break AFTER this trial
Results.blockParams                    = vars.blockParams;
Results.desiredBlockProbabilities      = vars.desiredBlockProbabilities;
Results.effectiveBlockProbabilities    = vars.effectiveBlockProbabilities;
Results.blockLengths                   = vars.blockLengths;
Results.trialByTrialBlockVector        = vars.trialByTrialBlockVector;

DummyDouble = ones(vars.NTrialsTotal,1).*NaN;
DummyString = strings(vars.NTrialsTotal,1);


Results = struct('trialN',{DummyDouble},'EmoResp',{DummyDouble}, 'ConfResp', {DummyDouble},...
    'EmoRT',{DummyDouble}, 'ConfRT', {DummyDouble}, 'EmoAcc', {DummyDouble}, 'PTResp',  {DummyDouble}, 'PTAcc', {DummyDouble}, 'PTRT', {DummyDouble},...
    'trialSuccess', {DummyDouble}, 'StimFile', {DummyString}, 'Condition', {DummyDouble},...
    'MorphLevel', {DummyDouble}, 'Indiv', {DummyString}, 'SubID', {DummyDouble}, 'Cue', {DummyDouble}, 'CueProbDesired',...
    {DummyDouble}, 'CueProbEffective', {DummyDouble},'Triggers', {DummyDouble}, 'SOT_trial', {DummyDouble}, 'SOT_cue', {DummyDouble},...
    'SOT_ISI', {DummyDouble}, 'SOT_face', {DummyDouble}, 'SOT_EmoResp', {DummyDouble}, 'SOT_ISI2', {DummyDouble}, 'SOT_ISI3', {DummyDouble}, 'SOT_ConfOn', {DummyDouble},...
    'SOT_ConfOff', {DummyDouble},'SOT_ConfResp', {DummyDouble},...
    'SOT_ITI', {DummyDouble},'SOT_PT', {DummyDouble}, 'SOT_PTResp', {DummyDouble}, 'SOT_PTEnd', {DummyDouble},'TrialDuration', {DummyDouble});

% trialN
% EmoResp
% ConfResp
% EmoRT
% EmoAcc            correct/incorrect
% ConfRT
% PTResp            predictiontrial response
% PTAcc             correct/incorrect  
% PRRT              prediction trial RT
% trialSuccess
% StimFile
% MorphLevel
% Indiv            M or F for PsiAdaptive
% subID
% Cue              1 or 2
% CueProb          Probability of this cue predicting Happy
% Triggers
% SOT_trial
% SOT_cue
% SOT_ISI
% SOT_face
% SOT_EmoResp
% SOT_ConfResp
% SOT_ITI
% SOT_PT
% TrialDuration

% Diplay configuration
% [scr] = displayConfig(scr);

% Keyboard & keys configuration
[keys] = keyConfig();

% Reseed the random-number generator
SetupRand;

global tutorialAbort

% If this participant does not have a FAD threshold, and we want to abort
if noThreshFlag
    disp('No emotion discrimination threshold found. Terminating CWT task.');
    vars.RunSuccessfull = 0;
    vars.Aborted = 1;
    experimentEnd(keys, Results, scr, vars);
    return
end

%% Prepare to start
try
    %% Open screen window
    if ~isfield(scr, 'win')
        

        AssertOpenGL;
        [scr.win, scr.winRect] = PsychImaging('OpenWindow', scr.screenID, scr.BackgroundGray); %,[0 0 1920 1080] mr screen dim
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
        scr.dist        = scr.ViewDist;
        scr.width       = scr.MonitorWidth;
        scr.resolution  = scr.winRect(3:4);
        
    end
                   
    StimSizePix = angle2pix(scr, vars.StimSize);
    vars.StimSizePix = StimSizePix;
    scr.hz          = Screen('NominalFrameRate', scr.win); 
    scr.pluxDurSec  =  scr.pluxDur / scr.hz;

    scr.TextColour = [192 192 192];
    
    % Dummy calls to prevent delays
    vars.ValidTrial = zeros(1,2);
    vars.RunSuccessfull = 0;
    vars.Aborted = 0;
    vars.Error = 0;
    thisTrialCorrect = 0;
    WaitSecs(0.1);
    GetSecs;
    vars.Resp = 888;
    vars.ConfResp = NaN;%888;
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
    

    if vars.runCWTtutorial 
        disp(num2str(cbal))
          cwtTutorial_Ashley(scr, keys, vars, cbal);
          % If Esc was pressed, abort
          if tutorialAbort == 1
              return
          end
    end
    
    %% Show task instructions
    Screen('FillRect', scr.win, scr.BackgroundGray, scr.winRect);
    if vars.pluxSynch
        Screen('FillRect', scr.win, scr.pluxBlack, scr.pluxRect);
    end
    DrawFormattedText(scr.win, [vars.InstructionTask], 'center', 'center', scr.TextColour);
    [~, ~] = Screen('Flip', scr.win);
    new_line;


    % Wait for Space press
    while keys.KeyCode(keys.Space) == 0
        [~, ~, keys.KeyCode] = KbCheck;
        WaitSecs(0.001);
    end

    
    Results.SessionStartT = GetSecs;            % session start
    disp(['Starting experiment.'])

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


    %% intitialize propix triggers
    
    isConnected = Datapixx('isReady');
    if ~isConnected
        Datapixx('Open');
    end

    send_propix_trigger(vars.propixtrigger, vars.triggers.TaskStart)
    [~, ~] = Screen('Flip', scr.win);

    %% Run through trials
    WaitSecs(0.500);            % pause before experiment start
    thisTrial = 1;              % trial counter
    happyCounter = 1;
    angryCounter = 1;
    thisPT = 1;                 % prediction trials counter
    endOfExpt = 0;
    
    send_propix_trigger(vars.propixtrigger, vars.triggers.CloseTrigger)
    
    [~, ~] = Screen('Flip', scr.win);

    while endOfExpt ~= 1       % General stop flag for the loop
        
        Results.SOT_trial(thisTrial) = GetSecs - Results.SessionStartT;

        if vars.pptrigger
            sendTrigger(10) % 10 = start of trial trigger
            disp('Trigger received')
        end
        
        if useEyeLink
            % EyeLink:  this trial
            startStimText = ['Trial ' num2str(thisTrial) ' start'];
            Eyelink('message', startStimText);
        end

        if vars.pptrigger
            sendTrigger(0) % remember to manually pull down triggers
        end

        %% Present cue
        thisCue = vars.cueSequence(thisTrial);
        thisTrialCue = ['cue_', num2str(cbal), '_', num2str(thisCue), '.tif'];          % ASHLEY -- this is where we load the cue image!!!
        disp(['Trial # ', num2str(thisTrial), '. Cue: ', thisTrialCue]);
        
        % Read stim image for this trial into matrix 'imdata'
        CueFilePath = strcat(vars.StimFolder, thisTrialCue);
        ImDataOrig = imread(char(CueFilePath));
        ImData = imresize(ImDataOrig, [StimSizePix NaN]);           % Adjust image size to StimSize dva in Y dir
        
        % Make texture image out of image matrix 'imdata'
        ImTex = Screen('MakeTexture', scr.win, ImData);
        
        % Draw texture image to backbuffer
        Screen('FillRect', scr.win, scr.BackgroundGray, scr.winRect);
        if vars.pluxSynch
            Screen('FillRect', scr.win, scr.pluxBlack, scr.pluxRect);
        end
        
        
        Screen('DrawTexture', scr.win, ImTex);
        
        send_propix_trigger(vars.propixtrigger, vars.triggers.cueOnset)    

        [~, CueOn] = Screen('Flip', scr.win);
        
   
        Results.SOT_cue(thisTrial) = CueOn - Results.SessionStartT;
        
        if vars.pptrigger
            if thisCue == 0     &&((GetSecs - CueOn) <= scr.pluxDurSec(1))
                sendTrigger(100) % 100 = cue 0 trigger
                disp('Trigger received')
            elseif thisCue == 1 &&((GetSecs - CueOn) <= scr.pluxDurSec(1))
                sendTrigger(105) % 105 = cue 1 trigger
                disp('Trigger received')
            end
        end

        if useEyeLink
            % EyeLink:  cue on
            startStimText = ['Trial ' num2str(thisTrial) ' cue on'];
            Eyelink('message', startStimText);
        end
        
        if vars.pptrigger
            sendTrigger(0) % remember to manually pull down triggers
        end

        % While loop to show stimulus until CueT seconds elapsed.
        while (GetSecs - CueOn) <= vars.CueT
            
            % Draw the cue screen
            Screen('FillRect', scr.win, scr.BackgroundGray, scr.winRect);
            if vars.pluxSynch
                Screen('FillRect', scr.win, scr.pluxBlack, scr.pluxRect);
            end
            Screen('DrawTexture', scr.win, ImTex);
            
            % Draw plux trigger -- CUE
            if vars.pluxSynch
                % if were in the first pluxDurationSec seconds, draw the rectangle
                if thisCue == 0     &&((GetSecs - CueOn) <= scr.pluxDurSec(1)) 
                    Screen('FillRect', scr.win, scr.pluxWhite, scr.pluxRect);
                elseif thisCue == 1 &&((GetSecs - CueOn) <= scr.pluxDurSec(1))
                    Screen('FillRect', scr.win, scr.pluxWhite, scr.pluxRect);
                end
            end

            % Flip screen
            Screen('Flip', scr.win);

            % KbCheck for Esc key
            if keys.KeyCode(keys.Escape)==1
                % Save, mark the run
                vars.RunSuccessfull = 0;
                vars.Aborted = 1;
                experimentEnd(keys, Results, scr, vars);
                return
            end
            
            [~, ~, keys.KeyCode] = KbCheck;
            WaitSecs(0.001);
            
        end
       
        if vars.pluxSynch
            Screen('FillRect', scr.win, scr.pluxBlack, scr.pluxRect);
        end

        send_propix_trigger(vars.propixtrigger, vars.triggers.CloseTrigger)
        [~, ~] = Screen('Flip', scr.win);            % clear screen
        
        if vars.pptrigger
            sendTrigger(12) % 12 = cue off trigger
            disp('Trigger received')
        end

        if useEyeLink
            % EyeLink:  cue off
            startStimText = ['Trial ' num2str(thisTrial) ' cue off'];
            Eyelink('message', startStimText);
        end

        if vars.pptrigger
            sendTrigger(0) % remember to manually pull down triggers
        end

        Screen('Close', ImTex);                      % Close the image texture
        
        %% ISI
        Screen('FillRect', scr.win, scr.BackgroundGray, scr.winRect);
        if vars.pluxSynch
            Screen('FillRect', scr.win, scr.pluxBlack, scr.pluxRect);
        end
        if vars.fixCrossFlag
            scr = drawFixation(scr);end

        send_propix_trigger(vars.propixtrigger, vars.triggers.fixOnset)
        
        [~, StartITI] = Screen('Flip', scr.win);
        
        Results.SOT_ISI(thisTrial) = StartITI - Results.SessionStartT;

        if vars.pptrigger
            sendTrigger(13) % 13 = ISI jitter start trigger
            disp('Trigger received')
        end

        if useEyeLink
            % EyeLink:  ITI
            startStimText = ['Trial ' num2str(thisTrial) ' jitter start'];
            Eyelink('message', startStimText);
        end
        
        if vars.pptrigger
            sendTrigger(0) % remember to manually pull down triggers
        end

        % Present the gray screen for ITI duration
        while (GetSecs - StartITI) <= vars.ISI(thisTrial)
            
            if keys.KeyCode(keys.Escape)==1
                % Save, mark the run
                vars.RunSuccessfull = 0;
                vars.Aborted = 1;
                experimentEnd(keys, Results, scr, vars);
                return
            end
        end
        
        [~, ~, keys.KeyCode] = KbCheck;
        send_propix_trigger(vars.propixtrigger, vars.triggers.CloseTrigger)
        [~, ~] = Screen('Flip', scr.win);
        WaitSecs(0.001);
        
        
        %% Show emotion prompt screen
        % Angry (L arrow) or Happy (R arrow)?
        Screen('FillRect', scr.win, scr.BackgroundGray, scr.winRect);
        if vars.pluxSynch
            Screen('FillRect', scr.win, scr.pluxBlack, scr.pluxRect);
        end
        DrawFormattedText(scr.win, [vars.InstructionQ], 'center', 'center', scr.TextColour);
        
        send_propix_trigger(vars.propixtrigger, vars.triggers.respIntOnset)

        [~, vars.StartRT] = Screen('Flip', scr.win);
        
        send_propix_trigger(vars.propixtrigger, vars.triggers.CloseTrigger)

        if vars.pptrigger
            sendTrigger(70) % 70 = emotion prompt trigger
            disp('Trigger received')
        end

        if useEyeLink
            % EyeLink:  face response
            startStimText = ['Trial ' num2str(thisTrial) ' face response screen on'];
            Eyelink('message', startStimText);
        end

        if vars.pptrigger
            sendTrigger(0) % remember to manually pull down triggers
        end

        thisTrialStim = vars.FaceEmot(thisTrial);         % 1 Happy, 0 Angry

        % Fetch the participant's response, via keyboard or mouse
        [vars] = getResponse(keys, scr, vars);
        
        Results.SOT_EmoResp(thisTrial) = vars.EndRT - Results.SessionStartT;
        
        if vars.abortFlag               % Esc was pressed
            Results.EmoResp(thisTrial) = 9;
            % Save, mark the run
            vars.RunSuccessfull = 0;
            vars.Aborted = 1;
            experimentEnd(keys, Results, scr, vars);
            return
        end
        
        % Time to stop? (max # trials reached)
        if (thisTrial == vars.NTrialsTotal)
            endOfExpt = 1;
        end
        
        % Compute response time
        RT = (vars.EndRT - vars.StartRT);
        
        % Compute accuracy
        if thisTrialStim==1     % 1 happy face
            if vars.Resp==1     % response happy
                thisTrialCorrect = 1;
            elseif vars.Resp==0
                thisTrialCorrect = 0;
            else                % resp = NaN
                thisTrialCorrect = NaN;
            end
        elseif thisTrialStim==0 % 0 angry face
            if vars.Resp==1     % response happy
                thisTrialCorrect = 0;
            elseif vars.Resp==0
                thisTrialCorrect = 1;
            else                % resp = NaN
                thisTrialCorrect = NaN;
            end
        end

        
        
        % Write trial result to file
        Results.EmoResp(thisTrial) = vars.Resp;
        Results.EmoRT(thisTrial) = RT;
        Results.EmoAcc(thisTrial) = thisTrialCorrect;
        Results.RTFliptimes(thisTrial) = vars.RTFlipTime;
        
        % nag the participant if too slow
        if vars.ValidTrial(1) == 0
            displayTooSlowMessage(scr)
        end

        %% ISI
        Screen('FillRect', scr.win, scr.BackgroundGray, scr.winRect);
        if vars.pluxSynch
            Screen('FillRect', scr.win, scr.pluxBlack, scr.pluxRect);
        end
        if vars.fixCrossFlag
            scr = drawFixation(scr);
        end

        send_propix_trigger(vars.propixtrigger, vars.triggers.fixOnset)
        [~, StartITI2] = Screen('Flip', scr.win);
        send_propix_trigger(vars.propixtrigger, vars.triggers.CloseTrigger)
        Results.SOT_ISI2(thisTrial) = StartITI2 - Results.SessionStartT;

        if vars.pptrigger
            sendTrigger(13) % 13 = ISI jitter start trigger
            disp('Trigger received')
        end

        if useEyeLink
            % EyeLink:  ITI
            startStimText = ['Trial ' num2str(thisTrial) ' 2nd jitter start'];
            Eyelink('message', startStimText);
        end
        
        if vars.pptrigger
            sendTrigger(0) % remember to manually pull down triggers
        end

        % Present the gray screen for ITI duration
        while (GetSecs - StartITI2) <= vars.ISI(thisTrial)
            
            if keys.KeyCode(keys.Escape)==1
                % Save, mark the run
                vars.RunSuccessfull = 0;
                vars.Aborted = 1;
                experimentEnd(keys, Results, scr, vars);
                return
            end
        end
        
        [~, ~, keys.KeyCode] = KbCheck;
        WaitSecs(0.001);
        
        %% Present face stimulus
        % Is the outcome H or A?
%         thisTrialStim = vars.FaceEmot(thisTrial);         % 1 Happy, 0 Angry
        if thisTrialStim %vars.FaceEmot(thisTrial)
            emotShown = 'happy';
        else
            emotShown = 'angry';
        end
        
        % Is the face F or M?
        if vars.faceSequence(thisTrial)     % 1 female
            thisFaceGender = 'F_';
        else                                % 0 male
            thisFaceGender = 'M_';
        end
        
        if thisTrialStim                    % Happy
            thisFaceAffect = vars.FaceMorphs(2, happyCounter);
            happyCounter = happyCounter + 1;
        else                                % Angry
            thisFaceAffect = vars.FaceMorphs(1, angryCounter);
            angryCounter = angryCounter + 1;
        end
        
        % Preassigned equal #s of M and F faces per block
        thisTrialFileName = [thisFaceGender, sprintf('%03d', thisFaceAffect), '.tif'];
        
        disp(['Trial # ', num2str(thisTrial), '. Stim: ', emotShown, ', ' thisTrialFileName(1:5)]);
        
        % Read stim image for this trial into matrix 'imdata'
        StimFilePath = strcat(vars.StimFolder, thisTrialFileName);
        ImDataOrig = imread(char(StimFilePath));
        StimFileName = thisTrialFileName;
        ImData = imresize(ImDataOrig, [StimSizePix NaN]);           % Adjust image size to StimSize dva in Y dir
        
        % Make texture image out of image matrix 'imdata'
        ImTex = Screen('MakeTexture', scr.win, ImData);
        
        % Draw texture image to backbuffer
        Screen('FillRect', scr.win, scr.BackgroundGray, scr.winRect);
        if vars.pluxSynch
            Screen('FillRect', scr.win, scr.pluxBlack, scr.pluxRect);
        end
        Screen('DrawTexture', scr.win, ImTex);
      
        send_propix_trigger(vars.propixtrigger, vars.triggers.stimOnset)
        [~, StimOn] = Screen('Flip', scr.win);
        
        
        Results.SOT_face(thisTrial) = StimOn - Results.SessionStartT;
        
        if vars.pptrigger
            if thisTrialStim == 0     &&((GetSecs - StimOn) <= scr.pluxDurSec(2)) 
                sendTrigger(120) % 120 = ANGRY stimulus trigger
                disp('Trigger received')
            elseif thisTrialStim == 1 &&((GetSecs - StimOn) <= scr.pluxDurSec(2))
                sendTrigger(125) % 125 = HAPPY stimulus trigger
                disp('Trigger received')
            end
        end
        
        if useEyeLink
            % EyeLink:  face on
            startStimText = ['Trial ' num2str(thisTrial) ' face stim on'];
            Eyelink('message', startStimText);
        end
        
        if vars.pptrigger
            sendTrigger(0) % remember to manually pull down triggers
        end

        % While loop to show stimulus until StimT seconds elapsed.
        while (GetSecs - StimOn) <= vars.StimT
            
            % Draw face stim
            Screen('FillRect', scr.win, scr.BackgroundGray, scr.winRect);
            if vars.pluxSynch
                Screen('FillRect', scr.win, scr.pluxBlack, scr.pluxRect);
            end
            Screen('DrawTexture', scr.win, ImTex);
            
            % Draw plux trigger -- STIM
            if vars.pluxSynch
                % if were in the first pluxDurationSec seconds, draw the rectangle
                % Angry
                if thisTrialStim == 0     &&((GetSecs - StimOn) <= scr.pluxDurSec(2)) 
                    Screen('FillRect', scr.win, scr.pluxWhite, scr.pluxRect);
                % Happy
                elseif thisTrialStim == 1 &&((GetSecs - StimOn) <= scr.pluxDurSec(2))
                    Screen('FillRect', scr.win, scr.pluxWhite, scr.pluxRect);
                end
            end

            % Flip screen
            Screen('Flip', scr.win);
            
            % KbCheck for Esc key
            if keys.KeyCode(keys.Escape)==1
                % Save, mark the run
                vars.RunSuccessfull = 0;
                vars.Aborted = 1;
                experimentEnd(keys, Results, scr, vars);
                return
            end
            
            [~, ~, keys.KeyCode] = KbCheck;
            WaitSecs(0.001);
            
        end
        
        if vars.pluxSynch
            Screen('FillRect', scr.win, scr.pluxBlack, scr.pluxRect);
        end
        send_propix_trigger(vars.propixtrigger, vars.triggers.CloseTrigger)
        [~, ~] = Screen('Flip', scr.win);            % clear screen
        
        if vars.pptrigger
            sendTrigger(123) % 123 = face stim off trigger
            disp('Trigger received')
        end

        if useEyeLink
            % EyeLink:  face off
            startStimText = ['Trial ' num2str(thisTrial) ' face stim off'];
            Eyelink('message', startStimText);
        end
        
        if vars.pptrigger
            sendTrigger(0) % remember to manually pull down triggers
        end
        
        %% ISI
        Screen('FillRect', scr.win, scr.BackgroundGray, scr.winRect);
        if vars.pluxSynch
            Screen('FillRect', scr.win, scr.pluxBlack, scr.pluxRect);
        end
        if vars.fixCrossFlag
            scr = drawFixation(scr);
        end

        send_propix_trigger(vars.propixtrigger, vars.triggers.fixOnset)
        [~, StartITI3] = Screen('Flip', scr.win);
        
        Results.SOT_ISI3(thisTrial) = StartITI3 - Results.SessionStartT;

        if vars.pptrigger
            sendTrigger(13) % 13 = ISI jitter start trigger
            disp('Trigger received')
        end

        if useEyeLink
            % EyeLink:  ITI
            startStimText = ['Trial ' num2str(thisTrial) ' 3rd jitter start'];
            Eyelink('message', startStimText);
        end
        
        if vars.pptrigger
            sendTrigger(0) % remember to manually pull down triggers
        end

        % Present the gray screen for ITI duration
        while (GetSecs - StartITI3) <= vars.ISI(thisTrial)
            
            if keys.KeyCode(keys.Escape)==1
                % Save, mark the run
                vars.RunSuccessfull = 0;
                vars.Aborted = 1;
                experimentEnd(keys, Results, scr, vars);
                return
            end
        end
        send_propix_trigger(vars.propixtrigger, vars.triggers.CloseTrigger)
        
        [~, ~, keys.KeyCode] = KbCheck;
        WaitSecs(0.001);
        
        %% Confidence rating
        if vars.ConfRating
            
            if useEyeLink
                % EyeLink:  conf rating
                startStimText = ['Trial ' num2str(thisTrial) ' confidence screen on'];
                Eyelink('message', startStimText);
            end
            
            % Fetch the participant's confidence rating
           
            [vars] = getConfidence(keys, scr, vars);
            Results.SOT_ConfResp(thisTrial) = vars.ConfRatingT - Results.SessionStartT;
            Results.SOT_ConfOn(thisTrial) = vars.ConfOnset - Results.SessionStartT;
            Results.SOT_ConfOff(thisTrial) = vars.ConfOffset - Results.SessionStartT;
            
            if vars.abortFlag       % Esc was pressed
                Results.ConfResp(thisTrial) = 9;
                % Save, mark the run
                vars.RunSuccessfull = 0;
                vars.Aborted = 1;
                experimentEnd(keys, Results, scr, vars);
                return
            end
            
            % If no confidence response was made, nag the participant
            if vars.ValidTrial(2) == 0
                displayTooSlowMessage(scr)
            end
            
            % Write trial result to file
            Results.ConfResp(thisTrial) = vars.ConfResp;
            Results.ConfRT(thisTrial) = vars.ConfRatingRT;
            
            % Was this a successfull trial? (both emotion and confidence rating valid)
            % 1-success, 0-fail
            Results.trialSuccess(thisTrial) = logical(sum(vars.ValidTrial) == 2);
            
        else % no Confidence rating
            
            % Was this a successfull trial? (emotion rating valid)
            % 1-success, 0-fail
            Results.trialSuccess(thisTrial) = logical(sum(vars.ValidTrial) == 1);
            
        end
        
        %% Update Results
        thisBlock = vars.trialByTrialBlockVector(thisTrial);
        Results.trialN(thisTrial) = thisTrial;
        Results.StimFile(thisTrial) = StimFileName;
        Results.SubID(thisTrial) = vars.subNo;
        Results.Condition(thisTrial) = vars.conditionSequence(thisTrial);
        Results.Indiv(thisTrial) = StimFileName(1);
        Results.MorphLevel(thisTrial) = str2double(StimFileName(3:5));
        Results.Cue(thisTrial) = vars.cueSequence(thisTrial);
        Results.CueProbDesired(thisTrial) = vars.desiredBlockProbabilities(thisBlock);
        Results.CueProbEffective(thisTrial) = vars.effectiveBlockProbabilities(thisBlock);
        
        %% ITI / prepare for next trial
        Screen('FillRect', scr.win, scr.BackgroundGray, scr.winRect);

        if vars.fixCrossFlag
            scr = drawFixation(scr);end
        send_propix_trigger(vars.propixtrigger, vars.triggers.trialEnd)
        
        [~, ~] = Screen('Flip', scr.win);
        
        
        Results.SOT_ITI(thisTrial) = GetSecs - Results.SessionStartT;

        if vars.pptrigger
            sendTrigger(80) % 80 = ITI start trigger
            disp('Trigger received')
        end

        if useEyeLink
            % EyeLink:  ITI
            startStimText = ['Trial ' num2str(thisTrial) ' ITI start'];
            Eyelink('message', startStimText);
        end
        
        if vars.pptrigger
            sendTrigger(0) % remember to manually pull down triggers
        end

        % Present the fixation for ITI duration
        while (GetSecs - StartITI) <= vars.ITI(thisTrial)
            
        [~, ~, keys.KeyCode] = KbCheck;
        WaitSecs(0.001);

            if keys.KeyCode(keys.Escape)==1
                % Save, mark the run
                vars.RunSuccessfull = 0;
                vars.Aborted = 1;
                experimentEnd(keys, Results, scr, vars);
                return
            end

        
        end
        
        
        % Clean up
        Screen('Close', ImTex);
        Results.TrialDuration(thisTrial) = GetSecs - Results.SOT_trial(thisTrial);
        vars.Resp = NaN;            % reset H A resp
        
        if vars.pptrigger
            sendTrigger(180) % 180 = end of trial trigger
            disp('Trigger received')
        end
        
        if useEyeLink
            % EyeLink:  trial end
            startStimText = ['Trial ' num2str(thisTrial) ' end'];
            Eyelink('message', startStimText);
        end
        
        if vars.pptrigger
            sendTrigger(0) % remember to manually pull down triggers
        end

        send_propix_trigger(vars.propixtrigger, vars.triggers.CloseTrigger)
        [~, ~] = Screen('Flip', scr.win, when, dontclear);
        %% Finish cleaning up after the trial
         % If the trial was missed, repeat it or go on...
        if vars.RepeatMissedTrials
            % if this was a valid trial, advance one. Else, repeat it.
            if vars.ValidTrial(1)            % face affect rating
                thisTrial = thisTrial + 1;
            else
                disp('Invalid response. Repeating trial.');
                % Repeat the trial...
            end
        else
            % Advance one trial (always in MR)
            thisTrial = thisTrial + 1;
        end
        
        % Reset Texture, ValidTrial, Resp
        vars.ValidTrial = zeros(1,2);
        vars.Resp = NaN;
        thisTrialCorrect = NaN;
        vars.ConfResp = NaN;
        PTcorrect = NaN;
        

  
        %% Should we have a break here?
        if (thisTrial == vars.breaks(1)) || (thisTrial == vars.breaks(2))
            % Gray screen - Take a short break
            Screen('FillRect', scr.win, scr.BackgroundGray, scr.winRect);
            if vars.pluxSynch
                Screen('FillRect', scr.win, scr.pluxBlack, scr.pluxRect);
            end
            DrawFormattedText(scr.win, vars.InstructionPause, 'center', 'center', scr.TextColour);
            
            send_propix_trigger(vars.propixtrigger, vars.triggers.BreakOnset)
            [~, breakStartsNow] = Screen('Flip', scr.win);

             send_propix_trigger(vars.propixtrigger, vars.triggers.CloseTrigger)
            if vars.pptrigger
                sendTrigger(200) % 200 = start of break trigger
                disp('Trigger received')

                sendTrigger(0) % remember to manually pull down triggers
            end
            
            % wait for vars.breakT seconds
            while (GetSecs - breakStartsNow) <= vars.breakT
                % Draw time remaining on the screen
                breakRemaining = vars.breakT - (GetSecs - breakStartsNow);
                breakRemainingString = [num2str(round(breakRemaining)), ' seconds'];
                Screen('FillRect', scr.win, scr.BackgroundGray, scr.winRect);
                if vars.pluxSynch
                    Screen('FillRect', scr.win, scr.pluxBlack, scr.pluxRect);
                end
                DrawFormattedText(scr.win, vars.InstructionPause, 'center', 'center', scr.TextColour);
                DrawFormattedText(scr.win, breakRemainingString, 'center', ((scr.winRect(4)/2)+200), scr.TextColour);
                [~, ~] = Screen('Flip', scr.win);
                WaitSecs(1);
                
            end
            
            % Get ready to continue...
            Screen('FillRect', scr.win, scr.BackgroundGray, scr.winRect);
            if vars.pluxSynch
                Screen('FillRect', scr.win, scr.pluxBlack, scr.pluxRect);
            end
            DrawFormattedText(scr.win, ['You can now continue. Press BUTTON 3...'], 'center', 'center', scr.TextColour);
            [~, ~] = Screen('Flip', scr.win);

            if vars.pptrigger
                sendTrigger(201) % 201 = end of break trigger
                disp('Trigger received')

                sendTrigger(0) % remember to manually pull down triggers
            end
            
            % Wait for space
            [~, ~, keys.KeyCode] = KbCheck;
            while keys.KeyCode(keys.Space) == 0
                [~, ~, keys.KeyCode] = KbCheck;
                WaitSecs(0.001);
            end
            
            if vars.pptrigger
                sendTrigger(202) % 202 = end of break button press trigger
                disp('Trigger received')

                sendTrigger(0) % remember to manually pull down triggers
            end
            
            WaitSecs(1);
            
        end
        
    end
 
    
    vars.RunSuccessfull = 1;
    Results.SessionEndT = GetSecs - Results.SessionStartT;
    
    % Save, mark the run
    experimentEnd(keys, Results, scr, vars);

    
    %% EyeLink: experiment end
    if useEyeLink
        addpath("C:\Users\stimuser.stimpc-08\Desktop\Ashley\CWT_behavioural\tasks\03_CWT\code\helpers");
        ELshutdown(vars)
    end
    
    Datapixx('close'); % close propixx connection

    % Cleanup at end of experiment - Close window, show mouse cursor, close
    % result file, switch back to priority 0
    %     sca;
    %     rmpath(genpath('code'));
    ShowCursor;
    %     fclose('all');
    %     Priority(0);
    
    
catch ME% Error. Clean up...
    
    % Save, mark the run
    rethrow(ME)
    vars.RunSuccessfull = 0;
    vars.Error = 1;
    experimentEnd(keys, Results, scr, vars);
%     rethrow(ME)
end
