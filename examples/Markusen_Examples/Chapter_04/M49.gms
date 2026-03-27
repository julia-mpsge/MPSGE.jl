$TITLE:  Model M49: 2X2X2 HECKSCHER-OHLIN MODEL
*  This is a full two-country HO model
$ONTEXT
     XHH  YHH  XHF  YHF  XFF  YFF  XFH  YFH   WH   WF   CONSH CONSF
PXH  150       -50                          -100 
PYH        50                            50 -100
PXF             50        50                     -100
PYF                           150       -50      -100
PWH                                          200        -200
PWF                                               200         -200
PLH -120  -10                                            130
PKH  -30  -40                                             70
PLF                      -40  -30                               70
PKF                      -10 -120                              130
$OFFTEXT
PARAMETERS
 TARH
 TARF;
TARH = 0;
TARF = 0;
$ONTEXT
$MODEL:M49
$SECTORS:
        WH
        WF
        XHH
        YHH
        XHF
        YHF
        XFF
        YFF
        XFH
        YFH
$COMMODITIES:
        PWH
        PWF
        PXH
        PXF
        PYH
        PYF
        PLH
        PLF
        PKH
        PKF
$CONSUMERS:
        CONSH
        CONSF
$PROD:XHH s:1
        O:PXH    Q:150
        I:PLH    Q:120
        I:PKH    Q: 30
$PROD:YHH s:1
        O:PYH    Q:50
        I:PLH    Q:10
        I:PKH    Q:40
$PROD:XFF s:1
        O:PXF    Q:50
        I:PLF    Q:40
        I:PKF    Q:10
$PROD:YFF s:1
        O:PYF    Q:150
        I:PLF    Q: 30
        I:PKF    Q:120
$PROD:XHF
        O:PXF    Q:50
        I:PXH    Q:50   A:CONSF  T:TARF
$PROD:YHF
        O:PYF    Q:50
        I:PYH    Q:50.1
$PROD:XFH
        O:PXH    Q:50
        I:PXF    Q:50.1
$PROD:YFH
        O:PYH    Q:50
        I:PYF    Q:50   A:CONSH  T:TARH
$PROD:WH  s:1
        O:PWH    Q:200
        I:PXH    Q:100
        I:PYH    Q:100
$PROD:WF  s:1
        O:PWF    Q:200
        I:PXF    Q:100
        I:PYF    Q:100
$DEMAND:CONSH
        D:PWH    Q:200
        E:PLH    Q:130
        E:PKH    Q: 70
$DEMAND:CONSF
        D:PWF    Q:200
        E:PLF    Q: 70
        E:PKF    Q:130
$OFFTEXT
$SYSINCLUDE mpsgeset M49
 YHF.L = 0.; XFH.L = 0.;
$INCLUDE M49.GEN
SOLVE M49 USING MCP;
* TARIFFS
TARH = .25;
$INCLUDE M49.GEN
SOLVE M49 USING MCP;
TARH = .25;
TARF = .25;
$INCLUDE M49.GEN
SOLVE M49 USING MCP;