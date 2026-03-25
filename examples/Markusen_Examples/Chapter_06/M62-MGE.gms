$TITLE: Model M62-MPS: Large-Group Monopolistic Competition, uses MPS/GE
$ONTEXT
                        Production Sectors           Consumers
   Markets   |   XI     X        N        Y        W    |  CONS   ENTR
----------------------------------------------------------------------
        PX   |        100                       -100    |
        CX   !  100  -100                               |
        PY   |                          100     -100    |
        PF   |                  20                      |          -20
        PU   |                                   200    |  -200
        PW   |  -32             -8      -60             |   100
        PZ   |  -48            -12      -40             |   100
        MK   |  -20                                     |           20
$OFFTEXT
PARAMETERS
  ENDOW  Size index for the economy
  INDEX  Price index for the X goods
  EP     Elasticity of substitution among X varieties;
ENDOW = 1;
EP = 5;

$ONTEXT
$MODEL:M62
$SECTORS:
        X       ! Activity level for sector X
        Y       ! Activity level for sector Y
        W       ! Activity level for sector W (Hicksian welfare index)
        N       ! Activity level for sector X fixed costs, no. of firms
        XI      ! Activity level -- marginal cost of X
$COMMODITIES:
        PX      ! Price index for commodity X (gross of markup)
        CX      ! Marginal cost index for commodity X (net markup)
        PY      ! Price index for commodity Y
        PW      ! Price index for unskilled labor
        PZ      ! Price index for skilled labor
        PF      ! Unit price of inputs to fixed cost
        PU      ! Price index for welfare (expenditure function)
$CONSUMERS:
        CONS    ! Income level for consumer CONS
        ENTRE   ! Entrepreneur (converts markup revenue to fixed cost)
$AUXILIARY:
        XQADJ   ! Quantity adjustment   (positive when X>1)
        XPADJ   ! X output subsidy rate (positive when X>1)
$PROD:X s:1
        O:PX    Q: 80   P:1.25   A:CONS  N:XPADJ  M:-1
        I:CX    Q: 80   P:1.25
$PROD:Y s:1
        O:PY    Q:100
        I:PW    Q: 60
        I:PZ    Q: 40
$PROD:XI s:1
        O:CX    Q: 80   A:ENTRE   T:0.20
        I:PW    Q: 32
        I:PZ    Q: 48
$PROD:N s:1
        O:PF    Q:20
        I:PZ    Q:12
        I:PW    Q: 8
$PROD:W s:1.0
        O:PU    Q:200
        I:PX    Q: 80   P:1.25
        I:PY    Q:100
$DEMAND:CONS
        D:PU    Q:200
        E:PW    Q:(100*ENDOW)
        E:PZ    Q:(100*ENDOW)
        E:PX    Q:80    R:XQADJ
$DEMAND: ENTRE
        D:PF    Q:20
$CONSTRAINT:XQADJ
        XQADJ =E= (N**(1/(EP-1)))*X - X;
$CONSTRAINT:XPADJ
        XPADJ =E= (N**(1/(EP-1))) - 1;
$OFFTEXT
$SYSINCLUDE mpsgeset M62


*       Adjust bounds so that the auxiliary variables can take on 
*       negative values:
XQADJ.LO = -INF;
XPADJ.LO = -INF;
*       Benchmark replication:
PY.FX = 1;
PX.L = 1.25; 
CX.L = 1.25;
$INCLUDE M62.GEN
SOLVE M62 USING MCP;
INDEX = (N.L*CX.L**(1-EP))**(1/(1-EP));
DISPLAY INDEX;
*       Counterfactual: expand the size of the economy
ENDOW = 2;
$INCLUDE M62.GEN
SOLVE M62 USING MCP;
INDEX = (N.L*CX.L**(1-EP))**(1/(1-EP));
DISPLAY INDEX;