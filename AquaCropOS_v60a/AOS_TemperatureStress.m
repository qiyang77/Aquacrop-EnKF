function [Kst] = AOS_TemperatureStress(Crop,Tmax,Tmin)
% Function to calculate temperature stress coefficients

%% Calculate temperature stress coefficients affecting crop pollination %%
% Get parameters for logistic curve
KsPol_up = 1;
KsPol_lo = 0.001;

% Calculate effects of heat stress on pollination
if Crop.PolHeatStress == 0
    % No heat stress effects on pollination
    Kst.PolH = 1;
elseif Crop.PolHeatStress == 1
    % Pollination affected by heat stress
    if Tmax <= Crop.Tmax_lo
        Kst.PolH = 1;
    elseif Tmax >= Crop.Tmax_up
        Kst.PolH = 0;
    else
        Trel = (Tmax-Crop.Tmax_lo)/(Crop.Tmax_up-Crop.Tmax_lo);
        Kst.PolH = (KsPol_up*KsPol_lo)/(KsPol_lo+(KsPol_up-KsPol_lo)...
            *exp(-Crop.fshape_b*(1-Trel)));
    end
end

% Calculate effects of cold stress on pollination
if Crop.PolColdStress == 0
    % No cold stress effects on pollination
    Kst.PolC = 1;
elseif Crop.PolColdStress == 1
    % Pollination affected by cold stress
    if Tmin >= Crop.Tmin_up
        Kst.PolC = 1;
    elseif Tmin <= Crop.Tmin_lo
        Kst.PolC = 0;
    else
        Trel = (Crop.Tmin_up-Tmin)/(Crop.Tmin_up-Crop.Tmin_lo);
        Kst.PolC = (KsPol_up*KsPol_lo)/(KsPol_lo+(KsPol_up-KsPol_lo)...
            *exp(-Crop.fshape_b*(1-Trel)));
    end
end

end

