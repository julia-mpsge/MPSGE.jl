$TITLE  Model M53-MPS: Oligopoly with free entry, MPS/GE version
$ONTEXT
                  Production Sectors                Consumers
   Markets   |   X        N        Y        W    |  CONS   ENTRE
   ----------------------------------------------------------
        PX   | 100                       -100    |
        PY   |                   100     -100    |
        PF   |           20                      |           -20
        PU   |                            200    |  -200
        PW   | -32       -8      -60             |   100
        PZ   | -48      -12      -40             |   100
        MK   | -20                               |            20
$OFFTEXT
PARAMETERS
 SIGMA
 ENDOW;
SIGMA = 1;
ENDOW = 1;
$ONTEXT
$MODEL:M53
$SECTORS:
        X       ! Activity level - sector X output
        Y       ! Activity level - competitive sector Y
        W       ! Welfare index for the representative consumer
        N       ! Activity level - sector X fixed costs = no. of firms
$COMMODITIES:
        PU      ! Price index for representative agent utility
        PX      ! Price of good X (gross of markup)
        PY      ! Price of good Y
        PF      ! Unit price of inputs to fixed cost
        PW      ! Price index for labor
        PZ      ! Price index for capital
$CONSUMERS:
        CONS    ! Representative agent
        ENTRE   ! Entrepreneur (converts markup revenue to fixed cost)

$AUXILIARY:
        MARKUP  ! Optimal markup based on Marshallian demand elasticity
$PROD:X  s:1
        O:PX    Q: 80    A:ENTRE  N:MARKUP
        I:PW    Q: 32
        I:PZ    Q: 48
$PROD:Y  s:1
        O:PY    Q:100
        I:PW    Q: 60
        I:PZ    Q: 40
$PROD:N  s:1
        O:PF    Q: (20/5)
        I:PW    Q: (8/5)
        I:PZ    Q: (12/5)
$PROD:W s:1
        O:PU    Q:200
        I:PX    Q: 80   P:1.25
        I:PY    Q:100
$DEMAND:CONS
        D:PU    Q:200
        E:PW    Q:(ENDOW*100)
        E:PZ    Q:(ENDOW*100)
$DEMAND:ENTRE
        D:PF    Q: 20
$CONSTRAINT:MARKUP
        MARKUP*N =E= 1;
$OFFTEXT
$SYSINCLUDE mpsgeset M53
*       Benchmark replication:
N.L = 5;
PX.L = 1.25;
MARKUP.L = 0.20;
$INCLUDE M53.GEN
SOLVE M53 USING MCP;

*       Counterfactual double the size of economy.
ENDOW = 2;
$INCLUDE M53.GEN
SOLVE M53 USING MCP;