function pytest_run()
%%
% test the code comparing with the Aquacrop offical version 6.0
%%

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
dateS = datenum(2008, 9, 1);
sim_s = datestr(dateS, 'yyyy-mm-dd');
%sim_e = datestr(dateE, 'yyyy-mm-dd');
%date_h = datestr(dateE, 'dd/mm');
date_p = datestr(dateS, 'dd/mm');
clock = {sim_s,date_p, 'N'};

DA_Initialize(input, output, clock);

