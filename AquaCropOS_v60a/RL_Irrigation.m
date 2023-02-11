function [NewCond,Irr] = RL_Irrigation(InitCond,action,Crop,Soil,...
    GrowingSeason,Rain,Runoff)
% Function to get irrigation depth for current day

%% Store intial conditions for updating %%
NewCond = InitCond;
        
%% Determine irrigation depth (mm/day) to be applied %%
if GrowingSeason == true
    % Calculate root zone water content and depletion
    [~,Dr,TAW,thRZ] = AOS_RootZoneWater(Soil,Crop,NewCond);
    % Use root zone depletions and TAW only for triggering irrigation
    Dr = Dr.Rz;
    TAW = TAW.Rz;

	% Determine adjustment for inflows and outflows on current day %
    if thRZ.Act > thRZ.FC
        rootdepth = max(InitCond.Zroot,Crop.Zmin);
        AbvFc = (thRZ.Act-thRZ.FC)*1000*rootdepth;
    else
        AbvFc = 0;
    end
    WCadj = InitCond.Tpot+InitCond.Epot-Rain+Runoff-AbvFc;
    
    % Update growth stage if it is first day of a growing season
    if NewCond.DAP == 1
        NewCond.GrowthStage = 1;
    end
    % Run irrigation depth calculation
    if action == 0 % no irrigation
        Irr = 0;
    
    elseif action == 1 % Irrigation 40 mm
        % Net irrigation calculation performed after transpiration, so
        % irrigation is zero here
        Irr = 40;
        
    else
        disp('Wrong action! Irr set to 0')
        Irr = 0;
    end
    % Update cumulative irrigation counter for growing season
    NewCond.IrrCum = NewCond.IrrCum+Irr;
elseif GrowingSeason == false
    % No irrigation outside growing season
    Irr = 0;
    NewCond.IrrCum = 0;
end

end

