function displayTooSlowMessage(scr)
%function displayTooSlowMessage(scr)
%
% Display a message in case of a slow response
%
% Project: CWT task, for fMRI.
%
% Input:
%   scr (struct)
%
% Micah Allen
% Last edit: 02/05/2023

%
    % Set the color of the message to red
    messageColor = [255, 0, 0];

    % Set the message text
    messageText = 'Too slow! Try to respond faster please.';

    % Display the message
    Screen('FillRect', scr.win, scr.BackgroundGray, scr.winRect);
    DrawFormattedText(scr.win, messageText, 'center', 'center', messageColor);

    % Flip the screen to show the message
    Screen('Flip', scr.win);

    % Optionally, you can add a pause so that the message is displayed for a certain amount of time before the program continues
    WaitSecs(.5);  % adjust the duration as needed

    % Clear the screen after the message has been shown
    Screen('FillRect', scr.win, scr.BackgroundGray, scr.winRect);
    Screen('Flip', scr.win);

end
