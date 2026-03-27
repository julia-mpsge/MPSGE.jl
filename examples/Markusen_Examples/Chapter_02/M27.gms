$TITLE  Model M27: 2x2 Economy with Formal/Informal Labor Supply
$ONTEXT
Activity LS transforms leisure into formal and informal labor supplies.
LF and LI are "dummy" activities used to keep track of how much labor
is supplied to each market.
                  Production Sectors               Consumers
Markets   |    X       Y        W       LF     LI     LS  |    CONS
-------------------------------------------------------------------
     PX   |  100             -100                         | 
     PY   |          100     -100                         |
     PW   |                   200                         |    -200
     PLF  |  -40     -10               50                 |
     PLI  |          -50                       50         |
     PLSF |                           -50             50  | 
     PLSI |                                   -50     50  |
     PL   |                                         -100  |     100
     PK   |  -60     -40                                  |     100
   ----------------------------------------------------------------
$OFFTEXT
PARAMETERS
 TL;
TL = 0;
$ONTEXT
$MODEL:M27
$SECTORS:
        X       ! Activity level for sector X
        Y       ! Activity level for sector Y
        LS      ! Activity level for household labor supply
        LF      ! Activity for formal labor supply
        LI      ! Activity for informal labor supply
        W       ! Activity level for sector W (Hicksian welfare index)
$COMMODITIES:
        PX      ! Price index for commodity X
        PY      ! Price index for commodity Y
        PL      ! Price index for labor
        PLSF    ! Price index for formal labor supplied to market
        PLSI    ! Price index for informal labor supply to market
        PLF     ! Price index for formal labor supplied to firms
        PLI     ! Price index for informal labor supplied to firms
        PK      ! Price index for primary factor K
        PW      ! Price index for welfare (expenditure function)
$CONSUMERS:
        CONS    ! Income level for consumer CONS
$PROD:X s:1
        O:PX    Q:100
        I:PLF   Q: 40 
        I:PK    Q: 60 
$PROD:Y s:1  a:3
        O:PY    Q:100
        I:PLF   Q: 10  a:
        I:PLI   Q: 50  a:
        I:PK    Q: 40
$PROD:LS t:5.0
        O:PLSF  Q: 50
        O:PLSI  Q: 50
        I:PL    Q:100
$PROD:LF
        O:PLF   Q: 50
        I:PLSF  Q: 50  A:CONS T:TL
$PROD:LI
        O:PLI   Q: 50
        I:PLSI  Q: 50
$PROD:W s:1.0
        O:PW    Q:200
        I:PX    Q:100 
        I:PY    Q:100
$DEMAND:CONS
        D:PW    Q:200
        E:PL    Q:100
        E:PK    Q:100
$OFFTEXT
$SYSINCLUDE mpsgeset M27
PW.FX = 1;
$INCLUDE M27.GEN
SOLVE M27 USING MCP;

*       Solve a counter-factual, tax formal labor supply at 50%
TL = 0.5;
$INCLUDE M27.GEN
SOLVE M27 USING MCP;