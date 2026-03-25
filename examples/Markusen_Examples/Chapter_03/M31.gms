$TITLE  Model M31.GMS: Closed 2x2 Economy - Calibrate to an Existing Tax
$ONTEXT
                  Production Sectors         Consumers
   Markets   |    X       Y        W    |       CONS
   ------------------------------------------------------
        PX   |  100             -100    |
        PY   |          100     -100    |
        PW   |                   200    |       -200
        PL   |  -20     -60             |         80
        PK   |  -60     -40             |        100
        TAX  |  -20       0             |         20
   ------------------------------------------------------
$OFFTEXT
PARAMETERS
 TX      Proportional output tax on sector X,
 TY      Proportional output tax on sector Y,
 TLX     Ad-valorem tax on labor inputs to X,
 TKX     Ad-valorem tax on capital inputs to X;
$ONTEXT
$MODEL:M31
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
$PROD:X s:1
        O:PX    Q:100        A:CONS T:TX
        I:PL    Q: 20   P:2  A:CONS T:TLX
        I:PK    Q: 60        A:CONS T:TKX
$PROD:Y s:1
        O:PY    Q:100        A:CONS T:TY
        I:PL    Q: 60
        I:PK    Q: 40
$PROD:W s:1
        O:PW    Q:200
        I:PX    Q:100
        I:PY    Q:100
$DEMAND:CONS
        D:PW    Q:200
        E:PL    Q: 80
        E:PK    Q:100
$OFFTEXT
$SYSINCLUDE mpsgeset M31

PW.FX = 1;
TX  = 0;
TY  = 0;
TLX = 1;
TKX = 0;

$INCLUDE M31.GEN
SOLVE M31 USING MCP;

*       In the first counterfactual, we replace the tax on labor inputs
*       by a uniform tax on both factors:
TLX = 0.25;
TKX = 0.25;
TX  = 0;
TY  = 0;
$INCLUDE M31.GEN
SOLVE M31 USING MCP;
*       Now demonstrate that a 25% tax on all inputs is equivalent to a
*       20% tax on the output (or all outputs if more than one)
TLX = 0;
TKX = 0;
TX  = 0.2;
TY  = 0;

$INCLUDE M31.GEN
SOLVE M31 USING MCP;
*       Finally, demonstrate that a 20% tax on the X sector output is 
*       equivalent to a 25% subsidy on Y sector output (assumes that the
*       funds for the subsidy can be raised lump sum from the consumer!)
TKX = 0;
TLX = 0;
TX  = 0;
TY  = -0.25;
$INCLUDE M31.GEN
SOLVE M31 USING MCP;