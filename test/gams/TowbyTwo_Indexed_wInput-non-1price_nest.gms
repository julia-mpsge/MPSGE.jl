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
    cons        Benchmark total consumption,
    pricePC(i)  Price of x and y /x 1, y 1/;

* Extract data from the original format into model-specific arrays

supply(i)   = sam(i,i);
factor(f,i) = -sam(f,i);
demand(i)   = -sam(i,'u');
cons        = sum(i, demand(i));
endow(f)    = sam(f,'ra');

display supply, factor, demand, cons, endow;

$ontext
$MODEL:twobytwo

$SECTORS:
    Y(i)    ! Activity level --  benchmark=1
    U       ! Final consumption index -- benchmark=1

$COMMODITIES:
    PU     ! Relative price of final consumption -- benchmkark=1
    PC(i)   ! Relative price of commodities -- benchmark=1
    PF(f)   ! Relative price of factors -- benchmark=1 

$CONSUMERS:
    RA      ! Income level (benchmark=150)

$PROD:Y(i) s:1
        O:PC(i)     Q:supply(i)
        I:PF(f)     Q:factor(f,i)

$PROD:U s:1 c:1
        O:PU     Q:cons
        I:PC(i)  Q:demand(i) P:pricePC(i) c:

$DEMAND:RA
        D:PU     Q:cons 
        E:PF(f)     Q:endow(f)
        
$REPORT:
  V:DY(f,i)   I:PF(f)  PROD:Y(i)
  V:SY(i)     O:PC(i)  PROD:Y(i)
  V:DU(i)     I:PC(i)  PROD:U  
  V:SU        O:PU     PROD:U  
  V:DPFY(i,f) I:PF(f)  PROD:Y(i)
  V:FDRA      D:PU     DEMAND:RA

$offtext
$sysinclude mpsgeset twobytwo

* Benchmark replication

twobytwo.iterlim = 0;
$include TWOBYTWO.GEN
solve twobytwo using mcp;
abort$(abs(twobytwo.objval) gt 1e-7) "*** twobytwo_wTax_indexedRA does not calibrate ! ***";

parameter   equilibrium Equilibrium values;

equilibrium("Y.L",i,"benchmark") = Y.L(i);
equilibrium("U.L","_","benchmark") = U.L;
equilibrium("PC.L",i,"benchmark") = PC.L(i);
equilibrium("PF.L",f,"benchmark") = PF.L(f);
equilibrium("PU.L","_","benchmark") = PU.L;
equilibrium("DU.L",i,"benchmark") = DU.L(i)/U.L;
equilibrium("SU.L","_","benchmark") = SU.L/U.L;
equilibrium(i,f,"benchmark")=DPFY.L(i,f)/Y.L(i);
equilibrium("SY.L(i)",i,"benchmark") = SY.L(i)/Y.L(i);
equilibrium("RA.L","_","benchmark") = RA.L;
equilibrium("FDRA.L","_","benchmark") = FDRA.L;

twobytwo.iterlim = 1000;

* Counterfactual : 10% increase in labor endowment

endow('l') = 1.1*endow('l');
RA.FX = 157;

*   Solve the model with the default normalization of prices which 
*   fixes the income level of the representative agent.  The RA
*   income level at the initial prices equals 80 + 1.1*70 = 157.

$include TWOBYTWO.GEN
solve twobytwo using mcp;

*   Save counterfactual values:

equilibrium("Y.L",i,"RA=157") = Y.L(i);
equilibrium("U.L","_","RA=157") = U.L;
equilibrium("PC.L",i,"RA=157") = PC.L(i);
equilibrium("PF.L",f,"RA=157") = PF.L(f);
equilibrium("PU.L","_","RA=157") = PU.L;
equilibrium("RA.L","_","RA=157") = RA.L;
equilibrium("DU.L",i,"RA=157") = DU.L(i)/U.L;
equilibrium("SU.L","_","RA=157") = SU.L/U.L;
equilibrium(i,f,"RA=157")=DPFY.L(i,f)/Y.L(i);
equilibrium("SY.L(i)",i,"RA=157") = SY.L(i)/Y.L(i);
equilibrium("RA.L","_","RA=157") = RA.L;
equilibrium("FDRA.L","_","RA=157") = FDRA.L;

*   Fix a numeraire price index and recalculate:
RA.LO = 0.000001; RA.UP = INF;
PC.FX("x") = 1;
$include TWOBYTWO.GEN
solve twobytwo using mcp;

equilibrium("Y.L",i,'PC.x=1') = Y.L(i);
equilibrium("U.L","_",'PC.x=1') = U.L;
equilibrium("PC.L",i,'PC.x=1') = PC.L(i);
equilibrium("PF.L",f,'PC.x=1') = PF.L(f);
equilibrium("PU.L","_",'PC.x=1') = PU.L;
equilibrium("DU.L",i,'PC.x=1') = DU.L(i)/U.L;
equilibrium("SU.L","_",'PC.x=1') = SU.L/U.L;
equilibrium(i,f,'PC.x=1')=DPFY.L(i,f)/Y.L(i);
equilibrium("SY.L(i)",i,'PC.x=1') = SY.L(i)/Y.L(i);
equilibrium("RA.L","_",'PC.x=1') = RA.L;
equilibrium("FDRA.L","_",'PC.x=1') = FDRA.L;

*   Recalculate with a different numeraire.
*   "Unfix" the price of X and fix the wage rate:

PC.UP("X") = +inf;  PC.LO("X") = 1e-5;  PF.FX("L") = 1;
$include TWOBYTWO.GEN
solve twobytwo using mcp;

equilibrium("Y.L",i,'PF.l=1') = Y.L(i);
equilibrium("U.L","_",'PF.l=1') = U.L;
equilibrium("PC.L",i,'PF.l=1') = PC.L(i);
equilibrium("PF.L",f,'PF.l=1') = PF.L(f);
equilibrium("PU.L","_",'PF.l=1') = PU.L;
equilibrium("DU.L",i,'PF.l=1') = DU.L(i)/U.L;
equilibrium("SU.L","_",'PF.l=1') = SU.L/U.L;
equilibrium(i,f,'PF.l=1')=DPFY.L(i,f)/Y.L(i);
equilibrium("SY.L(i)",i,'PF.l=1') = SY.L(i)/Y.L(i);
equilibrium("RA.L","_",'PF.l=1') = RA.L;
equilibrium("FDRA.L","_",'PF.l=1') = FDRA.L;

pricePC("x") =2
$include TWOBYTWO.GEN
solve twobytwo using mcp;

equilibrium("Y.L",i,'Pr.x=2') = Y.L(i);
equilibrium("U.L","_",'Pr.x=2') = U.L;
equilibrium("PC.L",i,'Pr.x=2') = PC.L(i);
equilibrium("PF.L",f,'Pr.x=2') = PF.L(f);
equilibrium("PU.L","_",'Pr.x=2') = PU.L;
equilibrium("DU.L",i,'Pr.x=2') = DU.L(i)/U.L;
equilibrium("SU.L","_",'Pr.x=2') = SU.L/U.L;
equilibrium(i,f,'Pr.x=2')=DPFY.L(i,f)/Y.L(i);
equilibrium("SY.L(i)",i,'Pr.x=2') = SY.L(i)/Y.L(i);
equilibrium("RA.L","_",'Pr.x=2') = RA.L;
equilibrium("FDRA.L","_",'Pr.x=2') = FDRA.L;

option decimals = 7;
display equilibrium;

execute_unload "TowbyTwo_Indexed_wInput-non-1price_nest.gdx" equilibrium

*=== Write to variable levels to Excel file from GDX 
*=== If we do not specify a sheet, data is placed in first sheet
execute 'gdxxrw.exe TowbyTwo_Indexed_wInput-non-1price_nest.gdx o=MPSGEresults.xlsx par=equilibrium rng=TwoxTwowOTax_IndPrice_Nest!'
execute 'gdxxrw.exe TowbyTwo_Indexed_wInput-non-1price_nest.gdx o=C:\Users\Eli\.julia\dev\MPSGE\test\MPSGEresults.xlsx par=equilibrium rng=TwoxTwowOTax_IndPrice_Nest!'
