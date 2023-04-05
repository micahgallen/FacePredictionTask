function [cueProbabilityOutput, blockParams, breaks] = createCueProbabilities(vars)
% New improved version of setupCueProbabilities
%       
% [cueProbabilityOutput, blockParams, breaks] = createCueProbabilities(vars)
%
% Project: CWT task, for fMRI.
% Sets up a squenece of blocks of cue probabilities given some parameters. NB that each block type must be presented an equal number of times
%
% Input:  none
%
% Output:       cueProbabilityOutput matrix with 9 columns
%   1       trial #
%   2       condition           [1, 2, 3, 4]        % 1 cue_0 valid   2 cue_1 valid    3 cue_0 invalid    4 cue_1 invalid
%   3       block type          [1, 2, 3]           % 1 non-predictive, 2 predictive short, 3 predictive long
%   4       face gender         [0, 1]
%   5       cue                 [0, 1]
%   6       trial type          [1, 2]              % (Happy|cue_0) or (Angry|cue_0)
%   7       desired prob        
%   8       effective prob
%   9       block volatility    [0, 1]              % 1 volatile, 0 stable
%
%   breaks                   array or trial #s after which to pause the
%                            experiment
%
% Niia Nikolova
% Last edit: 14/07/2020             changing to output one matrixL trial # x trial info

plotSequence = 1;           % 1 plot block probabilities, 0 no plot

new_line;
disp('Determining trial sequence...');

% Desired parameters
trialDuration               = [8, 10];                      % in sec (min 8, max 10)
probabilitiesHappy          = [0.25, 0.75];
NProbLevels                 = length(probabilitiesHappy);   % + 0.5 for Non-predicitve blocks
NBlocks_2                   = 4;                            % NB predictive short blocks
NBlocks_3                   = 2;                            % NB predictive long blocks
NBlocks_Pred                = NBlocks_2 + NBlocks_3;        % NB predictive blocks
NBlocks_U                   = (NBlocks_Pred-1);             % NB non-predictive blocks
NBlocks_total               = NBlocks_Pred + (NBlocks_Pred-1);        % predicitve and unpredictive blocks
NGroups                     = 2;                            % each group consists of NBlocks/2 predictive blocks
NTrialsTotal                = vars.NTrialsTotal;%210;                          %310;

cueBlockLength_shortP       = 24;% short predictive block, +/-jitter    || 24, total for 6* short blocks = 144
cueBlockLength_longP        = 60;% long predictive block, +/-jitter     || 48, total for 2* long blocks  = 96
cueBlockLength_U            = 10;% unpredictive block, +/-jitter        || 10, total for 5* U blocks     = 50
jitter                      = 4; % block length jitter for predictive blocks
jitter_U                    = 2;

% How many levels of jitter do we have around the H and A face stimuli (2*Happy & 2*Angry = 4 total)
NbStimJitterVals             = vars.NMorphJitters;

% Set up breaks
NBreaks                     = 1;                        % Number of breaks for the participant
breakAfterXTrials           = NTrialsTotal/(NBreaks+1);

% Create some empty arrays
breaks                      = [];
isThisBlockPredictive       = repmat([1, 0], 1, ((NBlocks_total-1)/2)+1);
blockLengths                = [];                   % master block length array for this sequence
trialSequence               = [];
effectiveBlockProbabilities = [];
desiredBlockProbabilities   = [];
cueSequence                 = [];
faceSequence                = [];
blockTypeSequence           = [];
blockVolatility             = [];
conditionSequence           = NaN * ones(1,NTrialsTotal);   	% trial-by-trial condition vector
outcomeSequence             = NaN * ones(1,NTrialsTotal);   	% trial-by-trial outcome vector, i.e. 1 happy or  0 anggry
NPtrials                     = zeros(1,NTrialsTotal);            % vector marking any non-predictive trials by 1

% Set up output matrix
NRows                       = 9;                    % Number of rows we'll need
trialNb                     = [1:NTrialsTotal]';
cueProbabilityOutput        = NaN * ones(NTrialsTotal, NRows);
cueProbabilityOutput(:,1)   = trialNb;


%% Jitter the block lengths (long predictive, short predictive and unpredictive)
% Option A: If we want to add random jitter
% blockLengths_3    	= round(jitter_values(cueBlockLength_longP, jitter, jitter, NBlocks_3));        % Predictive long
% blockLengths_2        = round(jitter_values(cueBlockLength_shortP, jitter, jitter, NBlocks_2));       % Predictive short
% blockLengths_1    	= round(jitter_values(cueBlockLength_U, jitter, jitter, (NBlocks_Pred-1)));     % Non-predictive

% Option B: We want the black lengths to vary, but in a more controlled way
% controlled way - we restrict to mult of 4
% 1 non-predictive, 2 predictive short, 3 predictive long
blockLengths_3    	= round(jitter_values(cueBlockLength_longP, jitter, jitter, NBlocks_3));  
blockLengths_2      = [round(jitter_values(cueBlockLength_shortP, 0, jitter, NBlocks_2/2)), round(jitter_values(cueBlockLength_shortP, jitter, 0, NBlocks_2/2))];
blockLengths_1      = mixArray([cueBlockLength_U-jitter_U*ones(1, ceil(NBlocks_U/2)), cueBlockLength_U+jitter_U*ones(1, floor(NBlocks_U/2))]);
% blockLengths_1    	= round(jitter_values(cueBlockLength_U, jitter, jitter, NBlocks_U));

% Check if we get the # of trials we expect, print expected duration
NTrialsCheck        = sum(blockLengths_3) + sum(blockLengths_2) + sum(blockLengths_1);
% Break if we don't get the expected # of trials
if NTrialsCheck ~= NTrialsTotal
    disp('Unexpected # of trials.'); 
    disp(['Expected: ', num2str(NTrialsTotal)]); 
    disp(['Calculated: ', num2str(NTrialsCheck)]);
    return; 
end
expectedDurationMin = NTrialsCheck * trialDuration(1) / 60;
expectedDurationMax = NTrialsCheck * trialDuration(2) / 60;
% Pring expected duration
disp(['Expected run duration at ', num2str(trialDuration(1)), 's/trial: ', num2str(expectedDurationMin), ' min.']);
disp(['Expected run duration at ', num2str(trialDuration(2)), 's/trial: ', num2str(expectedDurationMax), ' min.']);


%% Create array of Cue-Outcome probabilities per *predictive* block
% 1 long/highP, 2 long/lowP, 3 short/highP, 4 short/lowP   [P(Happy|cue_0)]
% Make sure that we have 2 short block together, and the long blocks
% seperate (i.e. LSSLSS or SSLSSL)
predBlockTypesArray = [ones(1,NBlocks_3/2), 2*ones(1,NBlocks_3/2), 3*ones(1, NBlocks_2/2), 4*ones(1, NBlocks_2/2)];
shortPredBlockTypes = mixArray(predBlockTypesArray(3:6));
longPredBlockTypes = mixArray(predBlockTypesArray(1:2));
blockPlacementSitch = round(rand);                          % Switch to help us decide whether we'll start or end with a long block
if blockPlacementSitch                                      % start with LONG block
    predBlockTypes = [longPredBlockTypes(1), shortPredBlockTypes(1:2), longPredBlockTypes(2), shortPredBlockTypes(3:4)]; 
else                                                        % start with short block
    predBlockTypes = [shortPredBlockTypes(1:2), longPredBlockTypes(1), shortPredBlockTypes(3:4), longPredBlockTypes(2)];
end



% Reorder the blocks
% %   Remove sequential block type repeats
% for doThis = 1:2                            % Loop through twice
%     for thisBlock = 1:NBlocks_Pred-1
%         nextBlock = thisBlock + 1;
%         B_1 = predBlockTypes(thisBlock);
%         B_2 = predBlockTypes(nextBlock);
%         
%         % If two blocks are identical, move block 2 down and remove row
%         if eq(B_1,B_2)
%             if thisBlock == NBlocks_Pred-1 	% If the last two block are the same, move the last one to 1st position
%                 predBlockTypes = [B_2, predBlockTypes];
%                 predBlockTypes(nextBlock)=[];
%             else                            % Otherwise move the duplicate block to the end
%                 predBlockTypes = [predBlockTypes, B_2];
%                 predBlockTypes(nextBlock)=[];
%             end
%         end
%     end
% end

%   Organise into Groups?                           <--- SHOULD WE DO THIS??   ####


%% Create trials for each block
blockCounter_3          = 1;                % Predictive long
blockCounter_2          = 1;                % Predictive short
blockCounter_1          = 1;                % Non-predictive
predLoopCounter         = 1;
cueOutcomeProbDesired   = [];               % Target prob
cueOutcomeProbEffective = [];               % Effective prob
stimJitterRepsByBlock   = [];               % nb times to present each morph jittel level per block  

for thisBlock = 1:NBlocks_total                 % Loop over all blocks       
    
    if isThisBlockPredictive(thisBlock)         % Predictive block

        switch predBlockTypes(predLoopCounter)
            case 1  % long, highP
                NTrialsInThisBlock      = blockLengths_3(blockCounter_3);
                blockLengths            = [blockLengths, NTrialsInThisBlock];
                pHappy                  = probabilitiesHappy(2);
                thisBlockType           = 3;
                thisBlockVolatility     = 0;                        % 0 stable, 1 volatile
                blockCounter_3          = blockCounter_3 + 1;
            case 2  % long, lowP
                NTrialsInThisBlock      = blockLengths_3(blockCounter_3);
                blockLengths            = [blockLengths, NTrialsInThisBlock];
                pHappy                  = probabilitiesHappy(1);
                thisBlockType           = 3;
                thisBlockVolatility     = 0;                      
                blockCounter_3          = blockCounter_3 + 1;
            case 3  % short, highP
                NTrialsInThisBlock      = blockLengths_2(blockCounter_2);
                blockLengths            = [blockLengths, NTrialsInThisBlock];
                pHappy                  = probabilitiesHappy(2);
                thisBlockType           = 2;
                thisBlockVolatility     = 1;                        
                blockCounter_2          = blockCounter_2 + 1;
            case 4  % short, lowP
                NTrialsInThisBlock      = blockLengths_2(blockCounter_2);
                blockLengths            = [blockLengths, NTrialsInThisBlock];
                pHappy                  = probabilitiesHappy(1);
                thisBlockType           = 2;
                thisBlockVolatility     = 1;                     
                blockCounter_2 = blockCounter_2 + 1;
        end
        predLoopCounter = predLoopCounter + 1;
        
    else                                    % Non-predictive blocks
        NTrialsInThisBlock              = blockLengths_1(blockCounter_1);
        blockLengths                    = [blockLengths, NTrialsInThisBlock];
        pHappy                          = 0.5;
        thisBlockType                   = 1;
        thisBlockVolatility             = 1;                        % Non-predictive marked as volatile
        blockCounter_1                  = blockCounter_1 + 1;
    end
    
    
    %% Set up individual trials per block   
    cueOutcomeProbDesired           = [pHappy * ones(NTrialsInThisBlock, 1)];
    
    % Generate the trials for this block & shuffle them
    % trialvector   [1]= Happy|cue_0 (valid trial for predictive blocks)
    % [2]= Angry|cue_0 (invalid trial for predictive blocks), equal prob of
    % H or A for non-predictive blocks
    [trialvector, realProbability]  = create_trials(pHappy, blockLengths(thisBlock));
    trialvector                     = mixArray(trialvector)';
    
    cueOutcomeProbEffective         = [realProbability * ones(NTrialsInThisBlock, 1)];
    
    % Generate cues for this block & shuffle
    [cueVectorThisBlock, ~]         = create_trials(0.5, NTrialsInThisBlock);       % 50% prob of either of the two cues
    cueVectorThisBlock              = mixArray(cueVectorThisBlock)';
    cueVectorThisBlock(cueVectorThisBlock==2)       = 0;      % change to [0 | 1]
    
    % Generate face genders for this block & shuffle
    [faceVectorThisBlock, ~]        = create_trials(0.5, NTrialsInThisBlock);       % 50% prob of either of the two genders
    faceVectorThisBlock             = mixArray(faceVectorThisBlock)';
    faceVectorThisBlock(faceVectorThisBlock==2)     = 0;    % change to [0 | 1]
    
    % Add this block to the large sequence of trials for a whole run
    trialSequence                   = [trialSequence; trialvector];                 % [1]= Happy|cue_0  [2]= Angry|cue_0
    effectiveBlockProbabilities     = [effectiveBlockProbabilities; cueOutcomeProbEffective];
    desiredBlockProbabilities       = [desiredBlockProbabilities; cueOutcomeProbDesired];
    cueSequence                     = [cueSequence; cueVectorThisBlock];
    faceSequence                    = [faceSequence; faceVectorThisBlock];
    blockTypeSequence               = [blockTypeSequence; thisBlockType * ones(NTrialsInThisBlock, 1)];
    blockVolatility                 = [blockVolatility; thisBlockVolatility * ones(NTrialsInThisBlock, 1)];
    
    desiredProbByBlock(thisBlock)   = pHappy;
    effectiveProbByBlock(thisBlock) = realProbability;
    
%% Set up stimulus jitter for this block, number of times to present each level
    NstimPerJitter                  = (NTrialsInThisBlock/NbStimJitterVals);     
    stimJitterRepsByBlock           = [stimJitterRepsByBlock, NstimPerJitter];
    
    if mod(NTrialsInThisBlock,NstimPerJitter) ~= 0
        disp('Warning! This block length is not dicisible by 4!');
        disp([num2str(NTrialsInThisBlock)]);
        return;
    end
end

% Update cueProbabilityOutput matrix
cueProbabilityOutput(:,3)   = blockTypeSequence;
cueProbabilityOutput(:,4)   = faceSequence;
cueProbabilityOutput(:,5)   = cueSequence;
cueProbabilityOutput(:,6)   = trialSequence;
cueProbabilityOutput(:,7)   = desiredBlockProbabilities;
cueProbabilityOutput(:,8)   = effectiveBlockProbabilities;
cueProbabilityOutput(:,9)   = blockVolatility;

% Print some information about the generated sequence
disp(['Number of trials in sequence: ', num2str(length(trialSequence))]);
disp(['Block lengths (nTrials): ', num2str(blockLengths)]);
disp(['Desired block probabilities: ', num2str(desiredProbByBlock)]);
disp(['Effective block probabilities: ', num2str(effectiveProbByBlock)]);

% #### NB that some stimJitterRepsByBlock arent integers! #####
blockParams = [desiredProbByBlock ; effectiveProbByBlock; blockLengths; stimJitterRepsByBlock];

%% Mark trials by condition
% 1 cue_0 valid   2 cue_1 valid    3 cue_0 invalid    4 cue_1 invalid
for trialsLoop = 1:NTrialsCheck                     % loop over all trials
    
    if trialSequence(trialsLoop) == 1               % [1]=valid trial (Happy|cue_0)
        if cueSequence(trialsLoop) == 0             % cue 0 or cue 1
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
    
    if blockTypeSequence(trialsLoop) == 1
       NPtrials(trialsLoop) = 1;                     % Mark non-predictive trials in conditionSequence        
    end
end


cueProbabilityOutput(:,2)   = conditionSequence;        % 1 cue_0 valid   2 cue_1 valid    3 cue_0 invalid    4 cue_1 invalid
cueProbabilityOutput(:,10) 	= outcomeSequence;          % 1 happy face, 0 angry face
cueProbabilityOutput(:,11) 	= NPtrials;                 % 1 non-predictive trial, 0 predictive trial

%% Find & mark halfway point to place a break there
for thisBlock = 1:NBlocks_total
    trialsSoFar = sum(blockLengths(1:thisBlock));
    
    if (trialsSoFar >= breakAfterXTrials) && (trialsSoFar ~= (length(trialSequence)))
        % Insert break after this block
        breaks = trialsSoFar;
        break;
    end
end

%% NB Should we have equal numbers of trials / condition?
% E.g. sum(logical(conditionSequence(conditionSequence==1)))
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
    plot(1:NTrialsTotal, effectiveBlockProbabilities, 'LineWidth', lineWidthA, 'Color', [.85 .33 .1]);
    plot(1:NTrialsTotal, 1-effectiveBlockProbabilities, '--', 'LineWidth', lineWidthA, 'Color', [.85 .33 .1]);
    % Plot desired (target) probabilities
    plot(1:NTrialsTotal, desiredBlockProbabilities, 'LineWidth', lineWidthA, 'Color', [.49 .18 .56]);
    plot(1:NTrialsTotal, 1-desiredBlockProbabilities, '--', 'LineWidth', lineWidthA, 'Color', [.49 .18 .56]);
    
    % Format
    box off
    ylim(gca,[0 1]);
    xlabel('Trial');
    ylabel('p(Happy)');
    legend('effective', '', 'desired', '');
    legend('boxoff');
    
end

end