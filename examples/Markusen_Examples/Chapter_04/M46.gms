$TITLE  Model M46: Small open economy model with a benchmark trade 
*  imbalance.
$ONTEXT
                Production Sectors                      Consumer
Markets   |     X1      X2      E1      M2      W       CONS
------------------------------------------------------------------
P1        |    150             -40             -110
P2        |             50              60     -110
PL        |   -100     -20                               120
PK        |    -50     -30                                80
PW        |                                     220     -220
PFX       |                     40     -60                20
------------------------------------------------------------------
$OFFTEXT
PARAMETERS
   PE2     Export price of good 2,
   PM1     Import price of good 1,
   PE1     Export price of good 1,
   PM2     Import price of good 2,
   TM2     Import tariff for good 2,
   BOPDEF  Balance of payments net deficit;
PE1 = 1;
PM2 = 1;
PE2 = 0.99;
PM1 = 1.01;
TM2 = 0;
$ONTEXT
$MODEL:M46
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
$PROD:X1 s:1
        O:P1    Q:150
        I:PL    Q:100
        I:PK    Q: 50
$PROD:X2 s:1
        O:P2    Q:50
        I:PL    Q:20
        I:PK    Q:30
$PROD:E1
        O:PFX   Q:(40*PE1)
        I:P1    Q:40
$PROD:M2
        O:P2    Q:60
        I:PFX   Q:(60*PM2)  A:CONS  T:TM2
$PROD:E2
        O:PFX   Q:(60*PE2)
        I:P2    Q:60
$PROD:M1
        O:P1    Q:40
        I:PFX   Q:(40*PM1)
$PROD:W  s:1
        O:PW    Q:220
        I:P1    Q:110
        I:P2    Q:110
$DEMAND:CONS
        D:PW    Q:220
        E:PL    Q:120
        E:PK    Q: 80
        E:PFX   Q:BOPDEF
$OFFTEXT
$SYSINCLUDE mpsgeset M46
E2.L = 0;
M1.L = 0;
E1.L = 1;
M2.L = 1;
BOPDEF = 20;
M46.ITERLIM = 0;
$INCLUDE M46.GEN
SOLVE M46 USING MCP;
M46.ITERLIM = 2000;
*   Compute a counterfactual experiment setting the deficit to zero.
BOPDEF = 0;
$INCLUDE M46.GEN
SOLVE M46 USING MCP;