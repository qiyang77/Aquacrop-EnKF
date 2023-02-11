function DA_updateCalendar(GDD)
%% Update phenological parameters
%% By Qi 2020/10/9
global AOS_ClockStruct
global AOS_InitialiseStruct

ii = 1;
CropNames = fieldnames(AOS_InitialiseStruct.Parameter.Crop);
%% init stat
DayCor_old = AOS_InitialiseStruct.InitialCondition.DAP-AOS_InitialiseStruct.InitialCondition.DelayedCDs...
    -1-AOS_InitialiseStruct.Parameter.Crop.(CropNames{ii}).HIstartCD;
%% Update planting date
% fprintf('before update,DAP:%d,plantingDate:%d\n',AOS_InitialiseStruct.InitialCondition.DAP,AOS_ClockStruct.PlantingDate)
% dateS = AOS_ClockStruct.PlantingDate;
dateS = AOS_ClockStruct.PlantingDate_predefined; % fix the predefined date to compute the currentDate , Qi 2021-7-23
% currentDate = datestr(dateS + AOS_InitialiseStruct.InitialCondition.DAP, 'yyyy-mm-dd');% currentDate is the predefined date
currentDate = datestr(dateS + AOS_ClockStruct.TimeStepCounter -1, 'yyyy-mm-dd');% by Qi 2021-7-24, AOS_ClockStruct.TimeStepCounter is keep unchanged
plantingDate = DA_calPlantingDate_by_GDD(GDD,currentDate); %GDD=1703
plantingDateNum = datenum(datevec(plantingDate,'yyyy-mm-dd'));
AOS_InitialiseStruct.InitialCondition.DAP = (dateS + AOS_ClockStruct.TimeStepCounter -1) - plantingDateNum; % update the DAP, by Qi 2021-7-24
date_p = datestr(plantingDateNum, 'dd/mm');
AOS_ClockStruct.SimulationStartTime = plantingDate;
AOS_ClockStruct.SimulationStartDate = plantingDateNum;
AOS_ClockStruct.PlantingDate = plantingDateNum;
AOS_InitialiseStruct.Parameter.Crop.(CropNames{ii}).PlantingDate = date_p;
% fprintf('after update,DAP:%d,plantingDate:%d\n',AOS_InitialiseStruct.InitialCondition.DAP,AOS_ClockStruct.PlantingDate)
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
% save bug1009.mat
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

%% update sCor1 and sCor2 (HIadjPostAnthesis parameters) by Qi 2021-7-29
DayCor = AOS_InitialiseStruct.InitialCondition.DAP-AOS_InitialiseStruct.InitialCondition.DelayedCDs...
    -1-AOS_InitialiseStruct.Parameter.Crop.(CropNames{ii}).HIstartCD;
if DayCor_old > 0
    try
        if length(AOS_InitialiseStruct.InitialCondition.dCor1_list)>=DayCor
            AOS_InitialiseStruct.InitialCondition.sCor1 = sum(AOS_InitialiseStruct.InitialCondition.dCor1_list(end-DayCor+1:end));
        else
            AOS_InitialiseStruct.InitialCondition.sCor1 = DayCor*mean(AOS_InitialiseStruct.InitialCondition.dCor1_list);
        end
    catch
%         save bug0806.mat
        disp('no InitialCondition.dCor1_list, skip')
    end
    try
    if length(AOS_InitialiseStruct.InitialCondition.dCor2_list)>=DayCor
        AOS_InitialiseStruct.InitialCondition.sCor2 = sum(AOS_InitialiseStruct.InitialCondition.dCor2_list(end-DayCor+1:end));     
    else
        AOS_InitialiseStruct.InitialCondition.sCor2 = DayCor*mean(AOS_InitialiseStruct.InitialCondition.dCor2_list); 
    end
    catch
%         save bug0810_2.mat
        disp('no InitialCondition.dCor2_list, skip')
    end
%     fprintf('DAP:%d,sCor1:%.2f,sCor2:%.2f\n',AOS_InitialiseStruct.InitialCondition.DAP,AOS_InitialiseStruct.InitialCondition.sCor1,...
%             AOS_InitialiseStruct.InitialCondition.sCor2)
else
    AOS_InitialiseStruct.InitialCondition.sCor1 = 0;
    AOS_InitialiseStruct.InitialCondition.sCor2 = 0;
end
end