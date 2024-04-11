$TITLE  Model M32: Closed 2x2 Economy --  Equal Yield Tax Reform
$ONTEXT
                  Production Sectors                Consumers
   Markets   |    A       B        W      TL   TK      CONS
   ----------------------------------------------------------
        PX   |  120             -120
        PY   |          120     -120
        PW   |                   340                  -340
        PLS  |  -48     -72              120
        PKS  |  -72     -48                      120   100
        PL   |                  -100    -100           200
        PK   |                                  -100
        TAX  |                           -20     -20    40 
   ---------------------------------------------------------
$OFFTEXT
SETS S /1*5/;
PARAMETERS
  TXL         Labor income tax rate,
  WELFARE(S)  Welfare,
  REALCONS(S) Real consumption of goods,
  LABSUP(S)   Labor supply,
  CAPTAX(S)   Capital tax rate;
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
$AUXILIARY:
        TXK     ! Endogenous capital tax from equal yield constraint.
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
        I:PL   Q:100  A:CONS T:TXL
$PROD:TK
        O:PKS  Q:100  P:1.2
        I:PK   Q:100  A:CONS N:TXK
$PROD:W s:0.7  a:1
        O:PW   Q:340
        I:PX   Q:120  a:
        I:PY   Q:120  a:
        I:PL   Q:100
$DEMAND:CONS
        D:PW   Q:340
        E:PL   Q:200
        E:PK   Q:100
$CONSTRAINT:TXK
  TXL*PL*TL*100 + TXK*PK*TK*100  =E= 40 * (PX + PY)/2;
$OFFTEXT
$SYSINCLUDE mpsgeset M32
TXL = 0.20;
TXK.L = 0.20;

PLS.L = 1.2;
PKS.L = 1.2;
M32.ITERLIM = 0;
$INCLUDE M32.GEN
SOLVE M32 USING MCP;
M32.ITERLIM = 2000;
LOOP(S,
TXL = 0.25 - 0.05*ORD(S);
$INCLUDE M32.GEN
SOLVE M32 USING MCP;
WELFARE(S) = W.L;
REALCONS(S) = (PX.L*X.L*120 + PY.L*Y.L*120)
               /(PX.L**0.5*PY.L**0.5*240);
LABSUP(S) = TL.L;
CAPTAX(S) = TXK.L;
);
DISPLAY WELFARE, REALCONS, LABSUP, CAPTAX;
