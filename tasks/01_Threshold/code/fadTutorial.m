function fadTutorial(scr, keys, vars)
%fadTutorial(scr, keys, vars)
%
% Runs a tutorial for FAD task
%
%   Input:
%       scr       screen parameters structure
%       keys      key names structure
%       vars      general vars (set by loadParams.m)
%
% Niia Nikolova 25/06/2021



% 1. Instruction: You will complete two tasks.. 1. Faces, 2. Learning task

% 2. Face discrimination, show stimulus example

% 3. FFace discrimination, 3 example trials, normal speed

global language
vars.language = language;

%% Set variables & instructions
nTrialsFAD = 5;        % Number of tutorial trials to run for FAD
nTrialsFAD = nTrialsFAD+1;
tutorialStims = [180, 20, 85, 118, 100, 10, 191, 105];
tutorialGenders = round(rand(1, nTrialsFAD));

% Instructions
if vars.language == 1       % English
    
    instr.A     = 'In this experiment, you will complete three tasks. \n \n \n \n 1st - Face discrimination task, duration 5 minutes \n \n 2nd - Localizer Task, duration 5 minutes \n \n 3rd - Learning task, duration 45 minutes. \n \n \n \n Before the 1st and 3rd tasks you will complete a short tutorial. \n \n Please tell the experimenter if you have any questions after the tutorials. \n \n  You will use the BUTTON BOX to respond. \n \n \n \n Press BUTTON 3 to continue.';
    instr.B     = '--- 1. Face discrimination task --- \n \n \n \n On each trial, you will see a face on the screen. \n \n \n \n \n \n \n \n \n \n \n \n \n \n \n Your task is to decide whether this face is either \n \n angry/in a bad mood (BUTTON 1) or happy/in a good mood (BUTTON 4). \n \n You will have 2 seconds to respond. \n \n \n \n Let''s try it now. \n \n \n Press BUTTON 3 to see an example trial.';
    instr.C     = 'Next, you will do a few practice trials. \n \n It may sometimes be difficult to decide whether the face is angry or happy. \n \n In these cases, please take your best guess and respond. \n \n There are no right or wrong answers; we are interested in learning how you perceive faces.\n \n \n \n Press BUTTON 3 to continue to the practice trials.';
    instr.D     = 'You have completed the tutorial and will now go on to the main experiment. This will take about 5 minutes. \n \n \n \n Press BUTTON 3 to continue.';
    instr.E     = 'Get ready…';
    
    instr.feedbackC = 'Correct!';
    instr.feedbackI = 'Incorrect!';
    instr.feedbackSlow = 'You did not make a response.';
    
elseif vars.language == 2       % Danish
    
    instr.A     = 'I dette eksperiment skal du gennemføre tre opgaver. \n \n \n \n Først - Ansigtsdiskrimineringsopgave, varighed 5 minutter \n \n Dernæst - Lokaliseringsopgave, varighed 5 minutter \n \n Sidst - Læringsopgave, varighed 45 minutter. \n \n \n \n Før hver opgave vil du gennemføre en kort prøverunde. \n \n Fortæl venligst den forsøgsansvarlige hvis du har nogen spørgsmål efter prøverunderne. \n \n Du skal bruge MUSEN til at svarere. \n \n \n \n Tryk på MELLEMRUMSTASTEN for at fortsætte.';
    instr.B     = '--- 1. Ansigstdiskrimineringsopgave --- \n \n \n \n I hver runde vil du se et ansigt på skærmen. \n \n \n \n \n \n \n \n \n \n \n \n \n \n \n Din opgave er at beslutte om ansigtet er vredt/i dårligt humør (VENSTRE piletast) eller glad/i godt humør (HØJRE piletast). \n \n Du har 2 sekunder til at svare. \n \n \n \n Lad os prøve det nu. \n \n \n Tryk på MELLEMRUMSTASTEN for at se en prøverunde.';
    instr.C     = 'Nu vil du gennemføre et par prøverunder. \n \n Nogle gange vil det muligvis være svært at beslutte om ansigtet er \n \n vredt/i dårligt humør eller glad/i godt humør. \n \n I disse tilfælde bedes du svare med dit bedste bud. \n \n Der er ikke noget rigtigt eller forkert; vi er interesserede i at lære hvordan du oplever ansigter.\n \n \n \n Tryk på MELLEMRUMSTASTEN for at fortsætte til øvelsesrunden.';
    instr.D     = 'Du har gennemført øvelsesrunden og vil nu fortsætte til selve eksperimentet. Dette vil tage omkring 5 minutter. \n \n \n \n Tryk på MELLEMRUMSTASTEN for at fortsætte.';
    instr.E     = 'Gør dig klar…';
    
    instr.feedbackC = 'Korrekt!';
    instr.feedbackI = 'Ikke korrekt!';
    instr.feedbackSlow = 'Du svarede ikke.';

end

global tutorialAbort

try
    
    pause(0.200);
    [~, ~, keys.KeyCode] = KbCheck;
    
    %% General task instructions
    showInstruction(scr, keys, instr.A);
    
    
    %% 1. Trial Instruction + single trial
    thisTrialStim       = 180;
    Screen('FillRect', scr.win, scr.BackgroundGray, scr.winRect);
    if vars.pluxSynch
        Screen('FillRect', scr.win, scr.pluxBlack, scr.pluxRect);
    end
    DrawFormattedText(scr.win, instr.B, 'center', 'center', scr.TextColour);
    thisTrialFileName = ['M_', sprintf('%03d', thisTrialStim), '.tif'];
    % Display a face image
    StimFilePath = strcat(vars.StimFolder, thisTrialFileName);
    ImDataOrig = imread(char(StimFilePath));
    ImData = imresize(ImDataOrig, [(vars.StimSizePix/2)  NaN]);           % Adjust image size to StimSize dva in Y dir
    ImTex = Screen('MakeTexture', scr.win, ImData);
    Screen('DrawTexture', scr.win, ImTex);
    Screen('Flip', scr.win);
    
    % Wait for space
    while keys.KeyCode(keys.Space) == 0
        [~, ~, keys.KeyCode] = KbCheck;
        WaitSecs(0.001);
        if keys.KeyCode(keys.Escape)==1
            % set tutorialAbort to 1
            tutorialAbort = 1;
            return
        end
    end
    [~, ~, keys.KeyCode] = KbCheck;
    WaitSecs(0.001);
    
    % Show a blank screen for 200ms for flow
    Screen('FillRect', scr.win, scr.BackgroundGray, scr.winRect);
    if vars.pluxSynch
        Screen('FillRect', scr.win, scr.pluxBlack, scr.pluxRect);
    end
    [~, ~] = Screen('Flip', scr.win);
    pause(0.2);
    
    [~, ~, keys.KeyCode] = KbCheck;
    WaitSecs(0.001);
  
    for thisTrial = 1 : (nTrialsFAD)
        
        if thisTrial == 2
            showInstruction(scr, keys, instr.C);
        end
        
        
        %% Example trials
        % Which gender face to present on this trial?
        switch tutorialGenders(thisTrial)
            case 0
                thisTrialGender = 'F_';
            case 1
                thisTrialGender = 'M_';
        end
        
        thisTrialStim = tutorialStims(thisTrial);
        
        thisTrialFileName = [thisTrialGender, sprintf('%03d', thisTrialStim), '.tif'];
        disp(['Trial # ', num2str(thisTrial), '. Stim: ', thisTrialFileName]);
        
        % Read stim image for this trial into matrix 'imdata'
        StimFilePath = strcat(vars.StimFolder, thisTrialFileName);
        ImDataOrig = imread(char(StimFilePath));
        ImData = imresize(ImDataOrig, [vars.StimSizePix NaN]);           % Adjust image size to StimSize dva in Y dir
        
        % Make texture image out of image matrix 'imdata'
        ImTex = Screen('MakeTexture', scr.win, ImData);
        
        % Draw texture image to backbuffer
        Screen('DrawTexture', scr.win, ImTex);
        if vars.pluxSynch
            Screen('FillRect', scr.win, scr.pluxBlack, scr.pluxRect);
        end
        [~, StimOn] = Screen('Flip', scr.win);
        
        % While loop to show stimulus until StimT seconds elapsed.
        while (GetSecs - StimOn) <= vars.StimT
            
            Screen('FillRect', scr.win, scr.BackgroundGray, scr.winRect);
            if vars.pluxSynch
                Screen('FillRect', scr.win, scr.pluxBlack, scr.pluxRect);
            end
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
                % set tutorialAbort to 1
                tutorialAbort = 1;
                return
            end
            [~, ~, keys.KeyCode] = KbCheck;
            WaitSecs(0.001);
        end
        
        if vars.pluxSynch
            Screen('FillRect', scr.win, scr.pluxBlack, scr.pluxRect);
        end
        [~, ~] = Screen('Flip', scr.win);            % clear screen
        
        
        % Show emotion prompt screen
        % Angry (L arrow) or Happy (R arrow)?
        Screen('FillRect', scr.win, scr.BackgroundGray, scr.winRect);
        if vars.pluxSynch
            Screen('FillRect', scr.win, scr.pluxBlack, scr.pluxRect);       % Ashley white rect for display of choice
        end
        DrawFormattedText(scr.win, [vars.InstructionQ], 'center', 'center', scr.TextColour);
        [~, vars.StartRT] = Screen('Flip', scr.win);
        
        % Fetch the participant's response, via keyboard or mouse
        [vars] = getResponse(keys, scr, vars);
        
        % ITI / prepare for next trial
        Screen('FillRect', scr.win, scr.BackgroundGray, scr.winRect);
        if vars.pluxSynch
            Screen('FillRect', scr.win, scr.pluxBlack, scr.pluxRect);
        end
        [~, StartITI] = Screen('Flip', scr.win);
        
        % Present the gray screen for ITI duration
        while (GetSecs - StartITI) <= vars.ITI(thisTrial)
            
            if keys.KeyCode(keys.Escape)==1
                % set tutorialAbort to 1
                tutorialAbort = 1;
                return
            end
            [~, ~, keys.KeyCode] = KbCheck;
            WaitSecs(0.001);
        end
        
        [~, ~, keys.KeyCode] = KbCheck;
        WaitSecs(0.001);
        
        Screen('Close', ImTex);
        
        
    end
    
    %% Tutorial complete screen
    showInstruction(scr, keys, instr.D);
    
catch ME
    rethrow(ME)
    
    
end

end
