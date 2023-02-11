# -*- coding: utf-8 -*-
"""
Created on Wed Dec 28 16:31:45 2022

@author: Qi Yang

Compare the agreement of Aquacrop-OS and FAO-Aquacrop under different parameter combinations
"""

import numpy as np
import matlab.engine
from DAA_UncertainPara import uncertain_para
import Cal_ETo_Write_Input as CEWI
import datetime
import os
import matplotlib.pyplot as plt
import matplotlib
import matplotlib.ticker as ticker
matplotlib.rcParams['font.family'] = 'Times New Roman'
matplotlib.rcParams['figure.dpi'] = 300
import subprocess

class Aquacrop_env_DM():
    def __init__(self, inputpath, start_date=['2000','1','1'], init_para=None):
        """

        Parameters
        ----------
        inputpath : str
        output : str
        start_date : list
        ensemble_n : int
        init_para : list >> the list of n (sample number) * N (parameter number) parameters

        """
        self.eng = matlab.engine.start_matlab()
        self.eng.addpath('AquaCropOS_v60a')
        self.inputpath = inputpath
        self.start_date = start_date
        self.init_para = init_para
        self.init_state = []
        self.reset()
        
    def reset(self):
        
        print ('Initializing the models...')

        if self.init_para != None:
            self.eng.DM_pyaqua_init(inputpath, self.start_date, 
                                    matlab.double(self.init_para), nargout= 0) # inside matlab.double should be a list
        else:
            self.eng.DM_pyaqua_init(inputpath, self.start_date, 
                                    [], nargout= 0)
        
    def run(self, irrList = [0]):
        out = self.eng.DM_oneRun(matlab.double(list(irrList)),False) 
        return out

def print2std(name, mean, std, validRange):
    print('%-10s with std %f: %.5f, range [%.5f, %.5f], sampling [%.5f, %.5f], '%(name, std, mean, validRange[0], validRange[1], mean-2*std, mean+2*std)) 

def printUncertainPara(u_para_name, init_paras, u_para_default):
    print('UncertainPara %-10s: %.5f(%.5f)'%(\
                 u_para_name, init_paras, u_para_default))

def runFAOaquacrop(valid_para_UP,tt):
    # pathes
    station = 'NanNing'
    out_path = 'PROJECT_FILE_NN'
    para_path = 'RICE_PARA'
    
    # modify the parameter
    with open('RICE_PARA/PaddyRiceGDD_bak.CRO','r') as f:
        paras_crop = f.readlines()
    with open('RICE_PARA/PADDY_bak.SOL','r') as f:
        paras_soil = f.readlines()
    paras = [paras_crop,paras_soil]
    
    uncertain_para = ['Ksat2', 'th_fc', 'th_wp','CCx',   # 14 paras, 
                   'Zmax', 'p_up2', 'p_up4', 'Senescence', 
                   'WP', 'YldForm', 'HIstart', 'Tbase', 
                   'CDC','CGC'] 
    lineNum = [[1,9,4],[1,8,2],[1,8,3],[0,49,0],
               [0,37,0],[0,15,0],[0,18,0],[0,70,0],
               [0,60,0],[0,76,0],[0,72,0],[0,7,0],
               [0,75,0],[0,74,0]]
    n=0
    for loc,p in zip(lineNum,valid_para_UP):
        tmp = paras[loc[0]][loc[1]].split()
        if loc[0] ==1:
            tmp[loc[2]] = '%.5f'%(p*100)
        elif n in [7,9,10]:
            tmp[loc[2]] = '%d'%p
        else:
            tmp[loc[2]] = '%.5f'%p
        tmpStr = ' '.join(tmp)+'\n'
        paras[loc[0]][loc[1]] = tmpStr
        # print(p)
        # if n==tt:
        #     break
        n+=1
    # re-generate para files
    with open('RICE_PARA/PaddyRiceGDD.CRO','w') as f:
       f.writelines(paras[0])
    with open('RICE_PARA/PADDY.SOL','w') as f:
       f.writelines(paras[1])
        
    # management
    irrgation = False
    groudwater = False
    initial = False
    offseason = False
    management = [irrgation, groudwater, initial, offseason]

    growth_period = []
    yield_list = []
    
    year =2050
    j = 5

    seed_day = [year, j, 1]
    sim_start_day = seed_day
    tmp = datetime.datetime(sim_start_day[0],sim_start_day[1],\
                            sim_start_day[2]) + datetime.timedelta(days=215)

    sim_end_day = [tmp.year, tmp.month, tmp.day]

    CEWI.write_project(out_path = out_path, para_path = para_path, station = station, seed_day = seed_day, 
                  sim_start_day = sim_start_day, sim_end_day = sim_end_day, management = management)
    
    ## run the simulation       
    main = "ACsaV60.exe"
    # r_v = os.system(main)
    obj = subprocess.Popen(main)
    try:
        obj.wait(timeout=5)
    except:
        print('case failed')
        obj.kill()
        return np.nan
    # time.sleep(0.2)
    
    ## output
    with open('OUTP\\' + station + 'PROday.OUT', 'r') as f:
        lines = f.readlines()
    data_list = lines[4:]
    with open('OUTP\\' + station + 'PROday.tmp', 'w') as f:
        for line in data_list:
            f.writelines(line)
    
    outdata = np.loadtxt('OUTP\\' + station + 'PROday.tmp')
    DAP = outdata[:,3]
    finalyield = outdata[:,41]
    growth_period.append(max(DAP))
    finalYield = max(finalyield)
    print('The yield of FAO is %.2f t/ha'%finalYield)
    return finalYield

def removeNaN(obs,pre,coef=1):
    x = np.array(obs)
    y = np.array(pre)*coef
    
    Loc = (1 - (np.isnan(x) | np.isnan(y)))
    x_ = x[Loc==1]
    y_ = y[Loc==1]
    return x_,y_

def plotEst(x_,y_,lim = None, xname='',yname = ''):
    x,y = removeNaN(x_,y_)
    x = x[:200]
    y = y[:200]
    fig, ax = plt.subplots(1, 1,figsize = (6,5))
    para = np.polyfit(x, y, 1)

    plt.scatter(x,y,c='k',alpha=.25,edgecolors='k')
    R2 = np.corrcoef(x,y)[0, 1] ** 2
    bias = np.mean(y)-np.mean(x)
    # plt.plot(x, y_fit, 'k') 
    # plt.text(0.05, 0.89, r'$y$ = %.2f $x$ + %.2f'%(para[0],para[1]), transform=ax.transAxes,fontsize=16, fontweight='bold')
    plt.text(0.05, 0.89, r'$R^2 $ = %.3f'%R2, transform=ax.transAxes,fontsize=16)
    plt.text(0.05, 0.80, r'$Bias $ = %.3f'%bias, transform=ax.transAxes,fontsize=16)
    plt.text(0.05, 0.73, r'$n $ = %d'%len(x), transform=ax.transAxes,fontsize=16)
    
    if not lim == None:
        plt.plot(np.arange(0,np.ceil(lim[1])+1), np.arange(0,np.ceil(lim[1])+1), 'k', label='1:1 line')
        plt.xlim(lim)
        plt.ylim(lim)
    plt.xlabel(xname, fontsize=16)
    plt.ylabel(yname,fontsize=16)
    ax.xaxis.set_major_locator(ticker.MultipleLocator(2))
    ax.yaxis.set_major_locator(ticker.MultipleLocator(2))
    
if __name__ == '__main__':
    
    ##  model settings
    perturb = True
    inputpath = './AquaCropOS_v60a/Input/rice_NN/'
    
    UP = uncertain_para()
    u_para_default = UP.u_para_default
    u_para_name = UP.uncertain_para
    para_default = UP.para_default
    
    if os.path.exists('os_FAO_para.npy'):
        yieldList_OS,yieldList_FAO =  np.load('os_FAO_climate.npy',allow_pickle=True)
    else:

        DAA_DM = Aquacrop_env_DM(inputpath)
        year =2050
        start_month = 5        
        start_date = [str(year),str(start_month),'1']
    
        ## Ensemble samples sampling
        yieldList_OS = []
        yieldList_FAO = []
        np.random.seed(1)
        for _ in range(400):
            
            # CV = [0.5]  + [0.1]*13 # Coefficient of Variation
            CV = [0.5, 0.05, 0.05, 0.08, 0.1,
                  0.1, 0.1, 0.05, 0.05, 0.1,
                  0.05, 0.15, 0.1, 0.1]
            std2_0 = list((np.asarray(u_para_default) * np.asarray(CV))**2)
            stdList = list(np.asarray(u_para_default) * np.asarray(CV))
            P_u_para = np.diag(std2_0)
            init_paras = list(np.random.multivariate_normal(mean=u_para_default, cov=P_u_para, size=1))
            
            ## 
            extent_para = UP.replace_uncertain(init_paras[0])  # padding the uncertain parameters to full size
            valid_para = UP.validation_check(extent_para)
            valid_para_UP = [valid_para[t] for t in UP.uncertain_loc]
            
            _ = [printUncertainPara(name, init, default) for name, init, default in zip(u_para_name, valid_para_UP, u_para_default)]  
            
     
    
            DAA_DM.start_date = start_date
            DAA_DM.init_para = valid_para
            DAA_DM.reset()
            out = DAA_DM.run()
         
            finalYield = out['Yield']._data[-1]
            print('The yield of OS is %.2f t/ha'%finalYield)
            yieldList_OS.append(finalYield)
            # run FAO
            yieldList_FAO.append(runFAOaquacrop(valid_para_UP,tt=14))
            
            np.save('os_FAO_para.npy',[yieldList_OS,yieldList_FAO])
    plotEst(x_=yieldList_FAO,y_=yieldList_OS,lim = [2,11], 
            xname='Yield estimation of Aquacrop-FAO (ton/ha)',
            yname = 'Yield estimation of AquacropOS (ton/ha)')