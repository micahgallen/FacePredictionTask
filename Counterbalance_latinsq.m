function [cbal] = Counterbalance_latinsq(subno_str, session_no_str) %, output_path)
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here

% output_filename = 'Counterbalance.mat';
% output_dir = fullfile(output_path, output_filename);

load('LatinSquare.mat', 'big_latin');

subno_str_end = subno_str(end-1:end);
session_no_str_end = session_no_str(end);

if strcmp(subno_str_end(end-1),'0')
    disp('starts with a zero')
    rowno = str2num(subno_str_end(end));
else
    disp('doesn''t start with a zero')
    rowno = (str2num(subno_str_end));
end

session_no = str2num(session_no_str_end);

cbal = big_latin(rowno, session_no);

smpl_array = big_latin(rowno, 1:session_no);

% save(output_dir, 'smpl_array')

end