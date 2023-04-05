%% example

% give me a

block_length = 56;
[trialvectorA, real_probabilityA] = create_trials(.75, block_length./2);
[trialvectorB, real_probabilityB] = create_trials(.75, block_length./2);

trial_matrix_a = [trialvectorA', ones(1,length(trialvectorA))'];

trial_matrix_b = [trialvectorB', ones(1,length(trialvectorA))'.*0];

block_order = [trial_matrix_a; trial_matrix_b];
shuff_vec = randn(1, length(block_order))

block_order = [block_order, shuff_vec']

block_order = sortrows(block_order, 3)