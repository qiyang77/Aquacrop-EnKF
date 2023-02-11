function [ParamStruct,CropChoices,FileLocation] = AOS_ReadModelParameters(FileLocation)
% Function to read input files and initialise soil and crop parameters

%% Define global variables %% 
global AOS_ClockStruct

%% Read input file location %%
Location = FileLocation.Input;

%% Read soil parameter input file %%
% Open file
filename = strcat(Location,FileLocation.SoilFilename);
fileID = fopen(filename);
if fileID == -1
    % Can't find text file defining soil parameters
    % Throw error message
    fprintf(2,'Error - Soil input file not found\n');
end
% Load data
DataArrayS = strtrim(textscan(fileID,'%s %*s',3,'delimiter',':','commentstyle','%%'));
DataArrayF = textscan(fileID,'%f %*s','delimiter',':','commentstyle','%%');
fclose(fileID);
varnames = {'CalcSHP';'Zsoil';'nComp';'nLayer';'AdjREW';'REW';'CN';'zRes'};
% Create assign string variables
FileLocation.SoilProfileFilename = DataArrayS{:}{1};
FileLocation.SoilTextureFilename = DataArrayS{:}{2};
FileLocation.SoilHydrologyFilename = DataArrayS{:}{3};
ParamStruct.Soil = cell2struct(num2cell(DataArrayF{:}),varnames);

% Assign default program properties (should not be changed without expert knowledge)
ParamStruct.Soil.EvapZsurf = 0.04; % Thickness of soil surface skin evaporation layer (m)
ParamStruct.Soil.EvapZmin = 0.15; % Minimum thickness of full soil surface evaporation layer (m)
ParamStruct.Soil.EvapZmax = 0.30; % Maximum thickness of full soil surface evaporation layer (m)
ParamStruct.Soil.Kex = 1.1; % Maximum soil evaporation coefficient
ParamStruct.Soil.fevap = 4; % Shape factor describing reduction in soil evaporation in stage 2.
ParamStruct.Soil.fWrelExp = 0.4; % Proportional value of Wrel at which soil evaporation layer expands
ParamStruct.Soil.fwcc = 50; % Maximum coefficient for soil evaporation reduction due to sheltering effect of withered canopy
ParamStruct.Soil.zCN = 0.3; % Thickness of soil surface (m) used to calculate water content to adjust curve number
ParamStruct.Soil.zGerm = 0.3; % Thickness of soil surface (m) used to calculate water content for germination
ParamStruct.Soil.AdjCN = 1; % Adjust curve number for antecedent moisture content (0: No, 1: Yes)
ParamStruct.Soil.fshape_cr = 16; % Capillary rise shape factor 
ParamStruct.Soil.zTop = 0.1; % Thickness of soil surface layer for water stress comparisons (m)

%% Read soil profile input file %%
% Open file
filename = strcat(Location,FileLocation.SoilProfileFilename);
fileID = fopen(filename);
if fileID == -1
    % Can't find text file defining soil profile
    % Throw error message
    fprintf(2,'Error - Soil profile input file not found\n');
end
% Load data
Data = textscan(fileID,'%f %f %f','headerlines',2);
fclose(fileID);
% Create vector of soil compartments sizes and associated layers
ParamStruct.Soil.Comp.dz = Data{1,2}(:)';
ParamStruct.Soil.Comp.dzsum = round(100*(cumsum(ParamStruct.Soil.Comp.dz)))/100;
ParamStruct.Soil.Comp.Layer = Data{1,3}(:)';

%% Read crop mix input file %%
filename = strcat(Location,FileLocation.CropFilename);
fileID = fopen(filename);
if fileID == -1
    % Can't find text file defining crop mix parameters
    % Throw error message
    fprintf(2,'Error - Crop mix input file not found\n');
end
% Number of crops
nCrops = cell2mat(textscan(fileID,'%f %*s',1,'delimiter',':','headerlines',1));
% Crop rotation filename
Rotation = strtrim(textscan(fileID,'%s %*s',1,'delimiter',':'));
% Crop rotation filename
RotationFilename = strtrim(textscan(fileID,'%s %*s',1,'delimiter',':'));
% Crop information (type and filename)
CropInfo = textscan(fileID,'%s %s %s %s',nCrops,'headerlines',3);
fclose(fileID);

%% Read crop parameter input files %%
% Create blank structure
ParamStruct.Crop = struct();
% Define variable names 
varnames = {'CropType';'PlantMethod';'CalendarType';'SwitchGDD';'PlantingDate';...
    'HarvestDate';'Emergence';'MaxRooting';'Senescence';'Maturity';...
    'HIstart';'Flowering';'YldForm';'GDDmethod';'Tbase';'Tupp';...
    'PolHeatStress';'Tmax_up';'Tmax_lo';'PolColdStress';'Tmin_up';...
    'Tmin_lo';'TrColdStress';'GDD_up';'GDD_lo';'Zmin';'Zmax';...
    'fshape_r';'SxTopQ';'SxBotQ';'SeedSize';'PlantPop';'CCx';'CDC';...
    'CGC';'Kcb';'fage';'WP';'WPy';'fsink';'HI0';'dHI_pre';'a_HI';'b_HI';...
    'dHI0';'Determinant';'exc';'p_up1';'p_up2';'p_up3';'p_up4';...
    'p_lo1';'p_lo2';'p_lo3';'p_lo4';'fshape_w1';'fshape_w2';'fshape_w3';...
    'fshape_w4'}; 

% Loop crop types
for ii = 1:nCrops
    % Open file
    filename = strcat(Location,CropInfo{1,2}{ii});
    fileID = fopen(filename);
    if fileID == -1
        % Can't find text file defining crop mix parameters
        % Throw error message
        fprintf(2,strcat('Error - Crop parameter input file, ',CropInfo{1,1}{ii},'not found\n'));
    end
    % Load data
    CropType = textscan(fileID,'%f %*s',1,'delimiter',':','headerlines',1);
    PlantMethod = textscan(fileID,'%f %*s',1,'delimiter',':'); 
    CalendarType = textscan(fileID,'%f %*s',1,'delimiter',':');
    SwitchGDD = textscan(fileID,'%f %*s',1,'delimiter',':');
    PlantingDateStr = textscan(fileID,'%s %*s',1,'delimiter',':');
    HarvestDateStr = textscan(fileID,'%s %*s',1,'delimiter',':');
    DataArray = textscan(fileID,'%f %*s','delimiter',':');
    fclose(fileID);
    % Create crop parameter structure
    ParamStruct.Crop.(CropInfo{1,1}{ii}) = cell2struct(num2cell(DataArray{1,1}),varnames(7:end));
    % Add additional parameters
    ParamStruct.Crop.(CropInfo{1,1}{ii}).CropType = cell2mat(CropType);
    ParamStruct.Crop.(CropInfo{1,1}{ii}).PlantMethod = cell2mat(PlantMethod);
    ParamStruct.Crop.(CropInfo{1,1}{ii}).CalendarType = cell2mat(CalendarType);
    ParamStruct.Crop.(CropInfo{1,1}{ii}).SwitchGDD = cell2mat(SwitchGDD);
    ParamStruct.Crop.(CropInfo{1,1}{ii}).PlantingDate = strtrim(PlantingDateStr{:}{:});
    ParamStruct.Crop.(CropInfo{1,1}{ii}).HarvestDate = strtrim(HarvestDateStr{:}{:});
    % Add irrigation management information
    ParamStruct.Crop.(CropInfo{1,1}{ii}).IrrigationFile = CropInfo{1,3}{ii};
    ParamStruct.Crop.(CropInfo{1,1}{ii}).FieldMngtFile = CropInfo{1,4}{ii};
    % Assign default program properties (should not be changed without expert knowledge)
    ParamStruct.Crop.(CropInfo{1,1}{ii}).fshape_b = 13.8135; % Shape factor describing the reduction in biomass production for insufficient growing degree days
    ParamStruct.Crop.(CropInfo{1,1}{ii}).PctZmin = 70; % Initial percentage of minimum effective rooting depth
    ParamStruct.Crop.(CropInfo{1,1}{ii}).fshape_ex = -6; % Shape factor describing the effects of water stress on root expansion
    ParamStruct.Crop.(CropInfo{1,1}{ii}).ETadj = 1; % Adjustment to water stress thresholds depending on daily ET0 (0 = No, 1 = Yes)
    ParamStruct.Crop.(CropInfo{1,1}{ii}).Aer = 0; % default 5, Vol (%) below saturation at which stress begins to occur due to deficient aeration
    ParamStruct.Crop.(CropInfo{1,1}{ii}).LagAer = -999; % default 3, Number of days lag before aeration stress affects crop growth
    ParamStruct.Crop.(CropInfo{1,1}{ii}).beta = 12; % Reduction (%) to p_lo3 when early canopy senescence is triggered
    ParamStruct.Crop.(CropInfo{1,1}{ii}).a_Tr = 1; % Exponent parameter for adjustment of Kcx once senescence is triggered
    ParamStruct.Crop.(CropInfo{1,1}{ii}).GermThr = 0.2; % Proportion of total water storage needed for crop to germinate
    ParamStruct.Crop.(CropInfo{1,1}{ii}).CCmin = 0.05; % Minimum canopy size below which yield formation cannot occur
    ParamStruct.Crop.(CropInfo{1,1}{ii}).MaxFlowPct = 100/3; % Proportion of total flowering time (%) at which peak flowering occurs
    ParamStruct.Crop.(CropInfo{1,1}{ii}).HIini = 0.01; % Initial harvest index
    ParamStruct.Crop.(CropInfo{1,1}{ii}).bsted = 0.000138; % WP co2 adjustment parameter given by Steduto et al. 2007
    ParamStruct.Crop.(CropInfo{1,1}{ii}).bface = 0.001165; % WP co2 adjustment parameter given by FACE experiments
end

%% Find planting and harvest dates %%
if (nCrops > 1) || (strcmp(Rotation{1,1},'Y'))
    % Crop rotation occurs during the simulation period
    % Open rotation time-series file
    filename = strcat(Location,RotationFilename{1,1}{1});
    fileID = fopen(filename);
    if fileID == -1
        % Can't find text file defining crop rotation
        % Throw error message
        fprintf(2,'Error - Crop rotation input file not found\n');
    end
    % Load data
    DataArray = textscan(fileID,'%s %s %s','headerlines',2);
    fclose(fileID);
    % Extract data
    PlantDates = datenum(DataArray{1,1},'dd/mm/yyyy');
    HarvestDates = datenum(DataArray{1,2},'dd/mm/yyyy');
    CropChoices = DataArray{1,3};
elseif nCrops == 1
    % Only one crop type considered during simulation - i.e. no rotations
    % either within or between yars
    % Get start and end years for full simulation
    SimStaDate = datevec(AOS_ClockStruct.SimulationStartDate);
    SimEndDate = datevec(AOS_ClockStruct.SimulationEndDate);
    % Get temporary crop structure
    CropTemp = ParamStruct.Crop.(CropInfo{1,1}{1});
    % Does growing season extend across multiple calendar years
    if datenum(CropTemp.PlantingDate,'dd/mm') < datenum(CropTemp.HarvestDate,'dd/mm')
        YrsPlant = SimStaDate(1):SimEndDate(1);
        YrsHarvest = YrsPlant;
    else
        YrsPlant = SimStaDate(1):SimEndDate(1)-1;
        YrsHarvest = SimStaDate(1)+1:SimEndDate(1);
    end
    % Correct for partial first growing season (may occur when simulating
    % off-season soil water balance)
    if datenum(strcat(CropTemp.PlantingDate,'/',num2str(YrsPlant(1))),...
            'dd/mm/yyyy') < AOS_ClockStruct.SimulationStartDate
        YrsPlant = YrsPlant(2:end);
        YrsHarvest = YrsHarvest(2:end);
    end
    % Define blank variables
    PlantDates = zeros(length(YrsPlant),1);
    HarvestDates = zeros(length(YrsHarvest),1);
    CropChoices = cell(length(YrsPlant),1);
    % Determine planting and harvest dates
    for ii = 1:length(YrsPlant)
        PlantDates(ii) = datenum(strcat(CropTemp.PlantingDate,'/',...
            num2str(YrsPlant(ii))),'dd/mm/yyyy');
        HarvestDates(ii) = datenum(strcat(CropTemp.HarvestDate,'/',...
            num2str(YrsHarvest(ii))),'dd/mm/yyyy');
        CropChoices{ii} = CropInfo{1,1}{1};
    end
end

%% Update clock parameters %%
% Store planting and harvest dates
AOS_ClockStruct.PlantingDate = PlantDates;
AOS_ClockStruct.HarvestDate = HarvestDates;
AOS_ClockStruct.nSeasons = length(PlantDates);
% Initialise growing season counter
if AOS_ClockStruct.StepStartTime == AOS_ClockStruct.PlantingDate(1) 
    AOS_ClockStruct.SeasonCounter = 1;
else
    AOS_ClockStruct.SeasonCounter = 0;
end

end