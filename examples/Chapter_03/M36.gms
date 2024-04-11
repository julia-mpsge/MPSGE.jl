$TITLE  Model M36: Closed 2x2 Economy - Taxes and Classical Unemployment
$ONTEXT
                  Production Sectors         Consumers
   Markets   |    X       Y        W    |       CONS
   ------------------------------------------------------
        PX   |  100             -100    |
        PY   |          100     -100    |
        PW   |                   200    |       -200
        PL   |  -20     -60             |        100*(1-U)
        PK   |  -60     -40             |        100
        TAX  |  -20       0             |         20
   ------------------------------------------------------
$OFFTEXT
PARAMETERS
 TX      Proportional output tax on sector X,
 TY      Proportional output tax on sector Y,
 TLX     Ad-valorem tax on labor inputs to X,
 TKX     Ad-valorem tax on capital inputs to X,
 U0      Initial unemployment rate;
U0 = 0.20;
$ONTEXT
$MODEL:M36
$SECTORS:
        X       ! Activity level for sector X
        Y       ! Activity level for sector Y
        W       ! Activity level for sector W (Hicksian welfare index)
$COMMODITIES:
        PX      ! Price index for commodity X
        PY      ! Price index for commodity Y
        PL      ! Price index for primary factor L (net of tax)
        PK      ! Price index for primary factor K
        PW      ! Price index for welfare (expenditure function)
$CONSUMERS:
        CONS    ! Income level for consumer CONS
$AUXILIARY:
        U ! Unemployment rate
$PROD:X s:1
        O:PX    Q:100       A:CONS T:TX
        I:PL    Q: 20  P:2  A:CONS T:TLX
        I:PK    Q: 60       A:CONS T:TKX
$PROD:Y s:1
        O:PY    Q:100  T:TY
        I:PL    Q: 60
        I:PK    Q: 40
$PROD:W s:1
        O:PW    Q:200
        I:PX    Q:100
        I:PY    Q:100
$DEMAND:CONS
        D:PW    Q:200
        E:PL    Q:(80/(1-U0))
        E:PL    Q:(-80/(1-U0))  R:U
        E:PK    Q:100
$CONSTRAINT:U
PL =G= PW;
$OFFTEXT
$SYSINCLUDE mpsgeset M36
PW.FX = 1;
TX  = 0;
TY  = 0;
TLX = 1;
TKX = 0;
U.L = U0;
M36.ITERLIM = 0;
$INCLUDE M36.GEN
SOLVE M36 USING MCP;
M36.ITERLIM = 2000;
*       As in M31, we replace the tax on labor inputs
*       by a uniform tax on both factors:
TLX = 0.25;
TKX = 0.25;
TX  = 0;
TY  = 0;

$INCLUDE M36.GEN
SOLVE M36 USING MCP;
U.FX = 0.20;
$INCLUDE M36.GEN
SOLVE M36 USING MCP;