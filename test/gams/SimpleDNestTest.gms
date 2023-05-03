$title  Simple Model for Nested Demands
*Model Constructed to test Demand Nests against a model without the nest
*Demand nests are generally a feature to allow for the elasticity in the nest/for a consumer
*to be *different* than the overall production elasticities using those commodities, but
*here it is set up to have the same elasticities for testing purposes.

parameter   sigmac      Armington elasticity in final demand  /1/
            endow       change in labour supply      /1/
            sigmadm     Elasticity of substitution (D versus M) /1/
            esubkl      Elasticity of substitution (K versus L) /1/
            t_elasY     Tranformation elasticity in Y          /0/
            sigma       Elasticity of substitution (C versus LS) /1/
            
$ontext
$model:MGE123DN

$SECTORS:
        Y       ! Production
        A       ! Armington composite !This prod out for nested
        M       ! Imports
        

$COMMODITIES:
        PD      ! Domestic price index
        PM      ! Import price index
        PA      ! Armington price index !This prod out for nested
        PL      ! Wage rate index
        RK      ! Rental price index
        PFX     ! Foreign exchange
        PC
        PX

$CONSUMERS:
        HH      ! Private households
        C
        GOVT

$PROD:Y s:esubkl t:t_elasY
        O:PC    Q:60
        O:PFX   Q:130
        I:RK    Q:110   ! KD
        I:PL    Q:80   ! LY
$report:
     v:SCY   o:PC    prod:Y
     v:SFXY  o:PFX   prod:Y
     v:DKY   i:RK    prod:Y
     v:DLY   i:PL    prod:Y

$PROD:A  s:sigmadm t:0 !This whole Production out for nested
        O:PA    Q:90          
        I:PD    Q:30                          ! DA
        I:PM    Q:60
*$report: !(leave whole report commented out to run nested/non-nested with same results set)
*    v:SAA    o:PA    prod:A
*    v:DDA    i:PD    prod:A
*    v:DMA    i:PM    prod:A

$PROD:M s:1 t:0
        O:PX    Q:100
        I:PFX   Q:40   
        I:PC    Q:60
$report:
    v:SXM    o:PX     prod:M
    v:DFXM   i:PFX    prod:M
    v:DCM    i:PC     prod:M
        
$DEMAND:C  s:sigmac
       E:PD    Q:30       
       E:PM    Q:60
       D:PFX   Q:90
$report:
    v:CFXC    d:PFX    demand:C
       
$DEMAND:GOVT s:1 !  c:sigmadm  ! Take out "!" before the c:sigmadm for the Nested
        E:RK    Q:110
        D:PX    Q:20
        D:PA    Q:90
*        D:PD    Q:30   c:
*        D:PM    Q:60   c:
$report:    
     v:CXG    d:PX    demand:GOVT
*    v:CAG    d:PA    demand:GOVT ! Leave commented out to run nested/non-nested with same results set
*    v:CMG    d:PM    demand:GOVT ! Leave commented out to run nested/non-nested with same results set
*    v:CDG    d:PD    demand:GOVT ! Leave commented out to run nested/non-nested with same results set

$DEMAND:HH  s:sigma
        E:PL    Q:(80*endow)
        D:PX    Q:80
$report:
    v:W       w:HH
    v:CXHH    d:PX    demand:HH
  
$offtext
$sysinclude mpsgeset MGE123DN

MGE123DN.iterlim = 0;
$include MGE123DN.GEN
solve MGE123DN using mcp;
abort$(MGE123DN.objval > 1e-4) "Benchmark model does not calibrate.";
MGE123DN.iterlim = 10000;


parameter   report  Tariff Remove with Revenue Replacement (% impact);

$onechov >%gams.scrdir%report.gms
abort$(MGE123DN.objval > 1e-4) "Scenario fails to solve.";

*report("W","%replacement%") = (W.L);
report("Y","%replacement%") = (Y.L);
*report("A","%replacement%") = (A.L);
report("M","%replacement%") = (M.L);
report("PC","%replacement%") = (PC.L);
report("PD","%replacement%") = (PD.L);
report("PM","%replacement%") = (PM.L);
*report("PA","%replacement%") = (PA.L);
report("PX","%replacement%") = (PX.L);
report("PL","%replacement%") = (PL.L);
report("RK","%replacement%") = (RK.L);
report("PFX","%replacement%") = (PFX.L);
report("SCY","%replacement%") = (SCY.L/Y.L);
report("SFXY","%replacement%") = (SFXY.L/Y.L);
*report("SAA","%replacement%") = (SAA.L/A.L);
report("SXM","%replacement%") = (SXM.L/M.L);
report("DKY","%replacement%") = (DKY.L/Y.L);
report("DLY","%replacement%") = (DLY.L/Y.L);
*report("DDA","%replacement%") = (DDA.L/A.L);
*report("DMA","%replacement%") = (DMA.L/A.L);
report("DFXM","%replacement%") = (DFXM.L/M.L);
*report("DAM","%replacement%") = (DAM.L/M.L);
*report("C","%replacement%") = C.L;
report("GOVT","%replacement%") = GOVT.L;
report("HH","%replacement%") = (HH.L);
report("C","%replacement%") = (C.L);
report("CFXC","%replacement%") = (CFXC.L);
*report("CAG","%replacement%") = (CAG.L);
*report("CMG","%replacement%") = (CMG.L);
report("CXG","%replacement%") = (CXG.L);
report("CXHH","%replacement%") = (CXHH.L);

$offecho

$include MGE123DN.GEN
solve MGE123DN using mcp;
$set replacement Benchmark
$include %gams.scrdir%report
endow=1.1;
*1.1;
$include MGE123DN.GEN
solve MGE123DN using mcp;
$set replacement endow=1.1
$include %gams.scrdir%report
*endow=1.2;
*$include MGE123DN.GEN
*solve MGE123DN using mcp;
*$set replacement endow=1.2
*$include %gams.scrdir%report
*endow=1.3;
*$include MGE123DN.GEN
*solve MGE123DN using mcp;
*$set replacement endow=1.3
*$include %gams.scrdir%report
*endow=1.4;
*$include MGE123DN.GEN
*solve MGE123DN using mcp;
*$set replacement endow=1.4
*$include %gams.scrdir%report
*endow=1.5;
*$include MGE123DN.GEN
*solve MGE123DN using mcp;
*$set replacement endow=1.5
*$include %gams.scrdir%report
*endow=1.6;
*$include MGE123DN.GEN
*solve MGE123DN using mcp;
*$set replacement endow=1.6
*$include %gams.scrdir%report
*endow=1.7;
*$include MGE123DN.GEN
*solve MGE123DN using mcp;
*$set replacement endow=1.7
*$include %gams.scrdir%report
*endow=1.8;
*$include MGE123DN.GEN
*solve MGE123DN using mcp;
*$set replacement endow=1.8
*$include %gams.scrdir%report
*endow=1.9;
*$include MGE123DN.GEN
*solve MGE123DN using mcp;
*$set replacement endow=1.9
*$include %gams.scrdir%report
*endow=2.0;
*$include MGE123DN.GEN
*solve MGE123DN using mcp;
*$set replacement endow=2.0
*$include %gams.scrdir%report
sigmac=0.5;
$include MGE123DN.GEN
solve MGE123DN using mcp;
$set replacement sigmac=0.5
$include %gams.scrdir%report
sigmadm=4;
$include MGE123DN.GEN
solve MGE123DN using mcp;
$set replacement sigmadm=4
$include %gams.scrdir%report
sigma=0.4;
$include MGE123DN.GEN
solve MGE123DN using mcp;
$set replacement sigma=0.4
$include %gams.scrdir%report
esubkl=1.5;
$include MGE123DN.GEN
solve MGE123DN using mcp;
$set replacement esubkl=1.5
$include %gams.scrdir%report
t_elasY=1;
$include MGE123DN.GEN
solve MGE123DN using mcp;
$set replacement t_elasY=1
$include %gams.scrdir%report
endow=2;
GOVT.FX=110
$include MGE123DN.GEN
solve MGE123DN using mcp;
$set replacement endow=2
$include %gams.scrdir%report
sigmac=4;
$include MGE123DN.GEN
solve MGE123DN using mcp;
$set replacement sigmac=4
$include %gams.scrdir%report
sigma=3;
$include MGE123DN.GEN
solve MGE123DN using mcp;
$set replacement sigma=3
$include %gams.scrdir%report
t_elasY=0.5;
$include MGE123DN.GEN
solve MGE123DN using mcp;
$set replacement t_elY=0.5
$include %gams.scrdir%report
sigmac=.1;
$include MGE123DN.GEN
solve MGE123DN using mcp;
$set replacement sigmac=.1
$include %gams.scrdir%report
esubkl=0;
$include MGE123DN.GEN
solve MGE123DN using mcp;
$set replacement esubkl=0
$include %gams.scrdir%report

option decimals=8
display report;

execute_unload "MGE123DN.gdx" report

execute 'gdxxrw.exe MGE123DN.gdx o=MPSGEresults.xlsx par=report rng=SimpleDemNest!'
execute 'gdxxrw.exe MGE123DN.gdx o=C:\Users\Eli\.julia\dev\MPSGE\test\MPSGEresults.xlsx par=report rng=SimpleDemNest!'
