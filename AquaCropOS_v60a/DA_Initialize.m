function [] = DA_Initialize(input,output,clock)
% Function to initialise AquaCrop-OS

%% Define global variables %% 
global AOS_ClockStruct
global AOS_InitialiseStruct

%% Get file locations %%
FileLocation = DA_ReadFileLocations(input,output);

%% Define model run time %%
sim_s = clock{1};
date_p = clock{2};
offseason = clock{3};
% pre-calculate GDD to define sim_e 
sim_e = DA_calSIM_END_by_GDD(FileLocation, sim_s);
disp(sim_e)
sim_e='2001-06-30';
AOS_ClockStruct = DA_ReadClockParameters(sim_s, sim_e, offseason);
date_h = datestr(datenum(sim_e), 'dd/mm');
%% Read climate data %%
WeatherStruct = AOS_ReadWeatherInputs(FileLocation);

%% Read model parameter files %%
[ParamStruct,CropChoices,FileLocation] = DA_ReadModelParameters(FileLocation, date_p, date_h);

%% Read irrigation management file %%
[IrrMngtStruct,FileLocation] = AOS_ReadIrrigationManagement(ParamStruct,...
    FileLocation);

%% Read field management file %%
FieldMngtStruct = AOS_ReadFieldManagement(ParamStruct,FileLocation);

%% Read groundwater table file %%
GwStruct = AOS_ReadGroundwaterTable(FileLocation);

%% Compute additional variables %%
ParamStruct = AOS_ComputeVariables(ParamStruct,WeatherStruct,...
    AOS_ClockStruct,GwStruct,CropChoices,FileLocation);

%% Define initial conditions %%
InitCondStruct = AOS_ReadModelInitialConditions(ParamStruct,GwStruct,...
    FieldMngtStruct,CropChoices,FileLocation);

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
FileLoc = FileLocation.Output;
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

if strcmp(AOS_InitialiseStruct.FileLocation.WriteDaily,'Y')
    % Water contents (daily)
    names = cell(1,ParamStruct.Soil.nComp);
    for ii = 1:ParamStruct.Soil.nComp
        z = ParamStruct.Soil.Comp.dzsum(ii)-(ParamStruct.Soil.Comp.dz(ii)/2);
        names{ii} = strcat(num2str(z),'m');
    end
    fid = fopen(strcat(FileLoc,FileLocation.OutputFilename,'_WaterContents.txt'),'w+t');
    fprintf(fid,strcat('%-10s%-10s%-10s%-10s%-10s',repmat('%-15s',1,...
        ParamStruct.Soil.nComp),'\n'),'Year','Month','Day','SimDay',...
        'Season',names{:});   
    fclose(fid);

    % Hydrological fluxes (daily)
    fid = fopen(strcat(FileLoc,FileLocation.OutputFilename,'_WaterFluxes.txt'),'w+t');
    fprintf(fid,strcat('%-10s%-10s%-10s%-10s%-10s%-15s%-15s%-15s%-15s%-15s',...
        '%-15s%-15s%-15s%-15s%-15s%-15s%-15s%-15s%-15s%-15s%-15s%-15s\n'),'Year','Month','Day',...
        'SimDay','Season','wRZ','Dr','TAW','zGW','wSurf','Irr','Rain','Infl','True_Infl','RO','DP','CR',...  % modified by Qi 20/3/23
        'GWin','Es','EsX','Tr','TrX');
    fclose(fid);

    % Crop growth (daily)
    fid = fopen(strcat(FileLoc,FileLocation.OutputFilename,'_CropGrowth.txt'),'w+t');
    fprintf(fid,strcat('%-10s%-10s%-10s%-10s%-10s%-15s%-15s%-15s%-15s%-15s',...
        '%-15s%-15s%-15s%-15s%-15s%-15s\n'),'Year','Month','Day',...
        'SimDay','Season','GDD','TotGDD','GrowthStage','Zr','CC','CCPot','Bio',...
        'BioPot','HI','HIadj','Yield');
    fclose(fid);
end

% Final output (at end of each growing season)
fid = fopen(strcat(FileLoc,FileLocation.OutputFilename,'_FinalOutput.txt'),'w+t');
fprintf(fid,'%-10s%-12s%-15s%-20s%-15s%-20s%-12s%-12s\n','Season',...
    'CropType','PlantDate','PlantSimDate','HarvestDate',...
    'HarvestSimDate','Yield','TotIrr');
fclose(fid);

end

