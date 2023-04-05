function [keys] = keyConfigQueue()
%function [keys] = keyConfigQueue()

% Set-up keyboard
KbName('UnifyKeyNames')
keys.Escape = KbName('ESCAPE');
keys.Space = KbName('space');

% In scanner
keys.Trigger = KbName('5%');
% keys.Left = KbName('left_mouse');
% keys.Right = KbName('right_mouse');

% keys.Left = KbName('LeftArrow');
keys.Left = KbName('3#');
% keys.Right = KbName('RightArrow');
keys.Right = KbName('2@');

keys.keysOfInterest=zeros(1,256);
keys.keysOfInterest(keys.Trigger)=1;
keys.keysOfInterest(keys.Left)=1;
keys.keysOfInterest(keys.Right)=1;
keys.keysOfInterest(keys.Escape)=1;
keys.keysOfInterest(keys.Space)=1;
end