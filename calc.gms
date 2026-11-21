* =========================================================================
* calc.gms  -  derived parameters. Assignments only, so it can be
* $include'd inside a scenario loop after the scalars are changed.
* =========================================================================

age(a)  = ord(a);
tt(y)   = ord(y) - 1;
disc(y) = 1/(1 + r)**tt(y);
discT   = 1/(1 + r)**card(y);

* proof gallons left in a barrel of age a
Q(a)  = Q0*(1 - delta)**age(a);

* base price curve with the aging premium tilted by "tilt" per extra year
pBase(a) = pM2(a)*(1 + tilt)**(age(a) - 1);

* demand shifter: decline of (g + gam*age) per year for Tdecl years, then flat
pInt(a,y) = pBase(a) * power(max(1e-6, 1 - g - gam*age(a)), min(tt(y), Tdecl));

I0(a) = I0share(a)*K;

* --- Faustmann benchmark at final-year (post-decline) prices ---------------
* Cycle: fill at time 0 (cost C), pay h for years 0..s-1, sell at time s.
* Prices are scaled by mrf, the ratio of marginal revenue to price that the
* model itself shows in the last reported year (see solve_scen.gms). With
* mrf = 1 this is the Milestone 2 price-taker Faustmann rule.
ann(s)  = sum(a$(age(a) <= age(s)), 1/(1 + r)**(age(a) - 1));
Rfin(s) = mrf*sum(y$(ord(y) = card(y)), pInt(s,y))*Q(s);
LEV(s)  = (-C - h*ann(s) + Rfin(s)/(1 + r)**age(s)) / (1 - 1/(1 + r)**age(s));
LEVstar = max(0, smax(s, LEV(s)));
Tfaust  = 0;
Tfaust$(LEVstar > 0) = smax(s$(LEV(s) = smax(s2, LEV(s2))), age(s));

* Value of a barrel of age a at the start of the year after the horizon:
* sell it at the best age s >= a, paying h until then, then refill the slot.
W(a) = smax(s$(age(s) >= age(a)),
            - h*sum(s2$(age(s2) <= age(s) - age(a)), 1/(1 + r)**(age(s2) - 1))
            + (Rfin(s) + LEVstar)/(1 + r)**(age(s) - age(a)));
