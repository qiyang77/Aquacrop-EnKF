# -*- coding: utf-8 -*-
"""
Created on Thu Jul 22 10:31:01 2021

@author: Qi Yang

OSS Experiment for assimilating Canopy Cover (CC) and aboveground biomass, and phenology (represented by GDD)
Evaluate the model performance at a wrong guess of planting date
"""

import numpy as np
import matlab.engine
from KFs import EnsembleKalmanFilter as EnKF
from DAA_UncertainPara import uncertain_para
import matplotlib.pyplot as plt
import matplotlib
import os
matplotlib.rcParams['font.family'] = 'Times New Roman'
matplotlib.rcParams['figure.dpi'] = 300

class Aquacrop_env():
    def __init__(self, inputpath, start_date, ensemble_n, init_para, state_case = 1, initUpdate = False):
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
        self.ensemble_n = ensemble_n
        self.init_para = init_para
        if len(init_para) != ensemble_n:
            raise ValueError('ensemble samples number error!')
        self.init_state = []
        self.state_case = state_case
        self.updateNextStep = initUpdate

        if self.state_case == 5:
            self.stateList = ['CC', 'biomass', 'Para_CDC', 'Para_CGC','Para_CCx', 'Para_WP','Para_Zmax','Para_p_up2','Para_p_up4'
                              ,'GDDcum','Para_HIstart','Para_YldForm', 'Para_Senescence']
        if self.state_case == 51:
            self.stateList = ['CC', 'biomass', 'Para_CDC', 'Para_CGC','Para_CCx', 'Para_WP','Para_Zmax','Para_p_up2','Para_p_up4'
                              ,'GDDcum','Para_HIstart','Para_YldForm', 'Para_Senescence']
        elif self.state_case == 7:  # update the planting date and other revelated paras based on GDD
            self.stateList = ['CC', 'biomass', 'Para_CDC', 'Para_CGC','Para_CCx', 'Para_WP','Para_Zmax','Para_p_up2','Para_p_up4'
                              , 'GDDcum','Para_HIstart','Para_YldForm', 'Para_Senescence']
        elif self.state_case == 71:  # update the planting date and other revelated paras based on GDD
            self.stateList = ['CC', 'biomass', 'Para_CDC', 'Para_CGC','Para_CCx', 'Para_WP','Para_Zmax'
                              , 'GDDcum','Para_HIstart','Para_YldForm', 'Para_Senescence']
        elif self.state_case == 8:
            self.stateList = ['CC', 'biomass', 'Para_CDC', 'Para_CGC','Para_CCx','Para_WP','Para_Zmax','Para_p_up2','Para_p_up4',
                              'GDDcum','Para_Tbase','Para_HIstart','Para_YldForm', 'Para_Senescence']
        elif self.state_case == 9:
            self.stateList = ['CC', 'biomass','GDDcum']
        self.reset()
        
    def reset(self):
        
        print ('Initializing the ensemble models...')
        for n in range(self.ensemble_n):
            #  engine start and initialaze
            if self.init_para != None:
                self.eng.DA_pyaqua_init(inputpath, start_date, 
                                        matlab.double(self.init_para[n]), int(n + 1), nargout= 0) # inside matlab.double should be a list
            else:
                self.eng.DA_pyaqua_init(inputpath, start_date, 
                                        [], int(n + 1), nargout= 0)
        
    def steprun(self, state_in, dt, sample_n):
        out = self.eng.step_run_DA_OSS(matlab.double(list(state_in)), int(dt), int(sample_n + 1), int(self.state_case), self.updateNextStep)  # sample_n start from 1

        state_out = [out[t] for t in self.stateList]   
        return state_out, out
    
def hx(x):
    return np.array([x[0],x[1],x[9]])
    # return np.array([x[0],x[1],x[7]])

def plotState(xs_enkf, color = 'r', DA_state_loc = 0, P_enkf = None, label = ' '):
      
    y = np.asarray([x[DA_state_loc] for x in xs_enkf])
    plt.plot(range(len(y)),y,color = color, label = label)
    ps = [p[DA_state_loc,DA_state_loc]**.5 for p in P_enkf]
    ps = np.asarray(ps)
    plt.fill_between(range(len(y)), y + ps ,
                 y - ps,color = color,alpha=.25,linewidth=0.5,linestyle='--') 

def plotState_extent(All_state, state_key, color = 'g', color2 = 'darkgreen', label = ' '):
      
    y = []
    std = []
    Yall=[]
    for state in All_state:
        tmp = []
        for s in state:
            tmp.append(s[state_key])
        Yall.append(tmp)
        std.append(np.std(tmp,ddof = 1))  # ddof = 1 mean no-bias std, divide (n-1)
        y.append(np.mean(tmp))
    
    y = np.asarray(y)
    Yall = np.array(Yall)
    for i in range(Yall.shape[1]):
        plt.plot(range(len(Yall[:,i])),Yall[:,i],color = color,alpha=.10,linewidth=0.5)
    plt.plot(range(len(y)),y,color = color2, label = label)
    # plt.plot(range(len(y)),y,color = color, label = label)
    # plt.fill_between(range(len(y)), y + std ,
    #              y - std,color = color,alpha=.25,linewidth=0.5,linestyle='--') 

def DA_plot(state_key, y_trueth, ylabel, title, plotPara = False):
       
    # fig = plt.figure()
    fig, ax = plt.subplots(1, 1,figsize = (6,5))
    plotState_extent(All_state, state_key = state_key, color = 'b', color2 = 'darkblue',label = 'Open-loop')
    plotState_extent(All_state2, state_key = state_key, color = 'g', color2 = 'darkgreen', label = 'EnKF') 
    if plotPara:
       plt.axhline(y_trueth, color = 'k', linestyle = '--', label = 'Reference')
    else:
        plt.plot(range(len(y_trueth)),y_trueth, color = 'k', linestyle = '--', label = 'Reference')
    plt.xlim(0,180)

    plt.legend()
    plt.xlabel('Day after plant',fontsize=16)
    plt.ylabel(ylabel,fontsize=16)
    # plt.title(title)
    plt.text(0.45, 0.9, title, transform=ax.transAxes,fontsize=16)
    return fig
    
def DA_plot_state(DA_state_loc, y_trueth, ylabel, title):     
    fig = plt.figure()
    plotState(xs_enkf = xs_enkf, color = 'r', DA_state_loc = DA_state_loc, P_enkf = P_enkf, label = 'Open-loop')
    plotState(xs_enkf = xs_enkf2, color = 'g', DA_state_loc = DA_state_loc, P_enkf = P_enkf2, label = 'EnKF')
    # plotState_extent(All_state2, state_key = 'CC', color = 'b', DA_state_loc = 0, P_enkf = P_enkf2, label = 'EnKF-modelstate') 
    plt.plot(range(len(y_trueth)),y_trueth, color = 'k', label = 'Reference')
    plt.xlim(0,180)
    plt.legend()
    plt.xlabel('Day after plant')
    plt.ylabel(ylabel)
    plt.title(title)
    return fig

if __name__ == '__main__':
    
    ##  model settings
    inputpath = './AquaCropOS_v60a/Input/rice_NN/'
    aheadDay = 10
    start_date = ['2039','7','%d'%(15-aheadDay)]        
    ensemble_n = 300
    np.random.seed(0)
    OSS_path='OSSE_truth'
    outPath = 'OSSresult_3obs_shift'#'OSSresult_1obs'
    saveResult = True
    forceOpenloop = False
    
    ## Ensemble samples sampling
    UP = uncertain_para()
    u_para_default = UP.u_para_default
    CV = [0.5, 0.05, 0.05, 0.08, 0.1,
          0.1, 0.1, 0.05, 0.05, 0.1,
          0.05, 0.15, 0.1, 0.1]
    std2_0 = list((np.asarray(u_para_default) * np.asarray(CV))**2)
    P_u_para = np.diag(std2_0)
    init_paras = list(np.random.multivariate_normal(mean=u_para_default, cov=P_u_para, size=ensemble_n))
    for i,init_para in enumerate(init_paras):
        extent_para = UP.replace_uncertain(init_para)  # padding the uncertain parameters to full size
        valid_para = UP.validation_check(extent_para)  # correct the init parameters
        init_paras[i] = valid_para
    
    ## batch Run EnKF
    # state_case_list = [1,2,3,4,5,6]
    state_case_list = [7,8]
    z_origin = list(np.zeros(aheadDay))+list(np.loadtxt('%s/sim_z.in'%OSS_path))
    z2_origin = list(np.zeros(aheadDay))+list(np.loadtxt('%s/sim_bio.in'%OSS_path))
    z3_origin = list(np.zeros(aheadDay))+list(np.loadtxt('%s/sim_GDD.in'%OSS_path))
    z_para = np.loadtxt('%s/sim_para.in'%OSS_path)
    for case_n, state_case in enumerate(state_case_list):
        print ('Runing case %d ...'%state_case)
        ## initialized the ensembled Aquacrop models
        Aquacrop = Aquacrop_env(inputpath, start_date, ensemble_n, init_para = init_paras, state_case = state_case, initUpdate = False)
        
        ## EnKF settings
        x_paraLoc = None   # If the first step needs to update and discrete the states, should give the paralocation and set initUpdate = True
         
        R = np.diag([0.03**2, 50.0**2, 20**2])  # measurement cov matrix
        P0 = np.diag([0.])
       
        if case_n == 0: 
            if (not os.path.exists('openLoopResult.npy')) | forceOpenloop:
                # ENKF - open loop
                DAA_enkf = EnKF(x=np.zeros(len(Aquacrop.stateList)), P=P0, dim_z=3, N=ensemble_n, hx = hx, fx = Aquacrop.steprun, x_paraLoc = x_paraLoc)
                DAA_enkf.R = R
                dt = 1
                xs_enkf = []
                sigmas_enkf = []
                P_enkf = []
                K_enkf = []
                All_state = []
                count = 0
                while not DAA_enkf.allModelDone:
                    # predict
                    DAA_enkf.predict(dt = dt)  
                    xs_enkf.append(DAA_enkf.x.copy())
                    P_enkf.append(DAA_enkf.P.copy())
                    K_enkf.append(DAA_enkf.K.copy())
                    sigmas_enkf.append(DAA_enkf.sigmas.copy())
                    All_state.append(DAA_enkf.allState.copy())
                    count += 1
                    
                    if count%10 == 0:
                        print ('Simulating %d days...'%count)
                Aquacrop.reset()
                
                np.save('openLoopResult.npy',[xs_enkf,P_enkf,K_enkf,sigmas_enkf,All_state])
            else:
                xs_enkf,P_enkf,K_enkf,sigmas_enkf,All_state = np.load('openLoopResult.npy',allow_pickle=True)
           
        # ENKF - assimilation
        DAA_enkf = EnKF(x=np.zeros(len(Aquacrop.stateList)), P=P0, dim_z=3, N=ensemble_n, hx = hx, fx = Aquacrop.steprun, x_paraLoc = x_paraLoc)
        DAA_enkf.R = R.copy()
        
        dt = 1
        xs_enkf2 = []
        sigmas_enkf2 = []
        P_enkf2 = []
        K_enkf2 = []
        All_state2 = []        
        z_DAP = list(np.arange(1,len(z_origin),5))
        z = [t for i,t in enumerate(z_origin) if (i+1) in z_DAP]
        z2 = [t for i,t in enumerate(z2_origin) if (i+1) in z_DAP]
        z3 = [t for i,t in enumerate(z3_origin) if (i+1) in z_DAP]
        DAP = 1
        ass_n = 0
        while not DAA_enkf.allModelDone:
            
            # predict
            DAA_enkf.predict(dt = dt)  
            Aquacrop.updateNextStep = False
            
            # update
            if DAP in z_DAP:
                DAA_enkf.update(np.asarray([z[ass_n],z2[ass_n],z3[ass_n]]))
                Aquacrop.updateNextStep = True
                ass_n += 1
            if DAP%10 == 0:
                print ('Simulating %d days...'%DAP)
            
            # record
            xs_enkf2.append(DAA_enkf.x.copy())
            P_enkf2.append(DAA_enkf.P.copy())
            K_enkf2.append(DAA_enkf.K.copy())
            sigmas_enkf2.append(DAA_enkf.sigmas.copy())
            All_state2.append(DAA_enkf.allState.copy())
            DAP += 1
        print ('Simulation of case %d is finished...'%state_case)
        if saveResult:
            if not os.path.exists(outPath):
                        os.mkdir(outPath)
            np.save('%s/case%d.npy'%(outPath,state_case),[All_state,All_state2])
        # plot CC
        # fig = DA_plot_state(DA_state_loc = 9, y_trueth = z3_origin, ylabel = 'GDD', title = 'Case %d'%state_case)
        fig = DA_plot(state_key = 'CC', y_trueth = z_origin, ylabel = 'Canoy cover %', title = 'Case %d'%state_case)
        if saveResult:
            fig.savefig(outPath + '/CC_case%d.jpg'%state_case, bbox_inches='tight')
        
        # plot yield
        y_trueth = list(np.zeros(aheadDay))+list(np.loadtxt('%s/sim_yield.in'%OSS_path))
        fig = DA_plot(state_key = 'yield',y_trueth = y_trueth, ylabel = 'Yield t/ha', title = 'Case %d'%state_case)
        plt.ylim(-0.2,8)
        if saveResult:
            fig.savefig(outPath + '/Yield_case%d.jpg'%state_case, bbox_inches='tight')
        
        # plot Biomass   
        y_trueth = list(np.zeros(aheadDay))+list(np.loadtxt('%s/sim_bio.in'%OSS_path))
        fig = DA_plot(state_key = 'biomass',y_trueth = y_trueth, ylabel = 'Biomass g/m2', title = 'Case %d'%state_case)
        plt.ylim(-50,2000)
        if saveResult:
            fig.savefig(outPath + '/Bio_case%d.jpg'%state_case, bbox_inches='tight')

        # plot Planting date
        fig = DA_plot(state_key = 'PlantingDate',y_trueth = 744926, ylabel = 'Planting date', plotPara = True, title = 'Case %d'%state_case) 
        # plt.ylim(7,11)
        if saveResult:
            fig.savefig(outPath + '/Tbase_case%d.jpg'%state_case, bbox_inches='tight')        
        
        if state_case in [6,8]:
            # plot Tbase
            y_trueth = z_para[21]
            fig = DA_plot(state_key = 'Para_Tbase',y_trueth = y_trueth, ylabel = 'Tbase C', plotPara = True, title = 'Case %d'%state_case) 
            # plt.ylim(7,11)
            if saveResult:
                fig.savefig(outPath + '/Tbase_case%d.jpg'%state_case, bbox_inches='tight')
            
        if state_case >= 5:
            # plot phenology parameters
            y_trueth = z_para[11]
            fig = DA_plot(state_key = 'Para_HIstart',y_trueth = y_trueth, ylabel = 'HIstart', plotPara = True, title = 'Case %d'%state_case) 
            plt.ylim(1000,1300)
            if saveResult:
                fig.savefig(outPath + '/HIstart_case%d.jpg'%state_case, bbox_inches='tight')
            
            y_trueth = z_para[14]
            fig = DA_plot(state_key = 'Para_YldForm',y_trueth = y_trueth, ylabel = 'YldForm', plotPara = True, title = 'Case %d'%state_case) 
            plt.ylim(600,850)
            if saveResult:
                fig.savefig(outPath + '/YldForm_case%d.jpg'%state_case, bbox_inches='tight')
            
            y_trueth = z_para[12]
            fig = DA_plot(state_key = 'Para_Senescence',y_trueth = y_trueth, ylabel = 'Senescence', plotPara = True, title = 'Case %d'%state_case) 
            plt.ylim(1000,1400)
            if saveResult:
                fig.savefig(outPath + '/Sen_case%d.jpg'%state_case, bbox_inches='tight')
            
        if state_case >= 3:
            # plot CDC
            y_trueth = z_para[20]
            fig = DA_plot(state_key = 'Para_CDC',y_trueth = y_trueth, ylabel = 'CDC', plotPara = True, title = 'Case %d'%state_case)
            plt.ylim(0.003,0.006)
            if saveResult:
                fig.savefig(outPath + '/CDC_case%d.jpg'%state_case, bbox_inches='tight')
            
            # plot CGC
            y_trueth = z_para[18]
            fig = DA_plot(state_key = 'Para_CGC',y_trueth = y_trueth, ylabel = 'CGC', plotPara = True, title = 'Case %d'%state_case)
            plt.ylim(0.003,0.009)
            if saveResult:
                fig.savefig(outPath + '/CGC_case%d.jpg'%state_case, bbox_inches='tight')
                
            # plot CCx
            y_trueth = z_para[19]
            fig = DA_plot(state_key = 'Para_CCx',y_trueth = y_trueth, ylabel = 'CCx', plotPara = True, title = 'Case %d'%state_case)
            plt.ylim(0.6,1)
            if saveResult:
                fig.savefig(outPath + '/CCx_case%d.jpg'%state_case, bbox_inches='tight')
                
        if state_case >= 4:
            # plot WP
            y_trueth = z_para[32]
            fig = DA_plot(state_key = 'Para_WP',y_trueth = y_trueth, ylabel = 'WP', plotPara = True, title = 'Case %d'%state_case)
            plt.ylim(14,21)
            if saveResult:
                fig.savefig(outPath + '/WP_case%d.jpg'%state_case, bbox_inches='tight')
            
            # plot Zmax
            y_trueth = z_para[24]
            fig = DA_plot(state_key = 'Para_Zmax',y_trueth = y_trueth, ylabel = 'Zmax', plotPara = True, title = 'Case %d'%state_case)
            plt.ylim(0.3, 0.6)
            if saveResult:
                fig.savefig(outPath + '/Zmax_case%d.jpg'%state_case, bbox_inches='tight')                

            # plot p_up2
            y_trueth = z_para[39]
            fig = DA_plot(state_key = 'Para_p_up2',y_trueth = y_trueth, ylabel = 'p_up2', plotPara = True, title = 'Case %d'%state_case)
            plt.ylim(0.3, 0.6)
            if saveResult:
                fig.savefig(outPath + '/p_up2_case%d.jpg'%state_case, bbox_inches='tight') 

            # plot p_up4
            y_trueth = z_para[43]
            fig = DA_plot(state_key = 'Para_p_up4',y_trueth = y_trueth, ylabel = 'p_up4', plotPara = True, title = 'Case %d'%state_case)
            plt.ylim(0.4, 0.9)
            if saveResult:
                fig.savefig(outPath + '/p_up4_case%d.jpg'%state_case, bbox_inches='tight')                 
        
        if state_case >= 5:
            # plot GDD
            y_trueth = list(np.zeros(aheadDay))+list(np.loadtxt('%s/sim_GDD.in'%OSS_path))
            fig = DA_plot(state_key = 'GDDcum', y_trueth = y_trueth, ylabel = 'GDD g/m2', title = 'Case %d'%state_case)
            plt.ylim(-50,2200)
            if saveResult:
                fig.savefig(outPath + '/GDD_case%d.jpg'%state_case, bbox_inches='tight')
            
