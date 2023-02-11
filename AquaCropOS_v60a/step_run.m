function out = step_run(action, rainfed)

global AOS_ClockStruct
global AOS_InitialiseStruct

%% step run
RL_PerformTimeStep(action, rainfed);

%% out
stepcount = AOS_ClockStruct.TimeStepCounter - 1;
out.status = AOS_ClockStruct.ModelTermination;
out.CC = AOS_InitialiseStruct.Outputs.CropGrowth(stepcount,10);
out.biomass = AOS_InitialiseStruct.Outputs.CropGrowth(stepcount,12);
out.biomass_p = AOS_InitialiseStruct.Outputs.CropGrowth(stepcount,13);
out.pheno = AOS_InitialiseStruct.Outputs.CropGrowth(stepcount,8);
%out.sim_day = AOS_InitialiseStruct.Outputs.CropGrowth(stepcount,4);
out.Dr = AOS_InitialiseStruct.Outputs.WaterFluxes(stepcount,7);
out.SurfW = AOS_InitialiseStruct.Outputs.WaterFluxes(stepcount,10);
out.Irr = AOS_InitialiseStruct.Outputs.WaterFluxes(stepcount,11);
out.IrrCum = AOS_InitialiseStruct.InitialCondition.IrrCum;
out.GDD = AOS_InitialiseStruct.InitialCondition.GDDcum;
out.sim_day = AOS_InitialiseStruct.InitialCondition.DAP;
out.Rain = AOS_InitialiseStruct.Outputs.WaterFluxes(stepcount,12);
%out.GDD = AOS_InitialiseStruct.Outputs.CropGrowth(stepcount,7);
out.Yield = AOS_InitialiseStruct.Outputs.CropGrowth(stepcount,16);
out.Esx = AOS_InitialiseStruct.Outputs.WaterFluxes(stepcount,20);
out.Trx = AOS_InitialiseStruct.Outputs.WaterFluxes(stepcount,22);
% if out.status == true
%     out.DrList = AOS_InitialiseStruct.Outputs.WaterFluxes(:,7);
%     out.RainList = AOS_InitialiseStruct.Outputs.WaterFluxes(:,12);
%     out.CCList = AOS_InitialiseStruct.Outputs.CropGrowth(:,10);
%     out.IrrList = AOS_InitialiseStruct.Outputs.WaterFluxes(:,11);
% end
    