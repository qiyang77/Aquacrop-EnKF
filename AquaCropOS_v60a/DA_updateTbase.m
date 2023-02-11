function DA_updateTbase()
%% Update phenological parameters after Tbase is changed
%% By Qi 2020/9/11

global AOS_ClockStruct
global AOS_InitialiseStruct
ii = 1;
CropNames = fieldnames(AOS_InitialiseStruct.Parameter.Crop);
%% Update simulation end date & Weather
% update simulation end day&time
[sim_e,WeatherDB] = SA_calSIM_END_by_GDD(AOS_InitialiseStruct.FileLocation,AOS_InitialiseStruct.Parameter.Crop.(CropNames{ii}), AOS_ClockStruct.SimulationStartTime);
DateStoV = datevec(sim_e,'yyyy-mm-dd');
AOS_ClockStruct.SimulationEndDate = datenum(DateStoV);
AOS_ClockStruct.HarvestDate = datenum(DateStoV);
AOS_ClockStruct.SimulationEndTime = sim_e;
% update time span (total numbers of time steps (days))
AOS_ClockStruct.nSteps = AOS_ClockStruct.SimulationEndDate-...
    AOS_ClockStruct.SimulationStartDate;
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

end