$title  A two by two general equilibrium model -- scalar GAMS/MCP
* Algebraic version with Elasticities to compate with 'TwoByTwo_Scalar-MPSGE.gms'
*
parameter   endow     index of labour endowment     / 1.0 /
       esub_x substit elas for x    /0.5/
       esub_y substition elas for y /0.6/;
*   =====================================================
*   Variables which appear explicitly in the MPSGE model:

Nonnegative Variables
    X   Activity level for sector X -- benchmark=1
    Y   Activity level for sector Y -- benchmark=1
    U   Activity level for sector U -- benchmark=1

    PU  Relative price index for commodity U -- benchmark=1 
    PX  Relative price index for commodity X -- benchmark=1 
    PY  Relative price index for commodity Y -- benchmark=1
    PL  Relative price index for labor -- benchmark=1
    PK  Relative price index for capital -- benchmark=1;

Free Variable
    RA  Income level for representative agent -- benchmark=150;

*   Assign default prices and activity levels:

X.L = 1; Y.L = 1; U.L = 1; PX.L = 1; PY.L = 1; PL.L = 1; PK.L = 1; PU.L = 1; RA.L = 150;

*   Insert lower bounds to avoid bad function calls:

PX.LO = 0.001; PY.LO = 0.001; PU.LO = 0.001; PL.LO = 0.001; PK.LO = 0.001;
RA.UP = INF;

*   =====================================================
*   Variables that enter the MPSGE model implicitly:

variables
   LX   'compensated labor demand in sector x'
   LY   'compensated labor demand in sector y'
   KX   'compensated capital demand in sector x'
   KY   'compensated capital demand in sector y'
   DX   'compensated demand for x in sector u'
   DY   'compensated demand for y in sector u';


*   Equations for the implicit variables:

Equations

   lxdef    'compensated labor demand in sector x'
   lydef    'compensated labor demand in sector y'
   kxdef    'compensated capital demand in sector x'
   kydef    'compensated capital demand in sector y'
   dxdef    'compensated demand for x in sector u'
   dydef    'compensated demand for y in sector u';


lxdef..     LX =e= 50*(((50/100)*PL**(1-esub_x) + (50/100)*PK**(1-esub_x))**(1/(1-esub_x))/PL)**esub_x;
lydef..     LY =e= 20*(((20/50) *PL**(1-esub_y) + (30/50) *PK**(1-esub_y))**(1/(1-esub_y))/PL)**esub_y;
kxdef..     KX =e= 50*(((50/100)*PL**(1-esub_x) + (50/100)*PK**(1-esub_x))**(1/(1-esub_x))/PK)**esub_x;
kydef..     KY =e= 30*(((20/50) *PL**(1-esub_y) + (30/50) *PK**(1-esub_y))**(1/(1-esub_y))/PK)**esub_y;
dxdef..     DX =e= (100/150)*(PU/PX)**1*150; 
dydef..     DY =e= (50/150)*(PU/PY)**1*150; 
* /PX; /PY;
*   Initial values:

LX.L = 50; LY.L = 20; KX.L = 50; KY.L = 30; DX.L = 100; DY.L = 50;

*   =====================================================

Equations
   prf_x    'zero profit for sector x'
   prf_y    'zero profit for sector y'
   prf_u    'zero profit for sector u (Hicksian welfare index)'

   mkt_x    'supply-demand balance for commodity x'
   mkt_y    'supply-demand balance for commodity y'
   mkt_l    'supply-demand balance for primary factor l'
   mkt_k    'supply-demand balance for primary factor k'
   mkt_u    'supply-demand balance for aggregate demand'

       i_ra     'income definition for consumer (ra)';
*     Zero Profit
*Original
prf_x..     PL*LX + PK*KX  =e= 100 * PX;
prf_y..     PL*LY + PK*KY  =E= 50 * PY;
prf_u..     150*PX**(100/150)*PY**(50/150) =g= 150*PU;

*   Market clearance:
mkt_x..         100 * X =e= DX*U;
mkt_y..         50 * Y =e= DY*U;
*mkt_x..         100 * X =e= (100/150)*(PU/PX)**1*150*U;
*mkt_y..         50 * Y =e= (50/150)*(PU/PY)**1*150*U;
mkt_u..         150 * U =E= RA / PU;

mkt_l..         70 * endow =e= LX*X + LY*Y;
mkt_k..         80 =e= KX*X + KY*Y;
*mkt_l..         70 * endow =e= (50/70)*70*X*(PX/PL)**esub_x + (20/70)*70*Y*(PY/PL)**esub_y;
* Cobb-Douglas inner nest version:
*mrk..l           70 * endow =e= 70 * X * (PX/PL**(50/100)*PK**(50/100))**esub_x
*mkt_k..         80 =e= (50/80)*80*X*(PX/PK)**esub_x +(30/80)*80*Y*(PY/PK)**esub_y;
*   Income balance:
i_ra..      RA =e= (70*endow)*PL + 80*PK;

* We declare the model using the mixed complementarity syntax
* in which equation identifiers are associated with variables.

model algebraic / prf_x.X, prf_y.Y, prf_u.U, mkt_x.PX, mkt_y.PY, mkt_l.PL, 
                 mkt_k.PK, mkt_u.PU, I_ra.RA,
         lxdef.LX, lydef.LY, kxdef.KX, kydef.KY, dxdef.DX, dydef.DY /;

algebraic.iterlim = 0;
solve algebraic using MCP;
algebraic.iterlim = 1000;

parameter   equilibrium Equilibrium values;

equilibrium("X.L","benchmark") = X.L;
equilibrium("Y.L","benchmark") = Y.L;
equilibrium("U.L","benchmark") = U.L;

equilibrium("PX.L","benchmark") = PX.L;
equilibrium("PY.L","benchmark") = PY.L;
equilibrium("PU.L","benchmark") = PU.L;
equilibrium("PL.L","benchmark") = PL.L;
equilibrium("PK.L","benchmark") = PK.L;

equilibrium("RA.L","benchmark") = RA.L;

equilibrium("LX.L","benchmark") = LX.L;
equilibrium("LY.L","benchmark") = LY.L;
equilibrium("KX.L","benchmark") = KX.L;
equilibrium("KY.L","benchmark") = KY.L;
equilibrium("DX.L","benchmark") = DX.L;
equilibrium("DY.L","benchmark") = DY.L;

equilibrium("PX.L/PX.L","benchmark") = PX.L/PX.L;
equilibrium("PY.L/PX.L","benchmark") = PY.L/PX.L;
equilibrium("PU.L/PX.L","benchmark") = PU.L/PX.L;
equilibrium("PL.L/PX.L","benchmark") = PL.L/PX.L;
equilibrium("PK.L/PX.L","benchmark") = PK.L/PX.L;

equilibrium("RA.L/PX.L","benchmark") = RA.L/PX.L;

*   Solve the same counterfactual:

endow = 1.1;

*   Fix the income level at the default level, i.e. the
*   income level corresponding to the counterfactual 
*   endowment at benchmark price:

RA.FX = 80 + 1.1 * 70;

solve algebraic using MCP;

*   Save counterfactual values:

equilibrium("X.L","RA=157") = X.L;
equilibrium("Y.L","RA=157") = Y.L;
equilibrium("U.L","RA=157") = U.L;

equilibrium("PX.L","RA=157") = PX.L;
equilibrium("PY.L","RA=157") = PY.L;
equilibrium("PU.L","RA=157") = PU.L;
equilibrium("PL.L","RA=157") = PL.L;
equilibrium("PK.L","RA=157") = PK.L;

equilibrium("RA.L","RA=157") = RA.L;

equilibrium("LX.L","RA=157") = LX.L;
equilibrium("LY.L","RA=157") = LY.L;
equilibrium("KX.L","RA=157") = KX.L;
equilibrium("KY.L","RA=157") = KY.L;
equilibrium("DX.L","RA=157") = DX.L;
equilibrium("DY.L","RA=157") = DY.L;

equilibrium("PX.L/PX.L","RA=157") = PX.L/PX.L;
equilibrium("PY.L/PX.L","RA=157") = PY.L/PX.L;
equilibrium("PU.L/PX.L","RA=157") = PU.L/PX.L;
equilibrium("PL.L/PX.L","RA=157") = PL.L/PX.L;
equilibrium("PK.L/PX.L","RA=157") = PK.L/PX.L;
equilibrium("RA.L/PX.L","RA=157") = RA.L/PX.L;

*   Fix a numeraire price index and recalculate:

RA.LO = -inf;
RA.UP = inf;
PX.FX = 1;

solve algebraic using mcp;

equilibrium("X.L","PX=1") = X.L;
equilibrium("Y.L","PX=1") = Y.L;
equilibrium("U.L","PX=1") = U.L;

equilibrium("PX.L","PX=1") = PX.L;
equilibrium("PY.L","PX=1") = PY.L;
equilibrium("PU.L","PX=1") = PU.L;
equilibrium("PL.L","PX=1") = PL.L;
equilibrium("PK.L","PX=1") = PK.L;

equilibrium("RA.L","PX=1") = RA.L;

equilibrium("LX.L","PX=1") = LX.L;
equilibrium("LY.L","PX=1") = LY.L;
equilibrium("KX.L","PX=1") = KX.L;
equilibrium("KY.L","PX=1") = KY.L;
equilibrium("DX.L","PX=1") = DX.L;
equilibrium("DY.L","PX=1") = DY.L;

equilibrium("LX.L/PX.L","PX=1") = LX.L/PX.L;

equilibrium("PX.L/PX.L","PX=1") = PX.L/PX.L;
equilibrium("PY.L/PX.L","PX=1") = PY.L/PX.L;
equilibrium("PU.L/PX.L","PX=1") = PU.L/PX.L;
equilibrium("PL.L/PX.L","PX=1") = PL.L/PX.L;
equilibrium("PK.L/PX.L","PX=1") = PK.L/PX.L;

equilibrium("RA.L/PX.L","PX=1") = RA.L/PX.L;

*   Recalculate with a different numeraire.
*   "Unfix" the price of X and fix the wage rate:

PX.UP = +inf; 
PX.LO = 1e-5;
PL.FX = 1;
solve algebraic using mcp;

equilibrium("X.L","PL=1") = X.L;
equilibrium("Y.L","PL=1") = Y.L;
equilibrium("U.L","PL=1") = U.L;

equilibrium("PX.L","PL=1") = PX.L;
equilibrium("PY.L","PL=1") = PY.L;
equilibrium("PU.L","PL=1") = PU.L;
equilibrium("PL.L","PL=1") = PL.L;
equilibrium("PK.L","PL=1") = PK.L;

equilibrium("RA.L","PL=1") = RA.L;

equilibrium("LX.L","PL=1") = LX.L;
equilibrium("LY.L","PL=1") = LY.L;
equilibrium("KX.L","PL=1") = KX.L;
equilibrium("KY.L","PL=1") = KY.L;
equilibrium("DX.L","PL=1") = DX.L;
equilibrium("DY.L","PL=1") = DY.L;

equilibrium("PX.L/PX.L","PL=1") = PX.L/PX.L;
equilibrium("PY.L/PX.L","PL=1") = PY.L/PX.L;
equilibrium("PU.L/PX.L","PL=1") = PU.L/PX.L;
equilibrium("PL.L/PX.L","PL=1") = PL.L/PX.L;
equilibrium("PK.L/PX.L","PL=1") = PK.L/PX.L;

equilibrium("RA.L/PX.L","PL=1") = RA.L/PX.L;
* equilibrium to a gdx for export to Excel
execute_unload "TwoxTwoCESProd.gdx" equilibrium

*=== Write to variable levels to Excel file from GDX 
*=== Since we do not specify a sheet, data is placed in first sheet
execute 'gdxxrw.exe TwoxTwoCESProd.gdx o=MPSGEresults.xlsx par=equilibrium rng=TwoxTwoCESProd!'

option decimals = 8; display equilibrium;