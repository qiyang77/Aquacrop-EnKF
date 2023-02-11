function [ClockStruct] = DA_ReadClockParameters(sim_s, sim_e, offseason)
% Function to read input files and initialise model clock parameters

%% Read clock parameter input file %%
% Create and assign variables
varnames = {'SimulationStartTime';'SimulationEndTime';'OffSeason'};
ClockStruct = cell2struct({sim_s; sim_e; offseason},varnames);

%% Define clock parameters %%
% Initialise time step counter
ClockStruct.TimeStepCounter = 1;
% Initialise model termination condition
ClockStruct.ModelTermination = false;
% Simulation start time as serial date number
DateStaV = datevec(ClockStruct.SimulationStartTime,'yyyy-mm-dd');
ClockStruct.SimulationStartDate = datenum(DateStaV);
% Simulation end time as serial date number
DateStoV = datevec(ClockStruct.SimulationEndTime,'yyyy-mm-dd');
ClockStruct.SimulationEndDate = datenum(DateStoV);
% Time step (years)
ClockStruct.TimeStep = 1;
% Total numbers of time steps (days)
ClockStruct.nSteps = ClockStruct.SimulationEndDate-...
    ClockStruct.SimulationStartDate;
% Time spans
TimeSpan = zeros(1,ClockStruct.nSteps+1);
TimeSpan(1) = ClockStruct.SimulationStartDate;
TimeSpan(end) = ClockStruct.SimulationEndDate;
for ss = 2:ClockStruct.nSteps
    TimeSpan(ss) = TimeSpan(ss-1)+1;
end
ClockStruct.TimeSpan = TimeSpan;
% Time at start of current time step
ClockStruct.StepStartTime = ClockStruct.TimeSpan(ClockStruct.TimeStepCounter);
% Time at end of current time step 
ClockStruct.StepEndTime = ClockStruct.TimeSpan(ClockStruct.TimeStepCounter+1);
% Number of time-steps (per day) for soil evaporation calculation
ClockStruct.EvapTimeSteps = 20;

end