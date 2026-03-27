$TITLE  Model M32: Closed 2x2 Economy --  income taxes and labor supply
$ONTEXT
                  Production Sectors                Consumers
   Markets   |    X       Y        W      TL   TK      CONS
   ----------------------------------------------------------
        PX   |  120             -120
        PY   |          120     -120
        PW   |                   340                  -340
        PLS  |  -48     -72              120
        PKS  |  -72     -48                      120
        PL   |                  -100    -100           200
        PK   |                                  -100   100
        TAX  |                           -20     -20    40 
   ---------------------------------------------------------
$OFFTEXT
*       Declare parameters to be used in setting up counter-factual
*       equilibria:
SETS S /1*5/;
PARAMETERS
  TXL         Labor income tax rate,
  TXK         Capital income tax rate,
  WELFARE(S)  Welfare,
  LABSUP(S)   Labor supply;
$ONTEXT
$MODEL:M32
$SECTORS:
        X       ! Activity level for sector X
        Y       ! Activity level for sector Y
        W       ! Activity level for sector W (Hicksian welfare index)
        TL      ! Supply activity for L
        TK      ! Supply activity for K
$COMMODITIES:
        PX      ! Price index for commodity X
        PY      ! Price index for commodity Y
        PL      ! Price index for primary factor L (net of tax)
        PK      ! Price index for primary factor K (net of tax)
        PLS     ! Price index for primary factor L (gross of tax)
        PKS     ! Price index for primary factor K (gross of tax)
        PW      ! Price index for welfare (expenditure function)
$CONSUMERS:
        CONS    ! Income level for consumer CONS
$PROD:X s:1
        O:PX   Q:120
        I:PLS  Q: 40  P:1.2
        I:PKS  Q: 60  P:1.2
$PROD:Y s:1
        O:PY   Q:120
        I:PLS  Q: 60  P:1.2
        I:PKS  Q: 40  P:1.2 
$PROD:TL
        O:PLS  Q:100  P:1.2
        I:PL   Q:100  P:1    A:CONS T:TXL
$PROD:TK
        O:PKS  Q:100  P:1.2
        I:PK   Q:100  P:1    A:CONS T:TXK
$PROD:W s:0.7  a:1
        O:PW   Q:340
        I:PX   Q:120  a:
        I:PY   Q:120  a:
        I:PL   Q:100
$DEMAND:CONS
        D:PW   Q:340
        E:PL   Q:200
        E:PK   Q:100
$OFFTEXT
$SYSINCLUDE mpsgeset M32
*       Benchmark replication:
TXL = 0.2;
TXK = 0.2;
PW.FX = 1;
PX.L =1.; PY.L =1.; PLS.L =1.2; PKS.L =1.2;

M32.ITERLIM = 0;
$INCLUDE M32.GEN
SOLVE M32 USING MCP;
M32.ITERLIM = 2000;
*       Lets do some counter-factual with taxes shifted to the
*       factor which is in fixed supply:
LOOP(S,
TXL = 0.25 - 0.05*ORD(S);
TXK = 0.15 + 0.05*ORD(S);
$INCLUDE M32.GEN
SOLVE M32 USING MCP;
WELFARE(S) = W.L;
LABSUP(S) = TL.L;
);
DISPLAY WELFARE, LABSUP;