$TITLE: Model M61-MCP: External Economies of Scale, uses MCP
$ONTEXT
The model is based on the benchmark social accounts for model M1-1:
                  Production Sectors          Consumers
   Markets   |    X       Y        W    |       CONS
   ------------------------------------------------------
        PX   |  100             -100    |
        PY   |          100     -100    |
        PU   |                   200    |       -200
        PW   |  -40     -60             |        100
        PZ   |  -60     -40             |        100
   ------------------------------------------------------
$OFFTEXT
PARAMETERS
B
ENDOWS
ENDOWL
MODELSTAT;
ENDOWS = 100;
ENDOWL = 100;
B = 0.2;
POSITIVE VARIABLES
X
Y
W
PX
PY
PU
PZ
PW
CONS;
EQUATIONS
DX        Demand for X
DY        Demand for Y
DW        Demand for W
PRICEX    MR = MC in X
PRICEY    Zero profit condition for Y (PY = MC)
PRICEW    Zero profit condition for W
SKLAB     Supply-demand balance for skilled labor

UNLAB     Supply-demand balance for unskilled labor
INCOME    National income;
PRICEX..   (PW**0.40)*(PZ**0.60)/(X**B) =G= PX;
PRICEY..   (PW**0.60)*(PZ**0.40) =G= PY;
PRICEW..   (PX**0.50)*(PY**0.50) =G= PU;
DX..       X*100 =E= CONS/(2*PX);
DY..       Y*100 =E= CONS/(2*PY);
DW..       200*W =E= CONS/PU;
SKLAB..    ENDOWS =E= 0.40*(PW**0.60)*(PZ**(0.40-1))*Y*100
               + 0.60*(PW**0.40)*(PZ**(0.60-1))*(X**(1-B))*100;
UNLAB..    ENDOWL =E= 0.60*(PW**(0.60-1))*(PZ**0.40)*Y*100
               + 0.40*(PW**(0.40-1))*(PZ**0.60)*(X**(1-B))*100;
INCOME..   CONS =E= PZ*ENDOWS + PW*ENDOWL;
MODEL M61 /DX.PX, DY.PY, DW.PU, PRICEX.X, PRICEY.Y, PRICEW.W, 
           SKLAB.PZ, UNLAB.PW, INCOME.CONS/;
OPTION MCP=MILES;
OPTION LIMROW=0;
OPTION LIMCOL=0;
$OFFSYMLIST OFFSYMXREF OFFUELLIST OFFUELXREF
CONS.L = 200;
X.L = 1;
Y.L = 1;
W.L = 1;
PX.L = 1;
PY.L = 1;
PZ.L = 1;
PW.L = 1;
PU.L = 1;
PY.FX = 1;

SOLVE M61 USING MCP;
MODELSTAT = M61.MODELSTAT - 1.;
DISPLAY MODELSTAT;
*       Counterfactual: expand the size of the economy
ENDOWS = 200;
ENDOWL = 200;
SOLVE M61 USING MCP;
*       Counterfactual: contract the size of the economy
ENDOWS = 80;
ENDOWL = 80.
SOLVE M61 USING MCP;