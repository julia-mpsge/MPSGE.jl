$TITLE BIGMPS

* 7040 WEAK INEQUALITIES AND COMPLEMENTARY NON-NEGATIVE VARIABLES
* high-dimension competitive model in Rutherford's mps/ge, using the path solver in GAMS
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
FX(F,G) factor f's share (intensity) in sector G
SCALE size of fringe countries;

$ONTEXT

$MODEL:BIGMPS

$SECTORS:
X(I,J,G) ! production activity for good G
EX(I,J,G) ! export activity for good G
IX(I,J,G) ! import activity for good G
XX(I,J,G) ! supply of domestically produced G to home
W(I,J) ! welfare of country ij

$COMMODITIES:
PW(I,J) ! utility price index for country j
PX(I,J,G) ! domestic producer price (mc) of good G
PCX(I,J,G) ! domestic consumer price of good G
PF(I,J,F) ! price of factor F in country ij
PFX(G) ! world (central market) price of good G

$CONSUMERS:
CONS(I,J) ! income of representative consumer in ij

$PROD:X(I,J,G) s:1
O:PX(I,J,G) Q:100
I:PF(I,J,F) Q:FX(F,G)

$PROD:EX(I,J,G)
O:PFX(G) Q:100
I:PX(I,J,G) Q:(100*TC(I))

$PROD:IX(I,J,G)
O:PCX(I,J,G) Q:100
I:PFX(G) Q:(100*TC(I))

$PROD:XX(I,J,G)
O:PCX(I,J,G) Q:100
I:PX(I,J,G) Q:100

$PROD:W(I,J) s:1
O:PW(I,J) Q:100
I:PCX(I,J,G) Q:100

$DEMAND:CONS(I,J)
D:PW(I,J) Q:(SUM(F, ENDOW(I,J,F)))
E:PF(I,J,F) Q:ENDOW(I,J,F)

$OFFTEXT
$SYSINCLUDE mpsgeset BIGMPS

* choose world price of central good G = 5 as numeraire

PFX.FX("6") = 1;

*here is the loop that sets the endowment of country j
*and the trade costs of country i

LOOP (I,
LOOP (J,

ENDOW(I,J,"K") = 120 - 10*ORD(J);
ENDOW(I,J,"L") = 10*ORD(J);

TC("9") = 1.0000025;
TC(I)$ (ORD(I) LT 9) = 1.45 - 0.05*ORD(I);

);
);

SCALE = 1;

*here is the loop that sets the factor shares (intensities) of
*sector G

LOOP (G,

FX("L",G) = 10*ORD(G);
FX("K",G) = 120 - 10*ORD(G);

);

$INCLUDE BIGMPS.GEN
SOLVE BIGMPS USING MCP;

PARAMETERS
PRODX(I,J,G) 1 if production of good G by country ij > 0
EXPORTX(I,J,G) 1 if exports of good G by country ij > 0
IMPORTX(I,J,G) 1 if imports of good G by country ij > 0
NOTRADEX(I,J,G) 1 if country ij neither imports or exports good G
VOT(I,J) total trade value of country I-J as share of income
WELFARE(I,J) welfare;

PRODX(I,J,G) = 1$(X.L(I,J,G) GT 0);
EXPORTX(I,J,G) = 1$(EX.L(I,J,G) GT 0);
IMPORTX(I,J,G) = 1$(IX.L(I,J,G) GT 0);
NOTRADEX(I,J,G) = 1$(PRODX(I,J,G) EQ 1 AND EXPORTX(I,J,G) EQ 0 AND IMPORTX(I,J,G) EQ 0);

VOT(I,J) = SUM(G, PFX.L(G)* (EX.L(I,J,G)*TC(I) + IX.L(I,J,G)))/ (CONS.L(I,J)/100);
WELFARE(I,J) = W.L(I,J)*11;

DISPLAY PRODX, EXPORTX, IMPORTX, NOTRADEX, VOT, TC, WELFARE;

$EXIT