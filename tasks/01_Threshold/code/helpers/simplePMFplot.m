function simplePMFplot(stair)
% function simplePMFplot(stair)
%
% Make a simple pmf plot based Psi adaptive staircase data
%
% Project: Face Affect Discrimination (FAD) Task, part of CWT
%
% Niia Nikolova
% Last edit: 16/07/2020

% stair.PM = stair.F.PM;

% Threshold estimate by trial
figure;
subplot(2,1,1);

t = 1:length(stair.PM.x)-1;               % trial #
plot(t,stair.PM.x(1:length(t)),'wo',...
    'MarkerSize',8,...
    'MarkerEdgeColor','r',...
    'MarkerFaceColor',[1 1 1]);
hold on
plot(1:length(t),stair.PM.threshold,'r-','LineWidth',2)

% Add axis labels
hold on
title('Presented Stimuli & Threshold Estimate by Trial');
axis([0 (length(stair.PM.x)+5) 0 200]);
xlabel('Trial number','fontsize',12);
ylabel('Morph (A->H)','fontsize',12);

%% PMF
subplot(2,1,2,'align');
title('PsiAdaptive PMF fit');
hold on
% SL stim levels, NP num positive, OON out of num
[SL, NP, OON] = PAL_PFML_GroupTrialsbyX(stair.PM.x(1:length(stair.PM.x)-1),stair.PM.response,ones(size(stair.PM.response)));
for SR = 1:length(SL(OON~=0))
    plot(SL(SR),NP(SR)/OON(SR),'ko','markerfacecolor','k','markersize',20*sqrt(OON(SR)./sum(OON)))
end
axis([20 180 0 1]);

% plot
plot([min(stair.stimRange):.01:max(stair.stimRange)], stair.PF([stair.PM.threshold(length(stair.PM.threshold)) 10.^stair.PM.slope(length(stair.PM.threshold)) 0 stair.PM.lapse(length(stair.PM.threshold))],min(stair.stimRange):.01:max(stair.stimRange)),'r-','linewidth',2)

xlabel('intensity (\itx\rm)','fontsize',12);
ylabel('\psi(\itx\rm; \alpha, \beta, \gamma, \lambda)','fontsize',12);
% text(min(stair.stimRange)+(max(stair.stimRange)-min(stair.stimRange))/4, .75,'Bayes fit','color','r','Fontsize',14)
set(gca,'ytick',[0:.25:1]);

drawnow

% Get the stim levels at which participant performane is .3 .5 and .7
pptPMFvals = [stair.PM.threshold(length(stair.PM.threshold)) 10.^stair.PM.slope(length(stair.PM.threshold)) 0 stair.PM.lapse(length(stair.PM.threshold))];
inversePMFvals = [0.3, 0.5, 0.7];
inversePMFstims = stair.PF(pptPMFvals, inversePMFvals, 'inverse');
inversePMFstims = round(inversePMFstims,2);

end