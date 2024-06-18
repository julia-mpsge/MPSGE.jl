$TITLE: Model M62-MCP:  Large-Group Monopolistic Competition: uses MCP
$ONTEXT
                        Production Sectors           Consumers
   Markets   |   XC     X        N        Y        W    |  CONS   ENTR
----------------------------------------------------------------------
        PX   |        100                       -100    |
        CX   !  100  -100                               |
        PY   |                          100     -100    |
        PF   |                  20                      |          -20
        PU   |                                   200    |  -200
        PW   |  -32             -8      -60             |   100
        PZ   |  -48            -12      -40             |   100
        MK   |  -20                                     |           20
$OFFTEXT
PARAMETERS
EP
FC
ENDOWS
ENDOWL
WELFARE
MODELSTAT;
EP = 5;
FC = 20;
ENDOWS = 100;
ENDOWL = 100;
POSITIVE VARIABLES
X
Y
W
N
E
PX
PY
PZ
PW
PU
CONS;

EQUATIONS
ZEROP     Zero profits - free entry condition in X (associated with N)
PRICEY    Zero profit condition for Y (PY = MC)
PRICEW    Zero profit condition for W (PU = MC of utility)
PRICEX    MR = MC in X (associated with X, output per firm)
INDEX     Price index for X sector goods (unit expenditure function)
DX        Supply-demand balance for X
DY        Supply-demand balance for Y
DW        Supply-demand balance for utility W(welfare)
SKLAB     Supply-demand balance for skilled labor
UNLAB     Supply-demand balance for unskilled labor
INCOME    National income;
DX..       X*80  =E= PX**(-EP)*(E**(EP-1))*CONS/2;
DY..       Y*100 =E= CONS/(2*PY);
DW..       200*W =E= (1.25**0.5)*CONS/PU;
ZEROP..    FC*(EP-1) =G= X*80;
PRICEX..   (PW**0.4)*(PZ**0.6) =G= PX*(1-1/EP);
PRICEY..   (PW**0.60)*(PZ**0.40) =G= PY;
PRICEW..   (E**0.5)*(PY**0.5) =G= PU;
INDEX..    E =E= (N*PX**(1-EP))**(1/(1-EP));
INCOME..   CONS =E= PZ*ENDOWS + PW*ENDOWL;
SKLAB..    ENDOWS =E= 0.40*(PW**0.60)*(PZ**(0.40-1))*Y*100
               + 0.6*(PW**0.4)*(PZ**(0.6-1))*N*X*80
               + 0.6*(PW**0.4)*(PZ**(0.6-1))*N*FC;
UNLAB..    ENDOWL =E= 0.60*(PW**(0.60-1))*(PZ**0.40)*Y*100
               + 0.4*(PW**(0.4-1))*(PZ**0.6)*N*X*80
               + 0.4*(PW**(0.4-1))*(PZ**0.6)*N*FC;
MODEL M62 /PRICEX.X, PRICEY.Y, PRICEW.W, ZEROP.N, 
   DX.PX, DY.PY, DW.PU, 
           SKLAB.PZ, UNLAB.PW, INDEX.E, INCOME.CONS/;
OPTION MCP=MILES;

OPTION LIMROW=0;
OPTION LIMCOL=0;
$OFFSYMLIST OFFSYMXREF OFFUELLIST OFFUELXREF
E.L = 1.25;
CONS.L = 200;
X.L = 1;
Y.L = 1;
N.L = 1;
W.L = 1;
PX.L = 1.25;
PY.L = 1;
PZ.L = 1;
PW.L = 1;
PU.L = 1.25**0.5;
PY.FX = 1;
SOLVE M62 USING MCP;
MODELSTAT = M62.MODELSTAT - 1.;
DISPLAY MODELSTAT;
*       Counterfactual: expand the size of the economy
ENDOWS = 200;
ENDOWL = 200;
SOLVE M62 USING MCP;