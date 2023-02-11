function [Soil,Crop,SoilHydro] = SA_Parameters_tune(Soil,Crop,CropMix,SoilHydro,para)
%% For Rice , by Qi 2020/8/21
%% Soil.txt %% 
Soil.CN = para(1); % Curve number

%% SoilHydrology.txt %% 6 parameters
SoilHydro.th_s = [para(2),para(3)]; % thS(m3/m3) 
SoilHydro.th_fc = [para(4),para(5)]; % thFC(m3/m3)
SoilHydro.th_wp = [para(6),para(7)]; % thWP(m3/m3)
SoilHydro.Ksat = [para(8),para(9)]; % Ksat(mm/day)
Soil.REW = para(10); % Readily evaporable water (mm) (only used if adjusting from default value)

%% Crop(RiceGDD in here).txt %%  59 parameters %%
%% Canopy and phenological development 11 parameters + 
Crop.(CropMix.CropInfo{1,1}{1}).Emergence = para(11); % Growing degree/Calendar days from sowing to emergence/transplant recovery
Crop.(CropMix.CropInfo{1,1}{1}).HIstart = para(12); % Growing degree/Calendar days from sowing to start of yield formation
Crop.(CropMix.CropInfo{1,1}{1}).Senescence = para(13); % Growing degree/Calendar days from sowing to senescence
Crop.(CropMix.CropInfo{1,1}{1}).Maturity = para(14); % Growing degree/Calendar days from sowing to maturity
Crop.(CropMix.CropInfo{1,1}{1}).YldForm = para(15); % Duration of yield formation in growing degree/calendar days
Crop.(CropMix.CropInfo{1,1}{1}).Flowering = para(16); % Duration of flowering in growing degree/calendar days (-999 for non-fruit/grain crops)
Crop.(CropMix.CropInfo{1,1}{1}).SeedSize = para(17); % Soil surface area (cm2) covered by an individual seedling at 90% emergence
Crop.(CropMix.CropInfo{1,1}{1}).PlantPop = para(18); % Number of plants per hectare
Crop.(CropMix.CropInfo{1,1}{1}).CGC = para(19); % Canopy growth coefficient (fraction per GDD)
Crop.(CropMix.CropInfo{1,1}{1}).CCx = para(20); % Maximum canopy cover (fraction of soil cover)
Crop.(CropMix.CropInfo{1,1}{1}).CDC = para(21); % Canopy decline coefficient (fraction per GDD/calendar day)
% in addition
Crop.(CropMix.CropInfo{1,1}{1}).Tbase = para(22); % Base temperature (degC) below which growth does not progress
Crop.(CropMix.CropInfo{1,1}{1}).Tupp = para(23); % Upper temperature (degC) above which crop development no longer increases

%% Root development
Crop.(CropMix.CropInfo{1,1}{1}).MaxRooting = para(24); % Growing degree/Calendar days from sowing to maximum rooting
Crop.(CropMix.CropInfo{1,1}{1}).Zmax = para(25); % Maximum rooting depth (m)
Crop.(CropMix.CropInfo{1,1}{1}).Zmin = para(26); % Minimum effective rooting depth (m)
Crop.(CropMix.CropInfo{1,1}{1}).fshape_r = para(27); % Shape factor describing root expansion  # something wrong, 25 in aquacrop6.1
Crop.(CropMix.CropInfo{1,1}{1}).SxTopQ = para(28); % Maximum root water extraction at top of the root zone (m3/m3/day)
Crop.(CropMix.CropInfo{1,1}{1}).SxBotQ = para(29); % Maximum root water extraction at the bottom of the root zone (m3/m3/day)

%% Transpiration
Crop.(CropMix.CropInfo{1,1}{1}).Kcb = para(30); % Crop coefficient when canopy growth is complete but prior to senescence
Crop.(CropMix.CropInfo{1,1}{1}).fage = para(31); % Decline of crop coefficient due to ageing (%/day)
Soil.fwcc = para(32); % Maximum coefficient for soil evaporation reduction due to sheltering effect of withered canopy

%% Production
Crop.(CropMix.CropInfo{1,1}{1}).WP = para(33); % Water productivity normalized for ET0 and C02 (g/m2)
Crop.(CropMix.CropInfo{1,1}{1}).HI0 = para(34); % Reference harvest index
Crop.(CropMix.CropInfo{1,1}{1}).exc = para(35); % Excess of potential fruits
Crop.(CropMix.CropInfo{1,1}{1}).WPy = para(36); % Adjustment of water productivity in yield formation stage (% of WP)

%% Water and temperature stresses
Crop.(CropMix.CropInfo{1,1}{1}).p_up1 = para(37); % Upper soil water depletion threshold for water stress effects on affect canopy expansion 
Crop.(CropMix.CropInfo{1,1}{1}).p_lo1 = para(38); % Lower soil water depletion threshold for water stress effects on canopy expansion
Crop.(CropMix.CropInfo{1,1}{1}).fshape_w1 = para(39); % Shape factor describing water stress effects on canopy expansion 
Crop.(CropMix.CropInfo{1,1}{1}).p_up2 = para(40); % Upper soil water depletion threshold for water stress effects on canopy stomatal control
Crop.(CropMix.CropInfo{1,1}{1}).fshape_w2 = para(41); % Shape factor describing water stress effects on stomatal control 
Crop.(CropMix.CropInfo{1,1}{1}).p_up3 = para(42); % Upper soil water depletion threshold for water stress effects on canopy senescence
Crop.(CropMix.CropInfo{1,1}{1}).fshape_w3 = para(43); % Shape factor describing water stress effects on canopy senescence 
Crop.(CropMix.CropInfo{1,1}{1}).p_up4 = para(44); % Upper soil water depletion threshold for water stress effects on canopy pollination 
Crop.(CropMix.CropInfo{1,1}{1}).dHI_pre = para(45); % Possible increase of harvest index due to water stress before flowering (%)
Crop.(CropMix.CropInfo{1,1}{1}).a_HI = para(46); % Coefficient describing positive impact on harvest index of restricted vegetative growth during yield formation 
Crop.(CropMix.CropInfo{1,1}{1}).b_HI = para(47); % Coefficient describing negative impact on harvest index of stomatal closure during yield formation 
Crop.(CropMix.CropInfo{1,1}{1}).dHI0 = para(48); % Maximum allowable increase of harvest index above reference value
Crop.(CropMix.CropInfo{1,1}{1}).Tmin_up = para(49); % Minimum air temperature (degC) below which pollination begins to fail
Crop.(CropMix.CropInfo{1,1}{1}).Tmax_up = para(50); % Maximum air temperature (degC) above which pollination begins to fail
Crop.(CropMix.CropInfo{1,1}{1}).Tmin_lo = para(51); % Minimum air temperature (degC) at which pollination completely fails  # unchange
Crop.(CropMix.CropInfo{1,1}{1}).Tmax_lo = para(52); % Maximum air temperature (degC) at which pollination completely fails  # unchange
Crop.(CropMix.CropInfo{1,1}{1}).GDD_up = para(53); % Minimum growing degree days (degC/day) required for full crop transpiration potential

end