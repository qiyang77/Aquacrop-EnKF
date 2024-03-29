function [NewCond] = AOS_HIadjPostAnthesis(InitCond,Crop,Ksw)
% Function to calculate adjustment to harvest index for post-anthesis water
% stress

%% Store initial conditions in a structure for updating %%
NewCond = InitCond;

%% Calculate harvest index adjustment %%
% 1. Adjustment for leaf expansion
tmax1 = Crop.CanopyDevEndCD-Crop.HIstartCD;
DAP = NewCond.DAP-InitCond.DelayedCDs;
if (DAP <= (Crop.CanopyDevEndCD+1)) && (tmax1 > 0) &&...
        (NewCond.Fpre > 0.99) && (NewCond.CC > 0.001) &&...
        (Crop.a_HI > 0)
    dCor = (1+(1-Ksw.Exp)/Crop.a_HI);
%     NewCond.sCor1 = InitCond.sCor1+(dCor/tmax1);   
    NewCond.sCor1 = InitCond.sCor1+dCor;   % modified by QI,divide tmax1 seems no use,2021-7-29
    DayCor = DAP-1-Crop.HIstartCD;
    NewCond.dCor1_list(DayCor) = dCor;  % added by Qi 2021-7-29, to record the history of dCor1
%     NewCond.fpost_upp = (tmax1/DayCor)*NewCond.sCor1;
    NewCond.fpost_upp = (1/DayCor)*NewCond.sCor1;   % modified by QI,divide tmax1 seems no use,2021-7-29
end

% 2. Adjustment for stomatal closure
tmax2 = Crop.YldFormCD;
DAP = NewCond.DAP-InitCond.DelayedCDs;
if (DAP <= (Crop.HIendCD+1)) && (tmax2 > 0) &&...
        (NewCond.Fpre > 0.99) && (NewCond.CC > 0.001) &&...
        (Crop.b_HI > 0)
    dCor = (exp(0.1*log(Ksw.Sto)))*(1-(1-Ksw.Sto)/Crop.b_HI);
%     NewCond.sCor2 = InitCond.sCor2+(dCor/tmax2);
    NewCond.sCor2 = InitCond.sCor2+dCor;  % modified by QI,divide tmax2 seems no use,2021-7-29
    DayCor = DAP-1-Crop.HIstartCD;
    NewCond.dCor2_list(DayCor) = dCor;  % added by Qi 2021-7-29, to record the history of dCor2
%     NewCond.fpost_dwn = (tmax2/DayCor)*NewCond.sCor2;
    NewCond.fpost_dwn = (1/DayCor)*NewCond.sCor2; % modified by QI,divide tmax2 seems no use,2021-7-29
end

% Determine total multiplier
if (tmax1 == 0) && (tmax2 == 0)
    NewCond.Fpost = 1;
else
    if tmax2 == 0
        NewCond.Fpost = NewCond.fpost_upp;
    else
        if tmax1 == 0
            NewCond.Fpost = NewCond.fpost_dwn;
        elseif tmax1 <= tmax2
            NewCond.Fpost = NewCond.fpost_dwn*(((tmax1*NewCond.fpost_upp)+...
                (tmax2-tmax1))/tmax2);
        else
            NewCond.Fpost = NewCond.fpost_upp*(((tmax2*NewCond.fpost_dwn)+...
                (tmax1-tmax2))/tmax1);
        end
    end
end
% fprintf('DAP:%d,tmax1:%.2f,tmax2:%.2f, fpost_upp:%.4f, fpost_dwn:%.4f, sCor1:%.3f, sCor2:%.3f,DayCor:%d,dCor:%.5f\n',...
%     NewCond.DAP,tmax1,tmax2,NewCond.fpost_upp,NewCond.fpost_dwn,NewCond.sCor1,NewCond.sCor2,DayCor,dCor)    
end

