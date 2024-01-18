$TITLE Accounting model to Verify Benchmark and Consistency of MGE and MCP Models

*	Matrix balancing method defines which dataset is loaded

$if not set matbal $set matbal ls
*$if not set matbal $set matbal National

$set sep %system.dirsep%

*$if not set ds $set ds data%sep%national_%matbal%%sep%nationaldata_%matbal%.gdx
$if not set ds $set ds nationaldata_ls.gdx

*$if not set run $set run 1997*2017
$if not set run $set run 2017

SET	yr	"Years in WiNDC Database",
   	i	"BEA Goods and sectors categories",
   	fd	"BEA Final demand categories",
   	ts	"BEA Taxes and subsidies categories",
   	va	"BEA Value added categories excluding othtax",
   	m	"Margins (trade or transport)";


$GDXIN %ds%
$LOADDC yr i va fd ts m

set	run(yr)		Which years do we run /%run%/;


alias (i,j);

PARAMETER
	y_0(yr,i)	"Gross output",
	ys_0(yr,j,i)	"Sectoral supply",
	ty_0(yr,j)	"Output tax rate"
	fs_0(yr,i)	"Household supply",
	id_0(yr,i,j)	"Intermediate demand",
	fd_0(yr,i,fd)	"Final demand",
	va_0(yr,va,j)	"Value added",
	ts_0(yr,ts,i)	"Taxes and subsidies",
	m_0(yr,i)	"Imports",
	x_0(yr,i)	"Exports of goods and services",
	mrg_0(yr,i)	"Trade margins",
	trn_0(yr,i)	"Transportation costs",
	duty_0(yr,i)	"Import duties",
	sbd_0(yr,i)	"Subsidies on products",
	tax_0(yr,i)	"Taxes on products",
	ms_0(yr,i,m)	"Margin supply",
	md_0(yr,m,i)	"Margin demand",
	s_0(yr,i)	"Aggregate supply",
	d_0(yr,i)	"Sales in the domestic market",
	a_0(yr,i)	"Armington supply",
	bopdef_0(yr)	"Balance of payments deficit",
	ta_0(yr,i)	"Tax net subsidy rate on intermediate demand",
	tm_0(yr,i)	"Import tariff";

$loaddc y_0 ys_0 ty_0 fs_0 id_0 fd_0 va_0 m_0
$loaddc x_0 ms_0 md_0 a_0 ta_0 tm_0
$gdxin

*	Parameters describing a single year:

PARAMETER
	y0(i)		"Gross output",
	ys0(j,i)	"Sectoral supply",
	ty0(j)		"Output tax rate",
	fs0(i)		"Household supply",
	id0(i,j)	"Intermediate demand",
	fd0(i,fd)	"Final demand",
	va0(va,j)	"Vaue added",
	ts0(ts,i)	"Taxes and subsidies",
	m0(i)		"Imports",
	x0(i)		"Exports of goods and services",
	mrg0(i)		"Trade margins",
	trn0(i)		"Transportation costs",
	duty0(i)	"Import duties",
	sbd0(i)		"Subsidies on products",
	tax0(i)		"Taxes on products",
	ms0(i,m)	"Margin supply",
	md0(m,i)	"Margin demand",
	s0(i)		"Aggregate supply",
	d0(i)		"Sales in the domestic market",
	a0(i)		"Armington supply",
	bopdef		"Balance of payments deficit",
	ta0(i)		"Tax net subsidy rate on intermediate demand",
	tm0(i)		"Import tariff",

	ty(j)	"Output tax rate",
	ta(i)	"Tax net subsidy rate on intermediate demand",
	tm(i)	"Import tariff";

sets	y_(j)	"Sectors with positive production",
	a_(i)	"Sectors with absorption",
	py_(i)	"Goods with positive supply",
	xfd(fd) "Exogenous components of final demand";

$ontext
$model:accounting

$sectors:
	Y(j)$y_(j)	!	Sectoral production
	A(i)$a_(i)	!	Armington supply
	MS(m)		!	Margin supply

$commodities:
	PA(i)$a0(i)	!	Armington price
	PY(i)$py_(i)	!	Supply
	PVA(va)		!	Value-added
	PM(m)		!	Margin
	PFX		!	Foreign exchnage

$consumer:
	RA		!	Representative agent

$prod:Y(j)$y_(j)  s:0 va:1
	o:PY(i)		q:ys0(j,i)	a:RA  t:ty(j)
	i:PA(i)		q:id0(i,j)
	i:PVA(va)	q:va0(va,j)	va:

$prod:MS(m)
	o:PM(m)		q:(sum(i,ms0(i,m)))
	i:PY(i)		q:ms0(i,m)

$prod:A(i)$a_(i)  s:0  t:2 dm:2
	o:PA(i)		q:a0(i)			a:ra	t:ta(i)	p:(1-ta0(i))
	o:PFX		q:x0(i)
	i:PY(i)		q:y0(i)		dm:
	i:PFX		q:m0(i)		dm: 	a:ra	t:tm(i)	p:(1+tm0(i))
	i:PM(m)		q:md0(m,i)

$demand:RA  s:1
	d:PA(i)		q:fd0(i,"pce")
	e:PY(i)		q:fs0(i)
	e:PFX		q:bopdef
	e:PA(i)		q:(-sum(xfd,fd0(i,xfd)))
	e:PVA(va)	q:(sum(j,va0(va,j)))

$report:
	v:C(i)		d:PA(i)		demand:RA
       v:CWI    W:RA
       V:DPYA(i)     I:PY(i)      prod:A(i)
       V:DPYMS(m,i)  I:PY(i)        prod:MS(m)
       v:SPAA(i) O:PA(i)       prod:A(i)
       v:SPMMS(m)       O:PM(m)    prod:MS(m)
*       v:DPMA(i,m)    I:PM(m)      prod:A(i)
       v:DPARA(i)          D:PA(i)      demand:RA

$offtext
$SYSINCLUDE mpsgeset accounting -mt=1

*	----------------------------------------------------------------------------------------

Nonnegative
Variables
	Y(j)		Sectoral production
	A(i)		Armington supply
	MS(m)		Margin supply

	PA(i)		Armington price
	PY(i)		Supply
	PVA(va)		Value-added
	PM(m)		Margin
	PFX		Foreign exchnage

	RA		Representative agent

equations
	prf_Y(j)	Zero profit for sectoral production
	prf_A(i)	Zero profit for Armington supply
	prf_MS(m)	Zero profit for margin supply

	bal_RA		Income balance for representative agent

	mkt_PA(i)	Market clearance for Armington price
	mkt_PY(i)	Market clearance for supply price
	mkt_PVA(va)	Market clearance for value-added
	mkt_PM(m)	Market clearance for margin
	mkt_PFX		Market clearance for foreign exchnage;

$echo	* Benchmark assignments for accounting_mcp		>%gams.scrdir%accounting_mcp.gen

* $prod:Y(j)$y_(j)  s:0 va:1
* 	o:PY(i)		q:ys0(j,i)  a:RA t:ty0(j)
* 	i:PA(i)		q:id0(i,j)
* 	i:PVA(va)	q:va0(va,j)	va:

parameter	thetava(va,j)	Value-added shares;
$echo	thetava(va,j) = 0; thetava(va,j)$va0(va,j) = va0(va,j)/sum(va.local,va0(va,j));	>>%gams.scrdir%accounting_mcp.gen

alias (va,va_);
$macro	CVA(j)	(prod(va_, PVA(va_)**thetava(va_,j)))

prf_Y(y_(j))..	CVA(j)*sum(va,va0(va,j)) + sum(i, PA(i)*id0(i,j)) =e= sum(i, PY(i)*ys0(j,i))*(1-ty(j));

* $prod:A(i)$a_(i)  s:0  t:2 dm:2
* 	o:PA(i)		q:a0(i)			a:ra	t:ta(i)	p:(1-ta0(i))
* 	o:PFX		q:x0(i)
* 	i:PY(i)		q:y0(i)		dm:
* 	i:PFX		q:m0(i)		dm: 	a:ra	t:tm(i) 	p:(1+tm0(i))
* 	i:PM(m)		q:md0(m,i)

parameter	thetam(i)	Import value share,
		thetax(i)	Export value share;

$echo	thetam(i) = 0; thetam(i)$m0(i) = m0(i)*(1+tm0(i))/( m0(i)*(1+tm0(i)) + y0(i) );	>>%gams.scrdir%accounting_mcp.gen
$echo	thetax(i) = 0; thetax(i)$x0(i) = x0(i)/(x0(i)+a0(i)*(1-ta0(i)));		>>%gams.scrdir%accounting_mcp.gen

$macro PMD(i)	((thetam(i)*(PFX*(1+tm(i))/(1+tm0(i)))**(1-2) + (1-thetam(i))*PY(i)**(1-2))**(1/(1-2)))
$macro PXD(i)   ((thetax(i)*PFX**(1+2) + (1-thetax(i))*(PA(i)*(1-ta(i))/(1-ta0(i)))**(1+2))**(1/(1+2)))

$macro MD(i) (A(i)*m0(i)*( (PMD(i)*(1+tm0(i))) / (PFX*(1+tm(i))) )**2)
$macro YD(i) (A(i)*y0(i)*(PMD(i)/PY(i))**2)
$macro XS(i) (A(i)*x0(i)*(PFX/PXD(i))**2)
$macro DS(i) (A(i)*a0(i)*(PA(i)*(1-ta(i))/(PXD(i)*(1-ta0(i))))**2)

prf_A(a_(i))..	sum(m,PM(m)*md0(m,i)) + PMD(i)*(y0(i)+(1+tm0(i))*m0(i)) =g= PXD(i)*(x0(i)+a0(i)*(1-ta0(i)));

* $prod:MS(m)
* 	o:PM(m)		q:(sum(i,ms0(i,m)))
* 	i:PY(i)		q:ms0(i,m)

prf_MS(m)..	sum(i,PY(i)*ms0(i,m)) =e= PM(m)*sum(i,ms0(i,m));

* $demand:RA  s:1
* 	d:PA(i)		q:fd0(i,"pce")
* 	e:PY(i)		q:fs0(i)
* 	e:PFX		q:bopdef
*	e:PA(i)		q:(-sum(xfd,fd0(i,xfd)))
*	e:PVA(va)	q:(sum(j,va0(va,j)))

parameter	thetac(i)	Benchmark value shares;

$echo	thetac(i) =  fd0(i,"pce")/sum(i.local,fd0(i,"pce"));				>>%gams.scrdir%accounting_mcp.gen

bal_RA..	RA =e= sum(i,PY(i)*fs0(i)) + PFX*bopdef - sum((i,xfd), PA(i)*fd0(i,xfd)) + sum((va,j),PVA(va)*va0(va,j))
			+ sum(i,A(i)* (a0(i)*PA(i)*ta(i) + PFX*MD(i)*tm(i))) + sum(j, Y(j)*sum(i,ys0(j,i)*PY(i))*ty(j));

mkt_PA(a_(i))..	DS(i) =e= thetac(i) * RA/PA(i) + sum(xfd,fd0(i,xfd)) + sum(y_(j),Y(j)*id0(i,j));

mkt_PY(i)..	sum(y_(j),Y(j)*ys0(j,i)) =e= sum(m,MS(m)*ms0(i,m)) + YD(i);

mkt_PVA(va)..	sum(j,va0(va,j)) =e= sum(y_(j), Y(j)*va0(va,j)*CVA(j)/PVA(va));

mkt_PM(m)..	MS(m)*sum(i,ms0(i,m)) =e= sum(i$a0(i), A(i)*md0(m,i));

mkt_PFX..	sum(a_(i), XS(i)) + bopdef =e= sum(a_(i),MD(i));

model accounting_mcp /
	prf_Y.Y, prf_A.A, prf_MS.MS, 
	bal_RA.RA, 
	mkt_PA.PA, mkt_PY.PY, mkt_PVA.PVA, mkt_PM.PM, mkt_PFX.PFX /;

*	----------------------------------------------------------------------------------------
parameter REPORT The output;

loop(run(yr),
	y0(i) = y_0(yr,i);
	ys0(j,i) = ys_0(yr,j,i);
	ty0(j) = ty_0(yr,j);
	fs0(i) = fs_0(yr,i);
	id0(i,j) = id_0(yr,i,j);
	fd0(i,fd) = fd_0(yr,i,fd);
	va0(va,j) = va_0(yr,va,j);
	m0(i) = m_0(yr,i);
	x0(i) = x_0(yr,i);
	ms0(i,m) = ms_0(yr,i,m);
	md0(m,i) = md_0(yr,m,i);
	a0(i) = a_0(yr,i);
	ta0(i) = ta_0(yr,i);
	tm0(i) = tm_0(yr,i);
	ta(i) = ta0(i);
	ty(j) = ty0(j);
	tm(i) = tm0(i);
	bopdef = sum(i, m0(i)-x0(i));

	y_(j) = yes$sum(i,ys0(j,i));
	a_(i) = yes$a0(i);
	py_(i) = yes$sum(j,ys0(j,i));
	xfd(fd) = yes$(not sameas(fd,'pce'));
*	xfd(fd) = yes$(not sameas('pce', fd));


*	Benchmark replication:

*	1. MGE model

	Y.L(j) = 1;
	A.L(i) = 1;
	MS.L(m) = 1;
	PA.L(i) = 1;
	PY.L(i) = 1;
	PVA.L(va) = 1;
	PM.L(m) = 1;
	PFX.L = 1;
	RA.LO = 0; RA.UP = +INF;
	accounting.iterlim = 0;
	

$include %gams.scrdir%accounting.gen
	solve accounting using mcp;
	abort$round(accounting.objval,3) "Benchmark replication fails for the MGE model.";

*$onechov >%gams.scrdir%report.gms
*report("Y",i,"%replacement%") =Y.L(i);
*report("A",i,"%replacement%") =A.L(i);
*report("RA", "%replacement%") = RA.L;
*report("CWI", "%replacement%") = CWI.L;

*$offecho
*
*$set replacement BchMGE
*$include %gams.scrdir%report
*
REPORT("Y",i,"benchmarkmge") = Y.L(i);
REPORT("A",i,"benchmarkmge") = A.L(i);
REPORT("DPARA",i,"benchmarkmge") = DPARA.L(i);
REPORT("SPAA",i,"benchmarkmge") = SPAA.L(i)/A.L(i);
REPORT("DPYA",i,"benchmarkmge") = DPYA.L(i)/A.L(i);
*REPORT("DPYMS","m,i","benchmarkmge") = DPYMS.L(m,i);
*REPORT("DPYMS",i,"benchmarkmge") = DPYMS.L(i);
REPORT("SPMMS",m,"benchmarkmge") = SPMMS.L(m)/MS.L(m);
*REPORT("DPMA",i,m,"benchmarkmge") = DPMA.L(i,m);
*REPORT("SYPY",j,i, "benchmarkmge") = SYPY.L(j,i);
REPORT("Y",i,"benchmarkmge") = Y.L(i);
REPORT("A",i,"benchmarkmge") = A.L(i);
REPORT("MS",m,"benchmarkmge") = MS.L(m);
REPORT("PA",i,"benchmarkmge") = PA.L(i);
REPORT("PY",i,"benchmarkmge") = PY.L(i);
REPORT("PVA",va,"benchmarkmge") = PVA.L(va);
REPORT("PM",m,"benchmarkmge") = PM.L(M);
REPORT("PFX","","benchmarkmge") = PFX.L;
REPORT("RA","","benchmarkmge") = RA.L;

*	2. MCP model

	accounting_mcp.iterlim = 0;
$include %gams.scrdir%accounting_mcp.gen

	RA.FX = sum(i,fd0(i,"pce"));

	solve accounting_mcp using mcp;
	abort$round(accounting_mcp.objval,3) "Benchmark replication fails for the MCP model.";

$set replacement BchMCP
*$include %gams.scrdir%report

*REPORT("Y",i,"benchmark-mcp") = Y.L(i);
*REPORT("A",i,"benchmark-mcp") = A.L(i);

*	3. Counterfactual with the MCP model:

	tm(i) = 0;
	ta(i) = 0;

	RA.LO = 0; RA.UP = +INF;
	accounting.iterlim = 10000;
$include %gams.scrdir%accounting.gen
	solve accounting using mcp;
	abort$round(accounting.objval,3) "Counterfactural simulation fails for the MGE model.";

$set replacement CntrMGE
*$include %gams.scrdir%report

REPORT("Y",i,"Countermge") = Y.L(i);
REPORT("A",i,"Countermge") = A.L(i);
REPORT("DPARA",i,"Countermge") = DPARA.L(i);
REPORT("SPAA",i,"Countermge") = SPAA.L(i)/A.L(i);
REPORT("DPYA",i,"Countermge") = DPYA.L(i)/A.L(i);
*REPORT("DPYMS","m,i","Countermge") = DPYMS.L(m,i);
*REPORT("DPYMS",i,"Countermge") = DPYMS.L(i);
REPORT("SPMMS",m,"Countermge") = SPMMS.L(m)/MS.L(m);
*REPORT("DPMA",i,m,"Countermge") = DPMA.L(i,m);
*REPORT("SYPY",j,i, "Countermge") = SYPY.L(j,i);
REPORT("Y",i,"Countermge") = Y.L(i);
REPORT("A",i,"Countermge") = A.L(i);
REPORT("MS",m,"Countermge") = MS.L(m);
REPORT("PA",i,"Countermge") = PA.L(i);
REPORT("PY",i,"Countermge") = PY.L(i);
REPORT("PVA",va,"Countermge") = PVA.L(va);
REPORT("PM",m,"Countermge") = PM.L(M);
REPORT("PFX","","Countermge") = PFX.L;
REPORT("RA","","Countermge") = RA.L;

*	4. Verify that the MGE solution also solves the MCP model.

$include %gams.scrdir%accounting_mcp.gen

	solve accounting_mcp using mcp;
*	abort$round(accounting_mcp.objval,2) "Counterfactural solution fails for the MCP model.";
);

$set replacement CntrMCP
*$include %gams.scrdir%report
*REPORT("Y",i,"CounterMCP") = Y.L(i);
*REPORT("A",i,"CounterMCP") = A.L(i);

option decimals=8;
display REPORT;

execute_unload "WNDCnat.gdx" REPORT
*=== Write to variable levels to Excel file from GDX 
*=== If we do not specify a sheet, data is placed in first sheet
*execute 'gdxxrw.exe WNDCnat.gdx o=MPSGEresults.xlsx par=report rng=The123!'
execute 'gdxxrw.exe WNDCnat.gdx o=C:\Users\Eli\.julia\dev\MPSGE\test\MPSGEresults.xlsx par=REPORT rng=WNDCnat!'
