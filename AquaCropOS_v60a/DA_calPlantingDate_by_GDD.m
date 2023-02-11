function plantingDate = DA_calPlantingDate_by_GDD(GDD,currentDate)
% Function to read and process input weather time-series
global AOS_InitialiseStruct
%% Read input file location %%
Location = AOS_InitialiseStruct.FileLocation.Input;
ii = 1;
CropNames = fieldnames(AOS_InitialiseStruct.Parameter.Crop);
Crop = AOS_InitialiseStruct.Parameter.Crop.(CropNames{ii});
%% Read weather data inputs %%
% Open file
filename = AOS_InitialiseStruct.FileLocation.WeatherFilename;
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
datenumCurrentDate = datenum(datevec(currentDate,'yyyy-mm-dd'));
StartRow = find(Dates==datenumCurrentDate);

%% tenet GDD
count = 0;
while GDD > 0
    GDD = GDD - DA_GrowingDegreeDay(Crop,Tmax(StartRow - count),Tmin(StartRow - count));
    count = count + 1;
end   
plantingDate = datestr(datenumCurrentDate - count, 'yyyy-mm-dd');

end