function [sim_e,WeatherDB] = SA_calSIM_END_by_GDD(FileLocation,Crop, sim_s)
% Function to read and process input weather time-series

%% Read input file location %%
Location = FileLocation.Input;

%% Read weather data inputs %%
% Open file
filename = FileLocation.WeatherFilename;
fileID = fopen(strcat(Location,filename));
if fileID == -1
    % Can't find text file defining weather inputs
    % Throw error message
    fprintf(2,'Error - Weather input file not found\n');
end

% Load data in
Data = textscan(fileID,'%f %f %f %f %f %f %f','headerlines',1);    % revised by Qi 20/3/25 , default 2 to 1.
fclose(fileID);

%% Convert dates to serial date format %%
Dates = datenum(Data{1,3},Data{1,2},Data{1,1});

%% Extract data %%
Tmin = Data{1,4};
Tmax = Data{1,5};

%% Extract data for simulation period %%
% Find start dates
StartDate = datenum(datevec(sim_s,'yyyy-mm-dd'));
StartRow = find(Dates==StartDate);
P = Data{1,6};
Et0 = Data{1,7};

%% pre-calculate GDD
count = 0;
GDDacc = 0;
while GDDacc < Crop.Maturity + 100
    GDDacc = GDDacc + DA_GrowingDegreeDay(Crop,Tmax(StartRow + count),Tmin(StartRow + count));
    count = count + 1;
end   
% sim_e = datestr(StartDate + count, 'yyyy-mm-dd');
sim_e = datestr(StartDate + count + 30, 'yyyy-mm-dd'); % by Qi 2021/7/21 aviod the GDD update fail
%fprintf('Simulation start from %s to %s with GDDaccum %.1f\n',sim_s,sim_e,GDDacc)

% Find start and end dates

EndDate = datenum(datevec(sim_e,'yyyy-mm-dd'));
StartRow = find(Dates==StartDate);
EndRow = find(Dates==EndDate);

% Store data for simulation period
WeatherDB = [Dates(StartRow:EndRow),Tmin(StartRow:EndRow),...
    Tmax(StartRow:EndRow),P(StartRow:EndRow),...
    Et0(StartRow:EndRow)];
end