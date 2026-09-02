$title simple

scalar p "Price" /20/;
scalar k "Capacity" /5/;

positive variable x "--units-- level of production";
variable Z "--$s-- profit, target of our optimization";

equations eq_objfn " our objective function",
        eq_capacitylimit "k >= x"
;

eq_objfn.. Z =e= p * x - x * x ;
eq_capacitylimit.. k =g= x ;

model simple /all/ ;
parameter rep;

solve simple using qcp maximizing Z ;
rep("k=5","profit") = z.l ;
rep("k=5","x") = x.l ;
rep("k=5","lamba") = eq_capacitylimit.m ;


execute_unload 'alldata.gdx' ;