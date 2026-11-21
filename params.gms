* =========================================================================
* params.gms  -  calibration inputs for the dynamic bourbon aging model
* Values marked (M2) carry over from Milestone 2. Values marked (ASSUMED)
* are illustrative placeholders: replace them as calibration improves.
* =========================================================================

* Last model year. Override on the command line, e.g.  gams run_all --lastyr=2050
$if not set lastyr $set lastyr 2065
* Oldest age tracked. Barrels never stay past age 6 in any run, so
* --maxage=10 gives the same answer and keeps the 2065 model inside the
* GAMS demo license (1,000 rows/columns for nonlinear models).
$if not set maxage $set maxage 15

Set
   y  'calendar year (start of year)'           / 2026*%lastyr% /
   aall 'all ages with price and inventory data (yr)' / 1*15 /
   a(aall) 'barrel age at start of year, ages tracked (yr)' / 1*%maxage% /;

* Years shown in the paper. The extra 20 years after 2045 keep end-of-
* horizon effects out of the reported window.
Set yrep(y) 'years reported' / 2026*2045 /
    yref(y) 'last reported year, used to set the terminal value' / 2045 /;

Alias (a, s, s2);

Scalars
   Q0     'proof gallons at fill (PG per barrel)                     (M2)'      / 66.25 /
   delta  'angel share lost per year (fraction per yr)               (M2)'      / 0.04  /
   C      'cost to fill a new barrel ($ per barrel)                  (M2)'      / 585   /
   r      'real discount rate (fraction per yr)                      (M2)'      / 0.08  /
   h      'holding cost: tax, insurance, storage ($ per barrel-yr)   (ASSUMED)' / 10    /
   K      'warehouse capacity (barrel positions)                     (ASSUMED)' / 20000 /
   tilt   'change in aging premium per extra year (fraction per yr); 0 = M2 curve' / 0 /
   g      'demand decline, all ages (fraction per yr)'                          / 0     /
   gam    'extra demand decline per year of age (fraction per yr per yr)'       / 0     /
   Tdecl  'number of years the decline lasts (yr)                    (ASSUMED)' / 10    /
   slope  'price drop, as a share of base price, if K barrels of one age are sold in one year; 0 = price taker (ASSUMED)' / 0.25 /;

* Base price curve by age ($ per PG), Milestone 2
Parameter pM2(aall) 'base value of bourbon aged a years ($ per PG)   (M2)'
   /  1 10.00,   2 11.50,   3 13.50,   4 16.50,   5 18.50
      6 20.25,   7 21.75,   8 23.00,   9 24.00,  10 24.75
     11 25.40,  12 26.00,  13 26.50,  14 27.00,  15 27.40 /;

* Starting inventory: full warehouse, weighted toward the young barrels
* filled during the COVID-era boom (shares of K, sum to 1)   (ASSUMED)
Parameter I0share(aall) 'share of warehouse holding barrels of age a in 2026'
   /  1 0.08,  2 0.10,  3 0.14,  4 0.16,  5 0.16
      6 0.12,  7 0.09,  8 0.07,  9 0.05, 10 0.03 /;

* Default values, so each scenario starts from the same baseline
Scalars r_def, delta_def, C_def, h_def, tilt_def, g_def, gam_def, slope_def;
r_def = r;  C_def = C;  delta_def = delta;  h_def = h;  tilt_def = tilt;
g_def = g;  gam_def = gam;      slope_def = slope;
