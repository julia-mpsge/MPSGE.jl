$TITLE Model M233: Closed Economy 2x2 with Joint Production
* 2023-03-01: Don't mess with this. Make a copy or something if needed for experimentation.
* Generates results for "TWOBYTWO with Transformation Elasticities (macro version)" in test_twobytwo_macro
* Benchmark with s:0,0,0 t:0,0,0 , then diff=10, CONS.FX and PW.FX, *then* to s:1,1,1, tr combos
* *then* to s:0,0,0 again for the other tr combos, *then* s: 1.5,2,0.5 and tr combos
* All stable *except* the need to run s:0,0,0 t:0,0,0 **first**
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
sub_elas_A CES btw L and K in sector A /0/
* /1.5/
sub_elas_B CES btw L and K in sector B /0/
* /2/
sub_elas_W CES btw X and Y in welfare W /0/
*  /0.5/
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
 
$PROD:A s:sub_elas_A t:tr_elas_A     !test s:1.5 *t:0!
 O:PX Q:80
 O:PY Q:20
 I:PL Q:40.0 A:CONS T:TA
 I:PK Q:60.0 A:CONS T:TA

$PROD:B s:sub_elas_B  t:tr_elas_B ! s:1.5
 O:PX Q:(20+diff) ! 20       ! 
 O:PY Q:80
 I:PL Q:60       ! (60+diff) !
 I:PK Q:40

$PROD:W s:sub_elas_W t:0 !s:1.5
 O:PW Q: 200              !(200+diff) !200  !
 I:PX Q:(100+diff)       !100 !
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

*eq("PX.L/PW.L","benchmark") = PX.L/PW.L;
*eq("PY.L/PW.L","benchmark") = PY.L/PW.L;
*eq("PW.L/PW.L","benchmark") = PW.L/PW.L;
*eq("PL.L/PW.L","benchmark") = PL.L/PW.L;
*eq("PK.L/PW.L","benchmark") = PK.L/PW.L;
*eq("CONS.L/PW.L","benchmark") = CONS.L/PW.L;


diff = 10;
CONS.FX = 200;
PW.FX = 1;
M233.iterlim = 1000;
$INCLUDE M233.GEN
SOLVE M233 USING MCP;


eq("A.L","Sub=0Tr=0") = A.L;
eq("B.L","Sub=0Tr=0") = B.L;
eq("W.L","Sub=0Tr=0") = W.L;
eq("PX.L","Sub=0Tr=0") = PX.L;
eq("PY.L","Sub=0Tr=0") = PY.L;
eq("PW.L","Sub=0Tr=0") = PW.L;
eq("PL.L","Sub=0Tr=0") = PL.L;
eq("PK.L","Sub=0Tr=0") = PK.L;
eq("CONS.L","Sub=0Tr=0") = CONS.L;

eq("SAX.L","Sub=0Tr=0") = SAX.L/A.L;
eq("SAY.L","Sub=0Tr=0") = SAY.L/A.L;
eq("SBX.L","Sub=0Tr=0") = SBX.L/B.L;
eq("SBY.L","Sub=0Tr=0") = SBY.L/B.L;
eq("DAL.L","Sub=0Tr=0") = DAL.L/A.L;
eq("DAK.L","Sub=0Tr=0") = DAK.L/A.L;
eq("DBL.L","Sub=0Tr=0") = DBL.L/B.L;
eq("DBK.L","Sub=0Tr=0") = DBK.L/B.L;
eq("SW.L","Sub=0Tr=0") = SW.L/w.l;
eq("DWX.L","Sub=0Tr=0") = DWX.L/w.l;
eq("DWY.L","Sub=0Tr=0") = DWY.L/w.l;
eq("DW.L","Sub=0Tr=0") = DW.L;
eq("CWI.L","Sub=0Tr=0") = CWI.L;

*eq("PX.L/PW.L","Sub=0Tr=0") = PX.L/PW.L;
*eq("PY.L/PW.L","Sub=0Tr=0") = PY.L/PW.L;
*eq("PW.L/PW.L","Sub=0Tr=0") = PW.L/PW.L;
*eq("PL.L/PW.L","Sub=0Tr=0") = PL.L/PW.L;
*eq("PK.L/PW.L","Sub=0Tr=0") = PK.L/PW.L;
*eq("CONS.L/PW.L","Sub=0Tr=0") = CONS.L/PW.L;

PW.LO=0.0001;
PW.UP=inf;
sub_elas_A = 1;
sub_elas_B = 1;
sub_elas_W = 1;
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
eq("SW.L","diff=10") = SW.L/w.l;
eq("DWX.L","diff=10") = DWX.L/w.l;
eq("DWY.L","diff=10") = DWY.L/w.l;
eq("DW.L","diff=10") = DW.L;
eq("CWI.L","diff=10") = CWI.L;

*eq("PX.L/PW.L","diff=10") = PX.L/PW.L;
*eq("PY.L/PW.L","diff=10") = PY.L/PW.L;
*eq("PW.L/PW.L","diff=10") = PW.L/PW.L;
*eq("PL.L/PW.L","diff=10") = PL.L/PW.L;
*eq("PK.L/PW.L","diff=10") = PK.L/PW.L;
*eq("CONS.L/PW.L","diff=10") = CONS.L/PW.L;

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
eq("SW.L","PW.FX=1") = SW.L/w.l;
eq("DWX.L","PW.FX=1") = DWX.L/w.l;
eq("DWY.L","PW.FX=1") = DWY.L/w.l;
eq("DW.L","PW.FX=1") = DW.L;
eq("CWI.L","PW.FX=1") = CWI.L;

*eq("PX.L/PW.L","PW.FX=1") = PX.L/PW.L;
*eq("PY.L/PW.L","PW.FX=1") = PY.L/PW.L;
*eq("PW.L/PW.L","PW.FX=1") = PW.L/PW.L;
*eq("PL.L/PW.L","PW.FX=1") = PL.L/PW.L;
*eq("PK.L/PW.L","PW.FX=1") = PK.L/PW.L;
*eq("CONS.L/PW.L","PW.FX=1") = CONS.L/PW.L;


* Counterfactual: 
tr_elas_A = 2;
tr_elas_B = 1.5;
$INCLUDE M233.GEN
SOLVE M233 USING MCP;

eq("A.L","TA=2B=1.5") = A.L;
eq("B.L","TA=2B=1.5") = B.L;
eq("W.L","TA=2B=1.5") = W.L;
eq("PX.L","TA=2B=1.5") = PX.L;
eq("PY.L","TA=2B=1.5") = PY.L;
eq("PW.L","TA=2B=1.5") = PW.L;
eq("PL.L","TA=2B=1.5") = PL.L;
eq("PK.L","TA=2B=1.5") = PK.L;
eq("CONS.L","TA=2B=1.5") = CONS.L;

eq("SAX.L","TA=2B=1.5") = SAX.L/A.L;
eq("SAY.L","TA=2B=1.5") = SAY.L/A.L;
eq("SBX.L","TA=2B=1.5") = SBX.L/B.L;
eq("SBY.L","TA=2B=1.5") = SBY.L/B.L;
eq("DAL.L","TA=2B=1.5") = DAL.L/A.L;
eq("DAK.L","TA=2B=1.5") = DAK.L/A.L;
eq("DBL.L","TA=2B=1.5") = DBL.L/B.L;
eq("DBK.L","TA=2B=1.5") = DBK.L/B.L;
eq("SW.L","TA=2B=1.5") = SW.L/w.l;
eq("DWX.L","TA=2B=1.5") = DWX.L/w.l;
eq("DWY.L","TA=2B=1.5") = DWY.L/w.l;
eq("DW.L","TA=2B=1.5") = DW.L;
eq("CWI.L","TA=2B=1.5") = CWI.L;

*eq("PX.L/PW.L","TA=2B=1.5") = PX.L/PW.L;
*eq("PY.L/PW.L","TA=2B=1.5") = PY.L/PW.L;
*eq("PW.L/PW.L","TA=2B=1.5") = PW.L/PW.L;
*eq("PL.L/PW.L","TA=2B=1.5") = PL.L/PW.L;
*eq("PK.L/PW.L","TA=2B=1.5") = PK.L/PW.L;
*eq("CONS.L/PW.L","TA=2B=1.5") = CONS.L/PW.L;

** Counterfactual: 
tr_elas_A = 3;
tr_elas_B = 1;
$INCLUDE M233.GEN
SOLVE M233 USING MCP;

eq("A.L","TrA=3B=1") = A.L;
eq("B.L","TrA=3B=1") = B.L;
eq("W.L","TrA=3B=1") = W.L;
eq("PX.L","TrA=3B=1") = PX.L;
eq("PY.L","TrA=3B=1") = PY.L;
eq("PW.L","TrA=3B=1") = PW.L;
eq("PL.L","TrA=3B=1") = PL.L;
eq("PK.L","TrA=3B=1") = PK.L;
eq("CONS.L","TrA=3B=1") = CONS.L;

eq("SAX.L","TrA=3B=1") = SAX.L/A.L;
eq("SAY.L","TrA=3B=1") = SAY.L/A.L;
eq("SBX.L","TrA=3B=1") = SBX.L/B.L;
eq("SBY.L","TrA=3B=1") = SBY.L/B.L;
eq("DAL.L","TrA=3B=1") = DAL.L/A.L;
eq("DAK.L","TrA=3B=1") = DAK.L/A.L;
eq("DBL.L","TrA=3B=1") = DBL.L/B.L;
eq("DBK.L","TrA=3B=1") = DBK.L/B.L;
eq("SW.L","TrA=3B=1") = SW.L/w.l;
eq("DWX.L","TrA=3B=1") = DWX.L/w.l;
eq("DWY.L","TrA=3B=1") = DWY.L/w.l;
eq("DW.L","TrA=3B=1") = DW.L;
eq("CWI.L","TrA=3B=1") = CWI.L;

*eq("PX.L/PW.L","TrA=3B=1") = PX.L/PW.L;
*eq("PY.L/PW.L","TrA=3B=1") = PY.L/PW.L;
*eq("PW.L/PW.L","TrA=3B=1") = PW.L/PW.L;
*eq("PL.L/PW.L","TrA=3B=1") = PL.L/PW.L;
*eq("PK.L/PW.L","TrA=3B=1") = PK.L/PW.L;
*eq("CONS.L/PW.L","TrA=3B=1") = CONS.L/PW.L;

** Counterfactual: 
tr_elas_A = 1;
tr_elas_B = 1;
$INCLUDE M233.GEN
SOLVE M233 USING MCP;

eq("A.L","TrA/B=1") = A.L;
eq("B.L","TrA/B=1") = B.L;
eq("W.L","TrA/B=1") = W.L;
eq("PX.L","TrA/B=1") = PX.L;
eq("PY.L","TrA/B=1") = PY.L;
eq("PW.L","TrA/B=1") = PW.L;
eq("PL.L","TrA/B=1") = PL.L;
eq("PK.L","TrA/B=1") = PK.L;
eq("CONS.L","TrA/B=1") = CONS.L;

eq("SAX.L","TrA/B=1") = SAX.L/A.L;
eq("SAY.L","TrA/B=1") = SAY.L/A.L;
eq("SBX.L","TrA/B=1") = SBX.L/B.L;
eq("SBY.L","TrA/B=1") = SBY.L/B.L;
eq("DAL.L","TrA/B=1") = DAL.L/A.L;
eq("DAK.L","TrA/B=1") = DAK.L/A.L;
eq("DBL.L","TrA/B=1") = DBL.L/B.L;
eq("DBK.L","TrA/B=1") = DBK.L/B.L;
eq("SW.L","TrA/B=1") = SW.L/w.l;
eq("DWX.L","TrA/B=1") = DWX.L/w.l;
eq("DWY.L","TrA/B=1") = DWY.L/w.l;
eq("DW.L","TrA/B=1") = DW.L;
eq("CWI.L","TrA/B=1") = CWI.L;

*eq("PX.L/PW.L","TrA/B=1") = PX.L/PW.L;
*eq("PY.L/PW.L","TrA/B=1") = PY.L/PW.L;
*eq("PW.L/PW.L","TrA/B=1") = PW.L/PW.L;
*eq("PL.L/PW.L","TrA/B=1") = PL.L/PW.L;
*eq("PK.L/PW.L","TrA/B=1") = PK.L/PW.L;
*eq("CONS.L/PW.L","TrA/B=1") = CONS.L/PW.L;

** Counterfactual: Re-set with Cobb-Douglas substitution elasticities

*diff = 0;
sub_elas_A = 0;
sub_elas_B = 0;
sub_elas_W = 0;
*tr_elas_A = 0;
*tr_elas_B = 0;
*$INCLUDE M233.GEN
*M233.iterlim = 0;
*solve M233 using MCP;
*

**CONS.LO=0.0001;
**CONS.UP=INF;
*
* Counterfactual: s 0,0,0
*diff=10;
tr_elas_A = 2;
tr_elas_B = 1.5;
$INCLUDE M233.GEN
SOLVE M233 USING MCP;

eq("A.L","S0Tr2,1.5") = A.L;
eq("B.L","S0Tr2,1.5") = B.L;
eq("W.L","S0Tr2,1.5") = W.L;
eq("PX.L","S0Tr2,1.5") = PX.L;
eq("PY.L","S0Tr2,1.5") = PY.L;
eq("PW.L","S0Tr2,1.5") = PW.L;
eq("PL.L","S0Tr2,1.5") = PL.L;
eq("PK.L","S0Tr2,1.5") = PK.L;
eq("CONS.L","S0Tr2,1.5") = CONS.L;

eq("SAX.L","S0Tr2,1.5") = SAX.L/A.L;
eq("SAY.L","S0Tr2,1.5") = SAY.L/A.L;
eq("SBX.L","S0Tr2,1.5") = SBX.L/B.L;
eq("SBY.L","S0Tr2,1.5") = SBY.L/B.L;
eq("DAL.L","S0Tr2,1.5") = DAL.L/A.L;
eq("DAK.L","S0Tr2,1.5") = DAK.L/A.L;
eq("DBL.L","S0Tr2,1.5") = DBL.L/B.L;
eq("DBK.L","S0Tr2,1.5") = DBK.L/B.L;
eq("SW.L","S0Tr2,1.5") = SW.L/w.l;
eq("DWX.L","S0Tr2,1.5") = DWX.L/w.l;
eq("DWY.L","S0Tr2,1.5") = DWY.L/w.l;
eq("DW.L","S0Tr2,1.5") = DW.L;
eq("CWI.L","S0Tr2,1.5") = CWI.L;

*eq("PX.L/PW.L","S0Tr2,1.5") = PX.L/PW.L;
*eq("PY.L/PW.L","S0Tr2,1.5") = PY.L/PW.L;
*eq("PW.L/PW.L","S0Tr2,1.5") = PW.L/PW.L;
*eq("PL.L/PW.L","S0Tr2,1.5") = PL.L/PW.L;
*eq("PK.L/PW.L","S0Tr2,1.5") = PK.L/PW.L;
*eq("CONS.L/PW.L","S0Tr2,1.5") = CONS.L/PW.L;

* Counterfactual: s: 0,0,0
tr_elas_A = 3;
tr_elas_B = 1;
$INCLUDE M233.GEN
SOLVE M233 USING MCP;


eq("A.L","S0Tr=3,1") = A.L;
eq("B.L","S0Tr=3,1") = B.L;
eq("W.L","S0Tr=3,1") = W.L;
eq("PX.L","S0Tr=3,1") = PX.L;
eq("PY.L","S0Tr=3,1") = PY.L;
eq("PW.L","S0Tr=3,1") = PW.L;
eq("PL.L","S0Tr=3,1") = PL.L;
eq("PK.L","S0Tr=3,1") = PK.L;
eq("CONS.L","S0Tr=3,1") = CONS.L;

eq("SAX.L","S0Tr=3,1") = SAX.L/A.L;
eq("SAY.L","S0Tr=3,1") = SAY.L/A.L;
eq("SBX.L","S0Tr=3,1") = SBX.L/B.L;
eq("SBY.L","S0Tr=3,1") = SBY.L/B.L;
eq("DAL.L","S0Tr=3,1") = DAL.L/A.L;
eq("DAK.L","S0Tr=3,1") = DAK.L/A.L;
eq("DBL.L","S0Tr=3,1") = DBL.L/B.L;
eq("DBK.L","S0Tr=3,1") = DBK.L/B.L;
eq("SW.L","S0Tr=3,1") = SW.L/w.l;
eq("DWX.L","S0Tr=3,1") = DWX.L/w.l;
eq("DWY.L","S0Tr=3,1") = DWY.L/w.l;
eq("DW.L","S0Tr=3,1") = DW.L;
eq("CWI.L","S0Tr=3,1") = CWI.L;

*eq("PX.L/PW.L","S0Tr=3,1") = PX.L/PW.L;
*eq("PY.L/PW.L","S0Tr=3,1") = PY.L/PW.L;
*eq("PW.L/PW.L","S0Tr=3,1") = PW.L/PW.L;
*eq("PL.L/PW.L","S0Tr=3,1") = PL.L/PW.L;
*eq("PK.L/PW.L","S0Tr=3,1") = PK.L/PW.L;
*eq("CONS.L/PW.L","S0Tr=3,1") = CONS.L/PW.L;

* Counterfactual: s:0,0,0
tr_elas_A = 1;
tr_elas_B = 1;
$INCLUDE M233.GEN
SOLVE M233 USING MCP;

eq("A.L","Sub=0Tr=1") = A.L;
eq("B.L","Sub=0Tr=1") = B.L;
eq("W.L","Sub=0Tr=1") = W.L;
eq("PX.L","Sub=0Tr=1") = PX.L;
eq("PY.L","Sub=0Tr=1") = PY.L;
eq("PW.L","Sub=0Tr=1") = PW.L;
eq("PL.L","Sub=0Tr=1") = PL.L;
eq("PK.L","Sub=0Tr=1") = PK.L;
eq("CONS.L","Sub=0Tr=1") = CONS.L;

eq("SAX.L","Sub=0Tr=1") = SAX.L/A.L;
eq("SAY.L","Sub=0Tr=1") = SAY.L/A.L;
eq("SBX.L","Sub=0Tr=1") = SBX.L/B.L;
eq("SBY.L","Sub=0Tr=1") = SBY.L/B.L;
eq("DAL.L","Sub=0Tr=1") = DAL.L/A.L;
eq("DAK.L","Sub=0Tr=1") = DAK.L/A.L;
eq("DBL.L","Sub=0Tr=1") = DBL.L/B.L;
eq("DBK.L","Sub=0Tr=1") = DBK.L/B.L;
eq("SW.L","Sub=0Tr=1") = SW.L/w.l;
eq("DWX.L","Sub=0Tr=1") = DWX.L/w.l;
eq("DWY.L","Sub=0Tr=1") = DWY.L/w.l;
eq("DW.L","Sub=0Tr=1") = DW.L;
eq("CWI.L","Sub=0Tr=1") = CWI.L;

*eq("PX.L/PW.L","Sub=0Tr=1") = PX.L/PW.L;
*eq("PY.L/PW.L","Sub=0Tr=1") = PY.L/PW.L;
*eq("PW.L/PW.L","Sub=0Tr=1") = PW.L/PW.L;
*eq("PL.L/PW.L","Sub=0Tr=1") = PL.L/PW.L;
*eq("PK.L/PW.L","Sub=0Tr=1") = PK.L/PW.L;
*eq("CONS.L/PW.L","Sub=0Tr=1") = CONS.L/PW.L;

* Counterfactual: Re-set with  CES substitution elasticities
sub_elas_A = 1.5;
sub_elas_B = 2;
sub_elas_W = 0.5;
tr_elas_A = 0;
tr_elas_B = 0;

$INCLUDE M233.GEN
SOLVE M233 USING MCP;
eq("A.L","1.52,.5T0") = A.L;
eq("B.L","1.52,.5T0") = B.L;
eq("W.L","1.52,.5T0") = W.L;
eq("PX.L","1.52,.5T0") = PX.L;
eq("PY.L","1.52,.5T0") = PY.L;
eq("PW.L","1.52,.5T0") = PW.L;
eq("PL.L","1.52,.5T0") = PL.L;
eq("PK.L","1.52,.5T0") = PK.L;
eq("CONS.L","1.52,.5T0") = CONS.L;

eq("SAX.L","1.52,.5T0") = SAX.L/A.L;
eq("SAY.L","1.52,.5T0") = SAY.L/A.L;
eq("SBX.L","1.52,.5T0") = SBX.L/B.L;
eq("SBY.L","1.52,.5T0") = SBY.L/B.L;
eq("DAL.L","1.52,.5T0") = DAL.L/A.L;
eq("DAK.L","1.52,.5T0") = DAK.L/A.L;
eq("DBL.L","1.52,.5T0") = DBL.L/B.L;
eq("DBK.L","1.52,.5T0") = DBK.L/B.L;
eq("SW.L","1.52,.5T0") = SW.L/w.l;
eq("DWX.L","1.52,.5T0") = DWX.L/w.l;
eq("DWY.L","1.52,.5T0") = DWY.L/w.l;
eq("DW.L","1.52,.5T0") = DW.L;
eq("CWI.L","1.52,.5T0") = CWI.L;

*eq("PX.L/PW.L","1.52,.5T0") = PX.L/PW.L;
*eq("PY.L/PW.L","1.52,.5T0") = PY.L/PW.L;
*eq("PW.L/PW.L","1.52,.5T0") = PW.L/PW.L;
*eq("PL.L/PW.L","1.52,.5T0") = PL.L/PW.L;
*eq("PK.L/PW.L","1.52,.5T0") = PK.L/PW.L;
*eq("CONS.L/PW.L","1.52,.5T0") = CONS.L/PW.L;

* Counterfactual: s:1.5,2,0.5
tr_elas_A = 2;
tr_elas_B = 1.5;
$INCLUDE M233.GEN
SOLVE M233 USING MCP;
eq("A.L","S..T2,1.5") = A.L;
eq("B.L","S..T2,1.5") = B.L;
eq("W.L","S..T2,1.5") = W.L;
eq("PX.L","S..T2,1.5") = PX.L;
eq("PY.L","S..T2,1.5") = PY.L;
eq("PW.L","S..T2,1.5") = PW.L;
eq("PL.L","S..T2,1.5") = PL.L;
eq("PK.L","S..T2,1.5") = PK.L;
eq("CONS.L","S..T2,1.5") = CONS.L;

eq("SAX.L","S..T2,1.5") = SAX.L/A.L;
eq("SAY.L","S..T2,1.5") = SAY.L/A.L;
eq("SBX.L","S..T2,1.5") = SBX.L/B.L;
eq("SBY.L","S..T2,1.5") = SBY.L/B.L;
eq("DAL.L","S..T2,1.5") = DAL.L/A.L;
eq("DAK.L","S..T2,1.5") = DAK.L/A.L;
eq("DBL.L","S..T2,1.5") = DBL.L/B.L;
eq("DBK.L","S..T2,1.5") = DBK.L/B.L;
eq("SW.L","S..T2,1.5") = SW.L/w.l;
eq("DWX.L","S..T2,1.5") = DWX.L/w.l;
eq("DWY.L","S..T2,1.5") = DWY.L/w.l;
eq("DW.L","S..T2,1.5") = DW.L;
eq("CWI.L","S..T2,1.5") = CWI.L;

*eq("PX.L/PW.L","S..T2,1.5") = PX.L/PW.L;
*eq("PY.L/PW.L","S..T2,1.5") = PY.L/PW.L;
*eq("PW.L/PW.L","S..T2,1.5") = PW.L/PW.L;
*eq("PL.L/PW.L","S..T2,1.5") = PL.L/PW.L;
*eq("PK.L/PW.L","S..T2,1.5") = PK.L/PW.L;
*eq("CONS.L/PW.L","S..T2,1.5") = CONS.L/PW.L;


* Counterfactual: s:1.5,2,0.5
tr_elas_A = 3;
tr_elas_B = 1;
$INCLUDE M233.GEN
SOLVE M233 USING MCP;
eq("A.L","S...T3,1") = A.L;
eq("B.L","S...T3,1") = B.L;
eq("W.L","S...T3,1") = W.L;
eq("PX.L","S...T3,1") = PX.L;
eq("PY.L","S...T3,1") = PY.L;
eq("PW.L","S...T3,1") = PW.L;
eq("PL.L","S...T3,1") = PL.L;
eq("PK.L","S...T3,1") = PK.L;
eq("CONS.L","S...T3,1") = CONS.L;

eq("SAX.L","S...T3,1") = SAX.L/A.L;
eq("SAY.L","S...T3,1") = SAY.L/A.L;
eq("SBX.L","S...T3,1") = SBX.L/B.L;
eq("SBY.L","S...T3,1") = SBY.L/B.L;
eq("DAL.L","S...T3,1") = DAL.L/A.L;
eq("DAK.L","S...T3,1") = DAK.L/A.L;
eq("DBL.L","S...T3,1") = DBL.L/B.L;
eq("DBK.L","S...T3,1") = DBK.L/B.L;
eq("SW.L","S...T3,1") = SW.L/w.l;
eq("DWX.L","S...T3,1") = DWX.L/w.l;
eq("DWY.L","S...T3,1") = DWY.L/w.l;
eq("DW.L","S...T3,1") = DW.L;
eq("CWI.L","S...T3,1") = CWI.L;

*eq("PX.L/PW.L","S...T3,1") = PX.L/PW.L;
*eq("PY.L/PW.L","S...T3,1") = PY.L/PW.L;
*eq("PW.L/PW.L","S...T3,1") = PW.L/PW.L;
*eq("PL.L/PW.L","S...T3,1") = PL.L/PW.L;
*eq("PK.L/PW.L","S...T3,1") = PK.L/PW.L;
*eq("CONS.L/PW.L","S...T3,1") = CONS.L/PW.L;

* Counterfactual: s:1.5,2,0.5
tr_elas_A = 1;
tr_elas_B = 1;
$INCLUDE M233.GEN
SOLVE M233 USING MCP;
eq("A.L","S...T1,1") = A.L;
eq("B.L","S...T1,1") = B.L;
eq("W.L","S...T1,1") = W.L;
eq("PX.L","S...T1,1") = PX.L;
eq("PY.L","S...T1,1") = PY.L;
eq("PW.L","S...T1,1") = PW.L;
eq("PL.L","S...T1,1") = PL.L;
eq("PK.L","S...T1,1") = PK.L;
eq("CONS.L","S...T1,1") = CONS.L;

eq("SAX.L","S...T1,1") = SAX.L/A.L;
eq("SAY.L","S...T1,1") = SAY.L/A.L;
eq("SBX.L","S...T1,1") = SBX.L/B.L;
eq("SBY.L","S...T1,1") = SBY.L/B.L;
eq("DAL.L","S...T1,1") = DAL.L/A.L;
eq("DAK.L","S...T1,1") = DAK.L/A.L;
eq("DBL.L","S...T1,1") = DBL.L/B.L;
eq("DBK.L","S...T1,1") = DBK.L/B.L;
eq("SW.L","S...T1,1") = SW.L/w.l;
eq("DWX.L","S...T1,1") = DWX.L/w.l;
eq("DWY.L","S...T1,1") = DWY.L/w.l;
eq("DW.L","S...T1,1") = DW.L;
eq("CWI.L","S...T1,1") = CWI.L;

*eq("PX.L/PW.L","S...T1,1") = PX.L/PW.L;
*eq("PY.L/PW.L","S...T1,1") = PY.L/PW.L;
*eq("PW.L/PW.L","S...T1,1") = PW.L/PW.L;
*eq("PL.L/PW.L","S...T1,1") = PL.L/PW.L;
*eq("PK.L/PW.L","S...T1,1") = PK.L/PW.L;
*eq("CONS.L/PW.L","S...T1,1") = CONS.L/PW.L;
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
eq("SW.L","TA=0.1") = SW.L/w.l;
eq("DWX.L","TA=0.1") = DWX.L/w.l;
eq("DWY.L","TA=0.1") = DWY.L/w.l;
eq("DW.L","TA=0.1") = DW.L;
eq("CWI.L","TA=0.1") = CWI.L;

*eq("PX.L/PW.L","TA=0.1") = PX.L/PW.L;
*eq("PY.L/PW.L","TA=0.1") = PY.L/PW.L;
*eq("PW.L/PW.L","TA=0.1") = PW.L/PW.L;
*eq("PL.L/PW.L","TA=0.1") = PL.L/PW.L;
*eq("PK.L/PW.L","TA=0.1") = PK.L/PW.L;
*eq("CONS.L/PW.L","TA=0.1") = CONS.L/PW.L;

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
eq("SW.L","TA=100%") = SW.L/w.l;
eq("DWX.L","TA=100%") = DWX.L/w.l;
eq("DWY.L","TA=100%") = DWY.L/w.l;
eq("DW.L","TA=100%") = DW.L;
eq("CWI.L","TA=100%") = CWI.L;

*eq("PX.L/PW.L","TA=100%") = PX.L/PW.L;
*eq("PY.L/PW.L","TA=100%") = PY.L/PW.L;
*eq("PW.L/PW.L","TA=100%") = PW.L/PW.L;
*eq("PL.L/PW.L","TA=100%") = PL.L/PW.L;
*eq("PK.L/PW.L","TA=100%") = PK.L/PW.L;
*eq("CONS.L/PW.L","TA=100%") = CONS.L/PW.L;


execute_unload "TwoxTwoMPSGECETTest.gdx" eq

*=== Write to variable levels to Excel file from GDX 
*=== If we do not specify a sheet, data is placed in first sheet
*execute 'gdxxrw.exe TwoxTwoMPSGECETTest.gdx o=TwoxTwoScalarCETTest.xlsx par=eq rng=TwoxTwoCET-Scalar!'
execute 'gdxxrw.exe TwoxTwoMPSGECETTest.gdx o=MPSGEresults.xlsx par=eq rng=TwoxTwoCET-Scalar!'
execute 'gdxxrw.exe TwoxTwoMPSGECETTest.gdx o=C:\Users\Eli\.julia\dev\MPSGE\test\MPSGEresults.xlsx par=eq rng=TwoxTwoCET-Scalar!'


option decimals = 8; display eq;