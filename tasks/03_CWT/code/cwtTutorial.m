function cwtTutorial(scr, keys, vars)
%cwtTutorial(scr, keys, vars)
%
% Runs a tutorial for CWT task
%
%   Input:
%       scr       screen parameters structure
%       keys      key names structure
%       vars      general vars (set by loadParams.m)
%
% Niia Nikolova 25/06/2021


% 1. CWT instructions

% 2. CWT example trial, no confidence

% 3. CWT example trial, confidence

% 4. Learning task explanation

% 5. Prediction trial explanation

% 6. CWT, some example trials

global language
vars.language = language;

%% Set variables & instructions
nTrialsCWT      = 10;        % Number of tutorial trials to run for FAD
nTrialsCWT      = nTrialsCWT + 2;   % Add two for intro trials
tutorialCues    = round(rand(1,nTrialsCWT));
tutorialStims   = round(rand(1,nTrialsCWT)*200);%[20, 180, 85, 128, 95, 10, 110, 35, 05, 170];
tutorialGenders = round(rand(1,nTrialsCWT));

% Instructions
if vars.language == 1       % English
    instr.A     = '--- 2. Learning task --- \n \n \n \n On each trial, you will first see a picture of either an elephant or a bicycle (a cue). \n \n Then you will see a face, and you should decide if this face is rather angry or happy (by pressing the LEFT / RIGHT mouse buttons, just as in the Face Discrimination task). \n \n \n \n Press SPACE to see an example trial.';
    instr.B     = 'After each trial, you will rate how confident you felt in your choice by clicking on a slider scale.  You will have 3 seconds to respond. \n \n Let''s try a trial with a confidence rating. \n \n \n \n Press SPACE to continue.';
    instr.C     = 'Great! In addition to this, there is a learning component to the task. There is a relationship between the cues and the faces in such a way that a given cue predicts the emotion of the face that will follow it. \n \n \n \n Press SPACE to continue. ';
    instr.D     = 'For example, the elephant cue might start out predicting an angry face, while the bicycle predicts a happy face. Crucially, these predictive associations will change over the course of the session. So the elephant may eventually go on to predict happy faces, then again angry, and so on. Note that although the cues predict face emotions with some certainty, this is not 100%. This means that there may be some trials that do not ‘go with’ the current relationship. \n \n \n \n Press SPACE to practice a few more trials.';
    instr.E     = 'We would like you to try to learn what the associations are at any given time. In order to see how you learn the associations, there are some trials which ask you to indicate which face emotion a given cue is currently predicting. For example, ‘Is the [elephant] predicting Angry (L) or Happy (R) faces?’. On these trials, please use the left and right response buttons to answer what you think the association is. \n \n \n \n Press SPACE to see a prediction trial. ';
    instr.F     = 'Now you will do a few practice trials. \n \n \n \n Press SPACE to continue.';
    instr.G     = 'You have completed the tutorial and will now go on to the main experiment. This will take about 40 minutes. \n \n \n \n You will have several opportunities to take breaks. \n \n \n \n Press SPACE to continue.';
    instr.H     = 'Get ready…';
    
    instr.feedbackA = 'Response: Angry';
    instr.feedbackH = 'Response: Happy';
    instr.feedbackS = 'Too slow!';
    
elseif vars.language == 2       % Danish
    
    instr.A     = '--- 2. Læringsopgave  --- \n \n \n \n I hver runde, vil du først se et billede af enten en elefant eller en cykel (et symbol). \n \n Så vil du se et ansigt, og du skal så beslutte om dette ansigt er relativt vredt eller relativt glad (ved at trykke på den VENSTRE / HØJRE mussetast, ligesom i Ansigstdiskrimineringsopgaven). \n \n \n \n Tryk på MELLEMRUMSTASTEN for at se et eksempel runde.';
    instr.B     = 'Efter hver runde skal du angive hvor sikker du er på dit valg ved at trykke på en glidende skala. Du har 3 sekunder til at svare. \n \n Lad os prøve en runde hvor du angiver din sikkerhed. \n \n \n \n Tryk på MELLEMRUMSTASTEN for at fortsætte.';
    instr.C     = 'Godt! Ud over dette er der en læringskomponent i denne opgave. Der er et forhold mellem symbolet og ansigterne. Symbolet forudsiger det efterfølgende ansigts følelse. \n \n \n \n Tryk på MELLEMRUMSTASTEN for at fortsætte. ';
    instr.D     = 'F.eks, elefant symbolet starter måske ud med at forudsige et vredt ansigt, mens cyklen forudsiger et glad ansigt. Det er vigtigt at vide at disse forudsigende associationer vil ændre sig igennem denne opgave. Så elefanten kommer måske til at forudse glade ansigter og så igen vrede, og så videre. Bemærk at selvom symboler forudser ansigternes følelser med nogen sikkerhed, så er det ikke 100%. Dette betyder at der vil være nogle runder som ikke ‘passer med’ det nuværende forhold. \n \n \n \n Tryk på MELLEMRUMSTASTEN for at øve nogle få runder.';
    instr.E     = 'Vi vil gerne have at du prøver at lærer associationerne på et givent tidspunkt. For at se om du lærer associationerne vil der være nogle runder hvor du vil blive spurgt om at indikere hvilken ansigtsfølelse et givent symbol på nuværende tidspunkt forudsiger. F.eks, ‘Forudsiger [elefant] Vrede (V) eller Glade (H) ansigter?’. I disse runder, bedes du venligst bruge den venstre og højre svar knapper til at svare hvad du tror associationen er. s. \n \n \n \n Tryk på MELLEMRUMSTASTEN for at se en forudsigende runde. ';
    instr.F     = 'Du vil nu gennemføre nogle få øve runder. \n \n \n \n Tryk på MELLEMRUMSTASTEN for at fortsætte.';
    instr.G     = 'Du har nu gennemført øvelsen og vil nu fortsætte til hoveddelen af eksperimentet. Dette tager omkring 40 min.. \n \n \n \n Du vil have flere muligheder for at tage pauser. \n \n \n \n Tryk på MELLEMRUMSTASTEN for at fortsætte.';
    instr.H     = 'Gør dig klar…';
    
    instr.feedbackA = 'Svar: Vred';
    instr.feedbackH = 'Svar: Glad';
    instr.feedbackS = 'For langsomt!';

end

global tutorialAbort

try
    
    pause(0.200);
    [~, ~, keys.KeyCode] = KbCheck;
    
    
    clear thisTrial
    
    %% 1. Example trials
    for thisTrial = 1 : (nTrialsCWT) % add two for introducing response & confidence
        
        if thisTrial == 1
            % General task instruction, example trial & response
            showInstruction(scr, keys, instr.A);
            
        elseif thisTrial == 2
            % Trial with confidence rating
            showInstruction(scr, keys, instr.B);
            
        elseif thisTrial == 3
            % Learning component
            showInstruction(scr, keys, instr.C);
            showInstruction(scr, keys, instr.D);
        end
        
        %% Present cue
        thisCue = tutorialCues(thisTrial);
        thisTrialCue = ['cue_', num2str(thisCue), '.tif'];
        disp(['Trial # ', num2str(thisTrial), '. Cue: ', thisTrialCue]);
        
        % Read stim image for this trial into matrix 'imdata'
        CueFilePath = strcat(vars.StimFolder, thisTrialCue);
        ImDataOrig = imread(char(CueFilePath));
        ImData = imresize(ImDataOrig, [vars.StimSizePix NaN]);
        ImTex = Screen('MakeTexture', scr.win, ImData);
        
        % Draw texture image to backbuffer
        Screen('FillRect', scr.win, scr.BackgroundGray, scr.winRect);
        Screen('DrawTexture', scr.win, ImTex);
        [~, CueOn] = Screen('Flip', scr.win);
        
        % While loop to show stimulus until CueT seconds elapsed.
        while (GetSecs - CueOn) <= vars.CueT
            
            % Draw the cue screen
            Screen('FillRect', scr.win, scr.BackgroundGray, scr.winRect);
            Screen('DrawTexture', scr.win, ImTex);
            
            % Draw plux trigger -- CUE
            if vars.pluxSynch
                % if were in the first pluxDurationSec seconds, draw the rectangle
                if thisCue == 0     &&((GetSecs - CueOn) <= scr.pluxDurSec(1))
                    Screen('FillRect', scr.win, scr.pluxWhite, scr.pluxRect);
                elseif thisCue == 1 &&((GetSecs - CueOn) <= scr.pluxDurSec(1))
                    Screen('FillRect', scr.win, scr.pluxBlack, scr.pluxRect);
                end
            end
            
            % Flip screen
            Screen('Flip', scr.win);
            
            if keys.KeyCode(keys.Escape)==1
                % set tutorialAbort to 1
                tutorialAbort = 1;
                return
            end
            [~, ~, keys.KeyCode] = KbCheck;
            WaitSecs(0.001);
            
        end%cueT
        
        [~, ~] = Screen('Flip', scr.win);            % clear screen
        Screen('Close', ImTex);                      % Close the image texture
        
        %% ISI
        Screen('FillRect', scr.win, scr.BackgroundGray, scr.winRect);
        if vars.fixCrossFlag
            scr = drawFixation(scr);end
        [~, StartITI] = Screen('Flip', scr.win);
        
        % Present the gray screen for ITI duration
        while (GetSecs - StartITI) <= vars.ISI(thisTrial)
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
        
        
        %% Present face stimulus
        % Is the face F or M?
        if tutorialGenders(thisTrial)     % 1 female
            thisFaceGender = 'F_';
        else                                % 0 male
            thisFaceGender = 'M_';
        end
        
        thisFacestim = tutorialStims(thisTrial);
        if thisFacestim < 100
            thisTrialStim = 0;      % Angry
        else
            thisTrialStim = 1;      % Happy
        end
        thisTrialFileName = [thisFaceGender, sprintf('%03d', thisFacestim), '.tif'];
        
        % Read stim image for this trial into matrix 'imdata'
        StimFilePath = strcat(vars.StimFolder, thisTrialFileName);
        ImDataOrig = imread(char(StimFilePath));
        ImData = imresize(ImDataOrig, [vars.StimSizePix NaN]);
        ImTex = Screen('MakeTexture', scr.win, ImData);
        
        % Draw texture image to backbuffer
        Screen('FillRect', scr.win, scr.BackgroundGray, scr.winRect);
        Screen('DrawTexture', scr.win, ImTex);
        [~, StimOn] = Screen('Flip', scr.win);
        
        % While loop to show stimulus until StimT seconds elapsed.
        while (GetSecs - StimOn) <= vars.StimT
            
            % Draw face stim
            Screen('FillRect', scr.win, scr.BackgroundGray, scr.winRect);
            Screen('DrawTexture', scr.win, ImTex);
            
            % Draw plux trigger -- STIM
            if vars.pluxSynch
                % if were in the first pluxDurationSec seconds, draw the rectangle
                % Angry
                if thisTrialStim == 0     &&((GetSecs - StimOn) <= scr.pluxDurSec(2))
                    Screen('FillRect', scr.win, scr.pluxBlack, scr.pluxRect);
                    % Happy
                elseif thisTrialStim == 1 &&((GetSecs - StimOn) <= scr.pluxDurSec(2))
                    Screen('FillRect', scr.win, scr.pluxWhite, scr.pluxRect);
                end
            end
            % Flip screen
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
        [~, ~] = Screen('Flip', scr.win);            % clear screen
        
        
        %% Show emotion prompt screen
        % Angry (L arrow) or Happy (R arrow)?
        Screen('FillRect', scr.win, scr.BackgroundGray, scr.winRect);
        DrawFormattedText(scr.win, [vars.InstructionQ], 'center', 'center', scr.TextColour);
        [~, vars.StartRT] = Screen('Flip', scr.win);
        
        % Fetch the participant's response, via keyboard or mouse
        [vars] = getResponse(keys, scr, vars);
        
        if vars.abortFlag               % Esc was pressed
            % set tutorialAbort to 1
            tutorialAbort = 1;
            return
        end
        
        % Feedback
        if thisTrial <= 4
            if vars.Resp==1     % response happy
                Screen('FillRect', scr.win, scr.BackgroundGray, scr.winRect);
                DrawFormattedText(scr.win, [instr.feedbackH], 'center', 'center', scr.TextColour);
            elseif vars.Resp==0 % response angry
                Screen('FillRect', scr.win, scr.BackgroundGray, scr.winRect);
                DrawFormattedText(scr.win, [instr.feedbackA], 'center', 'center', scr.TextColour);
            else                % resp = NaN
                Screen('FillRect', scr.win, scr.BackgroundGray, scr.winRect);
                DrawFormattedText(scr.win, [instr.feedbackS], 'center', 'center', scr.TextColour);
            end
        end
        
        [~, ~] = Screen('Flip', scr.win);
        WaitSecs(1)
        
        
        %% Confidence rating
        if vars.ConfRating
            
            if thisTrial >= 2
                
                % Fetch the participant's confidence rating
                [vars] = getConfidence(keys, scr, vars);
                if vars.abortFlag       % Esc was pressed
                    % set tutorialAbort to 1
                    tutorialAbort = 1;
                    return
                end
                
                WaitSecs(0.2);
                
            end
        end
        
        %% ITI / prepare for next trial
        Screen('FillRect', scr.win, scr.BackgroundGray, scr.winRect);
        if vars.fixCrossFlag
            scr = drawFixation(scr);end
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
        
        % Clean up
        Screen('Close', ImTex);
        vars.Resp = NaN;            % reset H A resp
        
    end
    
    %% Introduce prediction trial
    showInstruction(scr, keys, instr.E);
     
    Screen('FillRect', scr.win, scr.BackgroundGray, scr.winRect);
    DrawFormattedText(scr.win, [vars.PTTitle], 'center', ((scr.winRect(4)/2)-6*(scr.winRect(4)/8)), scr.TextColour);
    DrawFormattedText(scr.win, vars.PTQuestion, 'center', ((scr.winRect(4)/2)-(scr.winRect(4)/4)), scr.TextColour);
    [~, ~] = Screen('Flip', scr.win);
    WaitSecs(0.2);
    
    % Present cue + prediciton trial text
    thisCue = tutorialCues(1);
    thisTrialCue = ['cue_', num2str(thisCue), '.tif'];
    new_line;

    % Read stim image for this trial into matrix 'imdata'
    CueFilePath = strcat(vars.StimFolder, thisTrialCue);
    ImDataOrig = imread(char(CueFilePath));
    ImData = imresize(ImDataOrig, [vars.StimSizePix NaN]);           % Adjust image size to StimSize dva in Y dir
    ImTex = Screen('MakeTexture', scr.win, ImData);
    
    % Draw texture image to backbuffer
    Screen('FillRect', scr.win, scr.BackgroundGray, scr.winRect);
    Screen('DrawTexture', scr.win, ImTex);
    DrawFormattedText(scr.win, [vars.PTTitle], 'center', ((scr.winRect(4)/2)-6*(scr.winRect(4)/8)), scr.TextColour);
    DrawFormattedText(scr.win, [vars.PTQuestion], 'center', ((scr.winRect(4)/2)-(scr.winRect(4)/4)), scr.TextColour);
    [~, vars.PTOn] = Screen('Flip', scr.win);
    
    % Fetch the participant's response, via keyboard or mouse
    [vars] = getResponsePT(keys, scr, vars);
    
    % Show a fixation for the remainder of the 3sec
    while (GetSecs - vars.PTOn) <= (vars.PTTotT) %3sec total
        
        Screen('FillRect', scr.win, scr.BackgroundGray, scr.winRect);
        if vars.fixCrossFlag
            scr = drawFixation(scr);end
        Screen('Flip', scr.win);
        
        if keys.KeyCode(keys.Escape)==1
            % set tutorialAbort to 1
            tutorialAbort = 1;
            return
        end
        [~, ~, keys.KeyCode] = KbCheck;
        WaitSecs(0.001);
        
    end
    Screen('Close', ImTex);
    
    
    
    %% Tutoial complete..
     showInstruction(scr, keys, instr.G);
    
catch ME
    rethrow(ME)
    
    
end

end
