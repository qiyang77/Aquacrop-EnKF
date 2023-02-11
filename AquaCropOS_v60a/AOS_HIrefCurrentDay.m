function [NewCond] = AOS_HIrefCurrentDay(InitCond,Crop,GrowingSeason)
% Function to calculate reference (no adjustment for stress effects)
% harvest index on current day

%% Store initial conditions for updating %%
NewCond = InitCond;

%% Calculate reference harvest index (if in growing season) %%
if GrowingSeason == true
    % Check if in yield formation period
    tAdj = NewCond.DAP-NewCond.DelayedCDs;
    if tAdj > Crop.HIstartCD
        NewCond.YieldForm = true;
    else
        NewCond.YieldForm = false;
    end 

    % Get time for harvest index calculation  
    % NewCond = AOS_InitialiseStruct.InitialCondition;
    HIt = NewCond.DAP-NewCond.DelayedCDs-Crop.HIstartCD-1;
    
%     if (HIt <= 0)   %commented out by Qi 21/7/29
    if (HIt <= 0)&&(InitCond.HIref == 0)  %modified by Qi 21/7/29
        % Yet to reach time for HI build-up
        NewCond.HIref = 0;
        NewCond.PctLagPhase = 0;
    elseif (HIt <= 0)&&(InitCond.HIref ~= 0)  %added by Qi 21/7/29, aviod force update the HI after assmilating GDD
           NewCond.HIref = InitCond.HIref; 
    else
        if NewCond.CCprev <= (Crop.CCmin*Crop.CCx)
            % HI cannot develop further as canopy cover is too small
            NewCond.HIref = InitCond.HIref;
        else
            % Check crop type
            if (Crop.CropType == 1) || (Crop.CropType == 2)
                % If crop type is leafy vegetable or root/tuber, then proceed with
                % logistic growth (i.e. no linear switch)
                NewCond.PctLagPhase = 100; % No lag phase
                % Calculate reference harvest index for current day
                NewCond.HIref = (Crop.HIini*Crop.HI0)/(Crop.HIini+...
                    (Crop.HI0-Crop.HIini)*exp(-Crop.HIGC*HIt));
                % Harvest index apprAOShing maximum limit
                if NewCond.HIref >= (0.9799*Crop.HI0)
                    NewCond.HIref = Crop.HI0;
                end
            elseif Crop.CropType == 3
                % If crop type is fruit/grain producing, check for linear switch
                if HIt < Crop.tLinSwitch
                    % Not yet reached linear switch point, therefore proceed with
                    % logistic build-up
                    NewCond.PctLagPhase = 100*(HIt/Crop.tLinSwitch);
                    % Calculate reference harvest index for current day
                    % (logistic build-up)
                    if (HIt == 1)&&(InitCond.HIref == 0)  % by Qi 2021-7-25, to make the HIref accumulative
                        NewCond.HIref = (Crop.HIini*Crop.HI0)/(Crop.HIini+... % Crop = AOS_InitialiseStruct.Parameter.Crop.RiceGDD;
                            (Crop.HI0-Crop.HIini)*exp(-Crop.HIGC*HIt));
                    else
                        delta_HIref = (Crop.HIini*Crop.HI0)/(Crop.HIini+...
                            (Crop.HI0-Crop.HIini)*exp(-Crop.HIGC*HIt))-...
                            (Crop.HIini*Crop.HI0)/(Crop.HIini+... 
                            (Crop.HI0-Crop.HIini)*exp(-Crop.HIGC*(HIt-1)));
                        NewCond.HIref = NewCond.HIref + delta_HIref;
%                         fprintf('HIt:%.1f, delta_HIref:%.4f, HIref:%.4f\n',HIt, delta_HIref, NewCond.HIref) 
                    end
                    NewCond.HIref_noaccum = (Crop.HIini*Crop.HI0)/(Crop.HIini+... 
                        (Crop.HI0-Crop.HIini)*exp(-Crop.HIGC*HIt));
%                     NewCond.HIref = NewCond.HIref_noaccum; % test
                else
                    % Linear switch point has been reached
                    NewCond.PctLagPhase = 100;        
                    % Calculate reference harvest index for current day
                    % (logistic portion)
                    NewCond.HIref_noaccum = (Crop.HIini*Crop.HI0)/(Crop.HIini+...   % commented out by Qi 2021-7-25, to make the HIref accumulative
                        (Crop.HI0-Crop.HIini)*exp(-Crop.HIGC*Crop.tLinSwitch));
                    NewCond.HIref_noaccum = NewCond.HIref_noaccum+(Crop.dHILinear*...
                        (HIt-Crop.tLinSwitch));                    
                    % Calculate reference harvest index for current day
                    % (total - logistic portion + linear portion)
                    
                    delta_HIref_linear = Crop.dHILinear*(HIt-Crop.tLinSwitch) - Crop.dHILinear*(HIt-1-Crop.tLinSwitch);
                    NewCond.HIref = NewCond.HIref + delta_HIref_linear;
%                     NewCond.HIref = NewCond.HIref_noaccum; % test
                end
%                 fprintf('DAP:%d, Ht:%.2f,HIref-no accumulated:%.3f, HIref_accumulated:%.3f\n',NewCond.DAP,HIt, NewCond.HIref_noaccum, NewCond.HIref)
            end
            % Limit HIref and round off computed value
            if NewCond.HIref > Crop.HI0
                NewCond.HIref = Crop.HI0;
%             elseif NewCond.HIref <= (Crop.HIini+0.004) % discard by Qi
%             2021-7-27 to aviod HI equal 0 after DAP updated
%             elseif NewCond.HIref <= (Crop.HIini)   % Modified by Qi 2021-7-25
%                 NewCond.HIref = 0;
            elseif ((Crop.HI0-NewCond.HIref)<0.004)
                NewCond.HIref = Crop.HI0;
            end
        end
%         fprintf('DAP:%d, HIref:%.3f\n',NewCond.DAP, NewCond.HIref)
    end
%     fprintf('DAP:%d, Ht:%.2f, HIref:%.3f\n',NewCond.DAP,HIt, NewCond.HIref)
else
    % Reference harvest index is zero outside of growing season
    NewCond.HIref = 0;
end

end

