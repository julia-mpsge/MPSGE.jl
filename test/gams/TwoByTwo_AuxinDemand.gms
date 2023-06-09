$ontext
This test model is based on Markusen MS_8s, adapted to remove non-1 prices

The M2_8s model is based on M2-1S which introduced pre-existing taxes.
All features are identical except that in this model there is a lower
bound on the real wage and classical unemployment.

The following accounting matrix is identical to M2-1 except that
the labor endowment is now 100*(1-U) = 100*(1-0.2) = 80 in the benchmark.

                Production Sectors          Consumers

   Markets   |    X       Y        W    |       CONS
   ------------------------------------------------------
        PX   |  100             -100    |
        PY   |          100     -100    |
        PW   |                   200    |       -200
        PL   |  -20     -60             |        100*(1-U)
        PK   |  -60     -40             |        100
        TAX  |  -20       0             |         20
   ------------------------------------------------------

$offtext

*       Declare parameters which will be need to specify the
*       benchmark and counterfactual cases.  

SCALAR  TX      Proportional output tax on sector X,
        TY      Proportional output tax on sector Y,
        TLX     Ad-valorem tax on labor inputs to X,
        TKX     Ad-valorem tax on capital inputs to X
	U0	Initial unemployment rate	/ 0.2 /;

$ONTEXT

$MODEL:M2_8S_AuxTest

$SECTORS:
        X       ! Activity level for sector X
        Y       ! Activity level for sector Y
        W       ! Activity level for sector W (Hicksian welfare index)

$COMMODITIES:
        PX      ! Price index for commodity X
        PY      ! Price index for commodity Y
        PL      ! Price index for primary factor L (net of tax)
        PK      ! Price index for primary factor K
        PW      ! Price index for welfare (expenditure function)

$CONSUMERS:
        CONS    ! Income level for consumer CONS

$AUXILIARY:
	U	! Unemployment rate

$PROD:X s:1
        O:PX    Q:100      A:CONS T:TX
        I:PL    Q:40       !A:CONS T:TLX  !Q:20 P:2  
        I:PK    Q:50       A:CONS T:TKX
$REPORT:
        v:SXX    O:PX      PROD:X
        v:DLX    I:PL      PROD:X
        v:DKX    I:PK      PROD:X

$PROD:Y s:1
        O:PY    Q:100     T:TY     ! Output tax initially 0.
        I:PL    Q:60
        I:PK    Q:40
$REPORT:
        v:SYY    O:PY      PROD:Y
        v:DLY    I:PL      PROD:Y
        v:DKY    I:PK      PROD:Y

$PROD:W s:1
        O:PW    Q:200
        I:PX    Q:100
        I:PY    Q:100
$REPORT:
        v:SWW    O:PW      PROD:W
        v:DXW    I:PX      PROD:W
        v:DYW    I:PY      PROD:W
        

$DEMAND:CONS
        D:PW    Q:200   
        E:PL    Q:120!(80/(1-U0)) !100!
        E:PL    Q:(-80/(1-U0))  R:U  
        E:PK    Q:90  

$REPORT:
        v:CWCONS    D:PW      DEMAND:CONS
        v:CWI    W:CONS

*	Simple lower bound on the real wage -- using PW as the
*	price index for denominating wages

$CONSTRAINT:U
	PL=e=PW;

$OFFTEXT
$SYSINCLUDE mpsgeset M2_8S_AuxTest
parameter   equilibrium Equilibrium values;

*       Benchmark replication:

TX  = 0.1;
TY  = 0;
*TLX = .25;
***1;
TKX = 0;
U.L = U0;
***U0;
*
M2_8S_AuxTest.ITERLIM = 0;
$INCLUDE M2_8S_AuxTest.GEN
SOLVE M2_8S_AuxTest USING MCP;
abort$(abs(M2_8S_AuxTest.objval) gt 1e-7) "*** twobytwo does not calibrate ! ***";
equilibrium("X.L","benchmark") = X.L;
equilibrium("Y.L","benchmark") = Y.L;
equilibrium("W.L","benchmark") = W.L;
equilibrium("PX.L","benchmark") = PX.L;
equilibrium("PY.L","benchmark") = PY.L;
equilibrium("PW.L","benchmark") = PW.L;
equilibrium("PL.L","benchmark") = PL.L;
equilibrium("PK.L","benchmark") = PK.L;
equilibrium("U.L","benchmark") = U.L;
equilibrium("SXX.L","benchmark") = SXX.L/X.L;
equilibrium("SYY.L","benchmark") = SYY.L/Y.l;
equilibrium("SWW.L","benchmark") = SWW.L/W.L;
equilibrium("DKX.L","benchmark") = DKX.L/X.L;
equilibrium("DLX.L","benchmark") = DLX.L/X.L;
equilibrium("DLY.L","benchmark") = DLY.L/Y.L;
equilibrium("DKY.L","benchmark") = DKY.L/Y.L;
equilibrium("DXW.L","benchmark") = DXW.L/W.L;
equilibrium("DYW.L","benchmark") = DYW.L/W.L;

equilibrium("CONS.L","benchmark") = CONS.L;
equilibrium("CWCONS.L","benchmark") = CWCONS.L;
equilibrium("CWI.L","benchmark") = CWI.L;

M2_8S_AuxTest.ITERLIM = 1000;
*
*       As in M2-1S, we replace the tax on labor inputs
*       by a uniform tax on both factors:

U.L=.1;
$INCLUDE M2_8S_AuxTest.GEN
SOLVE M2_8S_AuxTest USING MCP;

equilibrium("X.L","UnEmp=.1") = X.L;
equilibrium("Y.L","UnEmp=.1") = Y.L;
equilibrium("W.L","UnEmp=.1") = W.L;
equilibrium("PX.L","UnEmp=.1") = PX.L;
equilibrium("PY.L","UnEmp=.1") = PY.L;
equilibrium("PW.L","UnEmp=.1") = PW.L;
equilibrium("PL.L","UnEmp=.1") = PL.L;
equilibrium("PK.L","UnEmp=.1") = PK.L;
equilibrium("U.L","UnEmp=.1") = U.L;

equilibrium("SXX.L","UnEmp=.1") = SXX.L/X.L;
equilibrium("SYY.L","UnEmp=.1") = SYY.L/Y.l;
equilibrium("SWW.L","UnEmp=.1") = SWW.L/W.L;
equilibrium("DLX.L","UnEmp=.1") = DLX.L/X.L;
equilibrium("DKX.L","UnEmp=.1") = DKX.L/X.L;
equilibrium("DLY.L","UnEmp=.1") = DLY.L/Y.L;
equilibrium("DKY.L","UnEmp=.1") = DKY.L/Y.L;
equilibrium("DXW.L","UnEmp=.1") = DXW.L/W.L;
equilibrium("DYW.L","UnEmp=.1") = DYW.L/W.L;

equilibrium("CONS.L","UnEmp=.1") = CONS.L;
equilibrium("CWI.L","UnEmp=.1") = CWI.L;
equilibrium("CWCONS.L","UnEmp=.1") = CWCONS.L;

PX.FX=1;
TKX = 0.25;
TX  = 0;
TY  = 0;
$INCLUDE M2_8S_AuxTest.GEN
SOLVE M2_8S_AuxTest USING MCP;

equilibrium("X.L","TKX=0.25") = X.L;
equilibrium("Y.L","TKX=0.25") = Y.L;
equilibrium("W.L","TKX=0.25") = W.L;
equilibrium("U.L","TKX=0.25") = U.L;
equilibrium("PX.L","TKX=0.25") = PX.L;
equilibrium("PY.L","TKX=0.25") = PY.L;
equilibrium("PW.L","TKX=0.25") = PW.L;
equilibrium("PL.L","TKX=0.25") = PL.L;
equilibrium("PK.L","TKX=0.25") = PK.L;

equilibrium("SXX.L","TKX=0.25") = SXX.L/X.L;
equilibrium("SYY.L","TKX=0.25") = SYY.L/Y.l;
equilibrium("SWW.L","TKX=0.25") = SWW.L/W.L;
equilibrium("DLX.L","TKX=0.25") = DLX.L/X.L;
equilibrium("DKX.L","TKX=0.25") = DKX.L/X.L;
equilibrium("DLY.L","TKX=0.25") = DLY.L/Y.L;
equilibrium("DKY.L","TKX=0.25") = DKY.L/Y.L;
equilibrium("DXW.L","TKX=0.25") = DXW.L/W.L;
equilibrium("DYW.L","TKX=0.25") = DYW.L/W.L;

equilibrium("CONS.L","TKX=0.25") = CONS.L;
equilibrium("CWI.L","TKX=0.25") = CWI.L;
equilibrium("CWCONS.L","TKX=0.25") = CWCONS.L;

TY  = 0.5;
$INCLUDE M2_8S_AuxTest.GEN
SOLVE M2_8S_AuxTest USING MCP;

equilibrium("X.L","&TY=.5") = X.L;
equilibrium("Y.L","&TY=.5") = Y.L;
equilibrium("W.L","&TY=.5") = W.L;
equilibrium("U.L","&TY=.5") = U.L;
equilibrium("PX.L","&TY=.5") = PX.L;
equilibrium("PY.L","&TY=.5") = PY.L;
equilibrium("PW.L","&TY=.5") = PW.L;
equilibrium("PL.L","&TY=.5") = PL.L;
equilibrium("PK.L","&TY=.5") = PK.L;

equilibrium("SXX.L","&TY=.5") = SXX.L/X.L;
equilibrium("SYY.L","&TY=.5") = SYY.L/Y.l;
equilibrium("SWW.L","&TY=.5") = SWW.L/W.L;
equilibrium("DLX.L","&TY=.5") = DLX.L/X.L;
equilibrium("DKX.L","&TY=.5") = DKX.L/X.L;
equilibrium("DLY.L","&TY=.5") = DLY.L/Y.L;
equilibrium("DKY.L","&TY=.5") = DKY.L/Y.L;
equilibrium("DXW.L","&TY=.5") = DXW.L/W.L;
equilibrium("DYW.L","&TY=.5") = DYW.L/W.L;

equilibrium("CONS.L","&TY=.5") = CONS.L;
equilibrium("CWI.L","&TY=.5") = CWI.L;
equilibrium("CWCONS.L","&TY=.5") = CWCONS.L;

TKX = 0.0;
TY  = 0.5;
$INCLUDE M2_8S_AuxTest.GEN
SOLVE M2_8S_AuxTest USING MCP;

equilibrium("X.L","TY=0.5") = X.L;
equilibrium("Y.L","TY=0.5") = Y.L;
equilibrium("W.L","TY=0.5") = W.L;
equilibrium("U.L","TY=0.5") = U.L;
equilibrium("PX.L","TY=0.5") = PX.L;
equilibrium("PY.L","TY=0.5") = PY.L;
equilibrium("PW.L","TY=0.5") = PW.L;
equilibrium("PL.L","TY=0.5") = PL.L;
equilibrium("PK.L","TY=0.5") = PK.L;

equilibrium("SXX.L","TY=0.5") = SXX.L/X.L;
equilibrium("SYY.L","TY=0.5") = SYY.L/Y.l;
equilibrium("SWW.L","TY=0.5") = SWW.L/W.L;
equilibrium("DLX.L","TY=0.5") = DLX.L/X.L;
equilibrium("DKX.L","TY=0.5") = DKX.L/X.L;
equilibrium("DLY.L","TY=0.5") = DLY.L/Y.L;
equilibrium("DKY.L","TY=0.5") = DKY.L/Y.L;
equilibrium("DXW.L","TY=0.5") = DXW.L/W.L;
equilibrium("DYW.L","TY=0.5") = DYW.L/W.L;

equilibrium("CONS.L","TY=0.5") = CONS.L;
equilibrium("CWI.L","TY=0.5") = CWI.L;
equilibrium("CWCONS.L","TY=0.5") = CWCONS.L;

option decimals=8;
display equilibrium;

execute_unload "M2_8S_AuxTest.gdx" equilibrium

*=== Write to variable levels to Excel file from GDX 
*=== If we do not specify a sheet, data is placed in first sheet
execute 'gdxxrw.exe M2_8S_AuxTest.gdx o=MPSGEresults.xlsx par=equilibrium rng=TwoxTwowAuxDem!'
execute 'gdxxrw.exe M2_8S_AuxTest.gdx o=C:\Users\Eli\.julia\dev\MPSGE\test\MPSGEresults.xlsx par=equilibrium rng=TwoxTwowAuxDem!'
