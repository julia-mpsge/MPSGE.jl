**stitle Dataset for a 123 Model

set     mcmrow  Rows in the micro-consistent matrix /
                PFX     Current account,
                PD      Domestic ouputput
                TA      Sales and excise taxes
                TM      Import tariffs
                TX      Export taxes
                TK      Capital taxes
                TL      Labor taxes
                RK      Return to capital
                PL      Wage rate
                PA      Price of Armington composite /,

        mcmcol  Columns in the micro-consistent matrix /
                S       Supply,
                D       Demand,
                GOVT    Government,
                HH      Households
                INVEST  Investment /;

table mcm(mcmrow,mcmcol)  Microconsistent matrix

              S           D        GOVT          HH      INVEST

PFX     106.386    -144.701      38.315
PD      218.308    -218.308
TA                  -32.027      32.027
TM                  -18.617      18.617
TX       -1.136                   1.136
TK      -12.837                  12.837
TL       -3.539                   3.539
RK     -143.862                             143.862
PL     -163.320                             163.320
PA                  413.653     -35.583    -291.694     -86.376

*       Parameter values describing base year equilibrium:

parameter       px0     Reference price of exports
                d0      Reference domestic supply
                x0      Reference exports
                kd0     Reference net capital earnings
                ly0     Reference net labor earnings
                rr0     Reference price of capital
                pl0     Reference wage
                tk      Capital tax rate
                tl      Labor tax rate
                ta      Excise and sales tax rate
                tx      Tax on exports
                a0      Aggregate supply (gross of tax)
                g0      Government demand,
                dtax    Direct tax net transfers
                m0      Imports
                l0      Leisure demand
                c0      Household consumption,
                i0      Aggregate investment
                tm      Import tariff rate
                pm0     Reference price of imports
                pwm     World price of imports /1/
                pwx     World price of exports /1/
                bopdef  Balance of payments deficit
                etadx   Elasticity of transformation (D versus X) /4/,
                sigmadm Elasticity of substitution (D versus M) /4/,
                esubkl  Elasticity of substitution (K versus L) /1/,
                sigma   Elasticity of substitution (C versus LS) /0.4/
*                ;
* Added for nesting
                cd0    Final demand for domestic good
                cm0    Final demand for imports
                sigmac Armington elasticity in final demand /0.5/;

d0  = mcm("pd","s");
x0  = mcm("pfx","s");
kd0 = -mcm("rk","s");
ly0 = -mcm("pl","s");

tx  = -mcm("tx","s")/mcm("pfx","s");
tk  = mcm("tk","s")/mcm("rk","s");
tl  = mcm("tl","s")/mcm("pl","s");

px0 = 1 - tx;
rr0 = 1 + tk;
pl0 = 1 + tl;

parameter       profit  Zero profit check;
profit("PD") = d0;
profit("PX") = x0;
profit("TX") = -tx*x0;
profit("TK") = -tk*kd0;
profit("TL") = -tl*ly0;
profit("PL") = -ly0;
profit("RK") = -kd0;
alias (u,*);
profit("CHK") = sum(u, profit(u));
display profit, tx, tk, tl;

m0 = -mcm("pfx","d");
tm = mcm("tm","d")/mcm("pfx","d");
pm0 = 1 + tm;
a0 = mcm("pa","d");
g0 = -mcm("pa","govt");
ta = -mcm("ta","d")/mcm("pa","d");
bopdef = mcm("pfx","govt");
dtax = g0 - bopdef - tm*m0 - ta*a0 - tl*ly0 - tk*kd0 - tx*x0;
i0 = -mcm("pa","invest");
c0 = a0 - i0 - g0;
l0 = 0.75*ly0;
*Updated for nesting
m0 = pm0*m0;
* Set to use for a0 re-calculation
ta = a0*ta;
*   Impute final demand for domestic and imported goods:
cd0 = c0 * d0/(d0+m0);
cm0 = c0 * m0/(d0+m0);
*   Armington supply net final demand:
a0 = d0+m0-cd0-cm0+ta;
*   Recalibrate taxes on A so that tax revenue remains unchanged:
ta = ta/a0;


$title  Static 123 Model Ala Devarjan

$ontext
$model:MGE123

$SECTORS:
        Y       ! Production
        A       ! Armington composite
        M       ! Imports
        X       ! Exports

$COMMODITIES:
        PD      ! Domestic price index
        PX      ! Export price index
        PM      ! Import price index
        PA      ! Armington price index
        PL      ! Wage rate index
        RK      ! Rental price index
        PFX     ! Foreign exchange

$CONSUMERS:
        HH      ! Private households
        GOVT    ! Government

$AUXILIARY:
        TAU_LS  ! Lumpsum Replacement tax
        TAU_TL  ! Labor tax replacement
        UR      ! Unemployment rate

$PROD:Y  t:etadx s:esubkl
        O:PD    Q:d0    P:1                             ! YD
        O:PX    Q:x0    P:px0   A:GOVT  T:tx            ! YX
        I:RK    Q:kd0   P:rr0   A:GOVT  T:tk            ! KD
        I:PL    Q:ly0   P:pl0   A:GOVT  T:tl  N:TAU_TL   ! LY

$report:
         v:YD   o:PD    prod:Y
         v:YX   o:PX    prod:Y
         v:KD   i:RK    prod:Y
         v:LY   i:PL    prod:Y

$PROD:A  s:sigmadm
        O:PA    Q:a0    A:GOVT  t:ta
        I:PD    Q:(d0-cd0)      !d0            ! DA
        I:PM    Q:(m0-cm0) ! m0   p:pm0 A:GOVT t:tm  ! no price & no tax in the nested version...p:pm0 A:GOVT t:tm   ! MA

$report:
    v:PAA   o:PA    prod:A
    v:DA    i:PD    prod:A
    v:MA    i:PM    prod:A

$PROD:M
        O:PM    Q:m0
        I:PFX   Q:(pwm*m0/pm0) A:GOVT t:tm !Nested not(pwm*m0) !
$report:
       v:PMM    o:PM     prod:M
       v:PFXM   I:PFX    prod:M

$PROD:X
        O:PFX   Q:(pwx*x0)
        I:PX    Q:x0
$report:
       v:PXX    i:PX     prod:X
       v:PFXX   o:PFX    prod:X

$DEMAND:GOVT
        E:PFX   Q:bopdef
        E:PA    Q:dtax
        E:PA    Q:g0            R:TAU_LS
        D:PA
        
$report:
    v:CAG     d:PA    demand:GOVT

$CONSTRAINT:UR
*        PL =G= PA; !no inequality in MPSGE.jl to compare
        PL =e= PA;

$CONSTRAINT:TAU_LS
        GOVT =e= PA * g0;

$CONSTRAINT:TAU_TL
        GOVT =e= PA * g0;

$DEMAND:HH  s:sigma c:sigmac
        E:PA    Q:(-g0)         R:TAU_LS
        E:PA    Q:(-dtax)
        E:RK    Q:kd0
        E:PA    Q:(-i0)
        E:PL    Q:(ly0+l0)      ! Labor endowment = ly0+l0 - UR * (ly0+l0)
        E:PL    Q:(-(ly0+l0))   R:UR
*        D:PA    Q:c0 !not in nested
        D:PL    Q:l0
        D:PD    Q:cd0  c:
        D:PM    Q:cm0  c:

$report:
    v:W     w:HH
    v:CAHH  d:PA    demand:HH
    v:LD    d:PL    demand:HH

$offtext
$sysinclude mpsgeset mge123

UR.FX = 0;
TAU_TL.FX = 0;
TAU_LS.UP =  INF;
TAU_LS.LO = -INF;

Parameter   report As (% impact) Tariff Remove with Revenue Replacement;

$onechov >%gams.scrdir%report.gms
*abort$(mge123.objval > 1e-4) "Scenario fails to solve.";

*report("W","%replacement%","%labormarket%") = 100*(W.L-1);
*report("Y","%replacement%","%labormarket%") = 100*(Y.L-1);
*report("A","%replacement%","%labormarket%") = 100 * (A.L-1);
*report("M","%replacement%","%labormarket%") = 100 * (M.L-1);
*report("X","%replacement%","%labormarket%") = 100 * (X.L-1);
*report("YD","%replacement%","%labormarket%") = 100 * (YD.L/d0-1);
*report("YX","%replacement%","%labormarket%") = 100 * (YX.L/x0-1);
*report("KD","%replacement%","%labormarket%") = 100 * (KD.L/kd0-1);
*report("LY","%replacement%","%labormarket%") = 100 * (LY.L/ly0-1);
*report("DA","%replacement%","%labormarket%") = 100 * (DA.L/d0-1);
*report("MA","%replacement%","%labormarket%") = 100 * (MA.L/m0-1);
*report("CAHH","%replacement%","%labormarket%") = (CAHH.L);
*report("CAG","%replacement%","%labormarket%") = (CAG.L);
*report("LD","%replacement%","%labormarket%") = 100 * (LD.L/l0-1);
*report("PD","%replacement%","%labormarket%") = 100 * (PD.L/PL.L - 1);
*report("PX","%replacement%","%labormarket%") = 100 * (PX.L/PL.L - 1);
*report("PM","%replacement%","%labormarket%") = 100 * (PM.L/PL.L - 1);
*report("PA","%replacement%","%labormarket%") = 100 * (PA.L/PL.L - 1);
*report("PPA","%replacement%","%labormarket%") = (PA.L);
*report("PL","%replacement%","%labormarket%") = 100 * (PL.L/PL.L - 1);
*report("RK","%replacement%","%labormarket%") = 100 * (RK.L/PL.L - 1);
*report("PFX","%replacement%","%labormarket%") = 100 * (PFX.L/PL.L - 1);
*report("HH","%replacement%","%labormarket%") = 100 * (HH.L/PL.L - 1);
*report("GOVT","%replacement%","%labormarket%") = 100 * (GOVT.L/PL.L - 1);
*
*report("TAU_TL","%replacement%","%labormarket%") = 100*TAU_TL.L;
*report("UR","%replacement%","%labormarket%") = 100*UR.L;

report("Y","%replacement%") =Y.L;
report("A","%replacement%") =A.L;
report("M","%replacement%") =M.L;
report("X","%replacement%") =X.L;
report("PD","%replacement%") =PD.L;
report("PX","%replacement%") =PX.L;
report("PM","%replacement%") =PM.L;
report("PA","%replacement%") =PA.L;
report("PL","%replacement%") =PL.L;
report("RK","%replacement%") =RK.L;
report("PFX","%replacement%") =PFX.L;
report("YD","%replacement%") =YD.L/Y.L;
report("YX","%replacement%") =YX.L/Y.L;
report("KD","%replacement%") =KD.L/Y.L;
report("LY","%replacement%") =LY.L/Y.L;
report("DA","%replacement%") =DA.L/A.L;
report("MA","%replacement%") =MA.L/A.L;
report("CAHH","%replacement%") =CAHH.L;
report("CAG","%replacement%") =CAG.L;
report("LD","%replacement%") =LD.L;
report("HH","%replacement%") =HH.L;
report("GOVT","%replacement%") =GOVT.L;
report("PAA","%replacement%") =PAA.L/A.L;
report("PMM","%replacement%") =PMM.L/M.L;
report("PFXX","%replacement%") =PFXX.L/X.L;
report("PFXM","%replacement%") =PFXM.L/M.L;
report("PXX","%replacement%") =PXX.L/X.L;

report("TAU_LS","%replacement%") =TAU_LS.L;
report("TAU_TL","%replacement%") =TAU_TL.L;
report("UR","%replacement%") = UR.L;

report("W","%replacement%") =W.L;

$offecho

mge123.iterlim = 0;
$include MGE123.GEN
solve mge123 using mcp;
*abort$(mge123.objval > 1e-4) "Benchmark model does not calibrate.";

$set replacement Benchmark
$set labormarket N
$include %gams.scrdir%report

mge123.iterlim = 10000;

*mge123.savepoint = 2;

*   Tariff reform:

tm = 0;

UR.FX = 0;
TAU_LS.UP = +inf;
TAU_LS.LO = -inf;
TAU_TL.FX = 0;
$include MGE123.GEN
solve mge123 using mcp;

$set replacement Lump Sum F
*$set labormarket Flexible
$include %gams.scrdir%report

UR.FX = 0;
TAU_TL.UP = +inf;
TAU_TL.LO = -inf;
TAU_LS.FX = 0;
$include MGE123.GEN
solve mge123 using mcp;

$set replacement Wage Tax F
*$set labormarket Flexible
$include %gams.scrdir%report

UR.LO = 0;
UR.UP = +inf;
TAU_LS.UP = +inf;
TAU_LS.LO = -inf;
TAU_TL.FX = 0;
$include MGE123.GEN
solve mge123 using mcp;

$set replacement Lump Sum R
*$set labormarket Rigid Wage
$include %gams.scrdir%report

UR.LO = 0;
UR.UP = +inf;
TAU_TL.UP = +inf;
TAU_TL.LO = -inf;
TAU_LS.FX = 0;
$include MGE123.GEN
solve mge123 using mcp;

$set replacement Wage Tax R
*$set labormarket Rigid Wage
$include %gams.scrdir%report

*option report:7:1:2;
option decimals=7;
display report;

execute_unload "123.gdx" report
*=== Write to variable levels to Excel file from GDX 
*=== If we do not specify a sheet, data is placed in first sheet
*execute 'gdxxrw.exe 123.gdx o=MPSGEresults.xlsx par=report rng=The123!'
*execute 'gdxxrw.exe 123.gdx o=C:\Users\Eli\.julia\dev\MPSGE\test\MPSGEresults.xlsx par=report rng=The123!'
*