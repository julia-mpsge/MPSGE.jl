$title  A two by two general equilibrium model -- scalar GAMS/MPSGE 
* This matches the 2x2_Scalar_Alg-MPSGE with x->s:1 and y->s:1,

parameter   endow     index of labour endowment     / 1.0 /
       esub_x substition elas for x /1/
       esub_y substition elas for y /1/
       esub_u substition elas for u /1/
       Otax  tax on output x     /0.2/
       Itax  tax on input L for x /0./;

*       MPSGE model declaration follows

$ontext
$MODEL:twobytwo_wPriceOut

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
        O:PX   Q:100   P:1.2   A:RA  T:Otax  
        I:PL   Q:30    A:RA  T:Itax  ! Variable LX in the algebraic model
        I:PK   Q:50    !P:1.2 !A:RA  T:Itax  ! Variable LX in the algebraic model

$PROD:Y s:esub_y !t:0
        O:PY   Q:54   ! A:RA  T:Otax  
        I:PL   Q:24   !P:1.2 A:RA  T:Itax  !Both PL in case benchmark     Variable KY in the algebraic model
        I:PK   Q:30   ! Variable KY in the algebraic model

$PROD:U s:esub_u !t:0
        O:PU   Q:154   !A:RA T:-Itax
        I:PX   Q:100   !P:1.2  A:RA T:-Itax! Variable DX in the algebraic model
        I:PY   Q:54    !P:0.8  ! Variable DY in the algebraic model

$DEMAND:RA !s:1
        D:PU   Q:150  !doesn't matter if Q is blank or any
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
    v:CWI    W:RA

$offtext

* Compiler directive instructing MPSGE to compile the functions

$sysinclude mpsgeset twobytwo_wPriceOut
PX.LO = 0.001; PY.LO = 0.001; PU.LO = 0.001; PL.LO = 0.001; PK.LO = 0.001;

* Benchmark replication
PU.FX= 1;
twobytwo_wPriceOut.iterlim = 0;

$include twobytwo_wPriceOut.GEN
solve twobytwo_wPriceOut using mcp;
abort$(abs(twobytwo_wPriceOut.objval) gt 1e-7) "*** twobytwo does not calibrate ! ***";
twobytwo_wPriceOut.iterlim = 1000;

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
$include twobytwo_wPriceOut.GEN
solve twobytwo_wPriceOut using mcp;

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
equilibrium("CWI","RA=157") = CWI.L;

equilibrium("PX/PX","RA=157") = PX.L/PX.L;
equilibrium("PY/PX","RA=157") = PY.L/PX.L;
equilibrium("PU/PX","RA=157") = PU.L/PX.L;
equilibrium("PL/PX","RA=157") = PL.L/PX.L;
equilibrium("PK/PX","RA=157") = PK.L/PX.L;
equilibrium("RA/PX","RA=157") = RA.L/PX.L;

*   Fix a numeraire price index and recalculate:

PU.UP=INF;
PU.LO=.001;
PX.FX = 1;
$include twobytwo_wPriceOut.GEN
solve twobytwo_wPriceOut using mcp;

equilibrium("X","PX=1") = X.L;
equilibrium("Y","PX=1") = Y.L;
equilibrium("U","PX=1") = U.L;

equilibrium("PX","PX=1") = PX.L;
equilibrium("PY","PX=1") = PY.L;
equilibrium("PU","PX=1") = PU.L;
equilibrium("PL","PX=1") = PL.L;
equilibrium("PK","PX=1") = PK.L;

equilibrium("SX","PX=1") = SX.L/X.L;
equilibrium("SY","PX=1") = SY.L/Y.L;
equilibrium("SU","PX=1") = SU.L/U.L;

equilibrium("DXL","PX=1") = DXL.L/X.L;
equilibrium("DXK","PX=1") = DXK.L/X.L;
equilibrium("DYL","PX=1") = DYL.L/Y.L;
equilibrium("DYK","PX=1") = DYK.L/Y.L;
equilibrium("DUX","PX=1") = DUX.L/U.L;
equilibrium("DUY","PX=1") = DUY.L/U.L;
equilibrium("DU","PX=1") = DU.L;
equilibrium("CWI","PX=1") = CWI.L;

equilibrium("RA","PX=1") = RA.L;

equilibrium("PX/PX","PX=1") = PX.L/PX.L;
equilibrium("PY/PX","PX=1") = PY.L/PX.L;
equilibrium("PU/PX","PX=1") = PU.L/PX.L;
equilibrium("PL/PX","PX=1") = PL.L/PX.L;
equilibrium("PK/PX","PX=1") = PK.L/PX.L;

equilibrium("RA/PX","PX=1") = RA.L/PX.L;

*   Recalculate with a different numeraire.
*   "Unfix" the price of X and fix the wage rate:

PX.UP = +inf; 
PX.LO = 0.001;
PL.FX = 1;
$include twobytwo_wPriceOut.GEN
solve twobytwo_wPriceOut using mcp;

equilibrium("X","PL=1") = X.L;
equilibrium("Y","PL=1") = Y.L;
equilibrium("U","PL=1") = U.L;

equilibrium("PX","PL=1") = PX.L;
equilibrium("PY","PL=1") = PY.L;
equilibrium("PU","PL=1") = PU.L;
equilibrium("PL","PL=1") = PL.L;
equilibrium("PK","PL=1") = PK.L;

equilibrium("SX","PL=1") = SX.L/X.L;
equilibrium("SY","PL=1") = SY.L/Y.L;
equilibrium("SU","PL=1") = SU.L/U.L;

equilibrium("DXL","PL=1") = DXL.L/X.L;
equilibrium("DXK","PL=1") = DXK.L/X.L;
equilibrium("DYL","PL=1") = DYL.L/Y.L;
equilibrium("DYK","PL=1") = DYK.L/Y.L;
equilibrium("DUX","PL=1") = DUX.L/U.L;
equilibrium("DUY","PL=1") = DUY.L/U.L;
equilibrium("DU","PL=1") = DU.L;
equilibrium("CWI","PL=1") = CWI.L;

equilibrium("RA","PL=1") = RA.L;

equilibrium("PX/PX","PL=1") = PX.L/PX.L;
equilibrium("PY/PX","PL=1") = PY.L/PX.L;
equilibrium("PU/PX","PL=1") = PU.L/PX.L;
equilibrium("PL/PX","PL=1") = PL.L/PX.L;
equilibrium("PK/PX","PL=1") = PK.L/PX.L;

equilibrium("RA/PX","PL=1") = RA.L/PX.L;

Itax = 0.1;
$include twobytwo_wPriceOut.GEN
solve twobytwo_wPriceOut using mcp;

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
equilibrium("CWI","Itax=0.1") = CWI.L;

equilibrium("PX/PX","Itax=0.1") = PX.L/PX.L;
equilibrium("PY/PX","Itax=0.1") = PY.L/PX.L;
equilibrium("PU/PX","Itax=0.1") = PU.L/PX.L;
equilibrium("PL/PX","Itax=0.1") = PL.L/PX.L;
equilibrium("PK/PX","Itax=0.1") = PK.L/PX.L;
equilibrium("RA/PX","Itax=0.1") = RA.L/PX.L;

Itax = 0.1;
Otax = 0.1;
$include twobytwo_wPriceOut.GEN
solve twobytwo_wPriceOut using mcp;

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
equilibrium("CWI","Otax=0.1") = CWI.L;

equilibrium("PX/PX","Otax=0.1") = PX.L/PX.L;
equilibrium("PY/PX","Otax=0.1") = PY.L/PX.L;
equilibrium("PU/PX","Otax=0.1") = PU.L/PX.L;
equilibrium("PL/PX","Otax=0.1") = PL.L/PX.L;
equilibrium("PK/PX","Otax=0.1") = PK.L/PX.L;
equilibrium("RA/PX","Otax=0.1") = RA.L/PX.L;

option decimals=7;
display equilibrium;

execute_unload "twobytwo_wPriceOut.gdx" equilibrium

*=== Write to variable levels to Excel file from GDX 
*=== If we do not specify a sheet, data is placed in first sheet
execute 'gdxxrw.exe twobytwo_wPriceOut.gdx o=MPSGEresults.xlsx par=equilibrium rng=two_by_two_PriceinOutput!'
execute 'gdxxrw.exe twobytwo_wPriceOut.gdx o=C:\Users\Eli\.julia\dev\MPSGE\test\MPSGEresults.xlsx par=equilibrium rng=two_by_two_PriceinOutput!'