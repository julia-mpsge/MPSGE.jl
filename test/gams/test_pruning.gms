
$ontext
$MODEL:prune

$SECTORS:
    X
    Y
    W

$COMMODITIES:
    PX
    PY
    PW
    PL
    PK

$CONSUMERS:
    CONS

$PROD:X s:.5 va:1 !t:0
        O:PX    Q:120
        I:PY    Q:20
        I:PL    Q:40 va: A:CONS T:0.5
        I:PK    Q:60 va: A:CONS T:0.5

$PROD:Y s:.75 va:1 !t:0
        O:PY    Q:120
        I:PX    Q:20
        I:PL    Q:60    va:
        I:PK    Q:40    va:

$PROD:W s:1 !t:0
        O:PW   Q:200
        I:PX   Q:100
        I:PY   Q:100

$DEMAND:CONS
        D:PW   Q:200
        E:PL   Q:100
        E:PK   Q:100

$offtext


$sysinclude mpsgeset prune

*prune.iterlim = 0;

CONS.fx = 200;

$include prune.GEN
solve prune using mcp;