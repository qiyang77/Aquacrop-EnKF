function [FileLocation] = DA_ReadFileLocations(input,output)
% Function to read input and output file locations

%% Declare global variables %%

FileLocation.Input = input;
FileLocation.Output = output;
    
%% Read file setup %%
% Load data
filename = 'FileSetup.txt';
fileID = fopen(strcat(FileLocation.Input,filename));
if fileID == -1
    % Can't find text file defining file setup.
    % Throw error message
    fprintf(2,'Error - File setup input file not found\n');
end
DataArray = textscan(fileID,'%s %*s','delimiter',':','headerlines',1);
fclose(fileID);

% Store strings
FileLocation.ClockFilename = strtrim(DataArray{1}{1});
FileLocation.WeatherFilename = strtrim(DataArray{1}{2});
FileLocation.CropFilename = strtrim(DataArray{1}{3});
FileLocation.SoilFilename = strtrim(DataArray{1}{4});
FileLocation.FieldMngtFallowFilename = strtrim(DataArray{1}{5});
FileLocation.InitialWCFilename = strtrim(DataArray{1}{6});
FileLocation.GroundwaterFilename = strtrim(DataArray{1}{7});
FileLocation.CO2Filename = strtrim(DataArray{1}{8});
FileLocation.OutputFilename = strtrim(DataArray{1}{9});
FileLocation.WriteDaily = strtrim(DataArray{1}{10});

end