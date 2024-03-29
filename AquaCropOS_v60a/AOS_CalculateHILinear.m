function [tSwitch,dHILin] = AOS_CalculateHILinear(Crop)
% Function to calculate time to switch to linear harvest index build-up,
% and associated linear rate of build-up. Only for fruit/grain crops.

%% Determine linear switch point %% 
% Initialise variables
ti = 0;
tmax = Crop.YldFormCD;
HIest = 0;
HIprev = Crop.HIini;
% Iterate to find linear switch point
% fprintf('HIest %.2f, HI0 %.2f, ti %.2f, tmax %.2f\n',HIest,Crop.HI0,ti,tmax);  % debug by Qi
% if isempty(tmax)
%     global AOS_ClockStruct
%     global AOS_InitialiseStruct
%     save('bug1006.mat','AOS_ClockStruct','AOS_InitialiseStruct')
% end
while (HIest <= Crop.HI0) && (ti < tmax)
    ti = ti+1;
    HInew = (Crop.HIini*Crop.HI0)/(Crop.HIini+(Crop.HI0-Crop.HIini)*...
        exp(-Crop.HIGC*ti));
    HIest = HInew+(tmax-ti)*(HInew-HIprev);
    HIprev = HInew;
end
tSwitch = ti-1;

%% Determine linear build-up rate %%
if tSwitch > 0
    HIest = (Crop.HIini*Crop.HI0)/(Crop.HIini+(Crop.HI0-Crop.HIini)*...
        exp(-Crop.HIGC*tSwitch));
else
    HIest = 0;
end
dHILin = (Crop.HI0-HIest)/(tmax-tSwitch);
    
end

