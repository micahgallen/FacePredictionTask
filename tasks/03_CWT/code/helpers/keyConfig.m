function [keys] = keyConfig()
%function [keys] = keyConfig()

% Set-up keyboard
KbName('UnifyKeyNames')
keys.Escape = KbName('ESCAPE');
keys.Space = KbName('3#');

% In scanner
keys.Trigger = KbName('5%');
% keys.Left = KbName('3#');
% keys.Right = KbName('4$');
keys.Left = KbName('1!');
keys.Right = KbName('4$');

% keys.Left = KbName('LeftArrow');
% keys.Right = KbName('RightArrow');

keys.One = KbName('1!');
keys.Two = KbName('2@');
keys.Three = KbName('3#');
keys.Four = KbName('4$');

end