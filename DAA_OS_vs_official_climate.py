# -*- coding: utf-8 -*-
"""
Created on Wed Dec 28 12:53:04 2022

@author: Qi Yang

Compare the agreement of Aquacrop-OS and FAO-Aquacrop under various climate scenarios
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

def runFAOaquacrop():
   
    sub_path = 'WG/'
    start_year = 2000
  
    outfile = 'SIM_NanNing_CHN_2000_100.cd'
    ## To calculate ETo and write the input file of aquacrop
    # lat=29.73
    lat=22.63
    elev=122.0
    method='asce'
    cli_file = sub_path + 'SIM_DATA\\aquacropdata_' + outfile
    station = 'NanNing'
    out_path = 'PROJECT_FILE_NN'
    para_path = 'RICE_PARA'
    
    # management
    irrgation = False
    groudwater = False
    initial = False
    offseason = False
    management = [irrgation, groudwater, initial, offseason]
    write_cli = False
    
    # write CLI and PROJECT file
    if write_cli:
        cli_start_day = [start_year, 1, 1]
        cli_data = np.loadtxt(cli_file)
        eto, tmax_list, tmin_list, rain_list = CEWI.cal_et(lat = lat, elev = elev, method = method, 
                                                      cli_file = cli_data,start_day = cli_start_day)
        CEWI.write_cli(out_path = out_path, station = station, eto = eto, 
                  tmax_list = tmax_list, tmin_list = tmin_list, rain_list = rain_list,start_day = cli_start_day)
    growth_period = []
    yield_list = []
    
    blackList = [40]
    n = 0
    for year in range(2000,2100):
        for j in [3,4,5,6]:
            if n in blackList:
                yield_list.append(np.nan)
                n+=1
                continue
            else:
                seed_day = [year, j, 1]
                sim_start_day = seed_day
                tmp = datetime.datetime(sim_start_day[0],sim_start_day[1],\
                                        sim_start_day[2]) + datetime.timedelta(days=215)
            
                sim_end_day = [tmp.year, tmp.month, tmp.day]
        
                CEWI.write_project(out_path = out_path, para_path = para_path, station = station, seed_day = seed_day, 
                              sim_start_day = sim_start_day, sim_end_day = sim_end_day, management = management)
                
                ## run the simulation       
                main = "ACsaV60.exe"
                r_v = os.system(main)
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
                yield_list.append(max(finalyield))
                print('Simulation of %d year %d month finished,%s'%(year,j,n))
                n+=1
    return yield_list

def removeNaN(obs,pre,coef=1):
    x = np.array(obs)
    y = np.array(pre)*coef
    
    Loc = (1 - (np.isnan(x) | np.isnan(y)))
    x_ = x[Loc==1]
    y_ = y[Loc==1]
    return x_,y_

def plotEst(x_,y_,lim = None, xname='',yname = ''):
    x,y = removeNaN(x_,y_)
    fig, ax = plt.subplots(1, 1,figsize = (6,5))
    para = np.polyfit(x, y, 1)

    plt.scatter(x,y,c='k',alpha=.25,edgecolors='k')
    R2 = np.corrcoef(x,y)[0, 1] ** 2
    bias = np.mean(y)-np.mean(x)
    # plt.plot(x, y_fit, 'k') 
    # plt.text(0.05, 0.89, r'$y$ = %.2f $x$ + %.2f'%(para[0],para[1]), transform=ax.transAxes,fontsize=16, fontweight='bold')
    plt.text(0.05, 0.89, r'$R^2 $ = %.3f'%R2, transform=ax.transAxes,fontsize=16)
    plt.text(0.05, 0.80, r'$Bias $ = %.3f'%bias, transform=ax.transAxes,fontsize=16)
    plt.text(0.05, 0.73, r'$n $ = %d'%len(x_), transform=ax.transAxes,fontsize=16)
    
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
    perturb = False
    inputpath = './AquaCropOS_v60a/Input/rice_NN/'
    
    UP = uncertain_para()
    u_para_default = UP.u_para_default
    u_para_name = UP.uncertain_para
    para_default = UP.para_default
    
    if os.path.exists('os_FAO_climate.npy'):
        yieldList,yieldList_FAO =  np.load('os_FAO_climate.npy',allow_pickle=True)
    else:
        yieldList = []
        DAA_DM = Aquacrop_env_DM(inputpath)
        for year in range(2000,2100):
            for start_month in [3,4,5,6]:         
                start_date = [str(year),str(start_month),'1']
    
                ## Ensemble samples sampling
                if perturb:
                    np.random.seed(1)
                    # CV = [0.5]  + [0.1]*13 # Coefficient of Variation
                    CV = [0.5, 0.05, 0.05, 0.08, 0.1,
                          0.1, 0.1, 0.05, 0.05, 0.1,
                          0.05, 0.15, 0.1, 0.1]
                    std2_0 = list((np.asarray(u_para_default) * np.asarray(CV))**2)
                    stdList = list(np.asarray(u_para_default) * np.asarray(CV))
                    P_u_para = np.diag(std2_0)
                    init_paras = list(np.random.multivariate_normal(mean=u_para_default, cov=P_u_para, size=1))
                    
                    _ = [printUncertainPara(name, init, default) for name, init, default in zip(u_para_name, init_paras[0], u_para_default)]  
                    
                
                    ## 
                    extent_para = UP.replace_uncertain(init_paras[0])  # padding the uncertain parameters to full size
                    valid_para = UP.validation_check(extent_para)
                    valid_para_UP = [valid_para[t] for t in UP.uncertain_loc]
                else:
                    valid_para = para_default
                # print(init_paras[0])
                # print(valid_para_UP)
                DAA_DM.start_date = start_date
                DAA_DM.init_para = valid_para
                DAA_DM.reset()
                out = DAA_DM.run()
             
                finalYield = out['Yield']._data[-1]
                print('The yield is %.2f t/ha'%finalYield)
                yieldList.append(finalYield)
        
        # run FAO
        yieldList_FAO = runFAOaquacrop()
        
        np.save('os_FAO_climate.npy',[yieldList,yieldList_FAO])
    plotEst(x_=yieldList_FAO,y_=yieldList,lim = [0,9], 
            xname='Yield estimation of Aquacrop-FAO (ton/ha)',
            yname = 'Yield estimation of AquacropOS (ton/ha)')