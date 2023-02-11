function [] = AOS_WriteOutputs()
% Function to write output files 

%% Define global variables %%
global AOS_ClockStruct
global AOS_InitialiseStruct

%% Define output file location and name %%
FileLoc = AOS_InitialiseStruct.FileLocation.Output;
FileName = AOS_InitialiseStruct.FileLocation.OutputFilename;

%% Write outputs (new) %%
if AOS_ClockStruct.ModelTermination == true
    if strcmp(AOS_InitialiseStruct.FileLocation.WriteDaily,'Y')
        % Water contents
        fid = fopen(strcat(FileLoc,FileName,'_WaterContents.txt'),'a+t');
        fprintf(fid,strcat('%-10d%-10d%-10d%-10d%-10d',repmat('%-15.2f',1,...
            AOS_InitialiseStruct.Parameter.Soil.nComp),'\n'),...
            AOS_InitialiseStruct.Outputs.WaterContents');
        fclose(fid);
        % Water fluxes
        fid = fopen(strcat(FileLoc,FileName,'_WaterFluxes.txt'),'a+t');
        fprintf(fid,strcat('%-10d%-10d%-10d%-10d%-10d%-15.2f%-15.2f%-15.2f',...
            '%-15.2f%-15.2f%-15.2f%-15.2f%-15.2f%-15.2f%-15.2f%-15.2f%-15.2f%-15.2f%-15.2f',...    % modified by Qi 20/3/23
            '%-15.2f%-15.2f%-15.2f\n'),AOS_InitialiseStruct.Outputs.WaterFluxes');
        fclose(fid);
        % Crop growth
        fid = fopen(strcat(FileLoc,FileName,'_CropGrowth.txt'),'a+t');
        fprintf(fid,strcat('%-10d%-10d%-10d%-10d%-10d%-15.2f%-15.2f%-15.2f',...   % modified by Qi 20/3/23
            '%-15.2f%-15.2f%-15.2f%-15.2f%-15.2f%-15.2f%-15.2f%-15.2f\n'),...
            AOS_InitialiseStruct.Outputs.CropGrowth');
        fclose(fid);
    end
    % Final output
    FinalOut = AOS_InitialiseStruct.Outputs.FinalOutput.';
    fid = fopen(strcat(FileLoc,FileName,'_FinalOutput.txt'),'a+t');
    fprintf(fid,'%-10d%-12s%-15s%-20d%-15s%-20d%-12.2f%-12.2f\n',...
        FinalOut{:});
    fclose(fid);
end

end