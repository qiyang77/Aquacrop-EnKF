# -*- coding: utf-8 -*-
"""
Created on Wed Aug  4 15:07:41 2021

@author: Qi Yang

OSS Experiment for assimilating Canopy Cover (CC) and aboveground biomass, and phenology (represented by GDD)
Evaluate the model performance at a wrong guess of planting date
Restart-EnKF strategy
"""

import numpy as np
import matlab.engine
from KFs import EnsembleKalmanFilter as EnKF
from DAA_UncertainPara import uncertain_para
import matplotlib.pyplot as plt
import matplotlib
import os
import datetime
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

        if self.state_case == 10:
            self.stateList = ['CC', 'biomass', 'Para_CDC', 'Para_CGC','Para_CCx', 'Para_WP','Para_Zmax','Para_p_up2','Para_p_up4'
                              , 'GDDcum','Para_HIstart','Para_YldForm', 'Para_Senescence','HIref']
        elif self.state_case == 11:    
            self.stateList = ['CC', 'biomass', 'Para_CDC', 'Para_CGC','Para_CCx', 'Para_WP','Para_Zmax','Para_p_up2','Para_p_up4'
                              , 'GDDcum','Para_HIstart','Para_YldForm', 'Para_Senescence']
        self.restart = False
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
        out = self.eng.step_run_DA_GDD(matlab.double(list(state_in)), int(dt), int(sample_n + 1), int(self.state_case), self.updateNextStep,self.restart)  # sample_n start from 1

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

def plotState_extent(All_state, state_key, color = 'g', color2 = 'darkgreen', label = ' ',restart=False):
      
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
        if restart:
            catDate = z_DAP_GDD_restart[-1]
            plt.plot(range(catDate-len(Yall[:,i]),catDate),Yall[:,i],color = color,alpha=.10,linewidth=0.5)
        else:
            plt.plot(range(len(Yall[:,i])),Yall[:,i],color = color,alpha=.10,linewidth=0.5)
            
    if restart:
        plt.plot(range(catDate-len(y),catDate),y,color = color2, label = label)
    else:
        plt.plot(range(len(y)),y,color = color2, label = label)
    # plt.plot(range(len(y)),y,color = color, label = label)
    # plt.fill_between(range(len(y)), y + std ,
    #              y - std,color = color,alpha=.25,linewidth=0.5,linestyle='--') 

def DA_plot(state_key, y_trueth, ylabel, title, plotPara = False):
       
    # fig = plt.figure()
    fig, ax = plt.subplots(1, 1,figsize = (6,5))
    plotState_extent(All_state, state_key = state_key, color = 'b', color2 = 'darkblue',label = 'Open-loop')
    plotState_extent(All_state2, state_key = state_key, color = 'g', color2 = 'darkgreen', label = 'EnKF')
    plotState_extent(All_state_restart, state_key = state_key, color = 'tomato', color2 = 'r', label = 'EnKF',restart=True) 
    if plotPara:
       plt.axhline(y_trueth, color = 'k', linestyle = '--', label = 'Reference')
    else:
        plt.plot(range(len(y_trueth)),y_trueth, color = 'k', linestyle = '--', label = 'Reference')
    plt.xlim(0,140)

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
    plt.xlim(0,140)
    plt.legend()
    plt.xlabel('Day after plant')
    plt.ylabel(ylabel)
    plt.title(title)
    return fig

def restart_EnKF(DAA_enkf,Aquacrop,z,z2,tDAP,startDateTime,z_DAP,dt=1,restartUpdate=True):
    # re-initialize the plantingDate for samples (all samples init to DAP 0)
    sigmas0 = DAA_enkf.sigmas.copy()
    DAA_enkf.predict(dt = dt) 
    tmp = DAA_enkf.allState.copy() # states after init
    
    # calculate the target date (the date which trigger the restart)
    targetDate = (startDateTime + datetime.timedelta(tDAP)).strftime('%Y-%m-%d')
    targetDateNum = datetime.date(int(targetDate.split('-')[0]),int(targetDate.split('-')[1]),
                                       int(targetDate.split('-')[2])).toordinal()
    
    # initilaze self.allRestartDone and self.allRestartDone, if the currentDate of the sample reach the target, then abort simulation
    firstObsDate = (startDateTime + datetime.timedelta(int(np.min(z_DAP)))).strftime('%Y-%m-%d')
    firstObsDateNum = datetime.date(int(firstObsDate.split('-')[0]),int(firstObsDate.split('-')[1]),
                                   int(firstObsDate.split('-')[2])).toordinal()
    sigmasCurrentDate = [t['currentDate'] for t in tmp]  
    for i, currentDate in enumerate(sigmasCurrentDate):
        currentDateNum = datetime.date(int(currentDate.split('-')[0]),int(currentDate.split('-')[1]),
                                               int(currentDate.split('-')[2])).toordinal()
        if currentDateNum >= firstObsDateNum:
            DAA_enkf.nextObsDone[i] = True 
        if currentDateNum >= targetDateNum:
            DAA_enkf.restartDone[i] = True
    if not (False in DAA_enkf.restartDone): 
        DAA_enkf.allRestartDone = True 
    if not (False in DAA_enkf.nextObsDone): 
        DAA_enkf.allnextObsDone = True
 
    # re-simulate                    
    Aquacrop.restart = False  # switch off to aviod initializing
    LAI_loc = 0
    All_state_restart = []
    while not DAA_enkf.allRestartDone:       
        # next obs date
        if LAI_loc == 0:
            nextObsDateNum = firstObsDateNum
            print('firstObsDate %s'%firstObsDate)
        else:
            nextObsDate = (startDateTime + datetime.timedelta(int(z_DAP[LAI_loc]))).strftime('%Y-%m-%d')
            print('nextObsDate %s'%nextObsDate)
            nextObsDateNum = datetime.date(int(nextObsDate.split('-')[0]),int(nextObsDate.split('-')[1]),
                                           int(nextObsDate.split('-')[2])).toordinal()
        
        # predict
        while not (DAA_enkf.allnextObsDone | DAA_enkf.allRestartDone):            
            DAA_enkf.restartPredict(dt, nextObsDateNum, targetDateNum)  # all samples stop at the next obs date (start dates are different)
            Aquacrop.updateNextStep = False
            # print(DAA_enkf.restartDone)
            All_state_restart.append(DAA_enkf.allState.copy())
        
        # update when reach the observation date
        if DAA_enkf.allnextObsDone:
            if restartUpdate:
                # DAA_enkf.update(np.asarray([z[LAI_loc], 0]), R = np.diag([stdCC**2, 1e10]))
                obs1 = z[LAI_loc]
                obs2 = z2[LAI_loc]
                R1 = stdCC**2
                R2 = stdBio**2
                DAA_enkf.update(np.asarray([obs1, obs2, 0]), R = np.diag([R1, R2, 1e10]))
                Aquacrop.updateNextStep = True
            LAI_loc += 1
            DAA_enkf.resetNextDone()
               
    # reset
    DAA_enkf.resetNextDone()
    DAA_enkf.resetRestartDone()
    return All_state_restart
    
if __name__ == '__main__':
    
    ##  model settings
    inputpath = './AquaCropOS_v60a/Input/rice_NN/'
    aheadDay = 10
    start_date = ['2039','7','%d'%(15-aheadDay)]        
    ensemble_n = 300
    np.random.seed(0)
    OSS_path='OSSE_truth'
    outPath = 'OSSresult_3obs_shift_restartEnKF'#'OSSresult_1obs'
    CaseNote = 'oneShot_91_restartUpdate'#'_obsAFflowering'
    saveResult = True
    forceOpenloop = False
    restartUpdate=True
    ## Ensemble samples sampling
    UP = uncertain_para()
    u_para_default = UP.u_para_default
    # CV = [ 0.5]  + [0.1]*13 # Coefficient of Variation
    CV = [0.5, 0.05, 0.05, 0.08, 0.1,
          0.1, 0.1, 0.05, 0.05, 0.1,
          0.05, 0.15, 0.1, 0.1]
    # CV = [0]*17 # Coefficient of Variation
    std2_0 = list((np.asarray(u_para_default) * np.asarray(CV))**2)
    P_u_para = np.diag(std2_0)
    init_paras = list(np.random.multivariate_normal(mean=u_para_default, cov=P_u_para, size=ensemble_n))
    for i,init_para in enumerate(init_paras):
        extent_para = UP.replace_uncertain(init_para)  # padding the uncertain parameters to full size
        valid_para = UP.validation_check(extent_para)  # correct the init parameters
        init_paras[i] = valid_para
    
    ## batch Run EnKF
    # state_case_list = [1,2,3,4,5,6]
    state_case_list = [11]#[7]
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
         
        stdCC = 0.03
        stdBio = 50
        stdGDD = 20        
        
        R = np.diag([stdCC**2, stdBio**2, stdGDD**2])  # measurement cov matrix
        P0 = np.diag([0.])
       
        if case_n == 0: 
            if (not os.path.exists('openLoopResultShift.npy')) | forceOpenloop:
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
                
                np.save('openLoopResultShift.npy',[xs_enkf,P_enkf,K_enkf,sigmas_enkf,All_state])
            else:
                xs_enkf,P_enkf,K_enkf,sigmas_enkf,All_state = np.load('openLoopResultShift.npy',allow_pickle=True)
           
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
        # z_DAP_GDD = list(np.arange(1,len(z_origin),5))[4:]
        z_DAP_GDD = [91]
        z_DAP_GDD_restart = [91]
        z = [t for i,t in enumerate(z_origin) if (i+1) in z_DAP]
        z2 = [t for i,t in enumerate(z2_origin) if (i+1) in z_DAP]
        z3 = [t for i,t in enumerate(z3_origin) if (i+1) in z_DAP_GDD]
        DAP = 1

        while not DAA_enkf.allModelDone:
            
            # predict
            DAA_enkf.predict(dt = dt)  
            Aquacrop.updateNextStep = False
            Aquacrop.restart = False
            
            # update
            if (DAP in z_DAP) & (DAP in z_DAP_GDD):
                CC_Bio_loc = z_DAP.index(DAP)
                GDD_loc = z_DAP_GDD.index(DAP)
                
                # Nodata situation
                obs1 = z[CC_Bio_loc]
                obs2 = z2[CC_Bio_loc]
                obs3 = z3[GDD_loc]
                    
                DAA_enkf.update(np.asarray([obs1, obs2, obs3]))
                Aquacrop.updateNextStep = True
                if DAP in z_DAP_GDD_restart:
                    Aquacrop.restart = True
                
            elif DAP in z_DAP:
                CC_Bio_loc = z_DAP.index(DAP)
                obs1 = z[CC_Bio_loc]
                obs2 = z2[CC_Bio_loc]
                R1 = stdCC**2
                R2 = stdBio**2
                DAA_enkf.update(np.asarray([obs1, obs2, 0]), R = np.diag([R1, R2, 1e10]))
                Aquacrop.updateNextStep = True

            elif DAP in z_DAP_GDD:
                GDD_loc = z_DAP_GDD.index(DAP)
                obs3 = z3[GDD_loc]
                R3 = stdGDD**2
                DAA_enkf.update(np.asarray([0, 0, obs3]), R = np.diag([1e10, 1e10, R3]))
                Aquacrop.updateNextStep = True
                if DAP in z_DAP_GDD_restart:
                    Aquacrop.restart = True
                
            if DAP%10 == 0:
                print ('Simulating %d days...'%DAP)
            
            # restart simulation
            if Aquacrop.restart:
                print ('DAP %s'%DAP)
                # print ('before restart currentDate')
                # print ([t['currentDate'] for t in DAA_enkf.allState.copy()])
                if DAP == z_DAP_GDD_restart[-1]:
                    All_state_restart=restart_EnKF(DAA_enkf=DAA_enkf,Aquacrop=Aquacrop, z = z,z2=z2, tDAP = DAP,
                                 startDateTime =datetime.datetime(int(start_date[0]), int(start_date[1]), int(start_date[2])),
                                 z_DAP=z_DAP,restartUpdate=restartUpdate)
                else:
                    All_state_restart=restart_EnKF(DAA_enkf=DAA_enkf,Aquacrop=Aquacrop, z = z,z2=z2, tDAP = DAP,
                                 startDateTime =datetime.datetime(int(start_date[0]), int(start_date[1]), int(start_date[2])),
                                 z_DAP=z_DAP,restartUpdate=False)    
                # print ('after restart currentDate')
                # print ([t['currentDate'] for t in DAA_enkf.allState.copy()]) 
                    
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
            np.save('%s/case%d_%s.npy'%(outPath,state_case,CaseNote),[All_state,All_state2,All_state_restart])
        # plot CC
        # fig = DA_plot_state(DA_state_loc = 9, y_trueth = z3_origin, ylabel = 'GDD', title = 'Case %d'%state_case)
        fig = DA_plot(state_key = 'CC', y_trueth = z_origin, ylabel = 'Canoy cover %', title = 'Case %d'%state_case)
        if saveResult:
            fig.savefig(outPath + '/CC_case%d_%s.jpg'%(state_case,CaseNote), bbox_inches='tight')
        
        # plot yield
        y_trueth = list(np.zeros(aheadDay))+list(np.loadtxt('%s/sim_yield.in'%OSS_path))
        fig = DA_plot(state_key = 'yield',y_trueth = y_trueth, ylabel = 'Yield t/ha', title = 'Case %d'%state_case)
        plt.ylim(-0.2,8)
        if saveResult:
            fig.savefig(outPath + '/Yield_case%d_%s.jpg'%(state_case,CaseNote), bbox_inches='tight')
        
        # plot Biomass   
        y_trueth = list(np.zeros(aheadDay))+list(np.loadtxt('%s/sim_bio.in'%OSS_path))
        fig = DA_plot(state_key = 'biomass',y_trueth = y_trueth, ylabel = 'Biomass g/m2', title = 'Case %d'%state_case)
        plt.ylim(-50,2000)
        if saveResult:
            fig.savefig(outPath + '/Bio_case%d_%s.jpg'%(state_case,CaseNote), bbox_inches='tight')

        # plot HIadj   
        y_trueth = list(np.zeros(aheadDay))+list(np.loadtxt('%s/sim_HIadj.in'%OSS_path))
        fig = DA_plot(state_key = 'HIadj',y_trueth = y_trueth, ylabel = 'HIadj', title = 'Case %d'%state_case)
        # plt.ylim(-50,2000)
        if saveResult:
            fig.savefig(outPath + '/HIadj_case%d_%s.jpg'%(state_case,CaseNote), bbox_inches='tight')
            
        # plot Planting date
        fig = DA_plot(state_key = 'PlantingDate',y_trueth = 744926, ylabel = 'Planting date', plotPara = True, title = 'Case %d'%state_case) 
        # plt.ylim(7,11)
        if saveResult:
            fig.savefig(outPath + '/Tbase_case%d_%s.jpg'%(state_case,CaseNote), bbox_inches='tight')        
        
        
        # plot GDD
        y_trueth = list(np.zeros(aheadDay))+list(np.loadtxt('%s/sim_GDD.in'%OSS_path))
        fig = DA_plot(state_key = 'GDDcum', y_trueth = y_trueth, ylabel = 'GDD g/m2', title = 'Case %d'%state_case)
        plt.ylim(-50,2200)
        if saveResult:
            fig.savefig(outPath + '/GDD_case%d_%s.jpg'%(state_case,CaseNote), bbox_inches='tight')
            
