# -*- coding: utf-8 -*-
# pylint: disable=invalid-name, too-many-arguments, too-many-instance-attributes
# pylint: disable=attribute-defined-outside-init

"""Copyright 2015 Roger R Labbe Jr.

FilterPy library.
http://github.com/rlabbe/filterpy

Documentation at:
https://filterpy.readthedocs.org

Supporting book at:
https://github.com/rlabbe/Kalman-and-Bayesian-Filters-in-Python

This is licensed under an MIT license. See the readme.MD file
for more information.
"""


from __future__ import (absolute_import, division, print_function,
                        unicode_literals)

from copy import deepcopy
import numpy as np
from numpy import array, zeros, eye, dot
from numpy.random import multivariate_normal
from KFs.common import pretty_str, outer_product_sum
import datetime

class EnsembleKalmanFilter(object):
    """
    This implements the ensemble Kalman filter (EnKF). The EnKF uses
    an ensemble of hundreds to thousands of state vectors that are randomly
    sampled around the estimate, and adds perturbations at each update and
    predict step. It is useful for extremely large systems such as found
    in hydrophysics. As such, this class is admittedly a toy as it is far
    too slow with large N.

    There are many versions of this sort of this filter. This formulation is
    due to Crassidis and Junkins [1]. It works with both linear and nonlinear
    systems.

    Parameters
    ----------

    x : np.array(dim_x)
        state mean

    P : np.array((dim_x, dim_x))
        covariance of the state

    dim_z : int
        Number of of measurement inputs. For example, if the sensor
        provides you with position in (x,y), dim_z would be 2.

    N : int
        number of sigma points (ensembles). Must be greater than 1.

    K : np.array
        Kalman gain

    hx : function hx(x)
        Measurement function. May be linear or nonlinear - converts state
        x into a measurement. Return must be an np.array of the same
        dimensionality as the measurement vector.

    fx : function fx(x, dt)
        State transition function. May be linear or nonlinear. Projects
        state x into the next time period. Returns the projected state x.


    Attributes
    ----------
    x : numpy.array(dim_x, 1)
        State estimate

    P : numpy.array(dim_x, dim_x)
        State covariance matrix

    x_prior : numpy.array(dim_x, 1)
        Prior (predicted) state estimate. The *_prior and *_post attributes
        are for convienence; they store the  prior and posterior of the
        current epoch. Read Only.

    P_prior : numpy.array(dim_x, dim_x)
        Prior (predicted) state covariance matrix. Read Only.

    x_post : numpy.array(dim_x, 1)
        Posterior (updated) state estimate. Read Only.

    P_post : numpy.array(dim_x, dim_x)
        Posterior (updated) state covariance matrix. Read Only.

    z : numpy.array
        Last measurement used in update(). Read only.

    R : numpy.array(dim_z, dim_z)
        Measurement noise matrix

    Q : numpy.array(dim_x, dim_x)
        Process noise matrix

    fx : callable (x, dt)
        State transition function

    hx : callable (x)
        Measurement function. Convert state `x` into a measurement

    K : numpy.array(dim_x, dim_z)
        Kalman gain of the update step. Read only.

    inv : function, default numpy.linalg.inv
        If you prefer another inverse function, such as the Moore-Penrose
        pseudo inverse, set it to that instead: kf.inv = np.linalg.pinv

    """

    def __init__(self, x, P, dim_z, N, hx, fx, x_paraLoc = None):
        if dim_z <= 0:
            raise ValueError('dim_z must be greater than zero')

        if N <= 0:
            raise ValueError('N must be greater than zero')

        dim_x = len(x)
        self.dim_x = dim_x
        self.dim_z = dim_z
        self.N = N
        self.hx = hx
        self.fx = fx
        self.K = zeros((dim_x, dim_z))
        self.z = array([[None] * self.dim_z]).T
        self.S = zeros((dim_z, dim_z))   # system uncertainty
        self.SI = zeros((dim_z, dim_z))  # inverse system uncertainty
        self.x_paraLoc = x_paraLoc
        self.initialize(x, P)
        # self.Q = eye(dim_x)       # process uncertainty # discarded by Qi
        self.R = eye(dim_z)       # state uncertainty
        self.inv = np.linalg.inv

        # used to create error terms centered at 0 mean for
        # state and measurement
        self._mean = zeros(dim_x)
        self._mean_z = zeros(dim_z)
        self.allState = [''] * self.N  # added by Qi 2020/8/31
        self.modelDone = [False] * self.N  # added by Qi 2020/8/31
        self.allModelDone = False  # added by Qi 2020/8/31
        self.nextObsDone = [False] * self.N 
        self.allnextObsDone = False 
        self.restartDone = [False] * self.N 
        self.allRestartDone = False 
        
    def initialize(self, x, P):
        """
        Initializes the filter with the specified mean and
        covariance. Only need to call this if you are using the filter
        to filter more than one set of data; this is called by __init__

        Parameters
        ----------

        x : np.array(dim_z)
            state mean

        P : np.array((dim_x, dim_x))
            covariance of the state
        """

        if x.ndim != 1:
            raise ValueError('x must be a 1D array')
            
        if self.x_paraLoc == None:  # added by Qi 2020/9/11
            self.sigmas = np.tile(x, (self.N, 1))  # added by Qi 2020/8/31
        else:
            CV = 0.1
            state_loc = [t for t in range(len(x)) if not t in self.x_paraLoc]  # added by Qi 2020/9/11
            self.sigmas = np.tile(x[state_loc], (self.N, 1))
            Pt = np.diag(list((x[self.x_paraLoc] * CV)**2))
            statePara = multivariate_normal(mean=x[self.x_paraLoc], cov=Pt, size=self.N)
            self.sigmas = np.hstack((self.sigmas, statePara))
            
        self.x = x
        self.P = P
        self.P_z = P  # added by Qi 2021/8/13, the P in measuremental space
        
        # these will always be a copy of x,P after predict() is called
        self.x_prior = self.x.copy()
        self.P_prior = self.P.copy()

        # these will always be a copy of x,P after update() is called
        self.x_post = self.x.copy()
        self.P_post = self.P.copy()

    def update(self, z, R=None, Q = None):  # 'Q': the process error, added by Qi 2020/10/9
        """
        Add a new measurement (z) to the kalman filter. If z is None, nothing
        is changed.

        Parameters
        ----------

        z : np.array
            measurement for this update.

        R : np.array, scalar, or None
            Optionally provide R to override the measurement noise for this
            one call, otherwise self.R will be used.
        """

        if z is None:
            self.z = array([[None]*self.dim_z]).T
            self.x_post = self.x.copy()
            self.P_post = self.P.copy()
            return

        if R is None:
            R = self.R
        if np.isscalar(R):
            R = eye(self.dim_z) * R
        if Q is None:  # 'Q': the process error, added by Qi 2020/10/9
            Q = R.copy()
        N = self.N
        dim_z = len(z)
        sigmas_h = zeros((N, dim_z))

        # transform sigma points into measurement space
        for i in range(N):
            sigmas_h[i] = self.hx(self.sigmas[i])

        z_mean = np.mean(sigmas_h, axis=0)

        P_zz = (outer_product_sum(sigmas_h - z_mean) / (N-1)) + R
        P_xz = outer_product_sum(
                self.sigmas - self.x, sigmas_h - z_mean) / (N - 1)

        self.S = P_zz
        self.SI = self.inv(self.S)
        self.K = dot(P_xz, self.SI)
        
        # tmp = self.sigmas[0].copy()
        # print ('update sigmas0:{}'.format(self.sigmas[2]))
        e_r = multivariate_normal(self._mean_z, Q, N)
        for i in range(N):
            self.sigmas[i] += dot(self.K, z + e_r[i] - sigmas_h[i])
        # print('sigmas:{},K:{},Q:{},er:{},delta:{}'.format(self.sigmas[0], self.K,Q,e_r, z + e_r[0] - sigmas_h[0]))
        # print ('origin sigmas:{}, updated:{}, K:{}, z:{}, delta :{}'.format(tmp, self.sigmas[0], self.K, z, z + e_r[0] - sigmas_h[0]))
        self.x = np.mean(self.sigmas, axis=0)
        self.P = self.P - dot(dot(self.K, self.S), self.K.T)

        # save measurement and posterior state
        self.z = deepcopy(z)
        self.x_post = self.x.copy()
        self.P_post = self.P.copy()

    def predict(self,dt):
        """ Predict next position. """

        N = self.N
        for i, s in enumerate(self.sigmas):
            self.sigmas[i],self.allState[i] = self.fx(s, dt, i)
            self.modelDone[i] = self.allState[i]['Done']  # added by Qi 2020/8/31
        if not (False in self.modelDone):  # added by Qi 2020/8/31
            self.allModelDone = True  # added by Qi 2020/8/31
        
        # e = multivariate_normal(self._mean, self.Q, N)  # discard by Qi 2020/8/31
        # self.sigmas += e

        self.x = np.mean(self.sigmas, axis=0)
        self.P = outer_product_sum(self.sigmas - self.x) / (N - 1)
        sigmas_h = np.array([self.hx(self.sigmas[i]) for i in range(N)])
        self.P_z = outer_product_sum(sigmas_h - np.mean(sigmas_h, axis=0)) / (N - 1)  # added by Qi 2021/8/13, the P in measuremental space
        
        # save prior
        self.x_prior = np.copy(self.x)
        self.P_prior = np.copy(self.P)
        
    def resetNextDone(self):
        self.nextObsDone = [False] * self.N 
        self.allnextObsDone = False 
        
    def resetRestartDone(self):
        self.restartDone = [False] * self.N 
        self.allRestartDone = False 
        
    def restartPredict(self,dt,nextObsDateNum,targetDateNum):   # added by Qi 2020/10/6
        """ Predict next position. """

        N = self.N
        for i, s in enumerate(self.sigmas):
            if not self.restartDone[i]:
                if not self.nextObsDone[i]:
                    self.sigmas[i],self.allState[i] = self.fx(s, dt, i)
                    currentDate = self.allState[i]['currentDate']
                    currentDateNum = datetime.date(int(currentDate.split('-')[0]),int(currentDate.split('-')[1]),
                                           int(currentDate.split('-')[2])).toordinal()
                    if currentDateNum >= nextObsDateNum:
                        self.nextObsDone[i] = True 
                    if currentDateNum >= targetDateNum:
                        self.restartDone[i] = True
        if not (False in self.restartDone): 
            self.allRestartDone = True 
        if not (False in self.nextObsDone): 
            self.allnextObsDone = True         
        # e = multivariate_normal(self._mean, self.Q, N)  # discard by Qi 2020/8/31
        # self.sigmas += e

        self.x = np.mean(self.sigmas, axis=0)
        self.P = outer_product_sum(self.sigmas - self.x) / (N - 1)

        # save prior
        self.x_prior = np.copy(self.x)
        self.P_prior = np.copy(self.P)
       
    def __repr__(self):
        return '\n'.join([
            'EnsembleKalmanFilter object',
            pretty_str('dim_x', self.dim_x),
            pretty_str('dim_z', self.dim_z),
            pretty_str('x', self.x),
            pretty_str('P', self.P),
            pretty_str('x_prior', self.x_prior),
            pretty_str('P_prior', self.P_prior),
            # pretty_str('Q', self.Q),
            pretty_str('R', self.R),
            pretty_str('K', self.K),
            pretty_str('S', self.S),
            pretty_str('sigmas', self.sigmas),
            pretty_str('hx', self.hx),
            pretty_str('fx', self.fx)
            ])
