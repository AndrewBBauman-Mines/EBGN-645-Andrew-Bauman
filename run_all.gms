$title Bourbon aging and refill model - baseline, experiments, sensitivity
* =========================================================================
* run_all.gms  -  reproduces every table and figure input for Milestone 3.
*
*   gams run_all                    full model, horizon to 2065
*   gams run_all --lastyr=2055      shorter horizon (fits the GAMS demo license)
*
* Writes to results/:
*   summary.csv     one row per case x sensitivity (Tables 2 and 3)
*   paths.csv       yearly fills, utilization, sale age, capacity shadow price
*   inventory.csv   barrels on hand and sold by age and year (Figure 1)
*   grid.csv        tilt x demand-decline grid with refill regimes (Figure 3)
*   checks.csv      model checks (Section 5)
* =========================================================================

$include model.gms

$if not dexist results $call mkdir results

* -------------------------------------------------------------------------
* Cases and sensitivities
* -------------------------------------------------------------------------
Set
   cs    'demand case'
         / base      'flat demand'
           decl_old  'EXPERIMENT: demand for older bourbon falls (gam = 0.001)'
           decl_all  'demand for all ages falls (g = 0.005)' /
   sens  'one-at-a-time sensitivity'
         / none      'calibrated values'
           r04       'r = 0.04'
           r12       'r = 0.12'
           d03       'delta = 0.03'
           d05       'delta = 0.05'
           c450      'C = 450'
           c700      'C = 700'
           h0        'h = 0'
           h25       'h = 25'
           b0        'slope = 0 (price taker)'
           b10       'slope = 0.10'
           b50       'slope = 0.50'
           tm02      'tilt = -0.02 (smaller aging premium)'
           tp02      'tilt = +0.02 (larger aging premium)' /
   item  'summary items'
         / npv_musd     'NPV of the warehouse (million 2026 $)'
           age26        'gallon-weighted average sale age, 2026 (yr)'
           age45        'gallon-weighted average sale age, 2045 (yr)'
           sold_old     'barrels aged 7+ sold 2026-2028'
           fills        'barrels filled 2026-2045'
           fills45      'barrels filled in 2045'
           util45       'warehouse utilization in 2045 (share of K)'
           empty45      'empty positions in 2045'
           yr_nofill    'number of years 2026-2045 with fills below 1% of K/4'
           cap30        'shadow price of a position in 2030 ($ per position, current $)'
           cap45        'shadow price of a position in 2045 ($ per position, current $)'
           levstar      'Faustmann value of an empty position after the horizon ($)'
           tfaust       'Faustmann optimal age at final prices (yr; 0 = do not refill)'
           mrf          'marginal revenue / price used for the terminal value'
           mstat        'solver model status (1 = optimal)' /
   pitem 'yearly path items'
         / fill         'barrels filled'
           sold         'barrels sold'
           util         'warehouse utilization (share of K)'
           saleage      'gallon-weighted average sale age (yr)'
           capshadow    'shadow price of a position ($, current)'
           revenue      'sales revenue (million $, current)' /;

Parameters
   summary(sens,cs,item)       'summary results'
   paths(sens,cs,y,pitem)      'yearly results'
   invrep(cs,y,a,*)            'inventory, sales and price by age (calibrated values only)';

* -------------------------------------------------------------------------
* Report macro: fill the result parameters from the current solution
* -------------------------------------------------------------------------
* average sale age is reported only when at least 1 barrel is sold
$macro SALEAGE(yy) ((sum(a, age(a)*Q(a)*SELL.l(a,yy)) / max(1e-9, sum(a, Q(a)*SELL.l(a,yy))))$(sum(a, SELL.l(a,yy)) >= 1))

loop((sens,cs),
*  reset every scalar to its calibrated value
   r = r_def;  delta = delta_def;  h = h_def;  tilt = tilt_def;  C = C_def;
   g = g_def;  gam = gam_def;      slope = slope_def;

*  demand case
   if(sameas(cs,'decl_old'), gam = 0.001);
   if(sameas(cs,'decl_all'), g   = 0.005);

*  sensitivity override
   if(sameas(sens,'r04'),  r     = 0.04);
   if(sameas(sens,'r12'),  r     = 0.12);
   if(sameas(sens,'d03'),  delta = 0.03);
   if(sameas(sens,'d05'),  delta = 0.05);
   if(sameas(sens,'c450'), C     = 450 );
   if(sameas(sens,'c700'), C     = 700 );
   if(sameas(sens,'h0'),   h     = 0   );
   if(sameas(sens,'h25'),  h     = 25  );
   if(sameas(sens,'b0'),   slope = 0   );
   if(sameas(sens,'b10'),  slope = 0.10);
   if(sameas(sens,'b50'),  slope = 0.50);
   if(sameas(sens,'tm02'), tilt  = -0.02);
   if(sameas(sens,'tp02'), tilt  =  0.02);

$  include solve_scen.gms

   summary(sens,cs,'mstat')    = bourbon_dyn.modelstat;
   summary(sens,cs,'npv_musd') = NPV.l/1e6;
   summary(sens,cs,'age26')    = sum(y$(ord(y) = 1), SALEAGE(y));
   summary(sens,cs,'age45')    = sum(yref, SALEAGE(yref));
   summary(sens,cs,'sold_old') = sum((a,y)$(age(a) >= 7 and ord(y) <= 3), SELL.l(a,y));
   summary(sens,cs,'fills')    = sum(yrep, FILL.l(yrep));
   summary(sens,cs,'fills45')  = sum(yref, FILL.l(yref));
   summary(sens,cs,'util45')   = sum(yref, sum(a, INV.l(a,yref) - SELL.l(a,yref)) + FILL.l(yref))/K;
   summary(sens,cs,'empty45')  = K*(1 - summary(sens,cs,'util45'));
   summary(sens,cs,'yr_nofill')= sum(yrep$(FILL.l(yrep) < 0.01*K/4), 1);
   summary(sens,cs,'cap30')    = sum(y$sameas(y,'2030'), eq_cap.m(y)/disc(y));
   summary(sens,cs,'cap45')    = sum(yref, eq_cap.m(yref)/disc(yref));
   summary(sens,cs,'levstar')  = LEVstar;
   summary(sens,cs,'tfaust')   = Tfaust;
   summary(sens,cs,'mrf')      = mrf;

   paths(sens,cs,yrep,'fill')      = FILL.l(yrep);
   paths(sens,cs,yrep,'sold')      = sum(a, SELL.l(a,yrep));
   paths(sens,cs,yrep,'util')      = (sum(a, INV.l(a,yrep) - SELL.l(a,yrep)) + FILL.l(yrep))/K;
   paths(sens,cs,yrep,'saleage') = SALEAGE(yrep);
   paths(sens,cs,yrep,'capshadow') = eq_cap.m(yrep)/disc(yrep);
   paths(sens,cs,yrep,'revenue')   = sum(a, (pInt(a,yrep) - pBase(a)*slope*SELL.l(a,yrep)/K)
                                            *Q(a)*SELL.l(a,yrep))/1e6;

   if(sameas(sens,'none'),
      invrep(cs,yrep,a,'onhand') = INV.l(a,yrep);
      invrep(cs,yrep,a,'sold')   = SELL.l(a,yrep);
      invrep(cs,yrep,a,'price')  = pInt(a,yrep) - pBase(a)*slope*SELL.l(a,yrep)/K;
   );
);

* -------------------------------------------------------------------------
* Comparative statics grid: aging premium (tilt) x demand decline (g)
* Refill regime from average utilization once the decline is over
* (2038-2045): full >= 0.98, stop <= 0.02, partial in between.
* -------------------------------------------------------------------------
Set
   ti 'tilt values'  / t1*t7 /
   gi 'g values'     / g1*g8 /
   yss(y) 'post-decline years used to classify the regime' / 2038*2045 /;
Parameters
   tiltv(ti) / t1 -0.02, t2 -0.01, t3 0, t4 0.01, t5 0.02, t6 0.03, t7 0.04 /
   gv(gi)    / g1 0, g2 0.0025, g3 0.005, g4 0.0075, g5 0.01, g6 0.015, g7 0.02, g8 0.03 /
   grid(ti,gi,*) 'grid results';

loop((ti,gi),
   r = r_def;  delta = delta_def;  h = h_def;  slope = slope_def;  C = C_def;
   gam = 0;  tilt = tiltv(ti);  g = gv(gi);

$  include solve_scen.gms

   grid(ti,gi,'tilt')     = tiltv(ti);
   grid(ti,gi,'g')        = gv(gi);
   grid(ti,gi,'util_ss')  = sum(yss, sum(a, INV.l(a,yss) - SELL.l(a,yss)) + FILL.l(yss))/(K*card(yss));
   grid(ti,gi,'fills_ss') = sum(yss, FILL.l(yss))/card(yss);
   grid(ti,gi,'age_ss')   = (sum(yss, sum(a, age(a)*Q(a)*SELL.l(a,yss)))
                            / max(1e-9, sum(yss, sum(a, Q(a)*SELL.l(a,yss)))))
                            $(sum((a,yss), SELL.l(a,yss)) >= card(yss));
   grid(ti,gi,'regime')   = 2;
   grid(ti,gi,'regime')$(grid(ti,gi,'util_ss') >= 0.98) = 1;
   grid(ti,gi,'regime')$(grid(ti,gi,'util_ss') <= 0.02) = 3;
   grid(ti,gi,'tfaust')   = Tfaust;
   grid(ti,gi,'npv_musd') = NPV.l/1e6;
   grid(ti,gi,'mstat')    = bourbon_dyn.modelstat;
);

* -------------------------------------------------------------------------
* Model checks (Section 5)
*  c1  Faustmann check: price taker, h = 0, flat demand -> steady-state
*      sale age should equal the Milestone 2 answer (4 years)
*  c2  largest capacity violation across all years
*  c3  smallest price paid for any barrel sold
*  c4  barrel accounting: starting stock + fills = sales + stock left
* -------------------------------------------------------------------------
Parameter checks(*) 'model checks';

r = r_def;  delta = delta_def;  C = C_def;  h = 0;  tilt = 0;  g = 0;  gam = 0;  slope = 0;
$include solve_scen.gms
checks('c1_faustmann_age_2045') = sum(yref, SALEAGE(yref));
checks('c1_tfaust')             = Tfaust;
checks('c1_mstat')              = bourbon_dyn.modelstat;

r = r_def;  delta = delta_def;  C = C_def;  h = h_def;  tilt = tilt_def;  g = g_def;  gam = gam_def;  slope = slope_def;
$include solve_scen.gms
checks('c2_max_cap_violation')  = smax(y, sum(a, INV.l(a,y) - SELL.l(a,y)) + FILL.l(y) - K);
checks('c3_min_price_sold')     = smin((a,y)$(SELL.l(a,y) > 1e-6), pInt(a,y) - pBase(a)*slope*SELL.l(a,y)/K);
checks('c4_balance_gap')        = sum(a, I0(a)) + sum(y$(ord(y) < card(y)), FILL.l(y))
                                - sum((a,y), SELL.l(a,y))
                                - sum(y$(ord(y) = card(y)), sum(a, INV.l(a,y) - SELL.l(a,y)));

display summary, grid, checks;

* -------------------------------------------------------------------------
* Write CSV files
* -------------------------------------------------------------------------
File fsum / 'results/summary.csv' /;  fsum.pc = 5;  fsum.nd = 4;
put fsum 'sens', 'case';
loop(item, put item.tl);
put /;
loop((sens,cs),
   put sens.tl, cs.tl;
   loop(item, put summary(sens,cs,item));
   put /;
);
putclose fsum;

File fpath / 'results/paths.csv' /;  fpath.pc = 5;  fpath.nd = 4;
put fpath 'sens', 'case', 'year';
loop(pitem, put pitem.tl);
put /;
loop((sens,cs,yrep),
   put sens.tl, cs.tl, yrep.tl;
   loop(pitem, put paths(sens,cs,yrep,pitem));
   put /;
);
putclose fpath;

File finv / 'results/inventory.csv' /;  finv.pc = 5;  finv.nd = 4;
put finv 'case', 'year', 'age', 'onhand', 'sold', 'price_per_pg' /;
loop((cs,yrep,a),
   put cs.tl, yrep.tl, a.tl, invrep(cs,yrep,a,'onhand'), invrep(cs,yrep,a,'sold'),
       invrep(cs,yrep,a,'price') /;
);
putclose finv;

File fgrid / 'results/grid.csv' /;  fgrid.pc = 5;  fgrid.nd = 4;
put fgrid 'tilt', 'g', 'util_ss', 'fills_ss', 'age_ss', 'regime', 'tfaust', 'npv_musd', 'mstat' /;
loop((ti,gi),
   put grid(ti,gi,'tilt'), grid(ti,gi,'g'), grid(ti,gi,'util_ss'), grid(ti,gi,'fills_ss'),
       grid(ti,gi,'age_ss'), grid(ti,gi,'regime'), grid(ti,gi,'tfaust'),
       grid(ti,gi,'npv_musd'), grid(ti,gi,'mstat') /;
);
putclose fgrid;

File fchk / 'results/checks.csv' /;  fchk.pc = 5;  fchk.nd = 6;
put fchk 'check', 'value' /;
put 'c1_faustmann_age_2045', checks('c1_faustmann_age_2045') /;
put 'c1_tfaust',             checks('c1_tfaust') /;
put 'c1_mstat',              checks('c1_mstat') /;
put 'c2_max_cap_violation',  checks('c2_max_cap_violation') /;
put 'c3_min_price_sold',     checks('c3_min_price_sold') /;
put 'c4_balance_gap',        checks('c4_balance_gap') /;
putclose fchk;
