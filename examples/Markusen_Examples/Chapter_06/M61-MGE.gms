$TITLE: Model M61-MPS: External Economies of Scale, MPS/GE version
$ONTEXT
The model is based on the benchmark social accounts for model M1-1:
                  Production Sectors          Consumers
   Markets   |    X       Y        W    |       CONS
   ------------------------------------------------------
        PX   |  100             -100    |
        PY   |          100     -100    |
        PU   |                   200    |       -200
        PW   |  -40     -60             |        100
        PZ   |  -60     -40             |        100
   ------------------------------------------------------
$OFFTEXT
PARAMETER
 ENDOW   Size index for the economy
 B       External economies parameter;
ENDOW = 1;
B = 0.2
$ONTEXT
$MODEL:M61
$SECTORS:
        X       ! Activity level for sector X
        Y       ! Activity level for sector Y
        W       ! Activity level for sector W (Hicksian welfare index)
$COMMODITIES:
        PX      ! Price index for commodity X
        PY      ! Price index for commodity Y
        PW      ! Price index for primary factor L
        PZ      ! Price index for primary factor S
        PU      ! Price index for welfare (expenditure function)
$CONSUMERS:
        CONS    ! Income level for consumer CONS
$AUXILIARY:
        XQADJ   ! Quantity adjustment   (positive when X>1)

        XPADJ   ! X output subsidy rate (positive when X>1)
$PROD: X s:1
        O:PX    Q:100  A:CONS  N:XPADJ M:-1
        I:PW    Q: 40
        I:PZ    Q: 60
$PROD: Y s:1
        O:PY    Q:100
        I:PW    Q: 60
        I:PZ    Q: 40
$PROD: W s:1
        O: PU   Q:200
        I: PX   Q:100
        I: PY   Q:100
$DEMAND:CONS
        D:PU    Q:200
        E:PW    Q:(ENDOW*100)
        E:PZ    Q:(ENDOW*100)
        E:PX    Q:100   R:XQADJ
$CONSTRAINT:XQADJ
        XQADJ =E= X**(1/(1-B)) - X;
$CONSTRAINT:XPADJ
        XPADJ * X =E= XQADJ;
$OFFTEXT
$SYSINCLUDE mpsgeset M61
*       Adjust bounds so that the auxiliary variables can take on 
*       negative values:
XQADJ.LO = -INF;
XPADJ.LO = -INF;
*       Benchmark replication
$INCLUDE M61.GEN
SOLVE M61 USING MCP;
*       Counterfactual: expand the size of the economy

ENDOW = 2;
$INCLUDE M61.GEN
SOLVE M61 USING MCP;
*       Counterfactual: contract the size of the economy
ENDOW = 0.8;
$INCLUDE M61.GEN
SOLVE M61 USING MCP;