$TITLE  Model M45: Small open economy model with a VER quota
$ONTEXT
In this example, units are chosen such that all DOMESTIC prices equal
one initially. 
                Production Sectors                  Consumer
Markets     |   X1      X2      E1      M2      W   CONSH  CONSF
------------------------------------------------------------------
P1          |  150             -50             -90           -10
P2          |           40              60    -100
PL          | -100     -20                            120
PK          |  -50     -20                             70
PW          |                                  190   -190
PFX         |                   50     -50
Q (ver rent)|                          -10                    10
------------------------------------------------------------------
$OFFTEXT
PARAMETERS
   PE2     Export price of good 2,
   PM1     Import price of good 1,
   PE1     Export price of good 1,
   PM2     Import price of good 2,
   TM2     Import tariff for good 2;
PE1 = 1;
PM2 = 1/(1.2);
PE2 = PM2*0.99;
PM1 = 1.01;
TM2 = 0.20;
$ONTEXT
$MODEL:M45
$SECTORS:
        X1      ! Production index for good 1
        X2      ! Production index good 2
        E1      ! Export level of good 1
        E2      ! Export level of good 2
        M1      ! Import level of good 1
        M2      ! Import level of good 2
        W       ! Welfare index 
$COMMODITIES:
        P1      ! Price index for good 1
        P2      ! Price index for good 1
        PFX     ! Read exchange rate index
        PW      ! Welfare price index
        PL      ! Wage index
        PK      ! Capital rental index
$CONSUMERS:
        CONSH   ! Income level for domestic consumer
        CONSF   ! Income level for foreign consumer (quota holder)
$AUXILIARY:
        V       ! Endogenous tax, shadow tax for VER
        Q       ! Endogenous tax, shadow tax for quota
$PROD:X1 s:1
        O:P1    Q:150
        I:PL    Q:100
        I:PK    Q: 50
$PROD:X2 s:1
        O:P2    Q:40
        I:PL    Q:20
        I:PK    Q:20
$PROD:E1
        O:PFX   Q:(50*PE1)
        I:P1    Q:50
$PROD:M2
        O:P2    Q:60 
        I:PFX   Q:(60*PM2)  A:CONSF  N:V  A:CONSH  N:Q
$PROD:E2
        O:PFX   Q:(60*PE2)
        I:P2    Q:60
$PROD:M1
        O:P1    Q:50
        I:PFX   Q:(50*PM1)
$PROD:W  s:1
        O:PW    Q:190
        I:P1    Q: 90
        I:P2    Q:100
$DEMAND:CONSH
        D:PW    Q:190
        E:PL    Q:120
        E:PK    Q: 70
$DEMAND:CONSF
        D:P1    Q:10
$CONSTRAINT:V
        1 =G= M2;
$CONSTRAINT:Q
        1 =G= M2;
$OFFTEXT
$SYSINCLUDE mpsgeset M45
PW.FX = 1;
E1.L = 1;
M2.L = 1;
E2.L = 0;
M1.L = 0;
V.L = 0.20;
Q.FX = 0;
M45.ITERLIM = 0;
$INCLUDE M45.GEN
SOLVE M45 USING MCP;
M45.ITERLIM = 2000;
*      Counterfactual: replace the VER with an auction quota
Q.LO = 0;
Q.UP = +INF;
V.FX = 0;
$INCLUDE M45.GEN
SOLVE M45 USING MCP;