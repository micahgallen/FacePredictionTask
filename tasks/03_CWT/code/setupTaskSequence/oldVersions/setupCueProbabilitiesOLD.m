function [trialSequence, cueSequence, faceSequence, conditionSequence, breaks, desiredBlockProbabilities, effectiveBlockProbabilities, blockLengths] = setupCueProbabilities()
% #### OLD VERSION = ONLY HERE FOR REFERENCE!
%
%[trialSequence, cueSequence, faceSequence, conditionSequence, breaks, desiredBlockProbabilities, effectiveBlockProbabilities, blockLengths] = function setupCueProbabilities()
%
% Project: CWT task, for fMRI.
% Sets up a squenece of blocks of cue probabilities given some parameters. NB that each block type must be presented an equal number of times
%
% Input:  none
%
% Output:
%   trialSequence [1, 2]     valid (Happy|cue_0) or invalid (Angry|cue_0) trial
%   cueSequence   [0, 1]     cue to be presented
%   faceSequence  [0, 1]     gender of face to be presented
%   conditionSequence        1 cue_0 valid   2 cue_1 valid    3 cue_0 invalid    4 cue_1 invalid
%   breaks                   array or trial #s after which to pause the
%                            experiment
%
% Niia Nikolova
% Last edit: 13/07/2020             added plot of probablitlies, and conditionSequence to output

disp('OLD VERSION OF setupCueProbabilities! Do not use!!');
pause

plotSequence = 1;                   % 1 plot block probabilities, 0 no plot

new_line;
disp('Determining trial sequence...');

% Set cue probablilities. vars.cueProbablitly = P(Happy|cue_0)
trialDuration       = [8, 10];                      % in sec (min 8, max 10)
probabilitiesHappy  = [0.25, 0.75];
NProbLevels         = length(probabilitiesHappy);   % + 0.5 for Non-predicitve blocks
NBlocks_long        = 2;
NBlocks_short       = 4;                            %6;
NBlocks             = NBlocks_long + NBlocks_short;
NBlocks_total       = NBlocks + (NBlocks-1);    % predicitve and unpredictive blocks
NGroups             = 2;                        % each group consists of NBlocks/2 predictive blocks
NTrialsTotal        = 210;%310;

cueBlockLength_shortP   = 20;% short predictive block, +/-jitter    || 24, total for 6* short blocks = 144
cueBlockLength_longP    = 40;% long predictive block, +/-jitter     || 48, total for 2* long blocks  = 96
cueBlockLength_U        = 10;% unpredictive block, +/-jitter        || 10, total for 5* U blocks     = 50
jitter                  = 4; %3

NBreaks                 = 1; % Number of breaks for the participant
breakAfterXTrials       = NTrialsTotal/(NBreaks+1);
breaks                  = [];

isThisBlockPredictive   = repmat([1, 0], 1, ((NBlocks_total-1)/2)+1);   % alternating 0 and 1
blockLengths            = [];                           % master block length array for this sequence
trialSequence           = [];
effectiveBlockProbabilities = [];
desiredBlockProbabilities   = [];

cueSequence     = [];
faceSequence    = [];
conditionSequence = NaN * ones(1,NTrialsTotal);         % trial-by-trial condition vector

cueProbabilityOutput = [];

%% Create arrays for P and U block lengths
blockLengths_3 = round(jitter_values(cueBlockLength_longP, jitter, jitter, NBlocks_long));
blockLengths_2 = round(jitter_values(cueBlockLength_shortP, jitter, jitter, NBlocks_short));
blockLengths_1 = round(jitter_values(cueBlockLength_U, jitter, jitter, (NBlocks-1)));

% check if we get the # of trials we expect, print expected duration
NTrialsCheck = sum(blockLengths_3) + sum(blockLengths_2) + sum(blockLengths_1);
if NTrialsCheck ~= NTrialsTotal
    disp('Unexpected # of trials.'); return; end
expectedDurationMin = NTrialsCheck * trialDuration(1) / 60;
expectedDurationMax = NTrialsCheck * trialDuration(2) / 60;
disp(['Expected run duration at ', num2str(trialDuration(1)), 's/trial: ', num2str(expectedDurationMin), ' min.']);
disp(['Expected run duration at ', num2str(trialDuration(2)), 's/trial: ', num2str(expectedDurationMax), ' min.']);


%% Create array of Cue-Outcome probabilities per *predictive* block
% 1 long/highP, 2 long/lowP, 3 short/highP, 4 short/lowP   [P(Happy|cue_0)]
predBlockTypes = [ones(1,NBlocks_long/2), 2*ones(1,NBlocks_long/2), 3*ones(1, NBlocks_short/2), 4*ones(1, NBlocks_short/2)];
predBlockTypes = mixArray(predBlockTypes);

% We want to remove sequential duplicate blocks
for doThis = 1:2                        % Loop through twice
    for thisBlock = 1:NBlocks-1
        nextBlock = thisBlock + 1;
        Stim_1 = predBlockTypes(thisBlock);
        Stim_2 = predBlockTypes(nextBlock);
        
        % if two blocks are identical, move Stim_2 down and remove row
        if eq(Stim_1,Stim_2)
            if thisBlock == NBlocks-1   % If the last two block are the same, move the last one to 1st position
                predBlockTypes = [Stim_2, predBlockTypes];
                predBlockTypes(nextBlock)=[];
            else                        % Otherwise move the duplicate block to the end
                predBlockTypes = [predBlockTypes, Stim_2];
                predBlockTypes(nextBlock)=[];
            end
        end
    end
end

%% Create trials for each block
blockCounter_3          = 1;                % Predictive long
blockCounter_2          = 1;                % Predictive short
blockCounter_1          = 1;                % Non-predictive
predLoopCounter         = 1;
cueOutcomeProbDesired   = [];               % Target prob
cueOutcomeProbEffective = [];               % Effective prob

for thisBlock = 1:NBlocks_total                 % Loop over all blocks       
    
    if isThisBlockPredictive(thisBlock)         % Predictive block
        
        switch predBlockTypes(predLoopCounter)
            case 1  % long, highP
                NTrialsInThisBlock = blockLengths_3(blockCounter_3);
                blockLengths = [blockLengths, NTrialsInThisBlock];
                pHappy = probabilitiesHappy(2);
                blockCounter_3 = blockCounter_3 + 1;
            case 2  % long, lowP
                NTrialsInThisBlock = blockLengths_3(blockCounter_3);
                blockLengths = [blockLengths, NTrialsInThisBlock];
                pHappy = probabilitiesHappy(1);
                blockCounter_3 = blockCounter_3 + 1;
            case 3  % short, highP
                NTrialsInThisBlock = blockLengths_2(blockCounter_2);
                blockLengths = [blockLengths, NTrialsInThisBlock];
                pHappy = probabilitiesHappy(2);
                blockCounter_2 = blockCounter_2 + 1;
            case 4  % short, lowP
                NTrialsInThisBlock = blockLengths_2(blockCounter_2);
                blockLengths = [blockLengths, NTrialsInThisBlock];
                pHappy = probabilitiesHappy(1);
                blockCounter_2 = blockCounter_2 + 1;
        end
        predLoopCounter = predLoopCounter + 1;
        
    else                                    % Non-predictive blocks
        NTrialsInThisBlock = blockLengths_1(blockCounter_1);
        blockLengths = [blockLengths, NTrialsInThisBlock];
        pHappy = 0.5;
        blockCounter_1 = blockCounter_1 + 1;
    end
    
    %% Fill in our arrays and the output matrix
    cueOutcomeProbDesired = [cueOutcomeProbDesired, pHappy * ones(1, NTrialsInThisBlock)];
    
    % Generate the trials for this block & shuffle them
    % trialvector   [1]=valid trial (Happy|cue_0)        [2]=invalid trial (Angry|cue_0)
    [trialvector, realProbability] = create_trials(pHappy, blockLengths(thisBlock));
    trialvector = mixArray(trialvector);
    
    cueOutcomeProbEffective = [cueOutcomeProbEffective, realProbability * ones(1, NTrialsInThisBlock)];
    
    % Generate cues for this block & shuffle
    [cueVectorThisBlock, ~] = create_trials(0.5, NTrialsInThisBlock);
    cueVectorThisBlock = mixArray(cueVectorThisBlock);
    cueVectorThisBlock(cueVectorThisBlock==2) = 0;      % change to [0 | 1]
    
    % Generate face genders for this block & shuffle
    [faceVectorThisBlock, ~] = create_trials(0.5, NTrialsInThisBlock);
    faceVectorThisBlock = mixArray(faceVectorThisBlock);
    faceVectorThisBlock(faceVectorThisBlock==2) = 0;    % change to [0 | 1]
    
    % Add this block to the large sequence of trials for a while run
    trialSequence = [trialSequence, trialvector];
    effectiveBlockProbabilities = [effectiveBlockProbabilities, realProbability];
    desiredBlockProbabilities = [desiredBlockProbabilities, pHappy];
    cueSequence = [cueSequence, cueVectorThisBlock];
    faceSequence = [faceSequence, faceVectorThisBlock];
    
end

disp(['Number of trials in sequence: ', num2str(length(trialSequence))]);
disp(['Block lengths (nTrials): ', num2str(blockLengths)]);
disp(['Desired block probabilities: ', num2str(desiredBlockProbabilities)]);
disp(['Effective block probabilities: ', num2str(effectiveBlockProbabilities)]);

% Mark trials by condition
% 1 cue_0 valid   2 cue_1 valid    3 cue_0 invalid    4 cue_1 invalid
for trialsLoop = 1:NTrialsCheck                     % loop over all trials
    
    if trialSequence(trialsLoop) == 1               % [1]=valid trial (Happy|cue_0)
        if cueSequence(trialsLoop) == 0              % cue 0 or cue 1
            conditionSequence(trialsLoop) = 1;
        elseif cueSequence(trialsLoop) == 1
            conditionSequence(trialsLoop) = 2;
        end
        
    elseif trialSequence(trialsLoop) == 2           % [2]=invalid trial (Angry|cue_0)
        if cueSequence(trialsLoop) == 0              % cue 0 or cue 1
            conditionSequence(trialsLoop) = 3;
        elseif cueSequence(trialsLoop) == 1
            conditionSequence(trialsLoop) = 4;
        end
    end
end

% Find & mark halfway point to place a break there
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



%% Draw a little plot of the blocks in this sequence
% Colour groups prob type, line style groups cue
if plotSequence
    lineWidthA = 2;
    lineWidthB = 4;
    figure; title(gca,'Probability sequence'); hold on;
    
    % Plot effective probabilities
    plot(1:NTrialsTotal, cueOutcomeProbEffective, 'LineWidth', lineWidthA, 'Color', [.85 .33 .1]);
    plot(1:NTrialsTotal, 1-cueOutcomeProbEffective, '--', 'LineWidth', lineWidthA, 'Color', [.85 .33 .1]);
    % Plot desired (target) probabilities
    plot(1:NTrialsTotal, cueOutcomeProbDesired, 'LineWidth', lineWidthA, 'Color', [.49 .18 .56]);
    plot(1:NTrialsTotal, 1-cueOutcomeProbDesired, '--', 'LineWidth', lineWidthA, 'Color', [.49 .18 .56]);
    
    % Format
    box off
    ylim(gca,[0 1]);
    xlabel('Trial');
    ylabel('p(Happy)');
    legend('effective', '', 'desired', '');
    legend('boxoff');
    
end
end