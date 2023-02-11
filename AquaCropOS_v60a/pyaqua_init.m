function pyaqua_init(input,output,start_date)
%%
% test the code comparing with the Aquacrop offical version 6.0

%% Run model %%
% Initialise simulation
if ~exist(output,'dir')
    mkdir(output);
end

% Define start date
dateS = datenum(str2num(start_date{1}), str2num(start_date{2}), str2num(start_date{3}));
sim_s = datestr(dateS, 'yyyy-mm-dd');
%sim_e = datestr(dateE, 'yyyy-mm-dd');
%date_h = datestr(dateE, 'dd/mm');
date_p = datestr(dateS, 'dd/mm');
clock = {sim_s,date_p, 'N'};

RL_Initialize(input, output, clock);

