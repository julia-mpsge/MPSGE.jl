$TITLE  Model M51-MCP.GMS: Closed 2x2 Economy, monopoly X producer
* MCP version
$ONTEXT
                  Production Sectors     Consumers
   Markets   |   X      Y        W    |  CONS   ENTRE
   -------------------------------------------------
        PX   !  100           -100    |
        PY   |        100     -100    |
        PU   |                 200    |  -180     -20
        PW   |  -32   -60             |    92
        PZ   |  -48   -40             |    88
        MK   |  -20                   |            20
$Offtext
PARAMETERS
A          Scale parameter for utility function,
SIGMA      Elasticity of substitution,
INCOMEM    Monopoly profit (in welfare units),
INCOMEC    factor owners' income,
ENDOWS
ENDOWL
MODELSTAT;
SIGMA = 9;
ENDOWS = 88;
ENDOWL = 92;
A = 0.5**(1/(1-SIGMA));
POSITIVE VARIABLES
X
Y
W
PX
PY
PU
PZ
PW
CONS
ENTRE
SHAREX
MARKUP;

EQUATIONS
DX        Demand for X
DY        Demand for Y
DW        Demand for W
PRICEX    MR = MC in X
PRICEY    Zero profit condition for Y (PY = MC)
PRICEW    Zero profit condition for W
SKLAB     Supply-demand balance for skilled labor
UNLAB     Supply-demand balance for unskilled labor
ICONS     Consumer (factor owners') income
IENTRE    Entrepreneur's profits
SHX       Share of X in expenditure
MK        Markup equation;
PRICEX..   (PW**0.40)*(PZ**0.60) =G= PX*(1 - MARKUP);
PRICEY..   (PW**0.60)*(PZ**0.40) =G= PY;
PRICEW..   A*((PX/1.25)**(1-SIGMA) + PY**(1-SIGMA))**(1/(1-SIGMA)) 
                =G= PU;
DX..       X*80 =E= A*(PX/1.25)**(-SIGMA)*
                 ((PX/1.25)**(1-SIGMA) +
                  PY**(1-SIGMA))**(SIGMA/(1-SIGMA))
                    *W*200/1.25;
DY..       Y*100 =E= A*PY**(-SIGMA)*
                 ((PX/1.25)**(1-SIGMA) +
                  PY**(1-SIGMA))**(SIGMA/(1-SIGMA))
                    *W*200;
DW..       W*200 =E= (CONS + ENTRE)/PU;
SKLAB..    ENDOWS =E= 0.40*(PW**0.60)*(PZ**(0.40-1))*Y*100
               + 0.60*(PW**0.40)*(PZ**(0.60-1))*X*80;
UNLAB..    ENDOWL =E= 0.60*(PW**(0.60-1))*(PZ**0.40)*Y*100
               + 0.40*(PW**(0.40-1))*(PZ**0.60)*X*80;
ICONS..    CONS =E= PZ*ENDOWS + PW*ENDOWL;
IENTRE..   ENTRE =E= MARKUP*PX*X*80;
SHX..      SHAREX =E= 80*PX*X / (80*PX*X + 100*PY*Y) ;
MK..       MARKUP =E= 1/(SIGMA - (SIGMA-1)*SHAREX);

MODEL M51 /DX.PX, DY.PY, DW.PU, PRICEX.X, PRICEY.Y, PRICEW.W, 
           SKLAB.PZ, UNLAB.PW, ICONS.CONS, IENTRE.ENTRE
           SHX.SHAREX, MK.MARKUP/;
OPTION MCP=MILES;
OPTION LIMROW=0;
OPTION LIMCOL=0;
$OFFSYMLIST OFFSYMXREF OFFUELLIST OFFUELXREF
CONS.L = 200;
X.L = 1;
Y.L = 1;
W.L = 1;
PX.L = 1.25;
PY.L = 1;
PZ.L = 1;
PW.L = 1;
PU.L = 1;
CONS.L = 180;
ENTRE.L = 20;
SHAREX.L = 0.5;
MARKUP.L = 0.20;
PY.FX = 1;
*M51.ITERLIM = 0;
SOLVE M51 USING MCP;
MODELSTAT = M51.MODELSTAT - 1.;
INCOMEM = W.L*(ENTRE.L/(ENTRE.L + CONS.L));
INCOMEC = W.L*(CONS.L/(ENTRE.L + CONS.L));
DISPLAY INCOMEM, INCOMEC;
*       Evaluate the potential gains from first-best (marginal
*       cost) pricing:
MARKUP.FX = 0;
SOLVE M51 USING MCP;
INCOMEM = W.L*(ENTRE.L/(ENTRE.L + CONS.L));
INCOMEC = W.L*(CONS.L/(ENTRE.L + CONS.L));
DISPLAY INCOMEM, INCOMEC;