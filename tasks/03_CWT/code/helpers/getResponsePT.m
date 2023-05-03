function [vars] = getResponsePT(keys, scr, vars)
%function [vars] = getResponsePT(keys, scr, vars)
%
% Get the participants response for prediction trial - either keyboard or mouse
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
% Last edit: 21/07/2020

feedbackString = 'O';
if vars.pptrigger
    sendTrigger = intialiseParallelPort();
end
% loop until valid key is pressed or RespT is reached
while ((GetSecs - vars.PTOn) <= vars.PTRespT)     
    
    switch vars.InputDevice
        
        case 2 % Keyboard response

            [~,~,keys.KeyCode] = KbCheck;
            while (~any(keys.KeyCode)) && ((GetSecs - vars.PTOn) <= vars.PTRespT) % wait for press & response time
                [~,~,keys.KeyCode] = KbCheck; % L [1 0 0], R [0 0 1]
            end
            
            % KbCheck for response
            if keys.KeyCode(keys.Left)==1         % Angry
                % update results
                vars.Resp = 0;
                vars.ValidTrial(1) = 1;

                if vars.pptrigger
                    sendTrigger(160) % 160 = ANGRY prediction trigger
                    disp('Trigger received')
                end
                
            elseif keys.KeyCode(keys.Right)==1    % Happy
                % update results
                vars.Resp = 1;
                vars.ValidTrial(1) = 1;

                if vars.pptrigger
                    sendTrigger(165) % 165 = HAPPY prediction trigger
                    disp('Trigger received')
                end
                
            elseif keys.KeyCode(keys.Escape)==1
                vars.abortFlag = 1;
                
            else
                % ? DrawText: Please press a valid key...
            end
            
            [~, vars.PTEndResp, keys.KeyCode] = KbCheck;
            WaitSecs(0.001);

            if vars.pptrigger
                sendTrigger(0) % remember to manually pull down triggers
            end
            
            
        case 1 % Mouse
            
            [~,~,buttons] = GetMouse;
            while (~any(buttons)) && ((GetSecs - vars.PTOn) <= vars.PTRespT) % wait for press & response time
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
            vars.PTEndResp = GetSecs;
    end
    
    %% Brief feedback
    if vars.Resp == 1% happy
        emotString = 'Happy';
%         feedbackXPos = ((scr.winRect(3)/2)+ 270); 
        feedbackXPos = ((3*(scr.winRect(3))/5)); 
    elseif vars.Resp == 0
        emotString = 'Angry';
        feedbackXPos = ((scr.winRect(3)/2));
    else
        emotString = '';
        feedbackXPos = ((scr.winRect(3)/2));
        vars.PTEndResp = vars.PTOn + 2;
    end
    
    % fixed timing - wait for response interval to pass
    if vars.fixedTiming
        if ~isnan(vars.Resp) && (vars.ValidTrial(1))    % valid trial
            % Draw texture image to backbuffer
            Screen('FillRect', scr.win, scr.BackgroundGray, scr.winRect);
            Screen('FillRect', scr.win, scr.pluxBlack, scr.pluxRect);
            DrawFormattedText(scr.win, [vars.PTTitle], 'center', ((scr.winRect(4)/2)-6*(scr.winRect(4)/8)), scr.TextColour);
            DrawFormattedText(scr.win, [vars.PTQuestion], 'center', ((scr.winRect(4)/2)-(scr.winRect(4)/4)), scr.TextColour);
%             DrawFormattedText(scr.win, [vars.PTQuestion], 'center', ((scr.winRect(4)/2)-(scr.winRect(4)/4)), scr.TextColour);
            DrawFormattedText(scr.win, feedbackString, feedbackXPos, ((scr.winRect(4)/2)-(scr.winRect(4)/4)+120), scr.AccentColour);
            [~, ~] = Screen('Flip', scr.win);
            
            outputString = ['Prediction: ', emotString];
        else
            outputString = 'No prediction response recorded';
        end
        
    else    % Variable timing
        if ~isnan(vars.Resp) && (vars.ValidTrial(1))
            % Draw texture image to backbuffer
            Screen('FillRect', scr.win, scr.BackgroundGray, scr.winRect);
            Screen('FillRect', scr.win, scr.pluxBlack, scr.pluxRect);
            DrawFormattedText(scr.win, [vars.PTTitle], 'center', ((scr.winRect(4)/2)-6*(scr.winRect(4)/8)), scr.TextColour);
            DrawFormattedText(scr.win, [vars.PTQuestion], 'center', ((scr.winRect(4)/2)-(scr.winRect(4)/4)), scr.TextColour);
%             DrawFormattedText(scr.win, [vars.PTQuestion], 'center', ((scr.winRect(4)/2)-(scr.winRect(4)/4)), scr.TextColour);
            DrawFormattedText(scr.win, feedbackString, feedbackXPos, ((scr.winRect(4)/2)-(scr.winRect(4)/4)+120), scr.AccentColour);
            [~, ~] = Screen('Flip', scr.win);
            WaitSecs(0.2);
            
            outputString = ['Prediction: ', emotString];
        else
            outputString = 'No prediction response recorded';
        end
        
        WaitSecs(0.2);
        break;
    end
    
    
end

if exist('outputString', 'var')
    disp(outputString);
end

end
