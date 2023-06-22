$title  A two by two general equilibrium model -- scalar GAMS/MPSGE 
* This matches the 2x2_Scalar_Alg-MPSGE with x->s:1 and y->s:1,

parameter   endow     index of labour endowment     / 1.0 /
       esub_x substition elas for x /1/
       esub_y substition elas for y /1/
       esub_u substition elas for u /1/
       esub_ra substition elas for u /1/
       pr_Ud Price of PU in RA (Demand) /1/
       Otax  tax on output x     /0.0/
       Itax  tax on input L for x /0./
       Pr_U  price of PU output in U /1./;

*       MPSGE model declaration follows

$ontext
$MODEL:twobytwo_wPriceDemand

$SECTORS:
    X   ! Activity level for sector X -- benchmark=1
    Y   ! Activity level for sector Y -- benchmark=1
    U   ! Activity level for sector U -- benchmark=1

$COMMODITIES:
    PX  ! Relative price index for commodity X -- benchmark=1
    PY  ! Relative price index for commodity Y -- benchmark=1
    PU  ! Relative price index for commodity U -- benchmark=1
    PL  ! Relative price index for labor -- benchmark=1
    PK  ! Relative price index for capital -- benchmark=1

$CONSUMERS:
    RA  ! Income level for representative agent 

$PROD:X s:esub_x !t:0
        O:PX   Q:80    A:RA  T:Otax  !P:1.2 
        I:PL   Q:30    A:RA  T:Itax  ! Variable LX in the algebraic model
        I:PK   Q:50    !P:1.2 !A:RA  T:Itax  ! Variable LX in the algebraic model

$PROD:Y s:esub_y !t:0
        O:PY   Q:54   ! A:RA  T:Otax  
        I:PL   Q:24   !P:1.2 A:RA  T:Itax  !Both PL in case benchmark     Variable KY in the algebraic model
        I:PK   Q:30   ! Variable KY in the algebraic model

$PROD:U s:esub_u !t:0
        O:PU   Q:124  P:Pr_U !A:RA T:-Itax
        I:PX   Q:80   !P:1.2  A:RA T:-Itax! Variable DX in the algebraic model
        I:PY   Q:44    !P:0.8  ! Variable DY in the algebraic model

$DEMAND:RA s:esub_ra
        D:PY   Q:10 P:1
        D:PU   Q:124 P:pr_Ud ! A Demand quantity serves as a baseline for Welfare, and needed for 2+ D
        E:PL   Q:(54*endow) 
        E:PK   Q:80
                
$REPORT:
    v:SX    O:PX      PROD:X
    v:DXL    I:PL      PROD:X
    v:DXK    I:PK      PROD:X
    v:SY    O:PY      PROD:Y
    v:DYL    I:PL      PROD:Y
    v:DYK    I:PK      PROD:Y
    v:SU     O:PU      PROD:U
    v:DUX    I:PX      PROD:U
    v:DUY    I:PY      PROD:U
    v:DU     D:PU      DEMAND:RA
    v:DY     D:PY      DEMAND:RA
    v:CWI    W:RA

$offtext

* Compiler directive instructing MPSGE to compile the functions

$sysinclude mpsgeset twobytwo_wPriceDemand
PX.LO = 0.001; PY.LO = 0.001; PU.LO = 0.001; PL.LO = 0.001; PK.LO = 0.001;

* Benchmark replication
PU.FX= 1;
twobytwo_wPriceDemand.iterlim = 0;

$include twobytwo_wPriceDemand.GEN
solve twobytwo_wPriceDemand using mcp;
abort$(abs(twobytwo_wPriceDemand.objval) gt 1e-7) "*** twobytwo does not calibrate ! ***";
twobytwo_wPriceDemand.iterlim = 1000;

parameter   equilibrium Equilibrium values;

equilibrium("X","benchmark") = X.L;
equilibrium("Y","benchmark") = Y.L;
equilibrium("U","benchmark") = U.L;

equilibrium("PX","benchmark") = PX.L;
equilibrium("PY","benchmark") = PY.L;
equilibrium("PU","benchmark") = PU.L;
equilibrium("PL","benchmark") = PL.L;
equilibrium("PK","benchmark") = PK.L;

equilibrium("SX","benchmark") = SX.L/X.L;
equilibrium("SY","benchmark") = SY.L/Y.L;
equilibrium("SU","benchmark") = SU.L/U.L;
equilibrium("DXL","benchmark") = DXL.L/X.L;
equilibrium("DXK","benchmark") = DXK.L/X.L;
equilibrium("DYL","benchmark") = DYL.L/Y.L;
equilibrium("DYK","benchmark") = DYK.L/Y.L;
equilibrium("DUX","benchmark") = DUX.L/U.L;
equilibrium("DUY","benchmark") = DUY.L/U.L;

equilibrium("RA","benchmark") = RA.L;
equilibrium("DU","benchmark") = DU.L;
equilibrium("DY","benchmark") = DY.L;
equilibrium("CWI","benchmark") = CWI.L;

equilibrium("PX/PX","benchmark") = PX.L/PX.L;
equilibrium("PY/PX","benchmark") = PY.L/PX.L;
equilibrium("PU/PX","benchmark") = PU.L/PX.L;
equilibrium("PL/PX","benchmark") = PL.L/PX.L;
equilibrium("PK/PX","benchmark") = PK.L/PX.L;
equilibrium("RA/PX","benchmark") = RA.L/PX.L;

*   Counterfactual : 10% increase in labor endowment

endow = 1.1;
*   Solve the model with the default normalization of prices which 
*   fixes the income level of the representative agent.  The RA
*   income level at the initial prices equals 80 + 1.1*70 = 157.

*RA.FX = 80 + 1.1 * 70;
$include twobytwo_wPriceDemand.GEN
solve twobytwo_wPriceDemand using mcp;

*   Save counterfactual values:

equilibrium("X","RA=157") = X.L;
equilibrium("Y","RA=157") = Y.L;
equilibrium("U","RA=157") = U.L;

equilibrium("PX","RA=157") = PX.L;
equilibrium("PY","RA=157") = PY.L;
equilibrium("PU","RA=157") = PU.L;
equilibrium("PL","RA=157") = PL.L;
equilibrium("PK","RA=157") = PK.L;

equilibrium("RA","RA=157") = RA.L;
equilibrium("SX","RA=157") = SX.L/X.L;
equilibrium("SY","RA=157") = SY.L/Y.L;
equilibrium("SU","RA=157") = SU.L/U.L;

equilibrium("DXL","RA=157") = DXL.L/X.L;
equilibrium("DXK","RA=157") = DXK.L/X.L;
equilibrium("DYL","RA=157") = DYL.L/Y.L;
equilibrium("DYK","RA=157") = DYK.L/Y.L;
equilibrium("DUX","RA=157") = DUX.L/U.L;
equilibrium("DUY","RA=157") = DUY.L/U.L;
equilibrium("DU","RA=157") = DU.L;
equilibrium("DY","RA=157") = DY.L;
equilibrium("CWI","RA=157") = CWI.L;

equilibrium("PX/PX","RA=157") = PX.L/PX.L;
equilibrium("PY/PX","RA=157") = PY.L/PX.L;
equilibrium("PU/PX","RA=157") = PU.L/PX.L;
equilibrium("PL/PX","RA=157") = PL.L/PX.L;
equilibrium("PK/PX","RA=157") = PK.L/PX.L;
equilibrium("RA/PX","RA=157") = RA.L/PX.L;

*   Fix a numeraire price index and recalculate:

*PU.UP=INF;
*PU.LO=.001;
*PX.FX = 1;
esub_ra=0.6;
$include twobytwo_wPriceDemand.GEN
solve twobytwo_wPriceDemand using mcp;

equilibrium("X","eRA=.6") = X.L;
equilibrium("Y","eRA=.6") = Y.L;
equilibrium("U","eRA=.6") = U.L;

equilibrium("PX","eRA=.6") = PX.L;
equilibrium("PY","eRA=.6") = PY.L;
equilibrium("PU","eRA=.6") = PU.L;
equilibrium("PL","eRA=.6") = PL.L;
equilibrium("PK","eRA=.6") = PK.L;

equilibrium("SX","eRA=.6") = SX.L/X.L;
equilibrium("SY","eRA=.6") = SY.L/Y.L;
equilibrium("SU","eRA=.6") = SU.L/U.L;

equilibrium("DXL","eRA=.6") = DXL.L/X.L;
equilibrium("DXK","eRA=.6") = DXK.L/X.L;
equilibrium("DYL","eRA=.6") = DYL.L/Y.L;
equilibrium("DYK","eRA=.6") = DYK.L/Y.L;
equilibrium("DUX","eRA=.6") = DUX.L/U.L;
equilibrium("DUY","eRA=.6") = DUY.L/U.L;
equilibrium("DU","eRA=.6") = DU.L;
equilibrium("DY","eRA=.6") = DY.L;
equilibrium("CWI","eRA=.6") = CWI.L;

equilibrium("RA","eRA=.6") = RA.L;

equilibrium("PX/PX","eRA=.6") = PX.L/PX.L;
equilibrium("PY/PX","eRA=.6") = PY.L/PX.L;
equilibrium("PU/PX","eRA=.6") = PU.L/PX.L;
equilibrium("PL/PX","eRA=.6") = PL.L/PX.L;
equilibrium("PK/PX","eRA=.6") = PK.L/PX.L;

equilibrium("RA/PX","eRA=.6") = RA.L/PX.L;

*   Recalculate with a different numeraire.
*   "Unfix" the price of X and fix the wage rate:

*PX.UP = +inf; 
*PX.LO = 0.001;
*PL.FX = 1;
pr_Ud = 3;
$include twobytwo_wPriceDemand.GEN
solve twobytwo_wPriceDemand using mcp;

equilibrium("X","pr_Ud=3") = X.L;
equilibrium("Y","pr_Ud=3") = Y.L;
equilibrium("U","pr_Ud=3") = U.L;

equilibrium("PX","pr_Ud=3") = PX.L;
equilibrium("PY","pr_Ud=3") = PY.L;
equilibrium("PU","pr_Ud=3") = PU.L;
equilibrium("PL","pr_Ud=3") = PL.L;
equilibrium("PK","pr_Ud=3") = PK.L;

equilibrium("SX","pr_Ud=3") = SX.L/X.L;
equilibrium("SY","pr_Ud=3") = SY.L/Y.L;
equilibrium("SU","pr_Ud=3") = SU.L/U.L;

equilibrium("DXL","pr_Ud=3") = DXL.L/X.L;
equilibrium("DXK","pr_Ud=3") = DXK.L/X.L;
equilibrium("DYL","pr_Ud=3") = DYL.L/Y.L;
equilibrium("DYK","pr_Ud=3") = DYK.L/Y.L;
equilibrium("DUX","pr_Ud=3") = DUX.L/U.L;
equilibrium("DUY","pr_Ud=3") = DUY.L/U.L;
equilibrium("DU","pr_Ud=3") = DU.L;
equilibrium("DY","pr_Ud=3") = DY.L;
equilibrium("CWI","pr_Ud=3") = CWI.L;

equilibrium("RA","pr_Ud=3") = RA.L;

equilibrium("PX/PX","pr_Ud=3") = PX.L/PX.L;
equilibrium("PY/PX","pr_Ud=3") = PY.L/PX.L;
equilibrium("PU/PX","pr_Ud=3") = PU.L/PX.L;
equilibrium("PL/PX","pr_Ud=3") = PL.L/PX.L;
equilibrium("PK/PX","pr_Ud=3") = PK.L/PX.L;

equilibrium("RA/PX","pr_Ud=3") = RA.L/PX.L;

esub_ra=0.5;
pr_Ud=2;
$include twobytwo_wPriceDemand.GEN
solve twobytwo_wPriceDemand using mcp;

equilibrium("X","prU2,eRA.5") = X.L;
equilibrium("Y","prU2,eRA.5") = Y.L;
equilibrium("U","prU2,eRA.5") = U.L;

equilibrium("PX","prU2,eRA.5") = PX.L;
equilibrium("PY","prU2,eRA.5") = PY.L;
equilibrium("PU","prU2,eRA.5") = PU.L;
equilibrium("PL","prU2,eRA.5") = PL.L;
equilibrium("PK","prU2,eRA.5") = PK.L;

equilibrium("SX","prU2,eRA.5") = SX.L/X.L;
equilibrium("SY","prU2,eRA.5") = SY.L/Y.L;
equilibrium("SU","prU2,eRA.5") = SU.L/U.L;

equilibrium("DXL","prU2,eRA.5") = DXL.L/X.L;
equilibrium("DXK","prU2,eRA.5") = DXK.L/X.L;
equilibrium("DYL","prU2,eRA.5") = DYL.L/Y.L;
equilibrium("DYK","prU2,eRA.5") = DYK.L/Y.L;
equilibrium("DUX","prU2,eRA.5") = DUX.L/U.L;
equilibrium("DUY","prU2,eRA.5") = DUY.L/U.L;
equilibrium("DU","prU2,eRA.5") = DU.L;
equilibrium("DY","prU2,eRA.5") = DY.L;
equilibrium("CWI","prU2,eRA.5") = CWI.L;

equilibrium("RA","prU2,eRA.5") = RA.L;

equilibrium("PX/PX","prU2,eRA.5") = PX.L/PX.L;
equilibrium("PY/PX","prU2,eRA.5") = PY.L/PX.L;
equilibrium("PU/PX","prU2,eRA.5") = PU.L/PX.L;
equilibrium("PL/PX","prU2,eRA.5") = PL.L/PX.L;
equilibrium("PK/PX","prU2,eRA.5") = PK.L/PX.L;

equilibrium("RA/PX","prU2,eRA.5") = RA.L/PX.L;

pr_Ud=0.5;
esub_ra=0.6
$include twobytwo_wPriceDemand.GEN
solve twobytwo_wPriceDemand using mcp;

equilibrium("X","prUd.5,e.6") = X.L;
equilibrium("Y","prUd.5,e.6") = Y.L;
equilibrium("U","prUd.5,e.6") = U.L;

equilibrium("PX","prUd.5,e.6") = PX.L;
equilibrium("PY","prUd.5,e.6") = PY.L;
equilibrium("PU","prUd.5,e.6") = PU.L;
equilibrium("PL","prUd.5,e.6") = PL.L;
equilibrium("PK","prUd.5,e.6") = PK.L;

equilibrium("SX","prUd.5,e.6") = SX.L/X.L;
equilibrium("SY","prUd.5,e.6") = SY.L/Y.L;
equilibrium("SU","prUd.5,e.6") = SU.L/U.L;

equilibrium("DXL","prUd.5,e.6") = DXL.L/X.L;
equilibrium("DXK","prUd.5,e.6") = DXK.L/X.L;
equilibrium("DYL","prUd.5,e.6") = DYL.L/Y.L;
equilibrium("DYK","prUd.5,e.6") = DYK.L/Y.L;
equilibrium("DUX","prUd.5,e.6") = DUX.L/U.L;
equilibrium("DUY","prUd.5,e.6") = DUY.L/U.L;
equilibrium("DU","prUd.5,e.6") = DU.L;
equilibrium("DY","prUd.5,e.6") = DY.L;
equilibrium("CWI","prUd.5,e.6") = CWI.L;

equilibrium("RA","prUd.5,e.6") = RA.L;

equilibrium("PX/PX","prUd.5,e.6") = PX.L/PX.L;
equilibrium("PY/PX","prUd.5,e.6") = PY.L/PX.L;
equilibrium("PU/PX","prUd.5,e.6") = PU.L/PX.L;
equilibrium("PL/PX","prUd.5,e.6") = PL.L/PX.L;
equilibrium("PK/PX","prUd.5,e.6") = PK.L/PX.L;

equilibrium("RA/PX","prUd.5,e.6") = RA.L/PX.L;

pr_Ud=0.5;
esub_ra=0.0
$include twobytwo_wPriceDemand.GEN
solve twobytwo_wPriceDemand using mcp;

equilibrium("X","prUd.5,e.0") = X.L;
equilibrium("Y","prUd.5,e.0") = Y.L;
equilibrium("U","prUd.5,e.0") = U.L;

equilibrium("PX","prUd.5,e.0") = PX.L;
equilibrium("PY","prUd.5,e.0") = PY.L;
equilibrium("PU","prUd.5,e.0") = PU.L;
equilibrium("PL","prUd.5,e.0") = PL.L;
equilibrium("PK","prUd.5,e.0") = PK.L;

equilibrium("SX","prUd.5,e.0") = SX.L/X.L;
equilibrium("SY","prUd.5,e.0") = SY.L/Y.L;
equilibrium("SU","prUd.5,e.0") = SU.L/U.L;

equilibrium("DXL","prUd.5,e.0") = DXL.L/X.L;
equilibrium("DXK","prUd.5,e.0") = DXK.L/X.L;
equilibrium("DYL","prUd.5,e.0") = DYL.L/Y.L;
equilibrium("DYK","prUd.5,e.0") = DYK.L/Y.L;
equilibrium("DUX","prUd.5,e.0") = DUX.L/U.L;
equilibrium("DUY","prUd.5,e.0") = DUY.L/U.L;
equilibrium("DU","prUd.5,e.0") = DU.L;
equilibrium("DY","prUd.5,e.0") = DY.L;
equilibrium("CWI","prUd.5,e.0") = CWI.L;

equilibrium("RA","prUd.5,e.0") = RA.L;

equilibrium("PX/PX","prUd.5,e.0") = PX.L/PX.L;
equilibrium("PY/PX","prUd.5,e.0") = PY.L/PX.L;
equilibrium("PU/PX","prUd.5,e.0") = PU.L/PX.L;
equilibrium("PL/PX","prUd.5,e.0") = PL.L/PX.L;
equilibrium("PK/PX","prUd.5,e.0") = PK.L/PX.L;

equilibrium("RA/PX","prUd.5,e.0") = RA.L/PX.L;

esub_ra=0.6;
Itax = 0.1;
$include twobytwo_wPriceDemand.GEN
solve twobytwo_wPriceDemand using mcp;

*   Save counterfactual values:

equilibrium("X","Itax=0.1") = X.L;
equilibrium("Y","Itax=0.1") = Y.L;
equilibrium("U","Itax=0.1") = U.L;

equilibrium("PX","Itax=0.1") = PX.L;
equilibrium("PY","Itax=0.1") = PY.L;
equilibrium("PU","Itax=0.1") = PU.L;
equilibrium("PL","Itax=0.1") = PL.L;
equilibrium("PK","Itax=0.1") = PK.L;

equilibrium("RA","Itax=0.1") = RA.L;
equilibrium("SX","Itax=0.1") = SX.L/X.L;
equilibrium("SY","Itax=0.1") = SY.L/Y.L;
equilibrium("SU","Itax=0.1") = SU.L/U.L;

equilibrium("DXL","Itax=0.1") = DXL.L/X.L;
equilibrium("DXK","Itax=0.1") = DXK.L/X.L;
equilibrium("DYL","Itax=0.1") = DYL.L/Y.L;
equilibrium("DYK","Itax=0.1") = DYK.L/Y.L;
equilibrium("DUX","Itax=0.1") = DUX.L/U.L;
equilibrium("DUY","Itax=0.1") = DUY.L/U.L;
equilibrium("DU","Itax=0.1") = DU.L;
equilibrium("DY","Itax=0.1") = DY.L;
equilibrium("CWI","Itax=0.1") = CWI.L;

equilibrium("PX/PX","Itax=0.1") = PX.L/PX.L;
equilibrium("PY/PX","Itax=0.1") = PY.L/PX.L;
equilibrium("PU/PX","Itax=0.1") = PU.L/PX.L;
equilibrium("PL/PX","Itax=0.1") = PL.L/PX.L;
equilibrium("PK/PX","Itax=0.1") = PK.L/PX.L;
equilibrium("RA/PX","Itax=0.1") = RA.L/PX.L;

Itax = 0.1;
Otax = 0.1;
$include twobytwo_wPriceDemand.GEN
solve twobytwo_wPriceDemand using mcp;

*   Save counterfactual values:

equilibrium("X","Otax=0.1") = X.L;
equilibrium("Y","Otax=0.1") = Y.L;
equilibrium("U","Otax=0.1") = U.L;

equilibrium("PX","Otax=0.1") = PX.L;
equilibrium("PY","Otax=0.1") = PY.L;
equilibrium("PU","Otax=0.1") = PU.L;
equilibrium("PL","Otax=0.1") = PL.L;
equilibrium("PK","Otax=0.1") = PK.L;

equilibrium("RA","Otax=0.1") = RA.L;
equilibrium("SX","Otax=0.1") = SX.L/X.L;
equilibrium("SY","Otax=0.1") = SY.L/Y.L;
equilibrium("SU","Otax=0.1") = SU.L/U.L;

equilibrium("DXL","Otax=0.1") = DXL.L/X.L;
equilibrium("DXK","Otax=0.1") = DXK.L/X.L;
equilibrium("DYL","Otax=0.1") = DYL.L/Y.L;
equilibrium("DYK","Otax=0.1") = DYK.L/Y.L;
equilibrium("DUX","Otax=0.1") = DUX.L/U.L;
equilibrium("DUY","Otax=0.1") = DUY.L/U.L;
equilibrium("DU","Otax=0.1") = DU.L;
equilibrium("DY","Otax=0.1") = DY.L;
equilibrium("CWI","Otax=0.1") = CWI.L;

equilibrium("PX/PX","Otax=0.1") = PX.L/PX.L;
equilibrium("PY/PX","Otax=0.1") = PY.L/PX.L;
equilibrium("PU/PX","Otax=0.1") = PU.L/PX.L;
equilibrium("PL/PX","Otax=0.1") = PL.L/PX.L;
equilibrium("PK/PX","Otax=0.1") = PK.L/PX.L;
equilibrium("RA/PX","Otax=0.1") = RA.L/PX.L;

option decimals=7;
display equilibrium;

execute_unload "twobytwo_wPriceDemand.gdx" equilibrium
**
***=== Write to variable levels to Excel file from GDX 
***=== If we do not specify a sheet, data is placed in first sheet
execute 'gdxxrw.exe twobytwo_wPriceDemand.gdx o=MPSGEresults.xlsx par=equilibrium rng=two_by_two_PriceinDem!'
execute 'gdxxrw.exe twobytwo_wPriceDemand.gdx o=C:\Users\Eli\.julia\dev\MPSGE\test\MPSGEresults.xlsx par=equilibrium rng=two_by_two_PriceinDem!'