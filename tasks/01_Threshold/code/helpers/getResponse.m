function [vars] = getResponse(keys, scr, vars)
%function [vars] = getResponse(keys, scr, vars)
%
% Get the participants response - either keyboard or mouse
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
%
% Niia Nikolova
% Last edit: 07/07/2020

feedbackString = 'O';
postResponseInt = 0.3;      %  pause for 300ms after response
if vars.pptrigger
    sendTrigger = intialiseParallelPort();
end

% loop until valid key is pressed or RespT is reached
send_propix_trigger(vars.propixtrigger, vars.triggers.respOnset+50)
while ((GetSecs - vars.StartRT) <= vars.RespT)
    
    switch vars.InputDevice
        
        case 1 % Keyboard response

            [~,~,keys.KeyCode] = KbCheck;
            while (~any(keys.KeyCode)) && ((GetSecs - vars.StartRT) <= vars.RespT) % wait for press & response time
                [~,~,keys.KeyCode] = KbCheck; % L [1 0 0], R [0 0 1]
            end

            [~, ~] = Screen('Flip', scr.win, 0, 1);
            send_propix_trigger(vars.propixtrigger, vars.triggers.CloseTrigger)

            % KbCheck for response
            if keys.KeyCode(keys.Left)==1         % Angry
                % update results
                vars.Resp = 0;
                vars.ValidTrial(1) = 1;

                if vars.pptrigger
                    sendTrigger(110) % 110 = ANGRY response trigger
                    disp('Trigger received')
                end

            elseif keys.KeyCode(keys.Right)==1    % Happy
                % update results
                vars.Resp = 1;
                vars.ValidTrial(1) = 1;

                if vars.pptrigger
                    sendTrigger(115) % 115 = HAPPY response trigger
                    disp('Trigger received')
                end
                
            elseif keys.KeyCode(keys.Escape)==1
                vars.abortFlag = 1;
                
            else
                % ? DrawText: Please press a valid key...
            end
            
            if vars.pptrigger
                sendTrigger(0) % remember to manually pull down triggers
            end

            [~, vars.EndRT, keys.KeyCode] = KbCheck;
            WaitSecs(0.001);
            
            
        case 2 % Mouse
            
            [~,~,buttons] = GetMouse;
            while (~any(buttons)) && ((GetSecs - vars.StartRT) <= vars.RespT) % wait for press & response time
                [~,~,buttons] = GetMouse; % L [1 0 0], R [0 0 1]
            end
            
            if buttons == [1 0 0] % Left - angry
                % update results
                vars.Resp = 0;
                vars.ValidTrial(1) = 1;
                
            elseif buttons == [0 0 1] % Right - happy
                % update results
                vars.Resp = 1;
                vars.ValidTrial(1) = 1;
                
            else
                
            end
            vars.EndRT = GetSecs;
    end
    
    %% Brief feedback
    if vars.Resp == 1% happy
        emotString = 'Happy';
        feedbackXPos = ((scr.winRect(3)/2)+150);
    elseif vars.Resp == 0
        emotString = 'Angry';
        feedbackXPos = ((scr.winRect(3)/2)-250);
    else
        emotString = '';
        feedbackXPos = ((scr.winRect(3)/2));
    end
    
    if vars.pluxSynch
        Screen('FillRect', scr.win, scr.pluxBlack, scr.pluxRect);
    end
%     [~, stimOn] = Screen('Flip', scr.win);
    
    % fixed timing - wait for response interval to pass
    if vars.fixedTiming
        if ~isnan(vars.Resp) && (vars.ValidTrial(1))    % valid trial
            while ((GetSecs - vars.StartRT) <= vars.RespT)
                Screen('FillRect', scr.win, scr.BackgroundGray, scr.winRect);
                DrawFormattedText(scr.win, [vars.InstructionQ], 'center', 'center', scr.TextColour);
                DrawFormattedText(scr.win, feedbackString, feedbackXPos, ((scr.winRect(4)/2)+150), scr.AccentColour);
                [~, ~] = Screen('Flip', scr.win);
            end

            outputString = ['Response recorded: ', emotString];
        else
            outputString = 'No response recorded';
        end
        
    else    % Variable timing
        if ~isnan(vars.Resp) && (vars.ValidTrial(1))
            while (GetSecs - stimOn) <= postResponseInt
                
                Screen('FillRect', scr.win, scr.BackgroundGray, scr.winRect);
                if vars.pluxSynch
                    Screen('FillRect', scr.win, scr.pluxBlack, scr.pluxRect);
                end
                DrawFormattedText(scr.win, [vars.InstructionQ], 'center', 'center', scr.TextColour);
                DrawFormattedText(scr.win, feedbackString, feedbackXPos, ((scr.winRect(4)/2)+150), scr.AccentColour);
                
                % Draw plux trigger -- RESP
                if vars.pluxSynch
                    % if were in the first pluxDurationSec seconds, draw the rectangle
                    % Angry
                    if vars.Resp == 0     &&((GetSecs - stimOn) <= scr.pluxDurSec(2))
                        Screen('FillRect', scr.win, scr.pluxWhite, scr.pluxRect);
                        % Happy
                    elseif vars.Resp == 1 &&((GetSecs - stimOn) <= scr.pluxDurSec(2))
                        Screen('FillRect', scr.win, scr.pluxWhite, scr.pluxRect);
                    end
                end
                
                [~, ~] = Screen('Flip', scr.win);
                
            end
%             WaitSecs(0.3);
            
            outputString = ['Response recorded: ', emotString];
        else
            outputString = 'No response recorded';
        end
        
        WaitSecs(0.2);
        break;
    end
    
end

disp(outputString);

end
