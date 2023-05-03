function experimentEnd(keys, Results, scr, vars)
%function experimentEnd(keys, Results, scr, vars)
%
% Project: CWT task
%
% End of experiment routine. Shows a message to let the user know if the
% run has been aborted or crashed, saves results, and cleans up

%
% Niia Nikolova
% Edited by Ashley Tyrer
% Last edit: 03/05/2023

if vars.pptrigger
    sendTrigger = intialiseParallelPort();
end

if isfield(vars,'Aborted') || isfield(vars,'Error')
    if vars.Aborted
        if isfield(scr, 'win')          % if a window is open, display a brief message
            % Abort screen
            Screen('FillRect', scr.win, scr.BackgroundGray, scr.winRect);
            DrawFormattedText(scr.win, 'Experiment aborted. Exiting...', 'center', 'center', scr.TextColour);
            [~, ~] = Screen('Flip', scr.win);

            if vars.pptrigger
                sendTrigger(250) % 250 = end of experiment trigger
                disp('Trigger received')

                sendTrigger(0) % remember to manually pull down triggers
            end

            WaitSecs(3);
        end

        %     ListenChar(0);
        ShowCursor;
        sca;
        disp('Experiment aborted by user!');
        
        % Save, mark the run
        vars.DataFileName = ['Aborted_', vars.DataFileName];
        save(strcat(vars.OutputFolder, vars.DataFileName), 'Results', 'vars', 'scr', 'keys' );
        disp(['Run was aborted. Results were saved as: ', vars.DataFileName]);
        
        % and as .csv
        csvName = strcat(vars.OutputFolder, vars.DataFileName, '.csv');
        struct2csv(Results, csvName);
        
    elseif vars.Error
        if isfield(scr, 'win')          % if a window is open, display a brief message
            % Abort screen
            Screen('FillRect', scr.win, scr.BackgroundGray, scr.winRect);
            DrawFormattedText(scr.win, 'Error. Exiting... ', 'center', 'center', scr.TextColour);
            [~, ~] = Screen('Flip', scr.win);

            if vars.pptrigger
                sendTrigger(250) % 250 = end of experiment trigger
                disp('Trigger received')

                sendTrigger(0) % remember to manually pull down triggers
            end

            WaitSecs(3);
        end
        
        % Error, save file
        vars.DataFileName = ['Error_',vars.DataFileName];
        save(strcat(vars.OutputFolder, vars.DataFileName), 'Results', 'vars', 'scr', 'keys' );
        % and as .csv
        csvName = strcat(vars.OutputFolder, vars.DataFileName, '.csv');
        struct2csv(Results, csvName);
        
        disp(['Run crashed. Results were saved as: ', vars.DataFileName]);
        disp(' ** Error!! ***')
        
        %     ListenChar(0);
        ShowCursor;
        sca;
        
        % Output the error message that describes the error:
        psychrethrow(psychlasterror);
        rethrow(ME)
    end
end

if vars.RunSuccessfull  % Successfull run
    % Show end screen and clean up
    Screen('FillRect', scr.win, scr.BackgroundGray, scr.winRect);
    DrawFormattedText(scr.win, vars.InstructionEnd, 'center', 'center', scr.TextColour);
    [~, ~] = Screen('Flip', scr.win);

    if vars.pptrigger
        sendTrigger(250) % 250 = end of experiment trigger
        disp('Trigger received')

        sendTrigger(0) % remember to manually pull down triggers
    end

    WaitSecs(6);
    sca

    % Save the data
    save(strcat(vars.OutputFolder, vars.DataFileName), 'Results', 'vars', 'scr', 'keys' );
    disp(['Run complete. Results were saved as: ', vars.DataFileName]);
    
    % and as .csv
    csvName = strcat(vars.OutputFolder, vars.DataFileName, '.csv');
    struct2csv(Results, csvName);                                       %<----- PsiAdaptive: NOT SAVING .csv due to PF objects in Results struct#####
    
end

rmpath(genpath('code'));
% ListenChar(0);          % turn on keypresses -> command window
% sca;
ShowCursor;
% fclose('all');
% Priority(0);