# Aquacrop-EnKF
A crop growth simulation system based on Aquacrop-OS crop model and ensemble Kalman filter.

# Highlights
## Assimilating phenological observations without disturbing the model clock/timeline.

**Context or problem:** in crop growth data assimilation systems, the mismatch between simulated and observed phenology significantly deteriorates the performance of crop growth modeling. This situation may be more severe for smallholder farmers-managed fields, where the phenological heterogeneity was high even when climate condition was relatively uniform. Previous studies investigated the non-sequential methods to retrospectively assimilate historical phenology observations. However, approaches to dynamically assimilating phenological measurements through sequential data assimilation methods remain unexplored

**Objective or research question:** one of the most intractable challenges of dynamic phenology assimilation is that aconsiderable proportion of model parameters and variables are entangled with phenology, therefore simply assimilating phenological measurements could disturb the model clock. This study aims to establish a robust crop
data assimilation framework capable of assimilating phenological measurements in real time without disturbing the model clock.
Source code will be available after the paper "Improving rice growth simulation and yield estimation by assimilating phenological observations sequentially via ensemble Kalman filter" is published.

**Citation:** Yang, Q., Shi, L., Han, J., Zha, Y., Yu, J., Wu, W. and Huang, K., 2023. Regulating the time of the crop model clock: A data assimilation framework for regions with high phenological heterogeneity. Field Crops Research, 293, p.108847.

# Usage
## Install the python API for matlab

```# Find the path of your Matlab```<br>
```cd *:\***\Polyspace\R2019b\extern\engines\python```<br>
```python setup.py install```<br>
Or refer to [this page](https://www.mathworks.com/help/matlab/matlab_external/install-the-matlab-engine-for-python.html)

## Validate the consistency between official FAO-AquaCrop (v6.0) and AquaCropOS (v6.0) 

**DAA_OS_vs_official_climate.py:** Compare the agreement of Aquacrop-OS and FAO-Aquacrop under various climate scenarios

**DAA_OS_vs_official_parameter.py** Compare the agreement of Aquacrop-OS and FAO-Aquacrop under different parameter combinations

## Two-step global sensitivity analysis

```pip install salib # install the external SA lib```

**rain_frequency_sort.py:** this script is used to find out the typical year (i.e., wet, normal, and dry year) from stochastic weather data.

**SA_aquacrop_morris.py:** Morris methods (Morris, 1991) to screen out the insensitive parameters in AquaCropOS (parameter details were described in the supplementary
material, Table S1). This method has high computational efficiency and thus is suitable for a rapid pre-selection before quantitative analysis. 

**SA_aquacrop_sobol.py** the sensitivity of the remaining parameters was quantitatively analyzed by Sobol’ method (Sobol’, 1990)
Morris, M.D., 1991. Factorial sampling plans for preliminary computational experiments. Technometrics 33, 161–174. https://doi.org/10.1080/00401706.1991.10484804
Sobol’, I.M., 1990. On sensitivity estimation for nonlinear mathematical models. Mat. Model 2, 112–118.

##  Observing System Simulation Experiments (OSSE)

**DAA_EnKF_batchOSS.py:** assimilating only measurements of canopy cover (CC).

**DAA_EnKF_batchOSS_phenoShift.py:** assimilating only measurements of canopy cover (CC) with wrong planting date.

**DAA_EnKF_batchOSS_2obs.py:** assimilating canopy cover (CC) and aboveground biomass.

**DAA_EnKF_batchOSS_3obs_phenoShift.py:** assimilating Canopy Cover (CC) and aboveground biomass, and phenology (represented by GDD) with wrong planting date.

**DAA_EnKF_batchOSS_3obs_phenoShift_restartEnKF.py:** assimilating Canopy Cover (CC) and aboveground biomass, and phenology (represented by GDD) with wrong planting date using restartEnKF strategy.
