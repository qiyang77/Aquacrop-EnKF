function [NewCond,Outputs] = RL_Solution_flexirr(WeatherStruct, irr)
% Function to perform AquaCrop-OS solution for a single time step
% WeatherStruct = Weather;
%% Define global variables %%
global AOS_ClockStruct
global AOS_InitialiseStruct

%% Unpack structures %%
Soil = AOS_InitialiseStruct.Parameter.Soil;
CO2 = AOS_InitialiseStruct.Parameter.CO2;
Groundwater = AOS_InitialiseStruct.Groundwater;
P = WeatherStruct.Precipitation;
Tmax = WeatherStruct.MaxTemp;
Tmin = WeatherStruct.MinTemp;
Et0 = WeatherStruct.ReferenceET;

%% Store initial conditions in structure for updating %%
NewCond = AOS_InitialiseStruct.InitialCondition;

%% Check if growing season is active on current time step %%
if AOS_ClockStruct.SeasonCounter > 0
    % Check if in growing season
    CurrentDate = AOS_ClockStruct.StepStartTime;
    PlantingDate = AOS_ClockStruct.PlantingDate...
        (AOS_ClockStruct.SeasonCounter);
    HarvestDate = AOS_ClockStruct.HarvestDate...
        (AOS_ClockStruct.SeasonCounter);
    if (CurrentDate >= PlantingDate) && (CurrentDate <= HarvestDate) &&...
            (NewCond.CropMature == false) && (NewCond.CropDead == false)
        GrowingSeason = true;
    else
        GrowingSeason = false;
    end
    % Assign crop, irrigation management, and field management structures
    Crop = AOS_InitialiseStruct.Parameter.Crop.(...
        AOS_InitialiseStruct.CropChoices{AOS_ClockStruct.SeasonCounter});
    IrrMngt = AOS_InitialiseStruct.IrrigationManagement.(...
        AOS_InitialiseStruct.CropChoices{AOS_ClockStruct.SeasonCounter});
    if GrowingSeason == true
        FieldMngt = AOS_InitialiseStruct.FieldManagement.(...
            AOS_InitialiseStruct.CropChoices{AOS_ClockStruct.SeasonCounter});
    else
        FieldMngt = AOS_InitialiseStruct.FieldManagement.Fallow;
    end
else
    % Not yet reached start of first growing season
    GrowingSeason = false;
    % Assign crop, irrigation management, and field management structures
    Crop = struct('Zmin',0.3,'Aer',5);
    IrrMngt = struct('IrrMethod',-99);
    FieldMngt = AOS_InitialiseStruct.FieldManagement.Fallow;
end

%% Increment time counters %%
if GrowingSeason == true
    % Calendar days after planting
    NewCond.DAP = NewCond.DAP+1;
    % Growing degree days after planting
    [GDD,NewCond] = AOS_GrowingDegreeDay(Crop,NewCond,Tmax,Tmin);
else
    % Calendar days after planting
    NewCond.DAP = 0;
    % Growing degree days after planting
    GDD = 0;
    NewCond.GDDcum = 0;
end

%% Run simulations %%
% 1. Check for groundwater table
NewCond = AOS_CheckGroundwaterTable(Soil,Groundwater,NewCond);

% 2. Root development
NewCond = AOS_RootDevelopment(Crop,Soil,Groundwater,NewCond,GDD,GrowingSeason);

% 3. Pre-irrigation %
[NewCond,PreIrr] = AOS_PreIrrigation(Soil,Crop,IrrMngt,NewCond,GrowingSeason);

% 4. Drainage
[NewCond,DeepPerc,FluxOut] = AOS_Drainage(Soil,NewCond);

% 5. Surface runoff
[Runoff,Infl,NewCond] = AOS_RainfallPartition(P,Soil,FieldMngt,NewCond);

% 6. Irrigation
% [NewCond,Irr] = AOS_Irrigation(NewCond,IrrMngt,Crop,Soil,...
%     AOS_ClockStruct,GrowingSeason,P,Runoff); 
[NewCond,Irr] = RL_Irrigation_flex(NewCond,irr,Crop,Soil,...
    GrowingSeason,P,Runoff);

% 7. Infiltration added true_infl by Qi
[NewCond,DeepPerc,Runoff,Infl,FluxOut,True_infl] = AOS_Infiltration(Soil,NewCond,Infl,...
    Irr,IrrMngt,FieldMngt,FluxOut,DeepPerc,Runoff,GrowingSeason);
%fprintf('date %d ',AOS_ClockStruct.TimeStepCounter);disp(FluxOut)
% fprintf('Surf %.2f after infil at date %d\n',NewCond.SurfaceStorage,AOS_ClockStruct.TimeStepCounter)

% 8. Capillary rise
[NewCond,CR] = AOS_CapillaryRise(Soil,Groundwater,NewCond,FluxOut);

% 9. Check germination
NewCond = AOS_Germination(NewCond,Soil,Crop,GDD,GrowingSeason);

% 10. Update growth stage
NewCond = AOS_GrowthStage(Crop,NewCond,GrowingSeason);

% 11. Canopy cover development
NewCond = AOS_CanopyCover(Crop,Soil,NewCond,GDD,Et0,GrowingSeason);

% 12. Soil evaporation
[NewCond,Es,EsPot] = AOS_SoilEvaporation(Soil,Crop,IrrMngt,FieldMngt,NewCond,...
    Et0,Infl,P,Irr,GrowingSeason);
% fprintf('Surf %.2f after Es at date %d\n',NewCond.SurfaceStorage,AOS_ClockStruct.TimeStepCounter)

% 13. Crop transpiration
[Tr,TrPot_NS,TrPot,NewCond,IrrNet] = AOS_Transpiration(Soil,Crop,...
    IrrMngt,NewCond,Et0,CO2,GrowingSeason,GDD);
% fprintf('Surf %.2f after Tr at date %d\n',NewCond.SurfaceStorage,AOS_ClockStruct.TimeStepCounter)

% 14. Groundwater inflow
[NewCond,GwIn] = AOS_GroundwaterInflow(Soil,NewCond);

% 15. Reference harvest index
NewCond = AOS_HIrefCurrentDay(NewCond,Crop,GrowingSeason);

% 16. Biomass accumulation
NewCond = AOS_BiomassAccumulation(Crop,NewCond,Tr,TrPot_NS,Et0,GrowingSeason);

% 17. Harvest index
NewCond = AOS_HarvestIndex(Soil,Crop,NewCond,Et0,Tmax,Tmin,GrowingSeason);

% 18. Crop yield
if GrowingSeason == true
    % Calculate crop yield (tonne/ha)
    NewCond.Y = (NewCond.B/100)*NewCond.HIadj;
    % Check if crop has reached maturity
    if ((Crop.CalendarType == 1) && (NewCond.DAP >= Crop.Maturity)) ||...
            ((Crop.CalendarType == 2) && (NewCond.GDDcum >= Crop.Maturity))
        % Crop has reached maturity
        NewCond.CropMature = true;
    end
else
    % Crop yield is zero outside of growing season
    NewCond.Y = 0;
end

% 19. Root zone water
[Wr,Dr,TAW,~] = AOS_RootZoneWater(Soil,Crop,NewCond);                 % modified by Qi 20/3/25

% 20. Update net irrigation to add any pre irrigation
IrrNet = IrrNet+PreIrr;
NewCond.IrrNetCum = NewCond.IrrNetCum+PreIrr;

%% Calculate the freezing date %%  added by Qi 2021/3/10
Tmean = 0.5*(Tmax + Tmin);
if Tmean < Crop.Tfreeze
    NewCond.FreezeDays = NewCond.FreezeDays+1;
else
    NewCond.FreezeDays = 0;
end
if NewCond.FreezeDays > Crop.LagCold
    NewCond.CropDead = true;
end

%% Update model outputs %%
Outputs = AOS_InitialiseStruct.Outputs;
row_day = AOS_ClockStruct.TimeStepCounter;
row_gs = AOS_ClockStruct.SeasonCounter;
% Irrigation
if GrowingSeason == true
    if IrrMngt.IrrMethod == 4
        % Net irrigation
        IrrDay = IrrNet;
        IrrTot = NewCond.IrrNetCum;
    else
        % Irrigation
        IrrDay = Irr;
        IrrTot = NewCond.IrrCum;
    end
else
    IrrDay = 0;
    IrrTot = 0;
end
% Water contents
Outputs.WaterContents(row_day,4:end) = [AOS_ClockStruct.TimeStepCounter,...
    GrowingSeason,NewCond.th];
% Water fluxes
Outputs.WaterFluxes(row_day,4:end) = [AOS_ClockStruct.TimeStepCounter,...
    GrowingSeason,Wr,Dr.Rz,TAW.Rz,NewCond.zGW,NewCond.SurfaceStorage,IrrDay,P,Infl,True_infl,Runoff,...    % modified by Qi 20/3/23
    DeepPerc,CR,GwIn,Es,EsPot,Tr,TrPot];
% Crop growth
Outputs.CropGrowth(row_day,4:end) = [AOS_ClockStruct.TimeStepCounter,...
    GrowingSeason,GDD,NewCond.GDDcum,NewCond.GrowthStage,NewCond.Zroot,NewCond.CC,NewCond.CC_NS,...
    NewCond.B,NewCond.B_NS,NewCond.HI,NewCond.HIadj,NewCond.Y];
% Final output (if at end of growing season) 
if AOS_ClockStruct.SeasonCounter > 0
    if ((NewCond.CropMature == true) || (NewCond.CropDead == true) ||...
            (AOS_ClockStruct.StepEndTime ==...
            AOS_ClockStruct.HarvestDate(AOS_ClockStruct.SeasonCounter))) &&...
            (NewCond.HarvestFlag == false)
        % Get planting and harvest dates
        plant_sdate = find(AOS_ClockStruct.TimeSpan == ...
            AOS_ClockStruct.PlantingDate(AOS_ClockStruct.SeasonCounter));
        plant_cdate = datestr(AOS_ClockStruct.PlantingDate...
            (AOS_ClockStruct.SeasonCounter),'dd/mm/yyyy');
        harvest_cdate = datestr(AOS_ClockStruct.StepStartTime,'dd/mm/yyyy');
        harvest_sdate = AOS_ClockStruct.TimeStepCounter;
        
        % Store final outputs
        Outputs.FinalOutput(row_gs,:) = {AOS_ClockStruct.SeasonCounter,...
            AOS_InitialiseStruct.CropChoices{AOS_ClockStruct.SeasonCounter},...
            plant_cdate,plant_sdate,harvest_cdate,harvest_sdate,...
            NewCond.Y,IrrTot};
        
        % Set harvest flag
        NewCond.HarvestFlag = true;
    end
end

end