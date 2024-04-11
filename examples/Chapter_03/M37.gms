$TITLE  Model M38: Closed 2x2 Economy - Steady State Capital Stock
$ONTEXT
                  Production Sectors         Consumers
   Markets   |    X     Y     K     W     |     CONS
   ------------------------------------------------------
        PX   |   100              -100    |
        PY   |         100        -100    |
        PW   |                     200    |     -200
        PL   |   -40   -60   -60          |      160
        PK   |  -120   -80    60          |      140
        SUB  |    60    40                |     -100
   ------------------------------------------------------
$OFFTEXT
PARAMETERS
   RHO     Time preference parameter,
   DELTA   Depreciation rate,
   TAU     Effective capital use tax (it is a subsidy, its < 0),
   KTAX    Tax on new capital production
   NEWCAP  New capital stock after counterfactual (= 1 initially);
RHO   = 0.4;
DELTA = 0.3;
TAU   = - (1 - DELTA) / (1 + RHO);
KTAX  = 0;
$ONTEXT
$MODEL:M37
$SECTORS:
        X       ! Activity level for sector X
        Y       ! Activity level for sector Y
        W       ! Activity level for sector W (Hicksian welfare index)
        K       ! Capital stock index
$COMMODITIES:
        PX      ! Price index for commodity X
        PY      ! Price index for commodity Y
        PL      ! Price index for primary factor L (net of tax)
        PK      ! Price index for primary factor K
        PW      ! Price index for welfare (expenditure function)

$CONSUMERS:
        CONS    ! Income level for consumer CONS
$AUXILIARY:
        KFORWRD  ! Capital stock from previous period
$PROD:X  s:1
        O:PX   Q:100
        I:PL   Q: 40
        I:PK   Q:120  P:0.5  A:CONS  T:TAU
$PROD:Y  s:1
        O:PY   Q:100
        I:PL   Q: 60
        I:PK   Q: 80  P:0.5  A:CONS  T:TAU
$PROD:K
        O:PK   Q:1    A:CONS  T:KTAX
        I:PL   Q:1
$PROD:W  s:1
        O:PW   Q:200
        I:PX   Q:100
        I:PY   Q:100
$DEMAND:CONS
        D:PW
        E:PL   Q:160
        E:PK   Q:1    R:KFORWRD
$CONSTRAINT:KFORWRD
        KFORWRD  =E= K * (1-DELTA) / DELTA;
$OFFTEXT
$SYSINCLUDE mpsgeset M37
K.L = 60;
KFORWRD.L = 140;
PW.FX = 1;
$INCLUDE M37.GEN
SOLVE M37 USING MCP;

*       Raise the rate of time preference from 0.4 to 0.6:
RHO = 0.6;
TAU = - (1 - DELTA) / (1 + RHO);
$INCLUDE M37.GEN
SOLVE M37 USING MCP;
NEWCAP = K.L/60;
DISPLAY NEWCAP;
*       Set rho back to 0.4, tax new capital at 0.20
RHO = 0.4;
TAU = - (1 - DELTA) / (1 + RHO);
KTAX = 0.20;
$INCLUDE M37.GEN
SOLVE M37 USING MCP;
NEWCAP = K.L/60;
DISPLAY NEWCAP;