$TITLE  Model M52-MCP.GMS: Closed Economy Monopoly with IRS
* uses MCP
$ONTEXT
                  Production Sectors                Consumers
   Markets   |   X        N        Y        W    |  CONS
   ----------------------------------------------------------
        PX   | 100                       -100    |
        PY   |                   100     -100    |
        PF   |           20                      |   -20
        PU   |                            200    |  -200
        PW   | -32       -8      -60             |   100
        PZ   | -48      -12      -40             |   100
        MK   | -20                               |    20
$OFFTEXT
PARAMETERS
A          Scale parameter for utility function,
SIGMA      Elasticity of substitution,
INCOMEM    Monopoly profit (in welfare units),
INCOMEC    Factor owners' income,
ENDOW      Endowment scale multiplier,
FCOST      Fixed costs scale multiplier,
MODELSTAT;
SIGMA = 9;
ENDOW = 1;
FCOST = 1;
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
DW..       W*200 =E= CONS/PU;
SKLAB..    100*ENDOW =E= 0.40*(PW**0.60)*(PZ**(0.40-1))*Y*100
               + 0.60*(PW**0.40)*(PZ**(0.60-1))*X*80 +12*FCOST;
UNLAB..    100*ENDOW =E= 0.60*(PW**(0.60-1))*(PZ**0.40)*Y*100
               + 0.40*(PW**(0.40-1))*(PZ**0.60)*X*80 + 8*FCOST;
ICONS..    CONS =E= PZ*100*ENDOW + PW*100*ENDOW + MARKUP*PX*X*80
                      -PZ*12*FCOST - PW*8*FCOST;
SHX..      SHAREX =E= 80*PX*X / (80*PX*X + 100*PY*Y) ;
MK..       MARKUP =E= 1/(SIGMA - (SIGMA-1)*SHAREX);

MODEL M52 /DX.PX, DY.PY, DW.PU, PRICEX.X, PRICEY.Y, PRICEW.W, 
           SKLAB.PZ, UNLAB.PW, ICONS.CONS,
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
*M52.ITERLIM = 0;
SOLVE M52 USING MCP;
MODELSTAT = M52.MODELSTAT - 1.;
INCOMEM = W.L*((MARKUP.L*PX.L*X.L*80 - PW.L*8*FCOST - PZ.L*12*FCOST)/
            (PX.L*X.L*80 + PY.L*Y.L*100));
INCOMEC = W.L - INCOMEM;
DISPLAY INCOMEM, INCOMEC;
* counterfactual: marginal-cost pricing
MARKUP.FX = 0;
SOLVE M52 USING MCP;
INCOMEM = W.L*((MARKUP.L*PX.L*X.L*80 - PW.L*8*FCOST - PZ.L*12*FCOST)/
            (PX.L*X.L*80 + PY.L*Y.L*100));
INCOMEC = W.L - INCOMEM;
DISPLAY INCOMEM, INCOMEC;

* counterfactual: double the size of the economy
MARKUP.LO = -INF;
MARKUP.UP = INF;
ENDOW = 2;
SOLVE M52 USING MCP;
INCOMEM = W.L*((MARKUP.L*PX.L*X.L*80 - PW.L*8*FCOST - PZ.L*12*FCOST)/
            (PX.L*X.L*80 + PY.L*Y.L*100));
INCOMEC = W.L - INCOMEM;
DISPLAY INCOMEM, INCOMEC;
* counterfactual: cut the size of the economy by 25%
ENDOW = 0.75;
SOLVE M52 USING MCP;
INCOMEM = W.L*((MARKUP.L*PX.L*X.L*80 - PW.L*8*FCOST - PZ.L*12*FCOST)/
            (PX.L*X.L*80 + PY.L*Y.L*100));
INCOMEC = W.L - INCOMEM;
DISPLAY INCOMEM, INCOMEC;