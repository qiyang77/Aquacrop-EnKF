# -*- coding: utf-8 -*-
"""
Created on Sat Aug 29 17:11:36 2020

@author: Qi Yang

This class initialized the uncertain parameters of Aquacrop
"""
import numpy as np

class uncertain_para():
    def __init__(self):
        self.names_list = ['CN', 'th_s','th_s2','th_fc','th_fc2', 
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

        self.uncertain_para = ['Ksat2', 'th_fc', 'th_wp','CCx',   # 14 paras, 
                       'Zmax', 'p_up2', 'p_up4', 'Senescence', 
                       'WP', 'YldForm', 'HIstart', 'Tbase', 
                       'CDC','CGC'] 
        uncertain_loc = []
        for para in self.uncertain_para:
            for i,t in enumerate(self.names_list):
                tmp = []
                tmp.append(para)
                if t in tmp:
                    uncertain_loc.append(i)
        self.uncertain_loc = uncertain_loc
        self.para_default = [77, 0.54, 0.55, 0.5, 0.54,
                             0.32, 0.39, 15, 2, 10,
                             50, 1150, 1300, 1900, 680,
                             350, 6, 1000000, 0.007004, 0.95,
                             0.005003, 8, 30, 370, 0.5,
                             0.3, 2.5, 0.048, 0.012, 1.1,
                             0.15, 50, 19, 0.43, 100,
                             100, 0, 0.4, 3, 0.5,
                             3, 0.55, 3, 0.75, 0, 
                             10, 7, 15, 8, 35,
                             5, 45, 10,]
        self.para_range = [[68, 92], [0.52,0.56], [0.53,0.57], [0.48,0.52],
               [0.52,0.56], [0.30,0.34], [0.37,0.41], [10,20],
               [1,10], [5,10], [35,80], [1000,1200],
               [1080,1430], [1750,2000], [330,800], [280,420],
               [4.0,8.0], [900000,1200000], [0.005,0.009], [0.75,1.00],
               [0.003,0.007], [5,11], [30,45], [300,450],
               [0.40,0.60], [0.2,0.35], [1,5], [0.045,0.050],
               [0.010,0.014], [1.05,1.15], [0.1,0.5], [30,70],
               [15,20], [0.40,0.46], [20,300], [75,125],
               [0.10,0.30], [0.55,0.80], [1,5], [0.50,0.80],
               [1,5], [0.60,0.80], [1,5], [0.70,0.95],
               [0,10], [0.5,10.0], [1,20], [15,35],
               [8,12], [35,40], [3,7], [42,48],
               [6,15]]
        self.uncertain_para_range = [self.para_range[t] for t in self.uncertain_loc]
        self.para_range_mean = [np.mean(para) for para in self.para_range]
        self.para_outRangeIndex = [i for i,para in enumerate(self.para_default) if ((para < self.para_range[i][0])|(para > self.para_range[i][1]))]
        self.u_para_default = [self.para_default[loc] for loc in self.uncertain_loc]
        self.u_para_rangeMean = [self.para_range_mean[loc] for loc in self.uncertain_loc]
        
    def replace_uncertain(self, u_para):
        tuned_para = self.para_default.copy()
        for u_p, loc in zip(u_para, self.uncertain_loc):
            tuned_para[loc] = u_p
            
        return tuned_para
    
    def validation_check(self, para):
        
        # YieldFormation stoped when maturaty
        if (para[11] + para[14]) > para[13]:
            para[14] = para[13] - para[11]
            
        # FloweringStart can't later than Senescence
        if para[11] > para[12]:
            para[11] = para[12]
        
        # Flowering can't last longer than (Senescence + 300) GDD
        if (para[11] + para[15]) > (para[12] + 300):
            para[15] = para[12] + 300 - para[11]
        
        # Ksat should great than 0
        if para[7] < 0:
            para[7] = 0.1
        if para[8] < 0:
            para[8] = 0.1
            
        # fc should not great than sat
        if para[3] > para[1]:
            para[3] = para[1]
        if para[4] > para[2]:
            para[4] = para[2]
        
        # CCx smaller than 1.0
        if para[19] > 0.99:
            para[19] = 0.99
            
        return para