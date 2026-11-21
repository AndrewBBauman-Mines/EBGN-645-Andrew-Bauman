* =========================================================================
* solve_scen.gms  -  solve one scenario with the current scalar values.
* Two solves: the first sets the terminal value with price-taker prices;
* the second rescales terminal prices by the model's own marginal-revenue
* ratio in the last reported year, so the end of the horizon is consistent
* with the demand slope.
* =========================================================================
mrf = 1;
$include calc.gms
solve bourbon_dyn using qcp maximizing NPV;

mrfden = sum((a,y)$yref(y), pInt(a,y)*Q(a)*SELL.l(a,y));
mrf$(mrfden > 0) = sum((a,y)$yref(y),
                      (pInt(a,y) - 2*pBase(a)*slope*SELL.l(a,y)/K)*Q(a)*SELL.l(a,y)) / mrfden;
$include calc.gms
solve bourbon_dyn using qcp maximizing NPV;
