% function test_run()
%%
% test the code comparing with the Aquacrop offical version 6.0
%%
clc
clear

%% Declare global variables %%
global AOS_ClockStruct

%% Run model %%
% Initialise simulation
input = './Input/rice/';
output = './Output/test/';
if ~exist(output,'dir')
    mkdir(output);
end

% Define start date
dateS = datenum(2000, 9, 15);
sim_s = datestr(dateS, 'yyyy-mm-dd');
date_p = datestr(dateS, 'dd/mm');
clock = {sim_s,date_p, 'N'};

% DA_Initialize(input, output, clock);
para = load('../sim_para.in');
SA_Initialize(input, [], clock, para);
% Perform single time-step (day)
count = 1;
while AOS_ClockStruct.ModelTermination == false
   AOS_PerformTimeStep();
   count = count + 1;
end

global AOS_InitialiseStruct

out = struct();
out.CC = AOS_InitialiseStruct.Outputs.CropGrowth(:,10);
out.Dr = AOS_InitialiseStruct.Outputs.WaterFluxes(:,7);
out.Yield = AOS_InitialiseStruct.Outputs.CropGrowth(:,16);
out.pheno = AOS_InitialiseStruct.Outputs.CropGrowth(:,8);
out.time_axi = AOS_InitialiseStruct.Outputs.CropGrowth(:,4);

loc = find(out.CC == -999);
out.CC(loc) = [];
out.Dr(loc) = [];
out.Yield(loc) = [];
out.pheno(loc) = [];
out.time_axi(loc) = [];

CC = AOS_InitialiseStruct.Outputs.CropGrowth(:,10);
time_axi = AOS_InitialiseStruct.Outputs.CropGrowth(:,4);
Dr = AOS_InitialiseStruct.Outputs.WaterFluxes(:,7);
Yield = AOS_InitialiseStruct.Outputs.CropGrowth(:,16);
GDDcum = AOS_InitialiseStruct.Outputs.CropGrowth(:,7);
pheno = AOS_InitialiseStruct.Outputs.CropGrowth(:,8);
Biomass = AOS_InitialiseStruct.Outputs.CropGrowth(:,12);

loc = find(CC == -999);
time_axi(loc) = [];
CC(loc) = [];
Dr(loc) = [];
Yield(loc) = [];
GDDcum(loc) = [];
pheno(loc) = [];
Biomass(loc) = [];
% Finish simulation
% AOS_Finish();
final_yield = AOS_InitialiseStruct.Outputs.FinalOutput{1,7};
fprintf('Final yield is %.2f t/ha \n', final_yield);

%% plot

figure()
subplot(4,1,1)
plot(time_axi, CC ,'r-')
ylabel('CC','Fontname','Times New Roman','FontWeight','Bold','FontSize',16);
subplot(4,1,2)
plot(time_axi, Biomass ,'g-')
ylabel('Biomass','Fontname','Times New Roman','FontWeight','Bold','FontSize',16);
subplot(4,1,3)
plot(time_axi, Dr ,'b-')
ylabel('Dr','Fontname','Times New Roman','FontWeight','Bold','FontSize',16);
set(gca,'YDir','reverse'); 
subplot(4,1,4)
plot(time_axi, GDDcum ,'k-')
ylabel('GDDcum','Fontname','Times New Roman','FontWeight','Bold','FontSize',16);