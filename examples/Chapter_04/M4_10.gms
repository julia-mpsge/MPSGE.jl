$TITLE  Model M410: Capital imports (less than perfect elastic)
$ONTEXT
             Production Sectors                   Consumer
Markets  |   X1    X2    E1    M2    KM      W    CONSH   CONSF
----------------------------------------------------------------
P1       |  170         -70               -100
P2       |         50          50         -100
PL       | -120   -20                              140
PK       |  -50   -30                20             60
PW       |                                 200    -200
PFX      |               70   -50   -10                    -10
PR       |                          -10                     10
----------------------------------------------------------------
$OFFTEXT
PARAMETER
  TM2     Import tariff for good X2;
TM2 = 0;
$ONTEXT
$MODEL:M410
$SECTORS:
        X1      ! Production index for good 1
        X2      ! Production index good 2
        E1      ! Export index of good 1
        E2      ! Export index of good 2
        M1      ! Import level of good 1
        M2      ! Import level of good 2
        KM      ! Capital imports
        W       ! Welfare index 
$COMMODITIES:
        P1      ! Price index for good 1
        P2      ! Price index for good 1
        PFX     ! Read exchange rate index
        PW      ! Welfare price index
        PL      ! Wage index
        PK      ! Capital rental index
        PR      ! Rent which generates concavity in capital supply
$CONSUMERS:
        CONSH   ! Income level for representative home agent
        CONSF   ! Income level for representative foreign agent
$PROD:X1 s:1
        O:P1    Q:170
        I:PL    Q:120
        I:PK    Q: 50
$PROD:X2 s:1
        O:P2    Q:50
        I:PL    Q:20
        I:PK    Q:30
$PROD:E1 s:1
        O:PFX   Q:70
        I:P1    Q:70
$PROD:M2
        O:P2    Q:50
        I:PFX   Q:50   A:CONSH  T:TM2
$PROD:E2
        O:PFX   Q:(50*0.99)
        I:P2    Q:50
$PROD:M1
        O:P1    Q:50
        I:PFX   Q:(100*1.01)
$PROD:KM s:1
        O:PK    Q:20
        I:PFX   Q:10
        I:PR    Q:10
$PROD:W  s:1
        O:PW    Q:200
        I:P1    Q:100
        I:P2    Q:100
$DEMAND:CONSH
        D:PW    Q:200
        E:PL    Q:140
        E:PK    Q:60
$DEMAND:CONSF
        D:PFX   Q:10
        E:PR    Q:10
$OFFTEXT
$SYSINCLUDE mpsgeset M410
E2.L = 0;
M1.L = 0;
PW.FX = 1;
M410.ITERLIM = 0;
$INCLUDE M410.GEN
SOLVE M410 USING MCP;
M410.ITERLIM = 2000;
TM2 = 0.05;
$INCLUDE M410.GEN
SOLVE M410 USING MCP;
KM.FX = 1;
$INCLUDE M410.GEN
SOLVE M410 USING MCP;