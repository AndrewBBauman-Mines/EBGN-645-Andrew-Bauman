* =========================================================================
* model.gms  -  dynamic (vintage) bourbon aging model
*
* Extends the Milestone 2 Faustmann model: the warehouse holds barrels of
* every age at once, each age has its own downward-sloping demand, and the
* distiller decides every year how many barrels to sell at each age and
* how many new barrels to fill (zero is allowed: sell down and stop).
*
* Timing within year y:
*   1. barrels of age a are on hand: INV(a,y)
*   2. sell SELL(a,y) of them (at the start of the year)
*   3. fill FILL(y) new barrels into the freed positions
*   4. the barrels left age one year: INV(a+1,y+1) = INV(a,y) - SELL(a,y),
*      and new barrels become age 1: INV(1,y+1) = FILL(y)
* =========================================================================

$include params.gms

Parameters
   age(a)    'age (yr)'
   tt(y)     'years since 2026'
   disc(y)   'discount factor to 2026'
   Q(a)      'proof gallons left at age a (PG per barrel)'
   pBase(a)     'base price intercept by age ($ per PG)'
   pInt(a,y)    'price intercept by age and year ($ per PG)'
   I0(a)     'starting inventory (barrels)'
   ann(s)    'PV of 1 $ paid at start of each of s years'
   Rfin(s)   'final-year value of a barrel sold at age s, price taker ($ per barrel)'
   LEV(s)    'Faustmann value of a position on an s-year cycle at final prices ($ per position)'
   W(a)      'terminal value of a barrel of age a, incl. refilling its position ($ per barrel)';
Scalars
   discT     'discount factor for the start of the year after the horizon'
   mrf       'marginal revenue / price in the last reported year, used for terminal prices'
   mrfden    'helper for mrf'
   LEVstar   'value of an empty position after the horizon ($ per position)'
   Tfaust    'Faustmann optimal age at final prices (yr; 0 = do not refill)';

mrf = 1;
$include calc.gms

Positive Variables
   INV(a,y)   'barrels of age a on hand at start of year y (barrels)'
   SELL(a,y)   'barrels of age a sold in year y (barrels)'
   FILL(y)     'new barrels filled in year y (barrels)';
Variable
   NPV      'present value of the distillery warehouse, 2026 $';

* starting inventory is given
INV.fx(a,y)$(ord(y) = 1) = I0(a);

Equations
   eq_obj          'present value of profits plus terminal value'
   eq_new(y)       'new fills become age-1 barrels next year'
   eq_aging(a,y)   'unsold barrels age one year'
   eq_sell(a,y)    'cannot sell more barrels than are on hand (final year; earlier years are implied by eq_aging and INV >= 0)'
   eq_oldest(a,y)  'barrels reaching the maximum age tracked must be sold'
   eq_cap(y)       'warehouse capacity (barrel positions)';

eq_obj..
   NPV =e= sum(y, disc(y)*(
              sum(a, (pInt(a,y) - pBase(a)*slope*SELL(a,y)/K)*Q(a)*SELL(a,y))
            - C*FILL(y)
            - h*(sum(a, INV(a,y) - SELL(a,y)) + FILL(y)) ))
         + discT*( sum((a,y)$(ord(y) = card(y) and ord(a) < card(a)),
                       (INV(a,y) - SELL(a,y))*(W(a+1) - LEVstar))
                 + sum(y$(ord(y) = card(y)), FILL(y)*(W('1') - LEVstar))
                 + K*LEVstar );

eq_new(y)$(ord(y) > 1)..                 INV('1',y) =e= FILL(y-1);
eq_aging(a,y)$(ord(a) > 1 and ord(y) > 1).. INV(a,y)   =e= INV(a-1,y-1) - SELL(a-1,y-1);
eq_sell(a,y)$(ord(y) = card(y)).. SELL(a,y)       =l= INV(a,y);
eq_oldest(a,y)$(ord(a) = card(a)).. SELL(a,y) =e= INV(a,y);
eq_cap(y)..                sum(a, INV(a,y) - SELL(a,y)) + FILL(y) =l= K;

Model bourbon_dyn / all /;
option qcp = cplex, limrow = 0, limcol = 0, solprint = off;
