$title  A two by two general equilibrium model -- indexed GAMS/MPSGE 

Sets
    i   Produced goods          / x, y /,
    f   Factors of production   / L, K /;

table  sam(*,*)    Benchmark input-output matrix

                X       Y       U     RA
        X     100             -100
        Y              50      -50
        U                      150   -150
        K     -50     -30             80
        L     -50     -20             70;
        
parameters
    supply(i)   Benchmark supply of output of sectors,
    factor(f,i) Benchmark factor demand,
    demand(i)   Benchmark demand for consumption,
    endow(f)    Factor endowment,
    cons(f)        Benchmark total consumption /l 75, k 75/,
    pricePU(f)  Price of x and y /l 1, k 1/;

* Extract data from the original format into model-specific arrays

supply(i)   = sam(i,i);
factor(f,i) = -sam(f,i);
demand(i)   = -sam(i,'u');
endow(f)    = sam(f,'ra');
*cons(f)   = /l 75, k 75/;
*pricePC(i)  = ;

display supply, factor, demand, cons, endow;

$ontext
$MODEL:twobytwoIndDem

$SECTORS:
    Y(i)    ! Activity level --  benchmark=1
    U       ! Final consumption index -- benchmark=1

$COMMODITIES:
    PU(f)     ! Relative price of final consumption -- benchmkark=1
    PC(i)   ! Relative price of commodities -- benchmark=1
    PF(f)   ! Relative price of factors -- benchmark=1 

$CONSUMERS:
    RA      ! Income level (benchmark=150)

$PROD:Y(i) s:1
        O:PC(i)     Q:supply(i)  ! x 100, y 50
        I:PF(f)     Q:factor(f,i)! xl

$PROD:U s:1
        O:PU(f)     Q:cons(f)
        I:PC(i)     Q:demand(i)

$DEMAND:RA s:1
        D:PU(f)     Q:cons(f)  P:pricePU(f) !c:
        E:PF(f)     Q:endow(f)
        
$REPORT:
  V:DY(f,i)   I:PF(f)  PROD:Y(i)
  V:SY(i)     O:PC(i)  PROD:Y(i)
  V:DU(i)     I:PC(i)  PROD:U  
  V:SU(f)     O:PU(f)  PROD:U  
  V:DPFY(i,f) I:PF(f)  PROD:Y(i)
  V:FDRA(f)   D:PU(f)  DEMAND:RA
  v:CWI(f)    W:RA
  
$offtext
$sysinclude mpsgeset twobytwoIndDem

* Benchmark replication
twobytwoIndDem.iterlim = 0;
$include twobytwoIndDem.GEN
solve twobytwoIndDem using mcp;
abort$(abs(twobytwoIndDem.objval) gt 1e-7) "*** twobytwo_DemandindNest does not calibrate ! ***";
parameter   equilibrium Equilibrium values;

equilibrium("Y",i,"benchmark") = Y.L(i);
equilibrium("U","_","benchmark") = U.L;
equilibrium("PC",i,"benchmark") = PC.L(i);
equilibrium("PF",f,"benchmark") = PF.L(f);
equilibrium("PU",f,"benchmark") = PU.L(f);
equilibrium("DU",i,"benchmark") = DU.L(i)/U.L;
equilibrium("SU",f,"benchmark") = SU.L(f);
equilibrium(i,f,"benchmark")=DPFY.L(i,f)/Y.L(i);
equilibrium("SY",i,"benchmark") = SY.L(i)/Y.L(i);
equilibrium("RA","_","benchmark") = RA.L;
equilibrium("FDRA",f,"benchmark") = FDRA.L(f);

twobytwoIndDem.iterlim = 1000;

* Counterfactual : 10% increase in labor endowment

endow('l') = 1.1*endow('l');
RA.FX = 157;

*   Solve the model with the default normalization of prices which 
*   fixes the income level of the representative agent.  The RA
*   income level at the initial prices equals 80 + 1.1*70 = 157.

$include twobytwoIndDem.GEN
solve twobytwoIndDem using mcp;

*   Save counterfactual values:

equilibrium("Y",i,"RA=157") = Y.L(i);
equilibrium("U","_","RA=157") = U.L;
equilibrium("PC",i,"RA=157") = PC.L(i);
equilibrium("PF",f,"RA=157") = PF.L(f);
equilibrium("PU",f,"RA=157") = PU.L(f);
equilibrium("RA","_","RA=157") = RA.L;
equilibrium("DU",i,"RA=157") = DU.L(i)/U.L;
equilibrium("SU",f,"RA=157") = SU.L(f)/U.L;
equilibrium(i,f,"RA=157")=DPFY.L(i,f)/Y.L(i);
equilibrium("SY",i,"RA=157") = SY.L(i)/Y.L(i);
equilibrium("RA","_","RA=157") = RA.L;
equilibrium("FDRA",f,"RA=157") = FDRA.L(f);

*   Fix a numeraire price index and recalculate:
RA.LO = 0.000001; RA.UP = INF;
PU.FX("k") = 1;
$include twobytwoIndDem.GEN
solve twobytwoIndDem using mcp;

equilibrium("Y",i,'PC.x=1') = Y.L(i);
equilibrium("U","_",'PC.x=1') = U.L;
equilibrium("PC",i,'PC.x=1') = PC.L(i);
equilibrium("PF",f,'PC.x=1') = PF.L(f);
equilibrium("PU",f,'PC.x=1') = PU.L(f);
equilibrium("DU",i,'PC.x=1') = DU.L(i)/U.L;
equilibrium("SU",f,'PC.x=1') = SU.L(f)/U.L;
equilibrium(i,f,'PC.x=1')=DPFY.L(i,f)/Y.L(i);
equilibrium("SY",i,'PC.x=1') = SY.L(i)/Y.L(i);
equilibrium("RA","_",'PC.x=1') = RA.L;
equilibrium("SU",f,'PC.x=1') = SU.L(f)/U.L;
equilibrium("FDRA",f,'PC.x=1') = FDRA.L(f);

*   Recalculate with a different numeraire.
*   "Unfix" the price of X and fix the wage rate:

pricePU("l") =1.5
$include twobytwoIndDem.GEN
solve twobytwoIndDem using mcp;

equilibrium("Y",i,'Pr.l=1.5') = Y.L(i);
equilibrium("U","_",'Pr.l=1.5') = U.L;
equilibrium("PC",i,'Pr.l=1.5') = PC.L(i);
equilibrium("PF",f,'Pr.l=1.5') = PF.L(f);
equilibrium("PU",f,'Pr.l=1.5') = PU.L(f);
equilibrium("DU",i,'Pr.l=1.5') = DU.L(i)/U.L;
equilibrium("SU",f,'Pr.l=1.5') = SU.L(f)/U.L;
equilibrium(i,f,'Pr.l=1.5')=DPFY.L(i,f)/Y.L(i);
equilibrium("SY",i,'Pr.l=1.5') = SY.L(i)/Y.L(i);
equilibrium("RA","_",'Pr.l=1.5') = RA.L;
equilibrium("FDRA",f,'Pr.l=1.5') = FDRA.L(f);

PC.UP("X") = +inf;  PC.LO("X") = 1e-5;  PF.FX("L") = 1;
$include twobytwoIndDem.GEN
solve twobytwoIndDem using mcp;

equilibrium("Y",i,'PF.l=1') = Y.L(i);
equilibrium("U","_",'PF.l=1') = U.L;
equilibrium("PC",i,'PF.l=1') = PC.L(i);
equilibrium("PF",f,'PF.l=1') = PF.L(f);
equilibrium("PU",f,'PF.l=1') = PU.L(f);
equilibrium("DU",i,'PF.l=1') = DU.L(i)/U.L;
equilibrium("SU",f,'PF.l=1') = SU.L(f)/U.L;
equilibrium(i,f,'PF.l=1')=DPFY.L(i,f)/Y.L(i);
equilibrium("SY",i,'PF.l=1') = SY.L(i)/Y.L(i);
equilibrium("RA","_",'PF.l=1') = RA.L;
equilibrium("FDRA",f,'PF.l=1') = FDRA.L(f);

option decimals = 7;
display equilibrium;

execute_unload "TowbyTwo_Indexed_wDemand-non-1price_nest.gdx" equilibrium

*=== Write to variable levels to Excel file from GDX 
*=== If we do not specify a sheet, data is placed in first sheet
execute 'gdxxrw.exe TowbyTwo_Indexed_wDemand-non-1price_nest.gdx o=MPSGEresults.xlsx par=equilibrium rng=TwoxTwo_DemandIndPrice_Nest!'
execute 'gdxxrw.exe TowbyTwo_Indexed_wDemand-non-1price_nest.gdx o=C:\Users\Eli\.julia\dev\MPSGE\test\MPSGEresults.xlsx par=equilibrium rng=TwoxTwo_DemandIndPrice_Nest!'