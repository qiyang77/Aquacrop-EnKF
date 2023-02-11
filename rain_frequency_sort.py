# -*- coding: utf-8 -*-
"""
Created on Mon Aug 24 10:40:15 2020

@author: Qi Yang

Find the typical year by sorting the stochastic weather data
"""

import numpy as np
import matplotlib.pyplot as plt

data = np.loadtxt('AquaCropOS_v60a/Input/rice_NN/aquacrop_os_SIM_NanNing_CHN_2000_100.cli', skiprows = 1)

start_year = 2000
rain_year = []
for i in range(100):        
    loc = np.where(data[:,2] == (start_year + i))[0]
    tmp = data[loc,5]
    rain_year.append(np.sum(tmp))
        

# histogram
fig = plt.figure()
plt.hist(rain_year, 20)

# sort
rain_year_sort = [np.array([i,t]) for i,t in enumerate(rain_year)]
sort_loc = np.argsort(rain_year)
tmp = list(sort_loc)
tmp.reverse()
sort_loc = np.array(tmp)
rain_year_sort = np.array(rain_year)[sort_loc]

# typical year
wet_year = start_year + sort_loc[int(0.2*len(sort_loc))]# wet_year  20%
normal_year = start_year + sort_loc[int(0.5*len(sort_loc))]# normal_year  50%
dry_year = start_year + sort_loc[int(0.8*len(sort_loc))]# dry_year  80%

print ('Wet year: %d, with rain %.1f mm \n\
normal year: %d, with rain %.1f mm \n\
dry year: %d, with rain %.1f mm'%(wet_year,rain_year[wet_year-start_year], normal_year,
       rain_year[normal_year-start_year],dry_year,rain_year[dry_year-start_year]))