%% Define parameters
%
% Project: Face Affect Discrimination (FAD) Task, part of CWT
%
% Sets key parameters, called by main.m
%
% Single Psi staircase. Data are collapsed accross M&F
% average faces, and gender on each trial is randomized
%
% Niia Nikolova
% Last edit: 16/07/2020

global language
vars.language = language;

%% Key flags
vars.ConfRating     = 0;                % Confidence rating? (1 yes, 0 no)
vars.InputDevice    = 1;                % Response method for conf rating. 1 - keyboard 2 - mouse
useEyeLink          = 1;
vars.RepeatMissedTrials = 0;            % Do we want to repeat any missed trials? 1 yes, 0 no
plotStaircase       = 0;
vars.pluxSynch      = 0;
vars.runFADtutorial = 0;
vars.pptrigger      = 0;
% vars.language       = 1;               	 % 1 English, 2 Danish


% Get current timestamp & set filename
startTime = clock;
saveTime = [num2str(startTime(4)), '-', num2str(startTime(5))];
vars.DataFileName = strcat(vars.DataFileName, date, '_', saveTime);

%% EDIT PARAMETERS BELOW
%Set up psi
stair.NumTrials = 60;                           % Number of trials in EACH staircase (2 interleaved staircases, showing M & F faces)
vars.NTrialsTotal = stair.NumTrials;                % Total N trials differs from stair.NumTrials when we have multiple staircases

stair.grain = 201;                                  % Grain of posterior, high numbers make method more precise at the cost of RAM and time to compute.
%Always check posterior after method completes [using e.g., :
%image(PAL_Scale0to1(PM.pdf)*64)] to check whether appropriate
%grain and parameter ranges were used.

stair.PF = @PAL_Weibull;                            % Assumed psychometric function, e.g. @PAL_Gumbel, @PAL_Logistic, @PAL_Weibull;

%Stimulus values the method can select from
stair.stimRange = 0:1:200;

%Define parameter ranges to be included in posterior
stair.priorAlphaRange = 0.01:.5:200;                              % Low start
stair.priorBetaRange = linspace(log10(1),log10(100000),stair.grain);    % Use log10 transformed values of beta (slope) parameter in PF      <-- 12/07 changed upper limit to 5, (log10(100000))
%         stair.priorBetaRange = 0:.05:5;                                   % non-log10 beta also works
stair.priorGammaRange = 0;                                       % guess rate = fixed value (using vector here would make it a free parameter)
stair.priorLambdaRange = .02;

%Initialize PM structure
stair.PM = PAL_AMPM_setupPM('priorAlphaRange',stair.priorAlphaRange,...
    'priorBetaRange',stair.priorBetaRange,...
    'priorGammaRange',stair.priorGammaRange,...
    'priorLambdaRange',stair.priorLambdaRange,...
    'numtrials',stair.NumTrials,...
    'PF' , stair.PF,...
    'stimRange',stair.stimRange);

%% Interleave face genders
vars.faceGenderSwitch = [zeros(stair.NumTrials, 1); ones(stair.NumTrials, 1)];
vars.faceGenderSwitch = mixArray(vars.faceGenderSwitch);

%% Task timing
vars.fixedTiming = 1;       % Flag to force fixed timing for affect response & conf rating. 1 - fixed timing, 2 - self-paced
vars.StimT = 1;      % sec
vars.RespT = 2;      % sec
vars.ConfT = 3;      % sec
vars.ITI_min = 1;    % variable ITI (1-2s)
vars.ITI_max = 2;
vars.ITI = randInRange(vars.ITI_min, vars.ITI_max, [vars.NTrialsTotal,1]);
singleTrialDuration = vars.StimT + vars.RespT + (vars.ConfT-1) + vars.ITI_max;
vars.sessionDuration = singleTrialDuration * vars.NTrialsTotal;


%% Plux synch variables
% Colours: White, Black
scr.pluxWhite     = WhiteIndex(scr.screenID);
scr.pluxBlack     = BlackIndex(scr.screenID);

% Duration
scr.pluxDur         = [2; 25];% [2;4]       % 2 frames - stim, 4 frames - response

% Size
% rows: x y width height
% provide size in cm and convert to pix
pluxRectTemp        = [0; 0; 1.0; 1.0];
multFactorW         = scr.resolution(1) ./ scr.MonitorWidth;
multFactorH         = scr.resolution(2) ./ scr.MonitorHeight;
scr.pluxRect(3)     = pluxRectTemp(3) .* multFactorW;
scr.pluxRect(4)     = pluxRectTemp(4) .* multFactorH;
scr.pluxRect = CenterRectOnPoint(scr.pluxRect,scr.resolution(1) - scr.pluxRect(3)/2,scr.resolution(2) - scr.pluxRect(4)/2);


%% Instructions
textSize = 35;
if vars.language == 1       % English
    switch vars.ConfRating
        
        case 1
            switch vars.InputDevice
                
                case 1 % Keyboard
                    vars.InstructionTask = 'Decide if the face presented on each trial is angry/in a bad mood or happy/in a good mood. \n \n ANGRY - BUTTON 1                         HAPPY - BUTTON 4 \n \n \n \n Then, rate how confident you are in your choice using the buttons to move the slider. \n \n Press BUTTON 3 to start.';
                    vars.InstructionConf = 'Rate your confidence using BUTTONS 1 and 4 to move the slider. Press BUTTON 3 to confirm.';
                    
                case 2 % Mouse
                    vars.InstructionTask = 'Decide if the face presented on each trial is angry/in a bad mood or happy/in a good mood. \n \n ANGRY - BUTTON 1                         HAPPY - BUTTON 4 \n \n \n \n Then, rate how confident you are in your choice using the mouse. \n \n Press BUTTON 3 to start.';
                    vars.InstructionConf = 'Rate your confidence using the mouse. Left click to confirm.';
                    vars.ConfEndPoins = {'Guess', 'Very sure'};
            end
            
        case 0
            switch vars.InputDevice
                
                case 1 % Keyboard
                    vars.InstructionTask = 'Decide if the face presented on each trial is angry/in a bad mood or happy/in a good mood. \n \n ANGRY - BUTTON 1                         HAPPY - BUTTON 4 \n \n \n \n Press BUTTON 3 to start.';
                case 2 % Mouse
                    vars.InstructionTask = 'Decide if the face presented on each trial is angry/in a bad mood or happy/in a good mood. \n \n ANGRY - BUTTON 1                         HAPPY - BUTTON 4 \n \n \n \n Press BUTTON 3 to start.';
            end
            
    end
    vars.InstructionQ = 'Angry (L)     or     Happy (R)';
    vars.InstructionPause = 'Take a short break... \n \n When you are ready to continue, press ''BUTTON 3''...';
    vars.InstructionEnd = 'You have completed the Face Discrimination task. \n \n Please take a short break. Do not press or click anything. \n \n \n \n In a minute, you will be able to continue with the Localizer Task.';
    % N.B. Text colour and size are set after Screen('Open') call
    
elseif vars.language == 2       % Danish
    
    switch vars.ConfRating
        
        case 1
            switch vars.InputDevice
                
                case 1 % Keyboard
                    vars.InstructionTask = 'Afgør i hver runde om ansigtet er vredt/i dårligt humør eller glad/i godt humør. \n \n VRED - Venstre tast                         GLAD - Højre piletast \n \n \n \n Så skal du angive hvor sikker du er på dit valg ved at bruge piletasterne til at flytte skyderen. \n \n Tryk på MELLEMRUMSTASTEN for at starte.';
                    vars.InstructionConf = 'Angiv hvor sikker/usikker du er ved hjælp af piletasterne til at flytte skyderen. Tryk på MELLEMRUMSTASTEN for at bekræfte.';
                    
                case 2 % Mouse
                    vars.InstructionTask = 'Afgør i hver runde om ansigtet er vredt/i dårligt humør eller glad/i godt humør. \n \n VRED - Venstre piletast                         GLAD - Højre piletast \n \n \n \n Så skal du angive hvor sikker du er på dit valg ved at bruge nummertasterne. \n \n Usikker (1), Sikker (2), og Meget sikker (3). \n \n Tryk på MELLEMRUMSTASTEN for at starte.';
                    
                    vars.InstructionConf = 'Angiv hvor sikker/usikker du er ved hjælp af musen. Klik på venstre mussetast for at bekræfte.';
                    vars.ConfEndPoins = {'Gæt', 'Meget sikker'};
            end
            
        case 0
            switch vars.InputDevice
                
                case 1 % Keyboard
                    vars.InstructionTask =  'Afgør i hver runde om ansigtet er vredt/i dårligt humør eller glad/i godt humør. \n \n VRED- Venstre tast                         GLAD - Højre tast \n \n \n \n Tryk på MELLEMRUMSTASTEN for at starte.';
                case 2 % Mouse
                    vars.InstructionTask = 'Afgør i hver runde om ansigtet er vredt/i dårligt humør eller glad/i godt humør. \n \n VRED- Venstre piletast                         GLAD - Højre piletast \n \n \n \n Tryk på MELLEMRUMSTASTEN for at starte.';
            end
            
    end
    vars.InstructionQ = 'Vred (L)     eller     Glad(R)';
    vars.InstructionPause = 'Tag en kort pause ... \n \n Når du er klar til at fortsætte, så tryk på mellemrumstasten ...';
    vars.InstructionEnd = 'Du har gennemført Ansigstdiskrimineringsopgaven. \n \n Tag venligst en kort pause. Du skal ikke trykke på tastaturet eller musen. \n \n \n \n Om et minut vil du kunne fortsætte med Læringsopgaven.';
    
end

%% Stimuli
% Stimuli
% vars.TaskPath = fullfile('.', 'code', 'task');          % from main task folder (ie. 'Pilot_2_PsiAdaptive')
vars.StimFolder = fullfile('..', '..','stimuli', filesep);   %fullfile('.', 'stimuli', filesep);
vars.StimSize = 4;%9;%7;                                      % DVA
vars.StimsInDir = dir([vars.StimFolder, '*.tif']);      % list contents of 'stimuli' folder

