function [CC] = AOS_CCDevelopment(CCo,CCx,CGC,CDC,dt,Mode,CCx0)
% Function to calculate canopy cover development by end of the current
% simulation day

%% Initialise output %%
CC = [];

%% Calculate new canopy cover %%
if strcmp(Mode,'Growth')
    % Calculate canopy growth
    % Exponential growth stage
    CC = CCo*exp(CGC*dt);
    if CC > (CCx/2)
        % Exponential decay stage
        CC = CCx-0.25*(CCx/CCo)*CCx*exp(-CGC*dt);
    end
    % Limit CC to CCx
    if CC > CCx
        CC = CCx;
    end 
elseif strcmp(Mode,'Decline')
    % Calculate canopy decline
    if CCx < 0.001
        CC = 0;
    else
        CC = CCx*(1-0.05*(exp(dt*CDC*3.33/(CCx0+2.29))-1)); % modified by Qi 2020/9/2
        % CC = CCx*(1-0.05*(exp(dt*CDC*3.33*((CCx+2.29)/(CCx0+2.29))/(CCx+2.29))-1));
        % Origin code (CCx+2.29)/(CCx+2.29) make no sense commented by QI
        
    end
end

%% Limit canopy cover to between 0 and 1 %%
if CC > 1
    CC = 1;
elseif CC < 0
    CC = 0;
end

end

