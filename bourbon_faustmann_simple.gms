$title Simple Faustmann Model for Bourbon Aging

* -------------------------------------------------------------------------
* The rickhouse is fixed in size and already full. Each barrel position is
* the "land": when a barrel is sold at age T it is refilled right away, and
* the cycle repeats forever. Choose the aging age T that maximizes the
* value of one barrel position (Faustmann land expectation value, LEV):
*
*    LEV(T) = [ R(T) - C*(1+r)^T ] / [ (1+r)^T - 1 ]
*    R(T)   = p(T) * Q0 * (1-delta)^T
* -------------------------------------------------------------------------

Set t 'aging age at sale (years)' / 1*15 /;

Scalar
   Q0     'proof gallons at fill (PG per barrel)'           / 66.25 /
   delta  'angel share lost per year (fraction per yr)'     / 0.00  /
   C      'cost to fill a new barrel ($ per barrel)'        / 585   /
   r      'real discount rate (fraction per yr)'            / 0.001  /;

Parameter p(t) 'value of aged bourbon ($ per PG)'
   /  1 10.00,   2 11.50,   3 13.50,   4 16.50,   5 18.50
      6 20.25,   7 21.75,   8 23.00,   9 24.00,  10 24.75
     11 25.40,  12 26.00,  13 26.50,  14 27.00,  15 27.40 /;

Parameter
   age(t)  'aging age (yr)'
   Q(t)    'proof gallons left at age t (PG per barrel)'
   Rv(t)   'value of a barrel sold at age t ($ per barrel)'
   LEV(t)  'value of one barrel position on a t-year cycle ($ per position)';

age(t) = ord(t);
Q(t)   = Q0*(1 - delta)**age(t);
Rv(t)  = p(t)*Q(t);
LEV(t) = (Rv(t) - C*(1 + r)**age(t)) / ((1 + r)**age(t) - 1);

* --- Optimization: pick exactly one aging age -----------------------------
Binary Variable y(t) '1 if barrels are sold at age t';
Variable        z    'value of one barrel position ($ per position)';

Equation
   objective  'value of the chosen cycle'
   onlyone    'choose exactly one aging age';

objective..  z =e= sum(t, LEV(t)*y(t));
onlyone..    sum(t, y(t)) =e= 1;

Model bourbon / all /;
option optcr = 0;
solve bourbon using mip maximizing z;

* --- Results ---------------------------------------------------------------
Scalar Tstar 'optimal aging age (yr)';
Tstar = sum(t, age(t)*y.l(t));

display Q, Rv, LEV, Tstar, z.l;

* --- Print a results table to a text file --------------------------------
File res / 'results.txt' /;
put res;
put 'Faustmann Bourbon Model - Results' /;
put '---------------------------------------------------------------' /;
put 'Age (yr)':>10, 'Proof gal':>12, '$ per PG':>10, 'Barrel $':>12, 'LEV $':>12 /;
loop(t,
   put age(t):10:0, Q(t):12:2, p(t):10:2, Rv(t):12:2, LEV(t):12:2 /;
);
put '---------------------------------------------------------------' /;
put 'Optimal aging age (yr):           ', Tstar:6:0 /;
put 'Value of a barrel position ($):   ', z.l:10:2 /;
putclose res;

* --- Same table as a CSV for Excel -----------------------------------------
File csv / 'results.csv' /;
csv.pc = 5;
put csv;
put 'Age_yr', 'Proof_gal', 'Price_per_PG', 'Barrel_value', 'LEV' /;
loop(t,
   put age(t):0:0, Q(t):0:2, p(t):0:2, Rv(t):0:2, LEV(t):0:2 /;
);
putclose csv;
