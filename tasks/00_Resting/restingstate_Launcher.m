function restingstate_Launcher(scr, subNo, visitNo)

global tutorialAbort
tutorialAbort = 0;

vars.useEyeLink  = 1; 

%% Setup
if nargin == 1
    vars.subNo = input('What is the subject number (e.g. 0001)?   ');
    vars.visitNo = input('What is the visit number (e.g. 0001)?   ');
    
elseif nargin < 1
    addpath(genpath('helpers'));
    vars.subNo = input('What is the subject number (e.g. 0001)?   ');
    vars.visitNo = input('What is the visit number (e.g. 0001)?   ');
    
    %% Set screen parameters and open a window
    scr.ViewDist = 56;
    [scr] = displayConfig(scr);
    AssertOpenGL;
    [scr.win, scr.winRect] = PsychImaging('OpenWindow', scr.screenID, scr.BackgroundGray); %,[0 0 1920 1080] mr screen dim
    PsychColorCorrection('SetEncodingGamma', scr.win, 1/scr.GammaGuess);
    
    % Set text size, dependent on screen resolution
    if any(logical(scr.winRect(:)>3000))       % 4K resolution
        scr.TextSize = 65;
    else
        scr.TextSize = 35;
    end
    Screen('TextSize', scr.win, scr.TextSize);
    
    % Set priority for script execution to realtime priority:
    scr.priorityLevel = MaxPriority(scr.win);
    Priority(scr.priorityLevel);
    
    % Determine stim size in pixels
    scr.dist = scr.ViewDist;
    scr.width  = scr.MonitorWidth;
    scr.resolution = scr.winRect(3:4);                    % number of pixels of display in horizontal direction
else
    addpath(genpath('helpers'));
    vars.subNo = subNo;
    vars.visitNo = visitNo;
end

vars.subIDstring = sprintf('%04d', vars.subNo);
vars.visitNostr  = sprintf('%04d', vars.visitNo);

scr.TextColour = [192 192 192];
restingscan_time = 300;

% Keyboard & keys configuration
[keys] = keyConfig();

try
    %% Open screen window, if one is not already open
    if ~exist('scr','var')
        if ~isfield(scr, 'win')
            % % Skip internal synch checks, suppress warnings
            % oldLevel = Screen('Preference', 'Verbosity', 0);
            % Screen('Preference', 'SkipSyncTests', 1);
            % Screen('Preference','VisualDebugLevel', 0);
            
            % Diplay configuration
            scr.ViewDist = 56;
            [scr] = displayConfig(scr);
            HideCursor;
            AssertOpenGL;
            [scr.win, scr.winRect] = PsychImaging('OpenWindow', scr.screenID, scr.BackgroundGray); %,[0 0 1920 1080] mr screen dim
            
            % Determine screen params
            scr.dist = scr.ViewDist;
            scr.width  = scr.MonitorWidth;
            scr.resolution = scr.winRect(3:4);
            
            % Set text size, dependent on screen resolution
            if any(logical(scr.winRect(:)>3000))       % 4K resolution
                scr.TextSize = 65;
            else
                scr.TextSize = 28;
            end
            Screen('TextSize', scr.win, scr.TextSize);
        end
    end
    

    if vars.useEyeLink
        vars.exptName = 'RestCWT';
        
        % check for eyelink data dir
        if ~exist('./data/eyelink', 'dir')
            mkdir('./data/eyelink')
        end
        
        [vars] = ELsetup(scr, vars);
    end
    
    % Determine stim size in pixels
    scr.bkColor = scr.BackgroundGray;
    HideCursor;

    WaitSecs(0.2);

    Screen('FillRect', scr.win, scr.BackgroundGray, scr.winRect);
    scr = drawFixation(scr);
    [~, rest_startT] = Screen('Flip', scr.win);

    %% Show init screen
    Screen('FillRect', scr.win, scr.BackgroundGray, scr.winRect);
    DrawFormattedText(scr.win, 'The resting scan will begin soon. \n \n \n \n Please keep your gaze on the fixation point.', 'center', 'center', scr.TextColour);
    [~, ~] = Screen('Flip', scr.win);
    new_line;
    disp('Waiting for experimenter to press SPACE.'); new_line;
    [~, ~, keys.KeyCode] = KbCheck;
    
    % Wait for trigger
    while keys.KeyCode(keys.Space) == 0
        [~, ~, keys.KeyCode] = KbCheck;
        WaitSecs(0.001);
    end
    
    if vars.useEyeLink
        Eyelink('message','STARTEXP');
    end


    isConnected = Datapixx('isReady');
    if ~isConnected
        Datapixx('Open');
    end


    send_propix_trigger(vars.propixtrigger, vars.triggers.TaskStart+60)
    [~, ~] = Screen('Flip', scr.win, 0, 1);
    send_propix_trigger(vars.propixtrigger, vars.triggers.CloseTrigger)
    [~, ~] = Screen('Flip', scr.win, 0, 1);
    %% Show fixation screen - 5 min
    while (GetSecs - rest_startT) <= restingscan_time
        Screen('FillRect', scr.win, scr.BackgroundGray, scr.winRect);
        scr = drawFixation(scr);
        [~, ~] = Screen('Flip', scr.win);

        [~, ~, keys.KeyCode] = KbCheck;
        if keys.KeyCode(keys.Escape)==1
            % Exit task
            return
        end

        if tutorialAbort == 1
            return
        end
    end

    send_propix_trigger(vars.propixtrigger, vars.triggers.TaskEnd+60)
    [~, ~] = Screen('Flip', scr.win, 0, 1);
    send_propix_trigger(vars.propixtrigger, vars.triggers.CloseTrigger)
    [~, ~] = Screen('Flip', scr.win, 0, 1);


     %% Show end screen
%     feedbackText = ['End of session. Close your eyes and relax while we set up the next scan...'];
    feedbackText = ['End of resting scan. The Tasks will begin soon...'];
    feedbackTextExperimenter = ['End of session'];
    disp(feedbackTextExperimenter);

    WaitSecs(3);
    Screen('FillRect', scr.win, scr.BackgroundGray, scr.winRect);
    DrawFormattedText(scr.win, feedbackText, 'center', 'center', scr.TextColour);
    [~, ~] = Screen('Flip', scr.win);
    WaitSecs(3);
    
     %% EyeLink: experiment end
    if vars.useEyeLink
        ELshutdown(vars)
    end
    
    %% Clean up
    
    rmpath(genpath('helpers'));
    
catch ME
    
    %% EyeLink: experiment end
%     if vars.useEyeLink
%         ELshutdown(vars)
%     end
    
    rmpath(genpath('helpers'));
    rethrow(ME)
end


end