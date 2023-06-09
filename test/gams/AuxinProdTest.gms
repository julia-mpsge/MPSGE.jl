$TITLE Model M2-3S: Closed 2x2 Economy -- Equal Yield Tax Reform

$ONTEXT

This model is a follow-up on model M2-2s where we considered some
income tax reform experiments.  Like that model, here we apply
taxes through activities which transform (supply) household owned
factors into production inputs.

The difference here is that we set up a model in which we can
do differential tax policy analysis --- holding the level of 
government revenue constant.  In order to keep things simple, we
continue to rebate tax revenue in lump-sum fashion.

This model introduces a fourth (and final) class of MPSGE unknown
(in addition to activity levels, commodity prices and income levels).
The new entity is called an "auxiliary variable".  In this model,
we use an auxiliary variable to endogenously alter the tax rate
in order to maintain an equal yield.

As in the previous model, the consumer owns 200 units of leisure, 
supplies 100 (LS) in the benchmark and retains 100 as leisure.  
Tax is applied to both labor and capital supply to the market.  
(The leisure margin is untaxed.)

Benchmark value flows:

                  Production Sectors                 Consumers
   Markets   |    A       B        W      TK   TK      CONS
   ----------------------------------------------------------
        PX   |  120             -120
        PY   |          120     -120           
        PW   |                   340                  -340
        PLS  |  -48     -72              120           
        PKS  |  -72     -48                      120   100
        PL   |                  -100    -100           200
        PK   |                                  -100
        TAX  |                           -20     -20    40 
   ---------------------------------------------------------

Activity TL transforms leisure into labor supply, and TK transforms
capital into capital supply.

In this example, we use the more traditional scaling in which 
all market prices are unity in the benchmark.

$OFFTEXT

*       Declare parameters to be used in setting up counter-factual
*       equilibria:

SCALAR  TXL     Labor income tax rate,
        TXK     Capital income tax rate;

$ONTEXT

$MODEL:M2_3S

$SECTORS:
        X       ! Activity level for sector X
        Y       ! Activity level for sector Y
        W       ! Activity level for sector W (Hicksian welfare index)
        TL      ! Supply activity for L
        TK      ! Supply activity for K

$COMMODITIES:
        PX      ! Price index for commodity X
        PY      ! Price index for commodity Y
        PL      ! Price index for primary factor L (net of tax)
        PK      ! Price index for primary factor K (net of tax)
        PLS     ! Price index for primary factor L (gross of tax)
        PKS     ! Price index for primary factor K (gross of tax)
        PW      ! Price index for welfare (expenditure function)

$CONSUMERS:
        CONS    ! Income level for consumer CONS

$AUXILIARY:
        TAU     ! Tax multiplier associated with equal yield constraint.

*       The P: fields shown here present the benchmark prices.
*       Strictly speaking, they could be omitted because the
*       marginal rate of substitution remains equal to unity when
*       the reference price of inputs are the same.

$PROD:X s:1
        O:PX   Q:120
        I:PLS  Q: 48
        I:PKS  Q: 72

$PROD:Y s:1
        O:PY   Q:120
        I:PLS  Q: 72
        I:PKS  Q: 48
$REPORT:
       v:SXX    O:PX   PROD:X
       v:DLSX   I:PLS  PROD:X
       v:DKSX   I:PKS  PROD:X
       v:SYY    O:PY   PROD:Y
       v:DLSY   I:PLS  PROD:Y
       v:DKSY   I:PKS  PROD:Y

*       The income tax applies to labor and capital supplies.

*       Notice that I've omitted the reference price for PL here --
*       the actual value is 1.2, but because there is only one input
*       we don't have to worry about specify the MRS!

*       The new syntax introduced here is the use of an eNdogenous
*       tax field (N:TAU) and Multiplier (M:TXL).  In this sector
*       the user cost of labor is given by:  PL (1 + TAU * TXL).

*       The value of TXL is exogenously specified, but the value of
*       TAU is determined within the model 

$PROD:TL
        O:PLS  Q:120
        I:PL   Q:100  A:CONS N:TAU  M:TXL

$PROD:TK
        O:PKS  Q:120
        I:PK   Q:100  A:CONS N:TAU  M:TXK

$PROD:W s:0.7  a:1
        O:PW   Q:340
        I:PX   Q:120  a:
        I:PY   Q:120  a:
        I:PL   Q:100

$DEMAND:CONS
        D:PW   Q:340
        E:PL   Q:200
        E:PK   Q:100
$REPORT:
       v:SLSTL    O:PLS   PROD:TL
       v:DLTL     I:PL   PROD:TL
       v:SKSTK    O:PKS   PROD:TK
       v:DKTK     I:PK   PROD:TK
       v:SWW      O:PW   PROD:W
       v:DXW      I:PX   PROD:W
       v:DYW      I:PY   PROD:W
       v:DLW      I:PL   PROD:W
       v:CWCONS   D:PW   DEMAND:CONS
       v:WCONS    W:CONS

*       The model-specification is complete, except that we must
*       specify the equal-yield constraint.  This is most easily
*       expressed by recognizing that government revenue equals the
*       difference between expenditure and factor incomes.  We 
*       specify a constraint stating that this value must remain
*       at the benchmark level:

$CONSTRAINT:TAU
        W * PW * 340 - PL * 200 - PK * 100  =E= 40 * (PX + PY)/2;

*       We multiply the benchmark tax revenue (40) by a weighted
*       average of X and Y prices.  This defines the revenue target in 
*       real terms -- assuming that government output requires
*       equal amounts of X and Y inputs.
$OFFTEXT

$SYSINCLUDE mpsgeset M2_3S
*       For historical reasons, the default value of auxiliary variables
*       is not unity but zero.  To replicate the benchmark, we must install
*       an initial value:
TAU.L = 1;
*       Benchmark replication:
TXL = 0.2;
TXK = 0.2;
M2_3S.ITERLIM = 0;
$INCLUDE M2_3S.GEN
SOLVE M2_3S USING MCP;

PARAMETER  SUMMARY  Consequences of tax reform;
SUMMARY("X","benchmark") = X.L;
SUMMARY("Y","benchmark") = Y.L;
SUMMARY("W","benchmark") = W.L;
SUMMARY("TL","benchmark") = TL.L;
SUMMARY("TK","benchmark") = TK.L;
SUMMARY("PX","benchmark") = PX.L;
SUMMARY("PY","benchmark") = PY.L;
SUMMARY("PW","benchmark") = PW.L;
SUMMARY("PL","benchmark") = PL.L;
SUMMARY("PK","benchmark") = PK.L;
SUMMARY("PKS","benchmark") = PKS.L;
SUMMARY("PLS","benchmark") = PLS.L;
SUMMARY("TAU","benchmark") = TAU.L;
SUMMARY("SXX","benchmark") = SXX.L/X.L;
SUMMARY("SYY","benchmark") = SYY.L/Y.L;
SUMMARY("SWW","benchmark") = SWW.L/W.L;
SUMMARY("SLSTL","benchmark") = SLSTL.L/TL.L;
SUMMARY("SKSTK","benchmark") = SKSTK.L/TK.L;
SUMMARY("DLSX","benchmark") = DLSX.L/X.L;
SUMMARY("DKSX","benchmark") = DKSX.L/X.L;
SUMMARY("DLSY","benchmark") = DLSY.L/Y.L;
SUMMARY("DKSY","benchmark") = DKSY.L/Y.L;
SUMMARY("DXW","benchmark") = DXW.L/W.L;
SUMMARY("DYW","benchmark") = DYW.L/W.L;
SUMMARY("DLW","benchmark") = DLW.L/W.L;
SUMMARY("DLTL","benchmark") = DLTL.L/TL.L;
SUMMARY("DKTK","benchmark") = DKTK.L/TK.L;
SUMMARY("CONS","benchmark") = CONS.L;
SUMMARY("CWCONS","benchmark") = CWCONS.L;
*SUMMARY("WCONS","benchmark") = WCONS.L;

*SUMMARY("TL/TK=3/5","Hicks EV%") = 100 * (W.L-1);
*SUMMARY("TL/TK=3/5","Real Wage%") = 100 * (PL.L/PW.L - 1);
*SUMMARY("TL/TK=3/5","TL")        = TAU.L * TXL;
*SUMMARY("TL/TK=3/5","TK")        = TAU.L * TXK;
*SUMMARY("TL/TK=3/5","Return %") = 100 * (PK.L/PW.L - 1);

M2_3S.ITERLIM = 2000;

*       Repeat our calculations subject to an equal yield constraint.
*       Here we fix the relative magnitude of the tax

TXL = 0.15;
TXK = 0.25;
$INCLUDE M2_3S.GEN
SOLVE M2_3S USING MCP;
SUMMARY("X","L.15,K.25") = X.L;
SUMMARY("Y","L.15,K.25") = Y.L;
SUMMARY("W","L.15,K.25") = W.L;
SUMMARY("TL","L.15,K.25") = TL.L;
SUMMARY("TK","L.15,K.25") = TK.L;
SUMMARY("PLS","L.15,K.25") = PLS.L;
SUMMARY("PKS","L.15,K.25") = PKS.L;
SUMMARY("PX","L.15,K.25") = PX.L;
SUMMARY("PY","L.15,K.25") = PY.L;
SUMMARY("PW","L.15,K.25") = PW.L;
SUMMARY("TAU","L.15,K.25") = TAU.L;
SUMMARY("SXX","L.15,K.25") = SXX.L/X.L;
SUMMARY("SYY","L.15,K.25") = SYY.L/Y.L;
SUMMARY("DLSX","L.15,K.25") = DLSX.L/X.L;
SUMMARY("DKSX","L.15,K.25") = DKSX.L/X.L;
SUMMARY("DLSY","L.15,K.25") = DLSY.L/Y.L;
SUMMARY("DKSY","L.15,K.25") = DKSY.L/Y.L;
SUMMARY("PL","L.15,K.25") = PL.L;
SUMMARY("PK","L.15,K.25") = PK.L;
SUMMARY("SLSTL","L.15,K.25") = SLSTL.L/TL.L;
SUMMARY("DLTL","L.15,K.25") = DLTL.L/TL.L;
SUMMARY("SKSTK","L.15,K.25") = SKSTK.L/TK.L;
SUMMARY("DKTK","L.15,K.25") = DKTK.L/TK.L;
SUMMARY("SWW","L.15,K.25") = SWW.L/W.L;
SUMMARY("DXW","L.15,K.25") = DXW.L/W.L;
SUMMARY("DYW","L.15,K.25") = DYW.L/W.L;
SUMMARY("DLW","L.15,K.25") = DLW.L/W.L;
SUMMARY("CWCONS","L.15,K.25") = CWCONS.L;
*SUMMARY("WCONS","L.15,K.25") = WCONS.L;
SUMMARY("CONS","L.15,K.25") = CONS.L;

*SUMMARY("TL/TK=3/5","Hicks EV%") = 100 * (W.L-1);
*SUMMARY("TL/TK=3/5","Real Wage%") = 100 * (PL.L/PW.L - 1);
*SUMMARY("TL/TK=3/5","TL")        = TAU.L * TXL;
*SUMMARY("TL/TK=3/5","TK")        = TAU.L * TXK;
*SUMMARY("TL/TK=3/5","Return %") = 100 * (PK.L/PW.L - 1);

TXL = 0.10;
TXK = 0.30;
$INCLUDE M2_3S.GEN
SOLVE M2_3S USING MCP;
SUMMARY("X","L.1,K.3") = X.L;
SUMMARY("Y","L.1,K.3") = Y.L;
SUMMARY("PLS","L.1,K.3") = PLS.L;
SUMMARY("PKS","L.1,K.3") = PKS.L;
SUMMARY("PX","L.1,K.3") = PX.L;
SUMMARY("PY","L.1,K.3") = PY.L;
SUMMARY("PW","L.1,K.3") = PW.L;
SUMMARY("TAU","L.1,K.3") = TAU.L;
SUMMARY("SXX","L.1,K.3") = SXX.L/X.L;
SUMMARY("SYY","L.1,K.3") = SYY.L/Y.L;
SUMMARY("DLSX","L.1,K.3") = DLSX.L/X.L;
SUMMARY("DKSX","L.1,K.3") = DKSX.L/X.L;
SUMMARY("DLSY","L.1,K.3") = DLSY.L/Y.L;
SUMMARY("DKSY","L.1,K.3") = DKSY.L/Y.L;
SUMMARY("TL","L.1,K.3") = TL.L;
SUMMARY("TK","L.1,K.3") = TK.L;
SUMMARY("W","L.1,K.3") = W.L;
SUMMARY("PL","L.1,K.3") = PL.L;
SUMMARY("PK","L.1,K.3") = PK.L;
SUMMARY("SLSTL","L.1,K.3") = SLSTL.L/TL.L;
SUMMARY("DLTL","L.1,K.3") = DLTL.L/TL.L;
SUMMARY("SKSTK","L.1,K.3") = SKSTK.L/TK.L;
SUMMARY("DKTK","L.1,K.3") = DKTK.L/TK.L;
SUMMARY("SWW","L.1,K.3") = SWW.L/W.L;
SUMMARY("DXW","L.1,K.3") = DXW.L/W.L;
SUMMARY("DYW","L.1,K.3") = DYW.L/W.L;
SUMMARY("DLW","L.1,K.3") = DLW.L/W.L;
SUMMARY("CWCONS","L.1,K.3") = CWCONS.L;
*SUMMARY("WCONS","L.1,K.3") = WCONS.L;
SUMMARY("CONS","L.1,K.3") = CONS.L;

*SUMMARY("TL/TK=1/3","Hicks EV%") = 100 * (W.L-1);
*SUMMARY("TL/TK=1/3","Real Wage%") = 100 * (PL.L/PW.L - 1);
*SUMMARY("TL/TK=1/3","Return %") = 100 * (PK.L/PW.L - 1);
*SUMMARY("TL/TK=1/3","TL")        = TAU.L * TXL;
*SUMMARY("TL/TK=1/3","TK")        = TAU.L * TXK;

TXL = 0.05;
TXK = 0.35;
$INCLUDE M2_3S.GEN
SOLVE M2_3S USING MCP;
SUMMARY("X","L.05,K.35") = X.L;
SUMMARY("Y","L.05,K.35") = Y.L;
SUMMARY("PLS","L.05,K.35") = PLS.L;
SUMMARY("PKS","L.05,K.35") = PKS.L;
SUMMARY("PX","L.05,K.35") = PX.L;
SUMMARY("PY","L.05,K.35") = PY.L;
SUMMARY("PW","L.05,K.35") = PW.L;
SUMMARY("TAU","L.05,K.35") = TAU.L;
SUMMARY("SXX","L.05,K.35") = SXX.L/X.L;
SUMMARY("SYY","L.05,K.35") = SYY.L/Y.L;
SUMMARY("DLSX","L.05,K.35") = DLSX.L/X.L;
SUMMARY("DKSX","L.05,K.35") = DKSX.L/X.L;
SUMMARY("DLSY","L.05,K.35") = DLSY.L/Y.L;
SUMMARY("DKSY","L.05,K.35") = DKSY.L/Y.L;
SUMMARY("TL","L.05,K.35") = TL.L;
SUMMARY("TK","L.05,K.35") = TK.L;
SUMMARY("W","L.05,K.35") = W.L;
SUMMARY("PL","L.05,K.35") = PL.L;
SUMMARY("PK","L.05,K.35") = PK.L;
SUMMARY("SLSTL","L.05,K.35") = SLSTL.L/TL.L;
SUMMARY("DLTL","L.05,K.35") = DLTL.L/TL.L;
SUMMARY("SKSTK","L.05,K.35") = SKSTK.L/TK.L;
SUMMARY("DKTK","L.05,K.35") = DKTK.L/TK.L;
SUMMARY("SWW","L.05,K.35") = SWW.L/W.L;
SUMMARY("DXW","L.05,K.35") = DXW.L/W.L;
SUMMARY("DYW","L.05,K.35") = DYW.L/W.L;
SUMMARY("DLW","L.05,K.35") = DLW.L/W.L;
SUMMARY("CWCONS","L.05,K.35") = CWCONS.L;
*SUMMARY("WCONS","L.05,K.35") = WCONS.L;
SUMMARY("CONS","L.05,K.35") = CONS.L;

*SUMMARY("TL/TK=1/7","Hicks EV%") = 100 * (W.L-1);
*SUMMARY("TL/TK=1/7","Real Wage%") = 100 * (PL.L/PW.L - 1);
*SUMMARY("TL/TK=1/7","Return %") = 100 * (PK.L/PW.L - 1);
*SUMMARY("TL/TK=1/7","TL")        = TAU.L * TXL;
*SUMMARY("TL/TK=1/7","TK")        = TAU.L * TXK;

TXL = 0.00;
TXK = 0.40;
$INCLUDE M2_3S.GEN
SOLVE M2_3S USING MCP;
SUMMARY("X","L.0,K.4") = X.L;
SUMMARY("Y","L.0,K.4") = Y.L;
SUMMARY("PLS","L.0,K.4") = PLS.L;
SUMMARY("PKS","L.0,K.4") = PKS.L;
SUMMARY("PX","L.0,K.4") = PX.L;
SUMMARY("PY","L.0,K.4") = PY.L;
SUMMARY("PW","L.0,K.4") = PW.L;
SUMMARY("TAU","L.0,K.4") = TAU.L;
SUMMARY("SXX","L.0,K.4") = SXX.L/X.L;
SUMMARY("SYY","L.0,K.4") = SYY.L/Y.L;
SUMMARY("DLSX","L.0,K.4") = DLSX.L/X.L;
SUMMARY("DKSX","L.0,K.4") = DKSX.L/X.L;
SUMMARY("DLSY","L.0,K.4") = DLSY.L/Y.L;
SUMMARY("DKSY","L.0,K.4") = DKSY.L/Y.L;
SUMMARY("TL","L.0,K.4") = TL.L;
SUMMARY("TK","L.0,K.4") = TK.L;
SUMMARY("W","L.0,K.4") = W.L;
SUMMARY("PL","L.0,K.4") = PL.L;
SUMMARY("PK","L.0,K.4") = PK.L;
SUMMARY("SLSTL","L.0,K.4") = SLSTL.L/TL.L;
SUMMARY("DLTL","L.0,K.4") = DLTL.L/TL.L;
SUMMARY("SKSTK","L.0,K.4") = SKSTK.L/TK.L;
SUMMARY("DKTK","L.0,K.4") = DKTK.L/TK.L;
SUMMARY("SWW","L.0,K.4") = SWW.L/W.L;
SUMMARY("DXW","L.0,K.4") = DXW.L/W.L;
SUMMARY("DYW","L.0,K.4") = DYW.L/W.L;
SUMMARY("DLW","L.0,K.4") = DLW.L/W.L;
SUMMARY("CWCONS","L.0,K.4") = CWCONS.L;
*SUMMARY("WCONS","L.0,K.4") = WCONS.L;
SUMMARY("CONS","L.0,K.4") = CONS.L;

*SUMMARY("TL=0","Hicks EV%") = 100 * (W.L-1);
*SUMMARY("TL=0","Real Wage%") = 100 * (PL.L/PW.L - 1);
*SUMMARY("TL=0","Return %") = 100 * (PK.L/PW.L - 1);
*SUMMARY("TL=0","TL")        = TAU.L * TXL;
*SUMMARY("TL=0","TK")        = TAU.L * TXK;

TXL = -0.05;
TXK = 0.45;
$INCLUDE M2_3S.GEN
SOLVE M2_3S USING MCP;
SUMMARY("X","L-.05,K.45") = X.L;
SUMMARY("Y","L-.05,K.45") = Y.L;
SUMMARY("PLS","L-.05,K.45") = PLS.L;
SUMMARY("PKS","L-.05,K.45") = PKS.L;
SUMMARY("PX","L-.05,K.45") = PX.L;
SUMMARY("PY","L-.05,K.45") = PY.L;
SUMMARY("PW","L-.05,K.45") = PW.L;
SUMMARY("TAU","L-.05,K.45") = TAU.L;
SUMMARY("SXX","L-.05,K.45") = SXX.L/X.L;
SUMMARY("SYY","L-.05,K.45") = SYY.L/Y.L;
SUMMARY("DLSX","L-.05,K.45") = DLSX.L/X.L;
SUMMARY("DKSX","L-.05,K.45") = DKSX.L/X.L;
SUMMARY("DLSY","L-.05,K.45") = DLSY.L/Y.L;
SUMMARY("DKSY","L-.05,K.45") = DKSY.L/Y.L;
SUMMARY("TL","L-.05,K.45") = TL.L;
SUMMARY("TK","L-.05,K.45") = TK.L;
SUMMARY("W","L-.05,K.45") = W.L;
SUMMARY("PL","L-.05,K.45") = PL.L;
SUMMARY("PK","L-.05,K.45") = PK.L;
SUMMARY("SLSTL","L-.05,K.45") = SLSTL.L/TL.L;
SUMMARY("DLTL","L-.05,K.45") = DLTL.L/TL.L;
SUMMARY("SKSTK","L-.05,K.45") = SKSTK.L/TK.L;
SUMMARY("DKTK","L-.05,K.45") = DKTK.L/TK.L;
SUMMARY("SWW","L-.05,K.45") = SWW.L/W.L;
SUMMARY("DXW","L-.05,K.45") = DXW.L/W.L;
SUMMARY("DYW","L-.05,K.45") = DYW.L/W.L;
SUMMARY("DLW","L-.05,K.45") = DLW.L/W.L;
SUMMARY("CWCONS","L-.05,K.45") = CWCONS.L;
*SUMMARY("WCONS","L-.05,K.45") = WCONS.L;
SUMMARY("CONS","L-.05,K.45") = CONS.L;

*SUMMARY("TL/TK=-1/7","Hicks EV%") = 100 * (W.L-1);
*SUMMARY("TL/TK=-1/7","Real Wage%") = 100 * (PL.L/PW.L - 1);
*SUMMARY("TL/TK=-1/7","Return %") = 100 * (PK.L/PW.L - 1);
*SUMMARY("TL/TK=-1/7","TL")        = TAU.L * TXL;
*SUMMARY("TL/TK=-1/7","TK")        = TAU.L * TXK;

option decimals=8;
DISPLAY SUMMARY;

execute_unload "M2_3S.gdx" SUMMARY

*=== Write to variable levels to Excel file from GDX 
*=== If we do not specify a sheet, data is placed in first sheet
execute 'gdxxrw.exe M2_3S.gdx o=MPSGEresults.xlsx par=SUMMARY rng=two_by_two_AuxinInput!'
execute 'gdxxrw.exe M2_3S.gdx o=C:\Users\Eli\.julia\dev\MPSGE\test\MPSGEresults.xlsx par=SUMMARY rng=two_by_two_AuxinInput!'
