function out = SA_py(input,output,start_date,para)
%% Declare global variables %%
global AOS_ClockStruct
global AOS_InitialiseStruct
%% Run model %%
% Initialise simulation
% input = './Input/rice_NN/';
% output = './Output/test/';
if ~exist(output,'dir')
    mkdir(output);
end

% Define start date
dateS = datenum(str2double(start_date{1}), str2double(start_date{2}), str2double(start_date{3}));
sim_s = datestr(dateS, 'yyyy-mm-dd');
date_p = datestr(dateS, 'dd/mm');
clock = {sim_s,date_p, 'N'};

SA_Initialize(input, output, clock, para);

% Perform single time-step (day)
count = 1;
while AOS_ClockStruct.ModelTermination == false
   AOS_PerformTimeStep();
   count = count + 1;
end

%% out
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
end