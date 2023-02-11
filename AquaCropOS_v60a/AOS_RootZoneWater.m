function [WrAct,Dr,TAW,thRZ] = AOS_RootZoneWater(Soil,Crop,InitCond)
% Function to calculate actual and total available water in the root
% zone at current time step

%% Calculate root zone water content and available water %%
% Compartments covered by the root zone
rootdepth = max(InitCond.Zroot,Crop.Zmin);
rootdepth = round((rootdepth*100))/100;
comp_sto = min(sum(Soil.Comp.dzsum<rootdepth)+1,Soil.nComp);
% Initialise counters
WrAct = 0;
WrS = 0;
WrFC = 0;
WrWP = 0;
WrDry = 0;
WrAer = 0;

for ii = 1:comp_sto
    % Specify layer
    layeri = Soil.Comp.Layer(ii);
    % Fraction of compartment covered by root zone
    if Soil.Comp.dzsum(ii) > rootdepth
        factor = 1-((Soil.Comp.dzsum(ii)-rootdepth)/Soil.Comp.dz(ii));
    else
        factor = 1;
    end
    % Actual water storage in root zone (mm)
    WrAct = WrAct+(factor*1000*InitCond.th(ii)*Soil.Comp.dz(ii));
    % Water storage in root zone at saturation (mm)
    WrS = WrS+(factor*1000*Soil.Layer.th_s(layeri)*Soil.Comp.dz(ii));
    % Water storage in root zone at field capacity (mm)
    WrFC = WrFC+(factor*1000*Soil.Layer.th_fc(layeri)*Soil.Comp.dz(ii));
    % Water storage in root zone at permanent wilting point (mm)
    WrWP = WrWP+(factor*1000*Soil.Layer.th_wp(layeri)*Soil.Comp.dz(ii)); 
    % Water storage in root zone at air dry (mm)
    WrDry = WrDry+(factor*1000*Soil.Layer.th_dry(layeri)*Soil.Comp.dz(ii));
    % Water storage in root zone at aeration stress threshold (mm)
    WrAer = WrAer+(factor*1000*(Soil.Layer.th_s(layeri)-(Crop.Aer/100))*Soil.Comp.dz(ii));
end

if WrAct < 0
    WrAct = 0;
end

% Calculate total available water (m3/m3)
TAW.Rz = max(WrFC-WrWP,0);
% Calculate soil water depletion (mm)
Dr.Rz = min(WrFC-WrAct,TAW.Rz);

% Actual root zone water content (m3/m3)
thRZ.Act = WrAct/(rootdepth*1000);
% Root zone water content at saturation (m3/m3)
thRZ.S = WrS/(rootdepth*1000);
% Root zone water content at field capacity (m3/m3)
thRZ.FC = WrFC/(rootdepth*1000);
% Root zone water content at permanent wilting point (m3/m3)
thRZ.WP = WrWP/(rootdepth*1000);
% Root zone water content at air dry (m3/m3)
thRZ.Dry = WrDry/(rootdepth*1000);
% Root zone water content at aeration stress threshold (m3/m3)
thRZ.Aer = WrAer/(rootdepth*1000);

%% Calculate top soil water content and available water %%
if rootdepth > Soil.zTop
    % Determine compartments covered by the top soil
    ztopdepth = Soil.zTop;
    ztopdepth = round((ztopdepth*100))/100;
    comp_sto = sum(Soil.Comp.dzsum<ztopdepth)+1;
    % Initialise counters
    WrAct_Zt = 0;
    WrFC_Zt = 0;
    WrWP_Zt = 0;
    % Calculate water storage in top soil
    for ii = 1:comp_sto
        % Specify layer
        layeri = Soil.Comp.Layer(ii);
        % Fraction of compartment covered by root zone
        if Soil.Comp.dzsum(ii) > ztopdepth
            factor = 1-((Soil.Comp.dzsum(ii)-ztopdepth)/Soil.Comp.dz(ii));
        else
            factor = 1;
        end
        % Actual water storage in top soil (mm)
        WrAct_Zt = WrAct_Zt+(factor*1000*InitCond.th(ii)*Soil.Comp.dz(ii));
        % Water storage in top soil at field capacity (mm)
        WrFC_Zt = WrFC_Zt+(factor*1000*Soil.Layer.th_fc(layeri)*Soil.Comp.dz(ii));
        % Water storage in top soil at permanent wilting point (mm)
        WrWP_Zt = WrWP_Zt+(factor*1000*Soil.Layer.th_wp(layeri)*Soil.Comp.dz(ii));
    end
    % Ensure available water in top soil is not less than zero
    if WrAct_Zt < 0
        WrAct_Zt = 0;
    end
    % Calculate total available water in top soil (m3/m3)
    TAW.Zt = max(WrFC_Zt-WrWP_Zt,0);
    % Calculate depletion in top soil (mm)
    Dr.Zt = min(WrFC_Zt-WrAct_Zt,TAW.Zt);
else
    % Set top soil depletions and TAW to root zone values
    Dr.Zt = Dr.Rz;
    TAW.Zt = TAW.Rz;
end

end

