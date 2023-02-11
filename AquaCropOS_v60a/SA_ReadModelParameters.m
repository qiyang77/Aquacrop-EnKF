function [ParamStruct,CropChoices] = SA_ReadModelParameters(Soil,Soilprofile,CropMix,Crop, date_p, date_h)
% Function to read input files and initialise soil and crop parameters

%% Define global variables %% 
global AOS_ClockStruct

%% Read soil parameter input file %%

ParamStruct.Soil = Soil;

% Assign default program properties (should not be changed without expert knowledge)
ParamStruct.Soil.EvapZsurf = 0.04; % Thickness of soil surface skin evaporation layer (m)
ParamStruct.Soil.EvapZmin = 0.15; % Minimum thickness of full soil surface evaporation layer (m)
ParamStruct.Soil.EvapZmax = 0.30; % Maximum thickness of full soil surface evaporation layer (m)
ParamStruct.Soil.Kex = 1.1; % Maximum soil evaporation coefficient
ParamStruct.Soil.fevap = 4; % Shape factor describing reduction in soil evaporation in stage 2.
ParamStruct.Soil.fWrelExp = 0.4; % Proportional value of Wrel at which soil evaporation layer expands
% ParamStruct.Soil.fwcc = 50; % moved to SA_Parameters.m . Maximum coefficient for soil evaporation reduction due to sheltering effect of withered canopy
ParamStruct.Soil.zCN = 0.3; % Thickness of soil surface (m) used to calculate water content to adjust curve number
ParamStruct.Soil.zGerm = 0.3; % Thickness of soil surface (m) used to calculate water content for germination
ParamStruct.Soil.AdjCN = 1; % Adjust curve number for antecedent moisture content (0: No, 1: Yes)
ParamStruct.Soil.fshape_cr = 16; % Capillary rise shape factor 
ParamStruct.Soil.zTop = 0.1; % Thickness of soil surface layer for water stress comparisons (m)

%% Read soil profile input file %%
% Create vector of soil compartments sizes and associated layers
ParamStruct.Soil.Comp.dz = Soilprofile{1,2}(:)';
ParamStruct.Soil.Comp.dzsum = round(100*(cumsum(ParamStruct.Soil.Comp.dz)))/100;
ParamStruct.Soil.Comp.Layer = Soilprofile{1,3}(:)';

%% Read crop mix input file %%
% Number of crops
nCrops = CropMix.nCrops;
% Crop rotation filename
Rotation = CropMix.Rotation;
% Crop rotation filename
RotationFilename = CropMix.RotationFilename;
% Crop information (type and filename)
CropInfo = CropMix.CropInfo;

%% Read crop parameter input files %%
% Create blank structure
ParamStruct.Crop = struct();

% Loop crop types
for ii = 1:nCrops
    
    PlantingDateStr = {date_p};
    HarvestDateStr = {date_h};
    % Create crop parameter structure
    ParamStruct.Crop.(CropInfo{1,1}{ii}) = Crop;
    ParamStruct.Crop.(CropInfo{1,1}{ii}).PlantingDate = strtrim(PlantingDateStr{:});    %  revised by Qi
    ParamStruct.Crop.(CropInfo{1,1}{ii}).HarvestDate = strtrim(HarvestDateStr{:});
    % Add irrigation management information
%     ParamStruct.Crop.(CropInfo{1,1}{ii}).IrrigationFile = CropInfo{1,3}{ii};
%     ParamStruct.Crop.(CropInfo{1,1}{ii}).FieldMngtFile = CropInfo{1,4}{ii};
    % Assign default program properties (should not be changed without expert knowledge)
    ParamStruct.Crop.(CropInfo{1,1}{ii}).fshape_b = 13.8135; % Shape factor describing the reduction in biomass production for insufficient growing degree days
    ParamStruct.Crop.(CropInfo{1,1}{ii}).PctZmin = 70; % Initial percentage of minimum effective rooting depth
    ParamStruct.Crop.(CropInfo{1,1}{ii}).fshape_ex = -6; % Shape factor describing the effects of water stress on root expansion
    ParamStruct.Crop.(CropInfo{1,1}{ii}).ETadj = 1; % Adjustment to water stress thresholds depending on daily ET0 (0 = No, 1 = Yes)
    ParamStruct.Crop.(CropInfo{1,1}{ii}).Aer = 0; % default 5, Vol (%) below saturation at which stress begins to occur due to deficient aeration
    ParamStruct.Crop.(CropInfo{1,1}{ii}).LagAer = -999; % default 3, Number of days lag before aeration stress affects crop growth
    ParamStruct.Crop.(CropInfo{1,1}{ii}).LagCold = 3; % default 3, Number of days lag before crop freezing to death              % added by Qi 2021/3/10
    ParamStruct.Crop.(CropInfo{1,1}{ii}).Tfreeze = 12; % default 12, degree of crop freezing              % added by Qi 2021/3/10
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