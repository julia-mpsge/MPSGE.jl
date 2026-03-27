$TITLE  Model M35: Closed 2x2 Economy - Public Output with Samuelson Rule
*  This model is the same as M34 except that the tax to finance the 
*  public good is set endogenously 
PARAMETER
 VG1  Preference index for public goods for consumer 1;
VG1 = 1;
$ONTEXT
$MODEL:M35
$SECTORS:
     X       ! Activity level for sector X
     Y       ! Activity level for sector Y
     G       ! Activity level for sector G  (public provision)
     W1      ! Activity level for sector W1 (consumer 1 welfare index)
     W2      ! Activity level for sector W2 (consumer 2 welfare index)
$COMMODITIES:
     PX      ! Price index for commodity X
     PY      ! Price index for commodity Y
     PG      ! Price index for commodity G (marg cost of public output)
     PL      ! Price index for primary factor L (net of tax)
     PK      ! Price index for primary factor K
     PW1     ! Price index for welfare (consumer 1)
     PW2     ! Price index for welfare (consumer 2)
     PG1     ! Private valuation of the public good (consumer 1)
     PG2     ! Private valuation of the public good (consumer 2)
$CONSUMERS:
     CONS1   ! Consumer 1
     CONS2   ! Consumer 2
     GOVT    ! Government
$AUXILIARY:
     LGP     ! Level of government provision
     TAX     ! Uniform value-added tax rate
$PROD:X  s:1
        O:PX    Q:100
        I:PL    Q: 50  P:1.25  A:GOVT  N:TAX
        I:PK    Q: 30  P:1.25  A:GOVT  N:TAX
$PROD:Y  s:1
        O:PY    Q:100
        I:PL    Q: 30  P:1.25  A:GOVT  N:TAX
        I:PK    Q: 50  P:1.25  A:GOVT  N:TAX
$PROD:G  s:1
        O:PG    Q: 50
        I:PL    Q: 20  P:1.25  A:GOVT  N:TAX
        I:PK    Q: 20  P:1.25  A:GOVT  N:TAX
$PROD:W1 s:1
        O:PW1   Q:125
        I:PX    Q: 70 
        I:PY    Q: 30
        I:PG1   Q:(VG1*50)  P:0.5
$PROD:W2 s:1
        O:PW2   Q:125
        I:PX    Q: 30
        I:PY    Q: 70
        I:PG2   Q: 50  P:0.5
$DEMAND:GOVT
        D:PG
$DEMAND:CONS1
        D:PW1   Q:125
        E:PL    Q: 50
        E:PK    Q: 50
        E:PG1   Q: 50  R:LGP
$DEMAND:CONS2
        D:PW2   Q:125
        E:PL    Q: 50
        E:PK    Q: 50
        E:PG2   Q: 50  R:LGP
$CONSTRAINT:LGP
        LGP =E= G;
$CONSTRAINT:TAX
        PG =E= PG1 + PG2;
$OFFTEXT
$SYSINCLUDE mpsgeset M35

*       Benchmark replication
TAX.L = 0.25;
LGP.L = 1;
PG1.L = 0.5;
PG2.L = 0.5;
M35.ITERLIM = 0;
$INCLUDE M35.GEN
SOLVE M35 USING MCP;
M35.ITERLIM = 2000;
*       What happens to consumer 2 welfare if consumer 1 decides
*       she would like more public output:
VG1 = 2;
$INCLUDE M35.GEN
SOLVE M35 USING MCP;