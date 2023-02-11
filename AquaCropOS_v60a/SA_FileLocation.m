function FileLocation = SA_FileLocation(input,output)
FileLocation = struct();
FileLocation.Input = input;
FileLocation.Output = output;  % output = ' ';
cliFileName = dir([input,'*.cli']);
FileLocation.WeatherFilename = cliFileName.name;
FileLocation.GroundwaterFilename = 'WaterTable.txt';
FileLocation.CO2Filename = 'MaunaLoaCO2.txt';
end