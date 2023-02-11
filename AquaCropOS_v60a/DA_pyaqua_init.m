function DA_pyaqua_init(input,start_date,para,ensemble_n)

%% Run model %%
% Initialise simulation
% Define start date
dateS = datenum(str2double(start_date{1}), str2double(start_date{2}), str2double(start_date{3}));
sim_s = datestr(dateS, 'yyyy-mm-dd');
date_p = datestr(dateS, 'dd/mm');
clock = {sim_s,date_p, 'N'};
% para = []; % Use the default parameters

SA_Initialize(input, [], clock, para);
%% Define global variables %% 
global AOS_ClockStruct
global AOS_InitialiseStruct
global AOS_ClockStruct_En
global AOS_InitialiseStruct_En
if ensemble_n == 1
    AOS_ClockStruct_En = {};
    AOS_InitialiseStruct_En = {};
end
AOS_ClockStruct_En{ensemble_n} = AOS_ClockStruct;
AOS_InitialiseStruct_En{ensemble_n} = AOS_InitialiseStruct;

clear global AOS_ClockStruct
clear global AOS_InitialiseStruct
end