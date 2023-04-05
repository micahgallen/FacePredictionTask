function randomSample = takeRandSample(mean_value, upper_bound, lower_bound, ntrials)
%% function to create a random uniform distribution of values (e.g., seconds ITI)
% given three values (lower, mea, upper), take a random sample of ntrials
%
% Niia Nikolova 2020


ms_a = mean_value-lower_bound;
ms_b = mean_value+upper_bound;

% random sample with replacement
theSample = randsample([ms_a, mean_value, ms_b],ntrials,true);


randomSample = theSample(randperm(length(theSample)));


end

