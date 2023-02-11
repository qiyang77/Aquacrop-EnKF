function DM_pyaqua_init(input,start_date, para)

%% Run model %%
% Initialise simulation
% Define start date
dateS = datenum(str2double(start_date{1}), str2double(start_date{2}), str2double(start_date{3}));
sim_s = datestr(dateS, 'yyyy-mm-dd');
date_p = datestr(dateS, 'dd/mm');
clock = {sim_s,date_p, 'N'};
% para = []; % Use the default parameters

SA_Initialize(input, [], clock, para);

end