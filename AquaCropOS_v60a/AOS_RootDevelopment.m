function [NewCond] = AOS_RootDevelopment(Crop,Soil,Groundwater,...
    InitCond,GDD,GrowingSeason)
% Function to calculate root zone expansion

%% Store initial conditions for updating %%
NewCond = InitCond;

%% Calculate root expansion (if in growing season) %%
if GrowingSeason == true
    % If today is first day of season, root depth is equal to minimum depth
    if NewCond.DAP == 1
        InitCond.Zroot = Crop.Zmin;
    end
    % Adjust time for any delayed development
    if Crop.CalendarType == 1
        tAdj = NewCond.DAP-NewCond.DelayedCDs;
    elseif Crop.CalendarType == 2
        tAdj = NewCond.GDDcum-NewCond.DelayedGDDs;
    end
    % Calculate root expansion %
    Zini = Crop.Zmin*(Crop.PctZmin/100);
    t0 = round((Crop.Emergence/2));
    tmax = Crop.MaxRooting;
    if Crop.CalendarType == 1
        tOld = tAdj-1;
    elseif Crop.CalendarType == 2
        tOld = tAdj-GDD;
    end

    % Potential root depth on previous day
    if tOld >= tmax
        ZrOld = Crop.Zmax;
    elseif tOld <= t0
        ZrOld = Zini;
    else
        X = (tOld-t0)/(tmax-t0);
        ZrOld = Zini+(Crop.Zmax-Zini)*nthroot(X,Crop.fshape_r);
    end
    if ZrOld < Crop.Zmin
        ZrOld = Crop.Zmin;
    end

    % Potential root depth on current day
    if tAdj >= tmax
        Zr = Crop.Zmax;
    elseif tAdj <= t0
        Zr = Zini;
    else
        X = (tAdj-t0)/(tmax-t0);
        Zr = Zini+(Crop.Zmax-Zini)*nthroot(X,Crop.fshape_r);
    end
    if Zr < Crop.Zmin
        Zr = Crop.Zmin;
    end
    % Store Zr as potential value
    ZrPot = Zr;
    
    % Determine rate of change
    dZr = Zr-ZrOld;
    
    % Adjust expansion rate for presence of restrictive soil horizons
    if Zr > Crop.Zmin
        layeri = 1;
        Zsoil = Soil.Layer.dz(layeri);
        while (Zsoil <= Crop.Zmin) && (layeri < Soil.nLayer)
            layeri = layeri+1;
            Zsoil = Zsoil+Soil.Layer.dz(layeri);
        end
        ZrAdj = Crop.Zmin;
        ZrRemain = Zr-Crop.Zmin;
        deltaZ = Zsoil-Crop.Zmin;
        EndProf = false;
        while EndProf == false
            ZrTest = ZrAdj+(ZrRemain*(Soil.Layer.Penetrability(layeri)/100));
            if (layeri == Soil.nLayer) || (Soil.Layer.Penetrability(layeri)==0) ||...
                    (ZrTest<=Zsoil)
                ZrOUT = ZrTest;
                EndProf = true;
            else
                ZrAdj = Zsoil;
                ZrRemain = ZrRemain-(deltaZ/(Soil.Layer.Penetrability(layeri)/100));
                layeri = layeri+1;
                Zsoil = Zsoil+Soil.Layer.dz(layeri);
                deltaZ = Soil.Layer.dz(layeri);
            end
        end
        % Correct Zr and dZr for effects of restrictive horizons
        Zr = ZrOUT;
        dZr = Zr-ZrOld;
    end
    
    % Adjust rate of expansion for any stomatal water stress
    if NewCond.TrRatio < 0.9999
        if Crop.fshape_ex >= 0
            dZr = dZr*NewCond.TrRatio;
        else
            fAdj = (exp(NewCond.TrRatio*Crop.fshape_ex)-1)/(exp(Crop.fshape_ex)-1);
            dZr = dZr*fAdj;
        end
    end

    % Adjust rate of root expansion for dry soil at expansion front
    if dZr > 0.001
        % Define water stress threshold for inhibition of root expansion
        pZexp = Crop.p_up(2)+((1-Crop.p_up(2))/2);
        % Define potential new root depth
        ZiTmp = InitCond.Zroot+dZr;
        % Find compartment that root zone will expand in to
        compi = find(Soil.Comp.dzsum>=ZiTmp,1,'first');
        % Get TAW in compartment
        layeri = Soil.Comp.Layer(compi);
        TAWcompi = (Soil.Layer.th_fc(layeri)-Soil.Layer.th_wp(layeri));
        % Define stress threshold
        thThr = Soil.Layer.th_fc(layeri)-(pZexp*TAWcompi);
        % Check for stress conditions
        if NewCond.th(compi) < thThr
            % Root expansion limited by water content at expansion front
            if NewCond.th(compi) <= Soil.Layer.th_wp(layeri)
                % Expansion fully inhibited
                dZr = 0;
            else
                % Expansion partially inhibited
                Wrel = (Soil.Layer.th_fc(layeri)-NewCond.th(compi))/...
                    TAWcompi;
                Drel = 1-((1-Wrel)/(1-pZexp));
                Ks = 1-((exp(Drel*Crop.fshape_w(2))-1)/(exp(Crop.fshape_w(2))-1));
                dZr = dZr*Ks;
            end
        end
    end
    
    % Adjust for early senescence 
    if (NewCond.CC <= 0) && (NewCond.CC_NS > 0.5)
        dZr = 0;
    end
    
    % Adjust root expansion for failure to germinate (roots cannot expand
    % if crop has not germinated)
    if InitCond.Germination == false
        dZr = 0;
    end

    % Get new rooting depth
    NewCond.Zroot = InitCond.Zroot+dZr;

    % Adjust root density if deepening is restricted due to dry subsoil
    % and/or restrictive layers
    if NewCond.Zroot < ZrPot
        NewCond.rCor = (2*(ZrPot/NewCond.Zroot)*((Crop.SxTop+Crop.SxBot)/2)...
            -Crop.SxTop)/Crop.SxBot;
        if NewCond.Tpot > 0
            NewCond.rCor = NewCond.rCor*NewCond.TrRatio;
            if NewCond.rCor < 1
                NewCond.rCor = 1;
            end
        end
    else
        NewCond.rCor = 1;
    end
    
    % Limit rooting depth if groundwater table is present (roots cannot
    % develop below the water table)
    if (Groundwater.WaterTable == 1) && (NewCond.zGW > 0)
        if NewCond.Zroot > NewCond.zGW
            NewCond.Zroot = NewCond.zGW;
            if NewCond.Zroot < Crop.Zmin
                NewCond.Zroot = Crop.Zmin;
            end
        end
    end    
else
    % No root system outside of the growing season
    NewCond.Zroot = 0;
end
end