function state1 = step_run_DA_DVS(state0, dt, ensemble_n, state_case, update)

global AOS_ClockStruct
global AOS_InitialiseStruct
global AOS_ClockStruct_En
global AOS_InitialiseStruct_En

AOS_ClockStruct = AOS_ClockStruct_En{ensemble_n};
AOS_InitialiseStruct = AOS_InitialiseStruct_En{ensemble_n};
ii = 1;
CropNames = fieldnames(AOS_InitialiseStruct.Parameter.Crop);
%% input states

if ((~isempty(state0))&& update)
    state0(find(state0 < 0)) = 0;
    if state_case == 0 
        AOS_InitialiseStruct.InitialCondition.GDDcum = state0(1);
    elseif state_case == 1 
        AOS_InitialiseStruct.InitialCondition.CC = state0(1);
    elseif state_case == 2
        CC = state0(1);
        GDD = state0(2);
        if CC < 0
            CC = 0;
        end
        if GDD < 0
            GDD = 0;
        end
        AOS_InitialiseStruct.InitialCondition.CC = CC;
        AOS_InitialiseStruct.InitialCondition.GDDcum = GDD;
        DA_updateCalendar(GDD);
    elseif state_case == 3
        AOS_InitialiseStruct.InitialCondition.CC = state0(1);
        AOS_InitialiseStruct.InitialCondition.B = state0(2);
        AOS_InitialiseStruct.InitialCondition.GDDcum = state0(3);
        DA_updateCalendar(state0(3));
    elseif state_case == 4
        AOS_InitialiseStruct.InitialCondition.CC = state0(1);
        AOS_InitialiseStruct.InitialCondition.B = state0(2);
        AOS_InitialiseStruct.InitialCondition.GDDcum = state0(3);
        AOS_InitialiseStruct.Parameter.Crop.(CropNames{ii}).Tbase = state0(4);
        AOS_InitialiseStruct.Parameter.Crop.(CropNames{ii}).Senescence = state0(5);
        DA_updateTbase()  % lots of Pheno parameters should be updated after a Tbase change
    elseif state_case == 5
        AOS_InitialiseStruct.InitialCondition.CC = state0(1);
        AOS_InitialiseStruct.InitialCondition.B = state0(2);
        AOS_InitialiseStruct.InitialCondition.GDDcum = state0(3);
        AOS_InitialiseStruct.Parameter.Crop.(CropNames{ii}).Tbase = state0(4);
        AOS_InitialiseStruct.Parameter.Crop.(CropNames{ii}).Senescence = state0(5);
        AOS_InitialiseStruct.Parameter.Crop.(CropNames{ii}).CDC = state0(6);
        AOS_InitialiseStruct.Parameter.Crop.(CropNames{ii}).WP = state0(7);
        AOS_InitialiseStruct.Parameter.Crop.(CropNames{ii}).CGC = state0(8);
        DA_updateTbase()  % lots of Pheno parameters should be updated after a Tbase change
    elseif state_case == 6
        AOS_InitialiseStruct.InitialCondition.CC = state0(1);
        AOS_InitialiseStruct.InitialCondition.B = state0(2);
        AOS_InitialiseStruct.InitialCondition.GDDcum = state0(3);
        AOS_InitialiseStruct.Parameter.Crop.(CropNames{ii}).CDC = state0(4);
        AOS_InitialiseStruct.Parameter.Crop.(CropNames{ii}).WP = state0(5);
        AOS_InitialiseStruct.Parameter.Crop.(CropNames{ii}).CGC = state0(6);

    end
end

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
state1.plantingDate = datestr(AOS_ClockStruct.PlantingDate, 'yyyy-mm-dd');
state1.currentDate = datestr(AOS_ClockStruct.PlantingDate + AOS_InitialiseStruct.InitialCondition.DAP, 'yyyy-mm-dd');
state1.HIadj = AOS_InitialiseStruct.InitialCondition.HIadj;

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
%% update and clear global
AOS_ClockStruct_En{ensemble_n} = AOS_ClockStruct;
AOS_InitialiseStruct_En{ensemble_n} = AOS_InitialiseStruct;
% % Debug
% if ~isreal(state1.CC)
%     save ('bug.mat','AOS_ClockStruct_En','AOS_InitialiseStruct_En')
% end
clear global AOS_ClockStruct
clear global AOS_InitialiseStruct
 