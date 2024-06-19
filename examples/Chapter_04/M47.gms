$TITLE  Model M47: Small open economy model with an Armington 
*  formulation.
$ONTEXT
                Production Sectors                    Consumer
Markets   |     X1      X2      E       M        W       CONS
---------------------------------------------------------------
P1        |     150           -100      50     -100
P2        |             50     -25      75     -100
PL        |    -100    -20                               120
PK        |    -50     -30                                80
PW        |                                     200     -200
PFX       |                    125    -125
---------------------------------------------------------------
$OFFTEXT
PARAMETERS
   PE2     Export price of good 2,
   PM1     Import price of good 1,
   PE1     Export price of good 1,
   PM2     Import price of good 2,
   TM2     Import tariff for good 2,
   ESUB    Armington elasticity of substitution;
PE1 = 1;
PM2 = 1;
PE2 = 1;
PM1 = 1;
TM2 = 0;
ESUB = 4;
$ONTEXT
$MODEL:M47
$SECTORS:
        X1      ! Production index for good 1
        X2      ! Production index good 2
        E1      ! Export index for good 1
        E2      ! Export index for good 2
        M1      ! Import index for good 1
        M2      ! Import index for good 2
        W       ! Welfare index 
$COMMODITIES:
        P1      ! Price index for good 1
        P2      ! Price index for good 1
        PF1     ! Price index for imported good 1
        PF2     ! Price index for imported good 2
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
$PROD:X2 s:1
        O:P2    Q:50
        I:PL    Q:20
        I:PK    Q:30
*       We scale the export price for good 1 and the import price
*       for good 2 to both be unity:
$PROD:E1
        O:PFX   Q:(PE1*100)
        I:P1    Q:100
$PROD:E2
        O:PFX   Q:(PE2*25)
        I:P2    Q:25
$PROD:M1
        O:PF1   Q:50
        I:PFX   Q:(PM1*50)
$PROD:M2
        O:PF2   Q:75
        I:PFX   Q:(PM2*75)  A:CONS  T:TM2
$PROD:W  s:1  G1:ESUB  G2:ESUB
        O:PW    Q:200
        I:P1    Q: 50  G1:
        I:PF1   Q: 50  G1:
        I:P2    Q: 25  G2:
        I:PF2   Q: 75  G2:
$DEMAND:CONS
        D:PW    Q:200
        E:PL    Q:120
        E:PK    Q: 80
$OFFTEXT
$SYSINCLUDE mpsgeset M47
PW.FX = 1;
M47.ITERLIM = 0;
$INCLUDE M47.GEN
SOLVE M47 USING MCP;
M47.ITERLIM = 2000;
TM2 = 0.05;
$INCLUDE M47.GEN
SOLVE M47 USING MCP;
TM2 = 0.10;
$INCLUDE M47.GEN
SOLVE M47 USING MCP;