function experimentEnd(vars, scr, keys, Results, stair)
%function experimentEnd(vars, scr, keys, Results, stair)
%
% Project: Face Affect Discrimination (FAD) Task, part of CWT
%
% End of experiment routine. Shows a message to let the user know if the
% run has been aborted or crashed, saves results, and cleans up

%
% Niia Nikolova
% Last edit: 20/07/2020

if vars.pptrigger
    sendTrigger = intialiseParallelPort();
end

if isfield(vars,'Aborted') || isfield(vars,'Error')
    if vars.Aborted
        % Abort screen
        Screen('FillRect', scr.win, scr.BackgroundGray, scr.winRect);
        DrawFormattedText(scr.win, 'Run aborted...', 'center', 'center', scr.TextColour);
        [~, ~] = Screen('Flip', scr.win);
        if vars.pptrigger
            sendTrigger(250) % 250 = end of experiment trigger
            disp('Trigger received')

            sendTrigger(0) % remember to manually pull down triggers
        end
        WaitSecs(3);
        ShowCursor;
%         sca;
        disp('Experiment aborted by user!');
        
        % Save, mark the run
        vars.DataFileName = ['Aborted_', vars.DataFileName];
        save(strcat(vars.OutputFolder, vars.DataFileName), 'stair', 'Results', 'vars', 'scr', 'keys' );
        disp(['Run was aborted. Results were saved as: ', vars.DataFileName]);
        
        % and as .csv
        Results.stair = stair;                  % Add staircase params to Results struct for the .csv
        csvName = strcat(vars.OutputFolder, vars.DataFileName, '.csv');
        struct2csv(Results, csvName);
        
    elseif vars.Error
        
        % Abort screen
        Screen('FillRect', scr.win, scr.BackgroundGray, scr.winRect);
        DrawFormattedText(scr.win, 'Run error...', 'center', 'center', scr.TextColour);
        [~, ~] = Screen('Flip', scr.win);
        if vars.pptrigger
            sendTrigger(250) % 250 = end of experiment trigger
            disp('Trigger received')

            sendTrigger(0) % remember to manually pull down triggers
        end
        WaitSecs(3);
        ShowCursor;
%         sca;
        disp(' ** Error!! ***')
        disp(['Run crashed. Results were saved as: ', vars.DataFileName]);
        
        % Error
        vars.DataFileName = ['Error_',vars.DataFileName];
        save(strcat(vars.OutputFolder, vars.DataFileName), 'stair', 'Results', 'vars', 'scr', 'keys' );
        % and as .csv
        Results.stair = stair;                      % Add staircase structure to Results to save
        csvName = strcat(vars.OutputFolder, vars.DataFileName, '.csv');
        struct2csv(Results, csvName);
        
        % Output the error message that describes the error:
        psychrethrow(psychlasterror);
    end
end

if vars.RunSuccessfull      % Successfull run
    % Show end screen and clean up
    Screen('FillRect', scr.win, scr.BackgroundGray, scr.winRect);
    DrawFormattedText(scr.win, vars.InstructionEnd, 'center', 'center', scr.TextColour);
    [~, ~] = Screen('Flip', scr.win);
    if vars.pptrigger
        sendTrigger(250) % 250 = end of experiment trigger
        disp('Trigger received')

        sendTrigger(0) % remember to manually pull down triggers
    end
    WaitSecs(3);
    ShowCursor;
%     sca;
    
    % Save the data
    save(strcat(vars.OutputFolder, vars.DataFileName), 'stair', 'Results', 'vars', 'scr', 'keys' );
    disp(['Run complete. Results were saved as: ', vars.DataFileName]);
    % also save to 1_VMPaux
%     copy2VMPaux(subID)
    
    % and as .csv
    Results.stair = stair;                      % Add staircase structure to Results to save
    csvName = strcat(vars.OutputFolder, vars.DataFileName, '.csv');
    struct2csv(Results, csvName);                                       %<----- N.B. PsiAdaptive: DOES NOT SAVE .csv due to PF objects in Results struct#####
    
end


% fclose('all');
% Priority(0);