% function [] = AquaCropOS_RUN()
clc
clear
% ---------------------------------------------------------------------- %
% Tim Foster                                                             %
% July 2018                                                              %
%                                                                        %
% Function to run AquaCrop-OS v6.0a                                      %
%                                                                        %
% ---------------------------------------------------------------------- %

%% Declare global variables %%
global AOS_ClockStruct

%% Run model %%
% Initialise simulation
AOS_Initialize();

% Perform single time-step (day)
while AOS_ClockStruct.ModelTermination == false
   AOS_PerformTimeStep();
end

% Finish simulation
AOS_Finish();

% end