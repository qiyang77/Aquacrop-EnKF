function [CCXadj,CDCadj] = AOS_UpdateCCxCDC(CCprev,CDC,CCx,dt)
% Function to update CCx and CDC parameter valyes for rewatering in late
% season of an early declining canopy

%% Get adjusted CCx %%
CCXadj = CCprev/(1-0.05*(exp(dt*((CDC*3.33)/(CCx+2.29)))-1));

%% Get adjusted CDC %%
CDCadj = CDC*((CCXadj+2.29)/(CCx+2.29));

end

