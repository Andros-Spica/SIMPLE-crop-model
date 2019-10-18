;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; GNU GENERAL PUBLIC LICENSE ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;  SIMPLE crop model (NetLogo implementation)
;;  Copyright (C) 2019 Andreas Angourakis (andros.spica@gmail.com)
;;  based on the contents of Zhao et al. 2019 (https://doi.org/10.1016/j.eja.2019.01.009)
;;  last update Oct 2019
;;  available at https://www.github.com/Andros-Spica/abm-templates
;;
;;  This program is free software: you can redistribute it and/or modify
;;  it under the terms of the GNU General Public License as published by
;;  the Free Software Foundation, either version 3 of the License, or
;;  (at your option) any later version.
;;
;;  This program is distributed in the hope that it will be useful,
;;  but WITHOUT ANY WARRANTY; without even the implied warranty of
;;  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;;  GNU General Public License for more details.
;;
;;  You should have received a copy of the GNU General Public License
;;  along with this program.  If not, see <http://www.gnu.org/licenses/>.

extensions [csv vid]

;;;;;;;;;;;;;;;;;
;;;;; BREEDS ;;;;
;;;;;;;;;;;;;;;;;

; no breeds

;;;;;;;;;;;;;;;;;
;;; VARIABLES ;;;
;;;;;;;;;;;;;;;;;

globals
[
  ;;; default constants
  totalPatches
  maxDist
  yearLenghtInDays

  typesOfCrops

  ;;; modified parameters

  ;;;; temperature (ºC)
  annualMaxTemperatureAtBaseLevel
  annualMinTemperatureAtBaseLevel
  dailyMeanTemperatureFluctuation
  dailytemperatureLowerDeviation
  dailytemperatureUpperDeviation

  ;;;; CO2 (ppm)
  meanCO2
  annualCO2Deviation
  dailyCO2Fluctuation

  ;;;; Solar radiation (kWh/m2)
  annualMaxSolarRadiation
  annualMinSolarRadiation
  dailyMeanSolarRadiationFluctuation

  ;;;; Crop parameters (extracted from cropsTable.csv)
  ;;;; the above are lists of floats
  ;;;; Species-specific
  RUE
  T_base
  T_opt
  I_50maxH
  I_50maxW
  T_heat
  T_extreme
  S_CO2
  S_Water
  ;;;; Cultivar-specific
  T_sum
  HI
  I_50A
  I_50B
  ;;;; management
  sugSowingDay
  sugHarvestingDay

  ;;; variables
  ;;;; time tracking
  currentYear
  currentDayInYear
  sowingDay
  harvestingDay

  ;;;; main (these follow a seasonal pattern and apply for all patches)
  T
  T_max
  T_min
  CO2
  solarRadiation

  ;;;; counters and final measures
  maxBiomass
  maxMeanYield
]

;;; agents variables

patches-own
[
  ;;; input variables (local, given by a spatial dataset)
  ;;;; water availability
  ET_0
  AWC
  ;;;; soil
  RCN
  DDC
  RZD
  ;;;; management
  f_Solar_max

  ;;; main variables
  crop ; this implementation assumes a single crop is grown per patch (randomly assigned at the setup)
  TT
  biomass
  yield

  ;;; auxiliar variables
  biomass_rate
  f_solar
  I_50Blocal
  f_CO2
  f_temp
  f_heat
  f_water
  ARID
  PAW
]

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; SETUP ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to setup

  clear-all

  ; --- loading/testing parameters -----------

  set-constants

  load-crops-table

  set-parameters

  ; --- core procedures ----------------------

  set currentDayInYear 1

  setup-patches

  update-inputs

  ; --- output handling ------------------------

  update-counters

  refresh-view

  reset-ticks

end

to set-constants

  ; "constants" are variables that will not be explored as parameters
  ; and may be used during a simulation.
  ; In this example, the constants depend on the size of the dimensions (x,y)
  set totalPatches count patches
  ; maximum distance
  set maxDist sqrt (((max-pxcor - min-pxcor) ^ 2) + ((max-pxcor - min-pxcor) ^ 2))

  set yearLenghtInDays 365

end

to set-parameters

  ; set random seed
  random-seed seed

  ; check parameters values
  parameters-check

  ;;; setup parameters depending on the type of experiment
  if (type-of-experiment = "user-defined")
  [
    ;;; load parameters from user interface
    set annualMaxTemperatureAtBaseLevel annual-max-temperature-at-base-level
    set annualMinTemperatureAtBaseLevel annual-min-temperature-at-base-level
    set dailyMeanTemperatureFluctuation daily-mean-temperature-fluctuation
    set dailyTemperatureLowerDeviation daily-temperature-lower-deviation
    set dailyTemperatureUpperDeviation daily-temperature-upper-deviation

    set meanCO2 mean-CO2
    set annualCO2Deviation annual-CO2-deviation
    set dailyCO2Fluctuation daily-CO2-fluctuation

    set annualMaxSolarRadiation annual-max-solar-radiation
    set annualMinSolarRadiation annual-min-solar-radiation
    set dailyMeanSolarRadiationFluctuation daily-mean-solar-radiation-fluctuation
  ]
  if (type-of-experiment = "random")
  [
    ;;; use values from user interface as a maximum for random uniform distributions
    set annualMaxTemperatureAtBaseLevel 15 + random-float 35
    set annualMinTemperatureAtBaseLevel -15 + random-float 30
    set dailyMeanTemperatureFluctuation random-float daily-mean-temperature-fluctuation
    set dailyTemperatureLowerDeviation random-float daily-temperature-lower-deviation
    set dailyTemperatureUpperDeviation random-float daily-temperature-upper-deviation

    set meanCO2 random-normal 350 20
    set annualCO2Deviation max (list 0 random-normal 2.5 0.5)
    set dailyCO2Fluctuation max (list 0 random-normal 2.5 0.5)

    set annualMinSolarRadiation random-normal 4 0.1
    set annualMaxSolarRadiation annualMinSolarRadiation + random-float 2
    set dailyMeanSolarRadiationFluctuation 0.01
  ]

  ;;; to be modified
  set sowingDay sugSowingDay
  set harvestingDay sugHarvestingDay

end

to parameters-check

  ;;; check if values were reset to 0 (NetLogo does that from time to time...!)
  ;;; and set default values (assuming they are not 0)

end

to setup-patches

  ask patches
  [
    set crop one-of typesOfCrops

    set RCN 70
    set DDC 0.3
    set RZD 800

    set f_Solar_max 0.95

    set yield (list)
  ]

end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; GO ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to go

  ; --- core procedures -------------------------

  update-inputs

  update-crops

  ; --- output handling ------------------------

  update-counters

  refresh-view

  ; --------------------------------------------

  advance-time

  tick

  ; --- stop conditions -------------------------

  if (ticks = end-simulation-in-tick) [stop]

end

;;; GLOBAL ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to advance-time

  set currentDayInYear currentDayInYear + 1
  if (currentDayInYear > yearLenghtInDays)
  [
    set currentYear currentYear + 1
    set currentDayInYear 1
  ]

end

to update-inputs

  ;;; values are assigned using simple parametric models
  ;;; alternatively, a specific time series could be used

  update-temperature currentDayInYear

  set CO2 get-CO2 currentDayInYear

  set solarRadiation get-solar-radiation currentDayInYear

  ask patches
  [
    set AWC 0.12
    ;;; set ET_0

    ;set ARID (1 - min (list ET_0 (0.096 * PAW / ET_0)))
    set ARID min (list 1 (abs random-normal 0 0.1))
  ]

end

to update-temperature [ dayInYear ]

  set T random-normal (get-temperature dayInYear) dailyMeanTemperatureFluctuation

  set T_min T - dailyTemperatureLowerDeviation

  set T_max T + dailyTemperatureUpperDeviation

end

to-report get-temperature [ dayInYear ]

  ; get temperature base level for the current day (ºC at lowest elevation)

  let amplitude (annualMaxTemperatureAtBaseLevel - annualMinTemperatureAtBaseLevel) / 2
  report annualMinTemperatureAtBaseLevel + amplitude * (1 + sin (270 + 360 * dayInYear / yearLenghtInDays)) ; sin function in NetLogo needs angle in degrees. 270º equivalent to 3 * pi / 2 and 360º equivalent to 2 * pi

end

to-report get-CO2 [ dayInYear ]

  ; get CO2 atmospheric concentration for the current day (ppm)
  let CO2-osc meanCO2 - annualCO2Deviation + annualCO2Deviation * (1 + sin (270 + 360 * dayInYear / yearLenghtInDays)) ; sin function in NetLogo needs angle in degrees. 270º equivalent to 3 * pi / 2 and 360º equivalent to 2 * pi

  report max (list 0 random-normal CO2-osc dailyCO2Fluctuation)

end

to-report get-solar-radiation [ dayInYear ]

  ;;; see approx. values in https://globalsolaratlas.info/

  let amplitude (annualMaxSolarRadiation - annualMinSolarRadiation) / 2
  let modelBase annualMinSolarRadiation + amplitude * (1 + sin (270 + 360 * dayInYear / yearLenghtInDays)) ; sin function in NetLogo needs angle in degrees. 270º equivalent to 3 * pi / 2 and 360º equivalent to 2 * pi
  let withFluctuation max (list 0 random-normal modelBase dailyMeanSolarRadiationFluctuation)

  ;;; return value converted from kWh/m2 to MJ/m2 (1 : 3.6)
  report withFluctuation * 3.6

end

to update-crops

  ask patches
  [
    let cropIndex position crop typesOfCrops

    if ( is-growing cropIndex )
    [
      update-biomass cropIndex
    ]

    if ( is-ripe cropIndex )
    [
      ;;; calculate harvest yield
      ifelse (TT >= item cropIndex T_sum)
      [ set yield lput (biomass * item cropIndex HI) yield ]
      [ set yield lput 0 yield ]
      ;;; reset biomass and auxiliary variables
      reset-variables
    ]
  ]

end

;;; PATCHES ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to reset-variables

  set TT 0
  set biomass 0

  set biomass_rate 0
  set f_solar 0
  set I_50Blocal 0
  set f_CO2 0
  set f_temp 0
  set f_heat 0
  set f_water 0

end

to-report is-growing [ cropIndex ]

  let myCropSowingDay (item cropIndex sowingDay)
  let myCropHarvestingDay (item cropIndex harvestingDay)

  ifelse (myCropSowingDay < myCropHarvestingDay)
  [
    ; summer crop (sowing day comes before harvesting day in the Jan-Dec calendar)
    report (currentDayInYear >= myCropSowingDay) and (currentDayInYear < myCropHarvestingDay)
  ]
  [
    ; winter crop (harvesting day comes before sowing day in the Jan-Dec calendar; ignore first year harvest)
    report (currentDayInYear >= myCropSowingDay) or (currentYear > 0 and currentDayInYear < myCropHarvestingDay)
  ]

end

to-report is-ripe [ cropIndex ]

  report (currentDayInYear = item cropIndex harvestingDay)

end

to update-biomass [ cropIndex ]

  update-TT cropIndex

  update-f_CO2 cropIndex

  update-f_Temp cropIndex

  update-f_Heat cropIndex

  update-f__Water cropIndex

  set I_50Blocal ((item cropIndex I_50B) + (item cropIndex I_50maxW) * (1 - f_Water) + (item cropIndex I_50maxH) * (1 - f_Heat))

  update-f_Solar cropIndex

  set biomass_rate solarRadiation * (item cropIndex RUE) * f_Solar * f_CO2 * f_Temp * min (list f_Heat f_Water)

  set biomass biomass + biomass_rate

end

to update-TT [ cropIndex ]

  let deltaTT 0

  ifelse ( T > item cropIndex T_base )
  [
    set deltaTT T - item cropIndex T_base
  ]
  [
    set deltaTT 0
  ]

  set TT TT + deltaTT

end

to update-f_CO2 [ cropIndex ]

  ifelse ( CO2 <= 350 )
  [
    set f_CO2 1 ; this is not specified in Zhao et al. 2019
  ]
  [
    ifelse ( CO2 > 700 )
    [
      set f_CO2 1 + 0.001 * 350;(item cropIndex S_CO2) * 350
    ]
    [
      set f_CO2 1 + 0.001 * (CO2 - 350);(item cropIndex S_CO2) * (CO2 - 350)
    ]
  ]

end

to update-f_Temp [ cropIndex ]

  ifelse ( T < item cropIndex T_base )
  [
    set f_Temp 0
  ]
  [
    ifelse ( T >= item cropIndex T_opt )
    [
      set f_Temp 1
    ]
    [
      set f_Temp (T - item cropIndex T_base) / (item cropIndex T_opt - item cropIndex T_base)
    ]
  ]

end

to update-f_Heat [ cropIndex ]

  ifelse ( T_max <= item cropIndex T_heat )
  [
    set f_Heat 1
  ]
  [
    ifelse ( T_max > item cropIndex T_extreme )
    [
      set f_Heat 0
    ]
    [
      set f_Heat (T_max - item cropIndex T_heat) / (item cropIndex T_extreme - item cropIndex T_heat)
    ]
  ]

end

to update-f__Water [ cropIndex ]

  set f_Water 1 - (item cropIndex S_Water) * ARID

end

to update-f_Solar [ cropIndex ]

  ifelse (TT < item cropIndex T_sum)
  [
    set f_Solar f_Solar_max / (1 + e ^ (-0.01 * (TT - item cropIndex I_50A)))
  ]
  [
    set f_Solar f_Solar_max / (1 + e ^ (-0.01 * (TT - I_50Blocal)))
  ]

  ;;; drought effect
  if (f_Water < 0.1)
  [
    set f_Solar f_Solar * (0.9 + f_Water)
  ]

end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; COUNTERS AND MEASURES ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to update-counters

  let newMaxBiomass max [biomass] of patches
  set maxBiomass max (list maxBiomass newMaxBiomass)

  carefully [ set maxMeanYield max [mean yield] of patches ] [ set maxMeanYield 0 ]

end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; DISPLAY ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to refresh-view

  refresh-to-display-mode

end

to refresh-to-display-mode

  ;;; set patch color depending on the display mode selector
  if (display-mode = "crops")
  [
    ask patches [ display-crops ]
  ]

  if (display-mode = "ARID")
  [
    ask patches [ display-arid ]
  ]

  if (display-mode = "biomass")
  [
    ask patches [ display-biomass ]
  ]

  if (display-mode = "mean yield")
  [
    ask patches [ display-meanYield ]
  ]

end

to display-crops

  set pcolor (15 + 7 * 10 * (position crop typesOfCrops)) mod 140 ; for a maximum of 13 crops

end

to display-arid

  set pcolor 14 + 5 * (1 - ARID)

end

to display-biomass

  ifelse (biomass > 0)
  [ set pcolor 52 + 6 * (1 - biomass / (maxBiomass + 1E-6)) ]
  [ set pcolor 59 ]

end

to display-meanYield

  carefully [ set pcolor 42 + 6 * (1 - mean yield / (maxMeanYield + 1E-6)) ] [ set pcolor 49 ]

end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; LOAD DATA FROM TABLES ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to load-crops-table

  ;;; this procedure loads the values of the crops table
  ;;; the table contains:
  ;;;   1. two lines of headers with comments (metadata, to be ignored)
  ;;;   2. two lines with statements mapping the different types of data, if more than one
  ;;;   3. the header of the table with the names of variables
  ;;;   4. remaining rows containing row name and values

  let cropsTable csv:from-file "cropsTable.csv"

  ;;;==================================================================================================================
  ;;; mapping coordinates (row or columns) in lines 3 and 4 (= index 2 and 3) -----------------------------------------
  ;;; NOTE: always correct raw mapping coordinates (start at 1) into list indexes (start at 0)

  ;;; line 3 (= index 2), row indexes

  ;;; Types of crops rows: value 2 and 4 (= index 1 and 3)
  let typesOfCropsRowRange (list ((item 1 (item 2 cropsTable)) - 1) ((item 3 (item 2 cropsTable)) - 1))

  ;;; line 4 (= index 3), column indexes

  ;;; annual base yield (unmanured) (Kg/ha) column: value 2 (= index 1)
  let T_sumColumn (item 1 (item 3 cropsTable)) - 1

  let HIColumn (item 3 (item 3 cropsTable)) - 1

  let I_50AColumn (item 5 (item 3 cropsTable)) - 1

  let I_50BColumn (item 7 (item 3 cropsTable)) - 1

  let T_baseColumn (item 9 (item 3 cropsTable)) - 1

  let T_optColumn (item 11 (item 3 cropsTable)) - 1

  let RUEColumn (item 13 (item 3 cropsTable)) - 1

  let I_50maxHColumn (item 15 (item 3 cropsTable)) - 1

  let I_50maxWColumn (item 17 (item 3 cropsTable)) - 1

  let T_heatColumn (item 19 (item 3 cropsTable)) - 1

  let T_extColumn (item 21 (item 3 cropsTable)) - 1

  let S_CO2Column (item 23 (item 3 cropsTable)) - 1

  let S_waterColumn (item 25 (item 3 cropsTable)) - 1

  let sugSowingDayColumn (item 27 (item 3 cropsTable)) - 1

  let sugHarvestingDayColumn (item 29 (item 3 cropsTable)) - 1

  ;;;==================================================================================================================
  ;;; extract data---------------------------------------------------------------------------------------

  ;;; read variables per crop type (list of lists, matrix: crop types x variables)
  let cropsData sublist cropsTable (item 0 typesOfCropsRowRange) (item 1 typesOfCropsRowRange + 1) ; select only those row corresponding to types of crops, if there is anything else

  ;;; extract types of crops from the first column
  set typesOfCrops map [row -> item 0 row ] cropsData

  ;;; extract parameter values from the given column
  set T_sum map [row -> item T_sumColumn row ] cropsData

  set HI map [row -> item HIColumn row ] cropsData

  set I_50A map [row -> item I_50AColumn row ] cropsData

  set I_50B map [row -> item I_50BColumn row ] cropsData

  set T_base map [row -> item T_baseColumn row ] cropsData

  set T_opt map [row -> item T_optColumn row ] cropsData

  set RUE map [row -> item RUEColumn row ] cropsData

  set I_50maxH map [row -> item I_50maxHColumn row ] cropsData

  set I_50maxW map [row -> item I_50maxWColumn row ] cropsData

  set T_heat map [row -> item T_heatColumn row ] cropsData

  set T_extreme map [row -> item T_extColumn row ] cropsData

  set S_CO2 map [row -> item S_CO2Column row ] cropsData

  set S_water map [row -> item S_waterColumn row ] cropsData

  set sugSowingDay map [row -> item sugSowingDayColumn row ] cropsData

  set sugHarvestingDay map [row -> item sugHarvestingDayColumn row ] cropsData

end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;; movie generation ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to generate-animation

  setup
  vid:start-recorder
  repeat end-simulation-in-tick [ go vid:record-view ]
  vid:save-recording  (word "run_" behaviorspace-run-number ".mov")
  vid:reset-recorder

end
@#$#@#$#@
GRAPHICS-WINDOW
293
22
605
335
-1
-1
16.0
1
10
1
1
1
0
1
1
1
-9
9
-9
9
0
0
1
ticks
30.0

BUTTON
37
26
92
59
NIL
setup
NIL
1
T
OBSERVER
NIL
1
NIL
NIL
1

BUTTON
212
25
267
58
NIL
go
T
1
T
OBSERVER
NIL
4
NIL
NIL
1

INPUTBOX
22
68
122
128
seed
0.0
1
0
Number

CHOOSER
58
134
196
179
type-of-experiment
type-of-experiment
"user-defined" "random"
0

PLOT
293
351
493
471
mean yield
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" "set-histogram-num-bars 20\ncarefully [ set-plot-x-range -0.01 (0.01 + ceiling max [mean yield] of patches) ] [ ]"
PENS
"default" 1.0 1 -16777216 true "" "carefully [ histogram [mean yield] of patches] [ ]"

MONITOR
45
236
118
281
NIL
sowingDay
0
1
11

MONITOR
1575
220
1757
257
NIL
annualMinTemperatureAtBaseLevel
2
1
9

BUTTON
94
26
149
59
NIL
go
NIL
1
T
OBSERVER
NIL
2
NIL
NIL
1

MONITOR
1575
186
1760
223
NIL
annualMaxTemperatureAtBaseLevel
2
1
9

INPUTBOX
124
68
237
128
end-simulation-in-tick
0.0
1
0
Number

MONITOR
119
236
217
281
NIL
HarvestingDay
0
1
11

SLIDER
1264
259
1543
292
daily-mean-temperature-fluctuation
daily-mean-temperature-fluctuation
0
20
2.5
0.1
1
NIL
HORIZONTAL

SLIDER
1264
294
1546
327
daily-temperature-lower-deviation
daily-temperature-lower-deviation
0
20
5.0
0.1
1
NIL
HORIZONTAL

SLIDER
1265
327
1549
360
daily-temperature-upper-deviation
daily-temperature-upper-deviation
0
20
5.0
0.1
1
NIL
HORIZONTAL

SLIDER
1259
187
1572
220
annual-max-temperature-at-base-level
annual-max-temperature-at-base-level
annual-min-temperature-at-base-level
40
35.0
0.1
1
ºC
HORIZONTAL

SLIDER
1261
224
1575
257
annual-min-temperature-at-base-level
annual-min-temperature-at-base-level
-10
annual-max-temperature-at-base-level
15.0
0.1
1
ºC
HORIZONTAL

MONITOR
1545
258
1697
295
NIL
dailyMeanTemperatureFluctuation
2
1
9

MONITOR
1541
294
1697
331
NIL
dailyTemperatureLowerDeviation
2
1
9

MONITOR
1543
330
1696
367
NIL
dailyTemperatureUpperDeviation
2
1
9

PLOT
639
184
1250
365
Temperature
days
ºC
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"mean" 1.0 0 -16777216 true "" "plot T"
"min" 1.0 0 -13345367 true "" "plot T_min"
"max" 1.0 0 -2674135 true "" "plot T_max"

MONITOR
38
189
117
234
NIL
currentYear
0
1
11

MONITOR
119
189
216
234
NIL
currentDayInYear
0
1
11

SLIDER
1271
401
1509
434
mean-CO2
mean-CO2
350
800
436.77
0.01
1
ppm
HORIZONTAL

SLIDER
1272
437
1510
470
annual-CO2-deviation
annual-CO2-deviation
0
5
5.0
0.01
1
ppm
HORIZONTAL

PLOT
640
368
1250
549
CO2
days
ppm
0.0
10.0
0.0
10.0
true
false
"set-plot-y-range (floor meanCO2 - annualCO2Deviation - dailyCO2Fluctuation - 2) (ceiling meanCO2 + annualCO2Deviation + dailyCO2Fluctuation + 2)" "set-plot-y-range (floor meanCO2 - annualCO2Deviation - dailyCO2Fluctuation - 2) (ceiling meanCO2 + annualCO2Deviation + dailyCO2Fluctuation + 2)"
PENS
"default" 1.0 0 -16777216 true "" "plot CO2"

SLIDER
1272
472
1510
505
daily-CO2-fluctuation
daily-CO2-fluctuation
0
5
5.0
0.01
1
ppm
HORIZONTAL

CHOOSER
22
291
185
336
display-mode
display-mode
"crops" "ARID" "biomass" "mean yield"
0

BUTTON
190
298
280
331
refresh view
refresh-view
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
151
25
211
58
+ year
repeat 365 [ go ]
NIL
1
T
OBSERVER
NIL
3
NIL
NIL
1

PLOT
639
28
1302
178
mean biomass of patches
days
g/m2
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"wheat" 1.0 0 -2674135 true "" "plot mean [biomass] of patches with [position crop typesOfCrops = 0]"
"rice" 1.0 0 -11221820 true "" "plot mean [biomass] of patches with [position crop typesOfCrops = 1]"

SLIDER
1259
609
1601
642
annual-max-solar-radiation
annual-max-solar-radiation
annual-min-solar-radiation
8
5.0
0.001
1
kWh/m2
HORIZONTAL

SLIDER
1259
570
1602
603
annual-min-solar-radiation
annual-min-solar-radiation
2
annual-max-solar-radiation
4.0
0.001
1
kWh/m2
HORIZONTAL

SLIDER
1260
647
1602
680
daily-mean-solar-radiation-fluctuation
daily-mean-solar-radiation-fluctuation
0
1
0.1
0.001
1
kWh/m2
HORIZONTAL

PLOT
641
552
1251
702
Solar radiation
days
KWh/m2
0.0
10.0
0.0
10.0
true
false
"set-plot-y-range (floor annualMinSolarRadiation - dailyMeanSolarRadiationFluctuation - 1) (ceiling annualMaxSolarRadiation + dailyMeanSolarRadiationFluctuation + 1)" "set-plot-y-range (floor annualMinSolarRadiation - dailyMeanSolarRadiationFluctuation - 1) (ceiling annualMaxSolarRadiation + dailyMeanSolarRadiationFluctuation + 1)"
PENS
"default" 1.0 0 -16777216 true "" "plot solarRadiation / 3.6"

MONITOR
1510
399
1573
436
NIL
meanCO2
2
1
9

MONITOR
1511
436
1612
473
NIL
annualCO2Deviation
2
1
9

MONITOR
1511
471
1607
508
NIL
dailyCO2Fluctuation
2
1
9

MONITOR
1605
568
1717
605
NIL
annualMinSolarRadiation
3
1
9

MONITOR
1603
606
1717
643
NIL
annualMaxSolarRadiation
3
1
9

MONITOR
1602
646
1760
683
NIL
dailyMeanSolarRadiationFluctuation
3
1
9

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.0.4
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
