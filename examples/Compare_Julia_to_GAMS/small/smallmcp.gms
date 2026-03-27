$TITLE: SMALLMODEL MCP VERSION

$ONTEXT two goods, two factors, one consumer in MCP format compares a tax and a (iceberg) transactions cost and showing the substantial difference between the two

Production Sectors	Consumers
Markets	X	Y	W	I
PX	100		-100	
PY		100	-100	
PL	-25	-75		100
PK	-75	-25		100
PW			200	-200
$OFFTEXT

PARAMETERS

TR ad valorem tax for X sector inputs on a NET basis 
TC iceberg transportation (trade) cost on X on a NET basis 
LBAR labor endowment 
KBAR capital endowment;

LBAR = 100; KBAR = 100; TR = 0; TC = 0;

NONNEGATIVE VARIABLES

W activity level for utility or welfare 
X activity level for X production 
Y activity level for Y production

PL price of labor 
PK price of capital 
PX price of good X 
PY price of good Y 
PW price of welfare (expenditure function)

I income of the representative consumer;

EQUATIONS

PRF_W zero profit for welfare
PRF_X zero profit for sector X 
PRF_Y zero profit for sector Y

MKT_L supply-demand balance for primary factor L 
MKT_K supply-demand balance for primary factor K 
MKT_X supply-demand balance for commodity X 
MKT_Y supply-demand balance for commodity Y 
MKT_W supply-demand balance for welfare

INC_I income balance;

* Zero profit inequalities
PRF_W.. PX**0.5 * PY**0.5 =G= PW;

PRF_X.. PL**0.25 * PK**0.75 * (1+TC) * (1+TR) =G= PX;

PRF_Y.. PL**0.75 * PK**0.25 =G= PY;

* Market clearance inequalities
MKT_L.. LBAR =G= 0.25*(PK/PL)**0.75*X + 0.75*(PK/PL)**0.25*Y;

MKT_K.. KBAR =G= 0.75*(PL/PK)**0.25*X + 0.25*(PL/PK)**0.75*Y;

MKT_X.. X/(1+TC) =G= 0.5*W*PW/PX;

MKT_Y.. Y =G= 0.5*W*PW/PY;

MKT_W.. W =G= I/PW;

* Income balance equation
INC_I.. I =E= LBAR*PL + KBAR*PK + TR*(PL**0.25*PK**0.75)*X;

MODEL SMALLMCP /PRF_W.W, PRF_X.X, PRF_Y.Y, MKT_L.PL, MKT_K.PK, MKT_X.PX, MKT_Y.PY, MKT_W.PW, INC_I.I /;

* Chose a numeraire: price of U fixed (.FX) at 1
PW.FX = 1;

* Set initial values of variables (.L notation after variable)
X.L=100; Y.L=100; W.L = 200; I.L=200; PX.L=1; PY.L=1; PK.L=1; PL.L=1; PW.L = 1;

SOLVE SMALLMCP USING MCP;

* SHOW HOW TO DO MULTIPLE SCENARIOS
* SHOW DIFFERENCE BETWEEN TARIFF AND TRADE COST OF EQUAL RATES
SETS T indexes 25 different gross cost levels /T1*T25/ 
     J indexes 2 scenarios: 1 = tariff 2 = trade cost /J1*J2/;

PARAMETERS 
    RATE (T) net tax or trade cost rate (gross rate minus 1) 
    WELFARE(T,J) welfare normalized to equal 1 in benchmark 
    RESULTS(T, *) formats results in one table;



LOOP(J, LOOP(T,

TC = 0; TR = 0; 
RATE (T) = 0.05*ORD (T) - 0.05; 
TR$ (ORD (J) EQ 1) = RATE (T); 
TC$ (ORD (J) EQ 2) = RATE (T);

SOLVE SMALLMCP USING MCP;

WELFARE (T,J) = W.L;

); );

RESULTS(T, "RATE") = RATE(T); 
RESULTS(T, "WELTR") = WELFARE(T, "J1") / 200; 
RESULTS(T, "WELTC") = WELFARE(T, "J2") / 200;

DISPLAY RESULTS;

* Write parameter RESULTS to an Excel file SMALL.XLS,
* starting in Sheet1
* Execute_Unload 'SMALL.gdx' RESULTS 
* execute 'gdxxrw.exe SMALL.gdx par=RESULTS rng=SHEET1!A3'
