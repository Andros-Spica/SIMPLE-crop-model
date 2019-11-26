# SIMPLE-crop-model
[NetLogo](https://ccl.northwestern.edu/netlogo/) implementation by Andreas Angourakis (a.k.a. Andros-Spica) of the SIMPLE crop model by Zhao et al. 2019 (https://doi.org/10.1016/j.eja.2019.01.009)


![Graphic digest of the model as it is presented in Zhao et al. 2019](https://github.com/Andros-Spica/SIMPLE-crop-model/blob/master/SIMPLE%20crop%20model%20by%20Zhao-et-al-2019.png)

---

![Snapshot of the implementation in NetLogo](https://github.com/Andros-Spica/SIMPLE-crop-model/blob/master/SIMPLE-crop-model%20interface.png)

The current preliminary version has **S_CO2** crop parameter fixed at 0.001 (see [lines 475-478](https://github.com/Andros-Spica/SIMPLE-crop-model/blob/7d9f30d27d5bcde172911e8870e5c9301e40f480/SIMPLE-crop-model.nlogo#L475)) in order to have S_CO2 at the scale of 1, producing biomass and harvests at a "realistic" scale. (pending solving issue related to f(CO2), see flow diagram above). This issue is only relevant with CO2 concentrations higher than 350 ppm.
