function [smpl_num] = Counterbalance_img(output_path)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

% Check if Counterbalance file already exists

output_filename = 'Counterbalance.mat';
output_dir = fullfile(output_path, output_filename);

if isfile(output_dir)
    load(output_dir, 'smpl_array');
    disp('File exists')
else
    smpl_array = [0];
    disp('File does not exist')
end

% Create randomisation array and select from it

randomise_array = [1 2 3];
% randomise_array = randomise_array(find(randomise_array~=smpl_array));
randomise_array = randomise_array(~ismember(randomise_array, smpl_array));
smpl_num = randsample(randomise_array,1);
smpl_array(end+1) = smpl_num;
smpl_array = nonzeros(smpl_array);

save(output_dir, 'smpl_array')
