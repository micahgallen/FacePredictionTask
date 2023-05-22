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

categorical_slider = vars.cat_slide;
when = 0;  % Flip on the next possible video retrace
dontclear = 1;  % Do not clear the framebuffer after flip

switch vars.InputDevice

    case 2 % Keyboard response

        % Rate confidence: 1 Unsure, 2 Sure, 3 Very sure

        Screen('FillRect', scr.win, scr.BackgroundGray, scr.winRect);
        if vars.pluxSynch
            Screen('FillRect', scr.win, scr.pluxBlack, scr.pluxRect);
        end
        DrawFormattedText(scr.win, [vars.InstructionConf], 'center', 'center', scr.TextColour);

        send_propix_trigger(vars.propixtrigger, vars.triggers.rateIntOnset)

        [~, StartConf] = Screen('Flip', scr.win);

        send_propix_trigger(vars.propixtrigger, vars.triggers.CloseTrigger)

        [~, ~] = Screen('Flip', scr.win, when, dontclear);

        vars.ConfOnset = StartConf;

        send_propix_trigger(vars.propixtrigger, vars.triggers.rateOnset)

        % loop until valid key is pressed or ConfT is reached
        while (GetSecs - StartConf) <= vars.ConfT

            [~,~,keys.KeyCode] = KbCheck;

            send_propix_trigger(vars.propixtrigger, vars.triggers.rateOnset)

            while (~any(keys.KeyCode)) && ((GetSecs - StartConf) <= vars.ConfT) % wait for press & response time

                [~,EndConf,keys.KeyCode] = KbCheck; % L [1 0 0], R [0 0 1]

                if ~any(keys.KeyCode)

                    [~, ~] = Screen('Flip', scr.win, when, dontclear);
                    send_propix_trigger(vars.propixtrigger, vars.triggers.CloseTrigger)
                else
                    WaitSecs(0.001);
                end

            end

            % send trigger for keypress



            % KbCheck for response
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
                    feedbackXPos = ((scr.winRect(3)/2)-350);
                case 2
                    feedbackXPos = ((scr.winRect(3)/2));
                case 3
                    feedbackXPos = ((scr.winRect(3)/2)+350);
            end

            feedbackString = 'O';
            Screen('FillRect', scr.win, scr.BackgroundGray, scr.winRect);
            if vars.pluxSynch
                Screen('FillRect', scr.win, scr.pluxBlack, scr.pluxRect);
            end
            DrawFormattedText(scr.win, [vars.InstructionConf], 'center', 'center', scr.TextColour);
            DrawFormattedText(scr.win, feedbackString, feedbackXPos, ((scr.winRect(4)/2)+200), scr.AccentColour);
            [~, ~] = Screen('Flip', scr.win);
            WaitSecs(0.5);

            disp(['Confidence recorded: ', num2str(vars.ConfResp)]);

        else
            disp('No confidence recorded.');
        end

    case 1 % Mouse response
        answer = 0;                 % reset response flag

        vars.ConfOnset = GetSecs;
        % We set a time-out for conf rating, b/c otherwise it's Inf...
        [position, ConfTimeStamp, RT, answer] = slideScale(keys, scr.win, ...
            vars.InstructionConf, ...
            scr.winRect, ...
            vars.ConfEndPoins, ...
            'scalalength', 0.7,...
            'scalacolor',scr.TextColour,...
            'linelength', 15,...
            'width', 6,...
            'device', 'keyboard', ...
            'stepsize', 10, ...
            'startposition', 'shuffle', ...
            'range', 2, ...
            'aborttime', vars.ConfT, ...
            'categorical_slider', categorical_slider, ...
            'trigger_rect', scr.pluxRect, ...
            'colour_rect', scr.pluxBlack, ...
            'pptrigger', vars.pptrigger);% ... 'displayPos', true, ... 'responseKeys', [KbName('return') KbName('LeftArrow') KbName('RightArrow')], ...

        %             % If we want to allow infinite resp time
        %             [position, ConfTimeStamp, RT, answer] = slideScale(scr.win, ...
        %                 vars.InstructionConf, ...
        %                 scr.winRect, ...
        %                 vars.ConfEndPoins, ...
        %                 'scalalength', 0.7,...
        %                 'linelength', 20,...
        %                 'width', 6,...
        %                 'device', 'mouse', ...
        %                 'stepsize', 10, ...
        %                 'startposition', 'shuffle', ...
        %                 'range', 2);

        vars.ConfOffset = GetSecs;
        % update results
        if answer
            vars.ConfResp = position;
            vars.ValidTrial(2) = 1;
        end
        vars.ConfRatingT = ConfTimeStamp;
        vars.ConfRatingRT = RT;

        % Show rating in command window
        if ~isnan(vars.ConfResp)
            disp(['Confidence recorded: ', num2str(round(vars.ConfResp))]);
        else
            disp('No confidence recorded.');
        end

end