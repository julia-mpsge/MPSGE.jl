$TITLE  Model M48: Large open economy model: large open economy
$ONTEXT
             Production Sectors                   Consumer
Markets  |   X1      X2      E1      M2      W    CONSH   CONSF
----------------------------------------------------------------
P1       |  150             -50           -100
P2       |           50              50   -100
PL       | -100     -20                            120
PK       |  -50     -30                             80
PW       |                                 200    -200
PFX      |                  100     -50                   -50
PR       |                  -50                            50
----------------------------------------------------------------
$OFFTEXT
PARAMETER
  TM2     Import tariff for good;
TM2 = 0;
$ONTEXT
$MODEL:M48
$SECTORS:
        X1      ! Production index for good 1
        X2      ! Production index good 2
        E1      ! Export index of good 1
        E2      ! Export index of good 2
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
        PR      ! Rent which generates the export demand function
$CONSUMERS:
        CONSH   ! Income level for representative home agent
        CONSF   ! Income level for representative foreign agent
$PROD:X1 s:1
        O:P1    Q:150
        I:PL    Q:100
        I:PK    Q: 50
$PROD:X2 s:1
        O:P2    Q:50
        I:PL    Q:20
        I:PK    Q:30
$PROD:E1 s:1
        O:PFX   Q:100
        I:P1    Q: 50
        I:PR    Q: 50
$PROD:M2
        O:P2    Q:50
        I:PFX   Q:50   A:CONSH  T:TM2
$PROD:E2
        O:PFX   Q:(50*0.99)
        I:P2    Q:50
$PROD:M1
        O:P1    Q:50
        I:PFX   Q:(100*1.01)
$PROD:W  s:1
        O:PW    Q:200
        I:P1    Q:100
        I:P2    Q:100
$DEMAND:CONSH
        D:PW    Q:200
        E:PL    Q:120
        E:PK    Q: 80
$DEMAND:CONSF
        D:PFX   Q:50
        E:PR    Q:50
$OFFTEXT
$SYSINCLUDE mpsgeset M48
E2.L = 0;
M1.L = 0;
M48.ITERLIM = 0;
$INCLUDE M48.GEN
SOLVE M48 USING MCP;
M48.ITERLIM = 2000;
*       Apply a tariff which improves the terms of trade and home
*       welfare:
TM2 = 0.05;
$INCLUDE M48.GEN
SOLVE M48 USING MCP;