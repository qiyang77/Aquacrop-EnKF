function state1 = DA_updateGDD(GDD, state_case, ensemble_n)
%% Update GDD: calculate the planting date to resimulate the sample
%% By Qi 2020/10/5
global AOS_ClockStruct
global AOS_InitialiseStruct

%% push back the GDD to transplanting date
% dateS = AOS_ClockStruct.PlantingDate;
% currentDate = datestr(dateS + AOS_InitialiseStruct.InitialCondition.DAP, 'yyyy-mm-dd');
dateS = AOS_ClockStruct.PlantingDate_predefined; % fix the predefined date to compute the currentDate , Qi 2021-8-4
currentDate = datestr(dateS + AOS_ClockStruct.TimeStepCounter -1, 'yyyy-mm-dd');% by Qi 2021-7-24,
plantingDate = DA_calPlantingDate_by_GDD(GDD,currentDate);
plantingDateNum = datenum(datevec(plantingDate,'yyyy-mm-dd'));
AOS_InitialiseStruct.InitialCondition.DAP = (dateS + AOS_ClockStruct.TimeStepCounter -1) - plantingDateNum; % update the DAP, by Qi 2021-7-24
% error('GDD is %.2f, plantingDate is %s, currentdate is %s \n',GDD,plantingDate, currentDate)
%% re-initilazing
dateS = datenum(datevec(plantingDate,'yyyy-mm-dd'));
sim_s = datestr(dateS, 'yyyy-mm-dd');
date_p = datestr(dateS, 'dd/mm');
clock = {sim_s,date_p, 'N'};
ParamStruct = AOS_InitialiseStruct.Parameter;
input = AOS_InitialiseStruct.input;
clear global AOS_ClockStruct
clear global AOS_InitialiseStruct
DA_ReInitializeTime(input,'',clock, ParamStruct);

global AOS_ClockStruct
global AOS_InitialiseStruct
%% output states
AOS_InitialiseStruct.input = input;
state1 = struct();
state1.CC = AOS_InitialiseStruct.InitialCondition.CC;
state1.yield = 0;
state1.biomass = AOS_InitialiseStruct.InitialCondition.B;
% error('biomass is %.2f',state1.biomass)
state1.pheno = AOS_InitialiseStruct.InitialCondition.GrowthStage;
state1.GDDcum = AOS_InitialiseStruct.InitialCondition.GDDcum;
state1.DAP = AOS_InitialiseStruct.InitialCondition.DAP;
state1.Done = AOS_ClockStruct.ModelTermination;
% state1.plantingDateNum = AOS_ClockStruct.PlantingDate;
state1.PlantingDateCD = datestr(AOS_ClockStruct.PlantingDate, 'yyyy-mm-dd');
% state1.currentDate = datestr(AOS_ClockStruct.PlantingDate + AOS_InitialiseStruct.InitialCondition.DAP, 'yyyy-mm-dd');
state1.SimulationStartTime = AOS_ClockStruct.SimulationStartTime;
state1.StepStartTime = datestr(AOS_ClockStruct.StepStartTime, 'yyyy-mm-dd');
state1.StepStartTimeNum = AOS_ClockStruct.StepStartTime;
state1.PlantingDate = AOS_ClockStruct.PlantingDate;
state1.PlantingDate_predefined = AOS_ClockStruct.PlantingDate_predefined;
state1.currentDate = datestr(state1.PlantingDate_predefined + AOS_ClockStruct.TimeStepCounter -1, 'yyyy-mm-dd');
state1.HIadj = AOS_InitialiseStruct.InitialCondition.HIadj;
state1.HI = AOS_InitialiseStruct.InitialCondition.HI;
state1.HIref = AOS_InitialiseStruct.InitialCondition.HIref;

cropName = fieldnames(AOS_InitialiseStruct.Parameter.Crop);
state1.Para_Tbase = AOS_InitialiseStruct.Parameter.Crop.(cropName{1}).Tbase;
state1.Para_Canopy10Pct = AOS_InitialiseStruct.Parameter.Crop.(cropName{1}).Canopy10Pct;
state1.Para_MaxCanopy = AOS_InitialiseStruct.Parameter.Crop.(cropName{1}).MaxCanopy;
state1.Para_Senescence = AOS_InitialiseStruct.Parameter.Crop.(cropName{1}).Senescence;
state1.Para_HIstart = AOS_InitialiseStruct.Parameter.Crop.(cropName{1}).HIstart;
state1.Para_Flowering = AOS_InitialiseStruct.Parameter.Crop.(cropName{1}).Flowering;
state1.Para_YldForm = AOS_InitialiseStruct.Parameter.Crop.(cropName{1}).YldForm;
state1.Para_CDC = AOS_InitialiseStruct.Parameter.Crop.(cropName{1}).CDC;
state1.Para_WP = AOS_InitialiseStruct.Parameter.Crop.(cropName{1}).WP;
state1.Para_CGC = AOS_InitialiseStruct.Parameter.Crop.(cropName{1}).CGC;
state1.Para_CCx = AOS_InitialiseStruct.Parameter.Crop.(cropName{1}).CCx;
state1.Para_Zmax = AOS_InitialiseStruct.Parameter.Crop.(cropName{1}).Zmax;
state1.Para_p_up2 = AOS_InitialiseStruct.Parameter.Crop.(cropName{1}).p_up(2);
state1.Para_p_up4 = AOS_InitialiseStruct.Parameter.Crop.(cropName{1}).p_up(4);

%% re-simulating
if state_case == 0 
    dateC = datenum(datevec(currentDate,'yyyy-mm-dd'));
    DAP = dateC - dateS;
    for i=1:round(DAP - 1)
        if AOS_ClockStruct.ModelTermination == false
           AOS_PerformTimeStep();
    %        RL_PerformTimeStep_flexirr(irr, NoRain);
        end
    end
end

%% update and clear global
global AOS_ClockStruct_En
global AOS_InitialiseStruct_En
AOS_ClockStruct_En{ensemble_n} = AOS_ClockStruct;
AOS_InitialiseStruct_En{ensemble_n} = AOS_InitialiseStruct;
% % Debug
% if ~isreal(state1.CC)
%     save ('bug.mat','AOS_ClockStruct_En','AOS_InitialiseStruct_En')
% end
clear global AOS_ClockStruct
clear global AOS_InitialiseStruct