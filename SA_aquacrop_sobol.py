# -*- coding: utf-8 -*-
"""
Created on Tue Aug 25 11:43:05 2020

@author: WIN
"""

from SALib.sample import saltelli
from SALib.analyze import sobol
import numpy as np
import matlab.engine
import time
import copy

names_list = ['CN', 'th_s','th_s2','th_fc','th_fc2', 
              'th_wp','th_wp2','Ksat','Ksat2','REW',
              'Emerge','HIstart','Senescence','Maturity','YldForm',
              'Flowering','SeedSize','PlantPop','CGC','CCx',
              'CDC','Tbase','Tupp','MaxRooting','Zmax',
              'Zmin','fshape_r','SxTopQ','SxBotQ','Kcb',
              'fage','fwcc','WP','HI0','exc',
              'WPy','p_up1','p_lo1','fshape_w1','p_up2',
              'fshape_w2','p_up3','fshape_w3','p_up4','dHI_pre',
              'a_HI','b_HI','dHI0','Tmin_up','Tmax_up',
              'Tmin_lo','Tmax_lo','GDD_up']
bounds_list = [[68, 92],
               [0.52,0.56],
               [0.53,0.57],
               [0.48,0.52],
               [0.52,0.56],
               [0.30,0.34],
               [0.37,0.41],
               [10,20],
               [1,10],
               [5,10],
               [35,80],
               [1000,1200],
               [1080,1430],
               [1750,2000],
               [330,800],
               [280,420],
               [4.0,8.0],
               [900000,1200000],
               [0.005,0.009],
               [0.75,1.00],
               [0.003,0.007],
               [5,11],
               [30,45],
               [300,450],
               [0.40,0.60],
               [0.2,0.35],
               [1,5],
               [0.045,0.050],
               [0.010,0.014],
               [1.05,1.15],
               [0.1,0.5],
               [30,70],
               [15,20],
               [0.40,0.46],
               [20,300],
               [75,125],
               [0.10,0.30],
               [0.55,0.80],
               [1,5],
               [0.50,0.80],
               [1,5],
               [0.60,0.80],
               [1,5],
               [0.70,0.95],
               [0,10],
               [0.5,10.0],
               [1,20],
               [15,35],
               [8,12],
               [35,40],
               [3,7],
               [42,48],
               [6,15]]

para_default = [77,
                0.54,
                0.55,
                0.5,
                0.54,
                0.32,
                0.39,
                15,
                2,
                10,
                50,
                1150,
                1300,
                1900,
                680,
                350,
                6,
                1000000,
                0.007004,
                0.95,
                0.005003,
                8,
                30,
                370,
                0.5,
                0.3,
                2.5,
                0.048,
                0.012,
                1.1,
                0.15,
                50,
                19,
                0.43,
                100,
                100,
                0,
                0.4,
                3,
                0.5,
                3,
                0.55,
                3,
                0.75,
                0,
                10,
                7,
                15,
                8,
                35,
                5,
                45,
                10,]
## name, bound and location
Wet = ['th_wp', 'HIstart', 'Senescence', 'YldForm', 'SeedSize', 'CGC', 'CCx', 
       'CDC', 'Tbase', 'Zmax', 'Kcb', 'WP', 'HI0', 'WPy', 'a_HI']
Normal = ['th_s2', 'th_fc', 'th_fc2', 'th_wp', 'Ksat2', 'HIstart',
          'Senescence', 'Maturity', 'YldForm', 'SeedSize', 'CGC', 'CCx', 
          'CDC', 'Tbase', 'Tupp', 'Zmax', 'Kcb', 'WP', 'HI0', 'WPy', 'p_up2', 
          'dHI_pre', 'a_HI', 'b_HI']
Dry = ['th_fc', 'th_wp', 'Ksat', 'HIstart', 'YldForm', 'CGC', 'CCx', 
       'CDC', 'Tbase', 'Tupp', 'Zmax', 'Kcb', 'WP', 'HI0', 'exc',
       'p_up2', 'fshape_w2', 'p_up4', 'a_HI', 'b_HI']

Wet_b = [i for i,t in zip(bounds_list,names_list) if (t in Wet)]
Normal_b = [i for i,t in zip(bounds_list,names_list) if (t in Normal)]
Dry_b = [i for i,t in zip(bounds_list,names_list) if (t in Dry)]

Wet_i = [i for i,t in enumerate(names_list) if (t in Wet)]
Normal_i = [i for i,t in enumerate(names_list) if (t in Normal)]
Dry_i = [i for i,t in enumerate(names_list) if (t in Dry)]

loc_list = [Wet_i, Normal_i, Dry_i]

problem_Wet = {
    'num_vars': len(Wet),
    'names': Wet,
    'bounds': Wet_b
        }
problem_Normal = {
    'num_vars': len(Normal),
    'names': Normal,
    'bounds': Normal_b
        }
problem_Dry = {
    'num_vars': len(Dry),
    'names': Dry,
    'bounds': Dry_b
        }

# environment
eng = matlab.engine.start_matlab()
eng.addpath('AquaCropOS_v60a')
inputpath = './AquaCropOS_v60a/Input/rice_NN/'
output = './AquaCropOS_v60a/Output/test/'

# sobol
Si_s_all = []
typical_year_list = ['Wet', 'Normal', 'Dry']
problem_list = [problem_Wet,problem_Normal,problem_Dry]
trajectory = 200

for i,problem in enumerate(problem_list):
    typical_year = typical_year_list[i]
    para_loc = loc_list[i]
    X_s = saltelli.sample(problem, trajectory,calc_second_order=False)
    
    if typical_year == 'Wet':
        start_date = ['2034','7','15']  # wet year
    elif typical_year == 'Normal':    
        start_date = ['2039','7','15']  # normal year
    elif typical_year == 'Dry':   
        start_date = ['2073','7','15']  # dry year
    else:
        raise ValueError('typical year ERROR!')
        
    # run Aquacrop model
    out = []
    t0 = time.time()
    for t in range(len(X_s)):
        para = np.array(copy.deepcopy(para_default))
        para[para_loc] = X_s[t]
        para = list(para)
        # YieldFormation stoped when maturaty
        if (para[11] + para[14]) > para[13]:
            para[14] = para[13] - para[11]
            
        # FloweringStart can't later than Senescence
        if para[11] > para[12]:
            para[11] = para[12]
        
        # Flowering can't last longer than (Senescence + 300) GDD
        if (para[11] + para[15]) > (para[12] + 300):
            para[15] = para[12] + 300 - para[11]
        
        # fc should not great than sat
        if para[3] > para[1]:
            para[3] = para[1]
        if para[4] > para[2]:
            para[4] = para[2]
            
        out.append(eng.SA_py(inputpath ,output, start_date, matlab.double(para)))
        if t % 20 == 0:
            print ('%d / %d is finised, processing time %.2f s'%(t,len(X_s),time.time() - t0))
    
    # Numpylize the results & save results    
    Y_s_np = []
    out_list = ['Yield']
    for item in out_list:
        Y_s_np.append([np.array(y[item]._data) for y in out])
    np.save('trajectory_yield_sobol_%d_%s.npy'%(trajectory,typical_year),Y_s_np)

    Y_s = np.array([y[-1] for y in Y_s_np[0]])

    Si_s = sobol.analyze(problem, Y_s, print_to_console=True, calc_second_order=False)
    Si_s_all.append(Si_s)