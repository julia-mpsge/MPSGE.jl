$TITLE  Model M43: Small open economy model with a benchmark tariff.
* alternaive price normalization from M42
$ONTEXT
This model is equivalent to M42 except that units are chosen such
that all WORLD prices equal one initially.  The benchmark domestic price
ratio is then P2 = 1.2.
Note that this changes the units of measurement in good 2.  There are
now 83.3333 units of good 2 consumed instead of 100, but this is simply
a change in units of measure and has no welfare consequences.
                Production Sectors                    Consumer
Markets   |     X1      X2      E1      M2      W       CONS
------------------------------------------------------------------
P1        |     150            -50             -100
P2        |             40              60     -100
PL        |    -100    -20                               120
PK        |     -50    -20                                70
PW        |                                     200     -200
PFX       |                     50      -50
T         |                             -10               10
------------------------------------------------------------------
$OFFTEXT
PARAMETERS
   PE2     Export price of good 2,
   PM1     Import price of good 1,
   PE1     Export price of good 1,
   PM2     Import price of good 2,
   TM2     Import tariff for good 2;
PE1 = 1;
PM2 = 1;
PE2 = 0.99;
PM1 = 1.01;
TM2 = 0.20;
$ONTEXT
$MODEL:M43
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
*       Cobb-Douglas production in both sectors:
$PROD:X1 s:1
        O:P1    Q:150
        I:PL    Q:100
        I:PK    Q: 50
$PROD:X2  s:1
        O:P2    Q:33.33333  P:1.2
        I:PL    Q:20
        I:PK    Q:20
$PROD:E1
        O:PFX   Q:(50*PE1)
        I:P1    Q:50
$PROD:M2
        O:P2    Q:50
        I:PFX   Q:(50*PM2)  A:CONS  T:TM2
$PROD:E2
        O:PFX   Q:(50*PE2)
        I:P2    Q:(50)
$PROD:M1
        O:P1    Q:50
        I:PFX   Q:(50*PM1)
$PROD:W   s:1
        O:PW    Q:200
        I:P1    Q:100
        I:P2    Q:83.33333  P:1.2
$DEMAND:CONS
        D:PW    Q:200
        E:PL    Q:120
        E:PK    Q: 70
$OFFTEXT
$SYSINCLUDE mpsgeset M43
PW.FX = 1;
*       Benchmark replication
E1.L = 1;
M2.L = 1;
E2.L = 0;
M1.L = 0;
P2.L = 1.2;
M43.ITERLIM = 0;
$INCLUDE M43.GEN
SOLVE M43 USING MCP;
M43.ITERLIM = 2000;
*       Counterfactual experiment is free trade
TM2 = 0;
$INCLUDE M43.GEN
SOLVE M43 USING MCP;