$TITLE: M54-MPS.GMS. Two country oligopoly model with free entry
*  uses MPS/GE
$ONTEXT
        YI   YJ     XI   XJ   NI   NJ    WI    WJ  CONI  CONJ  EHTI ENTJ
PYI    100                             -100
PYJ         100                              -100
PXI                100                  -50   -50
PXJ                     100             -50   -50
FCI                           20                                -20
FCJ                                20                                -20 
ZI     -40         -48       -12                    100
ZJ          -40         -48       -12                     100
WI     -60         -32        -8                    100
WJ          -60         -32        -8                     100
PUI                                     200        -200
PUJ                                           200        -200
MKI                -10  -10                                      10   10
MKJ                -10  -10                                      10   10
$OFFTEXT
PARAMETERS
 ENDOWIL
 ENDOWJL
 ENDOWIS
 ENDOWJS
 REALWI
 REALWJ
 REALZI
 REALZJ
 TC
 SUBSIDY;
TC = .0;
SUBSIDY = 0;
ENDOWIL = 1;
ENDOWJL = 1;
ENDOWIS = 1;
ENDOWJS = 1;
$ONTEXT
$MODEL:M54

$SECTORS:
 YI    YJ
 WFI   WFJ
 XI
 XII
 XIJ
 XJ
 XJI
 XJJ
 NI   NJ
$COMMODITIES:
 PY
 PUI   PUJ
 WI    WJ
 ZI    ZJ
 PXI   PXJ
 PXDI
 PXDJ
 FCI   FCJ
$CONSUMERS:
 CONSI   CONSJ
 ENTI    ENTJ
$AUXILIARY:
 MARKII
 MARKIJ
 MARKJI
 MARKJJ
$PROD:YI   s:1.0
 O:PY     Q:100.0
 I:WI     Q:60.0
 I:ZI     Q:40.0
$PROD:YJ   s:1.0
 O:PY     Q:100.0
 I:WJ     Q:60.0
 I:ZJ     Q:40.0
$PROD:XI   s:1
 O:PXDI   Q:80.
 I:WI     Q:32  A:CONSI  S:SUBSIDY
 I:ZI     Q:48  A:CONSI  S:SUBSIDY

$PROD:XII
 O:PXI    Q:40.    A:ENTI   N:MARKII
 I:PXDI   Q:40.
$PROD:XIJ s:0.0
 O:PXJ    Q:40.    A:ENTI   N:MARKIJ
 I:PXDI   Q:(40.*(1+TC))
$PROD:XJ   s:1
 O:PXDJ   Q:80.
 I:WJ     Q:32.
 I:ZJ     Q:48.
$PROD:XJI
 O:PXI    Q:40.    A:ENTJ   N:MARKJI
 I:PXDJ   Q:(40.*(1+TC))
$PROD:XJJ s:0.0
 O:PXJ    Q:40.    A:ENTJ   N:MARKJJ
 I:PXDJ   Q:40.
$PROD:NI   s:1
 O:FCI    Q:(20/2.5)
 I:WI     Q:(8/2.5)
 I:ZI     Q:(12/2.5)
$PROD:NJ   s:1
 O:FCJ    Q:(20/2.5)
 I:WJ     Q:(8/2.5)
 I:ZJ     Q:(12/2.5)
$PROD:WFI  s:1.0
 O:PUI    Q:200.
 I:PXI    Q:80.   P:1.25
 I:PY     Q:100.
$PROD:WFJ  s:1.0
 O:PUJ     Q:200.
 I:PXJ    Q:80.   P:1.25
 I:PY     Q:100.
$DEMAND:CONSI
 D:PUI    Q:200
 E:WI     Q:(100.*ENDOWIL)
 E:ZI     Q:(100.*ENDOWIS)

$DEMAND:CONSJ
 D:PUJ    Q:200
 E:WJ     Q:(100.*ENDOWJL)
 E:ZJ     Q:(100.*ENDOWJS)
$DEMAND:ENTI
 D:FCI    Q:20
$DEMAND:ENTJ
 D:FCJ    Q:20
$CONSTRAINT:MARKII
 MARKII*NI*(XII + XJI) =G= XII;
$CONSTRAINT:MARKIJ
 MARKIJ*NI*(XIJ + XJJ) =G= XIJ;
$CONSTRAINT:MARKJI
 MARKJI*NJ*(XII + XJI) =G= XJI;
$CONSTRAINT:MARKJJ
 MARKJJ*NJ*(XIJ + XJJ) =G= XJJ;
$OFFTEXT
$SYSINCLUDE MPSGESET M54
PXI.L = 1.25;
PXJ.L = 1.25;
MARKII.L = .2;
MARKJI.L = .2;
MARKIJ.L = .2;
MARKJJ.L = .2;
NI.L = 2.5;
NJ.L = 2.5;
PY.FX = 1.0;
NI.LO = 0.0001;
NJ.LO = 0.0001;
*OPTION SOLPRINT=OFF;
OPTION LIMROW=0;
OPTION LIMCOL=0;
$OFFSYMLIST OFFSYMXREF OFFUELLIST OFFUELXREF

$INCLUDE M54.GEN
SOLVE M54 USING MCP;
* counterfactual: trade costs of 15%
TC = 0.15;
$INCLUDE M54.GEN
SOLVE M54 USING MCP;
* counterfactual:  home production subsidy of 10%, trade costs 0
TC = 0.;
SUBSIDY = .10;
$INCLUDE M54.GEN
SOLVE M54 USING MCP;
* counterfactual: country's identical except for size,
* positive trade costs (home market advantage)
SUBSIDY = 0;
TC = 0.15;
ENDOWIL = 1.5;
ENDOWJL = 0.5;
ENDOWIS = 1.5;
ENDOWJS = 0.5;
$INCLUDE M54.GEN
SOLVE M54 USING MCP;
REALWI = WI.L/PUI.L;
REALWJ = WJ.L/PUJ.L;
REALZI = ZI.L/PUI.L;
REALZJ = ZJ.L/PUJ.L;
DISPLAY REALWI, REALWJ, REALZI, REALZJ;