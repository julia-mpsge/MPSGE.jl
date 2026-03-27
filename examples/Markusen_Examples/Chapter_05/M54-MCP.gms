$TITLE  Model M54-MCP: Two-Country Oligopoly with free entry
* MCP version
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
 ENDOWIS
 ENDOWJL
 ENDOWJS
 TC
 SUBSIDY
 MODELSTAT
 REALWI
 REALWJ
 REALZI
 REALZJ;
ENDOWIL = 1;
ENDOWIS = 1;
ENDOWJL = 1;
ENDOWJS = 1;
TC = 0;
SUBSIDY = 0;

POSITIVE VARIABLES
 YI
 YJ
 WFI
 WFJ
 XI
 XII
 XIJ
 XJ
 XJJ
 XJI
 NI
 NJ
 PY
 PUI 
 PUJ
 WI
 WJ
 ZI
 ZJ
 PXI
 PXJ
 PXDI
 PXDJ
 PFI
 PFJ
 CONSI
 CONSJ
 ENTI
 ENTJ
 MARKII
 MARKIJ
 MARKJI
 MARKJJ;
EQUATIONS
DXDI        X output in country i
DXI         Demand for X in country i
DXDJ        X output in country j
DXJ         Demand for X in country j
DY          Demand for Y
DWI         Demand for welfare in country i
DWJ         Demand for welfare in country j
DFI         Demand for fixed costs in i
DFJ         Demand for fixed costs in j
PRXDI       Marginal cost of X in i

PRXII       MR = MC for XII
PRXIJ       MR = MC for XIJ
PRXDJ       Marginal cost of X in j
PRXJJ       MR = MC for Xjj
PRXJI       MR = MC for Xji
PRYI        Zero profits for YI
PRYJ        Zero profits for YJ
PRWI        Zero profits for WFI
PRWJ        Zero profits for WFJ
PRFI        Zero profits for FI
PRFJ        Zero profits for FJ
SKLABI      Market clearing for SI
SKLABJ      Market clearing for SJ
UNLABI      Market clearing for LI
UNLABJ      Market clearing for LJ
ICONSI      Consumer income in i
ICONSJ      Consumer income in j
IENTREI     Entreprenuer's income (markups) in i
IENTREJ     Entrepreneur's income (markups) in j
MKII        Markup ii
MKIJ        Markup ij
MKJJ        Markup jj
MKJI        Markup ji;
PRXDI..   (WI**0.40)*(ZI**0.60)*(1-SUBSIDY) =G= PXDI;
PRXDJ..   (WJ**0.40)*(ZJ**0.60) =G= PXDJ;
PRXII..   PXDI =G= PXI*(1 - MARKII);
PRXIJ..   PXDI*(1+TC) =G= PXJ*(1 - MARKIJ);
PRXJJ..   PXDJ =G= PXJ*(1 - MARKJJ);
PRXJI..   PXDJ*(1+TC) =G= PXI*(1 - MARKJI);
PRYI..   (WI**0.60)*(ZI**0.40) =G= PY;
PRYJ..   (WJ**0.60)*(ZJ**0.40) =G= PY;
PRWI..   ((PXI/1.25)**0.5)*(PY**0.5) =G= PUI; 
PRWJ..   ((PXJ/1.25)**0.5)*(PY**0.5) =G= PUJ;
PRFI..   (WI**0.40)*(ZI**0.60) =G= PFI;
PRFJ..   (WJ**0.40)*(ZJ**0.60) =G= PFJ;

DXDI..   XII*40 + XIJ*40*(1+TC) =E= XI*80;
DXDJ..   XJJ*40 + XJI*40*(1+TC) =E= XJ*80;
DXI..    (XII*40 + XJI*40) =E= 0.5*CONSI/PXI;
DXJ..    (XJJ*40 + XIJ*40) =E= 0.5*CONSJ/PXJ;
DY..     (YI + YJ)*100 =E= 0.5*(CONSI + CONSJ)/PY;
DWI..    WFI*200 =E= CONSI/PUI;
DWJ..    WFJ*200 =E= CONSJ/PUJ;
DFI..    NI*8 =G= ENTI/PFI;
DFJ..    NJ*8 =G= ENTJ/PFJ;
SKLABI.. 100*ENDOWIS =E= 0.40*(WI**0.60)*(ZI**(0.40-1))*YI*100
          + 0.60*(WI**0.40)*(ZI**(0.60-1))*(XII+XIJ*(1+TC))*40 
  + 0.60*(WI**0.40)*(ZI**(0.60-1))*NI*8;
SKLABJ.. 100*ENDOWJS =E= 0.40*(WJ**0.60)*(ZJ**(0.40-1))*YJ*100
          + 0.60*(WJ**0.40)*(ZJ**(0.60-1))*(XJJ+XJI*(1+TC))*40 
  + 0.60*(WJ**0.40)*(ZJ**(0.60-1))*NJ*8;
UNLABI.. 100*ENDOWIL =E= 0.60*(WI**(0.60-1))*(ZI**0.40)*YI*100
          + 0.40*(WI**(0.40-1))*(ZI**0.60)*(XII+XIJ*(1+TC))*40 
          + 0.40*(WI**(0.40-1))*(ZI**0.60)*NI*8;
UNLABJ.. 100*ENDOWJL =E= 0.60*(WJ**(0.60-1))*(ZJ**0.40)*YJ*100
          + 0.40*(WJ**(0.40-1))*(ZJ**0.60)*(XJJ+XJI*(1+TC))*40 
          + 0.40*(WJ**(0.40-1))*(ZJ**0.60)*NJ*8;
ICONSI.. CONSI =E= ZI*100*ENDOWIS + WI*100*ENDOWIL
                   -(WI**0.40)*(ZI**0.60)*SUBSIDY*XI*80;
ICONSJ.. CONSJ =E= ZJ*100*ENDOWJS + WJ*100*ENDOWJL;
IENTREI..  ENTI =G= MARKII*PXI*XII*40 + MARKIJ*PXJ*XIJ*40;
IENTREJ..  ENTJ =G= MARKJJ*PXJ*XJJ*40 + MARKJI*PXI*XJI*40;

MKII..     MARKII =E= XII/(NI*(XII + XJI));
MKIJ..     MARKIJ =E= XIJ/(NI*(XIJ + XJJ));
MKJJ..     MARKJJ =E= XJJ/(NJ*(XIJ + XJJ));
MKJI..     MARKJI =E= XJI/(NJ*(XII + XJI));
MODEL M54 /DXDI.PXDI, DXDJ.PXDJ, DXI.PXI, DXJ.PXJ, DY.PY, 
           DWI.PUI, DWJ.PUJ, DFI.PFI, DFJ.PFJ, 
           PRXDI.XI, PRXII.XII, PRXIJ.XIJ, 
           PRXDJ.XJ, PRXJJ.XJJ, PRXJI.XJI, 
           PRYI.YI, PRYJ.YJ, PRWI.WFI, PRWJ.WFJ, 
           PRFI.NI, PRFJ.NJ, SKLABI.ZI, SKLABJ.ZJ, 
           UNLABI.WI, UNLABJ.WJ, ICONSI.CONSI, ICONSJ.CONSJ,
           IENTREI.ENTI, IENTREJ.ENTJ,
           MKII.MARKII, MKIJ.MARKIJ, MKJJ.MARKJJ, MKJI.MARKJI/;
OPTION MCP=MILES;
OPTION LIMROW=0;
OPTION LIMCOL=0;
$OFFSYMLIST OFFSYMXREF OFFUELLIST OFFUELXREF
CONSI.L = 200;
CONSJ.L = 200;
ENTI.L = 20;
ENTJ.L = 20;
XI.L = 1;
XJ.L = 1;
XII.L = 1;
XIJ.L = 1;
XJJ.L = 1;
XJI.L = 1;
YI.L = 1;
YJ.L = 1;
WFI.L = 1;
WFJ.L = 1;
NI.L = 2.5;
NJ.L = 2.5;
PXDI.L = 1;
PXDJ.L = 1;
PXI.L = 1.25;
PXJ.L = 1.25;
PY.L = 1;
ZI.L = 1;
ZJ.L = 1;
WI.L = 1;
WJ.L = 1;
PUI.L = 1;
PUJ.L = 1;

PFI.L = 1;
PFJ.L = 1;
MARKII.L = 0.20;
MARKIJ.L = 0.20;
MARKJJ.L = 0.20;
MARKJI.L = 0.20;
PY.FX = 1;
*M54.ITERLIM = 0;
SOLVE M54 USING MCP;
MODELSTAT = M54.MODELSTAT - 1.;
* counterfactual: trade costs of 15%
TC = 0.15;
SOLVE M54 USING MCP;
* counterfactual:  home production subsidy of 10%, trade costs 0
TC = 0.;
SUBSIDY = .10;
SOLVE M54 USING MCP;
* counterfactual: country's identical except for size,
* positive trade costs (home market advantage)
SUBSIDY = 0;
TC = 0.15;
ENDOWIL = 1.5;
ENDOWJL = 0.5;
ENDOWIS = 1.5;
ENDOWJS = 0.5;
SOLVE M54 USING MCP;
REALWI = WI.L/PUI.L;
REALWJ = WJ.L/PUJ.L;
REALZI = ZI.L/PUI.L;
REALZJ = ZJ.L/PUJ.L;
DISPLAY REALWI, REALWJ, REALZI, REALZJ;