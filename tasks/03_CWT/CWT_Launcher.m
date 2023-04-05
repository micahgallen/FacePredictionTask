function CWT_Launcher(scr, subNo, visitNo)
%function CWT_Launcher(scr, subNo, visitNo)
%
% Project: CWT task, for fMRI
%
% Input: subNo      4-digit subject ID number
%
% Sets paths, and calls main.m
%
% Previous versions:
%       CWT_v1-1    Pilot 1. 
%       CWT_v1-2    Pilot 2. July 10, 2020. 210 trials total, 2 long & 4
%       short blocks. Timing best guess optimized for HRF efficiency, using
%       a long ISI (2-3s),  self-pacing, and a short ITI (1-2s)
%       CWT_v1-3    Pilot 3 Debugged prob block sequence 
%
% ======================================================
%
% -------------- PRESS ESC TO EXIT ---------------------
%
% ======================================================
%
% Niia Nikolova
% Last edit: 21/07/2020


%% Initial settings
% Close existing workspace
% close all; clc;

devFlag = 0;                    % Development flag. Set to 1 when developing the task, will optimize stim size for laptop, not hide cursor

vars.exptName = 'CWT_behav';

%% setup path
addpath(genpath('code'));


%% Ask for subID, age, gender, and display details
if ~devFlag         % Experiment
    
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
    
else                % Development
    % Open PTB window in small rect, for debugging
    vars.windowMode = input('Do you want to open a small window? Enter 1 for yes, 0 for no. ');                
    if isempty(vars.windowMode)
        vars.windowMode = 1;
    end
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
% vars.CBFolder = fullfile('..', '..', 'data', ['sub_',vars.subIDstring], filesep);
% cbal = Counterbalance_img(vars.CBFolder);
load(strcat(vars.OutputFolder, 'visit_cbal'), 'cbal');
disp(strcat('Launcher, cbal = ', num2str(cbal)))
cbal_str = num2str(cbal);
vars.DataFileName = strcat(vars.exptName, '_',vars.subIDstring, '_visit', vars.visitNostr, '_cbal', cbal_str, '_');    % name of data file to write to

% Check if folder already exists in data dir
if ~exist(vars.OutputFolder, 'dir')
    mkdir(vars.OutputFolder)
else
%     disp('A folder already exists for this subject ID. Please enter a different ID.')
%     return
end

 %% Start experiment
% Run the experiment
% main(vars, scr);
main_Ashley_scanner(vars, scr, cbal);
% If Esc was pressed, abort
if tutorialAbort == 1
    rmpath(genpath('code'));
    return
end

