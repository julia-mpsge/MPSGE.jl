$title   Model with Joint Products and Intermediate Demand -- solved with GAMS/MPSGE

Sets    j      Sectors    / s1*s2 /,
        i      Goods      / g1*g2 /,
        f      Primary factors  / labor, capital / ;

alias (i,ii),(j,jj);

Table   make0(i,j)  Matrix -- supplies
           s1      s2
   g1       6       2
   g2       2      10 ;

Table   use0(i,j)   Use matrix -- intermediate demands
           s1      s2
   g1       4       2
   g2       2       6 ;

Table  fd0(f,j)     Factor demands
           s1       s2
   labor    1        3
   capital  1        1 ;

Parameters
  c0(i)     Consumer demand  / g1 2, g2 4 /
  e0(f)     Factor endowments
  Dem_elas  Demand Elasticity /1.0 /;

e0(f) = sum(j, fd0(f,j));
display e0;

$ontext
$MODEL:jpmge

$SECTORS:
    X(j)    ! Activity index -- benchmark=1

$COMMODITIES:
    P(i)    ! Relative commodity price -- benchmark=1
    PF(f)   ! Relative factor price -- benchmark=1

$CONSUMERS:
    Y       ! Nominal household income=expenditure

$PROD:X(j)   s:1    t:1
      O:P(i)    Q:make0(i,j)    ! S(i,j) in the MCP and NLP models
      I:P(i)    Q:use0(i,j)     ! D(i,j) in the MCP and NLP models
      I:PF(f)   Q:fd0(f,j)      ! FD(f,j) in the MCP and NLP models

$REPORT:
    v:S(i,j)    O:P(i)      PROD:X(j)
    v:D(i,j)    I:P(i)      PROD:X(j)
    v:FD(f,j)   I:PF(f)     PROD:X(j)

$DEMAND:Y s:Dem_elas
    D:P(i)      Q:c0(i)
    E:PF(f)     Q:e0(f)

$REPORT:
    v:PY(i)     D:P(i)      DEMAND:Y
    v:CWI       W:Y     
**    v:PY(i)     D:P(i)      DEMAND:Y
**    v:E(f)      E:PF(f)     DEMAND:Y
*    

$offtext
$sysinclude mpsgeset jpmge

* Benchmark replication

jpmge.iterlim = 0;
$include JPMGE.GEN
solve jpmge using mcp;
abort$(abs(jpmge.objval) gt 1e-7) "JPMGE does not calibrate!";
jpmge.iterlim = 1000;

Parameter   equilibrium   Equilibrium values;

equilibrium("X",j,"benchmark")   = X.L(j);
equilibrium("P",i,"benchmark")   = P.L(i);
equilibrium("PF",f,"benchmark")  = PF.L(f);
equilibrium(i,j,"benchmark")  = S.L(i,j)/X.L(j);
*! I don't think you can print the D differently in Display (bc same indexing), it overwrites
equilibrium(i,j,"D benchmark")   = D.L(i,j)/X.L(j);  
equilibrium(f,j,"benchmark")     = FD.L(f,j)/X.L(j);
equilibrium("Y","_","benchmark") = Y.L;
equilibrium("PY",i,"benchmark")   = PY.L(i);
equilibrium("CWI","_","benchmark")   = CWI.L;


** Counterfactual : 10% increase in labor endowment
e0("labor") = 1.1 * e0("labor");
Y.FX = sum(f,e0(f));

*
*
$include JPMGE.GEN
solve jpmge using mcp;
*
**   Save counterfactual values:
*
equilibrium("X",j,"Y=6.4")   = X.L(j);
equilibrium("P",i,"Y=6.4")   = P.L(i);
equilibrium("PF",f,"Y=6.4")  = PF.L(f);
equilibrium(i,j,"Y=6.4")     = S.L(i,j)/X.L(j);
*! Can't display same variable with same indexing (overwrites) so add column
equilibrium(i,j,"D Y=6.4")     = D.L(i,j)/X.L(j);
equilibrium(f,j,"Y=6.4")     = FD.L(f,j)/X.L(j);
equilibrium("Y","_","Y=6.4") = Y.L;
equilibrium("PY",i,"Y=6.4")   = PY.L(i);

**   Fix a numeraire price index and recalculate:

Y.LO = -INF;
Y.UP =  INF;
P.FX("g1") = 1;
$include JPMGE.GEN
solve jpmge using mcp;

equilibrium("P",  i,'P("g1")=1') = P.L(i);
equilibrium("PF", f,'P("g1")=1') = PF.L(f);
equilibrium("Y","_",'P("g1")=1') = Y.L;
equilibrium(i,j,'P("g1")=1') = S.L(i,j)/X.L(j);
*! Can't display same variable with same indexing (overwrites) so add column
equilibrium(i,j,'D P("g1")=1') = D.L(i,j)/X.L(j);
equilibrium(f, j,'P("g1")=1') = FD.L(f,j)/X.L(j);
equilibrium("PY", i,'P("g1")=1') = PY.L(i);
equilibrium("X", j,'P("g1")=1') = X.L(j);

*   Recalculate with a different numeraire.
*   "Unfix" the price of X and fix the wage rate:

P.UP("g1") = +inf;
P.LO("g1") = 1e-5;
PF.FX("labor") = 1;
*
$include JPMGE.GEN
solve jpmge using mcp;
*
equilibrium("X",  j,'PF("labor")=1')   = X.L(j);
equilibrium("P",  i,'PF("labor")=1')   = P.L(i);
equilibrium("PF", f,'PF("labor")=1')   = PF.L(f);
equilibrium(i,j,'PF("labor")=1') = S.L(i,j)/X.L(j);
*! Can't display same variable with same indexing (overwrites) so add column
equilibrium(i,j,'D PF("labor")=1') = D.L(i,j)/X.L(j);
equilibrium(f,j,'PF("labor")=1')   = FD.L(f,j)/X.L(j);
equilibrium("Y","_",'PF("labor")=1')   = Y.L;
equilibrium("PY",  i,'PF("labor")=1')   = PY.L(i);

Dem_elas = 0. ;
PF.UP("labor") = +INF;
PF.LO("labor") = 1e-5;

Y.FX = sum(f,e0(f));
$include JPMGE.GEN
solve jpmge using mcp;

**   Save counterfactual values but with Demand Elasticity updated:

equilibrium("X",j,"D_elas=0,Y=6.4")   = X.L(j);
equilibrium("P",i,"D_elas=0,Y=6.4")   = P.L(i);
equilibrium("PF",f,"D_elas=0,Y=6.4")  = PF.L(f);
equilibrium("Y","_","D_elas=0,Y=6.4") = Y.L;
equilibrium(i,j,"D_elas=0,Y=6.4")     = S.L(i,j)/X.L(j);
*! Can't display same variable with same indexing (overwrites) so add column
equilibrium(i,j,"D D_elas=0,Y=6.4")     = D.L(i,j)/X.L(j);
equilibrium(f,j,"D_elas=0,Y=6.4")     = FD.L(f,j)/X.L(j);
equilibrium("PY",i,"D_elas=0,Y=6.4")   = PY.L(i);

*   Fix a numeraire price index and recalculate:

P.FX("g1") = 1;
Y.LO = -INF;
Y.UP =  INF;

$include JPMGE.GEN
solve jpmge using mcp;

equilibrium("X",j,'D_elas=0,P("g1")=1') = X.L(j);
equilibrium("P",  i,'D_elas=0,P("g1")=1') = P.L(i);
equilibrium("PF", f,'D_elas=0,P("g1")=1') = PF.L(f);
equilibrium("Y","_",'D_elas=0,P("g1")=1') = Y.L;
equilibrium(i,j,'D_elas=0,P("g1")=1') = S.L(i,j)/X.L(j);
*! Can't display same variable with same indexing (overwrites) so add column
equilibrium(i,j,'D D_elas=0,P("g1")=1') = D.L(i,j)/X.L(j);
equilibrium(f,j,'D_elas=0,P("g1")=1') = FD.L(f,j)/X.L(j);
equilibrium("PY",i,'D_elas=0,P("g1")=1') = PY.L(i);

*   Recalculate with a different numeraire.
*   "Unfix" the price of X and fix the wage rate:

P.UP("g1") = +inf;
P.LO("g1") = 1e-5;
PF.FX("labor") = 1;

$include JPMGE.GEN
solve jpmge using mcp;

equilibrium("P",  i,'D_elas=0,PF("l")=1')   = P.L(i);
equilibrium("PF", f,'D_elas=0,PF("l")=1')   = PF.L(f);
equilibrium("Y","_",'D_elas=0,PF("l")=1')   = Y.L;
equilibrium(i,j,'D_elas=0,PF("l")=1') = S.L(i,j)/X.L(j);
*! Can't display same variable with same indexing (overwrites) so add column
equilibrium(i,j,'D D_elas=0,PF("l")=1') = D.L(i,j)/X.L(j);
equilibrium(f,j,'D_elas=0,PF("l")=1')   = FD.L(f,j)/X.L(j);
equilibrium("PY",i,'D_elas=0,PF("l")=1')   = PY.L(i);
equilibrium("X",j,'D_elas=0,PF("l")=1')   = X.L(j);

Dem_elas = 2.0 ;
PF.UP("labor") = +INF;
PF.LO("labor") = 1e-5;
Y.FX = sum(f,e0(f));

$include JPMGE.GEN
solve jpmge using mcp;

*   Save counterfactual values:

equilibrium("X",j,"D_elas=2,Y=6.4")   = X.L(j);
equilibrium("P",i,"D_elas=2,Y=6.4")   = P.L(i);
equilibrium("PF",f,"D_elas=2,Y=6.4")  = PF.L(f);
equilibrium(i,j,"D_elas=2,Y=6.4")     = S.L(i,j)/X.L(j);
*! Can't display same variable with same indexing (overwrites) so add column
equilibrium(i,j,"D D_elas=2,Y=6.4")     = D.L(i,j)/X.L(j);
equilibrium(f,j,"D_elas=2,Y=6.4")     = FD.L(f,j)/X.L(j);
equilibrium("Y","_","D_elas=2,Y=6.4") = Y.L;
equilibrium("PY",i,"D_elas=2,Y=6.4")   = PY.L(i);

*   Fix a numeraire price index and recalculate:

P.FX("g1") = 1;
Y.LO = -INF;
Y.UP =  INF;
$include JPMGE.GEN
solve jpmge using mcp;

equilibrium("X",  j,'D_elas=2,P("g1")=1') = X.L(j);
equilibrium("P",  i,'D_elas=2,P("g1")=1') = P.L(i);
equilibrium("PF", f,'D_elas=2,P("g1")=1') = PF.L(f);
equilibrium(i,    j,'D_elas=2,P("g1")=1') = S.L(i,j)/X.L(j);
*! Can't display same variable with same indexing (overwrites) so add column
equilibrium(i,    j,'D D_elas=2,P("g1")=1') = D.L(i,j)/X.L(j);
equilibrium(f,    j,'D_elas=2,P("g1")=1') = FD.L(f,j)/X.L(j);
equilibrium("Y","_",'D_elas=2,P("g1")=1') = Y.L;
equilibrium("PY",  i,'D_elas=2,P("g1")=1') = PY.L(i);

*   Recalculate with a different numeraire.
*   "Unfix" the price of X and fix the wage rate:

P.UP("g1") = +inf;
P.LO("g1") = 1e-5;
PF.FX("labor") = 1;

$include JPMGE.GEN
solve jpmge using mcp;

equilibrium("X",  j,'D_elas=2,PF("l")=1')   = X.L(j);
equilibrium("P",  i,'D_elas=2,PF("l")=1')   = P.L(i);
equilibrium("PF", f,'D_elas=2,PF("l")=1')   = PF.L(f);
equilibrium(i,      j,'D_elas=2,PF("l")=1') = S.L(i,j)/X.L(j);
*! Can't display same variable with same indexing (overwrites) so add column
equilibrium(i,      j,'D D_elas=2,PF("l")=1') = D.L(i,j)/X.L(j);
equilibrium(f,    j,'D_elas=2,PF("l")=1')   = FD.L(f,j)/X.L(j);
equilibrium("Y","_",'D_elas=2,PF("l")=1')   = Y.L;
equilibrium("PY",  i,'D_elas=2,PF("l")=1')   = PY.L(i);

* equilibrium to a gdx for export to Excel
execute_unload "JPMGE.gdx" equilibrium
*
**=== Write to variable levels to Excel file from GDX 
**=== If we do not specify a sheet, data is placed in first sheet
execute 'gdxxrw.exe JPMGE.gdx o=MPSGEresults.xlsx par=equilibrium rng=JPMGE!'
execute 'gdxxrw.exe JPMGE.gdx o=C:\Users\Eli\.julia\dev\MPSGE\test\MPSGEresults.xlsx par=equilibrium rng=JPMGE!'
*
option decimals=8;
display equilibrium;