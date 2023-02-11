# -*- coding: utf-8 -*-
"""
Created on Sun Aug 23 17:33:22 2020

@author: WIN
"""

from SALib.sample import morris
from SALib.analyze import morris as morris_a
import numpy as np
import matlab.engine
import time

problem = {
    'num_vars': 53,
    'names': ['CN', 'th_s','th_s2','th_fc','th_fc2', 
              'th_wp','th_wp2','Ksat','Ksat2','REW',
              'Emerge','HIstart','Senescence','Maturity','YldForm',
              'Flowering','SeedSize','PlantPop','CGC','CCx',
              'CDC','Tbase','Tupp','MaxRooting','Zmax',
              'Zmin','fshape_r','SxTopQ','SxBotQ','Kcb',
              'fage','fwcc','WP','HI0','exc',
              'WPy','p_up1','p_lo1','fshape_w1','p_up2',
              'fshape_w2','p_up3','fshape_w3','p_up4','dHI_pre',
              'a_HI','b_HI','dHI0','Tmin_up','Tmax_up',
              'Tmin_lo','Tmax_lo','GDD_up'],
    'bounds': [[68, 92],
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
}

# morris
num_levels = 8
trajectory = 100
typical_year_list = ['Wet', 'Normal', 'Dry']
X_m = morris.sample(problem, trajectory, num_levels=num_levels)

# environment
eng = matlab.engine.start_matlab()
eng.addpath('AquaCropOS_v60a')
inputpath = './AquaCropOS_v60a/Input/rice_NN/'  # stochastic weather of NanNing station
output = './AquaCropOS_v60a/Output/test/'   # output of Aquacrop

Si_m_all = []

for typical_year in typical_year_list:
    
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
    for t in range(len(X_m)):
        para = list(X_m[t])
        
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
        if t % 10 == 0:
            print ('%d / %d is finised, processing time %.2f s'%(t,len(X_m),time.time() - t0))
        
    # Numpylize the results & save results    
    Y_m_np = []
    out_list = ['CC','Dr','Yield','pheno','time_axi']
    for item in out_list:
        Y_m_np.append([np.array(y[item]._data) for y in out])
    np.save('trajectory_%d_%s.npy'%(trajectory,typical_year),Y_m_np)
    tmp = []
    for i in range(3):
        if i == 1:  # yield
            Y_m = np.array([y[-1] for y in Y_m_np[i+1]])
        else:
            Y_m = np.array([y[50] for y in Y_m_np[i+1]])
        Si_m = morris_a.analyze(problem, X_m, Y_m,
                            print_to_console=True, num_levels=num_levels)
        tmp.append(Si_m)
    Si_m_all.append(tmp)
    
# with open ('test.in','w') as f:
#     for t in para:
#         f.write(str(t) + '\n')
# a = np.load('trajectory_10_Wet.npy',allow_pickle=True)