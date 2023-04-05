function [cueProbabilityOutput, blockParams, breaks] = createCueProbabilities(vars)
% Set up probabilistic blocks
%       
% [cueProbabilityOutput, blockParams, breaks] = createCueProbabilities(vars)
%
% Project: CWT task, for fMRI.
% Sets up a squenece of blocks of cue probabilities given some parameters. NB that each block type must be presented an equal number of times
%
% Input:  vars struct with fields
%       NTrialsTotal        expectded total # of trials
%       NMorphJitters       total number of jitter values for face morphs,
%       for both Happy and Angry
%
% Output:       cueProbabilityOutput matrix with 9 columns
%   1       trial #
%   2       condition           [1, 2, 3, 4, 5]     % 1 cue_0 valid   2  cue_1 valid    3 cue_0 invalid    4 cue_1 invalid      5 non-predictive
%   3       block type          [1, 2, 3]           % 1 non-predictive, 2 predictive short, 3 predictive long
%   4       face gender         [0, 1]              % 0 male, 1 female
%   5       cue                 [0, 1]
%   6       trial type          [1, 2]              % Valid / Invalid
%   7       desired prob        
%   8       effective prob
%   9       block volatility    [0, 1]              % 1 volatile, 0 stable
%   10      outcome             [0, 1]              % face outcome. 0 Angry or 1 happy
%   11      predictive/non-predictive trial
%   12     	cue0PredictionSequence [0, 1, 2]        % 0 NP, 1 cue_0->Happy, 2 cue_0->Angry
%   13      predictionTrialNext [0, 1]              % 1 if there is a prediction trial after the ITI of this trial
%   14      reversalBlocksSequence;                                
%   15      blockwiseTrialNumber                    % trial # within a block

%   blockParams             block-level parameters
%           [desiredProbByBlock ; effectiveProbByBlock; blockLengths; stimJitterRepsByBlock; reversalBlocks]
%       reversalBlocks   1 if a reversal occured on this block
%
%   breaks                  array or trial #s after which to pause the
%                            experiment
%
% Niia Nikolova
% Last edit: 24/07/2020             added marker for reversal blocks


plotSequence = 1;           % 1 plot block probabilities, 0 no plot

% new_line;
disp('Determining trial sequence...');

% Desired parameters
probabilityInvalidValid     = [0.18, 0.82];  % determines the percent of invalid to valid trials

NProbLevels                 = length(probabilityInvalidValid);   % + 0.5 for Non-predicitve blocks
NBlocks_2                   = 4;                            % NB predictive short blocks
NBlocks_3                   = 2;                            % NB predictive long blocks
NBlocks_Pred                = NBlocks_2 + NBlocks_3;        % NB predictive blocks
% NBlocks_U                   = (NBlocks_Pred-1);             % NB non-predictive blocks
NBlocks_total               = NBlocks_Pred; % + (NBlocks_Pred-1);        % predicitve and unpredictive blocks
NGroups                     = 2;                            % each group consists of NBlocks/2 predictive blocks
NTrialsTotal                = vars.NTrialsTotal;%264

cueBlockLength_shortP       = 28;% short predictive block, +/-jitter    || 24, total for 4* short blocks = 144
cueBlockLength_longP        = 76;% long predictive block, +/-jitter     || 60, total for 2* long blocks  = 96
cueBlockLength_U            = 0;% unpredictive block, +/-jitter        || 10, total for 5* U blocks     = 50
jitter                      = 4; % block length jitter for predictive blocks
jitter_U                    = 2;

% Range of trial durations
trialDuration               = [8, 10];                      % in sec (min 8, max 10)
predTrialDuration           = [3, 3];                       % Always 3sec


% How many levels of jitter do we have around the H and A face stimuli (2*Happy & 2*Angry = 4 total)
NbStimJitterVals             = vars.NMorphJitters;  %4

% Set up breaks
NBreaks                     = 2;                        % Number of breaks for the participant
breakAfterXTrials           = [NTrialsTotal/(NBreaks+1), 2*NTrialsTotal/(NBreaks+1)];

% Create some empty arrays
breaks                      = [];
% isThisBlockPredictive       = repmat([1, 0], 1, ((NBlocks_total-1)/2)+1);
isThisBlockPredictive       = ones(1, NBlocks_total);
blockLengths                = [];                   % master block length array for this sequence
trialSequence               = [];
effectiveBlockProbabilities = [];
desiredBlockProbabilities   = [];
cueSequence                 = [];
faceSequence                = [];
cue0PredictionSequence      = [];   % 1 Happy, 2 Angry, 0 Non-predictive
blockClassSequence          = []; 	% 1 non-predictive, 2 predictive short, 3 predictive long                 
blockVolatility             = [];
reversalBlocksSequence      = [];
blockwiseTrialNumber        = [];   % which trial # in a block is this
conditionSequence           = NaN * ones(1,NTrialsTotal);   	% trial-by-trial condition vector
outcomeSequence             = NaN * ones(1,NTrialsTotal);   	% trial-by-trial outcome vector, i.e. 1 happy or  0 anggry
NPtrials                     = zeros(1,NTrialsTotal);            % vector marking any non-predictive trials by 1

% Set up output matrix
NRows                       = 9;                    % Number of rows we'll need
trialNb                     = [1:NTrialsTotal]';
cueProbabilityOutput        = NaN * ones(NTrialsTotal, NRows);
cueProbabilityOutput(:,1)   = trialNb;

vars.NPredTrials            = vars.NTrialsTotal;

%% Jitter the block lengths (long predictive, short predictive and unpredictive)
% Option A: If we want to add random jitter
% blockLengths_3    	= round(jitter_values(cueBlockLength_longP, jitter, jitter, NBlocks_3));        % Predictive long
% blockLengths_2        = round(jitter_values(cueBlockLength_shortP, jitter, jitter, NBlocks_2));       % Predictive short
% blockLengths_1    	= round(jitter_values(cueBlockLength_U, jitter, jitter, (NBlocks_Pred-1)));     % Non-predictive

% Option B: We want the black lengths to vary, but in a more controlled way
% controlled way - we restrict to mult of 4
% 1 non-predictive, 2 predictive short, 3 predictive long
% blockLengths_3    	= round(jitter_values(cueBlockLength_longP, jitter, jitter, NBlocks_3));  
% blockLengths_2      = [round(jitter_values(cueBlockLength_shortP, 0, jitter, NBlocks_2/2)), round(jitter_values(cueBlockLength_shortP, jitter, 0, NBlocks_2/2))];
% blockLengths_1      = mixArray([cueBlockLength_U-jitter_U*ones(1, ceil(NBlocks_U/2)), cueBlockLength_U+jitter_U*ones(1, floor(NBlocks_U/2))]);
blockLengths_3    	= round(jitter_values(cueBlockLength_longP, jitter, jitter, NBlocks_3));  
blockLengths_2      = mixArray([cueBlockLength_shortP-jitter*ones(1, ceil(NBlocks_2/2)), cueBlockLength_shortP+jitter*ones(1, floor(NBlocks_2/2))]);

% Check if we get the # of trials we expect, print expected duration
NTrialsCheck        = sum(blockLengths_3) + sum(blockLengths_2); % + sum(blockLengths_1);
% Break if we don't get the expected # of trials
if NTrialsCheck ~= NTrialsTotal
    disp('Unexpected # of trials.'); 
    disp(['Expected: ', num2str(NTrialsTotal)]); 
    disp(['Calculated: ', num2str(NTrialsCheck)]);
    return; 
end
expectedDurationMin = NTrialsCheck * trialDuration(1) / 60;
expectedDurationMax = NTrialsCheck * trialDuration(2) / 60;
% Prediction trials
predTrialsDurationMin = vars.NPredTrials * predTrialDuration(1) / 60;
predTrialsDurationMax = vars.NPredTrials * predTrialDuration(2) / 60;
expectedDurationMin = round(expectedDurationMin + predTrialsDurationMin);
expectedDurationMax = round(expectedDurationMax + predTrialsDurationMax);

% Print expected duration
disp(['Expected run duration at ', num2str(trialDuration(1)), 's/trial: ', num2str(expectedDurationMin), ' min.']);
disp(['Expected run duration at ', num2str(trialDuration(2)), 's/trial: ', num2str(expectedDurationMax), ' min.']);


%% Create block sequence
% 1 long/highP, 2 long/lowP, 3 short/highP, 4 short/lowP   [P(X|cue_0)]
% RULES:
%      - Short blocks occur in groups of 2, so that we get stable and volatile periods (this implieas that
%       the long blocks are not together (i.e. LSSLSS or SSLSSL))
%      - No more than 2 blocks of the same predictive value together

predBlockTypesArray = [ones(1,NBlocks_3/2), 2*ones(1,NBlocks_3/2), 3*ones(1, NBlocks_2/2), 4*ones(1, NBlocks_2/2)];
shortPredBlockTypes = mixArray(predBlockTypesArray(3:6));
longPredBlockTypes = mixArray(predBlockTypesArray(1:2));
blockPlacementSwitch = round(rand);                          % Switch to help us decide whether we'll start or end with a long block
if blockPlacementSwitch                                      % start with LONG block
    predBlockTypes = [longPredBlockTypes(1), shortPredBlockTypes(1:2), longPredBlockTypes(2), shortPredBlockTypes(3:4)]; 
else                                                        % start with short block
    predBlockTypes = [shortPredBlockTypes(1:2), longPredBlockTypes(1), shortPredBlockTypes(3:4), longPredBlockTypes(2)];
end

% Check if a reversal has occured and fill in
% 1 long/highP, 2 long/lowP, 3 short/highP, 4 short/lowP   [P(X|cue_0)]
% Reversals occur at 1-2, 1-4, 2-3, 3-4

% Label High and Low cue_0 predictive blocks & mark blocks where a reversal
% has occured
HiCue0PredictionBlocks = (predBlockTypes==1 | predBlockTypes==3);       % these are cue_0 -> Happy predictive blocks
reversalBlocks = ((diff([0 HiCue0PredictionBlocks])==1) | (diff([0 HiCue0PredictionBlocks])==-1));
reversalBlocks(1) = 0;                      % sometimes the first block is wrongly marked as a reversal. 


%% Create trials for each block
blockCounter_1          = 1;                % Non-predictive
blockCounter_2          = 1;                % Predictive short
blockCounter_3          = 1;                % Predictive long

predLoopCounter         = 1;
cueOutcomeProbDesired   = [];               % Target prob
cueOutcomeProbEffective = [];               % Effective prob
stimJitterRepsByBlock   = [];               % nb times to present each morph jittel level per block  

for thisBlock = 1:NBlocks_total                 % Loop over all blocks       
    % Is this block predictive or not?
    if isThisBlockPredictive(thisBlock)         % Predictive block
        % P is given for happy|cue_0
        switch predBlockTypes(predLoopCounter)
            case 1  % in this long block, cue zero is predictive of happy
                NTrialsInThisBlock      = blockLengths_3(blockCounter_3);
                blockLengths            = [blockLengths, NTrialsInThisBlock];
                pHappyCue0              = probabilityInvalidValid(2);       % this determines that the zero cue is predictive i.e., 75% of happy outcomes
                cue0PredictiveOf        = 1;        % Happy
                thisBlockClass          = 2;        % Predictive long
                thisBlockVolatility     = 0;        % 0 stable, 1 volatile
                blockCounter_3          = blockCounter_3 + 1;
                
            case 2  % in this long block, cue zero is antipredictive of happy (predicts angry)
                NTrialsInThisBlock      = blockLengths_3(blockCounter_3);
                blockLengths            = [blockLengths, NTrialsInThisBlock];
                pHappyCue0              = probabilityInvalidValid(1);       % 25%
                cue0PredictiveOf        = 2;        % Angry
                thisBlockClass          = 2;        % Predictive long
                thisBlockVolatility     = 0;                      
                blockCounter_3          = blockCounter_3 + 1;
                
            case 3  % in this short block, cue zero is predictive of happy 
                NTrialsInThisBlock      = blockLengths_2(blockCounter_2);
                blockLengths            = [blockLengths, NTrialsInThisBlock];
                pHappyCue0              = probabilityInvalidValid(2);
                cue0PredictiveOf        = 1;        % Happy
                thisBlockClass          = 1;        % Predictive short
                thisBlockVolatility     = 1;                        
                blockCounter_2          = blockCounter_2 + 1;
                
            case 4 % in this short block, cue zero is antipredictive of happy (predicts angry)
                NTrialsInThisBlock      = blockLengths_2(blockCounter_2);
                blockLengths            = [blockLengths, NTrialsInThisBlock];
                pHappyCue0              = probabilityInvalidValid(1);
                cue0PredictiveOf        = 2;        % Angry
                thisBlockClass          = 1;        % Predictive short
                thisBlockVolatility     = 1;                     
                blockCounter_2 = blockCounter_2 + 1;
                
        end
        predLoopCounter = predLoopCounter + 1;
        
    else                                    % Non-predictive blocks
%         NTrialsInThisBlock              = blockLengths_1(blockCounter_1);
%         blockLengths                    = [blockLengths, NTrialsInThisBlock];
%         pHappyCue0                      = 0.5;
%         cue0PredictiveOf                = 0;        % Non-predictive
%         thisBlockClass                  = 1;        % Non=predictive
%         thisBlockVolatility             = 1;        % Non-predictive marked as volatile
%         blockCounter_1                  = blockCounter_1 + 1;
    end
    
    
    %% Set up individual trials per block   
    cueOutcomeProbDesired           = [pHappyCue0 * ones(NTrialsInThisBlock, 1)];
    
    % Mark blocks where a reversal occured
    blockIsAReversal           = [reversalBlocks(predLoopCounter-1) * ones(NTrialsInThisBlock, 1)];

    
    %% initialize coin toss for rounding up or down blocks
    
    coin = rand(1, 1)<.5;
    
    % Create trials for each cue in this block
    if isThisBlockPredictive(thisBlock)
        [trialvectorCue0, real_probabilityCue0] = create_trials(probabilityInvalidValid(2), NTrialsInThisBlock./2, coin);
        [trialvectorCue1, real_probabilityCue1] = create_trials(probabilityInvalidValid(2), NTrialsInThisBlock./2, coin);
    else
        [trialvectorCue0, real_probabilityCue0] = create_trials(0.5, NTrialsInThisBlock./2, coin);
        [trialvectorCue1, real_probabilityCue1] = create_trials(0.5, NTrialsInThisBlock./2, coin);

    end
    % Create vectors for the cues
    trialmatrixCue0 = [trialvectorCue0', ones(1,length(trialvectorCue0))'.*0];
    trialmatrixCue1 = [trialvectorCue1', ones(1,length(trialvectorCue1))'];
    
    trialsThisBlock = [trialmatrixCue0; trialmatrixCue1];
    
    permVect = randperm(size(trialsThisBlock,1))';    % permute row numbers
    
    % col 1: 1 valid/2 invalid,  col 2: 0 cue_0/1 cue_1
    trialsThisBlockShuffled = trialsThisBlock(permVect,:);
    
    %% check that valid/invalid proportions work out for both cues
    cue0Trials = (trialsThisBlockShuffled(trialsThisBlockShuffled(:,2)==0));
    cue1Trials = (trialsThisBlockShuffled(trialsThisBlockShuffled(:,2)==1));
    
    nInvalidTrials0 = sum(cue0Trials(:)== 2);
    nInvalidTrials1 = sum(cue1Trials(:)== 2);
    nValidTrials0 = sum(cue0Trials(:)== 1);
    nValidTrials1 = sum(cue1Trials(:)== 1);
    
    totalcue0Trials = length(cue0Trials);
    totalcue1Trials = length(cue1Trials);
    
    % proportion valid = .75, invalid = .25
   
    propInvalid0 = nInvalidTrials0 ./ totalcue0Trials;
     disp(['Proportion invalid cue 0:', num2str(propInvalid0)])
    propInvalid1 = nInvalidTrials1 ./ totalcue1Trials;
    disp(['Proportion invalid cue 1:', num2str(propInvalid1)])
    propValid0 = nValidTrials0 ./ totalcue0Trials;
    disp(['Proportion valid cue 0:', num2str(propValid0)])
    propValid1 = nValidTrials1 ./ totalcue1Trials;
    disp(['Proportion valid cue 1:', num2str(propValid1)])
    
    %% Add to trial-wise sequences
    % Mark which world we're in (is cue 0 predictive of Happy (1) or Angry (2) faces, on non-predictive(0)?)
    blockCue0Prediction     = [cue0PredictiveOf * ones(NTrialsInThisBlock, 1)];

    % Mark cue_0 and cue_1 trials
    cueVectorThisBlock      = trialsThisBlockShuffled(:,2);
    
    % Mark valid & invalid trials
    trialvector             = trialsThisBlockShuffled(:,1);    
       
    % Effective outcome probability (for cue_0). When NP or predicting Happy, this =
    % propValid0, when predicting Angry, this = 1-propValid0
   
    if cue0PredictiveOf == 0  % notpredictive (p(s1|c1) = 0.5)
        cueOutcomeProbEffective = [propValid0 * ones(NTrialsInThisBlock, 1)];
    elseif cue0PredictiveOf == 1 % predictive of happy (p(s1|c1) = 0.75 (e.g,)
        cueOutcomeProbEffective = [propValid0 * ones(NTrialsInThisBlock, 1)];
    elseif cue0PredictiveOf == 2 % predictive of angry (p(s2|c1) = 0.75 
        cueOutcomeProbEffective = [(1-propValid0) * ones(NTrialsInThisBlock, 1)];
    end
    
    % Generate face genders for this block & shuffle: 50% prob of either of the two genders
    [faceVectorThisBlock, ~]        = create_trials(0.5, NTrialsInThisBlock, coin);       
    faceVectorThisBlock             = mixArray(faceVectorThisBlock)';
    faceVectorThisBlock(faceVectorThisBlock==2)     = 0;    % change to [0 | 1]
    
    % Make block trial number sequence
    trialNbThisBlock = 1:NTrialsInThisBlock;
    
    %% Add this block to the large sequence of trials for a whole run
    cue0PredictionSequence           = [cue0PredictionSequence; blockCue0Prediction]; 
    trialSequence                   = [trialSequence; trialvector];   % 1 valid, 2 invalid
    effectiveBlockProbabilities     = [effectiveBlockProbabilities; cueOutcomeProbEffective];
    desiredBlockProbabilities       = [desiredBlockProbabilities; cueOutcomeProbDesired];
    cueSequence                     = [cueSequence; cueVectorThisBlock];
    faceSequence                    = [faceSequence; faceVectorThisBlock];
    blockClassSequence              = [blockClassSequence; thisBlockClass * ones(NTrialsInThisBlock, 1)]; % 1 non-predictive, 2 predictive short, 3 predictive long
    blockVolatility                 = [blockVolatility; thisBlockVolatility * ones(NTrialsInThisBlock, 1)]; % 1 volatile, 0 stable
    reversalBlocksSequence          = [reversalBlocksSequence; blockIsAReversal];
    blockwiseTrialNumber            = [blockwiseTrialNumber, trialNbThisBlock];
    
    desiredProbByBlock(thisBlock)   = pHappyCue0;
    effectiveProbByBlock(thisBlock) = cueOutcomeProbEffective(1);
    
%% Set up stimulus jitter for this block, number of times to present each level
    NstimPerJitter                  = (NTrialsInThisBlock/NbStimJitterVals);     
    stimJitterRepsByBlock           = [stimJitterRepsByBlock, NstimPerJitter];
    
    if mod(NTrialsInThisBlock,NstimPerJitter) ~= 0
        disp('Warning! This block length is not divisible by 4!');
        disp([num2str(NTrialsInThisBlock)]);
        return;
    end
end

% Update cueProbabilityOutput matrix
cueProbabilityOutput(:,3)   = blockClassSequence;           % 1 non-predictive, 2 predictive short, 3 predictive long
cueProbabilityOutput(:,4)   = faceSequence;                 % face gender. 0 male, 1 female
cueProbabilityOutput(:,5)   = cueSequence;                  % cue. cue_0, cue_1
cueProbabilityOutput(:,6)   = trialSequence;                % 1 valid, 2 invalid
cueProbabilityOutput(:,7)   = desiredBlockProbabilities;    % target block probabilities
cueProbabilityOutput(:,8)   = effectiveBlockProbabilities;  % resulting block probabilities
cueProbabilityOutput(:,9)   = blockVolatility;              % 0 stable, 1 volatile
cueProbabilityOutput(:,12)  = cue0PredictionSequence;       %(is cue 0 predictive of Happy (1) or Angry (2) faces, on non-predictive(0)?)
cueProbabilityOutput(:,14)  = reversalBlocksSequence;
cueProbabilityOutput(:,15)  = blockwiseTrialNumber;

% Print some information about the generated sequence
disp(['Number of trials in sequence: ', num2str(length(trialSequence))]);
disp(['Block lengths (nTrials): ', num2str(blockLengths)]);
disp(['Desired block probabilities: ', num2str(desiredProbByBlock)]);
disp(['Effective block probabilities: ', num2str(effectiveProbByBlock)]);

% #### NB that some stimJitterRepsByBlock arent integers! #####
blockParams = [desiredProbByBlock ; effectiveProbByBlock; blockLengths; stimJitterRepsByBlock];


%% Mark trials by condition
% 1 cue_0 valid   2 cue_1 valid    3 cue_0 invalid    4 cue_1 invalid      5 non-predictive 
for trialsLoop = 1:NTrialsCheck                     % loop over all trials
    
    if cue0PredictionSequence(trialsLoop) == 1       % if we're in a block where cue_0 is predicting Happy and Cue_1 is predicting angry
    
        if trialSequence(trialsLoop) == 1               % [1]=valid trial 
            if cueSequence(trialsLoop) == 0             % cue 0 
                conditionSequence(trialsLoop) = 1;
                outcomeSequence(trialsLoop) = 1;        % Happy
            elseif cueSequence(trialsLoop) == 1
                conditionSequence(trialsLoop) = 2;
                outcomeSequence(trialsLoop) = 0;        % Angry
            end
        
        elseif trialSequence(trialsLoop) == 2           % [2]=invalid trial (Angry|cue_0)
            if cueSequence(trialsLoop) == 0             % cue 0 or cue 1
                conditionSequence(trialsLoop) = 3;
                outcomeSequence(trialsLoop) = 0;        % Angry
            elseif cueSequence(trialsLoop) == 1
                conditionSequence(trialsLoop) = 4;
                outcomeSequence(trialsLoop) = 1;        % Happy
            end
        end
        
% 1 cue_0 valid   2 cue_1 valid    3 cue_0 invalid    4 cue_1 invalid      5 non-predictive  
    elseif cue0PredictionSequence(trialsLoop) == 2       % if we're in a block where cue_0 is predicting Angry
        
        if trialSequence(trialsLoop) == 1               % [1]=valid trial 
            if cueSequence(trialsLoop) == 0             % cue 0 
                conditionSequence(trialsLoop) = 1;
                outcomeSequence(trialsLoop) = 0;        % Angry
            elseif cueSequence(trialsLoop) == 1         % cue 1
                conditionSequence(trialsLoop) = 2;
                outcomeSequence(trialsLoop) = 1;        % Happy
            end
        
        elseif trialSequence(trialsLoop) == 2           % [2]=invalid trial (Angry|cue_0)
            if cueSequence(trialsLoop) == 0             % cue 0 or cue 1
                conditionSequence(trialsLoop) = 3;
                outcomeSequence(trialsLoop) = 1;        % Happy
            elseif cueSequence(trialsLoop) == 1
                conditionSequence(trialsLoop) = 4;
                outcomeSequence(trialsLoop) = 0;        % Angry
            end
        end
        
    elseif cue0PredictionSequence(trialsLoop) == 0      % if we're in a non-predictive block (invalid)
        conditionSequence(trialsLoop) = 5;
        NPtrials(trialsLoop) = 1;
        if trialSequence(trialsLoop) == 1               % valid/invalid
            if cueSequence(trialsLoop) == 0             % cue 0 or cue 1
                outcomeSequence(trialsLoop) = 1;        % Happy
            elseif cueSequence(trialsLoop) == 1
                outcomeSequence(trialsLoop) = 0;        % Angry
            end
        elseif trialSequence(trialsLoop) == 2
            if cueSequence(trialsLoop) == 0             % cue 0 or cue 1
                outcomeSequence(trialsLoop) = 0;        % Angry
            elseif cueSequence(trialsLoop) == 1
                outcomeSequence(trialsLoop) = 1;        % Happy
            end
        end
        
        
    end % which world are we in

end%trialsLoop

%% Make a control matrix
controlMat = [cue0PredictionSequence, trialSequence, cueSequence, conditionSequence', outcomeSequence'];

% Add condition sequence, trial-by-trial outcomes, and non-predictive trials flag
cueProbabilityOutput(:,2)   = conditionSequence;        % 1 cue_0 valid   2 cue_1 valid    3 cue_0 invalid    4 cue_1 invalid      5 non-predictive 
cueProbabilityOutput(:,10) 	= outcomeSequence;          % 1 happy face, 0 angry face
cueProbabilityOutput(:,11) 	= NPtrials;                 % 1 non-predictive trial, 0 predictive trial



%% Add prediction trials (PTs)
PredEveryXTrials = vars.PredEveryXTrials;
predictionTrialNext = zeros(NTrialsCheck, 1);
predictionTrialNext(PredEveryXTrials : PredEveryXTrials : end) = 1;
cueProbabilityOutput(:,13) 	= predictionTrialNext;
figure, imagesc(cueProbabilityOutput(:,2:end-1));colorbar


%% Find & mark break point to place a break there
break1 = 1;
break2 = 1;
for thisBlock = 1:NBlocks_total
    trialsSoFar = sum(blockLengths(1:thisBlock));
    
    if break1 && (trialsSoFar >= breakAfterXTrials(1)) && (trialsSoFar ~= (length(trialSequence)))
        % Insert break after this block
        breaks = [breaks; trialsSoFar];
        break1 = 0;
    end
    
    if break2 && (trialsSoFar >= breakAfterXTrials(2)) && (trialsSoFar ~= (length(trialSequence)))
        % Insert break after this block
        breaks = [breaks; trialsSoFar];
        break2 = 0;
    end
end
breaks

%% Check: Do we have equal numbers of trials / condition?
Ntrials_cond1 = sum(logical(conditionSequence(conditionSequence==1)));
Ntrials_cond2 = sum(logical(conditionSequence(conditionSequence==2)));
Ntrials_cond3 = sum(logical(conditionSequence(conditionSequence==3)));
Ntrials_cond4 = sum(logical(conditionSequence(conditionSequence==4)));

%% Draw a little plot of the blocks in this sequence
% Colour groups prob type, line style groups cue
if plotSequence
    lineWidthA = 2;
    lineWidthB = 4;
    figure; title(gca,'Probability sequence'); hold on;
    
    % Plot effective probabilities
    plot(1:NTrialsTotal, effectiveBlockProbabilities, 'LineWidth', lineWidthA, 'Color', [0.6484 0.8047 0.8867]);      %[.85 .33 .1]
    plot(1:NTrialsTotal, 1-effectiveBlockProbabilities, '--', 'LineWidth', lineWidthA, 'Color', [0.6484 0.8047 0.8867]);
    % Plot desired (target) probabilities
    plot(1:NTrialsTotal, desiredBlockProbabilities, 'LineWidth', lineWidthA, 'Color', [0.1211 0.4688 0.7031]);       %[.49 .18 .56]
    plot(1:NTrialsTotal, 1-desiredBlockProbabilities, '--', 'LineWidth', lineWidthA, 'Color', [0.1211 0.4688 0.7031]);
    
    % Format
    box off
    ylim(gca,[0 1]);
    xlabel('Trial');
    ylabel('p(Happy)');
    legend('effective', '', 'desired', '');
    legend('boxoff');
    
end

disp(['Reversal blocks: ', num2str(reversalBlocks)]);
disp(['Number of reversals: ', num2str(sum(reversalBlocks))]);


save(fullfile(['sequence6_NEW2']), 'cueProbabilityOutput', 'blockParams', 'breaks');
end