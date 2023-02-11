function [IrrMngtStruct] = SA_ReadIrrigationManagement...
    (ParamStruct,Irr)
% Function to read and initialise irrigation management parameters

%% Read irrigation management input files %%
% Check for number of crop types
Crops = fieldnames(ParamStruct.Crop);
nCrops = length(Crops);
% Create blank structure
IrrMngtStruct = struct();

for ii = 1:nCrops
    
    % Create and assign numeric variables
    IrrMngtStruct.(Crops{ii}) = Irr;
    
    % Consolidate soil moisture targets in to one variable
    IrrMngtStruct.(Crops{ii}).SMT = [IrrMngtStruct.(Crops{ii}).SMT1,...
        IrrMngtStruct.(Crops{ii}).SMT2,IrrMngtStruct.(Crops{ii}).SMT3,...
        IrrMngtStruct.(Crops{ii}).SMT4];
    IrrMngtStruct.(Crops{ii}) = rmfield(IrrMngtStruct.(Crops{ii}),...
        {'SMT1','SMT2','SMT3','SMT4'});
    
    % If specified, read input irrigation time-series
    if IrrMngtStruct.(Crops{ii}).IrrMethod == 3
        % Throw error message
        fprintf(2,strcat('Error - This function not provide by Qi \n'));

    end
end

end