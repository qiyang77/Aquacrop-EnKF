function state1 = step_run_DA(state0, dt, ensemble_n, state_case, update)

global AOS_ClockStruct
global AOS_InitialiseStruct
global AOS_ClockStruct_En
global AOS_InitialiseStruct_En

AOS_ClockStruct = AOS_ClockStruct_En{ensemble_n};
AOS_InitialiseStruct = AOS_InitialiseStruct_En{ensemble_n};
ii = 1;
CropNames = fieldnames(AOS_InitialiseStruct.Parameter.Crop);
%% input states
% if AOS_ClockStruct.ModelTermination == 0    % by Qi 2021/8/10
if ((~isempty(state0))&& update)
    if state_case == 1 
        AOS_InitialiseStruct.InitialCondition.CC = state0(1);
        AOS_InitialiseStruct.InitialCondition.B = state0(2);
        AOS_InitialiseStruct.Parameter.Crop.(CropNames{ii}).CDC = state0(3);
        AOS_InitialiseStruct.Parameter.Crop.(CropNames{ii}).CGC = state0(4);
        AOS_InitialiseStruct.Parameter.Crop.(CropNames{ii}).CCx = state0(5);
        AOS_InitialiseStruct.Parameter.Crop.(CropNames{ii}).WP = state0(6);
        AOS_InitialiseStruct.Parameter.Crop.(CropNames{ii}).Zmax = state0(7);
    elseif state_case == 2
        AOS_InitialiseStruct.InitialCondition.CC = state0(1);
        AOS_InitialiseStruct.InitialCondition.B = state0(2);
        AOS_InitialiseStruct.Parameter.Crop.(CropNames{ii}).CDC = state0(3);
        AOS_InitialiseStruct.Parameter.Crop.(CropNames{ii}).CGC = state0(4);
        AOS_InitialiseStruct.Parameter.Crop.(CropNames{ii}).CCx = state0(5);
        AOS_InitialiseStruct.Parameter.Crop.(CropNames{ii}).WP = state0(6);
        AOS_InitialiseStruct.Parameter.Crop.(CropNames{ii}).Zmax = state0(7);
        AOS_InitialiseStruct.Parameter.Crop.(CropNames{ii}).Tbase = state0(8);
        AOS_InitialiseStruct.InitialCondition.HIref = state0(9); % HIref mainly affected by GDD, so update HIref with pheno paras, Qi,21-8-5
        DA_updateTbase()
    elseif state_case == 3
        AOS_InitialiseStruct.InitialCondition.CC = state0(1);
        AOS_InitialiseStruct.InitialCondition.B = state0(2);
        AOS_InitialiseStruct.Parameter.Crop.(CropNames{ii}).CDC = state0(3);
        AOS_InitialiseStruct.Parameter.Crop.(CropNames{ii}).CGC = state0(4);
        AOS_InitialiseStruct.Parameter.Crop.(CropNames{ii}).CCx = state0(5);
        AOS_InitialiseStruct.Parameter.Crop.(CropNames{ii}).WP = state0(6);
        AOS_InitialiseStruct.Parameter.Crop.(CropNames{ii}).Zmax = state0(7);
        AOS_InitialiseStruct.Parameter.Crop.(CropNames{ii}).Tbase = state0(8);
        AOS_InitialiseStruct.InitialCondition.GDDcum = state0(9);
        AOS_InitialiseStruct.InitialCondition.HIref = state0(10); % HIref mainly affected by GDD, so update HIref with pheno paras, Qi,21-8-5
        DA_updateCalendar(state0(9));

    elseif state_case == 31
        AOS_InitialiseStruct.InitialCondition.CC = state0(1);
        AOS_InitialiseStruct.InitialCondition.B = state0(2);
        AOS_InitialiseStruct.Parameter.Crop.(CropNames{ii}).CDC = state0(3);
        AOS_InitialiseStruct.Parameter.Crop.(CropNames{ii}).CGC = state0(4);
        AOS_InitialiseStruct.Parameter.Crop.(CropNames{ii}).CCx = state0(5);
        AOS_InitialiseStruct.Parameter.Crop.(CropNames{ii}).WP = state0(6);
        AOS_InitialiseStruct.Parameter.Crop.(CropNames{ii}).Zmax = state0(7);
        AOS_InitialiseStruct.Parameter.Crop.(CropNames{ii}).Tbase = state0(8);
        AOS_InitialiseStruct.InitialCondition.GDDcum = state0(9);
        AOS_InitialiseStruct.InitialCondition.HIref = state0(10); % HIref mainly affected by GDD, so update HIref with pheno paras, Qi,21-8-5
        
    elseif state_case == 4
        AOS_InitialiseStruct.InitialCondition.CC = state0(1);
        AOS_InitialiseStruct.InitialCondition.B = state0(2);
        AOS_InitialiseStruct.Parameter.Crop.(CropNames{ii}).CDC = state0(3);
        AOS_InitialiseStruct.Parameter.Crop.(CropNames{ii}).CGC = state0(4);
        AOS_InitialiseStruct.Parameter.Crop.(CropNames{ii}).CCx = state0(5);
        AOS_InitialiseStruct.Parameter.Crop.(CropNames{ii}).WP = state0(6);
        AOS_InitialiseStruct.Parameter.Crop.(CropNames{ii}).Zmax = state0(7);
        AOS_InitialiseStruct.InitialCondition.GDDcum = state0(8);
        AOS_InitialiseStruct.InitialCondition.HIref = state0(9); % HIref mainly affected by GDD, so update HIref with pheno paras, Qi,21-8-5
        DA_updateCalendar(state0(8));
    elseif state_case == 41
        AOS_InitialiseStruct.InitialCondition.CC = state0(1);
        AOS_InitialiseStruct.InitialCondition.B = state0(2);
        AOS_InitialiseStruct.Parameter.Crop.(CropNames{ii}).CDC = state0(3);
        AOS_InitialiseStruct.Parameter.Crop.(CropNames{ii}).CGC = state0(4);
        AOS_InitialiseStruct.Parameter.Crop.(CropNames{ii}).CCx = state0(5);
        AOS_InitialiseStruct.Parameter.Crop.(CropNames{ii}).WP = state0(6);
        AOS_InitialiseStruct.Parameter.Crop.(CropNames{ii}).Zmax = state0(7);
        AOS_InitialiseStruct.InitialCondition.GDDcum = state0(8);
        AOS_InitialiseStruct.InitialCondition.HIref = state0(9); % HIref mainly affected by GDD, so update HIref with pheno paras, Qi,21-8-5
    elseif state_case == 5
        AOS_InitialiseStruct.InitialCondition.CC = state0(1);
        AOS_InitialiseStruct.InitialCondition.B = state0(2);
        AOS_InitialiseStruct.InitialCondition.GDDcum = state0(3);
        AOS_InitialiseStruct.InitialCondition.HIref = state0(4); % HIref mainly affected by GDD, so update HIref with pheno paras, Qi,21-8-5
        DA_updateCalendar(state0(3));
    elseif state_case == 6
        AOS_InitialiseStruct.InitialCondition.CC = state0(1);
        AOS_InitialiseStruct.InitialCondition.B = state0(2);
        AOS_InitialiseStruct.InitialCondition.GDDcum = state0(3);
    end
end
% end
%% step run
for i=1:round(dt)
    if AOS_ClockStruct.ModelTermination == false
       AOS_PerformTimeStep();
%        RL_PerformTimeStep_flexirr(irr, NoRain);
    end
end


%% output states
state1 = struct();
state1.CC = AOS_InitialiseStruct.InitialCondition.CC;
state1.yield = AOS_InitialiseStruct.InitialCondition.Y;
state1.biomass = AOS_InitialiseStruct.InitialCondition.B;
state1.pheno = AOS_InitialiseStruct.InitialCondition.GrowthStage;
state1.GDDcum = AOS_InitialiseStruct.InitialCondition.GDDcum;
state1.DAP = AOS_InitialiseStruct.InitialCondition.DAP;
state1.Done = AOS_ClockStruct.ModelTermination;
state1.CropDead = AOS_InitialiseStruct.InitialCondition.CropDead;
state1.CropMature = AOS_InitialiseStruct.InitialCondition.CropMature;
state1.FreezeDays = AOS_InitialiseStruct.InitialCondition.FreezeDays;
state1.SimulationStartTime = AOS_ClockStruct.SimulationStartTime;
state1.StepStartTime = datestr(AOS_ClockStruct.StepStartTime, 'yyyy-mm-dd');
state1.StepStartTimeNum = AOS_ClockStruct.StepStartTime;
state1.PlantingDate = AOS_ClockStruct.PlantingDate;
state1.PlantingDate_predefined = AOS_ClockStruct.PlantingDate_predefined;
state1.currentDate = datestr(state1.PlantingDate_predefined + AOS_ClockStruct.TimeStepCounter -1, 'yyyy-mm-dd');
state1.HIadj = AOS_InitialiseStruct.InitialCondition.HIadj;
state1.HI = AOS_InitialiseStruct.InitialCondition.HI;
state1.HIref = AOS_InitialiseStruct.InitialCondition.HIref;
state1.TimeStepCounter = AOS_ClockStruct.TimeStepCounter;

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
%% update and clear global
AOS_ClockStruct_En{ensemble_n} = AOS_ClockStruct;
AOS_InitialiseStruct_En{ensemble_n} = AOS_InitialiseStruct;
% % Debug
% if ~isreal(state1.CC)
%     save ('bug.mat','AOS_ClockStruct_En','AOS_InitialiseStruct_En')
% end
clear global AOS_ClockStruct
clear global AOS_InitialiseStruct
 