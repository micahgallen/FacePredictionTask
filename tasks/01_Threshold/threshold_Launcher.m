function threshold_Launcher(scr, subNo, visitNo)
%function threshold_Launcher(scr, subNo, visitNo)
%
% Project: Face Affect Discrimination (FAD) Task, part of CWT - MRI task
% branch
%
% Input:    subNo      4-digit subject ID number
%           scr        screen params
%
% Versions:
%       FAD_v1-1    Pilot 1. MCS procedure, stimuli faces of 4 individuals from KDEF
%       FAD_v1-2    Pilot 2. Adaptive (psi), stimuli two averaged faces (M & F),
%                   each based on 9 KDEF individuals, OR N-down staircase (4 interleaved stairs)
%       FAD_v1-3    Pilot 3. MRI task, Adaptive (psi), stimuli two averaged faces (M & F)
%       FAD_v1-4    Pilot 4. MRI task, Adaptive (psi), collapsed accross face gender (M & F)
%       FAD_v1-5    FAD task for thresholding for CWT task, for MRI, single
%       staircase, removed N-down and MCS switches
%
% ======================================================
%
% -------------- PRESS ESC TO EXIT ---------------------
%
% ======================================================
%
% Niia Nikolova
% Last edit: 19/07/2020


%% Initial settings
% Close existing workspace
% close all; clc;


devFlag = 0;                % optional flag. Set to 1 when developing the task
vars.exptName = 'Threshold';


%% Do system checks

% % Check that PTB is installed
% PTBv = PsychtoolboxVersion;
% if isempty(PTBv)
%     disp('Please install Psychtoolbox 3. Download and installation can be found here: http://psychtoolbox.org/download');
%     return
% end

% % Skip internal synch checks, suppress warnings
% oldLevel = Screen('Preference', 'Verbosity', 0);
% Screen('Preference', 'SkipSyncTests', 1);
% Screen('Preference','VisualDebugLevel', 0);


% % check working directory & change if necessary
% vars.workingDir = fullfile('FADtask_2_Psi_MR');                      % <--- EDIT here as needed ####
% currentFolder = pwd;
% correctFolder = contains(currentFolder, vars.workingDir);
% if ~correctFolder                   % if we're not in the correct working directory, prompt to change
%     disp(['Incorrect working directory. Please start from ', vars.workingDir]); return;
% end
%
% % check for data dir
% if ~exist('data', 'dir')
%     mkdir('data')
% end

% setup path
addpath(genpath('code'));

%% Ask for subID, age, gender, and display details
if ~devFlag % if we're testing
    
    if nargin == 1
        vars.subNo = input('What is the subject number (e.g. 0001)?   ');
        vars.visitNo = input('What is the visit number (e.g. 0001)?   ');

    elseif nargin < 1
        vars.subNo = input('What is the subject number (e.g. 0001)?   ');
        vars.visitNo = input('What is the visit number (e.g. 0001)?   ');
        
        %% Open a PTB window
        % Skip internal synch checks, suppress warnings
        oldLevel = Screen('Preference', 'Verbosity', 0);
        Screen('Preference', 'SkipSyncTests', 1);
        Screen('Preference','VisualDebugLevel', 0);

        scr.ViewDist = 56;
        [scr] = displayConfig(scr);
        AssertOpenGL;
        [scr.win, scr.winRect] = PsychImaging('OpenWindow', scr.screenID, scr.BackgroundGray); %,[0 0 1920 1080] mr screen dim
        PsychColorCorrection('SetEncodingGamma', scr.win, 1/scr.GammaGuess);
        
        % Set text size, dependent on screen resolution
        if any(logical(scr.winRect(:)>3000))       % 4K resolution
            scr.TextSize = 65;
        else
            scr.TextSize = 28;
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
        vars.subNo = subNo;
        vars.visitNo = visitNo;
    end
    
    scr.ViewDist = 56;
    HideCursor;
else
    scr.ViewDist = 40;
end

if ~isfield(vars,'subNo') || isempty(vars.subNo)
    vars.subNo = 9999;                                               % test
end

global tutorialAbort

%% Output
vars.subIDstring = sprintf('%04d', vars.subNo);
vars.visitNostr  = sprintf('%04d', vars.visitNo);
vars.OutputFolder = fullfile('..', '..', 'data', ['sub_',vars.subIDstring], ['visit_', vars.visitNostr], filesep);
vars.DataFileName = strcat(vars.exptName, '_',vars.subIDstring, '_visit', vars.visitNostr, '_');    % name of data file to write to

% Check if folder already exists in data dir
if ~exist(vars.OutputFolder, 'dir') 
    mkdir(vars.OutputFolder)
end


%% Start experiment
main(vars, scr);
% If Esc was pressed, abort
if tutorialAbort == 1
    rmpath(genpath('code'));
    return
end

% Restore path
rmpath(genpath('code'));
