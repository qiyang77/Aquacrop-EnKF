function [] = DA_ReInitializeTime(input,output,clock,currentParamStruct)
% Function to initialise AquaCrop-OS

%% Define global variables %% 
global AOS_ClockStruct
global AOS_InitialiseStruct

%% Clock.txt %% 3 parameters
sim_s = clock{1};
date_p = clock{2};
offseason = clock{3};

%% Weatherfile & WaterTable file %%
FileLocation = SA_FileLocation(input,output);
AOS_InitialiseStruct.input = input;
AOS_InitialiseStruct.FileLocation = FileLocation;

%% read parameters %%
[Soilprofile,Soil,CropMix,~,Irr,FieldMngtStruct,SoilHydro,IniWC] = SA_Parameters();
Crop = currentParamStruct.Crop;
%% Calculate sim end date and Read climate data %%
[sim_e,WeatherStruct] = SA_calSIM_END_by_GDD(FileLocation,Crop.(CropMix.CropInfo{1,1}{1}), sim_s);

%% Define model run time %%
AOS_ClockStruct = YQ_ReadClockParameters(sim_s, sim_e, offseason);
date_h = datestr(datenum(sim_e), 'dd/mm');

%% Read model parameter files %%
[ParamStruct,CropChoices] = SA_ReadModelParameters(Soil,Soilprofile,CropMix,Crop.(CropMix.CropInfo{1,1}{1}), date_p, date_h);
currentParamStruct.Crop.(CropMix.CropInfo{1,1}{1}).PlantingDate = ParamStruct.Crop.(CropMix.CropInfo{1,1}{1}).PlantingDate;    % modified by QI 2020/10/5
currentParamStruct.Crop.(CropMix.CropInfo{1,1}{1}).HarvestDate = ParamStruct.Crop.(CropMix.CropInfo{1,1}{1}).HarvestDate;
% save('bug1006-2.mat','AOS_ClockStruct','AOS_InitialiseStruct','ParamStruct','currentParamStruct')
ParamStruct = currentParamStruct;


%% Read irrigation management file %%
[IrrMngtStruct] = SA_ReadIrrigationManagement(ParamStruct,...
    Irr);

%% Read field management file %%
% discarded and replaced by Qi

%% Read groundwater table file %%
GwStruct = AOS_ReadGroundwaterTable(FileLocation);

%% Compute additional variables %%
ParamStruct = DA_ReComputeVariables(ParamStruct,WeatherStruct,...
    AOS_ClockStruct,GwStruct,CropChoices,FileLocation,SoilHydro);

%% Define initial conditions %%
InitCondStruct = SA_ReadModelInitialConditions(ParamStruct,GwStruct,...
    FieldMngtStruct,CropChoices,IniWC);

%% Pack output structure %%
AOS_InitialiseStruct = struct();
AOS_InitialiseStruct.Parameter = ParamStruct;
AOS_InitialiseStruct.IrrigationManagement = IrrMngtStruct;
AOS_InitialiseStruct.FieldManagement = FieldMngtStruct;
AOS_InitialiseStruct.Groundwater = GwStruct;
AOS_InitialiseStruct.InitialCondition = InitCondStruct;
AOS_InitialiseStruct.CropChoices = CropChoices;
AOS_InitialiseStruct.Weather = WeatherStruct;
AOS_InitialiseStruct.FileLocation = FileLocation;

%% Setup output files %%
% Define output file location

% Setup blank matrices to store outputs
AOS_InitialiseStruct.Outputs.WaterContents = zeros(...
    length(AOS_ClockStruct.TimeSpan),5+ParamStruct.Soil.nComp);
AOS_InitialiseStruct.Outputs.WaterContents(:,[4,6:end]) = -999;
AOS_InitialiseStruct.Outputs.WaterFluxes = zeros(...
    length(AOS_ClockStruct.TimeSpan),22);                                   % modified by Qi 20/3/23
AOS_InitialiseStruct.Outputs.WaterFluxes(:,[4,6:end]) = -999;
AOS_InitialiseStruct.Outputs.CropGrowth = zeros(...
    length(AOS_ClockStruct.TimeSpan),16);                                  % modified by Qi 20/3/26
AOS_InitialiseStruct.Outputs.CropGrowth(:,[4,6:end]) = -999;
AOS_InitialiseStruct.Outputs.FinalOutput = cell(AOS_ClockStruct.nSeasons,8);
% Store dates in daily matrices
Dates = datevec(AOS_ClockStruct.TimeSpan);
AOS_InitialiseStruct.Outputs.WaterContents(:,1:3) = Dates(:,1:3);
AOS_InitialiseStruct.Outputs.WaterFluxes(:,1:3) = Dates(:,1:3);
AOS_InitialiseStruct.Outputs.CropGrowth(:,1:3) = Dates(:,1:3);
%% Initialize some stuff %% by Qi 2021-7-29
AOS_ClockStruct.PlantingDate_predefined = AOS_ClockStruct.PlantingDate;
AOS_InitialiseStruct.InitialCondition.HIref = 0;
end

