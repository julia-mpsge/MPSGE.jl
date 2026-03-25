$TITLE  Model M44: Small open economy model with a (auction) quota
$ONTEXT
In this example, units are chosen such that all DOMESTIC prices equal
one initially.  Implied world prices are then P1/P2 = 1.2
                    Production Sectors                    Consumer
Markets       |     X1      X2      E1      M2      W       CONS
------------------------------------------------------------------
P1            |    150             -50            -100
P2            |             40              60    -100
PL            |   -100     -20                              120
PK            |    -50     -20                               70
PW            |                                    200     -200
PFX           |                     50     -50
Q (quota rent)|                            -10               10
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
$MODEL:M42
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
        CONS    ! Income level for representative agent
$AUXILIARY:
        Q
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
        I:PFX   Q:(60*PM2)  A:CONS  N:Q
$PROD:E2
        O:PFX   Q:(60*PE2)
        I:P2    Q:60
$PROD:M1
        O:P1    Q:50
        I:PFX   Q:(50*PM1)
$PROD:W  s:1
        O:PW    Q:200
        I:P1    Q:100
        I:P2    Q:100
$DEMAND:CONS
        D:PW    Q:200
        E:PL    Q:120
        E:PK    Q: 70
$CONSTRAINT:Q
        1 =G= M2;
$OFFTEXT
$SYSINCLUDE mpsgeset M42
PW.FX = 1;
E1.L = 1;
M2.L = 1;
E2.L = 0;
M1.L = 0;
Q.L = 0.20;
M42.ITERLIM = 0;
$INCLUDE M42.GEN
SOLVE M42 USING MCP;
M42.ITERLIM = 2000;
*       Counterfactual experiment is free trade
Q.FX = 0;
$INCLUDE M42.GEN
SOLVE M42 USING MCP;