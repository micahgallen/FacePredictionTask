function CWTwrapper(whichPart)
% function CWTwrapper(whichPart)
%
% Project: CWT task behavioural, for VMP 2.0 (summer/Fall 2021)
%
% Input: whichPart  optional argument to only run one of the CWT component tasks
%       1   Thresholding
%       2   CWT (content)
%
% Sets paths, and calls functions
%
% Niia Nikolova
% Last edit: 22/06/2021

%% CWT tasks wrapper

% Close existing workspace
close all; clc;

%% Get participant information
participant.subNo       = input('What is the subject number (e.g. 0001)?   ');
participant.subIDstring = sprintf('%04d', participant.subNo);
% participant.subAge      = input('What is the participants year of birth (e.g. 1988)?   ');
% participant.subGender   = input('What is the participants gender (f or m)?   ', 's');
global language
language                = input('Preferred language? (1 English, 2 Danish)   :');
% participant.chinrest    = input('Is a chinrest used? (1 yes, 0 no)   :');
participant.visitNo     = input('What number visit is this? (1, 2, or 3)   :');
participant.visitNostr  = sprintf('%04d', participant.visitNo);

participant.location    = 1;
% Location codes:
% 1     7T testing booth, Left
% 2     7T testing booth, Right
% 3     7T testing booth, Large
% 4     J115, window
% 5     J115, Right



%% Set up paths
addpath(genpath('data'));
addpath(genpath('stimuli'));
savepath;

participant.MetaDataFileName = strcat(participant.subIDstring, '_visit', participant.visitNostr, '_metaData'); 
participant.partsCompleted = zeros(1,3);

%% Do a few preliminary checks

% Check if folder already exists in data dir
dataDirectory = fullfile('.', 'data', ['sub_',participant.subIDstring], ['visit_', participant.visitNostr]);
if ~exist(dataDirectory, 'dir') && (participant.subNo ~= 9999)
    mkdir(dataDirectory)
else
    
    % Check which (if any) tasks the participant has already completed
    expectedDataFiles = {['Threshold_',participant.subIDstring,'_visit',participant.visitNostr]; ['LocalizerCWT_',participant.subIDstring,'_visit',participant.visitNostr]; ['CWT_v1-3_',participant.subIDstring,'_visit',participant.visitNostr]};
    for taskFiles = 1:3
        
        foundFiles = dir(strcat(dataDirectory, filesep, expectedDataFiles{taskFiles}, '*.mat'));
        
        if size(foundFiles,1) ~= 0
            if isempty(foundFiles.name)
                % No file exists for this task
            else
                % File already exists in Outputdir
                if participant.subNo ~= 9999
                    participant.partsCompleted(taskFiles) = 1;
                end
            end
        end
    end
end



% Check that PTB is installed
PTBv = PsychtoolboxVersion;
if isempty(PTBv)
    disp('Please install Psychtoolbox 3. Download and installation can be found here: http://psychtoolbox.org/download');
    return
end

% Skip internal synch checks, suppress warnings
oldLevel = Screen('Preference', 'Verbosity', 0);
Screen('Preference', 'SkipSyncTests', 1);
Screen('Preference','VisualDebugLevel', 0);

%% Open a PTB window
scr.ViewDist = 56;
[scr] = displayConfig(scr);
AssertOpenGL;
[scr.win, scr.winRect] = PsychImaging('OpenWindow', scr.screenID, scr.BackgroundGray); %,[0 0 1920 1080] mr screen dim
%[scr.win, scr.winRect] = PsychImaging('OpenWindow', scr.screenID, scr.BackgroundGray,[0 0 1000 800]);

% Set text size, dependent on screen resolution
if any(logical(scr.winRect(:)>3000))       % 4K resolution
    scr.TextSize = 65;
else
    scr.TextSize = 28;
end
Screen('TextSize', scr.win, scr.TextSize);
Screen('Textfont', scr.win, '-:lang=da'); 

% Set priority for script execution to realtime priority:
scr.priorityLevel = MaxPriority(scr.win);
Priority(scr.priorityLevel);

% Determine stim size in pixels
scr.dist        = scr.ViewDist;
scr.width       = scr.MonitorWidth;
scr.resolution  = scr.winRect(3:4);                    % number of pixels of display in horizontal direction

global tutorialAbort
tutorialAbort = 0;

cd(fullfile('.', 'tasks', '00_Resting'))
restingstate_Launcher(scr);
if tutorialAbort == 1
    disp('-------------- Experiment aborted. ----------------')
    sca
    return
end
cd(fullfile('..', '..'))

%% 01 Run thresholding task
if ((nargin < 1) || (whichPart==1)) && (participant.partsCompleted(1) == 0)
    % Run the task
    cd(fullfile('.', 'tasks', '01_Threshold'))
    threshold_Launcher(scr, participant.subNo, participant.visitNo);
    % If Esc was pressed, abort
    if tutorialAbort == 1
        disp('-------------- Experiment aborted. ----------------')
        sca
        return
    end
    participant.partsCompleted(1) = 1;
    cd(fullfile('..', '..'))
    % Save metadata
    save(fullfile(dataDirectory, ['sub_', participant.MetaDataFileName]), 'participant');
    disp('FAD complete');
else
    disp('Threshold file found for this subject. Continuing to Localizer...');

end

%% 02 Run localizer
if ((nargin < 1) || (whichPart==2)) && (participant.partsCompleted(2) == 0)
    % Run the task
    cd(fullfile('.', 'tasks', '02_Localizer'))
    localizer_Launcher(scr, participant.subNo, participant.visitNo);
    participant.partsCompleted(2) = 1;
    cd(fullfile('..', '..'));
    % Save metadata
    save(fullfile(dataDirectory, ['sub_', participant.MetaDataFileName]), 'participant');
else
    disp('Localizer file found for this subject. Continuing to CWT...');
end

% goOn2 = input('Localizer task completed. Continue to CWT? 1-yes, 0-no ');
% if ~goOn2
%     return
% end

%% 03 Run CWT
if ((nargin < 1) || (whichPart==3)) && (participant.partsCompleted(3) == 0)
    % Run the task
    cd(fullfile('.', 'tasks', '03_CWT'))
    CWT_Launcher(scr, participant.subNo, participant.visitNo);
    % If Esc was pressed, abort
    if tutorialAbort == 1
        disp('-------------- Experiment aborted. ----------------')
        sca
        return
    end
    % if vars.RunSuccessfull
    participant.partsCompleted(3) = 1;
    cd(fullfile('..', '..'))
    % Save metadata
    save(fullfile(dataDirectory, ['sub_', participant.MetaDataFileName]), 'participant');
end



%% Finish up
% Copy data files to NA_aux
copy2NAaux(participant.subNo, participant.visitNo);

% Remove global vars from workspace
clear global language
clear global tutorialAbort

rmpath(genpath('data'))

% Close screen etc
sca;
ShowCursor;
fclose('all');
Priority(0);
ListenChar(0);          % turn on keypresses -> command window
Screen('Preference', 'Verbosity', oldLevel);

