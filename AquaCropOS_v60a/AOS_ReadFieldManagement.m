function [FieldMngtStruct] = AOS_ReadFieldManagement(ParamStruct,FileLocation)
% Function to read input files and initialise field management parameters

%% Get input file location %%
Location = FileLocation.Input;

%% Read field management parameter input files (growing seasons) %%
% Check for number of crop types
Crops = fieldnames(ParamStruct.Crop);
nCrops = length(Crops);
% Create blank structure
FieldMngtStruct = struct();
% Define variable names 
varnames = {'MulchPct';'fMulch';'zBund';'BundWater';'CNadjPct'};

for ii = 1:nCrops
    % Open file
    filename = strcat(Location,ParamStruct.Crop.(Crops{ii}).FieldMngtFile);
    fileID = fopen(filename);
    if fileID == -1
        % Can't find text file defining irrigation management
        % Throw error message
        fprintf(2,strcat('Error - Field management input file not found for ',Crops{ii},'\n'));
    end
    % Load data
    Mulches = strtrim(textscan(fileID,'%s %*s',1,'delimiter',':','headerlines',1));
    Bunds = strtrim(textscan(fileID,'%s %*s',1,'delimiter',':'));
    CNadj = strtrim(textscan(fileID,'%s %*s',1,'delimiter',':'));
    SRinhb = strtrim(textscan(fileID,'%s %*s',1,'delimiter',':'));
    DataArray = textscan(fileID,'%f %*s','delimiter',':');
    fclose(fileID);
    
    % Create and assign numeric variables
    FieldMngtStruct.(Crops{ii}) = cell2struct(num2cell(DataArray{1,1}),varnames);
    % Add additional string variables
    FieldMngtStruct.(Crops{ii}).Mulches = Mulches{:}{:};
    FieldMngtStruct.(Crops{ii}).Bunds = Bunds{:}{:};
    FieldMngtStruct.(Crops{ii}).SRinhb = SRinhb{:}{:};
    FieldMngtStruct.(Crops{ii}).CNadj = CNadj{:}{:};
end

%% Read field management practice input file (fallow periods) %%
% Open file
filename = strcat(Location,FileLocation.FieldMngtFallowFilename);
fileID = fopen(filename);
if fileID == -1
    % Can't find text file defining soil parameters
    % Throw error message
    fprintf(2,'Error - Field management input file for fallow periods not found\n');
end

% Load data
Mulches = strtrim(textscan(fileID,'%s %*s',1,'delimiter',':','headerlines',1));
Bunds = strtrim(textscan(fileID,'%s %*s',1,'delimiter',':'));
CNadj = strtrim(textscan(fileID,'%s %*s',1,'delimiter',':'));
SRinhb = strtrim(textscan(fileID,'%s %*s',1,'delimiter',':'));
DataArray = textscan(fileID,'%f %*s','delimiter',':');
fclose(fileID);

% Create and assign numeric variables
FieldMngtStruct.Fallow = cell2struct(num2cell(DataArray{1,1}),varnames);
% Add additional string variables
FieldMngtStruct.Fallow.Mulches = Mulches{:}{:};
FieldMngtStruct.Fallow.Bunds = Bunds{:}{:};
FieldMngtStruct.Fallow.SRinhb = SRinhb{:}{:};
FieldMngtStruct.Fallow.CNadj = CNadj{:}{:};

end