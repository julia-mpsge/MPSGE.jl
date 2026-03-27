$TITLE  Model M53-MCP: Oligopoly with Free Entry, MCP version
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
SIGMA      Elasticity of substitution,
ENDOW      Endowment scale multiplier,
MODELSTAT;
SIGMA = 1;
ENDOW = 1;
POSITIVE VARIABLES
X
Y
W
N
PX
PY
PU
PF
PZ
PW
CONS
ENTRE
MARKUP;
EQUATIONS
DX        Demand for X
DY        Demand for Y
DW        Demand for W
DF        Demand for fixed costs
PRICEX    MR = MC in X
PRICEY    Zero profit condition for Y (PY = MC)

PRICEW    Zero profit condition for W
PRICEF    Zero profit condition for fixed costs
SKLAB     Supply-demand balance for skilled labor
UNLAB     Supply-demand balance for unskilled labor
ICONS     Consumer (factor owners') income
IENTRE    Entrepreneur's profits
MK        Markup equation;
PRICEX..   (PW**0.40)*(PZ**0.60) =G= PX*(1 - MARKUP);
PRICEY..   (PW**0.60)*(PZ**0.40) =G= PY;
PRICEW..   ((PX/1.25)**0.5)*(PY**0.5) =G= PU; 
PRICEF..   (PW**0.40)*(PZ**0.60) =G= PF;
DX..       X*80 =E= 0.5*CONS/PX;
DY..       Y*100 =E= 0.5*CONS/PY;
DW..       W*200 =E= CONS/PU;
DF..       N*4 =G= ENTRE/PF;
SKLAB..    100*ENDOW =E= 0.40*(PW**0.60)*(PZ**(0.40-1))*Y*100
               + 0.60*(PW**0.40)*(PZ**(0.60-1))*X*80 
       + 0.60*(PW**0.40)*(PZ**(0.60-1))*N*4;
UNLAB..    100*ENDOW =E= 0.60*(PW**(0.60-1))*(PZ**0.40)*Y*100
               + 0.40*(PW**(0.40-1))*(PZ**0.60)*X*80 
               + 0.40*(PW**(0.40-1))*(PZ**0.60)*N*4;
ICONS..    CONS =E= PZ*100*ENDOW + PW*100*ENDOW;
IENTRE..   ENTRE =E= MARKUP*PX*X*80;
MK..       MARKUP*N =E= 1;
MODEL M53 /DX.PX, DY.PY, DW.PU, DF.PF, PRICEX.X, PRICEY.Y, PRICEW.W, 
           PRICEF.N, SKLAB.PZ, UNLAB.PW, ICONS.CONS, IENTRE.ENTRE,
           MK.MARKUP/;
OPTION MCP=MILES;
OPTION LIMROW=0;
OPTION LIMCOL=0;

$OFFSYMLIST OFFSYMXREF OFFUELLIST OFFUELXREF
CONS.L = 200;
X.L = 1;
Y.L = 1;
W.L = 1;
N.L = 4;
PX.L = 1.25;
PY.L = 1;
PZ.L = 1;
PW.L = 1;
PU.L = 1;
PF.L = 1;
CONS.L = 180;
ENTRE.L = 20;
MARKUP.L = 0.20;
PY.FX = 1;
*M53.ITERLIM = 0;
SOLVE M53 USING MCP;
MODELSTAT = M53.MODELSTAT - 1.;
* counterfactual: double the size of the economy
ENDOW = 2;
SOLVE M53 USING MCP;