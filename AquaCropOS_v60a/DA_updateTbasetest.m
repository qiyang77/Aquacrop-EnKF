function DA_updatePhenotest(ensemble_n,input)
global AOS_ClockStruct
global AOS_InitialiseStruct
global AOS_ClockStruct_En
global AOS_InitialiseStruct_En

AOS_ClockStruct = AOS_ClockStruct_En{ensemble_n};
AOS_InitialiseStruct = AOS_InitialiseStruct_En{ensemble_n};
AOS_InitialiseStruct.Weather;
ii = 1;
CropNames = fieldnames(AOS_InitialiseStruct.Parameter.Crop);
%% Update simulation end date & Weather
FileLocation = SA_FileLocation(input,' ');
[sim_e,WeatherDB] = SA_calSIM_END_by_GDD(FileLocation,AOS_InitialiseStruct.Parameter.Crop.(CropNames{ii}), AOS_ClockStruct.SimulationStartTime);
DateStoV = datevec(sim_e,'yyyy-mm-dd');
AOS_ClockStruct.SimulationEndDate = datenum(DateStoV);
AOS_ClockStruct.HarvestDate = datenum(DateStoV);
AOS_ClockStruct.SimulationEndTime = sim_e;
% update time span
% Total numbers of time steps (days)
AOS_ClockStruct.nSteps = AOS_ClockStruct.SimulationEndDate-...
    AOS_ClockStruct.SimulationStartDate;
% Time spans
TimeSpan = zeros(1,AOS_ClockStruct.nSteps+1);
TimeSpan(1) = AOS_ClockStruct.SimulationStartDate;
TimeSpan(end) = AOS_ClockStruct.SimulationEndDate;
for ss = 2:AOS_ClockStruct.nSteps
    TimeSpan(ss) = TimeSpan(ss-1)+1;
end
AOS_ClockStruct.TimeSpan = TimeSpan;

AOS_InitialiseStruct.Parameter.Crop.(CropNames{ii}).HarvestDate = datestr(datenum(sim_e), 'dd/mm');
AOS_InitialiseStruct.Weather = WeatherDB;

%% Update pheno Calendar Day
% Crop calendar


AOS_InitialiseStruct.Parameter.Crop.(CropNames{ii}) =...
    AOS_ComputeCropCalendar(AOS_InitialiseStruct.Parameter.Crop.(CropNames{ii}),CropNames{ii},...
    CropNames,AOS_InitialiseStruct.Weather);

% Harvest index growth coefficient
AOS_InitialiseStruct.Parameter.Crop.(CropNames{ii}).HIGC =...
    AOS_CalculateHIGC(AOS_InitialiseStruct.Parameter.Crop.(CropNames{ii}));

% Days to linear HI switch point
if AOS_InitialiseStruct.Parameter.Crop.(CropNames{ii}).CropType == 3
    % Determine linear switch point and HIGC rate for fruit/grain crops
    [tLin,HIGClin] = AOS_CalculateHILinear(AOS_InitialiseStruct.Parameter.Crop.(CropNames{ii}));
    AOS_InitialiseStruct.Parameter.Crop.(CropNames{ii}).tLinSwitch = tLin;
    AOS_InitialiseStruct.Parameter.Crop.(CropNames{ii}).dHILinear = HIGClin;
else
    % No linear switch for leafy vegetable or root/tiber crops
    AOS_InitialiseStruct.Parameter.Crop.(CropNames{ii}).tLinSwitch = [];
    AOS_InitialiseStruct.Parameter.Crop.(CropNames{ii}).dHILinear = [];
end
%% update and clear global
AOS_ClockStruct_En{ensemble_n} = AOS_ClockStruct;
AOS_InitialiseStruct_En{ensemble_n} = AOS_InitialiseStruct;
clear global AOS_ClockStruct
clear global AOS_InitialiseStruct
end