
parameter 
    endow /70/
    diff /50/;

$ontext
$MODEL:benchmark_theta

$SECTORS:
    X   ! Activity level for sector X -- benchmark=1
    Y   ! Activity level for sector Y -- benchmark=1
    U   ! Activity level for sector U -- benchmark=1

$COMMODITIES:
    PX  ! Relative price index for commodity X -- benchmark=1
    PY  ! Relative price index for commodity Y -- benchmark=1
    PU  ! Relative price index for commodity U -- benchmark=1
    PL  ! Relative price index for labor -- benchmark=1
    PK  ! Relative price index for capital -- benchmark=1

$CONSUMERS:
    RA  ! Income level for representative agent 

$PROD:X s:1 !t:0
        O:PX   Q:100
        I:PL   Q:diff
        I:PK   Q:50

$PROD:Y s:1 !t:0
        O:PY   Q:50
        I:PL   Q:20
        I:PK   Q:30

$PROD:U s:1 !t:0
        O:PU   Q:150
        I:PX   Q:100
        I:PY   Q:50

$DEMAND:RA
        D:PU   Q:150
        E:PL   Q:(endow) 
        E:PK   Q:80

$offtext


$sysinclude mpsgeset benchmark_theta

benchmark_theta.iterlim = 0;

$include benchmark_theta.GEN
solve benchmark_theta using mcp;


diff = 60;
RA.FX = 150;
*   Solve the model with the default normalization of prices which 
*   fixes the income level of the representative agent.  The RA
*   income level at the initial prices equals 80 + 1.1*70 = 157.

*RA.FX = 80 + 1.1 * 70;
benchmark_theta.iterlim = 1000;
$include benchmark_theta.GEN
solve benchmark_theta using mcp;