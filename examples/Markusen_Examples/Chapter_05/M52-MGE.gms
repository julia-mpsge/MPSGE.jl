$TITLE  Model M52-MPS: Monopoly with IRTS - calibrated to zero profits
$ONTEXT
                  Production Sectors                Consumers
   Markets   |   X        N        Y        W    |  CONS
   ----------------------------------------------------------
        PX   | 100                       -100    |
        PY   |                   100     -100    |
        PF   |           20                      |   -20
        PU   |                            200    |  -200
        PW   | -32       -8      -60             |   100
        PZ   | -48      -12      -40             |   100
        MK   | -20                               |    20
$OFFTEXT
PARAMETERS
 SIGMA     Elasticity of substitution in demand,
 FCOST     Ratio of fixed costs to benchmark, 
 ENDOW     Level of factor endowment,
 INCOMEM   Income of the monopolist,
 INCOMEC   Inome of the factor owners;
SIGMA = 9;
FCOST = 1;
ENDOW = 1;
$ONTEXT
$MODEL:M52
$SECTORS:
        X       ! Activity level -- monopolist sector X
        Y       ! Activity level -- competitive sector Y
        W       ! Welfare index for the consumer
$COMMODITIES:
        PU      ! Welfare price index for the consumer
        PX      ! Price index for X (gross of markup)
        PY      ! Price index for Y (gross of markup)
        PW      ! Price index for labor
        PZ      ! Price index for capital
$CONSUMERS:
        CONS    ! All consumers

$AUXILIARY:
        SHAREX  ! Value share of X in total consumption
        MARKUP  ! Markup based on Marshallian demand
$PROD:X  s:1
        O:PX    Q: 80    A:CONS  N:MARKUP
        I:PW    Q: 32
        I:PZ    Q: 48
$PROD:Y  s:1
        O:PY    Q:100
        I:PW    Q: 60
        I:PZ    Q: 40
$PROD:W         s:sigma
        O:PU    Q:200
        I:PX    Q: 80   P:1.25
        I:PY    Q:100
$DEMAND:CONS
        D:PU    Q:200
        E:PW    Q:(100*ENDOW)
        E:PZ    Q:(100*ENDOW)
        E:PW    Q:(-8*FCOST)
        E:PZ    Q:(-12*FCOST)
$CONSTRAINT:SHAREX
        SHAREX*(80*PX*X + 100*PY*Y) =G= 80*PX*X;
$CONSTRAINT:MARKUP
        MARKUP =E= 1/(SIGMA - (SIGMA-1)*SHAREX);
$OFFTEXT
$SYSINCLUDE mpsgeset M52
*       Benchmark replication:
PX.L      = 1.25; 
SHAREX.L  = 0.5; 
MARKUP.L  = 0.20; 
$INCLUDE M52.GEN
SOLVE M52 USING MCP;
INCOMEM = W.L*((MARKUP.L*PX.L*X.L*80 - PW.L*8*FCOST - PZ.L*12*FCOST)/
            (PX.L*X.L*80 + PY.L*Y.L*100));
INCOMEC = W.L - INCOMEM;

DISPLAY INCOMEM, INCOMEC;
* counterfactual: marginal-cost pricing
MARKUP.FX = 0;
$INCLUDE M52.GEN
SOLVE M52 USING MCP;
INCOMEM = W.L*((MARKUP.L*PX.L*X.L*80 - PW.L*8*FCOST - PZ.L*12*FCOST)/
            (PX.L*X.L*80 + PY.L*Y.L*100));
INCOMEC = W.L - INCOMEM;
DISPLAY INCOMEM, INCOMEC;
* counterfactual: double the size of the economy
MARKUP.LO = -INF;
MARKUP.UP = INF;
ENDOW = 2;
$INCLUDE M52.GEN
SOLVE M52 USING MCP;
INCOMEM = W.L*((MARKUP.L*PX.L*X.L*80 - PW.L*8*FCOST - PZ.L*12*FCOST)/
            (PX.L*X.L*80 + PY.L*Y.L*100));
INCOMEC = W.L - INCOMEM;
DISPLAY INCOMEM, INCOMEC;
* counterfactual: cut the size of the economy by 25%
ENDOW = 0.75;
$INCLUDE M52.GEN
SOLVE M52 USING MCP;
INCOMEM = W.L*((MARKUP.L*PX.L*X.L*80 - PW.L*8*FCOST - PZ.L*12*FCOST)/
            (PX.L*X.L*80 + PY.L*Y.L*100));
INCOMEC = W.L - INCOMEM;
DISPLAY INCOMEM, INCOMEC;