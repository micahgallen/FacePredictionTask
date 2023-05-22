function [vars] = getConfidence(keys, scr, vars)
%function [vars] = getConfidence(keys, scr, vars)
%
% Get the participants confidence response - either keyboard or mouse
%
% Project: CWT task, for fMRI.
%
% Input:
%   keys (struct)
%   scr (struct)
%   vars (struct)
%
%
% Output:
%   vars (struct)
%
% Niia Nikolova
% Edited by Ashley Tyrer
% Last edit: 02/05/2023


%% setup variables
when = 0;  % Flip on the next possible video retrace
dontclear = 1;  % Do not clear the framebuffer after flip
validkeypress = 0; % set indicator to zero

%% draw screen


Screen('FillRect', scr.win, scr.BackgroundGray, scr.winRect);

DrawFormattedText(scr.win, [vars.InstructionConf], 'center', 'center', scr.TextColour);

send_propix_trigger(vars.propixtrigger, vars.triggers.rateIntOnset)

[~, StartConf] = Screen('Flip', scr.win);

send_propix_trigger(vars.propixtrigger, vars.triggers.CloseTrigger)

[~, ~] = Screen('Flip', scr.win, when, dontclear);

vars.ConfOnset = StartConf;

send_propix_trigger(vars.propixtrigger, vars.triggers.rateOnset)

%% loop until valid key is pressed or ConfT is reached
while (GetSecs - StartConf) <= vars.ConfT

    [~,~,keys.KeyCode] = KbCheck;

    send_propix_trigger(vars.propixtrigger, vars.triggers.rateOnset)


    while (~validkeypress) && ((GetSecs - StartConf) <= vars.ConfT) % wait for press & response time

        [~,EndConf,keys.KeyCode] = KbCheck; 

        if keys.KeyCode(keys.One)==1 || keys.KeyCode(keys.Two)==1 || keys.KeyCode(keys.Three)==1 || keys.KeyCode(keys.Four)==1

            [~, ~] = Screen('Flip', scr.win, when, dontclear);
            validkeypress = 1;
            WaitSecs(0.001);

        
        else
            WaitSecs(0.001);
            validkeypress = 0;

        end

    end

    % clear the response trigger
    send_propix_trigger(vars.propixtrigger, vars.triggers.CloseTrigger)
    

    %% Read Keycodes for logging
    if keys.KeyCode(keys.One)==1
        % update results
        vars.ConfResp = 1;
        vars.ValidTrial(2) = 1;
    elseif keys.KeyCode(keys.Two)==1
        % update results
        vars.ConfResp = 2;
        vars.ValidTrial(2) = 1;
    elseif keys.KeyCode(keys.Three)==1
        % update results
        vars.ConfResp = 3;
        vars.ValidTrial(2) = 1;
    elseif keys.KeyCode(keys.Four)==1
        % update results
        vars.ConfResp = 4;
        vars.ValidTrial(2) = 1;
    elseif keys.KeyCode(keys.Escape)==1
        vars.abortFlag = 1;

    else
        % DrawText: Please press a valid key...
   
    end



    if ~vars.fixedTiming
        % Stop waiting when a rating is made
        if(vars.ValidTrial(2)), WaitSecs(0.2); break; end
    end

    % Compute response time
    vars.ConfRatingT = (EndConf - StartConf);

end

% show brief feedback
if ~isnan(vars.ConfResp)
    switch vars.ConfResp
        case 1
            feedbackXPos = ((scr.winRect(3)/2)-450);  % Position for 'Guessing'
        case 2
            feedbackXPos = ((scr.winRect(3)/2)-150);  % Position for 'Unsure'
        case 3
            feedbackXPos = ((scr.winRect(3)/2)+150);  % Position for 'Confident'
        case 4
            feedbackXPos = ((scr.winRect(3)/2)+450);  % Position for 'Certain'
    end

    feedbackString = 'O';
    Screen('FillRect', scr.win, scr.BackgroundGray, scr.winRect);
    DrawFormattedText(scr.win, [vars.InstructionConf], 'center', 'center', scr.TextColour);
    DrawFormattedText(scr.win, feedbackString, feedbackXPos, ((scr.winRect(4)/2)+200), scr.AccentColour);
    [~, ~] = Screen('Flip', scr.win);
    %WaitSecs(0.5);

    disp(['Confidence recorded: ', num2str(vars.ConfResp)]);

else
    disp('No confidence recorded.');
end

