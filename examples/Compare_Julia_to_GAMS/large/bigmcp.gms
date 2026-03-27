$TITLE BIGMCP

* 7040 WEAK INEQUALITIES AND COMPLEMENTARY NON-NEGATIVE VARIABLES
* high-dimension competitive model in mcp format, using the path solver in GAMS
* there are 99 countries (need an odd number for middle country), sets I, J
* two factors, set F
* eleven goods, set G
* countries have double index ij: trade cost i, endowment j (11x9 matrix of countries)

* exploits complementarity: e.g., the subset of goods that each country produces
* and what trade links are active/inactive and direction of trade

SETS
I countries trade cost /1*9/,
J countries endowment ratio /1*11/,
F factors of production /L,K /
G goods /1*11/;

PARAMETERS
TC(I) trade cost of country i,
ENDOW(I,J,F) country ij's endowment of factor F,
FX(F,G) factor f's share (intensity) in sector G;

NONNEGATIVE VARIABLES
X(I,J,G) production activity for good G
EX(I,J,G) export activity for good G
IX(I,J,G) import activity for good G
XX(I,J,G) supply of domestically produced G to home
W(I,J) welfare of country ij

PW(I,J) utility price index for country j
PX(I,J,G) domestic producer price (mc) of good G
PCX(I,J,G) domestic consumer price of good G
PF(I,J,F) price of factor F in country ij
PFX(G) world (central market) price of good G

CONS(I,J) income of representative consumer in ij;

EQUATIONS
COSTX(I,J,G) pricing inequality for X (mc >= p)
COSTEX(I,J,G) pricing inequality for exports of X
COSTIM(I,J,G) pricing inequality for imports of X
COSTXX(I,J,G) pricing inequality for domestic sales of X
COSTW(I,J) pricing inequality of welfare

MKTPW(I,J) market clearing for W (supply >= demand)
MKTPX(I,J,G) market clearing inequality for X = XX + XE
MKTPCX(I,J,G) market clearing inequality for supply XX + imports IX >= consumer demand
MKTPF(I,J,F) market clearing inequality for factor f in each country
MKTPFX(G) market clearing inequality for world price of good G (world exports = imports)

ICONS(I,J) income balance for representative consumer in country ij;

COSTX(I,J,G) .. PROD(F, PF(I,J,F)**FX(F,G)) =G= PX(I,J,G);
COSTEX(I,J,G) .. PX(I,J,G)*TC(I) =G= PFX(G);
COSTIM(I,J,G) .. PFX(G)*TC(I) =G= PCX(I,J,G);
COSTXX(I,J,G) .. PX(I,J,G) =G= PCX(I,J,G);
COSTW(I,J) .. PROD(G, PCX(I,J,G)**(1/11)) =G= PW(I,J);



MKTPW(I,J).. W(I,J) =G= CONS(I,J)/PW(I,J);

MKTPX(I,J,G).. X(I,J,G) =G= XX(I,J,G) + EX(I,J,G);

MKTPCX(I,J,G).. XX(I,J,G) + IX(I,J,G) =G= (1/CARD(J))*CONS(I,J)/PCX(I,J,G);

MKTPF(I,J,F).. ENDOW(I,J,F) =G= SUM(G, FX(F,G)*PX(I,J,G)/PF(I,J,F)*X(I,J,G));

MKTPFX(G).. SUM((I,J), EX(I,J,G)/TC(I) - TC(I)*IX(I,J,G)) =E= 0;

ICONS(I,J).. CONS(I,J) =G= SUM(F, PF(I,J,F)*ENDOW(I,J,F));

* model declaration matches weak inequalities with complementary non-negative variables

MODEL BIGMCP /
COSTX.X,
COSTEX.EX,
COSTIM.IX,
COSTXX.XX,
COSTW.W,
MKTPW.PW,
MKTPX.PX,
MKTPCX.PCX,
MKTPF.PF,
MKTPFX.PFX,
ICONS.CONS /;

* starting values to help the solver
X.L(I,J,G) = 100;
EX.L(I,J,G) = 10;
IX.L(I,J,G) = 10;
XX.L(I,J,G) = 100;
W.L(I,J) = 120;
PW.L(I,J) = 1;
PX.L(I,J,G) = 1;
PCX.L(I,J,G) =1;
PF.L(I,J,F) = 1;
PFX.L(G) = 1;
CONS.L(I,J) = 120;

* choice of numeraire (world price of central good J = 6)
PFX.FX("6") = 1;

*here is the loop that sets the endowment of country j
*and the trade costs of country i

LOOP(I,
LOOP(J,

ENDOW(I,J,"K") = 120 - 10*ORD(J);
ENDOW(I,J,"L") = 10*ORD(J);

TC("9") = 1.0000025;
TC(I)$ (ORD(I) LT 9) = 1.45 - 0.05*ORD(I);

);

);

*here is the loop that sets the factor shares (intensities) of
*sector G

LOOP(G,

FX("L",G) = (10*ORD(G))/120;
FX("K",G) = (120 - 10*ORD(G))/120;

);

SOLVE BIGMCP USING MCP;

PARAMETERS
PRODX(I,J,G) 1 if production of good G by country ij > 0
EXPORTX(I,J,G) 1 if exports of good G by country ij > 0
IMPORTX(I,J,G) 1 if imports of good G by country ij > 0
NOTRADEX(I,J,G) 1 if country ij neither imports or exports good G
VOT(I,J) total trade value of country I-J as share of income
WELFARE(I,J) welfare; 

PRODX(I,J,G) = 1$ (X.L(I,J,G) GT 0);
EXPORTX(I,J,G) = 1$ (EX.L(I,J,G) GT 0);
IMPORTX(I,J,G) = 1$ (IX.L(I,J,G) GT 0);
NOTRADEX(I,J,G) = 1$ (PRODX(I,J,G) EQ 1 AND EXPORTX(I,J,G) EQ 0 AND IMPORTX(I,J,G) EQ 0);

VOT(I,J) = SUM(G, PFX.L(G) * (EX.L(I,J,G) + IX.L(I,J,G))) / (CONS.L(I,J));
WELFARE(I,J) = W.L(I,J)/120;

DISPLAY PRODX, EXPORTX, IMPORTX, NOTRADEX, VOT, TC, WELFARE;

$EXIT

Execute_Unload 'BIG.gdx' VOT
execute 'gdxxrw.exe BIG.gdx par=VOT rng=SHEET3!A3:M15'
Execute_Unload 'BIG.gdx' WELFARE
execute 'gdxxrw.exe BIG.gdx par=WELFARE rng=SHEET4!B3:N15'

$EXIT
* this is for calculating autarky welfare
TC(I) = 5;
SOLVE BIGMCP USING MCP;

WELFARE(I,J) = W.L(I,J)/120;
DISPLAY WELFARE;

Execute_Unload 'BIG.gdx' WELFARE
execute 'gdxxrw.exe BIG.gdx par=WELFARE rng=SHEET6!B3:N15'

&lt;page_number&gt;3&lt;/page_number&gt;