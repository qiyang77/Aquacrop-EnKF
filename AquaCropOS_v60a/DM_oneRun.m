function out = DM_oneRun(irrList, autoIRR)

global AOS_ClockStruct
global AOS_InitialiseStruct
%%
count = 1;
NoRain = false;
while AOS_ClockStruct.ModelTermination == false
   if autoIRR
       if count>1
           Drtmp = AOS_InitialiseStruct.Outputs.WaterFluxes(count - 1,7);
           %error(num2str(Drtmp))
           if Drtmp > 20
               irr = 40;
           else
               irr = 0;
           end
       else
           irr = 0;
       end
   else    
       if length(irrList) >= count
           irr = irrList(count);
       else
           irr = 0;
       end
   end
   RL_PerformTimeStep_flexirr(irr, NoRain);
%    AOS_PerformTimeStep();
   count = count + 1;
end

%% out
out = struct();
out.CC = AOS_InitialiseStruct.Outputs.CropGrowth(:,10);
out.Dr = AOS_InitialiseStruct.Outputs.WaterFluxes(:,7);
out.Yield = AOS_InitialiseStruct.Outputs.CropGrowth(:,16);
out.GDDcum = AOS_InitialiseStruct.Outputs.CropGrowth(:,7);
out.Biomass = AOS_InitialiseStruct.Outputs.CropGrowth(:,12);
out.HI = AOS_InitialiseStruct.Outputs.CropGrowth(:,14);
out.HIadj = AOS_InitialiseStruct.Outputs.CropGrowth(:,15);
out.pheno = AOS_InitialiseStruct.Outputs.CropGrowth(:,8);
out.time_axi = AOS_InitialiseStruct.Outputs.CropGrowth(:,4);
out.Irr = AOS_InitialiseStruct.Outputs.WaterFluxes(:,11);
out.Rain = AOS_InitialiseStruct.Outputs.WaterFluxes(:,12);
out.SurfW = AOS_InitialiseStruct.Outputs.WaterFluxes(:,10);
out.Tr = AOS_InitialiseStruct.Outputs.WaterFluxes(:,21);
out.Tmean = 0.5*(AOS_InitialiseStruct.Weather(:,2)+AOS_InitialiseStruct.Weather(:,3));

loc = find(out.CC == -999);
out.CC(loc) = [];
out.Dr(loc) = [];
out.Yield(loc) = [];
out.GDDcum(loc) = [];
out.Biomass(loc) = [];
out.HI(loc) = [];
out.HIadj(loc) = [];
out.pheno(loc) = [];
out.time_axi(loc) = [];
out.Irr(loc) = [];
out.Rain(loc) = [];
out.SurfW(loc) = [];
out.Tr(loc) = [];
out.Tmean(loc) = [];
