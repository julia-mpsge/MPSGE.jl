$TITLE: Model M63:  Two Country Large-Group Monopolistic Competition
*  uses MPS/GE
$ontext
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
UTILI                                   200        -200
UTILJ                                         200        -200
MKI                -10  -10                                      10   10
MKJ                -10  -10                                      10   10
$offtext
PARAMETERS
 ENDOWIL
 ENDOWJL
 ENDOWIS
 ENDOWJS
 TC
 SUBSIDY
 SIGMA
 REALWI
 REALWJ
 REALZI
 REALZJ; 
ENDOWIL = 1.;
ENDOWJL = 1.;
ENDOWIS = 1.;
ENDOWJS = 1.;
TC = 1;
SUBSIDY = 0;
SIGMA = 5;

$ONTEXT
$MODEL:M63
$SECTORS:
 WFI   WFJ
 XI
 XII
 XIJ
 XJ
 XJI
 XJJ
 YI    YJ
 NI    NJ
$COMMODITIES:
 PY
 PUI   PUJ
 WI    WJ
 ZI    ZJ
 PXII   PXJI   PXJJ   PXIJ
 PXI
 PXJ
 FCI   FCJ
$CONSUMERS:
 CONSI   CONSJ
 ENTI    ENTJ
$AUXILIARY:
 XQADJII
 XQADJJI
 XQADJJJ
 XQADJIJ
 XPADJI
 XPADJJ
$PROD:YI   s:1.0
 O:PY     Q:100.0
 I:WI     Q: 60.0
 I:ZI     Q: 40.0
$PROD:YJ   s:1.0
 O:PY     Q:100.0
 I:WJ     Q: 60.0
 I:ZJ     Q: 40.0
$PROD:XI  s:1.0

 O:PXI    Q:80.       A:ENTI  T:.20
 I:ZI     Q:48
 I:WI     Q:32
$PROD:XII
 O:PXII   Q:40.          A:CONSI   N:XPADJI  M:-1.0
 I:PXI    Q:40.
$PROD:XIJ
 O:PXIJ   Q:(40./TC)     A:CONSJ   N:XPADJI  M:-1.0
 I:PXI    Q:(40.)
$PROD:XJ  s:1.0
 O:PXJ    Q:80.       A:ENTJ  T:.20
 I:ZJ     Q:48
 I:WJ     Q:32
$PROD:XJI
 O:PXJI   Q:(40./TC)     A:CONSI   N:XPADJJ  M:-1.0
 I:PXJ    Q:(40.)
$PROD:XJJ
 O:PXJJ   Q:40.          A:CONSJ   N:XPADJJ  M:-1.0
 I:PXJ    Q:40.
$PROD:NI    s:1.0
 O:FCI    Q:20
 I:ZI     Q:12
 I:WI     Q:8
$PROD:NJ    s:1.0
 O:FCJ    Q:20
 I:ZJ     Q:12
 I:WJ     Q:8
$PROD:WFI  s:1.0  a:5.0
 O:PUI    Q:200.
 I:PXII   Q:40.    P:1.25   a:
 I:PXJI   Q:40     P:1.25   a:
 I:PY     Q:100.
$PROD:WFJ  s:1.0  a:5.0
 O:PUJ    Q:200.
 I:PXJJ   Q:40.    P:1.25   a:
 I:PXIJ   Q:40.    P:1.25   a:
 I:PY     Q:100.
$DEMAND:CONSI

 D:PUI
 E:WI     Q:(100*ENDOWIL)
 E:ZI     Q:(100*ENDOWIS) 
 E:PXII   Q:40  R:XQADJII
 E:PXJI   Q:40  R:XQADJJI
$DEMAND:CONSJ
 D:PUJ
 E:WJ     Q:(100*ENDOWJL)
 E:ZJ     Q:(100*ENDOWJS)
 E:PXIJ   Q:40  R:XQADJIJ
 E:PXJJ   Q:40  R:XQADJJJ
$DEMAND:ENTI
 D:FCI
$DEMAND:ENTJ
 D:FCJ
$CONSTRAINT:XQADJII
 XQADJII =E= (NI**(.25))*XII - XII;
$CONSTRAINT:XQADJJI
 XQADJJI =E= (NJ**(.25))*XJI/TC - XJI/TC;
$CONSTRAINT:XQADJJJ
 XQADJJJ =E= (NJ**(.25))*XJJ - XJJ;
$CONSTRAINT:XQADJIJ
 XQADJIJ =E= (NI**(.25))*XIJ/TC - XIJ/TC;
$CONSTRAINT:XPADJI
 XPADJI =E= NI**.25 - 1;
$CONSTRAINT:XPADJJ
 XPADJJ =E= NJ**.25 - 1;
$OFFTEXT
$SYSINCLUDE MPSGESET M63
XQADJII.LO = -INF;
XQADJIJ.LO = -INF;
XQADJJI.LO = -INF;
XQADJJJ.LO = -INF;
XPADJI.LO = -INF;
XPADJJ.LO = -INF;

PY.FX = 1;
PXII.L = 1.25;
PXIJ.L = 1.25;
PXJJ.L = 1.25;
PXJI.L = 1.25;
PXI.L = 1.25;
PXJ.L = 1.25;
XII.L = 1;
XIJ.L = 1;
XJJ.L = 1;
XJI.L = 1;
M63.ITERLIM = 5000;
OPTION LIMROW=0;
OPTION LIMCOL=0;
$OFFSYMLIST OFFSYMXREF OFFUELLIST OFFUELXREF
$INCLUDE M63.GEN
SOLVE M63 USING MCP;
*counterfactual: double size of world economy

ENDOWIL = 2;
ENDOWJL = 2;
ENDOWIS = 2;
ENDOWJS = 2;
$INCLUDE M63.GEN
SOLVE M63 USING MCP;


TC = 1.15;
ENDOWIL = 1;
ENDOWJL = 1;
ENDOWIS = 1;
ENDOWJS = 1;
$INCLUDE M63.GEN
SOLVE M63 USING MCP;



TC = 1.0;
ENDOWIL = 1.5;
ENDOWIS = 1.5;
ENDOWJL = .5;
ENDOWJS = .5;
$INCLUDE M63.GEN
SOLVE M63 USING MCP;



TC = 1.15;
ENDOWIL = 1.5;
ENDOWIS = 1.5;
ENDOWJL = 0.5;
ENDOWJS = 0.5;
$INCLUDE M63.GEN
SOLVE M63 USING MCP;



REALWI = WI.L/PUI.L;
REALWJ = WJ.L/PUJ.L;
REALZI = ZI.L/PUI.L;
REALZJ = ZJ.L/PUJ.L;
DISPLAY REALWI, REALWJ, REALZI, REALZJ;



ENDOWIL = 1.0;
ENDOWIS = 1.2;
ENDOWJL = 1.0;
ENDOWJS = 0.8;
$INCLUDE M63.GEN
SOLVE M63 USING MCP;

option DECIMALS = 8;

REALWI = WI.L/PUI.L;
REALWJ = WJ.L/PUJ.L;
REALZI = ZI.L/PUI.L;
REALZJ = ZJ.L/PUJ.L;
DISPLAY REALWI, REALWJ, REALZI, REALZJ;