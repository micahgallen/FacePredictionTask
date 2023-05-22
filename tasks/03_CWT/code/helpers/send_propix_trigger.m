function [] = send_propix_trigger(doTrig, message)
%send_propix_trigger Function to send propix trigger
%   Takes a numeric "message" as input - 0 to close

if doTrig

    Datapixx('SetDoutValues', message); % get propix ready, trigger code 4
    Datapixx('RegWrVideoSync'); % send propix trigger on next flip

else

    disp('Note: Propix Triggers are Currently Disabled')

end

end