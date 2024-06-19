$TITLE  Model M51-MPS.GMS: Closed 2x2 Economy, monopoly X producer
* MPS/GE version
$ONTEXT
                  Production Sectors     Consumers
   Markets   |   X      Y        W    |  CONS   ENTRE
   -------------------------------------------------
        PX   !  100           -100    |
        PY   |        100     -100    |
        PU   |                 200    |  -180     -20
        PW   |  -32   -60             |    92
        PZ   |  -48   -40             |    88
        MK   |  -20                   |            20
$offtext
SCALAR  SIGMA      Elasticity of substitution,
        INCOMEM    Monopoly profit (in welfare units),
        INCOMEC    factor owners' income;
SIGMA = 9;
$ONTEXT
$MODEL:M51
$SECTORS:
        X       ! Activity level for sector X
        Y       ! Activity level for sector Y
        W       ! Activity level for sector W (Hicksian welfare index)
$COMMODITIES:
        PX      ! Price index for commodity X
        PY      ! Price index for commodity Y
        PW      ! Price index for primary factor L (net of tax)
        PZ      ! Price index for primary factor K
        PU      ! Price index for welfare (expenditure function)
$CONSUMERS:
        CONS    ! Representative agent.
        ENTRE   ! Entreprenuer (monopolist)
$AUXILIARY:
        SHAREX  ! Value share of good X
        MARKUP  ! X sector markup on marginal cost

$PROD:X  s:1
        O:PX    Q: 80    A:ENTRE  N:MARKUP
        I:PW    Q: 32
        I:PZ    Q: 48
$PROD:Y  s:1
        O:PY    Q:100
        I:PW    Q:60
        I:PZ    Q:40
$PROD:W s:SIGMA
        O:PU    Q:200
        I:PX    Q:80  P:1.25
        I:PY    Q:100
$DEMAND:CONS
        D:PU     Q:180
        E:PW     Q:92
        E:PZ     Q:88
$DEMAND:ENTRE
D:PU     Q:20
$CONSTRAINT:SHAREX
        SHAREX =E= 80*PX*X / (80*PX*X + 100*PY*Y) ;
$CONSTRAINT:MARKUP
        MARKUP =E= 1/(SIGMA - (SIGMA-1)*SHAREX);
$OFFTEXT
$SYSINCLUDE mpsgeset M51
*       Benchmark replication:
PX.L     =  1.25;
SHAREX.L =  0.5;
MARKUP.L =  0.20;
PU.FX = 1;
$INCLUDE M51.GEN
SOLVE M51 USING MCP;
INCOMEM = W.L*(ENTRE.L/(ENTRE.L + CONS.L));
INCOMEC = W.L*(CONS.L/(ENTRE.L + CONS.L));
DISPLAY INCOMEM, INCOMEC;

*       Evaluate the potential gains from first-best (marginal
*       cost) pricing:
MARKUP.FX = 0;
$INCLUDE M51.GEN
SOLVE M51 USING MCP;
INCOMEM = W.L*(ENTRE.L/(ENTRE.L + CONS.L));
INCOMEC = W.L*(CONS.L/(ENTRE.L + CONS.L));
DISPLAY INCOMEM, INCOMEC;