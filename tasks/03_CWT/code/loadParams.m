%% Define parameters
%
% Project: CWT task, for fMRI
%
% Sets key parameters, called by main.m
%
% Niia Nikolova
% Last edit: 10/07/2020

global language
vars.language = language;

%% Key flags
vars.emulate        = 0;                % 0 scanning, 1 testing
vars.ConfRating     = 1;                % Confidence rating? (1 yes, 0 no)
vars.InputDevice    = 2;                % Response method for conf rating. 1 - keyboard 2 - mouse
useEyeLink          = 0;                % Use EyeLink to record gaze & pupil?
vars.fixCrossFlag   = 1;
vars.pluxSynch      = 1;
vars.runCWTtutorial = 1;
% vars.language       = 1;

% Get current timestamp & set filename
vars.exptName = 'CWTcontent_';
startTime = clock;
saveTime = [num2str(startTime(4)), '-', num2str(startTime(5))];
vars.DataFileName = strcat(vars.DataFileName, '_', date, '_', saveTime);

%% Procedure
vars.NTrialsTotal = 264;
vars.PredEveryXTrials = 12;
vars.NPredTrials = vars.NTrialsTotal ./ vars.PredEveryXTrials;
vars.NTrialsWPred = vars.NTrialsTotal + vars.NPredTrials;

vars.NCatchTrials = 10;


%% Stimuli
vars.PMFptsForStimuli           = .3;%.3              % Percent below and above FAD threshold to use as Happy and Angry stimulus mid-points
vars.jitterStimsBy              = 0.02;             % Amount of jitter around A & H stims

% Start calculating morphs to use (this continues after block setup)
[noThreshFlag, thresh, PMFstims]= getParticipantThreshold(vars);                 % get PMFstims = stimLevels at [.3 .5 .7 p(correct)]
NJitterLevels = length(PMFstims);
vars.NMorphJitters = NJitterLevels;
stimJitterA = PMFstims(1:NJitterLevels/2);
stimJitterH = PMFstims((NJitterLevels/2)+1:end);


%% Add 50/50 catch trials  - currently not in use ###
% catchTrialStim = '100';
% vars.catchTrialArray = [ones(1,vars.NCatchTrials/2), zeros(1,vars.NCatchTrials/2)];
% vars.catchTrialArray = mixArray(vars.catchTrialArray);  % shuffle F and M face catch trials


%% Cueing
% Set temporal evolution of cue probablilities using
% createCueProbabilities.m

% Fetch trialSequence & cueSequence from saved file
% [cueProbabilityOutput, blockParams, breaks] = createCueProbabilities(vars);

% Randomly select #1, 4 (later also 6, maybe 2[3 reversals, more
% difficult])
randSequence = round(rand);
if randSequence
    chosenSequence = 'sequence1.mat';
else
    chosenSequence = 'sequence4.mat';
end
% Add 'sequence6.mat'

[Output] = load(chosenSequence);
cueProbabilityOutput=Output.cueProbabilityOutput;
blockParams = Output.blockParams;
breaks = Output.breaks;
vars.cueProbabilityOutput = cueProbabilityOutput;
vars.conditionSequence  = cueProbabilityOutput(:,2);            % conditions (1:5), % 1 cue_0 valid   2 cue_1 valid    3 cue_0 invalid    4 cue_1 invalid      5 non-predictive
vars.faceSequence       = cueProbabilityOutput(:,4);            % sequence of face genders [0|1]
vars.cueSequence        = cueProbabilityOutput(:,5);            % sequence of cues [0|1]
vars.trialSequence      = cueProbabilityOutput(:,6);            % 1 valid, 2 invalid
vars.FaceEmot           = cueProbabilityOutput(:,10);           % 1 happy, 0 angry
vars.cue0Prediction     = cueProbabilityOutput(:,12);           % %(is cue 0 predictive of Happy (1) or Angry (2) faces, on non-predictive(0)?)
vars.predictionTrialNext = cueProbabilityOutput(:,13);          % 1 if there is a prediction trial after the ITI of this trial

vars.breaks                         = breaks;                  	% break AFTER this trial
vars.blockParams                    = blockParams;
vars.desiredBlockProbabilities      = blockParams(1,:);
vars.effectiveBlockProbabilities    = blockParams(2,:);
vars.blockLengths                   = blockParams(3,:);
stimJitterRepsByBlock               = blockParams(4,:);

vars.trialByTrialBlockVector    = [];
vars.FaceMorphs                 = [];                           % (Ntrials/2) x 2 array, [angry, happy]
blockCount                      = 1;

% Make a vector with block lengths & FaceMorphVals by trial
for thisBlock = 1:length(vars.blockLengths)
    tempBlockN = (blockCount .* ones(1,vars.blockLengths(thisBlock)));
    vars.trialByTrialBlockVector = [vars.trialByTrialBlockVector, tempBlockN];
    blockCount = blockCount + 1;
    clear tempBlockN
    
    thisBlockAngryStims = mixArray(repmat(stimJitterA, 1, stimJitterRepsByBlock(thisBlock)));
    thisBlockHappyStims = mixArray(repmat(stimJitterH, 1, stimJitterRepsByBlock(thisBlock)));
    thisBlockAllFaceStims = vertcat(thisBlockAngryStims, thisBlockHappyStims);
    
    vars.FaceMorphs = horzcat(vars.FaceMorphs, thisBlockAllFaceStims);
    
    % Add some extra stim morph levels b/c it doesn't always work out that
    % we have exactly = numbers of happy and angry stims - find a better
    % way to do this!
    if thisBlock == length(vars.blockLengths)
        thisBlockAngryStims = mixArray(repmat(stimJitterA, 1, stimJitterRepsByBlock(thisBlock)));
        thisBlockHappyStims = mixArray(repmat(stimJitterH, 1, stimJitterRepsByBlock(thisBlock)));
        thisBlockAllFaceStims = vertcat(thisBlockAngryStims, thisBlockHappyStims);
        
        vars.FaceMorphs = horzcat(vars.FaceMorphs, thisBlockAllFaceStims);
    end
    
end


%% Paths
% Faces
vars.TaskPath = fullfile('.', 'code', 'task');
vars.StimFolder = fullfile('..', '..', 'stimuli', filesep);   %fullfile('.', 'stimuli', filesep);
vars.StimSize = 4;                                      % DVA    (5 for behavioural CWT, summer/fall 2021)
vars.StimsInDir = dir([vars.StimFolder, '*.tif']);      % list contents of 'stimuli' folder

% Cues
vars.CuesInDir = dir([vars.StimFolder, 'cue*']);      % list contents in 'stimuli' folder


%% Task timing
vars.fixedTiming        = 0;    % Flag to force fixed timing for affect response  1 fixed, 0 self-paced (Conf rating always fixed, otherwise infinite!)
vars.RepeatMissedTrials = 0;
vars.CueT               = .5;
vars.StimT              = .5;   % sec
vars.RespT              = 2;    % sec
vars.ConfT              = 3;    % sec
vars.PTRespT            = 3;    % sec  2
vars.PTTotT             = 4;    % sec  3
vars.ISI_min            = 2;    % long variable ISI, 2-3 or 2-4 sec
vars.ISI_max            = 3;
vars.ISI                = randInRange(vars.ISI_min, vars.ISI_max, [vars.NTrialsTotal,1]);
vars.ITI_min            = 1;    % short variable ITI
vars.ITI_max            = 2;
vars.ITI                = randInRange(vars.ITI_min, vars.ITI_max, [vars.NTrialsTotal,1]);
vars.breakT             = 60;   % sec
trialDur_min            = vars.CueT + vars.StimT + vars.RespT + vars.ConfT + vars.ISI_min + vars.ITI_min - 2;   % -2 if we expect ppts to respond quickly
trialDur_max            = vars.CueT + vars.StimT + vars.RespT + vars.ConfT + vars.ISI_max + vars.ITI_max;
trialDuration           = [trialDur_min, trialDur_max];


%% Plux synch variables
% Colours: White, Black
scr.pluxWhite     = WhiteIndex(scr.screenID);
scr.pluxBlack     = BlackIndex(scr.screenID);

% Duration
scr.pluxDur         = [2; 25];% [2;4]       % 2 frames - stim, 4 frames - response

% Size
% rows: x y width height
% provide size in cm and convert to pix
pluxRectTemp        = [0; 0; .5; .5];
multFactorW         = scr.resolution(1) ./ scr.MonitorWidth;
multFactorH         = scr.resolution(2) ./ scr.MonitorHeight;
scr.pluxRect(3)     = pluxRectTemp(3) .* multFactorW;
scr.pluxRect(4)     = pluxRectTemp(4) .* multFactorH;
scr.pluxRect = CenterRectOnPoint(scr.pluxRect,scr.pluxRect(3)/2,scr.resolution(2) - scr.pluxRect(4)/2);


%% Prediction trials set-up
vars.PTwhichCue = repmat([0; 1],(vars.NPredTrials/2),1);         % Which cue will be presented on this prediction trial? 0 cue_0, 1 cue_1

%% Instructions
textSize = 35;
if vars.language == 1       % English
    
    vars.PTTitle = 'Prediction trial';
    vars.PTQuestion = 'Is this cue predicting    Angry (L)     or     Happy (R)    faces? ';
    
    switch vars.ConfRating
        case 1
            switch vars.InputDevice
                case 1 % Keyboard
                    vars.InstructionTask = 'Decide if the face presented on each trial is angry or happy. \n \n ANGRY - Left arrow key                         HAPPY - Right arrow key \n \n \n \n Then, rate how confident you are in your choice using the number keys. \n \n Unsure (1), Sure (2), and Very sure (3). \n \n Press SPACE to start...';
                    vars.InstructionConf = 'Rate your confidence \n \n Unsure (1)     Sure (2)     Very sure (3)';
                    
                case 2 % Mouse
                    vars.InstructionTask = 'Decide if the face presented on each trial is angry or happy. \n \n ANGRY - Left button                         HAPPY - Right button \n \n \n \n Then, rate how confident you are in your choice using the mouse. \n \n Press SPACE to start...';
                    vars.InstructionConf = 'How confident are you in your choice?. Left click to confirm.';
                    vars.ConfEndPoins = {'Guess', 'Certain'};
            end
        case 0
            switch vars.InputDevice
                
                case 1 % Keyboard
                    vars.InstructionTask = 'Decide if the face presented on each trial is angry or happy. \n \n ANGRY - Left arrow key                         HAPPY - Right arrow key \n \n \n \n Press SPACE to start...';
                case 2 % Mouse
                    vars.InstructionTask = 'Decide if the face presented on each trial is angry or happy. \n \n ANGRY - Left button                         HAPPY - Right button \n \n \n \n Press SPACE to start...';
            end
    end
    vars.InstructionQ = 'Angry (L)     or     Happy (R)';
    vars.InstructionPause = 'Take a short break... \n \n You can continue in ...';
    vars.InstructionEnd = 'You have completed the session. Thank you!';
    
elseif vars.language == 2       % Danish
    
    vars.PTTitle = 'Forudsiger trial';   %% <-------- UPDATE
    vars.PTQuestion = 'Forudsiger dette symbol Vrede (V) eller Glade (H) ansigter ';
    
    switch vars.ConfRating
        case 1
            switch vars.InputDevice
                case 1 % Keyboard
                    vars.InstructionTask = 'Afgør om det ansigt der bliver præsenteret i hver runde er vredt eller glad. \n \n VRED - Venstre piletast                         GLAD - Højre piletast \n \n \n \n Så skal du angive for sikker på er på dit valg ved at bruge tallene Usikker(1), Sikker (2), og Meget sikker (3). \n \n Unsure (1), Sure (2), and Very sure (3). \n \n Tryk på MELLEMRUMSTASTEN for at begynde...';
                    vars.InstructionConf = 'Angiv din sikkerhed \n \n Usikker (1)     Sikker (2)     Meget sikker (3)';
                    
                case 2 % Mouse
                    vars.InstructionTask = 'Afgør om det ansigt der bliver præsenteret i hver runde er vredt eller glad. \n \n VRED - Venstre tast                         GLAD - Højre tast \n \n \n \n Så skal du angive hvor sikker du er på dit valg ved at bruge musen. \n \n Tryk på MELLEMRUMSTASTEN for at begynde...';
                    vars.InstructionConf = 'Hvor sikker er du på dit valg? Tryk på venstre tast for at bekræfte.';
                    vars.ConfEndPoins = {'Gæt', 'Sikker'};
            end
        case 0
            switch vars.InputDevice
                
                case 1 % Keyboard
                    vars.InstructionTask = 'Afgør om det ansigt der bliver præsenteret i hver runde er vredt eller glad. \n \n VRED - Venstre piletast                         GLAD - Højre piletask \n \n \n \n Tryk på MELLEMRUMSTASTEN for at begynde...';
                case 2 % Mouse
                    vars.InstructionTask = 'Afgør om det ansigt der bliver præsenteret i hver runde er vredt eller glad. \n \n VRED - Venstre piletast                         GLAD - Højre piletask \n \n \n \n Tryk på MELLEMRUMSTASTEN for at begynde...';
            end
    end
    vars.InstructionQ = 'Vred (V)     eller     Glad (H)';
    vars.InstructionPause = 'Tag en kort pause... \n \n Du kan fortsætte om ...';
    vars.InstructionEnd = 'Du har gennemført sessionen. Tak!!';
    
    
end


