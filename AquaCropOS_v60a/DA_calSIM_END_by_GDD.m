function sim_e = DA_calSIM_END_by_GDD(FileLocation, sim_s)
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

%% Read crop mix input file %%
filename = strcat(Location,FileLocation.CropFilename);
fileID = fopen(filename);
if fileID == -1
    % Can't find text file defining crop mix parameters
    % Throw error message
    fprintf(2,'Error - Crop mix input file not found\n');
end
% Number of crops
nCrops = cell2mat(textscan(fileID,'%f %*s',1,'delimiter',':','headerlines',1));
% Crop information (type and filename)
CropInfo = textscan(fileID,'%s %s %s %s',nCrops,'headerlines',5);
fclose(fileID);

%% Read crop parameter input files %%
% Create blank structure
Crop = struct();
% Define variable names 
varnames = {'CropType';'PlantMethod';'CalendarType';'SwitchGDD';'PlantingDate';...
    'HarvestDate';'Emergence';'MaxRooting';'Senescence';'Maturity';...
    'HIstart';'Flowering';'YldForm';'GDDmethod';'Tbase';'Tupp';...
    'PolHeatStress';'Tmax_up';'Tmax_lo';'PolColdStress';'Tmin_up';...
    'Tmin_lo';'TrColdStress';'GDD_up';'GDD_lo';'Zmin';'Zmax';...
    'fshape_r';'SxTopQ';'SxBotQ';'SeedSize';'PlantPop';'CCx';'CDC';...
    'CGC';'Kcb';'fage';'WP';'WPy';'fsink';'HI0';'dHI_pre';'a_HI';'b_HI';...
    'dHI0';'Determinant';'exc';'p_up1';'p_up2';'p_up3';'p_up4';...
    'p_lo1';'p_lo2';'p_lo3';'p_lo4';'fshape_w1';'fshape_w2';'fshape_w3';...
    'fshape_w4'}; 

% Loop crop types
for ii = 1:nCrops
    % Open file
    filename = strcat(Location,CropInfo{1,2}{ii});
    fileID = fopen(filename);
    if fileID == -1
        % Can't find text file defining crop mix parameters
        % Throw error message
        fprintf(2,strcat('Error - Crop parameter input file, ',CropInfo{1,1}{ii},'not found\n'));
    end
    % Load data
    DataArray = textscan(fileID,'%f %*s','delimiter',':','headerlines',7);
    fclose(fileID);
    % Create crop parameter structure
    Crop.(CropInfo{1,1}{ii}) = cell2struct(num2cell(DataArray{1,1}),varnames(7:end));

    %% pre-calculate GDD
    count = 0;
    GDDacc = 0;
    while GDDacc < Crop.(CropInfo{1,1}{ii}).Maturity + 100
        GDDacc = GDDacc + DA_GrowingDegreeDay(Crop.(CropInfo{1,1}{ii}),Tmax(StartRow + count),Tmin(StartRow + count));
        count = count + 1;
    end   
    sim_e = datestr(StartDate + count, 'yyyy-mm-dd');
    %fprintf('Simulation start from %s to %s with GDDaccum %.1f\n',sim_s,sim_e,GDDacc)
end    
end