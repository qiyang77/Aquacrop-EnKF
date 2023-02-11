function [Ksa,NewCond] = AOS_AerationStress(Crop,InitCond,thRZ)
% Function to calculate aeration stress coefficient

%% Store initial conditions in new structure for updating %%
NewCond = InitCond;

%% Determine aeration stress (root zone) %%
if thRZ.Act > thRZ.Aer
    % Calculate aeration stress coefficient
    if NewCond.AerDays < Crop.LagAer
        stress = 1-((thRZ.S-thRZ.Act)/(thRZ.S-thRZ.Aer));
        Ksa.Aer = 1-((NewCond.AerDays/Crop.LagAer)*stress);    % modified by Qi 20/3/21, replaced the 3 to LagAer
    elseif NewCond.AerDays >= Crop.LagAer
        Ksa.Aer = (thRZ.S-thRZ.Act)/(thRZ.S-thRZ.Aer);
    end
    % Increment aeration days counter
    NewCond.AerDays = NewCond.AerDays+1;
    if NewCond.AerDays > Crop.LagAer
        NewCond.AerDays = Crop.LagAer;
    end
else
    % Set aeration stress coefficient to one (no stress value)
    Ksa.Aer = 1;
    % Reset aeration days counter
    NewCond.AerDays = 0;
end

end