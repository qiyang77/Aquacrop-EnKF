# -*- coding: utf-8 -*-
"""
Created on Sat Aug 31 20:31:22 2019

@author: Reborn

Required Parameters (hourly & daily)
ea	ndarray	Actual vapor pressure [kPa]
rs	ndarray	Incoming shortwave solar radiation [MJ m-2 day-1]
uz	ndarray	Wind speed [m s-1]
zw	float	Wind speed height [m]
elev	ndarray	Elevation [m]
lat	ndarray	Latitude [degrees]
doy	ndarray	Day of year

Required Daily Parameters
Variable	Type	Description [default units]
tmin	ndarray	Minimum daily temperature [C]
tmax	ndarray	Maximum daily temperature [C]

Required Hourly Parameters
Variable	Type	Description [default units]
tmean	ndarray	Average hourly temperature [C]
lon	ndarray	Longitude [degrees]
time	ndarray	UTC hour at start of time period

Optional Parameters
Variable	Type	Description [default units]
method	str	
Calculation method
'asce' -- Calculations will follow ASCE-EWRI 2005 (default)
'refet' -- Calculations will follow RefET software
rso_type	str	
Override default clear sky solar radiation (Rso) calculation
Defaults to None if not set
'full' -- Full clear sky solar formulation
'simple' -- Simplified clear sky solar formulation
'array' -- Read Rso values from "rso" function parameter
rso	array_like	
Clear sky solar radiation [MJ m-2 day-1]
Only used if rso_type == 'array'
Defaults to None if not set
input_units	dict	
Override default input unit types
Input values will be converted to default unit types

"""
import math
import refet
import numpy as np
import datetime
import os

# Cal ETo
def cal_et(lat, elev, method, cli_file, start_day): # start_day = [2018,12,30]
    data = cli_file
    
    start = datetime.datetime(start_day[0],start_day[1],start_day[2])
    [row,col] = np.shape(data)
    eto = []
    tmax_list = []
    tmin_list = []
    rain_list = []
    for i in range(0, row):
        tmax = data[i,0+3]
        tmin = data[i,1+3]
        rs = data[i,2+3] 
        tdew_c = data[i,3+3]
        uz = data[i,4+3] 
        rain = data[i,5+3]
        MaxRH = data[i,6+3] / 100.0
        MinRH = data[i,7+3] / 100.0
        # Cal ea
        if MaxRH == -9.99:
            ea = refet.calcs._sat_vapor_pressure(tdew_c)
        else:
            e_0_max = 0.6108 * math.exp(17.27 * tmax / (tmax + 237.3))
            e_0_min = 0.6108 * math.exp(17.27 * tmin / (tmin + 237.3))
            ea = (e_0_min * MaxRH + e_0_max * MinRH) / 2 
        #
        # doy = DOY_satrt + i
        start += datetime.timedelta(days=1)   ## BUG of DOY, repaired by YQ at 20200204
        doy = int(start.strftime('%j'))
    #    #
    #    ra = refet.calcs._ra_daily(lat *(math.pi / 180.0), doy, method)
    #    rso = refet.calcs._rso_simple(ra, elev)
    #    #
        eto_day = refet.Daily(
            tmin=tmin, tmax=tmax, ea=ea, rs=rs, uz=uz, zw=2.0, elev=elev,
            lat=lat, doy=doy, method=method,
            input_units={'tmin': 'C', 'tmax': 'C', 'rs': 'mj m-2 day-1', 'uz': 'm/s',
                         'lat': 'deg'}
            ).eto()
        eto.append(eto_day)
        tmax_list.append(tmax)
        tmin_list.append(tmin)
        rain_list.append(rain)
    return eto, tmax_list, tmin_list, rain_list
      
# Cal ETo for single day
def cal_et_oneday(lat, elev, method, single_cli, current_day): 
    data = single_cli
    eto = []
    tmax_list = []
    tmin_list = []
    rain_list = []

    tmax = data[0]
    tmin = data[1]
    rs = data[2] 
    tdew_c = data[3]
    uz = data[4] 
    rain = data[5]
    MaxRH = data[6] / 100.0
    MinRH = data[7] / 100.0
    # Cal ea
    if MaxRH == -9.99:
        ea = refet.calcs._sat_vapor_pressure(tdew_c)
    else:
        e_0_max = 0.6108 * math.exp(17.27 * tmax / (tmax + 237.3))
        e_0_min = 0.6108 * math.exp(17.27 * tmin / (tmin + 237.3))
        ea = (e_0_min * MaxRH + e_0_max * MinRH) / 2 

    doy = int(current_day.strftime('%j'))
#    #
#    ra = refet.calcs._ra_daily(lat *(math.pi / 180.0), doy, method)
#    rso = refet.calcs._rso_simple(ra, elev)
#    #
    eto_day = refet.Daily(
        tmin=tmin, tmax=tmax, ea=ea, rs=rs, uz=uz, zw=2.0, elev=elev,
        lat=lat, doy=doy, method=method,
        input_units={'tmin': 'C', 'tmax': 'C', 'rs': 'mj m-2 day-1', 'uz': 'm/s',
                     'lat': 'deg'}
        ).eto()
    eto.append(eto_day)
    tmax_list.append(tmax)
    tmin_list.append(tmin)
    rain_list.append(rain)
    return eto, tmax_list, tmin_list, rain_list

def write_ini(out_path, station, ini_status):
    
    if len(ini_status) != 19:
        print('ini_stuatus get a wrong length!')
    if not os.path.exists(out_path):
        os.mkdir(out_path)
    with open (out_path + '/' + station  + '.SW0','w') as f:
        f.writelines(station + '\n')
        f.writelines('6.1  : AquaCrop Version (May 2018) \n')
        f.writelines(str(ini_status[0]) + '  : initial canopy cover (%) at start of simulation period \n')
        f.writelines(str(ini_status[1]) + '  : biomass (ton/ha) produced before the start of the simulation period \n')
        f.writelines(str(ini_status[2]) + '  : initial effective rooting depth (m) at start of simulation period \n')
        f.writelines(str(ini_status[3]) + '  : water layer (mm) stored between soil bunds (if present) \n')
        f.writelines(str(ini_status[4]) + '  : electrical conductivity (dS/m) of water layer stored between soil bunds (if present) \n')
        f.writelines(str(int(ini_status[5])) + '  : soil water content specified for specific layers \n')
        f.writelines(str(int(ini_status[6])) + '  : number of layers considered \n')
        f.writelines(' \n')
        f.writelines('Thickness layer (m)     Water content (vol%)     ECe(dS/m) \n')
        f.writelines('============================================================== \n')
        for i in range(0, 12):
            f.writelines('         0.10                ' + '%.2f' % ini_status[i + 7] + '                  0.00 \n')
            
def write_cli(out_path, station, eto, tmax_list, tmin_list, rain_list, start_day):
    [row,col] = np.shape(eto)
    if not os.path.exists(out_path):
        os.mkdir(out_path)
    with open (out_path + '/' + station  + '.ETo','w') as f:
        f.writelines(station + '\n')
        f.writelines('1  : Daily records (1=daily, 2=10-daily and 3=monthly data) \n')
        f.writelines(str(start_day[2]) + '  : First day of record (1, 11 or 21 for 10-day or 1 for months) \n')
        f.writelines(str(start_day[1]) + '  : First month of record \n')
        f.writelines(str(start_day[0]) + '  : First year of record (1901 if not linked to a specific year) \n')
        f.writelines(' \n')
        f.writelines('  Average ETo (mm/day) \n')
        f.writelines('======================= \n')
        for i in range(0, row):
            f.writelines('%.3f' % eto[i][0] + '\n')
        
    with open (out_path + '/' + station  + '.PLU','w') as f:
        f.writelines(station + '\n')
        f.writelines('1  : Daily records (1=daily, 2=10-daily and 3=monthly data) \n')
        f.writelines(str(start_day[2]) + '  : First day of record (1, 11 or 21 for 10-day or 1 for months) \n')
        f.writelines(str(start_day[1]) + '  : First month of record \n')
        f.writelines(str(start_day[0]) + '  : First year of record (1901 if not linked to a specific year) \n')
        f.writelines(' \n')
        f.writelines('  Total Rain (mm) \n')
        f.writelines('======================= \n')
        for i in range(0, row):
            f.writelines('%.3f' % rain_list[i] + '\n')
            
    with open (out_path + '/' + station  + '.TMP','w') as f:
        f.writelines(station + '\n')
        f.writelines('1  : Daily records (1=daily, 2=10-daily and 3=monthly data) \n')
        f.writelines(str(start_day[2]) + '  : First day of record (1, 11 or 21 for 10-day or 1 for months) \n')
        f.writelines(str(start_day[1]) + '  : First month of record \n')
        f.writelines(str(start_day[0]) + '  : First year of record (1901 if not linked to a specific year) \n')
        f.writelines(' \n')
        f.writelines('  Tmin (C)   TMax (C) \n')
        f.writelines('======================= \n')
        for i in range(0, row):
            f.writelines('%.3f' % tmin_list[i] + ' ' + '%.3f' % tmax_list[i]+ '\n')
            
    with open (out_path + '/' + station  + '.CLI','w') as f:
        f.writelines(station + '\n')
        f.writelines(' 6.1   : AquaCrop Version (May 2018) \n')
        f.writelines(station + '.TMP \n')
        f.writelines(station + '.ETo \n')
        f.writelines(station + '.PLU \n')
        f.writelines('MaunaLoa.CO2 \n')
              
def write_project(station, seed_day, sim_start_day, sim_end_day, out_path, para_path, management):
    
#    if os.path.exists('PROJECT_FILE/' + station + '.PRO'):
#        os.remove('PROJECT_FILE/' + station + '.PRO')
#    shutil.copy('DATA/project_head.txt','PROJECT_FILE/' + station + '.PRO')
    if not os.path.exists(out_path):
        os.mkdir(out_path)
    [irrgation, groudwater, initial, offseason] = management
    default_para = '  4         : Evaporation decline factor for stage II \n\
      1.10      : Ke(x) Soil evaporation coefficient for fully wet and non-shaded soil surface \n\
      5         : Threshold for green CC below which HI can no longer increase (% cover) \n\
     70         : Starting depth of root zone expansion curve (% of Zmin) \n\
      5.00      : Maximum allowable root zone expansion (fixed at 5 cm/day) \n\
     -6         : Shape factor for effect water stress on root zone expansion \n\
     20         : Required soil water content in top soil for germination (% TAW) \n\
      1.0       : Adjustment factor for FAO-adjustment soil water depletion (p) by ETo \n\
      3         : Number of days after which deficient aeration is fully effective \n\
      1.00      : Exponent of senescence factor adjusting drop in photosynthetic activity of dying crop \n\
     12         : Decrease of p(sen) once early canopy senescence is triggered (% of p(sen)) \n\
     10         : Thickness top soil (cm) in which soil water depletion has to be determined \n\
     30         : Depth [cm] of soil profile affected by water extraction by soil evaporation \n\
      0.30      : Considered depth (m) of soil profile for calculation of mean soil water content for CN adjustment \n\
      1         : CN is adjusted to Antecedent Moisture Class \n\
     20         : salt diffusion factor (capacity for salt diffusion in micro pores) [%] \n\
    100         : salt solubility [g/liter] \n\
     16         : shape factor for effect of soil water content gradient on capillary rise \n\
     12.0       : Default minimum temperature (癈) if no temperature file is specified \n\
     28.0       : Default maximum temperature (癈) if no temperature file is specified \n\
      3         : Default method for the calculation of growing degree days \n'
    month_DOY = [0, 31, 59.25, 90.25, 120.25,
                 151.25, 181.25, 212.25, 243.25,
                 273.25, 304.25, 334.25]
    seed_start_doy = np.int32(np.floor((seed_day[0] - 1901) * 365.25 \
                                       + month_DOY[seed_day[1]-1] + seed_day[2]))
    sim_start_doy = np.int32(np.floor((sim_start_day[0] - 1901) * 365.25\
                                      + month_DOY[sim_start_day[1]-1] + sim_start_day[2]))
    sim_end_doy = np.int32(np.floor((sim_end_day[0] - 1901) * 365.25\
                                      + month_DOY[sim_end_day[1]-1] + sim_end_day[2]))
    current_path = os.path.abspath(__file__)
    father_path = os.path.abspath(os.path.dirname(current_path) + os.path.sep + ".")
#    print ('current path is : ' + father_path)
    
    with open ('LIST/' + station  + '.PRO','w') as f:
            f.writelines(station + '\n')
            f.writelines(' 6.1   : AquaCrop Version (May 2018) \n')
            f.writelines(str(sim_start_doy) + '  : First day of simulation period \n')
            f.writelines(str(sim_end_doy) + '  : Last day of simulation period \n')
            f.writelines(str(seed_start_doy) + '  : First day of cropping period \n')
            f.writelines(str(0) + '  : Last day of cropping period \n')
            f.writelines(default_para)
            f.writelines('-- 1. Climate (CLI) file \n')          
            f.writelines('   ' + station + '.CLI \n')
            f.writelines('   ' + father_path  + '/' + out_path + '/ \n')
            f.writelines('   1.1 Temperature (Tnx or TMP) file \n')
            f.writelines('   ' + station + '.TMP \n')
            f.writelines('   ' + father_path  + '/' + out_path + '/ \n')
            f.writelines('   1.2 Reference ET (ETo) file \n')
            f.writelines('   ' + station + '.ETo \n')
            f.writelines('   ' + father_path  + '/' + out_path + '/ \n')
            f.writelines('   1.3 Rain (PLU) file \n')
            f.writelines('   ' + station + '.PLU \n')
            f.writelines('   ' + father_path  + '/' + out_path + '/ \n')
            f.writelines('   1.4 Atmospheric CO2 concentration (CO2) file \n')
            f.writelines('   MaunaLoa.CO2 \n')
            f.writelines('   ' + father_path  + '/' + para_path + '/ \n')
            f.writelines('-- 2. Crop (CRO) file \n')
            f.writelines('   PaddyRiceGDD.CRO \n')
            f.writelines('   ' + father_path  + '/' + para_path + '/ \n')
            f.writelines('-- 3. Irrigation management (IRR) file \n')
            if irrgation == False:
                f.writelines('   (None) \n')
                f.writelines('   (None) \n')
            else:
                f.writelines('   ' + station + '.IRR \n')
                f.writelines('   ' + father_path  + '/' + para_path + '/ \n')
            f.writelines('-- 4. Field management (MAN) file \n')
            f.writelines('   Bunds.MAN \n')
            f.writelines('   ' + father_path  + '/' + para_path + '/ \n')
            f.writelines('-- 5. Soil profile (SOL) file \n')
            f.writelines('   PADDY.SOL \n')
            f.writelines('   ' + father_path  + '/' + para_path + '/ \n')
            f.writelines('-- 6. Groundwater table (GWT) file \n')
            if groudwater == False:
                f.writelines('   (None) \n')
                f.writelines('   (None) \n')
            else:
                f.writelines('   ' + station + '.GWT \n')
                f.writelines('   ' + father_path  + '/' + para_path + '/ \n')
            f.writelines('-- 7. Initial conditions (SW0) file \n')
            if initial == False:
                f.writelines('   (None) \n')
                f.writelines('   (None) \n')
            else:
                f.writelines('   ' + station + '.SW0 \n')
                f.writelines('   ' + father_path  + '/' + para_path + '/ \n')
            f.writelines('-- 8. Off-season conditions (OFF) file \n')
            if offseason == False:
                f.writelines('   (None) \n')
                f.writelines('   (None) \n')
            else:
                f.writelines('   ' + station + '.OFF \n')
                f.writelines('   ' + father_path  + '/' + para_path + '/ \n')
if __name__ == '__main__':
    
    # Hyperparameters
    lat=23.11
    elev=100.0
    method='asce'
    cli_file = 'DATA/bingyang_20180713_20181126.txt'
    station = 'binyang'
    out_path = 'PROJECT_FILE'
    head_path = 'DATA/project_head.txt'
    
    ## management
    irrgation = False
    groudwater = False
    initial = False
    offseason = False
    management = [irrgation, groudwater, initial, offseason]
    ##
    cli_start_day = [2018, 7, 13]
    seed_day = [2018, 7, 21]
    sim_start_day = [2018, 7, 21]
    sim_end_day = [2018, 11, 21]
    eto, tmax_list, tmin_list, rain_list = cal_et(lat = lat, elev = elev, method = method, 
                                                  cli_file = cli_file,start_day = cli_start_day)
    write_cli(out_path = out_path, station = station, eto = eto, 
              tmax_list = tmax_list, tmin_list = tmin_list, rain_list = rain_list,start_day = cli_start_day)
    write_project( out_path = out_path, station = station, seed_day = seed_day, 
                  sim_start_day = sim_start_day, sim_end_day = sim_end_day, management = management)
# write CLI to txt
