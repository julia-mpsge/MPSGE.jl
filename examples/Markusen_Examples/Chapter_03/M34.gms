$TITLE  Model M34: Closed 2x2 Economy --  Public Provision
$ONTEXT
             Production Sectors              Consumers
Markets|    X    Y    G   W1   W2       CONS1   CONS2   GOVT
---------------------------------------------------------------
  PX   |  100            -70  -30
  PY   |       100       -30  -70 
  PG   |             50                                  -50
  PL   |  -50  -30  -20                    50      50
  PK   |  -30  -50  -20                    50      50
  TAX  |  -20  -20  -10                                   50
  PW1  |                  125            -125
  PW2  |                       125               -125
  PG1  |                  -25              25
  PG2  |                       -25                 25
---------------------------------------------------------------
$OFFTEXT
PARAMETERS
 TAX    Tax rate on factor inputs to all sectors;
$ONTEXT
$MODEL:M34
$SECTORS:
        X    ! Activity level for sector X
        Y    ! Activity level for sector Y
        G    ! Activity level for sector G  (public provision)
        W1   ! Activity level for sector W1 (consumer 1 welfare index)
        W2   ! Activity level for sector W2 (consumer 2 welfare index)
$COMMODITIES:
        PX   ! Price index for commodity X
        PY   ! Price index for commodity Y
        PG   ! Price index for commodity G(marginal cost of public output)
        PL   ! Price index for primary factor L (net of tax)
        PK   ! Price index for primary factor K
        PW1  ! Price index for welfare (consumer 1)
        PW2  ! Price index for welfare (consumer 2)
        PG1  ! Private valuation of the public good (consumer 1)
        PG2  ! Private valuation of the public good (consumer 2)
$CONSUMERS:
        CONS1   ! Consumer 1
        CONS2   ! Consumer 2
        GOVT    ! Government
$AUXILIARY:
        LGP     ! Level of government provision
$PROD:X  s:1
        O:PX    Q:100
        I:PL    Q: 50   P:1.25  A:GOVT  T:TAX
        I:PK    Q: 30   P:1.25  A:GOVT  T:TAX
$PROD:Y  s:1
        O:PY    Q:100
        I:PL    Q: 30   P:1.25  A:GOVT  T:TAX
        I:PK    Q: 50   P:1.25  A:GOVT  T:TAX
$PROD:G  s:1
        O:PG    Q: 50
        I:PL    Q: 20  P:1.25  A:GOVT  T:TAX
        I:PK    Q: 20  P:1.25  A:GOVT  T:TAX
$PROD:W1 s:1
        O:PW1   Q:125
        I:PX    Q: 70 
        I:PY    Q: 30
        I:PG1   Q: 50   P:0.5
$PROD:W2 s:1
        O:PW2   Q:125
        I:PX    Q: 30
        I:PY    Q: 70
        I:PG2   Q: 50   P:0.5
$DEMAND:GOVT
        D:PG
$DEMAND:CONS1
        D:PW1   Q:125
        E:PL    Q: 50
        E:PK    Q: 50
        E:PG1   Q: 50  R:LGP
$DEMAND:CONS2
        D:PW2   Q:125
        E:PL    Q: 50
        E:PK    Q: 50
        E:PG2   Q: 50  R:LGP
$CONSTRAINT:LGP
        LGP =E= G;
$OFFTEXT
$SYSINCLUDE mpsgeset M34
TAX = 0.25;
LGP.L = 1;
PG1.L = 0.5;
PG2.L = 0.5;
M34.ITERLIM = 0;
$INCLUDE M34.GEN
SOLVE M34 USING MCP;
M34.ITERLIM = 2000;
*    The following counterfactuals check that the original
*    benchmark is indeed an optimum by raising/lowering the tax
TAX = 0.20;
$INCLUDE M34.GEN
SOLVE M34 USING MCP;
TAX = 0.30;
$INCLUDE M34.GEN
SOLVE M34 USING MCP;