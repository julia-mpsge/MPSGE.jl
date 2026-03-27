$TITLE: Model M63:  Two Country Large-Group Monopolistic Competition
*  uses MCP
$ontext
        YI   YJ    XMI  XMJ  NMI  NMJ    WI    WJ  CONI  CONJ  EHTI ENTJ
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
EP
EY
TC
FC
ENDOWIS
ENDOWIL
ENDOWJS
ENDOWJL
REALWI
REALWJ
REALZI
REALZJ
MODELSTAT;
EP = 5;
EY = 3;
TC = 1.;
FC = 20;
ENDOWIS = 100;
ENDOWIL = 100;
ENDOWJS = 100;
ENDOWJL = 100;
POSITIVE VARIABLES
WFI

WFJ
XII
XIJ
XJJ
XJI
YI
YJ
NI
NJ
PI
PJ
PY
PUI
PUJ
EI
EJ
ZI
WI
ZJ
WJ
MI
MJ;
EQUATIONS
WELFAREI
WELFAREJ
DXII
DXJI
DXJJ
DXIJ
DY
ZEROPI
ZEROPJ
PRICEI
PRICEJ
PRICYI
PRICYJ
PRICEUI
PRICEUJ
DWJ
INDEXI
INDEXJ
EXPI
EXPJ
SKLABI
UNLABI
SKLABJ
UNLABJ;

WELFAREI.. 200*WFI =E= ((2**(1/(1-EP))*1.25)**0.5)*MI/(1.025*PUI);
WELFAREJ.. 200*WFJ =E= ((2**(1/(1-EP))*1.25)**0.5)*MJ/(1.025*PUJ);
DXII..      XII*40 =E= PI**(-EP)*(EI**(EP-1))*MI/2;
DXJI..      XJI*40/TC =E= (PJ*TC)**(-EP)*(EI**(EP-1))*MI/2;
DXJJ..      XJJ*40 =E= PJ**(-EP)*(EJ**(EP-1))*MJ/2;
DXIJ..      XIJ*40/TC =E= (PI*TC)**(-EP)*(EJ**(EP-1))*MJ/2;
DY..        YI*100 + YJ*100 =E= MI/(2*PY) + MJ/(2*PY);
ZEROPI..    FC*(EP-1) =G= XII*40 + XIJ*40;
ZEROPJ..    FC*(EP-1) =G= XJJ*40 + XJI*40;
PRICEI..    (WI**0.4)*(ZI**0.6) =G= PI*(1-1/EP);
PRICEJ..    (WJ**0.4)*(ZJ**0.6) =G= PJ*(1-1/EP);
PRICYI..    (WI**0.60)*(ZI**0.40)  =G= PY;
PRICYJ..    (WJ**0.60)*(ZJ**0.40)  =G= PY;
PRICEUI..   (EI**0.5)*(PY**0.5)/1.025 =G= PUI;
PRICEUJ..   (EJ**0.5)*(PY**0.5)/1.025 =G= PUJ;
INDEXI..    EI =E= (NI*PI**(1-EP) + NJ*(PJ*TC)**(1-EP))**(1/(1-EP));
INDEXJ..    EJ =E= (NI*(PI*TC)**(1-EP) + NJ*PJ**(1-EP))**(1/(1-EP));
EXPI..      MI =E= ZI*ENDOWIS + WI*ENDOWIL;
EXPJ..      MJ =E= ZJ*ENDOWJS + WJ*ENDOWJL;
SKLABI..    ENDOWIS =E= 0.40*(WI**0.60)*(ZI**(0.40-1))*YI*100
               + 0.6*(WI**0.4)*(ZI**(0.6-1))*NI*((XII+XIJ)*40 + FC);
UNLABI..    ENDOWIL =E= 0.60*(WI**(0.60-1))*(ZI**0.40)*YI*100
               + 0.4*(WI**(0.4-1))*(ZI**0.6)*NI*((XII+XIJ)*40 + FC);

SKLABJ..    ENDOWJS =E= 0.40*(WJ**0.60)*(ZJ**(0.40-1))*YJ*100
               + 0.6*(WJ**0.4)*(ZJ**(0.6-1))*NJ*((XJJ+XJI)*40 + FC);
UNLABJ..    ENDOWJL =E= 0.60*(WJ**(0.60-1))*(ZJ**0.40)*YJ*100
               + 0.4*(WJ**(0.4-1))*(ZJ**0.6)*NJ*((XJJ+XJI)*40 + FC);
MODEL M63 /   WELFAREI.WFI, WELFAREJ.WFJ,
              PRICYI.YI, PRICYJ.YJ, DXII.XII, DXJI.XJI,
              DXJJ.XJJ, DXIJ.XIJ, DY.PY,
              ZEROPI.NI, ZEROPJ.NJ,
              PRICEI.PI, PRICEJ.PJ, 
              PRICEUI.PUI, PRICEUJ.PUJ,
              SKLABI.ZI, SKLABJ.ZJ, UNLABI.WI,
              UNLABJ.WJ, INDEXI.EI, INDEXJ.EJ, EXPI.MI, EXPJ.MJ/;
OPTION MCP=MILES;
OPTION LIMROW=0;
OPTION LIMCOL=0;
$OFFSYMLIST OFFSYMXREF OFFUELLIST OFFUELXREF
WFI.L = 1;
WFJ.L = 1;
PUI.L = 1.25**0.5;
PUJ.L = 1.25**0.5;
EI.L = 1;
EJ.L = 1;
MI.L = 200;
MJ.L = 200;
XII.L = 1;
XIJ.L = 1;
XJJ.L = 1;
XJI.L = 1;
YI.L = 1;
YJ.L = 1;
NI.L = 1;
NJ.L = 1;
PI.L = 1.25;
PJ.L = 1.25;
PY.L = 1;
ZI.L = 1;
WI.L = 1;
ZJ.L = 1;
WJ.L = 1;
PY.FX = 1;

TC = 1.;
SOLVE M63 USING MCP;


MODELSTAT = M63.MODELSTAT - 1.;
ENDOWIS = 200;
ENDOWIL = 200;
ENDOWJS = 200;
ENDOWJL = 200;
SOLVE M63 USING MCP;

TC = 1.15;
ENDOWIS = 100;
ENDOWIL = 100;
ENDOWJS = 100;
ENDOWJL = 100;
SOLVE M63 USING MCP;

TC = 1.0;
ENDOWIS = 150;
ENDOWIL = 150;
ENDOWJS =  50;
ENDOWJL =  50;
SOLVE M63 USING MCP;

TC = 1.15;
ENDOWIS = 150;
ENDOWIL = 150;
ENDOWJS = 50;
ENDOWJL = 50;
SOLVE M63 USING MCP;

REALWI = WI.L/PUI.L;
REALWJ = WJ.L/PUJ.L;
REALZI = ZI.L/PUI.L;
REALZJ = ZJ.L/PUJ.L;

DISPLAY REALWI, REALWJ, REALZI, REALZJ;
ENDOWIS = 120;
ENDOWIL = 100;
ENDOWJS =  80;
ENDOWJL = 100;
SOLVE M63 USING MCP;


OPTION DECIMALS = 8;

REALWI = WI.L/PUI.L;
REALWJ = WJ.L/PUJ.L;
REALZI = ZI.L/PUI.L;
REALZJ = ZJ.L/PUJ.L;
DISPLAY REALWI, REALWJ, REALZI, REALZJ;