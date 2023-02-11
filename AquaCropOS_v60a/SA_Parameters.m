function [Soilprofile,Soil,CropMix,Crop,Irr,FieldMngtStruct,SoilHydro,IniWC] = SA_Parameters()
%% For Rice , by Qi 2020/8/21
%% SoilProfile.txt %%
comp_n = [1:12]'; % Compartment
comp_thick = [0.1;0.1;0.1;0.1;0.1;0.1;0.1;0.1;0.1;0.1;0.1;0.1]; % Thickness(m)
comp_layer = [1;1;1;1;1;1;2;2;2;2;2;2]; % Layer
Soilprofile = {comp_n,comp_thick,comp_layer}; 

%% Soil.txt %% 8 parameters
Soil = struct();
Soil.CalcSHP = 0; % Calculate soil hydraulic properties (0 = No, 1 = Yes) 
Soil.Zsoil = 2; % Total thickness of soil profile (m)
Soil.nComp = 12; % Total number of soil compartments
Soil.nLayer = 2; % Total number of soil layers
Soil.AdjREW = 1; % Adjust default value for readily evaporable water (0 = No, 1 = Yes)  # changed
Soil.REW = 10; % Readily evaporable water (mm) (only used if adjusting from default value)
Soil.CN = 77; % Curve number
Soil.zRes = -999; % Depth of restrictive soil layer (set to negative value if not present) 
Soil.fwcc = 50; % Maximum coefficient for soil evaporation reduction due to sheltering effect of withered canopy

%% CropMix.txt %%
CropMix = struct();
CropMix.nCrops = 1; % Number of crop types to be simulated
CropMix.Rotation = {'N'}; % Specified crop rotation calendar (Y or N)
CropMix.RotationFilename = {'N/A'}; % Crop rotation filename
CropMix.CropInfo = {{'RiceGDD'},{'RiceGDD.txt'}}; % CropType   CropFilename

%% Crop(RiceGDD in here).txt %%  59 parameters
Crop = struct();
Crop.(CropMix.CropInfo{1,1}{1}).CropType = 3; % Crop Type (1 = Leafy vegetable, 2 = Root/tuber, 3 = Fruit/grain)
Crop.(CropMix.CropInfo{1,1}{1}).PlantMethod = 0; % Planting method (0 = Transplanted, 1 =  Sown)
Crop.(CropMix.CropInfo{1,1}{1}).CalendarType = 2; % Calendar Type (1 = Calendar days, 2 = Growing degree days)
Crop.(CropMix.CropInfo{1,1}{1}).SwitchGDD = 1; % Convert calendar to GDD mode if inputs are given in calendar days (0 = No; 1 = Yes)
Crop.(CropMix.CropInfo{1,1}{1}).PlantingDate = 'N/A'; % Planting Date (dd/mm)
Crop.(CropMix.CropInfo{1,1}{1}).HarvestDate = 'N/A'; % Latest Harvest Date (dd/mm)
Crop.(CropMix.CropInfo{1,1}{1}).Emergence = 50; % Growing degree/Calendar days from sowing to emergence/transplant recovery
Crop.(CropMix.CropInfo{1,1}{1}).MaxRooting = 370; % Growing degree/Calendar days from sowing to maximum rooting
Crop.(CropMix.CropInfo{1,1}{1}).Senescence = 1300; % Growing degree/Calendar days from sowing to senescence
Crop.(CropMix.CropInfo{1,1}{1}).Maturity = 1900; % Growing degree/Calendar days from sowing to maturity
Crop.(CropMix.CropInfo{1,1}{1}).HIstart = 1150; % Growing degree/Calendar days from sowing to start of yield formation
Crop.(CropMix.CropInfo{1,1}{1}).Flowering = 350; % Duration of flowering in growing degree/calendar days (-999 for non-fruit/grain crops)
Crop.(CropMix.CropInfo{1,1}{1}).YldForm = 680; % Duration of yield formation in growing degree/calendar days
Crop.(CropMix.CropInfo{1,1}{1}).GDDmethod = 2; % Growing degree day calculation method
Crop.(CropMix.CropInfo{1,1}{1}).Tbase = 8; % Base temperature (degC) below which growth does not progress
Crop.(CropMix.CropInfo{1,1}{1}).Tupp = 30; % Upper temperature (degC) above which crop development no longer increases
Crop.(CropMix.CropInfo{1,1}{1}).PolHeatStress = 1; % Pollination affected by heat stress (0 = No, 1 = Yes)
Crop.(CropMix.CropInfo{1,1}{1}).Tmax_up = 35; % Maximum air temperature (degC) above which pollination begins to fail
Crop.(CropMix.CropInfo{1,1}{1}).Tmax_lo = 45; % Maximum air temperature (degC) at which pollination completely fails  # unchange
Crop.(CropMix.CropInfo{1,1}{1}).PolColdStress = 1; % Pollination affected by cold stress (0 = No, 1 = Yes)
Crop.(CropMix.CropInfo{1,1}{1}).Tmin_up = 8; % Minimum air temperature (degC) below which pollination begins to fail
Crop.(CropMix.CropInfo{1,1}{1}).Tmin_lo = 5; % Minimum air temperature (degC) at which pollination completely fails  # unchange
Crop.(CropMix.CropInfo{1,1}{1}).TrColdStress = 1; % Transpiration affected by cold temperature stress (0 = No, 1 = Yes) 
Crop.(CropMix.CropInfo{1,1}{1}).GDD_up = 10; % Minimum growing degree days (degC/day) required for full crop transpiration potential
Crop.(CropMix.CropInfo{1,1}{1}).GDD_lo = 0; % Growing degree days (degC/day) at which no crop transpiration occurs  # unchange
Crop.(CropMix.CropInfo{1,1}{1}).Zmin = 0.3; % Minimum effective rooting depth (m)
Crop.(CropMix.CropInfo{1,1}{1}).Zmax = 0.5; % Maximum rooting depth (m)
Crop.(CropMix.CropInfo{1,1}{1}).fshape_r = 2.5; % Shape factor describing root expansion  # something wrong, 25 in aquacrop6.1
Crop.(CropMix.CropInfo{1,1}{1}).SxTopQ = 0.048; % Maximum root water extraction at top of the root zone (m3/m3/day)
Crop.(CropMix.CropInfo{1,1}{1}).SxBotQ = 0.012; % Maximum root water extraction at the bottom of the root zone (m3/m3/day)
Crop.(CropMix.CropInfo{1,1}{1}).SeedSize = 6.0; % Soil surface area (cm2) covered by an individual seedling at 90% emergence
Crop.(CropMix.CropInfo{1,1}{1}).PlantPop = 1000000; % Number of plants per hectare
Crop.(CropMix.CropInfo{1,1}{1}).CCx = 0.95; % Maximum canopy cover (fraction of soil cover)
Crop.(CropMix.CropInfo{1,1}{1}).CDC = 0.005003; % Canopy decline coefficient (fraction per GDD/calendar day)
Crop.(CropMix.CropInfo{1,1}{1}).CGC = 0.007004; % Canopy growth coefficient (fraction per GDD)
Crop.(CropMix.CropInfo{1,1}{1}).Kcb = 1.1; % Crop coefficient when canopy growth is complete but prior to senescence
Crop.(CropMix.CropInfo{1,1}{1}).fage = 0.15; % Decline of crop coefficient due to ageing (%/day)
Crop.(CropMix.CropInfo{1,1}{1}).WP = 19.0; % Water productivity normalized for ET0 and C02 (g/m2)
Crop.(CropMix.CropInfo{1,1}{1}).WPy = 100; % Adjustment of water productivity in yield formation stage (% of WP)
Crop.(CropMix.CropInfo{1,1}{1}).fsink = 50; % Crop performance under elevated atmospheric CO2 concentration (%)
Crop.(CropMix.CropInfo{1,1}{1}).HI0 = 0.43; % Reference harvest index
Crop.(CropMix.CropInfo{1,1}{1}).dHI_pre = 0; % Possible increase of harvest index due to water stress before flowering (%)
Crop.(CropMix.CropInfo{1,1}{1}).a_HI = 10; % Coefficient describing positive impact on harvest index of restricted vegetative growth during yield formation 
Crop.(CropMix.CropInfo{1,1}{1}).b_HI = 7; % Coefficient describing negative impact on harvest index of stomatal closure during yield formation 
Crop.(CropMix.CropInfo{1,1}{1}).dHI0 = 15; % Maximum allowable increase of harvest index above reference value
Crop.(CropMix.CropInfo{1,1}{1}).Determinant = 1; % Crop Determinancy (0 = Indeterminant, 1 = Determinant) 
Crop.(CropMix.CropInfo{1,1}{1}).exc = 100; % Excess of potential fruits
Crop.(CropMix.CropInfo{1,1}{1}).p_up1 = 0; % Upper soil water depletion threshold for water stress effects on affect canopy expansion 
Crop.(CropMix.CropInfo{1,1}{1}).p_up2 = 0.5; % Upper soil water depletion threshold for water stress effects on canopy stomatal control
Crop.(CropMix.CropInfo{1,1}{1}).p_up3 = 0.55; % Upper soil water depletion threshold for water stress effects on canopy senescence 
Crop.(CropMix.CropInfo{1,1}{1}).p_up4 = 0.75; % Upper soil water depletion threshold for water stress effects on canopy pollination 
Crop.(CropMix.CropInfo{1,1}{1}).p_lo1 = 0.4; % Lower soil water depletion threshold for water stress effects on canopy expansion 
Crop.(CropMix.CropInfo{1,1}{1}).p_lo2 = 1; % Lower soil water depletion threshold for water stress effects on canopy stomatal control   # unchange
Crop.(CropMix.CropInfo{1,1}{1}).p_lo3 = 1; % Lower soil water depletion threshold for water stress effects on canopy senescence   # unchange
Crop.(CropMix.CropInfo{1,1}{1}).p_lo4 = 1; % Lower soil water depletion threshold for water stress effects on canopy pollination   # unchange
Crop.(CropMix.CropInfo{1,1}{1}).fshape_w1 = 3; % Shape factor describing water stress effects on canopy expansion 
Crop.(CropMix.CropInfo{1,1}{1}).fshape_w2 = 3; % Shape factor describing water stress effects on stomatal control 
Crop.(CropMix.CropInfo{1,1}{1}).fshape_w3 = 3; % Shape factor describing water stress effects on canopy senescence 
Crop.(CropMix.CropInfo{1,1}{1}).fshape_w4 = 2.7; % Shape factor describing water stress effects on pollination   # unchange

%% IrrigationManagement.txt %%  10 parameters
Irr = struct();
Irr.IrrMethod = 0; % Irrigation scheduling method (0 = Rainfed; 1 = Soil moisture based; 2 = Fixed interval; 3 = Specified time series; 4 = Net calculation)
Irr.IrrInterval = 3; % Irrigation interval in days (only used if irrigation method is equal to 2)
Irr.SMT1 = 70; % Soil moisture target in 1st growth stage (% of TAW below which irrigation is triggered)
Irr.SMT2 = 70; % Soil moisture target in 2nd growth stage (% of TAW below which irrigation is triggered)
Irr.SMT3 = 70; % Soil moisture target in 3rd growth stage (% of TAW below which irrigation is triggered)
Irr.SMT4 = 70; % Soil moisture target in 4th growth stage (% of TAW below which irrigation is triggered)
Irr.MaxIrr = 25; % Maximum irrigation depth (mm/day)
Irr.AppEff = 90; % Irrigation application efficiency (%)
Irr.NetIrrSMT = 80; % Net irrigation threshold moisture level (% of TAW that will be maintained)
Irr.WetSurf = 100; % Soil surface wetted by irrigation (%)

%% FieldManagement.txt %% 9 parameters
FieldMngtStruct = struct();
FieldMngtStruct.(CropMix.CropInfo{1,1}{1}).Mulches = 'N'; % Soil surface covered by mulches (Y or N)
FieldMngtStruct.(CropMix.CropInfo{1,1}{1}).Bunds = 'Y'; % Surface bunds present (Y or N)
FieldMngtStruct.(CropMix.CropInfo{1,1}{1}).CNadj = 'N'; % Field conditions affect curve number (Y or N)  # unchange
FieldMngtStruct.(CropMix.CropInfo{1,1}{1}).SRinhb = 'Y'; % Management practices fully inhibit surface runoff (Y or N)
FieldMngtStruct.(CropMix.CropInfo{1,1}{1}).MulchPct = 0; % Area of soil surface covered by mulches growing season (%)
FieldMngtStruct.(CropMix.CropInfo{1,1}{1}).fMulch = 0.5; % Soil evaporation adjustment factor due to effect of mulches
FieldMngtStruct.(CropMix.CropInfo{1,1}{1}).zBund = 0.2; % Bund height (m)
FieldMngtStruct.(CropMix.CropInfo{1,1}{1}).BundWater = 0; % Initial water height in surface bunds (mm)
FieldMngtStruct.(CropMix.CropInfo{1,1}{1}).CNadjPct = 0; % Percentage change in curve number (positive or negative)  # unchange
% off-season
FieldMngtStruct.Fallow = FieldMngtStruct.(CropMix.CropInfo{1,1}{1});

%% SoilHydrology.txt %% 6 parameters
SoilHydro = struct();
SoilHydro.dz = [0.5,1.5]; % Thickness(m)
SoilHydro.th_s = [0.54,0.55]; % thS(m3/m3) 
SoilHydro.th_fc = [0.50,0.54]; % thFC(m3/m3)
SoilHydro.th_wp = [0.32,0.39]; % thWP(m3/m3)
SoilHydro.Ksat = [15,2]; % Ksat(mm/day)
SoilHydro.Penetrability = [100,100]; % Penetrability(%)

%% InitialWaterContent.txt %% 
IniWC = struct();
IniWC.TypeStr = 'Prop'; % Type of value ('Prop' = 'WP'/'FC'/'SAT'; 'Num' = XXX m3/m3; 'Pct' = % TAW))
IniWC.MethodStr = 'Layer'; % Method ('Depth' = Interpolate depth points; 'Layer' = Constant value for each soil layer)
IniWC.Locs = [1;2]; % Depth/Layer
IniWC.Data_Pts = {IniWC.Locs,{'FC';'FC'}}; % Value
end