$TITLE: SMALLMODEL MPS/GE VERSION

$ONTEXT
two goods, two factors, one consumer in MPS/GE format
compares a tax and a (iceberg) transactions cost
and showing the substantial difference between the two

| Markets | X   | Y   | W    | CONS |
| ---     | --- | --- | ---  | ---  |
| PX      | 100 |     | -100 |      |
| PY      |     | 100 | -100 |      |
| PL      | -25 | -75 |      | 100  |
| PK      | -75 | -25 |      | 100  |
| PW      |     |     | 200  | -200 |

$OFFTEXT

PARAMETERS

TR ad-valorem tax rate for X sector inputs
TC iceberg transport (trade) cost on X
LBAR labor endowment
KBAR capital endowment;

LBAR = 100;
KBAR = 100;
TR = 0; TC = 0;

$ONTEXT
$MODEL:SMALLMPS

$SECTORS:
X ! Activity level for sector X
Y ! Activity level for sector Y
W ! Activity level for sector W (welfare index)

$COMMODITIES:
PX ! Price index for commodity X
PY ! Price index for commodity Y
PL ! Price index for primary factor L
PK ! Price index for primary factor K
PW ! Price index for welfare (expenditure function)

$CONSUMERS:
CONS ! Income level for consumer CONS

$PROD:X s:1
O:PX Q:(100/(1+TC))
I:PL Q:25 A:CONS T:TR
I:PK Q:75 A:CONS T:TR

$PROD:Y s:1
O:PY Q:100
I:PL Q:75
I:PK Q:25

$PROD:W s:1
O:PW Q:200
I:PX Q:100
I:PY Q:100

$DEMAND:CONS
D:PW Q:200
E:PL Q:LBAR
E:PK Q:KBAR

$OFFTEXT
$SYSINCLUDE mpsgeset SMALLMPS

PW.FX = 1;

$INCLUDE SMALLMPS.GEN
SOLVE SMALLMPS USING MCP;

* SHOW HOW TO DO MULTIPLE SCENARIOS
* SHOW DIFFERENCE BETWEEN TARIFF AND TRADE COST OF EQUAL RATES

SETS T indexes 25 different gross cost levels /T1*T25/
J indexes 2 scenarios: 1 = tariff 2 = trade cost /J1*J2/;

PARAMETERS
RATE (T) net tax or trade cost rate (gross rate minus 1)
WELFARE (T, J) welfare normalized to equal 1 in benchmark
RESULTS (T, *) formats results in one table;

LOOP (J,
LOOP (T,

TC = 0; TR = 0;
RATE (T) = 0.05*ORD (T) - 0.05;
TR$ (ORD (J) EQ 1) = RATE (T);
TC$ (ORD (J) EQ 2) = RATE (T);

$INCLUDE SMALLMPS.GEN
SOLVE SMALLMPS USING MCP;

WELFARE (T, J) = W.L;

);

);

RESULTS (T, "RATE") = RATE (T);
RESULTS (T, "WELTR") = WELFARE (T, "J1");
RESULTS (T, "WELTC") = WELFARE (T, "J2");

DISPLAY RESULTS;

DISPLAY WELFARE;

* Write parameter RESULTS to an Excel file SMALLMPS.XLS,
* starting in Sheet1

*Execute_Unload 'SMALL.gdx' RESULTS
*execute 'gdxxrw.exe SMALL.gdx par=RESULTS rng=SHEET2!A3'