$TITLE Model M233: Closed Economy 2x2 with Joint Production

$ONTEXT

Production Sectors Consumers
Markets |  A   B    W    | CONS
------------------------------------------------------
PX      | 80   20   -100 |
PY      | 20   80   -100 |
PW      | 200            | -200
PL      | -40  -60       | 100
PK      | -60  -40       | 100
------------------------------------------------------

$OFFTEXT

PARAMETERS
tr_elas_A CET btw X and Y in sector A /0/
tr_elas_B CET btw X and Y in sector B /0/
 diff
 TA;
diff = 0;
TA = 0;
$ONTEXT

$MODEL: M233

$SECTORS:
 A ! Activity level for sector A (80:20 for X:Y)
 B ! Activity level for sector B (20:80 for X:Y)
 W ! Activity level for sector W (Hicksian welfare index)

$COMMODITIES:
 PX ! Price index for commodity X
 PY ! Price index for commodity Y
 PL ! Price index for primary factor L
 PK ! Price index for primary factor K
 PW ! Price index for welfare (expenditure function)

$CONSUMERS:
 CONS ! Income level for consumer CONS
 
$PROD:A t:tr_elas_A s:1
 O:PX Q:80
 O:PY Q:20
 I:PL Q:40.0 A:CONS T:TA
 I:PK Q:60.0 A:CONS T:TA

$PROD:B t:tr_elas_B s:1
 O:PX Q:(20+diff)
 O:PY Q:80
 I:PL Q:60
 I:PK Q:40

$PROD:W s:1
 O:PW Q:200
 I:PX Q:(100+diff)
 I:PY Q:100

$DEMAND:CONS s:1
 D:PW Q:200
 E:PL Q:100
 E:PK Q:100
 
$REPORT:
    v:SAX     O:PX      PROD:A
    v:SAY     O:PY      PROD:A
    v:SBX     O:PX      PROD:B
    v:SBY     O:PY      PROD:B
    v:DAL    I:PL      PROD:A
    v:DAK    I:PK      PROD:A
    v:DBL    I:PL      PROD:B
    v:DBK    I:PK      PROD:B
    v:SW     O:PW      PROD:W
    v:DWX    I:PX      PROD:W
    v:DWY    I:PY      PROD:W
    v:DW     D:PW      DEMAND:CONS
    v:CWI    W:CONS

 
$OFFTEXT
$SYSINCLUDE mpsgeset M233
$INCLUDE M233.GEN
M233.iterlim = 0;
solve M233 using MCP;
M233.iterlim = 1000;
parameter eq Equilibrium values;

eq("A.L","benchmark") = A.L;
eq("B.L","benchmark") = B.L;
eq("W.L","benchmark") = W.L;
eq("PX.L","benchmark") = PX.L;
eq("PY.L","benchmark") = PY.L;
eq("PW.L","benchmark") = PW.L;
eq("PL.L","benchmark") = PL.L;
eq("PK.L","benchmark") = PK.L;
eq("CONS.L","benchmark") = CONS.L;

eq("SAX.L","benchmark") = SAX.L/A.L;
eq("SAY.L","benchmark") = SAY.L/A.L;
eq("SBX.L","benchmark") = SBX.L/B.L;
eq("SBY.L","benchmark") = SBY.L/B.L;
eq("DAL.L","benchmark") = DAL.L/A.L;
eq("DAK.L","benchmark") = DAK.L/A.L;
eq("DBL.L","benchmark") = DBL.L/B.L;
eq("DBK.L","benchmark") = DBK.L/B.L;
eq("SW.L","benchmark") = SW.L;
eq("DWX.L","benchmark") = DWX.L;
eq("DWY.L","benchmark") = DWY.L;
eq("DW.L","benchmark") = DW.L;
eq("CWI.L","benchmark") = CWI.L;

eq("PX.L/PW.L","benchmark") = PX.L/PW.L;
eq("PY.L/PW.L","benchmark") = PY.L/PW.L;
eq("PW.L/PW.L","benchmark") = PW.L/PW.L;
eq("PL.L/PW.L","benchmark") = PL.L/PW.L;
eq("PK.L/PW.L","benchmark") = PK.L/PW.L;
eq("CONS.L/PW.L","benchmark") = CONS.L/PW.L;

diff=10;
*CONS.FX = 200;

$INCLUDE M233.GEN
SOLVE M233 USING MCP;

eq("A.L","diff=10") = A.L;
eq("B.L","diff=10") = B.L;
eq("W.L","diff=10") = W.L;
eq("PX.L","diff=10") = PX.L;
eq("PY.L","diff=10") = PY.L;
eq("PW.L","diff=10") = PW.L;
eq("PL.L","diff=10") = PL.L;
eq("PK.L","diff=10") = PK.L;
eq("CONS.L","diff=10") = CONS.L;

eq("SAX.L","diff=10") = SAX.L/A.L;
eq("SAY.L","diff=10") = SAY.L/A.L;
eq("SBX.L","diff=10") = SBX.L/B.L;
eq("SBY.L","diff=10") = SBY.L/B.L;
eq("DAL.L","diff=10") = DAL.L/A.L;
eq("DAK.L","diff=10") = DAK.L/A.L;
eq("DBL.L","diff=10") = DBL.L/B.L;
eq("DBK.L","diff=10") = DBK.L/B.L;
eq("SW.L","diff=10") = SW.L;
eq("DWX.L","diff=10") = DWX.L;
eq("DWY.L","diff=10") = DWY.L;
eq("DW.L","diff=10") = DW.L;
eq("CWI.L","diff=10") = CWI.L;

eq("PX.L/PW.L","diff=10") = PX.L/PW.L;
eq("PY.L/PW.L","diff=10") = PY.L/PW.L;
eq("PW.L/PW.L","diff=10") = PW.L/PW.L;
eq("PL.L/PW.L","diff=10") = PL.L/PW.L;
eq("PK.L/PW.L","diff=10") = PK.L/PW.L;
eq("CONS.L/PW.L","diff=10") = CONS.L/PW.L;

PW.FX = 1;
$INCLUDE M233.GEN
SOLVE M233 USING MCP;

eq("A.L","PW.FX=1") = A.L;
eq("B.L","PW.FX=1") = B.L;     
eq("W.L","PW.FX=1") = W.L;
eq("PX.L","PW.FX=1") = PX.L;
eq("PY.L","PW.FX=1") = PY.L;
eq("PW.L","PW.FX=1") = PW.L;
eq("PL.L","PW.FX=1") = PL.L;
eq("PK.L","PW.FX=1") = PK.L;
eq("CONS.L","PW.FX=1") = CONS.L;

eq("SAX.L","PW.FX=1") = SAX.L/A.L;
eq("SAY.L","PW.FX=1") = SAY.L/A.L;
eq("SBX.L","PW.FX=1") = SBX.L/B.L;
eq("SBY.L","PW.FX=1") = SBY.L/B.L;
eq("DAL.L","PW.FX=1") = DAL.L/A.L;
eq("DAK.L","PW.FX=1") = DAK.L/A.L;
eq("DBL.L","PW.FX=1") = DBL.L/B.L;
eq("DBK.L","PW.FX=1") = DBK.L/B.L;
eq("SW.L","PW.FX=1") = SW.L;
eq("DWX.L","PW.FX=1") = DWX.L;
eq("DWY.L","PW.FX=1") = DWY.L;
eq("DW.L","PW.FX=1") = DW.L;
eq("CWI.L","PW.FX=1") = CWI.L;

eq("PX.L/PW.L","PW.FX=1") = PX.L/PW.L;
eq("PY.L/PW.L","PW.FX=1") = PY.L/PW.L;
eq("PW.L/PW.L","PW.FX=1") = PW.L/PW.L;
eq("PL.L/PW.L","PW.FX=1") = PL.L/PW.L;
eq("PK.L/PW.L","PW.FX=1") = PK.L/PW.L;
eq("CONS.L/PW.L","PW.FX=1") = CONS.L/PW.L;

* Counterfactual: 
tr_elas_A = 2;
tr_elas_B = 1.5;
$INCLUDE M233.GEN
SOLVE M233 USING MCP;
eq("A.L","TrA=2, TrB=1.5") = A.L;
eq("B.L","TrA=2, TrB=1.5") = B.L;
eq("W.L","TrA=2, TrB=1.5") = W.L;
eq("PX.L","TrA=2, TrB=1.5") = PX.L;
eq("PY.L","TrA=2, TrB=1.5") = PY.L;
eq("PW.L","TrA=2, TrB=1.5") = PW.L;
eq("PL.L","TrA=2, TrB=1.5") = PL.L;
eq("PK.L","TrA=2, TrB=1.5") = PK.L;
eq("CONS.L","TrA=2, TrB=1.5") = CONS.L;

eq("SAX.L","TrA=2, TrB=1.5") = SAX.L/A.L;
eq("SAY.L","TrA=2, TrB=1.5") = SAY.L/A.L;
eq("SBX.L","TrA=2, TrB=1.5") = SBX.L/B.L;
eq("SBY.L","TrA=2, TrB=1.5") = SBY.L/B.L;
eq("DAL.L","TrA=2, TrB=1.5") = DAL.L/A.L;
eq("DAK.L","TrA=2, TrB=1.5") = DAK.L/A.L;
eq("DBL.L","TrA=2, TrB=1.5") = DBL.L/B.L;
eq("DBK.L","TrA=2, TrB=1.5") = DBK.L/B.L;
eq("SW.L","TrA=2, TrB=1.5") = SW.L;
eq("DWX.L","TrA=2, TrB=1.5") = DWX.L;
eq("DWY.L","TrA=2, TrB=1.5") = DWY.L;
eq("DW.L","TrA=2, TrB=1.5") = DW.L;
eq("CWI.L","TrA=2, TrB=1.5") = CWI.L;

eq("PX.L/PW.L","TrA=2, TrB=1.5") = PX.L/PW.L;
eq("PY.L/PW.L","TrA=2, TrB=1.5") = PY.L/PW.L;
eq("PW.L/PW.L","TrA=2, TrB=1.5") = PW.L/PW.L;
eq("PL.L/PW.L","TrA=2, TrB=1.5") = PL.L/PW.L;
eq("PK.L/PW.L","TrA=2, TrB=1.5") = PK.L/PW.L;
eq("CONS.L/PW.L","TrA=2, TrB=1.5") = CONS.L/PW.L;


* Counterfactual: 10% tax on X sector inputs:
TA = 0.10;
$INCLUDE M233.GEN
SOLVE M233 USING MCP;
eq("A.L","TA=0.1") = A.L;
eq("B.L","TA=0.1") = B.L;
eq("W.L","TA=0.1") = W.L;
eq("PX.L","TA=0.1") = PX.L;
eq("PY.L","TA=0.1") = PY.L;
eq("PW.L","TA=0.1") = PW.L;
eq("PL.L","TA=0.1") = PL.L;
eq("PK.L","TA=0.1") = PK.L;
eq("CONS.L","TA=0.1") = CONS.L;

eq("SAX.L","TA=0.1") = SAX.L/A.L;
eq("SAY.L","TA=0.1") = SAY.L/A.L;
eq("SBX.L","TA=0.1") = SBX.L/B.L;
eq("SBY.L","TA=0.1") = SBY.L/B.L;
eq("DAL.L","TA=0.1") = DAL.L/A.L;
eq("DAK.L","TA=0.1") = DAK.L/A.L;
eq("DBL.L","TA=0.1") = DBL.L/B.L;
eq("DBK.L","TA=0.1") = DBK.L/B.L;
eq("SW.L","TA=0.1") = SW.L;
eq("DWX.L","TA=0.1") = DWX.L;
eq("DWY.L","TA=0.1") = DWY.L;
eq("DW.L","TA=0.1") = DW.L;
eq("CWI.L","TA=0.1") = CWI.L;

eq("PX.L/PW.L","TA=0.1") = PX.L/PW.L;
eq("PY.L/PW.L","TA=0.1") = PY.L/PW.L;
eq("PW.L/PW.L","TA=0.1") = PW.L/PW.L;
eq("PL.L/PW.L","TA=0.1") = PL.L/PW.L;
eq("PK.L/PW.L","TA=0.1") = PK.L/PW.L;
eq("CONS.L/PW.L","TA=0.1") = CONS.L/PW.L;

** Counterfactual: 100% tax on X sector inputs:
TA = 1.00;
$INCLUDE M233.GEN
SOLVE M233 USING MCP;
eq("A.L","TA=100%") = A.L;
eq("B.L","TA=100%") = B.L;
eq("W.L","TA=100%") = W.L;
eq("PX.L","TA=100%") = PX.L;
eq("PY.L","TA=100%") = PY.L;
eq("PW.L","TA=100%") = PW.L;
eq("PL.L","TA=100%") = PL.L;
eq("PK.L","TA=100%") = PK.L;
eq("CONS.L","TA=100%") = CONS.L;

eq("SAX.L","TA=100%") = SAX.L/A.L;
eq("SAY.L","TA=100%") = SAY.L/A.L;
eq("SBX.L","TA=100%") = SBX.L/B.L;
eq("SBY.L","TA=100%") = SBY.L/B.L;
eq("DAL.L","TA=100%") = DAL.L/A.L;
eq("DAK.L","TA=100%") = DAK.L/A.L;
eq("DBL.L","TA=100%") = DBL.L/B.L;
eq("DBK.L","TA=100%") = DBK.L/B.L;
eq("SW.L","TA=100%") = SW.L;
eq("DWX.L","TA=100%") = DWX.L;
eq("DWY.L","TA=100%") = DWY.L;
eq("DW.L","TA=100%") = DW.L;
eq("CWI.L","TA=100%") = CWI.L;

eq("PX.L/PW.L","TA=100%") = PX.L/PW.L;
eq("PY.L/PW.L","TA=100%") = PY.L/PW.L;
eq("PW.L/PW.L","TA=100%") = PW.L/PW.L;
eq("PL.L/PW.L","TA=100%") = PL.L/PW.L;
eq("PK.L/PW.L","TA=100%") = PK.L/PW.L;
eq("CONS.L/PW.L","TA=100%") = CONS.L/PW.L;


execute_unload "TwoxTwoMPSGECETTest.gdx" eq

*=== Write to variable levels to Excel file from GDX 
*=== If we do not specify a sheet, data is placed in first sheet
execute 'gdxxrw.exe TwoxTwoMPSGECETTest.gdx o=TwoxTwoScalarCETTest.xlsx par=eq rng=TwoxTwoCET-Scalar!'
execute 'gdxxrw.exe TwoxTwoMPSGECETTest.gdx o=MPSGEresults.xlsx par=eq rng=TwoxTwoCET-Scalar!'
execute 'gdxxrw.exe TwoxTwoMPSGECETTest.gdx o=C:\Users\Eli\.julia\dev\MPSGE\test\MPSGEresults.xlsx par=eq rng=TwoxTwoCET-Scalar!'


option decimals = 8; display eq;