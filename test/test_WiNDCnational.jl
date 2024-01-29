@testitem "WiNDC national model" begin
# Replication of the WiNDC national MGE model
using XLSX, MPSGE.JuMP.Containers
using JLD2
import JuMP


## Load all the data: Data was uploaded and structured into Dicts of DenseAxisArrays with a Julia notebook "national_data.ipynb"
# New data from Mitch Oct 11
P= load(joinpath(@__DIR__,"./gams/DAAData.jld2"))["data"] # load in date from saved Notebook output Dict, named P
S= load(joinpath(@__DIR__,"./gams/Indices.jld2"))["data"] # load in date from saved Notebook output Dict, named S
# Alternate, Julia WiNDC generated data
# PJ= load(joinpath(@__DIR__,"./gams/JDAAData.jld2"))["data"] # load in date from saved Notebook output Dict, named P
# SJ= load(joinpath(@__DIR__,"./gams/JIndices.jld2"))["data"] # load in date from saved Notebook output Dict, named S

y_ = filter!(x -> x != :oth && x!= :use, S[:i][:]) # These 2 sectors 'use' & 'oth' are in the indices list, but have no data (and therefore cause problems)
a_ = filter!(x -> x != :fbt && x != :mvt && x != :gmt, copy(y_))

# Indexes (set from the data files, via the notebook)
sectorsi = S[:i]#[:] # "BEA Goods and sectors categories", is "i" in GAMS
sectorsj = copy(sectorsi) # "BEA Goods and sectors categories", is "j" in GAMS, for iterating over double index
xfd = filter!(x -> x != :pce, S[:fd]) # "BEA Final demand categories",
ts = S[:ts] # "BEA Taxes and subsidies categories",
valueadded = filter!(s -> s != :othtax, S[:va]) # "BEA Value added categories excluding othtax", va in GAMS
margin  = S[:m] # "Margins (trade or transport)"; m in GAMS

yr = Symbol(2017)
# PARAMETERS

# Data For a single year, knock out one dimension
y_0 = P[:y_0][yr,:][y_] #	"Gross output",
ys_0 = P[:ys_0][yr,y_,y_] #	"Sectoral supply",
ty_0 = P[:ty_0][yr,:][y_] #	"Output tax rate"
fs_0 = P[:fs_0][yr,:][y_] #	"Household supply", # All zeros
id_0 = P[:id_0][yr,y_,y_] #	"Intermediate demand",
fd_0 = P[:fd_0][yr,y_,:] #	"Final demand",
va_0 = P[:va_0][yr,:,y_] #	"Value added",
m_0 = P[:m_0][yr,:][y_] #	"Imports",
x_0 = P[:x_0][yr,:][y_] #	"Exports of goods and services",
ms_0 = P[:ms_0][yr,y_,:] #	"Margin supply",
md_0 = P[:md_0][yr,:,y_] #	"Margin demand",
a_0 = P[:a_0][yr,:][a_]  #	"Armington supply",
bopdef_0 = P[:bopdef_0][yr] #	"Balance of payments deficit",
ta_0 = P[:ta_0][yr,:][y_] #	"Tax net subsidy rate on intermediate demand", Initial, for price
tm_0 = P[:tm_0][yr,:][y_] #	"Import tariff"; Initial, for price 

WiNnat = MPSGE.Model()

	# parameters
	ta = add!(WiNnat, MPSGE.Parameter(:ta, indices = (sectorsi,), value=P[:ta_0][yr,sectorsi].data)) #	"Tax net subsidy rate on intermediate demand",
	tm = add!(WiNnat, MPSGE.Parameter(:tm, indices = (sectorsi,), value=P[:tm_0][yr,sectorsi].data)) #	"Import tariff";

	# Elasticity parameters
	t_elas_y =  add!(WiNnat, MPSGE.Parameter(:t_elas_y,  value=0.))
	elas_y =    add!(WiNnat, MPSGE.Parameter(:elas_y,    value=0.))
	elas_va =   add!(WiNnat, MPSGE.Parameter(:elas_va,   value=1.))
	t_elas_m =  add!(WiNnat, MPSGE.Parameter(:t_elas_m,  value=0.))
	elas_m =    add!(WiNnat, MPSGE.Parameter(:elas_m,    value=0.))
	t_elas_a =  add!(WiNnat, MPSGE.Parameter(:t_elas_a,  value=2.))
	elas_a =    add!(WiNnat, MPSGE.Parameter(:elas_a,    value=0.))
	elas_dm =   add!(WiNnat, MPSGE.Parameter(:elas_dm,   value=2.))
	d_elas_ra = add!(WiNnat, MPSGE.Parameter(:d_elas_ra, value=1.))

	# sectors:
	Y = add!(WiNnat, Sector(:Y, indices=(sectorsj,)))
	A = add!(WiNnat, Sector(:A, indices=(sectorsi,)))

	MS = add!(WiNnat, Sector(:MS, indices=(margin,)))

	# commodities:
	PA  = add!(WiNnat, Commodity(:PA, indices=(sectorsi, ))) #	Armington price
	PY  = add!(WiNnat, Commodity(:PY, indices=(sectorsi,))) #	Supply
	PVA = add!(WiNnat, Commodity(:PVA, indices=(valueadded,))) #		Value-added
	PM  = add!(WiNnat, Commodity(:PM, indices=(margin,))) #		Margin
	PFX = add!(WiNnat, Commodity(:PFX))	#	Foreign exchnage

	# consumers:
	RA = add!(WiNnat, Consumer(:RA, benchmark = sum(fd_0[:,:pce]) ))

	# production functions
	for j in y_
		@production(WiNnat, Y[j], 0., 0.,
		[	
			Output(PY[i], ys_0[j,i], taxes=[Tax(ty_0[j], RA)]) for i in sectorsi if ys_0[j,i]>0
		], 
		[
			[Input(PA[i], id_0[i,j]) for i in a_ if id_0[i,j]>0];  # filtered to A
			[Input(Nest(
					Symbol("VA$j"),
					1.,
					sum(va_0[:,j]),
							[Input(PVA[va], va_0[va,j]) for va in valueadded if va_0[va,j]>0.] 
						),
						sum(va_0[:,j] )
				  )
			]
		]
	)
	end

	for m in margin
		add!(WiNnat, Production(MS[m], 0., 0., 
			[Output(PM[m], sum(ms_0[:,m]) ) ],
			[Input(PY[i], ms_0[i,m]) for i in sectorsi if ms_0[i,m]>0])) 
	end

	for i in a_  
		@production(WiNnat, A[i], 2., 0.,
			[
				[
				Output(PA[i], a_0[i], taxes=[Tax(:($(ta[i])*1), RA)], price=(1-ta_0[i]) )
				];
				[
					Output(PFX, x_0[i])
				]
			]
			,
				[
					[	
						Input(Nest(Symbol("dm$i"),
						2.,
						(y_0[i]+m_0[i]+m_0[i]*get_value(tm[tm[i].subindex])),
						if m_0[i]>0 && y_0[i]>0
							[
								Input(PY[i], y_0[i] ),
								Input(PFX, m_0[i], taxes=[Tax(:($(tm[i])*1), RA)],  price=(1+tm_0[i]*1)  )
							]
						elseif y_0[i]>0
							[
								Input(PY[i], y_0[i] )
							]
						end
								),
						(y_0[i]+m_0[i]+m_0[i]*get_value(tm[tm[i].subindex])))
					];
					[Input(PM[m], md_0[m,i]) for m in margin if md_0[m,i]>0]
				]
				)
	end

	add!(WiNnat, DemandFunction(RA, 1.,
		[Demand(PA[i], fd_0[i,:pce]) for i in a_],
		[
			[Endowment(PY[i], fs_0[i]) for i in a_];
			[Endowment(PA[i], -sum(fd_0[i,xfd])) for i in a_];  
			[Endowment(PVA[va], sum(va_0[va,sectorsi])) for va in valueadded];
			Endowment(PFX, bopdef_0)
		]
		))

set_value((A[(:gmt)]), 1.0)
set_value((A[(:mvt)]), 1.0)
set_value((A[(:fbt)]), 1.0)
set_fixed!(A[(:gmt)], true)
set_fixed!(A[(:mvt)], true)
set_fixed!(A[(:fbt)], true)
set_value((PA[(:gmt)]), 1.0)
set_value((PA[(:mvt)]), 1.0)
set_value((PA[(:fbt)]), 1.0)
set_fixed!(PA[(:gmt)], true)
set_fixed!(PA[(:mvt)], true)
set_fixed!(PA[(:fbt)], true)

set_value(RA, 13138.7573)
set_fixed!(RA, true)

solve!(WiNnat, cumulative_iteration_limit=0);

gams_results = XLSX.readxlsx(joinpath(@__DIR__, "MPSGEresults.xlsx"))
a_table = gams_results["WNDCnat"][:]  # Generated from JPMGE_MPSGE
WNDCnat = DenseAxisArray(a_table[2:end,2:end],string.(a_table[2:end,1],".",a_table[2:end,2]),a_table[1,2:end])


@test JuMP.value(WiNnat._jump_model[Symbol("Y")][:ppd]) ≈ WNDCnat["Y.ppd","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("Y")][:res]) ≈ WNDCnat["Y.res","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("Y")][:com]) ≈ WNDCnat["Y.com","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("Y")][:amb]) ≈ WNDCnat["Y.amb","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("Y")][:fbp]) ≈ WNDCnat["Y.fbp","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("Y")][:rec]) ≈ WNDCnat["Y.rec","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("Y")][:con]) ≈ WNDCnat["Y.con","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("Y")][:agr]) ≈ WNDCnat["Y.agr","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("Y")][:eec]) ≈ WNDCnat["Y.eec","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("Y")][:fnd]) ≈ WNDCnat["Y.fnd","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("Y")][:pub]) ≈ WNDCnat["Y.pub","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("Y")][:hou]) ≈ WNDCnat["Y.hou","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("Y")][:fbt]) ≈ WNDCnat["Y.fbt","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("Y")][:ins]) ≈ WNDCnat["Y.ins","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("Y")][:tex]) ≈ WNDCnat["Y.tex","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("Y")][:leg]) ≈ WNDCnat["Y.leg","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("Y")][:fen]) ≈ WNDCnat["Y.fen","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("Y")][:uti]) ≈ WNDCnat["Y.uti","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("Y")][:nmp]) ≈ WNDCnat["Y.nmp","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("Y")][:brd]) ≈ WNDCnat["Y.brd","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("Y")][:bnk]) ≈ WNDCnat["Y.bnk","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("Y")][:ore]) ≈ WNDCnat["Y.ore","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("Y")][:edu]) ≈ WNDCnat["Y.edu","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("Y")][:ote]) ≈ WNDCnat["Y.ote","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("Y")][:man]) ≈ WNDCnat["Y.man","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("Y")][:mch]) ≈ WNDCnat["Y.mch","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("Y")][:dat]) ≈ WNDCnat["Y.dat","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("Y")][:amd]) ≈ WNDCnat["Y.amd","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("Y")][:oil]) ≈ WNDCnat["Y.oil","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("Y")][:hos]) ≈ WNDCnat["Y.hos","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("Y")][:rnt]) ≈ WNDCnat["Y.rnt","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("Y")][:pla]) ≈ WNDCnat["Y.pla","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("Y")][:fof]) ≈ WNDCnat["Y.fof","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("Y")][:fin]) ≈ WNDCnat["Y.fin","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("Y")][:tsv]) ≈ WNDCnat["Y.tsv","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("Y")][:nrs]) ≈ WNDCnat["Y.nrs","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("Y")][:sec]) ≈ WNDCnat["Y.sec","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("Y")][:art]) ≈ WNDCnat["Y.art","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("Y")][:mov]) ≈ WNDCnat["Y.mov","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("Y")][:fpd]) ≈ WNDCnat["Y.fpd","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("Y")][:slg]) ≈ WNDCnat["Y.slg","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("Y")][:pri]) ≈ WNDCnat["Y.pri","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("Y")][:grd]) ≈ WNDCnat["Y.grd","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("Y")][:pip]) ≈ WNDCnat["Y.pip","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("Y")][:sle]) ≈ WNDCnat["Y.sle","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("Y")][:osv]) ≈ WNDCnat["Y.osv","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("Y")][:trn]) ≈ WNDCnat["Y.trn","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("Y")][:smn]) ≈ WNDCnat["Y.smn","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("Y")][:fmt]) ≈ WNDCnat["Y.fmt","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("Y")][:pet]) ≈ WNDCnat["Y.pet","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("Y")][:mvt]) ≈ WNDCnat["Y.mvt","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("Y")][:cep]) ≈ WNDCnat["Y.cep","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("Y")][:wst]) ≈ WNDCnat["Y.wst","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("Y")][:mot]) ≈ WNDCnat["Y.mot","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("Y")][:adm]) ≈ WNDCnat["Y.adm","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("Y")][:soc]) ≈ WNDCnat["Y.soc","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("Y")][:alt]) ≈ WNDCnat["Y.alt","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("Y")][:pmt]) ≈ WNDCnat["Y.pmt","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("Y")][:trk]) ≈ WNDCnat["Y.trk","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("Y")][:fdd]) ≈ WNDCnat["Y.fdd","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("Y")][:gmt]) ≈ WNDCnat["Y.gmt","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("Y")][:wtt]) ≈ WNDCnat["Y.wtt","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("Y")][:wpd]) ≈ WNDCnat["Y.wpd","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("Y")][:wht]) ≈ WNDCnat["Y.wht","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("Y")][:wrh]) ≈ WNDCnat["Y.wrh","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("Y")][:ott]) ≈ WNDCnat["Y.ott","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("Y")][:che]) ≈ WNDCnat["Y.che","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("Y")][:air]) ≈ WNDCnat["Y.air","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("Y")][:mmf]) ≈ WNDCnat["Y.mmf","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("Y")][:otr]) ≈ WNDCnat["Y.otr","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("Y")][:min]) ≈ WNDCnat["Y.min","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("A")][:ppd]) ≈ WNDCnat["A.ppd","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("A")][:res]) ≈ WNDCnat["A.res","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("A")][:com]) ≈ WNDCnat["A.com","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("A")][:amb]) ≈ WNDCnat["A.amb","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("A")][:fbp]) ≈ WNDCnat["A.fbp","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("A")][:rec]) ≈ WNDCnat["A.rec","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("A")][:con]) ≈ WNDCnat["A.con","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("A")][:agr]) ≈ WNDCnat["A.agr","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("A")][:eec]) ≈ WNDCnat["A.eec","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("A")][:fnd]) ≈ WNDCnat["A.fnd","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("A")][:pub]) ≈ WNDCnat["A.pub","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("A")][:hou]) ≈ WNDCnat["A.hou","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("A")][:fbt]) ≈ WNDCnat["A.fbt","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("A")][:ins]) ≈ WNDCnat["A.ins","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("A")][:tex]) ≈ WNDCnat["A.tex","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("A")][:leg]) ≈ WNDCnat["A.leg","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("A")][:fen]) ≈ WNDCnat["A.fen","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("A")][:uti]) ≈ WNDCnat["A.uti","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("A")][:nmp]) ≈ WNDCnat["A.nmp","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("A")][:brd]) ≈ WNDCnat["A.brd","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("A")][:bnk]) ≈ WNDCnat["A.bnk","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("A")][:ore]) ≈ WNDCnat["A.ore","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("A")][:edu]) ≈ WNDCnat["A.edu","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("A")][:ote]) ≈ WNDCnat["A.ote","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("A")][:man]) ≈ WNDCnat["A.man","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("A")][:mch]) ≈ WNDCnat["A.mch","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("A")][:dat]) ≈ WNDCnat["A.dat","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("A")][:amd]) ≈ WNDCnat["A.amd","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("A")][:oil]) ≈ WNDCnat["A.oil","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("A")][:hos]) ≈ WNDCnat["A.hos","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("A")][:rnt]) ≈ WNDCnat["A.rnt","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("A")][:pla]) ≈ WNDCnat["A.pla","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("A")][:fof]) ≈ WNDCnat["A.fof","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("A")][:fin]) ≈ WNDCnat["A.fin","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("A")][:tsv]) ≈ WNDCnat["A.tsv","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("A")][:nrs]) ≈ WNDCnat["A.nrs","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("A")][:sec]) ≈ WNDCnat["A.sec","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("A")][:art]) ≈ WNDCnat["A.art","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("A")][:mov]) ≈ WNDCnat["A.mov","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("A")][:fpd]) ≈ WNDCnat["A.fpd","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("A")][:slg]) ≈ WNDCnat["A.slg","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("A")][:pri]) ≈ WNDCnat["A.pri","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("A")][:grd]) ≈ WNDCnat["A.grd","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("A")][:pip]) ≈ WNDCnat["A.pip","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("A")][:sle]) ≈ WNDCnat["A.sle","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("A")][:osv]) ≈ WNDCnat["A.osv","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("A")][:trn]) ≈ WNDCnat["A.trn","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("A")][:smn]) ≈ WNDCnat["A.smn","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("A")][:fmt]) ≈ WNDCnat["A.fmt","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("A")][:pet]) ≈ WNDCnat["A.pet","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("A")][:mvt]) ≈ WNDCnat["A.mvt","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("A")][:cep]) ≈ WNDCnat["A.cep","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("A")][:wst]) ≈ WNDCnat["A.wst","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("A")][:mot]) ≈ WNDCnat["A.mot","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("A")][:adm]) ≈ WNDCnat["A.adm","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("A")][:soc]) ≈ WNDCnat["A.soc","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("A")][:alt]) ≈ WNDCnat["A.alt","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("A")][:pmt]) ≈ WNDCnat["A.pmt","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("A")][:trk]) ≈ WNDCnat["A.trk","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("A")][:fdd]) ≈ WNDCnat["A.fdd","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("A")][:gmt]) ≈ WNDCnat["A.gmt","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("A")][:wtt]) ≈ WNDCnat["A.wtt","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("A")][:wpd]) ≈ WNDCnat["A.wpd","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("A")][:wht]) ≈ WNDCnat["A.wht","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("A")][:wrh]) ≈ WNDCnat["A.wrh","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("A")][:ott]) ≈ WNDCnat["A.ott","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("A")][:che]) ≈ WNDCnat["A.che","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("A")][:air]) ≈ WNDCnat["A.air","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("A")][:mmf]) ≈ WNDCnat["A.mmf","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("A")][:otr]) ≈ WNDCnat["A.otr","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("A")][:min]) ≈ WNDCnat["A.min","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("PA[ppd]ρRA")]) ≈ WNDCnat["DPARA.ppd","benchmarkmge"]#  44.9917512786608
@test JuMP.value(WiNnat._jump_model[Symbol("PA[res]ρRA")]) ≈ WNDCnat["DPARA.res","benchmarkmge"]#  739.640977649195
@test JuMP.value(WiNnat._jump_model[Symbol("PA[amb]ρRA")]) ≈ WNDCnat["DPARA.amb","benchmarkmge"]#  1051.49526950129
@test JuMP.value(WiNnat._jump_model[Symbol("PA[fbp]ρRA")]) ≈ WNDCnat["DPARA.fbp","benchmarkmge"]#  1032.63715951023
@test JuMP.value(WiNnat._jump_model[Symbol("PA[rec]ρRA")]) ≈ WNDCnat["DPARA.rec","benchmarkmge"]#  198.973632905629
@test JuMP.value(WiNnat._jump_model[Symbol("PA[agr]ρRA")]) ≈ WNDCnat["DPARA.agr","benchmarkmge"]#  147.860765929871
@test JuMP.value(WiNnat._jump_model[Symbol("PA[eec]ρRA")]) ≈ WNDCnat["DPARA.eec","benchmarkmge"]#  86.2937794590717
@test JuMP.value(WiNnat._jump_model[Symbol("PA[pub]ρRA")]) ≈ WNDCnat["DPARA.pub","benchmarkmge"]#  130.558271938077
@test JuMP.value(WiNnat._jump_model[Symbol("PA[hou]ρRA")]) ≈ WNDCnat["DPARA.hou","benchmarkmge"]#  2035.11235903476
@test JuMP.value(WiNnat._jump_model[Symbol("PA[ins]ρRA")]) ≈ WNDCnat["DPARA.ins","benchmarkmge"]#  386.984798816457
@test JuMP.value(WiNnat._jump_model[Symbol("PA[tex]ρRA")]) ≈ WNDCnat["DPARA.tex","benchmarkmge"]#  72.742311765499
@test JuMP.value(WiNnat._jump_model[Symbol("PA[leg]ρRA")]) ≈ WNDCnat["DPARA.leg","benchmarkmge"]#  104.839454950276
@test JuMP.value(WiNnat._jump_model[Symbol("PA[fen]ρRA")]) ≈ WNDCnat["DPARA.fen","benchmarkmge"]#  6.15724913707967
@test JuMP.value(WiNnat._jump_model[Symbol("PA[uti]ρRA")]) ≈ WNDCnat["DPARA.uti","benchmarkmge"]#  264.75348987443
@test JuMP.value(WiNnat._jump_model[Symbol("PA[nmp]ρRA")]) ≈ WNDCnat["DPARA.nmp","benchmarkmge"]#  20.8800042900968
@test JuMP.value(WiNnat._jump_model[Symbol("PA[brd]ρRA")]) ≈ WNDCnat["DPARA.brd","benchmarkmge"]#  330.910993843052
@test JuMP.value(WiNnat._jump_model[Symbol("PA[bnk]ρRA")]) ≈ WNDCnat["DPARA.bnk","benchmarkmge"]#  279.347316867508
@test JuMP.value(WiNnat._jump_model[Symbol("PA[ore]ρRA")]) ≈ WNDCnat["DPARA.ore","benchmarkmge"]#  5.63069962732941
@test JuMP.value(WiNnat._jump_model[Symbol("PA[edu]ρRA")]) ≈ WNDCnat["DPARA.edu","benchmarkmge"]#  351.693474833195
@test JuMP.value(WiNnat._jump_model[Symbol("PA[ote]ρRA")]) ≈ WNDCnat["DPARA.ote","benchmarkmge"]#  32.6161713845304
@test JuMP.value(WiNnat._jump_model[Symbol("PA[mch]ρRA")]) ≈ WNDCnat["DPARA.mch","benchmarkmge"]#  24.0979004885706
@test JuMP.value(WiNnat._jump_model[Symbol("PA[dat]ρRA")]) ≈ WNDCnat["DPARA.dat","benchmarkmge"]#  55.6169482736214
@test JuMP.value(WiNnat._jump_model[Symbol("PA[amd]ρRA")]) ≈ WNDCnat["DPARA.amd","benchmarkmge"]#  157.445263925325
@test JuMP.value(WiNnat._jump_model[Symbol("PA[hos]ρRA")]) ≈ WNDCnat["DPARA.hos","benchmarkmge"]#  1066.45110949419
@test JuMP.value(WiNnat._jump_model[Symbol("PA[rnt]ρRA")]) ≈ WNDCnat["DPARA.rnt","benchmarkmge"]#  105.365483950026
@test JuMP.value(WiNnat._jump_model[Symbol("PA[pla]ρRA")]) ≈ WNDCnat["DPARA.pla","benchmarkmge"]#  67.3705556680468
@test JuMP.value(WiNnat._jump_model[Symbol("PA[fof]ρRA")]) ≈ WNDCnat["DPARA.fof","benchmarkmge"]#  11.7882882944089
@test JuMP.value(WiNnat._jump_model[Symbol("PA[fin]ρRA")]) ≈ WNDCnat["DPARA.fin","benchmarkmge"]#  162.337880923005
@test JuMP.value(WiNnat._jump_model[Symbol("PA[tsv]ρRA")]) ≈ WNDCnat["DPARA.tsv","benchmarkmge"]#  72.8032149654701
@test JuMP.value(WiNnat._jump_model[Symbol("PA[nrs]ρRA")]) ≈ WNDCnat["DPARA.nrs","benchmarkmge"]#  242.29760788508
@test JuMP.value(WiNnat._jump_model[Symbol("PA[sec]ρRA")]) ≈ WNDCnat["DPARA.sec","benchmarkmge"]#  224.455670893543
@test JuMP.value(WiNnat._jump_model[Symbol("PA[art]ρRA")]) ≈ WNDCnat["DPARA.art","benchmarkmge"]#  78.2323166628951
@test JuMP.value(WiNnat._jump_model[Symbol("PA[mov]ρRA")]) ≈ WNDCnat["DPARA.mov","benchmarkmge"]#  32.5341701845693
@test JuMP.value(WiNnat._jump_model[Symbol("PA[fpd]ρRA")]) ≈ WNDCnat["DPARA.fpd","benchmarkmge"]#  119.650958943251
@test JuMP.value(WiNnat._jump_model[Symbol("PA[pri]ρRA")]) ≈ WNDCnat["DPARA.pri","benchmarkmge"]#  8.42087210600606
@test JuMP.value(WiNnat._jump_model[Symbol("PA[grd]ρRA")]) ≈ WNDCnat["DPARA.grd","benchmarkmge"]#  45.8913275782342
@test JuMP.value(WiNnat._jump_model[Symbol("PA[sle]ρRA")]) ≈ WNDCnat["DPARA.sle","benchmarkmge"]#  70.8505336663962
@test JuMP.value(WiNnat._jump_model[Symbol("PA[osv]ρRA")]) ≈ WNDCnat["DPARA.osv","benchmarkmge"]#  615.300415708169
@test JuMP.value(WiNnat._jump_model[Symbol("PA[trn]ρRA")]) ≈ WNDCnat["DPARA.trn","benchmarkmge"]#  1.50801962928476
@test JuMP.value(WiNnat._jump_model[Symbol("PA[fmt]ρRA")]) ≈ WNDCnat["DPARA.fmt","benchmarkmge"]#  40.6884084807019
@test JuMP.value(WiNnat._jump_model[Symbol("PA[pet]ρRA")]) ≈ WNDCnat["DPARA.pet","benchmarkmge"]#  310.684543852645
@test JuMP.value(WiNnat._jump_model[Symbol("PA[cep]ρRA")]) ≈ WNDCnat["DPARA.cep","benchmarkmge"]#  164.51940292197
@test JuMP.value(WiNnat._jump_model[Symbol("PA[wst]ρRA")]) ≈ WNDCnat["DPARA.wst","benchmarkmge"]#  27.02992138718
@test JuMP.value(WiNnat._jump_model[Symbol("PA[mot]ρRA")]) ≈ WNDCnat["DPARA.mot","benchmarkmge"]#  338.060986839661
@test JuMP.value(WiNnat._jump_model[Symbol("PA[adm]ρRA")]) ≈ WNDCnat["DPARA.adm","benchmarkmge"]#  63.9123816696869
@test JuMP.value(WiNnat._jump_model[Symbol("PA[soc]ρRA")]) ≈ WNDCnat["DPARA.soc","benchmarkmge"]#  210.496481900163
@test JuMP.value(WiNnat._jump_model[Symbol("PA[alt]ρRA")]) ≈ WNDCnat["DPARA.alt","benchmarkmge"]#  399.697885810427
@test JuMP.value(WiNnat._jump_model[Symbol("PA[pmt]ρRA")]) ≈ WNDCnat["DPARA.pmt","benchmarkmge"]#  1.73992778917477
@test JuMP.value(WiNnat._jump_model[Symbol("PA[trk]ρRA")]) ≈ WNDCnat["DPARA.trk","benchmarkmge"]#  12.2893814941713
@test JuMP.value(WiNnat._jump_model[Symbol("PA[wtt]ρRA")]) ≈ WNDCnat["DPARA.wtt","benchmarkmge"]#  21.4072842898467
@test JuMP.value(WiNnat._jump_model[Symbol("PA[wpd]ρRA")]) ≈ WNDCnat["DPARA.wpd","benchmarkmge"]#  7.89415413625588
@test JuMP.value(WiNnat._jump_model[Symbol("PA[wrh]ρRA")]) ≈ WNDCnat["DPARA.wrh","benchmarkmge"]#  0.0873265562585818
@test JuMP.value(WiNnat._jump_model[Symbol("PA[ott]ρRA")]) ≈ WNDCnat["DPARA.ott","benchmarkmge"]#  5.46827548740645
@test JuMP.value(WiNnat._jump_model[Symbol("PA[che]ρRA")]) ≈ WNDCnat["DPARA.che","benchmarkmge"]#  630.352943701029
@test JuMP.value(WiNnat._jump_model[Symbol("PA[air]ρRA")]) ≈ WNDCnat["DPARA.air","benchmarkmge"]#  129.274758938686
@test JuMP.value(WiNnat._jump_model[Symbol("PA[mmf]ρRA")]) ≈ WNDCnat["DPARA.mmf","benchmarkmge"]#  264.623776874491
@test JuMP.value(WiNnat._jump_model[Symbol("PA[otr]ρRA")]) ≈ WNDCnat["DPARA.otr","benchmarkmge"]#  23.3470480889267
@test JuMP.value(WiNnat._jump_model[Symbol("PA[min]ρRA")]) ≈ WNDCnat["DPARA.min","benchmarkmge"]#  0.643946397694582
@test JuMP.value(WiNnat._jump_model[Symbol("PA[ppd]‡A[ppd]")]) ≈ WNDCnat["SPAA.ppd","benchmarkmge"]#  237.61937898161
@test JuMP.value(WiNnat._jump_model[Symbol("PA[res]‡A[res]")]) ≈ WNDCnat["SPAA.res","benchmarkmge"]#  959.336695999382
@test JuMP.value(WiNnat._jump_model[Symbol("PA[com]‡A[com]")]) ≈ WNDCnat["SPAA.com","benchmarkmge"]#  524.890024973663
@test JuMP.value(WiNnat._jump_model[Symbol("PA[amb]‡A[amb]")]) ≈ WNDCnat["SPAA.amb","benchmarkmge"]#  1093.37976000005
@test JuMP.value(WiNnat._jump_model[Symbol("PA[fbp]‡A[fbp]")]) ≈ WNDCnat["SPAA.fbp","benchmarkmge"]#  1517.70571993414
@test JuMP.value(WiNnat._jump_model[Symbol("PA[rec]‡A[rec]")]) ≈ WNDCnat["SPAA.rec","benchmarkmge"]#  204.693237
@test JuMP.value(WiNnat._jump_model[Symbol("PA[con]‡A[con]")]) ≈ WNDCnat["SPAA.con","benchmarkmge"]#  1661.39430000001
@test JuMP.value(WiNnat._jump_model[Symbol("PA[agr]‡A[agr]")]) ≈ WNDCnat["SPAA.agr","benchmarkmge"]#  517.589199751203
@test JuMP.value(WiNnat._jump_model[Symbol("PA[eec]‡A[eec]")]) ≈ WNDCnat["SPAA.eec","benchmarkmge"]#  298.912943
@test JuMP.value(WiNnat._jump_model[Symbol("PA[fnd]‡A[fnd]")]) ≈ WNDCnat["SPAA.fnd","benchmarkmge"]#  380.898129
@test JuMP.value(WiNnat._jump_model[Symbol("PA[pub]‡A[pub]")]) ≈ WNDCnat["SPAA.pub","benchmarkmge"]#  348.3906469578
@test JuMP.value(WiNnat._jump_model[Symbol("PA[hou]‡A[hou]")]) ≈ WNDCnat["SPAA.hou","benchmarkmge"]#  2035.11236
@test JuMP.value(WiNnat._jump_model[Symbol("PA[ins]‡A[ins]")]) ≈ WNDCnat["SPAA.ins","benchmarkmge"]#  1174.63183999205
@test JuMP.value(WiNnat._jump_model[Symbol("PA[tex]‡A[tex]")]) ≈ WNDCnat["SPAA.tex","benchmarkmge"]#  145.78984
@test JuMP.value(WiNnat._jump_model[Symbol("PA[leg]‡A[leg]")]) ≈ WNDCnat["SPAA.leg","benchmarkmge"]#  348.314109011953
@test JuMP.value(WiNnat._jump_model[Symbol("PA[fen]‡A[fen]")]) ≈ WNDCnat["SPAA.fen","benchmarkmge"]#  70.4793684
@test JuMP.value(WiNnat._jump_model[Symbol("PA[uti]‡A[uti]")]) ≈ WNDCnat["SPAA.uti","benchmarkmge"]#  652.129446
@test JuMP.value(WiNnat._jump_model[Symbol("PA[nmp]‡A[nmp]")]) ≈ WNDCnat["SPAA.nmp","benchmarkmge"]#  214.381814997754
@test JuMP.value(WiNnat._jump_model[Symbol("PA[brd]‡A[brd]")]) ≈ WNDCnat["SPAA.brd","benchmarkmge"]#  707.121256008476
@test JuMP.value(WiNnat._jump_model[Symbol("PA[bnk]‡A[bnk]")]) ≈ WNDCnat["SPAA.bnk","benchmarkmge"]#  792.046892594355
@test JuMP.value(WiNnat._jump_model[Symbol("PA[ore]‡A[ore]")]) ≈ WNDCnat["SPAA.ore","benchmarkmge"]#  1255.26627000537
@test JuMP.value(WiNnat._jump_model[Symbol("PA[edu]‡A[edu]")]) ≈ WNDCnat["SPAA.edu","benchmarkmge"]#  392.687609997531
@test JuMP.value(WiNnat._jump_model[Symbol("PA[ote]‡A[ote]")]) ≈ WNDCnat["SPAA.ote","benchmarkmge"]#  277.836923944712
@test JuMP.value(WiNnat._jump_model[Symbol("PA[man]‡A[man]")]) ≈ WNDCnat["SPAA.man","benchmarkmge"]#  579.490321000943
@test JuMP.value(WiNnat._jump_model[Symbol("PA[mch]‡A[mch]")]) ≈ WNDCnat["SPAA.mch","benchmarkmge"]#  588.491860085505
@test JuMP.value(WiNnat._jump_model[Symbol("PA[dat]‡A[dat]")]) ≈ WNDCnat["SPAA.dat","benchmarkmge"]#  245.652028996898
@test JuMP.value(WiNnat._jump_model[Symbol("PA[amd]‡A[amd]")]) ≈ WNDCnat["SPAA.amd","benchmarkmge"]#  229.587824
@test JuMP.value(WiNnat._jump_model[Symbol("PA[oil]‡A[oil]")]) ≈ WNDCnat["SPAA.oil","benchmarkmge"]#  411.63889798397
@test JuMP.value(WiNnat._jump_model[Symbol("PA[hos]‡A[hos]")]) ≈ WNDCnat["SPAA.hos","benchmarkmge"]#  1073.11604999793
@test JuMP.value(WiNnat._jump_model[Symbol("PA[rnt]‡A[rnt]")]) ≈ WNDCnat["SPAA.rnt","benchmarkmge"]#  367.735560970776
@test JuMP.value(WiNnat._jump_model[Symbol("PA[pla]‡A[pla]")]) ≈ WNDCnat["SPAA.pla","benchmarkmge"]#  363.00797901718
@test JuMP.value(WiNnat._jump_model[Symbol("PA[fof]‡A[fof]")]) ≈ WNDCnat["SPAA.fof","benchmarkmge"]#  92.0874858004525
@test JuMP.value(WiNnat._jump_model[Symbol("PA[fin]‡A[fin]")]) ≈ WNDCnat["SPAA.fin","benchmarkmge"]#  183.495134
@test JuMP.value(WiNnat._jump_model[Symbol("PA[tsv]‡A[tsv]")]) ≈ WNDCnat["SPAA.tsv","benchmarkmge"]#  1988.02194989871
@test JuMP.value(WiNnat._jump_model[Symbol("PA[nrs]‡A[nrs]")]) ≈ WNDCnat["SPAA.nrs","benchmarkmge"]#  245.658333
@test JuMP.value(WiNnat._jump_model[Symbol("PA[sec]‡A[sec]")]) ≈ WNDCnat["SPAA.sec","benchmarkmge"]#  513.798265994931
@test JuMP.value(WiNnat._jump_model[Symbol("PA[art]‡A[art]")]) ≈ WNDCnat["SPAA.art","benchmarkmge"]#  174.622135001627
@test JuMP.value(WiNnat._jump_model[Symbol("PA[mov]‡A[mov]")]) ≈ WNDCnat["SPAA.mov","benchmarkmge"]#  146.386317008313
@test JuMP.value(WiNnat._jump_model[Symbol("PA[fpd]‡A[fpd]")]) ≈ WNDCnat["SPAA.fpd","benchmarkmge"]#  221.314816995872
@test JuMP.value(WiNnat._jump_model[Symbol("PA[slg]‡A[slg]")]) ≈ WNDCnat["SPAA.slg","benchmarkmge"]#  1744.23136
@test JuMP.value(WiNnat._jump_model[Symbol("PA[pri]‡A[pri]")]) ≈ WNDCnat["SPAA.pri","benchmarkmge"]#  89.3225462013793
@test JuMP.value(WiNnat._jump_model[Symbol("PA[grd]‡A[grd]")]) ≈ WNDCnat["SPAA.grd","benchmarkmge"]#  93.1481825
@test JuMP.value(WiNnat._jump_model[Symbol("PA[pip]‡A[pip]")]) ≈ WNDCnat["SPAA.pip","benchmarkmge"]#  0.374257519
@test JuMP.value(WiNnat._jump_model[Symbol("PA[sle]‡A[sle]")]) ≈ WNDCnat["SPAA.sle","benchmarkmge"]#  104.176032
@test JuMP.value(WiNnat._jump_model[Symbol("PA[osv]‡A[osv]")]) ≈ WNDCnat["SPAA.osv","benchmarkmge"]#  868.463054999984
@test JuMP.value(WiNnat._jump_model[Symbol("PA[trn]‡A[trn]")]) ≈ WNDCnat["SPAA.trn","benchmarkmge"]#  7.94738373497139
@test JuMP.value(WiNnat._jump_model[Symbol("PA[smn]‡A[smn]")]) ≈ WNDCnat["SPAA.smn","benchmarkmge"]#  124.292406
@test JuMP.value(WiNnat._jump_model[Symbol("PA[fmt]‡A[fmt]")]) ≈ WNDCnat["SPAA.fmt","benchmarkmge"]#  477.616345039274
@test JuMP.value(WiNnat._jump_model[Symbol("PA[pet]‡A[pet]")]) ≈ WNDCnat["SPAA.pet","benchmarkmge"]#  757.577833
@test JuMP.value(WiNnat._jump_model[Symbol("PA[cep]‡A[cep]")]) ≈ WNDCnat["SPAA.cep","benchmarkmge"]#  753.924908891486
@test JuMP.value(WiNnat._jump_model[Symbol("PA[wst]‡A[wst]")]) ≈ WNDCnat["SPAA.wst","benchmarkmge"]#  117.577674999935
@test JuMP.value(WiNnat._jump_model[Symbol("PA[mot]‡A[mot]")]) ≈ WNDCnat["SPAA.mot","benchmarkmge"]#  1119.67645
@test JuMP.value(WiNnat._jump_model[Symbol("PA[adm]‡A[adm]")]) ≈ WNDCnat["SPAA.adm","benchmarkmge"]#  929.228217998669
@test JuMP.value(WiNnat._jump_model[Symbol("PA[soc]‡A[soc]")]) ≈ WNDCnat["SPAA.soc","benchmarkmge"]#  211.263869
@test JuMP.value(WiNnat._jump_model[Symbol("PA[alt]‡A[alt]")]) ≈ WNDCnat["SPAA.alt","benchmarkmge"]#  429.277534993067
@test JuMP.value(WiNnat._jump_model[Symbol("PA[pmt]‡A[pmt]")]) ≈ WNDCnat["SPAA.pmt","benchmarkmge"]#  307.0467769927
@test JuMP.value(WiNnat._jump_model[Symbol("PA[trk]‡A[trk]")]) ≈ WNDCnat["SPAA.trk","benchmarkmge"]#  37.7022274993623
@test JuMP.value(WiNnat._jump_model[Symbol("PA[fdd]‡A[fdd]")]) ≈ WNDCnat["SPAA.fdd","benchmarkmge"]#  598.321003
@test JuMP.value(WiNnat._jump_model[Symbol("PA[wtt]‡A[wtt]")]) ≈ WNDCnat["SPAA.wtt","benchmarkmge"]#  24.8619917973652
@test JuMP.value(WiNnat._jump_model[Symbol("PA[wpd]‡A[wpd]")]) ≈ WNDCnat["SPAA.wpd","benchmarkmge"]#  169.552497997188
@test JuMP.value(WiNnat._jump_model[Symbol("PA[wht]‡A[wht]")]) ≈ WNDCnat["SPAA.wht","benchmarkmge"]#  101.032245
@test JuMP.value(WiNnat._jump_model[Symbol("PA[wrh]‡A[wrh]")]) ≈ WNDCnat["SPAA.wrh","benchmarkmge"]#  141.95619299996
@test JuMP.value(WiNnat._jump_model[Symbol("PA[ott]‡A[ott]")]) ≈ WNDCnat["SPAA.ott","benchmarkmge"]#  7.216437
@test JuMP.value(WiNnat._jump_model[Symbol("PA[che]‡A[che]")]) ≈ WNDCnat["SPAA.che","benchmarkmge"]#  1318.00180013406
@test JuMP.value(WiNnat._jump_model[Symbol("PA[air]‡A[air]")]) ≈ WNDCnat["SPAA.air","benchmarkmge"]#  208.476751
@test JuMP.value(WiNnat._jump_model[Symbol("PA[mmf]‡A[mmf]")]) ≈ WNDCnat["SPAA.mmf","benchmarkmge"]#  433.137576991175
@test JuMP.value(WiNnat._jump_model[Symbol("PA[otr]‡A[otr]")]) ≈ WNDCnat["SPAA.otr","benchmarkmge"]#  234.454974992182
@test JuMP.value(WiNnat._jump_model[Symbol("PA[min]‡A[min]")]) ≈ WNDCnat["SPAA.min","benchmarkmge"]#  111.084490990502
@test JuMP.value(WiNnat._jump_model[Symbol("PY[ppd]†A→dmppd")]) ≈ WNDCnat["DPYA.ppd","benchmarkmge"]#  177.848050085401
@test JuMP.value(WiNnat._jump_model[Symbol("PY[res]†A→dmres")]) ≈ WNDCnat["DPYA.res","benchmarkmge"]#  899.582049
@test JuMP.value(WiNnat._jump_model[Symbol("PY[com]†A→dmcom")]) ≈ WNDCnat["DPYA.com","benchmarkmge"]#  517.204729
@test JuMP.value(WiNnat._jump_model[Symbol("PY[amb]†A→dmamb")]) ≈ WNDCnat["DPYA.amb","benchmarkmge"]#  1092.93382
@test JuMP.value(WiNnat._jump_model[Symbol("PY[fbp]†A→dmfbp")]) ≈ WNDCnat["DPYA.fbp","benchmarkmge"]#  930.255710616793
@test JuMP.value(WiNnat._jump_model[Symbol("PY[rec]†A→dmrec")]) ≈ WNDCnat["DPYA.rec","benchmarkmge"]#  195.091973
@test JuMP.value(WiNnat._jump_model[Symbol("PY[con]†A→dmcon")]) ≈ WNDCnat["DPYA.con","benchmarkmge"]#  1659.55143
@test JuMP.value(WiNnat._jump_model[Symbol("PY[agr]†A→dmagr")]) ≈ WNDCnat["DPYA.agr","benchmarkmge"]#  396.050008932756
@test JuMP.value(WiNnat._jump_model[Symbol("PY[eec]†A→dmeec")]) ≈ WNDCnat["DPYA.eec","benchmarkmge"]#  117.88548944717
@test JuMP.value(WiNnat._jump_model[Symbol("PY[fnd]†A→dmfnd")]) ≈ WNDCnat["DPYA.fnd","benchmarkmge"]#  380.898129
@test JuMP.value(WiNnat._jump_model[Symbol("PY[pub]†A→dmpub")]) ≈ WNDCnat["DPYA.pub","benchmarkmge"]#  279.160328
@test JuMP.value(WiNnat._jump_model[Symbol("PY[hou]†A→dmhou")]) ≈ WNDCnat["DPYA.hou","benchmarkmge"]#  2073.31916
@test JuMP.value(WiNnat._jump_model[Symbol("PY[ins]†A→dmins")]) ≈ WNDCnat["DPYA.ins","benchmarkmge"]#  1122.38542
@test JuMP.value(WiNnat._jump_model[Symbol("PY[tex]†A→dmtex")]) ≈ WNDCnat["DPYA.tex","benchmarkmge"]#  46.3777108288246
@test JuMP.value(WiNnat._jump_model[Symbol("PY[leg]†A→dmleg")]) ≈ WNDCnat["DPYA.leg","benchmarkmge"]#  342.991585
@test JuMP.value(WiNnat._jump_model[Symbol("PY[fen]†A→dmfen")]) ≈ WNDCnat["DPYA.fen","benchmarkmge"]#  70.9003684
@test JuMP.value(WiNnat._jump_model[Symbol("PY[uti]†A→dmuti")]) ≈ WNDCnat["DPYA.uti","benchmarkmge"]#  624.190868
@test JuMP.value(WiNnat._jump_model[Symbol("PY[nmp]†A→dmnmp")]) ≈ WNDCnat["DPYA.nmp","benchmarkmge"]#  123.614506
@test JuMP.value(WiNnat._jump_model[Symbol("PY[brd]†A→dmbrd")]) ≈ WNDCnat["DPYA.brd","benchmarkmge"]#  683.419058
@test JuMP.value(WiNnat._jump_model[Symbol("PY[bnk]†A→dmbnk")]) ≈ WNDCnat["DPYA.bnk","benchmarkmge"]#  852.55204
@test JuMP.value(WiNnat._jump_model[Symbol("PY[ore]†A→dmore")]) ≈ WNDCnat["DPYA.ore","benchmarkmge"]#  1259.29276
@test JuMP.value(WiNnat._jump_model[Symbol("PY[edu]†A→dmedu")]) ≈ WNDCnat["DPYA.edu","benchmarkmge"]#  393.263985
@test JuMP.value(WiNnat._jump_model[Symbol("PY[ote]†A→dmote")]) ≈ WNDCnat["DPYA.ote","benchmarkmge"]#  317.811410898786
@test JuMP.value(WiNnat._jump_model[Symbol("PY[man]†A→dmman")]) ≈ WNDCnat["DPYA.man","benchmarkmge"]#  582.277441
@test JuMP.value(WiNnat._jump_model[Symbol("PY[mch]†A→dmmch")]) ≈ WNDCnat["DPYA.mch","benchmarkmge"]#  351.230727563246
@test JuMP.value(WiNnat._jump_model[Symbol("PY[dat]†A→dmdat")]) ≈ WNDCnat["DPYA.dat","benchmarkmge"]#  249.633814
@test JuMP.value(WiNnat._jump_model[Symbol("PY[amd]†A→dmamd")]) ≈ WNDCnat["DPYA.amd","benchmarkmge"]#  211.274527
@test JuMP.value(WiNnat._jump_model[Symbol("PY[oil]†A→dmoil")]) ≈ WNDCnat["DPYA.oil","benchmarkmge"]#  231.922532588968
@test JuMP.value(WiNnat._jump_model[Symbol("PY[hos]†A→dmhos")]) ≈ WNDCnat["DPYA.hos","benchmarkmge"]#  1069.65353
@test JuMP.value(WiNnat._jump_model[Symbol("PY[rnt]†A→dmrnt")]) ≈ WNDCnat["DPYA.rnt","benchmarkmge"]#  433.205937
@test JuMP.value(WiNnat._jump_model[Symbol("PY[pla]†A→dmpla")]) ≈ WNDCnat["DPYA.pla","benchmarkmge"]#  230.941662410601
@test JuMP.value(WiNnat._jump_model[Symbol("PY[fof]†A→dmfof")]) ≈ WNDCnat["DPYA.fof","benchmarkmge"]#  65.8524888157003
@test JuMP.value(WiNnat._jump_model[Symbol("PY[fin]†A→dmfin")]) ≈ WNDCnat["DPYA.fin","benchmarkmge"]#  183.457238
@test JuMP.value(WiNnat._jump_model[Symbol("PY[tsv]†A→dmtsv")]) ≈ WNDCnat["DPYA.tsv","benchmarkmge"]#  2036.04782
@test JuMP.value(WiNnat._jump_model[Symbol("PY[nrs]†A→dmnrs")]) ≈ WNDCnat["DPYA.nrs","benchmarkmge"]#  242.743749
@test JuMP.value(WiNnat._jump_model[Symbol("PY[sec]†A→dmsec")]) ≈ WNDCnat["DPYA.sec","benchmarkmge"]#  584.315032
@test JuMP.value(WiNnat._jump_model[Symbol("PY[art]†A→dmart")]) ≈ WNDCnat["DPYA.art","benchmarkmge"]#  169.263525
@test JuMP.value(WiNnat._jump_model[Symbol("PY[mov]†A→dmmov")]) ≈ WNDCnat["DPYA.mov","benchmarkmge"]#  145.130265
@test JuMP.value(WiNnat._jump_model[Symbol("PY[fpd]†A→dmfpd")]) ≈ WNDCnat["DPYA.fpd","benchmarkmge"]#  71.5262340021643
@test JuMP.value(WiNnat._jump_model[Symbol("PY[slg]†A→dmslg")]) ≈ WNDCnat["DPYA.slg","benchmarkmge"]#  1744.23136
@test JuMP.value(WiNnat._jump_model[Symbol("PY[pri]†A→dmpri")]) ≈ WNDCnat["DPYA.pri","benchmarkmge"]#  71.103540199266
@test JuMP.value(WiNnat._jump_model[Symbol("PY[grd]†A→dmgrd")]) ≈ WNDCnat["DPYA.grd","benchmarkmge"]#  92.1405807
@test JuMP.value(WiNnat._jump_model[Symbol("PY[pip]†A→dmpip")]) ≈ WNDCnat["DPYA.pip","benchmarkmge"]#  0.551520281
@test JuMP.value(WiNnat._jump_model[Symbol("PY[sle]†A→dmsle")]) ≈ WNDCnat["DPYA.sle","benchmarkmge"]#  104.176032
@test JuMP.value(WiNnat._jump_model[Symbol("PY[osv]†A→dmosv")]) ≈ WNDCnat["DPYA.osv","benchmarkmge"]#  843.629126
@test JuMP.value(WiNnat._jump_model[Symbol("PY[trn]†A→dmtrn")]) ≈ WNDCnat["DPYA.trn","benchmarkmge"]#  10.818151
@test JuMP.value(WiNnat._jump_model[Symbol("PY[smn]†A→dmsmn")]) ≈ WNDCnat["DPYA.smn","benchmarkmge"]#  126.289406
@test JuMP.value(WiNnat._jump_model[Symbol("PY[fmt]†A→dmfmt")]) ≈ WNDCnat["DPYA.fmt","benchmarkmge"]#  329.180896584783
@test JuMP.value(WiNnat._jump_model[Symbol("PY[pet]†A→dmpet")]) ≈ WNDCnat["DPYA.pet","benchmarkmge"]#  528.436219055607
@test JuMP.value(WiNnat._jump_model[Symbol("PY[cep]†A→dmcep")]) ≈ WNDCnat["DPYA.cep","benchmarkmge"]#  298.351501859884
@test JuMP.value(WiNnat._jump_model[Symbol("PY[wst]†A→dmwst")]) ≈ WNDCnat["DPYA.wst","benchmarkmge"]#  115.754169
@test JuMP.value(WiNnat._jump_model[Symbol("PY[mot]†A→dmmot")]) ≈ WNDCnat["DPYA.mot","benchmarkmge"]#  657.78166616378
@test JuMP.value(WiNnat._jump_model[Symbol("PY[adm]†A→dmadm")]) ≈ WNDCnat["DPYA.adm","benchmarkmge"]#  923.386612
@test JuMP.value(WiNnat._jump_model[Symbol("PY[soc]†A→dmsoc")]) ≈ WNDCnat["DPYA.soc","benchmarkmge"]#  210.448152
@test JuMP.value(WiNnat._jump_model[Symbol("PY[alt]†A→dmalt")]) ≈ WNDCnat["DPYA.alt","benchmarkmge"]#  18.7614694421086
@test JuMP.value(WiNnat._jump_model[Symbol("PY[pmt]†A→dmpmt")]) ≈ WNDCnat["DPYA.pmt","benchmarkmge"]#  208.537991982698
@test JuMP.value(WiNnat._jump_model[Symbol("PY[trk]†A→dmtrk")]) ≈ WNDCnat["DPYA.trk","benchmarkmge"]#  38.934866
@test JuMP.value(WiNnat._jump_model[Symbol("PY[fdd]†A→dmfdd")]) ≈ WNDCnat["DPYA.fdd","benchmarkmge"]#  598.321003
@test JuMP.value(WiNnat._jump_model[Symbol("PY[wtt]†A→dmwtt")]) ≈ WNDCnat["DPYA.wtt","benchmarkmge"]#  29.5450418
@test JuMP.value(WiNnat._jump_model[Symbol("PY[wpd]†A→dmwpd")]) ≈ WNDCnat["DPYA.wpd","benchmarkmge"]#  110.755670091967
@test JuMP.value(WiNnat._jump_model[Symbol("PY[wht]†A→dmwht")]) ≈ WNDCnat["DPYA.wht","benchmarkmge"]#  103.418245
@test JuMP.value(WiNnat._jump_model[Symbol("PY[wrh]†A→dmwrh")]) ≈ WNDCnat["DPYA.wrh","benchmarkmge"]#  141.952358
@test JuMP.value(WiNnat._jump_model[Symbol("PY[ott]†A→dmott")]) ≈ WNDCnat["DPYA.ott","benchmarkmge"]#  7.216437
@test JuMP.value(WiNnat._jump_model[Symbol("PY[che]†A→dmche")]) ≈ WNDCnat["DPYA.che","benchmarkmge"]#  747.701432229913
@test JuMP.value(WiNnat._jump_model[Symbol("PY[air]†A→dmair")]) ≈ WNDCnat["DPYA.air","benchmarkmge"]#  189.931126
@test JuMP.value(WiNnat._jump_model[Symbol("PY[mmf]†A→dmmmf")]) ≈ WNDCnat["DPYA.mmf","benchmarkmge"]#  145.823807487888
@test JuMP.value(WiNnat._jump_model[Symbol("PY[otr]†A→dmotr")]) ≈ WNDCnat["DPYA.otr","benchmarkmge"]#  244.23904
@test JuMP.value(WiNnat._jump_model[Symbol("PY[min]†A→dmmin")]) ≈ WNDCnat["DPYA.min","benchmarkmge"]#  83.8020487
@test JuMP.value(WiNnat._jump_model[Symbol("PM[trn]‡MS[trn]")]) ≈ WNDCnat["SPMMS.trn","benchmarkmge"]#  441.38467
@test JuMP.value(WiNnat._jump_model[Symbol("PM[trd]‡MS[trd]")]) ≈ WNDCnat["SPMMS.trd","benchmarkmge"]#  2963.50744
@test JuMP.value(WiNnat._jump_model[Symbol("MS")][:trn]) ≈ WNDCnat["MS.trn","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("MS")][:trd]) ≈ WNDCnat["MS.trd","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("PA")][:ppd]) ≈ WNDCnat["PA.ppd","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("PA")][:res]) ≈ WNDCnat["PA.res","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("PA")][:com]) ≈ WNDCnat["PA.com","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("PA")][:amb]) ≈ WNDCnat["PA.amb","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("PA")][:fbp]) ≈ WNDCnat["PA.fbp","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("PA")][:rec]) ≈ WNDCnat["PA.rec","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("PA")][:con]) ≈ WNDCnat["PA.con","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("PA")][:agr]) ≈ WNDCnat["PA.agr","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("PA")][:eec]) ≈ WNDCnat["PA.eec","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("PA")][:fnd]) ≈ WNDCnat["PA.fnd","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("PA")][:pub]) ≈ WNDCnat["PA.pub","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("PA")][:hou]) ≈ WNDCnat["PA.hou","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("PA")][:fbt]) ≈ WNDCnat["PA.fbt","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("PA")][:ins]) ≈ WNDCnat["PA.ins","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("PA")][:tex]) ≈ WNDCnat["PA.tex","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("PA")][:leg]) ≈ WNDCnat["PA.leg","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("PA")][:fen]) ≈ WNDCnat["PA.fen","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("PA")][:uti]) ≈ WNDCnat["PA.uti","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("PA")][:nmp]) ≈ WNDCnat["PA.nmp","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("PA")][:brd]) ≈ WNDCnat["PA.brd","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("PA")][:bnk]) ≈ WNDCnat["PA.bnk","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("PA")][:ore]) ≈ WNDCnat["PA.ore","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("PA")][:edu]) ≈ WNDCnat["PA.edu","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("PA")][:ote]) ≈ WNDCnat["PA.ote","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("PA")][:man]) ≈ WNDCnat["PA.man","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("PA")][:mch]) ≈ WNDCnat["PA.mch","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("PA")][:dat]) ≈ WNDCnat["PA.dat","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("PA")][:amd]) ≈ WNDCnat["PA.amd","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("PA")][:oil]) ≈ WNDCnat["PA.oil","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("PA")][:hos]) ≈ WNDCnat["PA.hos","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("PA")][:rnt]) ≈ WNDCnat["PA.rnt","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("PA")][:pla]) ≈ WNDCnat["PA.pla","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("PA")][:fof]) ≈ WNDCnat["PA.fof","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("PA")][:fin]) ≈ WNDCnat["PA.fin","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("PA")][:tsv]) ≈ WNDCnat["PA.tsv","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("PA")][:nrs]) ≈ WNDCnat["PA.nrs","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("PA")][:sec]) ≈ WNDCnat["PA.sec","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("PA")][:art]) ≈ WNDCnat["PA.art","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("PA")][:mov]) ≈ WNDCnat["PA.mov","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("PA")][:fpd]) ≈ WNDCnat["PA.fpd","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("PA")][:slg]) ≈ WNDCnat["PA.slg","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("PA")][:pri]) ≈ WNDCnat["PA.pri","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("PA")][:grd]) ≈ WNDCnat["PA.grd","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("PA")][:pip]) ≈ WNDCnat["PA.pip","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("PA")][:sle]) ≈ WNDCnat["PA.sle","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("PA")][:osv]) ≈ WNDCnat["PA.osv","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("PA")][:trn]) ≈ WNDCnat["PA.trn","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("PA")][:smn]) ≈ WNDCnat["PA.smn","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("PA")][:fmt]) ≈ WNDCnat["PA.fmt","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("PA")][:pet]) ≈ WNDCnat["PA.pet","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("PA")][:mvt]) ≈ WNDCnat["PA.mvt","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("PA")][:cep]) ≈ WNDCnat["PA.cep","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("PA")][:wst]) ≈ WNDCnat["PA.wst","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("PA")][:mot]) ≈ WNDCnat["PA.mot","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("PA")][:adm]) ≈ WNDCnat["PA.adm","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("PA")][:soc]) ≈ WNDCnat["PA.soc","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("PA")][:alt]) ≈ WNDCnat["PA.alt","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("PA")][:pmt]) ≈ WNDCnat["PA.pmt","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("PA")][:trk]) ≈ WNDCnat["PA.trk","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("PA")][:fdd]) ≈ WNDCnat["PA.fdd","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("PA")][:gmt]) ≈ WNDCnat["PA.gmt","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("PA")][:wtt]) ≈ WNDCnat["PA.wtt","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("PA")][:wpd]) ≈ WNDCnat["PA.wpd","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("PA")][:wht]) ≈ WNDCnat["PA.wht","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("PA")][:wrh]) ≈ WNDCnat["PA.wrh","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("PA")][:ott]) ≈ WNDCnat["PA.ott","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("PA")][:che]) ≈ WNDCnat["PA.che","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("PA")][:air]) ≈ WNDCnat["PA.air","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("PA")][:mmf]) ≈ WNDCnat["PA.mmf","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("PA")][:otr]) ≈ WNDCnat["PA.otr","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("PA")][:min]) ≈ WNDCnat["PA.min","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("PY")][:ppd]) ≈ WNDCnat["PY.ppd","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("PY")][:res]) ≈ WNDCnat["PY.res","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("PY")][:com]) ≈ WNDCnat["PY.com","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("PY")][:amb]) ≈ WNDCnat["PY.amb","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("PY")][:fbp]) ≈ WNDCnat["PY.fbp","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("PY")][:rec]) ≈ WNDCnat["PY.rec","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("PY")][:con]) ≈ WNDCnat["PY.con","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("PY")][:agr]) ≈ WNDCnat["PY.agr","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("PY")][:eec]) ≈ WNDCnat["PY.eec","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("PY")][:fnd]) ≈ WNDCnat["PY.fnd","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("PY")][:pub]) ≈ WNDCnat["PY.pub","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("PY")][:hou]) ≈ WNDCnat["PY.hou","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("PY")][:fbt]) ≈ WNDCnat["PY.fbt","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("PY")][:ins]) ≈ WNDCnat["PY.ins","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("PY")][:tex]) ≈ WNDCnat["PY.tex","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("PY")][:leg]) ≈ WNDCnat["PY.leg","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("PY")][:fen]) ≈ WNDCnat["PY.fen","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("PY")][:uti]) ≈ WNDCnat["PY.uti","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("PY")][:nmp]) ≈ WNDCnat["PY.nmp","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("PY")][:brd]) ≈ WNDCnat["PY.brd","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("PY")][:bnk]) ≈ WNDCnat["PY.bnk","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("PY")][:ore]) ≈ WNDCnat["PY.ore","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("PY")][:edu]) ≈ WNDCnat["PY.edu","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("PY")][:ote]) ≈ WNDCnat["PY.ote","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("PY")][:man]) ≈ WNDCnat["PY.man","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("PY")][:mch]) ≈ WNDCnat["PY.mch","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("PY")][:dat]) ≈ WNDCnat["PY.dat","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("PY")][:amd]) ≈ WNDCnat["PY.amd","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("PY")][:oil]) ≈ WNDCnat["PY.oil","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("PY")][:hos]) ≈ WNDCnat["PY.hos","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("PY")][:rnt]) ≈ WNDCnat["PY.rnt","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("PY")][:pla]) ≈ WNDCnat["PY.pla","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("PY")][:fof]) ≈ WNDCnat["PY.fof","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("PY")][:fin]) ≈ WNDCnat["PY.fin","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("PY")][:tsv]) ≈ WNDCnat["PY.tsv","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("PY")][:nrs]) ≈ WNDCnat["PY.nrs","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("PY")][:sec]) ≈ WNDCnat["PY.sec","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("PY")][:art]) ≈ WNDCnat["PY.art","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("PY")][:mov]) ≈ WNDCnat["PY.mov","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("PY")][:fpd]) ≈ WNDCnat["PY.fpd","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("PY")][:slg]) ≈ WNDCnat["PY.slg","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("PY")][:pri]) ≈ WNDCnat["PY.pri","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("PY")][:grd]) ≈ WNDCnat["PY.grd","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("PY")][:pip]) ≈ WNDCnat["PY.pip","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("PY")][:sle]) ≈ WNDCnat["PY.sle","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("PY")][:osv]) ≈ WNDCnat["PY.osv","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("PY")][:trn]) ≈ WNDCnat["PY.trn","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("PY")][:smn]) ≈ WNDCnat["PY.smn","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("PY")][:fmt]) ≈ WNDCnat["PY.fmt","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("PY")][:pet]) ≈ WNDCnat["PY.pet","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("PY")][:mvt]) ≈ WNDCnat["PY.mvt","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("PY")][:cep]) ≈ WNDCnat["PY.cep","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("PY")][:wst]) ≈ WNDCnat["PY.wst","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("PY")][:mot]) ≈ WNDCnat["PY.mot","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("PY")][:adm]) ≈ WNDCnat["PY.adm","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("PY")][:soc]) ≈ WNDCnat["PY.soc","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("PY")][:alt]) ≈ WNDCnat["PY.alt","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("PY")][:pmt]) ≈ WNDCnat["PY.pmt","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("PY")][:trk]) ≈ WNDCnat["PY.trk","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("PY")][:fdd]) ≈ WNDCnat["PY.fdd","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("PY")][:gmt]) ≈ WNDCnat["PY.gmt","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("PY")][:wtt]) ≈ WNDCnat["PY.wtt","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("PY")][:wpd]) ≈ WNDCnat["PY.wpd","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("PY")][:wht]) ≈ WNDCnat["PY.wht","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("PY")][:wrh]) ≈ WNDCnat["PY.wrh","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("PY")][:ott]) ≈ WNDCnat["PY.ott","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("PY")][:che]) ≈ WNDCnat["PY.che","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("PY")][:air]) ≈ WNDCnat["PY.air","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("PY")][:mmf]) ≈ WNDCnat["PY.mmf","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("PY")][:otr]) ≈ WNDCnat["PY.otr","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("PY")][:min]) ≈ WNDCnat["PY.min","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("PVA")][:compen]) ≈ WNDCnat["PVA.compen","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("PVA")][:surplus]) ≈ WNDCnat["PVA.surplus","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("PM")][:trn]) ≈ WNDCnat["PM.trn","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("PM")][:trd]) ≈ WNDCnat["PM.trd","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("PFX")]) ≈ WNDCnat["PFX.missing","benchmarkmge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("RA")]) ≈ WNDCnat["RA.missing","benchmarkmge"]#  13138.7573084527



# Counterfactual
for i in sectorsi
	set_value(ta[i], 0.)
	set_value(tm[i], 0.)
end
set_value(RA,  12453.8963) #So far, this updated default normalization value needs to be set, value from GAMS output. 12453.8963
set_fixed!(RA, true)

solve!(WiNnat, convergence_tolerance=1e-6, cumulative_iteration_limit=10000);

@test JuMP.value(WiNnat._jump_model[Symbol("Y")][:ppd]) ≈ WNDCnat["Y.ppd","Countermge"]  #  atol=1.0e-7 #  1.01879539799114
@test JuMP.value(WiNnat._jump_model[Symbol("Y")][:res]) ≈ WNDCnat["Y.res","Countermge"]  #atol=1.0e-5 #  1.03916450940003
@test JuMP.value(WiNnat._jump_model[Symbol("Y")][:com]) ≈ WNDCnat["Y.com","Countermge"]  #atol=1.0e-5 #  0.999213507047477
@test JuMP.value(WiNnat._jump_model[Symbol("Y")][:amb]) ≈ WNDCnat["Y.amb","Countermge"]     #atol=1.0e-8 #  0.969241605623854
@test JuMP.value(WiNnat._jump_model[Symbol("Y")][:fbp]) ≈ WNDCnat["Y.fbp","Countermge"]     #atol=1.0e-8 #  1.04401987590314
@test JuMP.value(WiNnat._jump_model[Symbol("Y")][:rec]) ≈ WNDCnat["Y.rec","Countermge"]      #atol=1.0e-9 #  1.02557666099282
@test JuMP.value(WiNnat._jump_model[Symbol("Y")][:con]) ≈ WNDCnat["Y.con","Countermge"]     #atol=1.0e-8 #  0.998727851907362
@test JuMP.value(WiNnat._jump_model[Symbol("Y")][:agr]) ≈ WNDCnat["Y.agr","Countermge"]     #atol=1.0e-8 #  1.02650937597374
@test JuMP.value(WiNnat._jump_model[Symbol("Y")][:eec]) ≈ WNDCnat["Y.eec","Countermge"]     #atol=1.0e-8 #  0.99342306828626
@test JuMP.value(WiNnat._jump_model[Symbol("Y")][:fnd]) ≈ WNDCnat["Y.fnd","Countermge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("Y")][:pub]) ≈ WNDCnat["Y.pub","Countermge"] #atol=1.0e-4 #  0.995058224664917
@test JuMP.value(WiNnat._jump_model[Symbol("Y")][:hou]) ≈ WNDCnat["Y.hou","Countermge"]  #atol=1.0e-5 #  0.946697277098152
@test JuMP.value(WiNnat._jump_model[Symbol("Y")][:fbt]) ≈ WNDCnat["Y.fbt","Countermge"]     #atol=1.0e-8 #  1.02333194011532
@test JuMP.value(WiNnat._jump_model[Symbol("Y")][:ins]) ≈ WNDCnat["Y.ins","Countermge"]  #atol=1.0e-5 #  0.99526434878665
@test JuMP.value(WiNnat._jump_model[Symbol("Y")][:tex]) ≈ WNDCnat["Y.tex","Countermge"]  #atol=1.0e-5 #  0.987755013051637
@test JuMP.value(WiNnat._jump_model[Symbol("Y")][:leg]) ≈ WNDCnat["Y.leg","Countermge"]    #atol=1.0e-7 #  1.00528427737105
@test JuMP.value(WiNnat._jump_model[Symbol("Y")][:fen]) ≈ WNDCnat["Y.fen","Countermge"]  #atol=1.0e-5 #  1.00420711992385
@test JuMP.value(WiNnat._jump_model[Symbol("Y")][:uti]) ≈ WNDCnat["Y.uti","Countermge"]    #atol=1.0e-7 #  1.02814569632055
@test JuMP.value(WiNnat._jump_model[Symbol("Y")][:nmp]) ≈ WNDCnat["Y.nmp","Countermge"]     #atol=1.0e-8 #  0.997668770519886
@test JuMP.value(WiNnat._jump_model[Symbol("Y")][:brd]) ≈ WNDCnat["Y.brd","Countermge"]      #atol=1.0e-9 #  1.02314762629269
@test JuMP.value(WiNnat._jump_model[Symbol("Y")][:bnk]) ≈ WNDCnat["Y.bnk","Countermge"]  #atol=1.0e-5 #  0.981976556556577
@test JuMP.value(WiNnat._jump_model[Symbol("Y")][:ore]) ≈ WNDCnat["Y.ore","Countermge"]     #atol=1.0e-8 #  1.00433844228312
@test JuMP.value(WiNnat._jump_model[Symbol("Y")][:edu]) ≈ WNDCnat["Y.edu","Countermge"]#  0.961325642755518
@test JuMP.value(WiNnat._jump_model[Symbol("Y")][:ote]) ≈ WNDCnat["Y.ote","Countermge"]   #atol=1.0e-6 #  1.00279349452643
@test JuMP.value(WiNnat._jump_model[Symbol("Y")][:man]) ≈ WNDCnat["Y.man","Countermge"]       #atol=1.0e-10 #  1.0157557775201
@test JuMP.value(WiNnat._jump_model[Symbol("Y")][:mch]) ≈ WNDCnat["Y.mch","Countermge"]     #atol=1.0e-8 #  1.00583441769422
@test JuMP.value(WiNnat._jump_model[Symbol("Y")][:dat]) ≈ WNDCnat["Y.dat","Countermge"]     #atol=1.0e-8 #  0.997027704824509
@test JuMP.value(WiNnat._jump_model[Symbol("Y")][:amd]) ≈ WNDCnat["Y.amd","Countermge"]   #atol=1.0e-6 #  1.05731716703795
@test JuMP.value(WiNnat._jump_model[Symbol("Y")][:oil]) ≈ WNDCnat["Y.oil","Countermge"]   #atol=1.0e-6 #  1.07601899897433
@test JuMP.value(WiNnat._jump_model[Symbol("Y")][:hos]) ≈ WNDCnat["Y.hos","Countermge"]#  0.969741673504474
@test JuMP.value(WiNnat._jump_model[Symbol("Y")][:rnt]) ≈ WNDCnat["Y.rnt","Countermge"]     #atol=1.0e-8 #  1.02006210132733
@test JuMP.value(WiNnat._jump_model[Symbol("Y")][:pla]) ≈ WNDCnat["Y.pla","Countermge"]       #atol=1.0e-10 #  1.00803411783979
@test JuMP.value(WiNnat._jump_model[Symbol("Y")][:fof]) ≈ WNDCnat["Y.fof","Countermge"]   #atol=1.0e-6 #  1.01200162267001
@test JuMP.value(WiNnat._jump_model[Symbol("Y")][:fin]) ≈ WNDCnat["Y.fin","Countermge"]  #atol=1.0e-5 #  0.973024378808373
@test JuMP.value(WiNnat._jump_model[Symbol("Y")][:tsv]) ≈ WNDCnat["Y.tsv","Countermge"]#  1.00152715398509
@test JuMP.value(WiNnat._jump_model[Symbol("Y")][:nrs]) ≈ WNDCnat["Y.nrs","Countermge"]     #atol=1.0e-8 #  0.986391506133684
@test JuMP.value(WiNnat._jump_model[Symbol("Y")][:sec]) ≈ WNDCnat["Y.sec","Countermge"]    #atol=1.0e-7 #  0.981791061304817
@test JuMP.value(WiNnat._jump_model[Symbol("Y")][:art]) ≈ WNDCnat["Y.art","Countermge"]     #atol=1.0e-8 #  1.00647162064957
@test JuMP.value(WiNnat._jump_model[Symbol("Y")][:mov]) ≈ WNDCnat["Y.mov","Countermge"]     #atol=1.0e-8 #  1.00701578823184
@test JuMP.value(WiNnat._jump_model[Symbol("Y")][:fpd]) ≈ WNDCnat["Y.fpd","Countermge"]   #atol=1.0e-6 #  1.01933464614267
@test JuMP.value(WiNnat._jump_model[Symbol("Y")][:slg]) ≈ WNDCnat["Y.slg","Countermge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("Y")][:pri]) ≈ WNDCnat["Y.pri","Countermge"]  #atol=1.0e-5 #  1.00376858507486
@test JuMP.value(WiNnat._jump_model[Symbol("Y")][:grd]) ≈ WNDCnat["Y.grd","Countermge"]   #atol=1.0e-6 #  0.991541344798476
@test JuMP.value(WiNnat._jump_model[Symbol("Y")][:pip]) ≈ WNDCnat["Y.pip","Countermge"]   #atol=1.0e-6 #  1.02794335860495
@test JuMP.value(WiNnat._jump_model[Symbol("Y")][:sle]) ≈ WNDCnat["Y.sle","Countermge"]     #atol=1.0e-8 #  0.996458642436654
@test JuMP.value(WiNnat._jump_model[Symbol("Y")][:osv]) ≈ WNDCnat["Y.osv","Countermge"]      #atol=1.0e-9 #  0.992685782257385
@test JuMP.value(WiNnat._jump_model[Symbol("Y")][:trn]) ≈ WNDCnat["Y.trn","Countermge"]   #atol=1.0e-6 #  1.02187138857596
@test JuMP.value(WiNnat._jump_model[Symbol("Y")][:smn]) ≈ WNDCnat["Y.smn","Countermge"]     #atol=1.0e-8 #  0.970472174292795
@test JuMP.value(WiNnat._jump_model[Symbol("Y")][:fmt]) ≈ WNDCnat["Y.fmt","Countermge"]   #atol=1.0e-6 #  1.00183519282339
@test JuMP.value(WiNnat._jump_model[Symbol("Y")][:pet]) ≈ WNDCnat["Y.pet","Countermge"]      #atol=1.0e-9 #  1.08463382092375
@test JuMP.value(WiNnat._jump_model[Symbol("Y")][:mvt]) ≈ WNDCnat["Y.mvt","Countermge"]      #atol=1.0e-9 #  1.02309900824386
@test JuMP.value(WiNnat._jump_model[Symbol("Y")][:cep]) ≈ WNDCnat["Y.cep","Countermge"]  #atol=1.0e-5 #  0.985266980409964
@test JuMP.value(WiNnat._jump_model[Symbol("Y")][:wst]) ≈ WNDCnat["Y.wst","Countermge"]#  1.00291955467072
@test JuMP.value(WiNnat._jump_model[Symbol("Y")][:mot]) ≈ WNDCnat["Y.mot","Countermge"]     #atol=1.0e-8 #  1.02404048249363
@test JuMP.value(WiNnat._jump_model[Symbol("Y")][:adm]) ≈ WNDCnat["Y.adm","Countermge"]      #atol=1.0e-9 #  1.00240441433003
@test JuMP.value(WiNnat._jump_model[Symbol("Y")][:soc]) ≈ WNDCnat["Y.soc","Countermge"]     #atol=1.0e-8 #  0.977517939406463
@test JuMP.value(WiNnat._jump_model[Symbol("Y")][:alt]) ≈ WNDCnat["Y.alt","Countermge"]  #atol=1.0e-5 #  0.849290791579411
@test JuMP.value(WiNnat._jump_model[Symbol("Y")][:pmt]) ≈ WNDCnat["Y.pmt","Countermge"]     #atol=1.0e-8 #  1.01858672910096
@test JuMP.value(WiNnat._jump_model[Symbol("Y")][:trk]) ≈ WNDCnat["Y.trk","Countermge"]    #atol=1.0e-7 #  1.02647470638081
@test JuMP.value(WiNnat._jump_model[Symbol("Y")][:fdd]) ≈ WNDCnat["Y.fdd","Countermge"] #  1
@test JuMP.value(WiNnat._jump_model[Symbol("Y")][:gmt]) ≈ WNDCnat["Y.gmt","Countermge"] #atol=1.0e-4 #  1.02311042055839
@test JuMP.value(WiNnat._jump_model[Symbol("Y")][:wtt]) ≈ WNDCnat["Y.wtt","Countermge"]  #atol=1.0e-5 #  1.01549527464292
@test JuMP.value(WiNnat._jump_model[Symbol("Y")][:wpd]) ≈ WNDCnat["Y.wpd","Countermge"]     #atol=1.0e-8 #  1.00651815029712
@test JuMP.value(WiNnat._jump_model[Symbol("Y")][:wht]) ≈ WNDCnat["Y.wht","Countermge"]#  1.02303098388213
@test JuMP.value(WiNnat._jump_model[Symbol("Y")][:wrh]) ≈ WNDCnat["Y.wrh","Countermge"] #atol=1.0e-4 #  1.01943032335002
@test JuMP.value(WiNnat._jump_model[Symbol("Y")][:ott]) ≈ WNDCnat["Y.ott","Countermge"]#  1.02349454873077
@test JuMP.value(WiNnat._jump_model[Symbol("Y")][:che]) ≈ WNDCnat["Y.che","Countermge"]     #atol=1.0e-8 #  1.00544525470182
@test JuMP.value(WiNnat._jump_model[Symbol("Y")][:air]) ≈ WNDCnat["Y.air","Countermge"]  #atol=1.0e-5 #  1.08534791211508
@test JuMP.value(WiNnat._jump_model[Symbol("Y")][:mmf]) ≈ WNDCnat["Y.mmf","Countermge"]  #atol=1.0e-5 #  0.996969585088487
@test JuMP.value(WiNnat._jump_model[Symbol("Y")][:otr]) ≈ WNDCnat["Y.otr","Countermge"]#  1.02245484859239
@test JuMP.value(WiNnat._jump_model[Symbol("Y")][:min]) ≈ WNDCnat["Y.min","Countermge"]  #atol=1.0e-5 #  1.01680420130584
@test JuMP.value(WiNnat._jump_model[Symbol("A")][:ppd]) ≈ WNDCnat["A.ppd","Countermge"]#  1.01598686308657
@test JuMP.value(WiNnat._jump_model[Symbol("A")][:res]) ≈ WNDCnat["A.res","Countermge"]#  1.03671030869442
@test JuMP.value(WiNnat._jump_model[Symbol("A")][:com]) ≈ WNDCnat["A.com","Countermge"]#  1.00094988736871
@test JuMP.value(WiNnat._jump_model[Symbol("A")][:amb]) ≈ WNDCnat["A.amb","Countermge"]#  0.970346024279367
@test JuMP.value(WiNnat._jump_model[Symbol("A")][:fbp]) ≈ WNDCnat["A.fbp","Countermge"]#  1.04186460804857
@test JuMP.value(WiNnat._jump_model[Symbol("A")][:rec]) ≈ WNDCnat["A.rec","Countermge"]#  1.02538056034579
@test JuMP.value(WiNnat._jump_model[Symbol("A")][:con]) ≈ WNDCnat["A.con","Countermge"]#  0.998504509599111
@test JuMP.value(WiNnat._jump_model[Symbol("A")][:agr]) ≈ WNDCnat["A.agr","Countermge"]#  1.02359577080848
@test JuMP.value(WiNnat._jump_model[Symbol("A")][:eec]) ≈ WNDCnat["A.eec","Countermge"]#  1.00721109739291
@test JuMP.value(WiNnat._jump_model[Symbol("A")][:fnd]) ≈ WNDCnat["A.fnd","Countermge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("A")][:pub]) ≈ WNDCnat["A.pub","Countermge"]#  0.995390649098765
@test JuMP.value(WiNnat._jump_model[Symbol("A")][:hou]) ≈ WNDCnat["A.hou","Countermge"]#  0.947340240416864
@test JuMP.value(WiNnat._jump_model[Symbol("A")][:fbt]) ≈ WNDCnat["A.fbt","Countermge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("A")][:ins]) ≈ WNDCnat["A.ins","Countermge"]#  0.995012305070024
@test JuMP.value(WiNnat._jump_model[Symbol("A")][:tex]) ≈ WNDCnat["A.tex","Countermge"]#  1.02455568009021
@test JuMP.value(WiNnat._jump_model[Symbol("A")][:leg]) ≈ WNDCnat["A.leg","Countermge"]#  1.0053916028044
@test JuMP.value(WiNnat._jump_model[Symbol("A")][:fen]) ≈ WNDCnat["A.fen","Countermge"]#  1.00419569566607
@test JuMP.value(WiNnat._jump_model[Symbol("A")][:uti]) ≈ WNDCnat["A.uti","Countermge"]#  1.02048042118959
@test JuMP.value(WiNnat._jump_model[Symbol("A")][:nmp]) ≈ WNDCnat["A.nmp","Countermge"]#  1.0057216161252
@test JuMP.value(WiNnat._jump_model[Symbol("A")][:brd]) ≈ WNDCnat["A.brd","Countermge"]#  1.0231397237401
@test JuMP.value(WiNnat._jump_model[Symbol("A")][:bnk]) ≈ WNDCnat["A.bnk","Countermge"]#  0.982247692163263
@test JuMP.value(WiNnat._jump_model[Symbol("A")][:ore]) ≈ WNDCnat["A.ore","Countermge"]#  1.00425054695281
@test JuMP.value(WiNnat._jump_model[Symbol("A")][:edu]) ≈ WNDCnat["A.edu","Countermge"]#  0.97190425151925
@test JuMP.value(WiNnat._jump_model[Symbol("A")][:ote]) ≈ WNDCnat["A.ote","Countermge"]#  1.00325541716249
@test JuMP.value(WiNnat._jump_model[Symbol("A")][:man]) ≈ WNDCnat["A.man","Countermge"]#  1.0157557775201
@test JuMP.value(WiNnat._jump_model[Symbol("A")][:mch]) ≈ WNDCnat["A.mch","Countermge"]#  1.00647437017813
@test JuMP.value(WiNnat._jump_model[Symbol("A")][:dat]) ≈ WNDCnat["A.dat","Countermge"]#  0.997095137051688
@test JuMP.value(WiNnat._jump_model[Symbol("A")][:amd]) ≈ WNDCnat["A.amd","Countermge"]#  1.04227942698265
@test JuMP.value(WiNnat._jump_model[Symbol("A")][:oil]) ≈ WNDCnat["A.oil","Countermge"]#  1.07357624742805
@test JuMP.value(WiNnat._jump_model[Symbol("A")][:hos]) ≈ WNDCnat["A.hos","Countermge"]#  0.975843411673593
@test JuMP.value(WiNnat._jump_model[Symbol("A")][:rnt]) ≈ WNDCnat["A.rnt","Countermge"]#  1.01298650454753
@test JuMP.value(WiNnat._jump_model[Symbol("A")][:pla]) ≈ WNDCnat["A.pla","Countermge"]#  1.01315757064412
@test JuMP.value(WiNnat._jump_model[Symbol("A")][:fof]) ≈ WNDCnat["A.fof","Countermge"]#  1.0150793421308
@test JuMP.value(WiNnat._jump_model[Symbol("A")][:fin]) ≈ WNDCnat["A.fin","Countermge"]#  0.977232120623297
@test JuMP.value(WiNnat._jump_model[Symbol("A")][:tsv]) ≈ WNDCnat["A.tsv","Countermge"]#  1.00197670869542
@test JuMP.value(WiNnat._jump_model[Symbol("A")][:nrs]) ≈ WNDCnat["A.nrs","Countermge"]#  0.986301952951202
@test JuMP.value(WiNnat._jump_model[Symbol("A")][:sec]) ≈ WNDCnat["A.sec","Countermge"]#  0.981846949135725
@test JuMP.value(WiNnat._jump_model[Symbol("A")][:art]) ≈ WNDCnat["A.art","Countermge"]#  1.00644843651161
@test JuMP.value(WiNnat._jump_model[Symbol("A")][:mov]) ≈ WNDCnat["A.mov","Countermge"]#  1.00730734728963
@test JuMP.value(WiNnat._jump_model[Symbol("A")][:fpd]) ≈ WNDCnat["A.fpd","Countermge"]#  1.01083024525834
@test JuMP.value(WiNnat._jump_model[Symbol("A")][:slg]) ≈ WNDCnat["A.slg","Countermge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("A")][:pri]) ≈ WNDCnat["A.pri","Countermge"]#  1.00264222546002
@test JuMP.value(WiNnat._jump_model[Symbol("A")][:grd]) ≈ WNDCnat["A.grd","Countermge"]#  0.992577811772709
@test JuMP.value(WiNnat._jump_model[Symbol("A")][:pip]) ≈ WNDCnat["A.pip","Countermge"]#  1.06222612169058
@test JuMP.value(WiNnat._jump_model[Symbol("A")][:sle]) ≈ WNDCnat["A.sle","Countermge"]#  0.996996456841127
@test JuMP.value(WiNnat._jump_model[Symbol("A")][:osv]) ≈ WNDCnat["A.osv","Countermge"]#  0.999043118120281
@test JuMP.value(WiNnat._jump_model[Symbol("A")][:trn]) ≈ WNDCnat["A.trn","Countermge"]#  0.986965551382337
@test JuMP.value(WiNnat._jump_model[Symbol("A")][:smn]) ≈ WNDCnat["A.smn","Countermge"]#  1.00731962935406
@test JuMP.value(WiNnat._jump_model[Symbol("A")][:fmt]) ≈ WNDCnat["A.fmt","Countermge"]#  1.00894214241408
@test JuMP.value(WiNnat._jump_model[Symbol("A")][:pet]) ≈ WNDCnat["A.pet","Countermge"]#  1.07877535469425
@test JuMP.value(WiNnat._jump_model[Symbol("A")][:mvt]) ≈ WNDCnat["A.mvt","Countermge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("A")][:cep]) ≈ WNDCnat["A.cep","Countermge"]#  0.998660303572017
@test JuMP.value(WiNnat._jump_model[Symbol("A")][:wst]) ≈ WNDCnat["A.wst","Countermge"]#  1.00298117291499
@test JuMP.value(WiNnat._jump_model[Symbol("A")][:mot]) ≈ WNDCnat["A.mot","Countermge"]#  1.01595926766198
@test JuMP.value(WiNnat._jump_model[Symbol("A")][:adm]) ≈ WNDCnat["A.adm","Countermge"]#  1.00241194482332
@test JuMP.value(WiNnat._jump_model[Symbol("A")][:soc]) ≈ WNDCnat["A.soc","Countermge"]#  0.978118116258101
@test JuMP.value(WiNnat._jump_model[Symbol("A")][:alt]) ≈ WNDCnat["A.alt","Countermge"]#  1.07760725354631
@test JuMP.value(WiNnat._jump_model[Symbol("A")][:pmt]) ≈ WNDCnat["A.pmt","Countermge"]#  1.01403892070354
@test JuMP.value(WiNnat._jump_model[Symbol("A")][:trk]) ≈ WNDCnat["A.trk","Countermge"]#  1.01810679824243
@test JuMP.value(WiNnat._jump_model[Symbol("A")][:fdd]) ≈ WNDCnat["A.fdd","Countermge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("A")][:gmt]) ≈ WNDCnat["A.gmt","Countermge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("A")][:wtt]) ≈ WNDCnat["A.wtt","Countermge"]#  1.00693767941564
@test JuMP.value(WiNnat._jump_model[Symbol("A")][:wpd]) ≈ WNDCnat["A.wpd","Countermge"]#  1.00634650454765
@test JuMP.value(WiNnat._jump_model[Symbol("A")][:wht]) ≈ WNDCnat["A.wht","Countermge"]#  1.01980126761136
@test JuMP.value(WiNnat._jump_model[Symbol("A")][:wrh]) ≈ WNDCnat["A.wrh","Countermge"]#  1.01969958461885
@test JuMP.value(WiNnat._jump_model[Symbol("A")][:ott]) ≈ WNDCnat["A.ott","Countermge"]#  0.98433973173757
@test JuMP.value(WiNnat._jump_model[Symbol("A")][:che]) ≈ WNDCnat["A.che","Countermge"]#  1.00690581565546
@test JuMP.value(WiNnat._jump_model[Symbol("A")][:air]) ≈ WNDCnat["A.air","Countermge"]#  1.0779792107529
@test JuMP.value(WiNnat._jump_model[Symbol("A")][:mmf]) ≈ WNDCnat["A.mmf","Countermge"]#  1.00711561245115
@test JuMP.value(WiNnat._jump_model[Symbol("A")][:otr]) ≈ WNDCnat["A.otr","Countermge"]#  1.02108030242368
@test JuMP.value(WiNnat._jump_model[Symbol("A")][:min]) ≈ WNDCnat["A.min","Countermge"]#  1.01630155662069
@test JuMP.value(WiNnat._jump_model[Symbol("PA[ppd]ρRA")]) ≈ WNDCnat["DPARA.ppd","Countermge"]#  45.0983450258118
@test JuMP.value(WiNnat._jump_model[Symbol("PA[res]ρRA")]) ≈ WNDCnat["DPARA.res","Countermge"]#  774.30644850203
@test JuMP.value(WiNnat._jump_model[Symbol("PA[amb]ρRA")]) ≈ WNDCnat["DPARA.amb","Countermge"]#  1020.04917657084
@test JuMP.value(WiNnat._jump_model[Symbol("PA[fbp]ρRA")]) ≈ WNDCnat["DPARA.fbp","Countermge"]#  1080.86336015448
@test JuMP.value(WiNnat._jump_model[Symbol("PA[rec]ρRA")]) ≈ WNDCnat["DPARA.rec","Countermge"]#  204.125961820132
@test JuMP.value(WiNnat._jump_model[Symbol("PA[agr]ρRA")]) ≈ WNDCnat["DPARA.agr","Countermge"]#  144.627985840036
@test JuMP.value(WiNnat._jump_model[Symbol("PA[eec]ρRA")]) ≈ WNDCnat["DPARA.eec","Countermge"]#  87.2169771491712
@test JuMP.value(WiNnat._jump_model[Symbol("PA[pub]ρRA")]) ≈ WNDCnat["DPARA.pub","Countermge"]#  129.471085383795
@test JuMP.value(WiNnat._jump_model[Symbol("PA[hou]ρRA")]) ≈ WNDCnat["DPARA.hou","Countermge"]#  1927.94383239772
@test JuMP.value(WiNnat._jump_model[Symbol("PA[ins]ρRA")]) ≈ WNDCnat["DPARA.ins","Countermge"]#  383.943789595992
@test JuMP.value(WiNnat._jump_model[Symbol("PA[tex]ρRA")]) ≈ WNDCnat["DPARA.tex","Countermge"]#  75.5437796408227
@test JuMP.value(WiNnat._jump_model[Symbol("PA[leg]ρRA")]) ≈ WNDCnat["DPARA.leg","Countermge"]#  106.266138994311
@test JuMP.value(WiNnat._jump_model[Symbol("PA[fen]ρRA")]) ≈ WNDCnat["DPARA.fen","Countermge"]#  5.97072004230777
@test JuMP.value(WiNnat._jump_model[Symbol("PA[uti]ρRA")]) ≈ WNDCnat["DPARA.uti","Countermge"]#  272.992165442691
@test JuMP.value(WiNnat._jump_model[Symbol("PA[nmp]ρRA")]) ≈ WNDCnat["DPARA.nmp","Countermge"]#  21.0690866095121
@test JuMP.value(WiNnat._jump_model[Symbol("PA[brd]ρRA")]) ≈ WNDCnat["DPARA.brd","Countermge"]#  343.608479971518
@test JuMP.value(WiNnat._jump_model[Symbol("PA[bnk]ρRA")]) ≈ WNDCnat["DPARA.bnk","Countermge"]#  270.463738156423
@test JuMP.value(WiNnat._jump_model[Symbol("PA[ore]ρRA")]) ≈ WNDCnat["DPARA.ore","Countermge"]#  5.53000837942978
@test JuMP.value(WiNnat._jump_model[Symbol("PA[edu]ρRA")]) ≈ WNDCnat["DPARA.edu","Countermge"]#  340.647696780532
@test JuMP.value(WiNnat._jump_model[Symbol("PA[ote]ρRA")]) ≈ WNDCnat["DPARA.ote","Countermge"]#  32.155916106726
@test JuMP.value(WiNnat._jump_model[Symbol("PA[mch]ρRA")]) ≈ WNDCnat["DPARA.mch","Countermge"]#  24.1038938445545
@test JuMP.value(WiNnat._jump_model[Symbol("PA[dat]ρRA")]) ≈ WNDCnat["DPARA.dat","Countermge"]#  54.4633114169796
@test JuMP.value(WiNnat._jump_model[Symbol("PA[amd]ρRA")]) ≈ WNDCnat["DPARA.amd","Countermge"]#  167.153475662182
@test JuMP.value(WiNnat._jump_model[Symbol("PA[hos]ρRA")]) ≈ WNDCnat["DPARA.hos","Countermge"]#  1040.7247049585
@test JuMP.value(WiNnat._jump_model[Symbol("PA[rnt]ρRA")]) ≈ WNDCnat["DPARA.rnt","Countermge"]#  107.152323154972
@test JuMP.value(WiNnat._jump_model[Symbol("PA[pla]ρRA")]) ≈ WNDCnat["DPARA.pla","Countermge"]#  68.1704729408806
@test JuMP.value(WiNnat._jump_model[Symbol("PA[fof]ρRA")]) ≈ WNDCnat["DPARA.fof","Countermge"]#  11.5651242722978
@test JuMP.value(WiNnat._jump_model[Symbol("PA[fin]ρRA")]) ≈ WNDCnat["DPARA.fin","Countermge"]#  158.55105630941
@test JuMP.value(WiNnat._jump_model[Symbol("PA[tsv]ρRA")]) ≈ WNDCnat["DPARA.tsv","Countermge"]#  70.8316547519168
@test JuMP.value(WiNnat._jump_model[Symbol("PA[nrs]ρRA")]) ≈ WNDCnat["DPARA.nrs","Countermge"]#  238.932568746628
@test JuMP.value(WiNnat._jump_model[Symbol("PA[sec]ρRA")]) ≈ WNDCnat["DPARA.sec","Countermge"]#  218.521852430846
@test JuMP.value(WiNnat._jump_model[Symbol("PA[art]ρRA")]) ≈ WNDCnat["DPARA.art","Countermge"]#  78.4055247393738
@test JuMP.value(WiNnat._jump_model[Symbol("PA[mov]ρRA")]) ≈ WNDCnat["DPARA.mov","Countermge"]#  32.4430654023884
@test JuMP.value(WiNnat._jump_model[Symbol("PA[fpd]ρRA")]) ≈ WNDCnat["DPARA.fpd","Countermge"]#  122.363411973318
@test JuMP.value(WiNnat._jump_model[Symbol("PA[pri]ρRA")]) ≈ WNDCnat["DPARA.pri","Countermge"]#  8.37274945985891
@test JuMP.value(WiNnat._jump_model[Symbol("PA[grd]ρRA")]) ≈ WNDCnat["DPARA.grd","Countermge"]#  45.2558721438874
@test JuMP.value(WiNnat._jump_model[Symbol("PA[sle]ρRA")]) ≈ WNDCnat["DPARA.sle","Countermge"]#  70.283657579612
@test JuMP.value(WiNnat._jump_model[Symbol("PA[osv]ρRA")]) ≈ WNDCnat["DPARA.osv","Countermge"]#  612.787024500054
@test JuMP.value(WiNnat._jump_model[Symbol("PA[trn]ρRA")]) ≈ WNDCnat["DPARA.trn","Countermge"]#  1.25120478127489
@test JuMP.value(WiNnat._jump_model[Symbol("PA[fmt]ρRA")]) ≈ WNDCnat["DPARA.fmt","Countermge"]#  40.7255951187371
@test JuMP.value(WiNnat._jump_model[Symbol("PA[pet]ρRA")]) ≈ WNDCnat["DPARA.pet","Countermge"]#  358.729529644352
@test JuMP.value(WiNnat._jump_model[Symbol("PA[cep]ρRA")]) ≈ WNDCnat["DPARA.cep","Countermge"]#  162.838825409896
@test JuMP.value(WiNnat._jump_model[Symbol("PA[wst]ρRA")]) ≈ WNDCnat["DPARA.wst","Countermge"]#  26.8562461473655
@test JuMP.value(WiNnat._jump_model[Symbol("PA[mot]ρRA")]) ≈ WNDCnat["DPARA.mot","Countermge"]#  344.573830948772
@test JuMP.value(WiNnat._jump_model[Symbol("PA[adm]ρRA")]) ≈ WNDCnat["DPARA.adm","Countermge"]#  62.6015621217838
@test JuMP.value(WiNnat._jump_model[Symbol("PA[soc]ρRA")]) ≈ WNDCnat["DPARA.soc","Countermge"]#  205.873629707678
@test JuMP.value(WiNnat._jump_model[Symbol("PA[alt]ρRA")]) ≈ WNDCnat["DPARA.alt","Countermge"]#  432.459984153533
@test JuMP.value(WiNnat._jump_model[Symbol("PA[pmt]ρRA")]) ≈ WNDCnat["DPARA.pmt","Countermge"]#  1.71848845347668
@test JuMP.value(WiNnat._jump_model[Symbol("PA[trk]ρRA")]) ≈ WNDCnat["DPARA.trk","Countermge"]#  12.3653759398715
@test JuMP.value(WiNnat._jump_model[Symbol("PA[wtt]ρRA")]) ≈ WNDCnat["DPARA.wtt","Countermge"]#  21.4157591930215
@test JuMP.value(WiNnat._jump_model[Symbol("PA[wpd]ρRA")]) ≈ WNDCnat["DPARA.wpd","Countermge"]#  7.91823844428873
@test JuMP.value(WiNnat._jump_model[Symbol("PA[wrh]ρRA")]) ≈ WNDCnat["DPARA.wrh","Countermge"]#  0.0854605630590118
@test JuMP.value(WiNnat._jump_model[Symbol("PA[ott]ρRA")]) ≈ WNDCnat["DPARA.ott","Countermge"]#  5.31473768111257
@test JuMP.value(WiNnat._jump_model[Symbol("PA[che]ρRA")]) ≈ WNDCnat["DPARA.che","Countermge"]#  632.508582230469
@test JuMP.value(WiNnat._jump_model[Symbol("PA[air]ρRA")]) ≈ WNDCnat["DPARA.air","Countermge"]#  143.422732837925
@test JuMP.value(WiNnat._jump_model[Symbol("PA[mmf]ρRA")]) ≈ WNDCnat["DPARA.mmf","Countermge"]#  268.65901078116
@test JuMP.value(WiNnat._jump_model[Symbol("PA[otr]ρRA")]) ≈ WNDCnat["DPARA.otr","Countermge"]#  23.0291158739367
@test JuMP.value(WiNnat._jump_model[Symbol("PA[min]ρRA")]) ≈ WNDCnat["DPARA.min","Countermge"]#  0.653932358001658
@test JuMP.value(WiNnat._jump_model[Symbol("PA[ppd]‡A[ppd]")]) ≈ WNDCnat["SPAA.ppd","Countermge"]#  236.988938393355
@test JuMP.value(WiNnat._jump_model[Symbol("PA[res]‡A[res]")]) ≈ WNDCnat["SPAA.res","Countermge"]#  959.304544516456
@test JuMP.value(WiNnat._jump_model[Symbol("PA[com]‡A[com]")]) ≈ WNDCnat["SPAA.com","Countermge"]#  525.364047878254
@test JuMP.value(WiNnat._jump_model[Symbol("PA[amb]‡A[amb]")]) ≈ WNDCnat["SPAA.amb","Countermge"]#  1093.38041860847
@test JuMP.value(WiNnat._jump_model[Symbol("PA[fbp]‡A[fbp]")]) ≈ WNDCnat["SPAA.fbp","Countermge"]#  1515.65653419943
@test JuMP.value(WiNnat._jump_model[Symbol("PA[rec]‡A[rec]")]) ≈ WNDCnat["SPAA.rec","Countermge"]#  204.693237
@test JuMP.value(WiNnat._jump_model[Symbol("PA[con]‡A[con]")]) ≈ WNDCnat["SPAA.con","Countermge"]#  1661.39205237938
@test JuMP.value(WiNnat._jump_model[Symbol("PA[agr]‡A[agr]")]) ≈ WNDCnat["SPAA.agr","Countermge"]#  516.056457439951
@test JuMP.value(WiNnat._jump_model[Symbol("PA[eec]‡A[eec]")]) ≈ WNDCnat["SPAA.eec","Countermge"]#  298.232417532365
@test JuMP.value(WiNnat._jump_model[Symbol("PA[fnd]‡A[fnd]")]) ≈ WNDCnat["SPAA.fnd","Countermge"]#  380.898129
@test JuMP.value(WiNnat._jump_model[Symbol("PA[pub]‡A[pub]")]) ≈ WNDCnat["SPAA.pub","Countermge"]#  348.824378750271
@test JuMP.value(WiNnat._jump_model[Symbol("PA[hou]‡A[hou]")]) ≈ WNDCnat["SPAA.hou","Countermge"]#  2035.11236
@test JuMP.value(WiNnat._jump_model[Symbol("PA[ins]‡A[ins]")]) ≈ WNDCnat["SPAA.ins","Countermge"]#  1174.52373324662
@test JuMP.value(WiNnat._jump_model[Symbol("PA[tex]‡A[tex]")]) ≈ WNDCnat["SPAA.tex","Countermge"]#  145.347236767545
@test JuMP.value(WiNnat._jump_model[Symbol("PA[leg]‡A[leg]")]) ≈ WNDCnat["SPAA.leg","Countermge"]#  348.469159371955
@test JuMP.value(WiNnat._jump_model[Symbol("PA[fen]‡A[fen]")]) ≈ WNDCnat["SPAA.fen","Countermge"]#  70.4845665297578
@test JuMP.value(WiNnat._jump_model[Symbol("PA[uti]‡A[uti]")]) ≈ WNDCnat["SPAA.uti","Countermge"]#  652.03285818802
@test JuMP.value(WiNnat._jump_model[Symbol("PA[nmp]‡A[nmp]")]) ≈ WNDCnat["SPAA.nmp","Countermge"]#  214.116328876329
@test JuMP.value(WiNnat._jump_model[Symbol("PA[brd]‡A[brd]")]) ≈ WNDCnat["SPAA.brd","Countermge"]#  706.802123628329
@test JuMP.value(WiNnat._jump_model[Symbol("PA[bnk]‡A[bnk]")]) ≈ WNDCnat["SPAA.bnk","Countermge"]#  792.554975640748
@test JuMP.value(WiNnat._jump_model[Symbol("PA[ore]‡A[ore]")]) ≈ WNDCnat["SPAA.ore","Countermge"]#  1255.20269149723
@test JuMP.value(WiNnat._jump_model[Symbol("PA[edu]‡A[edu]")]) ≈ WNDCnat["SPAA.edu","Countermge"]#  392.715902817812
@test JuMP.value(WiNnat._jump_model[Symbol("PA[ote]‡A[ote]")]) ≈ WNDCnat["SPAA.ote","Countermge"]#  276.943867862988
@test JuMP.value(WiNnat._jump_model[Symbol("PA[man]‡A[man]")]) ≈ WNDCnat["SPAA.man","Countermge"]#  579.527335362865
@test JuMP.value(WiNnat._jump_model[Symbol("PA[mch]‡A[mch]")]) ≈ WNDCnat["SPAA.mch","Countermge"]#  586.917497613094
@test JuMP.value(WiNnat._jump_model[Symbol("PA[dat]‡A[dat]")]) ≈ WNDCnat["SPAA.dat","Countermge"]#  245.620113987753
@test JuMP.value(WiNnat._jump_model[Symbol("PA[amd]‡A[amd]")]) ≈ WNDCnat["SPAA.amd","Countermge"]#  229.587824
@test JuMP.value(WiNnat._jump_model[Symbol("PA[oil]‡A[oil]")]) ≈ WNDCnat["SPAA.oil","Countermge"]#  411.265605375987
@test JuMP.value(WiNnat._jump_model[Symbol("PA[hos]‡A[hos]")]) ≈ WNDCnat["SPAA.hos","Countermge"]#  1073.11067297167
@test JuMP.value(WiNnat._jump_model[Symbol("PA[rnt]‡A[rnt]")]) ≈ WNDCnat["SPAA.rnt","Countermge"]#  368.095713098834
@test JuMP.value(WiNnat._jump_model[Symbol("PA[pla]‡A[pla]")]) ≈ WNDCnat["SPAA.pla","Countermge"]#  362.202794356016
@test JuMP.value(WiNnat._jump_model[Symbol("PA[fof]‡A[fof]")]) ≈ WNDCnat["SPAA.fof","Countermge"]#  92.1024335819389
@test JuMP.value(WiNnat._jump_model[Symbol("PA[fin]‡A[fin]")]) ≈ WNDCnat["SPAA.fin","Countermge"]#  183.495134
@test JuMP.value(WiNnat._jump_model[Symbol("PA[tsv]‡A[tsv]")]) ≈ WNDCnat["SPAA.tsv","Countermge"]#  1988.87361079195
@test JuMP.value(WiNnat._jump_model[Symbol("PA[nrs]‡A[nrs]")]) ≈ WNDCnat["SPAA.nrs","Countermge"]#  245.658333
@test JuMP.value(WiNnat._jump_model[Symbol("PA[sec]‡A[sec]")]) ≈ WNDCnat["SPAA.sec","Countermge"]#  514.086810307178
@test JuMP.value(WiNnat._jump_model[Symbol("PA[art]‡A[art]")]) ≈ WNDCnat["SPAA.art","Countermge"]#  174.632096282488
@test JuMP.value(WiNnat._jump_model[Symbol("PA[mov]‡A[mov]")]) ≈ WNDCnat["SPAA.mov","Countermge"]#  146.421796945177
@test JuMP.value(WiNnat._jump_model[Symbol("PA[fpd]‡A[fpd]")]) ≈ WNDCnat["SPAA.fpd","Countermge"]#  221.263642518005
@test JuMP.value(WiNnat._jump_model[Symbol("PA[slg]‡A[slg]")]) ≈ WNDCnat["SPAA.slg","Countermge"]#  1744.23136
@test JuMP.value(WiNnat._jump_model[Symbol("PA[pri]‡A[pri]")]) ≈ WNDCnat["SPAA.pri","Countermge"]#  89.2774959690228
@test JuMP.value(WiNnat._jump_model[Symbol("PA[grd]‡A[grd]")]) ≈ WNDCnat["SPAA.grd","Countermge"]#  93.1481825
@test JuMP.value(WiNnat._jump_model[Symbol("PA[pip]‡A[pip]")]) ≈ WNDCnat["SPAA.pip","Countermge"]#  0.379117207466209
@test JuMP.value(WiNnat._jump_model[Symbol("PA[sle]‡A[sle]")]) ≈ WNDCnat["SPAA.sle","Countermge"]#  104.176032
@test JuMP.value(WiNnat._jump_model[Symbol("PA[osv]‡A[osv]")]) ≈ WNDCnat["SPAA.osv","Countermge"]#  868.463128476593
@test JuMP.value(WiNnat._jump_model[Symbol("PA[trn]‡A[trn]")]) ≈ WNDCnat["SPAA.trn","Countermge"]#  7.9177444003776
@test JuMP.value(WiNnat._jump_model[Symbol("PA[smn]‡A[smn]")]) ≈ WNDCnat["SPAA.smn","Countermge"]#  124.248422623903
@test JuMP.value(WiNnat._jump_model[Symbol("PA[fmt]‡A[fmt]")]) ≈ WNDCnat["SPAA.fmt","Countermge"]#  477.087153193648
@test JuMP.value(WiNnat._jump_model[Symbol("PA[pet]‡A[pet]")]) ≈ WNDCnat["SPAA.pet","Countermge"]#  753.406521409953
@test JuMP.value(WiNnat._jump_model[Symbol("PA[cep]‡A[cep]")]) ≈ WNDCnat["SPAA.cep","Countermge"]#  754.550491682529
@test JuMP.value(WiNnat._jump_model[Symbol("PA[wst]‡A[wst]")]) ≈ WNDCnat["SPAA.wst","Countermge"]#  117.575866726324
@test JuMP.value(WiNnat._jump_model[Symbol("PA[mot]‡A[mot]")]) ≈ WNDCnat["SPAA.mot","Countermge"]#  1115.45451278408
@test JuMP.value(WiNnat._jump_model[Symbol("PA[adm]‡A[adm]")]) ≈ WNDCnat["SPAA.adm","Countermge"]#  929.230785877763
@test JuMP.value(WiNnat._jump_model[Symbol("PA[soc]‡A[soc]")]) ≈ WNDCnat["SPAA.soc","Countermge"]#  211.263869
@test JuMP.value(WiNnat._jump_model[Symbol("PA[alt]‡A[alt]")]) ≈ WNDCnat["SPAA.alt","Countermge"]#  428.629726604932
@test JuMP.value(WiNnat._jump_model[Symbol("PA[pmt]‡A[pmt]")]) ≈ WNDCnat["SPAA.pmt","Countermge"]#  306.431094109142
@test JuMP.value(WiNnat._jump_model[Symbol("PA[trk]‡A[trk]")]) ≈ WNDCnat["SPAA.trk","Countermge"]#  37.6284978938027
@test JuMP.value(WiNnat._jump_model[Symbol("PA[fdd]‡A[fdd]")]) ≈ WNDCnat["SPAA.fdd","Countermge"]#  598.321003
@test JuMP.value(WiNnat._jump_model[Symbol("PA[wtt]‡A[wtt]")]) ≈ WNDCnat["SPAA.wtt","Countermge"]#  24.6916474208002
@test JuMP.value(WiNnat._jump_model[Symbol("PA[wpd]‡A[wpd]")]) ≈ WNDCnat["SPAA.wpd","Countermge"]#  169.415697653342
@test JuMP.value(WiNnat._jump_model[Symbol("PA[wht]‡A[wht]")]) ≈ WNDCnat["SPAA.wht","Countermge"]#  101.037762899492
@test JuMP.value(WiNnat._jump_model[Symbol("PA[wrh]‡A[wrh]")]) ≈ WNDCnat["SPAA.wrh","Countermge"]#  141.954773608058
@test JuMP.value(WiNnat._jump_model[Symbol("PA[ott]‡A[ott]")]) ≈ WNDCnat["SPAA.ott","Countermge"]#  7.216437
@test JuMP.value(WiNnat._jump_model[Symbol("PA[che]‡A[che]")]) ≈ WNDCnat["SPAA.che","Countermge"]#  1315.11234144772
@test JuMP.value(WiNnat._jump_model[Symbol("PA[air]‡A[air]")]) ≈ WNDCnat["SPAA.air","Countermge"]#  206.669586610514
@test JuMP.value(WiNnat._jump_model[Symbol("PA[mmf]‡A[mmf]")]) ≈ WNDCnat["SPAA.mmf","Countermge"]#  432.7463596551
@test JuMP.value(WiNnat._jump_model[Symbol("PA[otr]‡A[otr]")]) ≈ WNDCnat["SPAA.otr","Countermge"]#  234.219103766939
@test JuMP.value(WiNnat._jump_model[Symbol("PA[min]‡A[min]")]) ≈ WNDCnat["SPAA.min","Countermge"]#  110.649058719086
@test JuMP.value(WiNnat._jump_model[Symbol("PY[ppd]†A→dmppd")]) ≈ WNDCnat["DPYA.ppd","Countermge"]#  178.302361762145
@test JuMP.value(WiNnat._jump_model[Symbol("PY[res]†A→dmres")]) ≈ WNDCnat["DPYA.res","Countermge"]#  899.582049
@test JuMP.value(WiNnat._jump_model[Symbol("PY[com]†A→dmcom")]) ≈ WNDCnat["DPYA.com","Countermge"]#  516.669955819314
@test JuMP.value(WiNnat._jump_model[Symbol("PY[amb]†A→dmamb")]) ≈ WNDCnat["DPYA.amb","Countermge"]#  1092.93382
@test JuMP.value(WiNnat._jump_model[Symbol("PY[fbp]†A→dmfbp")]) ≈ WNDCnat["DPYA.fbp","Countermge"]#  931.487295227378
@test JuMP.value(WiNnat._jump_model[Symbol("PY[rec]†A→dmrec")]) ≈ WNDCnat["DPYA.rec","Countermge"]#  195.091973
@test JuMP.value(WiNnat._jump_model[Symbol("PY[con]†A→dmcon")]) ≈ WNDCnat["DPYA.con","Countermge"]#  1659.55143
@test JuMP.value(WiNnat._jump_model[Symbol("PY[agr]†A→dmagr")]) ≈ WNDCnat["DPYA.agr","Countermge"]#  397.159192634641
@test JuMP.value(WiNnat._jump_model[Symbol("PY[eec]†A→dmeec")]) ≈ WNDCnat["DPYA.eec","Countermge"]#  116.334102941302
@test JuMP.value(WiNnat._jump_model[Symbol("PY[fnd]†A→dmfnd")]) ≈ WNDCnat["DPYA.fnd","Countermge"]#  380.898129
@test JuMP.value(WiNnat._jump_model[Symbol("PY[pub]†A→dmpub")]) ≈ WNDCnat["DPYA.pub","Countermge"]#  279.10604025972
@test JuMP.value(WiNnat._jump_model[Symbol("PY[hou]†A→dmhou")]) ≈ WNDCnat["DPYA.hou","Countermge"]#  2073.31916
@test JuMP.value(WiNnat._jump_model[Symbol("PY[ins]†A→dmins")]) ≈ WNDCnat["DPYA.ins","Countermge"]#  1122.67044865478
@test JuMP.value(WiNnat._jump_model[Symbol("PY[tex]†A→dmtex")]) ≈ WNDCnat["DPYA.tex","Countermge"]#  44.7173450880499
@test JuMP.value(WiNnat._jump_model[Symbol("PY[leg]†A→dmleg")]) ≈ WNDCnat["DPYA.leg","Countermge"]#  342.950931606667
@test JuMP.value(WiNnat._jump_model[Symbol("PY[fen]†A→dmfen")]) ≈ WNDCnat["DPYA.fen","Countermge"]#  70.8982368935855
@test JuMP.value(WiNnat._jump_model[Symbol("PY[uti]†A→dmuti")]) ≈ WNDCnat["DPYA.uti","Countermge"]#  624.245619014942
@test JuMP.value(WiNnat._jump_model[Symbol("PY[nmp]†A→dmnmp")]) ≈ WNDCnat["DPYA.nmp","Countermge"]#  122.647906087377
@test JuMP.value(WiNnat._jump_model[Symbol("PY[brd]†A→dmbrd")]) ≈ WNDCnat["DPYA.brd","Countermge"]#  683.422688863694
@test JuMP.value(WiNnat._jump_model[Symbol("PY[bnk]†A→dmbnk")]) ≈ WNDCnat["DPYA.bnk","Countermge"]#  852.551655382011
@test JuMP.value(WiNnat._jump_model[Symbol("PY[ore]†A→dmore")]) ≈ WNDCnat["DPYA.ore","Countermge"]#  1259.29276
@test JuMP.value(WiNnat._jump_model[Symbol("PY[edu]†A→dmedu")]) ≈ WNDCnat["DPYA.edu","Countermge"]#  393.244804987551
@test JuMP.value(WiNnat._jump_model[Symbol("PY[ote]†A→dmote")]) ≈ WNDCnat["DPYA.ote","Countermge"]#  317.698887736103
@test JuMP.value(WiNnat._jump_model[Symbol("PY[man]†A→dmman")]) ≈ WNDCnat["DPYA.man","Countermge"]#  582.277441
@test JuMP.value(WiNnat._jump_model[Symbol("PY[mch]†A→dmmch")]) ≈ WNDCnat["DPYA.mch","Countermge"]#  351.025893693393
@test JuMP.value(WiNnat._jump_model[Symbol("PY[dat]†A→dmdat")]) ≈ WNDCnat["DPYA.dat","Countermge"]#  249.640344193458
@test JuMP.value(WiNnat._jump_model[Symbol("PY[amd]†A→dmamd")]) ≈ WNDCnat["DPYA.amd","Countermge"]#  211.274527
@test JuMP.value(WiNnat._jump_model[Symbol("PY[oil]†A→dmoil")]) ≈ WNDCnat["DPYA.oil","Countermge"]#  232.433992418968
@test JuMP.value(WiNnat._jump_model[Symbol("PY[hos]†A→dmhos")]) ≈ WNDCnat["DPYA.hos","Countermge"]#  1069.66225689397
@test JuMP.value(WiNnat._jump_model[Symbol("PY[rnt]†A→dmrnt")]) ≈ WNDCnat["DPYA.rnt","Countermge"]#  433.205937
@test JuMP.value(WiNnat._jump_model[Symbol("PY[pla]†A→dmpla")]) ≈ WNDCnat["DPYA.pla","Countermge"]#  229.76217795404
@test JuMP.value(WiNnat._jump_model[Symbol("PY[fof]†A→dmfof")]) ≈ WNDCnat["DPYA.fof","Countermge"]#  65.7668539641593
@test JuMP.value(WiNnat._jump_model[Symbol("PY[fin]†A→dmfin")]) ≈ WNDCnat["DPYA.fin","Countermge"]#  183.457238
@test JuMP.value(WiNnat._jump_model[Symbol("PY[tsv]†A→dmtsv")]) ≈ WNDCnat["DPYA.tsv","Countermge"]#  2035.48578452599
@test JuMP.value(WiNnat._jump_model[Symbol("PY[nrs]†A→dmnrs")]) ≈ WNDCnat["DPYA.nrs","Countermge"]#  242.743749
@test JuMP.value(WiNnat._jump_model[Symbol("PY[sec]†A→dmsec")]) ≈ WNDCnat["DPYA.sec","Countermge"]#  584.314802811685
@test JuMP.value(WiNnat._jump_model[Symbol("PY[art]†A→dmart")]) ≈ WNDCnat["DPYA.art","Countermge"]#  169.255170120476
@test JuMP.value(WiNnat._jump_model[Symbol("PY[mov]†A→dmmov")]) ≈ WNDCnat["DPYA.mov","Countermge"]#  145.11676859954
@test JuMP.value(WiNnat._jump_model[Symbol("PY[fpd]†A→dmfpd")]) ≈ WNDCnat["DPYA.fpd","Countermge"]#  72.1173745812346
@test JuMP.value(WiNnat._jump_model[Symbol("PY[slg]†A→dmslg")]) ≈ WNDCnat["DPYA.slg","Countermge"]#  1744.23136
@test JuMP.value(WiNnat._jump_model[Symbol("PY[pri]†A→dmpri")]) ≈ WNDCnat["DPYA.pri","Countermge"]#  71.1597078701849
@test JuMP.value(WiNnat._jump_model[Symbol("PY[grd]†A→dmgrd")]) ≈ WNDCnat["DPYA.grd","Countermge"]#  92.1405807
@test JuMP.value(WiNnat._jump_model[Symbol("PY[pip]†A→dmpip")]) ≈ WNDCnat["DPYA.pip","Countermge"]#  0.551520281
@test JuMP.value(WiNnat._jump_model[Symbol("PY[sle]†A→dmsle")]) ≈ WNDCnat["DPYA.sle","Countermge"]#  104.176032
@test JuMP.value(WiNnat._jump_model[Symbol("PY[osv]†A→dmosv")]) ≈ WNDCnat["DPYA.osv","Countermge"]#  843.624530878845
@test JuMP.value(WiNnat._jump_model[Symbol("PY[trn]†A→dmtrn")]) ≈ WNDCnat["DPYA.trn","Countermge"]#  10.818151
@test JuMP.value(WiNnat._jump_model[Symbol("PY[smn]†A→dmsmn")]) ≈ WNDCnat["DPYA.smn","Countermge"]#  126.304327893962
@test JuMP.value(WiNnat._jump_model[Symbol("PY[fmt]†A→dmfmt")]) ≈ WNDCnat["DPYA.fmt","Countermge"]#  326.869823793069
@test JuMP.value(WiNnat._jump_model[Symbol("PY[pet]†A→dmpet")]) ≈ WNDCnat["DPYA.pet","Countermge"]#  530.474799018386
@test JuMP.value(WiNnat._jump_model[Symbol("PY[cep]†A→dmcep")]) ≈ WNDCnat["DPYA.cep","Countermge"]#  294.430494107922
@test JuMP.value(WiNnat._jump_model[Symbol("PY[wst]†A→dmwst")]) ≈ WNDCnat["DPYA.wst","Countermge"]#  115.756794370096
@test JuMP.value(WiNnat._jump_model[Symbol("PY[mot]†A→dmmot")]) ≈ WNDCnat["DPYA.mot","Countermge"]#  662.904680000772
@test JuMP.value(WiNnat._jump_model[Symbol("PY[adm]†A→dmadm")]) ≈ WNDCnat["DPYA.adm","Countermge"]#  923.384581727345
@test JuMP.value(WiNnat._jump_model[Symbol("PY[soc]†A→dmsoc")]) ≈ WNDCnat["DPYA.soc","Countermge"]#  210.448152
@test JuMP.value(WiNnat._jump_model[Symbol("PY[alt]†A→dmalt")]) ≈ WNDCnat["DPYA.alt","Countermge"]#  15.145671960047
@test JuMP.value(WiNnat._jump_model[Symbol("PY[pmt]†A→dmpmt")]) ≈ WNDCnat["DPYA.pmt","Countermge"]#  209.39716483577
@test JuMP.value(WiNnat._jump_model[Symbol("PY[trk]†A→dmtrk")]) ≈ WNDCnat["DPYA.trk","Countermge"]#  38.934866
@test JuMP.value(WiNnat._jump_model[Symbol("PY[fdd]†A→dmfdd")]) ≈ WNDCnat["DPYA.fdd","Countermge"]#  598.321003
@test JuMP.value(WiNnat._jump_model[Symbol("PY[wtt]†A→dmwtt")]) ≈ WNDCnat["DPYA.wtt","Countermge"]#  29.5450418
@test JuMP.value(WiNnat._jump_model[Symbol("PY[wpd]†A→dmwpd")]) ≈ WNDCnat["DPYA.wpd","Countermge"]#  110.785996753944
@test JuMP.value(WiNnat._jump_model[Symbol("PY[wht]†A→dmwht")]) ≈ WNDCnat["DPYA.wht","Countermge"]#  103.418245
@test JuMP.value(WiNnat._jump_model[Symbol("PY[wrh]†A→dmwrh")]) ≈ WNDCnat["DPYA.wrh","Countermge"]#  141.952358
@test JuMP.value(WiNnat._jump_model[Symbol("PY[ott]†A→dmott")]) ≈ WNDCnat["DPYA.ott","Countermge"]#  7.216437
@test JuMP.value(WiNnat._jump_model[Symbol("PY[che]†A→dmche")]) ≈ WNDCnat["DPYA.che","Countermge"]#  749.112013186912
@test JuMP.value(WiNnat._jump_model[Symbol("PY[air]†A→dmair")]) ≈ WNDCnat["DPYA.air","Countermge"]#  191.390664071866
@test JuMP.value(WiNnat._jump_model[Symbol("PY[mmf]†A→dmmmf")]) ≈ WNDCnat["DPYA.mmf","Countermge"]#  144.470044937235
@test JuMP.value(WiNnat._jump_model[Symbol("PY[otr]†A→dmotr")]) ≈ WNDCnat["DPYA.otr","Countermge"]#  244.240036073202
@test JuMP.value(WiNnat._jump_model[Symbol("PY[min]†A→dmmin")]) ≈ WNDCnat["DPYA.min","Countermge"]#  83.8341797595734
@test JuMP.value(WiNnat._jump_model[Symbol("PM[trn]‡MS[trn]")]) ≈ WNDCnat["SPMMS.trn","Countermge"]#  441.38467
@test JuMP.value(WiNnat._jump_model[Symbol("PM[trd]‡MS[trd]")]) ≈ WNDCnat["SPMMS.trd","Countermge"]#  2963.50744
@test JuMP.value(WiNnat._jump_model[Symbol("MS")][:trn]) ≈ WNDCnat["MS.trn","Countermge"]#  1.0274842107524
@test JuMP.value(WiNnat._jump_model[Symbol("MS")][:trd]) ≈ WNDCnat["MS.trd","Countermge"]#  1.0227852178378
@test JuMP.value(WiNnat._jump_model[Symbol("PA")][:ppd]) ≈ WNDCnat["PA.ppd","Countermge"]#  0.945634369221923
@test JuMP.value(WiNnat._jump_model[Symbol("PA")][:res]) ≈ WNDCnat["PA.res","Countermge"]#  0.905438678778641
@test JuMP.value(WiNnat._jump_model[Symbol("PA")][:com]) ≈ WNDCnat["PA.com","Countermge"]#  0.974365685151435
@test JuMP.value(WiNnat._jump_model[Symbol("PA")][:amb]) ≈ WNDCnat["PA.amb","Countermge"]#  0.977095849796917
@test JuMP.value(WiNnat._jump_model[Symbol("PA")][:fbp]) ≈ WNDCnat["PA.fbp","Countermge"]#  0.905582265791183
@test JuMP.value(WiNnat._jump_model[Symbol("PA")][:rec]) ≈ WNDCnat["PA.rec","Countermge"]#  0.923949511926179
@test JuMP.value(WiNnat._jump_model[Symbol("PA")][:con]) ≈ WNDCnat["PA.con","Countermge"]#  0.961935259230885
@test JuMP.value(WiNnat._jump_model[Symbol("PA")][:agr]) ≈ WNDCnat["PA.agr","Countermge"]#  0.969062010446656
@test JuMP.value(WiNnat._jump_model[Symbol("PA")][:eec]) ≈ WNDCnat["PA.eec","Countermge"]#  0.937841431938745
@test JuMP.value(WiNnat._jump_model[Symbol("PA")][:fnd]) ≈ WNDCnat["PA.fnd","Countermge"]#  0.980078177983152
@test JuMP.value(WiNnat._jump_model[Symbol("PA")][:pub]) ≈ WNDCnat["PA.pub","Countermge"]#  0.955834186217905
@test JuMP.value(WiNnat._jump_model[Symbol("PA")][:hou]) ≈ WNDCnat["PA.hou","Countermge"]#  1.0005642221854
@test JuMP.value(WiNnat._jump_model[Symbol("PA")][:fbt]) ≈ WNDCnat["PA.fbt","Countermge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("PA")][:ins]) ≈ WNDCnat["PA.ins","Countermge"]#  0.955382349850157
@test JuMP.value(WiNnat._jump_model[Symbol("PA")][:tex]) ≈ WNDCnat["PA.tex","Countermge"]#  0.912723734471556
@test JuMP.value(WiNnat._jump_model[Symbol("PA")][:leg]) ≈ WNDCnat["PA.leg","Countermge"]#  0.935148987460656
@test JuMP.value(WiNnat._jump_model[Symbol("PA")][:fen]) ≈ WNDCnat["PA.fen","Countermge"]#  0.97748696184398
@test JuMP.value(WiNnat._jump_model[Symbol("PA")][:uti]) ≈ WNDCnat["PA.uti","Countermge"]#  0.919268682856152
@test JuMP.value(WiNnat._jump_model[Symbol("PA")][:nmp]) ≈ WNDCnat["PA.nmp","Countermge"]#  0.939368148193974
@test JuMP.value(WiNnat._jump_model[Symbol("PA")][:brd]) ≈ WNDCnat["PA.brd","Countermge"]#  0.912847599104492
@test JuMP.value(WiNnat._jump_model[Symbol("PA")][:bnk]) ≈ WNDCnat["PA.bnk","Countermge"]#  0.979008388674344
@test JuMP.value(WiNnat._jump_model[Symbol("PA")][:ore]) ≈ WNDCnat["PA.ore","Countermge"]#  0.965133801325786
@test JuMP.value(WiNnat._jump_model[Symbol("PA")][:edu]) ≈ WNDCnat["PA.edu","Countermge"]#  0.978610359392943
@test JuMP.value(WiNnat._jump_model[Symbol("PA")][:ote]) ≈ WNDCnat["PA.ote","Countermge"]#  0.961441908081136
@test JuMP.value(WiNnat._jump_model[Symbol("PA")][:man]) ≈ WNDCnat["PA.man","Countermge"]#  0.975562160138965
@test JuMP.value(WiNnat._jump_model[Symbol("PA")][:mch]) ≈ WNDCnat["PA.mch","Countermge"]#  0.947639065226955
@test JuMP.value(WiNnat._jump_model[Symbol("PA")][:dat]) ≈ WNDCnat["PA.dat","Countermge"]#  0.967952547107727
@test JuMP.value(WiNnat._jump_model[Symbol("PA")][:amd]) ≈ WNDCnat["PA.amd","Countermge"]#  0.892822538012179
@test JuMP.value(WiNnat._jump_model[Symbol("PA")][:oil]) ≈ WNDCnat["PA.oil","Countermge"]#  0.944983671747272
@test JuMP.value(WiNnat._jump_model[Symbol("PA")][:hos]) ≈ WNDCnat["PA.hos","Countermge"]#  0.971305932599545
@test JuMP.value(WiNnat._jump_model[Symbol("PA")][:rnt]) ≈ WNDCnat["PA.rnt","Countermge"]#  0.932068283248755
@test JuMP.value(WiNnat._jump_model[Symbol("PA")][:pla]) ≈ WNDCnat["PA.pla","Countermge"]#  0.936752320181424
@test JuMP.value(WiNnat._jump_model[Symbol("PA")][:fof]) ≈ WNDCnat["PA.fof","Countermge"]#  0.966165219811593
@test JuMP.value(WiNnat._jump_model[Symbol("PA")][:fin]) ≈ WNDCnat["PA.fin","Countermge"]#  0.970513739104977
@test JuMP.value(WiNnat._jump_model[Symbol("PA")][:tsv]) ≈ WNDCnat["PA.tsv","Countermge"]#  0.974258324432599
@test JuMP.value(WiNnat._jump_model[Symbol("PA")][:nrs]) ≈ WNDCnat["PA.nrs","Countermge"]#  0.961224273470257
@test JuMP.value(WiNnat._jump_model[Symbol("PA")][:sec]) ≈ WNDCnat["PA.sec","Countermge"]#  0.973613672259928
@test JuMP.value(WiNnat._jump_model[Symbol("PA")][:art]) ≈ WNDCnat["PA.art","Countermge"]#  0.945780771735518
@test JuMP.value(WiNnat._jump_model[Symbol("PA")][:mov]) ≈ WNDCnat["PA.mov","Countermge"]#  0.950536519538076
@test JuMP.value(WiNnat._jump_model[Symbol("PA")][:fpd]) ≈ WNDCnat["PA.fpd","Countermge"]#  0.926863031324691
@test JuMP.value(WiNnat._jump_model[Symbol("PA")][:slg]) ≈ WNDCnat["PA.slg","Countermge"]#  0.971202575845032
@test JuMP.value(WiNnat._jump_model[Symbol("PA")][:pri]) ≈ WNDCnat["PA.pri","Countermge"]#  0.953322691791067
@test JuMP.value(WiNnat._jump_model[Symbol("PA")][:grd]) ≈ WNDCnat["PA.grd","Countermge"]#  0.961184232055451
@test JuMP.value(WiNnat._jump_model[Symbol("PA")][:pip]) ≈ WNDCnat["PA.pip","Countermge"]#  0.779861393418628
@test JuMP.value(WiNnat._jump_model[Symbol("PA")][:sle]) ≈ WNDCnat["PA.sle","Countermge"]#  0.955519878838054
@test JuMP.value(WiNnat._jump_model[Symbol("PA")][:osv]) ≈ WNDCnat["PA.osv","Countermge"]#  0.951762529497917
@test JuMP.value(WiNnat._jump_model[Symbol("PA")][:trn]) ≈ WNDCnat["PA.trn","Countermge"]#  1.1424298822833
@test JuMP.value(WiNnat._jump_model[Symbol("PA")][:smn]) ≈ WNDCnat["PA.smn","Countermge"]#  0.966755543366378
@test JuMP.value(WiNnat._jump_model[Symbol("PA")][:fmt]) ≈ WNDCnat["PA.fmt","Countermge"]#  0.947009244551105
@test JuMP.value(WiNnat._jump_model[Symbol("PA")][:pet]) ≈ WNDCnat["PA.pet","Countermge"]#  0.820924987727197
@test JuMP.value(WiNnat._jump_model[Symbol("PA")][:mvt]) ≈ WNDCnat["PA.mvt","Countermge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("PA")][:cep]) ≈ WNDCnat["PA.cep","Countermge"]#  0.957657289208879
@test JuMP.value(WiNnat._jump_model[Symbol("PA")][:wst]) ≈ WNDCnat["PA.wst","Countermge"]#  0.954004512414617
@test JuMP.value(WiNnat._jump_model[Symbol("PA")][:mot]) ≈ WNDCnat["PA.mot","Countermge"]#  0.929958821668799
@test JuMP.value(WiNnat._jump_model[Symbol("PA")][:adm]) ≈ WNDCnat["PA.adm","Countermge"]#  0.967722383012059
@test JuMP.value(WiNnat._jump_model[Symbol("PA")][:soc]) ≈ WNDCnat["PA.soc","Countermge"]#  0.969159093871482
@test JuMP.value(WiNnat._jump_model[Symbol("PA")][:alt]) ≈ WNDCnat["PA.alt","Countermge"]#  0.87606610546441
@test JuMP.value(WiNnat._jump_model[Symbol("PA")][:pmt]) ≈ WNDCnat["PA.pmt","Countermge"]#  0.95970014637895
@test JuMP.value(WiNnat._jump_model[Symbol("PA")][:trk]) ≈ WNDCnat["PA.trk","Countermge"]#  0.942049354860982
@test JuMP.value(WiNnat._jump_model[Symbol("PA")][:fdd]) ≈ WNDCnat["PA.fdd","Countermge"]#  0.975397084495546
@test JuMP.value(WiNnat._jump_model[Symbol("PA")][:gmt]) ≈ WNDCnat["PA.gmt","Countermge"]#  1
@test JuMP.value(WiNnat._jump_model[Symbol("PA")][:wtt]) ≈ WNDCnat["PA.wtt","Countermge"]#  0.947499646789479
@test JuMP.value(WiNnat._jump_model[Symbol("PA")][:wpd]) ≈ WNDCnat["PA.wpd","Countermge"]#  0.944991672182799
@test JuMP.value(WiNnat._jump_model[Symbol("PA")][:wht]) ≈ WNDCnat["PA.wht","Countermge"]#  0.975014893609673
@test JuMP.value(WiNnat._jump_model[Symbol("PA")][:wrh]) ≈ WNDCnat["PA.wrh","Countermge"]#  0.968571172807743
@test JuMP.value(WiNnat._jump_model[Symbol("PA")][:ott]) ≈ WNDCnat["PA.ott","Countermge"]#  0.975257967255208
@test JuMP.value(WiNnat._jump_model[Symbol("PA")][:che]) ≈ WNDCnat["PA.che","Countermge"]#  0.94464432024234
@test JuMP.value(WiNnat._jump_model[Symbol("PA")][:air]) ≈ WNDCnat["PA.air","Countermge"]#  0.85437139250456
@test JuMP.value(WiNnat._jump_model[Symbol("PA")][:mmf]) ≈ WNDCnat["PA.mmf","Countermge"]#  0.933637758695232
@test JuMP.value(WiNnat._jump_model[Symbol("PA")][:otr]) ≈ WNDCnat["PA.otr","Countermge"]#  0.960960790713352
@test JuMP.value(WiNnat._jump_model[Symbol("PA")][:min]) ≈ WNDCnat["PA.min","Countermge"]#  0.933400104861808
@test JuMP.value(WiNnat._jump_model[Symbol("PY")][:ppd]) ≈ WNDCnat["PY.ppd","Countermge"]#  0.957868287320578
@test JuMP.value(WiNnat._jump_model[Symbol("PY")][:res]) ≈ WNDCnat["PY.res","Countermge"]#  0.968514037688796
@test JuMP.value(WiNnat._jump_model[Symbol("PY")][:com]) ≈ WNDCnat["PY.com","Countermge"]#  0.981996223212021
@test JuMP.value(WiNnat._jump_model[Symbol("PY")][:amb]) ≈ WNDCnat["PY.amb","Countermge"]#  0.977572048008309
@test JuMP.value(WiNnat._jump_model[Symbol("PY")][:fbp]) ≈ WNDCnat["PY.fbp","Countermge"]#  0.955374628831952
@test JuMP.value(WiNnat._jump_model[Symbol("PY")][:rec]) ≈ WNDCnat["PY.rec","Countermge"]#  0.969420799392601
@test JuMP.value(WiNnat._jump_model[Symbol("PY")][:con]) ≈ WNDCnat["PY.con","Countermge"]#  0.963061555002948
@test JuMP.value(WiNnat._jump_model[Symbol("PY")][:agr]) ≈ WNDCnat["PY.agr","Countermge"]#  0.958425576039579
@test JuMP.value(WiNnat._jump_model[Symbol("PY")][:eec]) ≈ WNDCnat["PY.eec","Countermge"]#  0.967618806882819
@test JuMP.value(WiNnat._jump_model[Symbol("PY")][:fnd]) ≈ WNDCnat["PY.fnd","Countermge"]#  0.980078177983152
@test JuMP.value(WiNnat._jump_model[Symbol("PY")][:pub]) ≈ WNDCnat["PY.pub","Countermge"]#  0.979870171287797
@test JuMP.value(WiNnat._jump_model[Symbol("PY")][:hou]) ≈ WNDCnat["PY.hou","Countermge"]#  0.982125981772766
@test JuMP.value(WiNnat._jump_model[Symbol("PY")][:fbt]) ≈ WNDCnat["PY.fbt","Countermge"]#  0.976877322086655
@test JuMP.value(WiNnat._jump_model[Symbol("PY")][:ins]) ≈ WNDCnat["PY.ins","Countermge"]#  0.971102515229571
@test JuMP.value(WiNnat._jump_model[Symbol("PY")][:tex]) ≈ WNDCnat["PY.tex","Countermge"]#  0.956419001397148
@test JuMP.value(WiNnat._jump_model[Symbol("PY")][:leg]) ≈ WNDCnat["PY.leg","Countermge"]#  0.979046064875649
@test JuMP.value(WiNnat._jump_model[Symbol("PY")][:fen]) ≈ WNDCnat["PY.fen","Countermge"]#  0.977465610171964
@test JuMP.value(WiNnat._jump_model[Symbol("PY")][:uti]) ≈ WNDCnat["PY.uti","Countermge"]#  0.962873443545834
@test JuMP.value(WiNnat._jump_model[Symbol("PY")][:nmp]) ≈ WNDCnat["PY.nmp","Countermge"]#  0.963907909054831
@test JuMP.value(WiNnat._jump_model[Symbol("PY")][:brd]) ≈ WNDCnat["PY.brd","Countermge"]#  0.962737675115177
@test JuMP.value(WiNnat._jump_model[Symbol("PY")][:bnk]) ≈ WNDCnat["PY.bnk","Countermge"]#  0.978021603806015
@test JuMP.value(WiNnat._jump_model[Symbol("PY")][:ore]) ≈ WNDCnat["PY.ore","Countermge"]#  0.964580778608618
@test JuMP.value(WiNnat._jump_model[Symbol("PY")][:edu]) ≈ WNDCnat["PY.edu","Countermge"]#  0.979278839744443
@test JuMP.value(WiNnat._jump_model[Symbol("PY")][:ote]) ≈ WNDCnat["PY.ote","Countermge"]#  0.970342961210194
@test JuMP.value(WiNnat._jump_model[Symbol("PY")][:man]) ≈ WNDCnat["PY.man","Countermge"]#  0.978079421364602
@test JuMP.value(WiNnat._jump_model[Symbol("PY")][:mch]) ≈ WNDCnat["PY.mch","Countermge"]#  0.965957072977109
@test JuMP.value(WiNnat._jump_model[Symbol("PY")][:dat]) ≈ WNDCnat["PY.dat","Countermge"]#  0.971309167903213
@test JuMP.value(WiNnat._jump_model[Symbol("PY")][:amd]) ≈ WNDCnat["PY.amd","Countermge"]#  0.970212484349206
@test JuMP.value(WiNnat._jump_model[Symbol("PY")][:oil]) ≈ WNDCnat["PY.oil","Countermge"]#  0.970185928137116
@test JuMP.value(WiNnat._jump_model[Symbol("PY")][:hos]) ≈ WNDCnat["PY.hos","Countermge"]#  0.972895064809636
@test JuMP.value(WiNnat._jump_model[Symbol("PY")][:rnt]) ≈ WNDCnat["PY.rnt","Countermge"]#  0.975906207384103
@test JuMP.value(WiNnat._jump_model[Symbol("PY")][:pla]) ≈ WNDCnat["PY.pla","Countermge"]#  0.958990245593247
@test JuMP.value(WiNnat._jump_model[Symbol("PY")][:fof]) ≈ WNDCnat["PY.fof","Countermge"]#  0.976273590058943
@test JuMP.value(WiNnat._jump_model[Symbol("PY")][:fin]) ≈ WNDCnat["PY.fin","Countermge"]#  0.970714214098813
@test JuMP.value(WiNnat._jump_model[Symbol("PY")][:tsv]) ≈ WNDCnat["PY.tsv","Countermge"]#  0.976674041816356
@test JuMP.value(WiNnat._jump_model[Symbol("PY")][:nrs]) ≈ WNDCnat["PY.nrs","Countermge"]#  0.972765534159397
@test JuMP.value(WiNnat._jump_model[Symbol("PY")][:sec]) ≈ WNDCnat["PY.sec","Countermge"]#  0.975817623574049
@test JuMP.value(WiNnat._jump_model[Symbol("PY")][:art]) ≈ WNDCnat["PY.art","Countermge"]#  0.976954080603763
@test JuMP.value(WiNnat._jump_model[Symbol("PY")][:mov]) ≈ WNDCnat["PY.mov","Countermge"]#  0.9745910294591
@test JuMP.value(WiNnat._jump_model[Symbol("PY")][:fpd]) ≈ WNDCnat["PY.fpd","Countermge"]#  0.961626006921848
@test JuMP.value(WiNnat._jump_model[Symbol("PY")][:slg]) ≈ WNDCnat["PY.slg","Countermge"]#  0.971202575845032
@test JuMP.value(WiNnat._jump_model[Symbol("PY")][:pri]) ≈ WNDCnat["PY.pri","Countermge"]#  0.962621092645164
@test JuMP.value(WiNnat._jump_model[Symbol("PY")][:grd]) ≈ WNDCnat["PY.grd","Countermge"]#  0.971695246366333
@test JuMP.value(WiNnat._jump_model[Symbol("PY")][:pip]) ≈ WNDCnat["PY.pip","Countermge"]#  0.981294089857977
@test JuMP.value(WiNnat._jump_model[Symbol("PY")][:sle]) ≈ WNDCnat["PY.sle","Countermge"]#  0.955519878838054
@test JuMP.value(WiNnat._jump_model[Symbol("PY")][:osv]) ≈ WNDCnat["PY.osv","Countermge"]#  0.974328653331936
@test JuMP.value(WiNnat._jump_model[Symbol("PY")][:trn]) ≈ WNDCnat["PY.trn","Countermge"]#  0.961539260781785
@test JuMP.value(WiNnat._jump_model[Symbol("PY")][:smn]) ≈ WNDCnat["PY.smn","Countermge"]#  0.966869522562102
@test JuMP.value(WiNnat._jump_model[Symbol("PY")][:fmt]) ≈ WNDCnat["PY.fmt","Countermge"]#  0.969540222668639
@test JuMP.value(WiNnat._jump_model[Symbol("PY")][:pet]) ≈ WNDCnat["PY.pet","Countermge"]#  0.950760040941333
@test JuMP.value(WiNnat._jump_model[Symbol("PY")][:mvt]) ≈ WNDCnat["PY.mvt","Countermge"]#  0.978123175292777
@test JuMP.value(WiNnat._jump_model[Symbol("PY")][:cep]) ≈ WNDCnat["PY.cep","Countermge"]#  0.98341694429052
@test JuMP.value(WiNnat._jump_model[Symbol("PY")][:wst]) ≈ WNDCnat["PY.wst","Countermge"]#  0.968385487377624
@test JuMP.value(WiNnat._jump_model[Symbol("PY")][:mot]) ≈ WNDCnat["PY.mot","Countermge"]#  0.950391900111253
@test JuMP.value(WiNnat._jump_model[Symbol("PY")][:adm]) ≈ WNDCnat["PY.adm","Countermge"]#  0.974370746646231
@test JuMP.value(WiNnat._jump_model[Symbol("PY")][:soc]) ≈ WNDCnat["PY.soc","Countermge"]#  0.972915646452545
@test JuMP.value(WiNnat._jump_model[Symbol("PY")][:alt]) ≈ WNDCnat["PY.alt","Countermge"]#  0.958960454043128
@test JuMP.value(WiNnat._jump_model[Symbol("PY")][:pmt]) ≈ WNDCnat["PY.pmt","Countermge"]#  0.962191266007256
@test JuMP.value(WiNnat._jump_model[Symbol("PY")][:trk]) ≈ WNDCnat["PY.trk","Countermge"]#  0.952990571877631
@test JuMP.value(WiNnat._jump_model[Symbol("PY")][:fdd]) ≈ WNDCnat["PY.fdd","Countermge"]#  0.975397084495546
@test JuMP.value(WiNnat._jump_model[Symbol("PY")][:gmt]) ≈ WNDCnat["PY.gmt","Countermge"]#  0.977747439515496
@test JuMP.value(WiNnat._jump_model[Symbol("PY")][:wtt]) ≈ WNDCnat["PY.wtt","Countermge"]#  0.95750014618209
@test JuMP.value(WiNnat._jump_model[Symbol("PY")][:wpd]) ≈ WNDCnat["PY.wpd","Countermge"]#  0.962446994223797
@test JuMP.value(WiNnat._jump_model[Symbol("PY")][:wht]) ≈ WNDCnat["PY.wht","Countermge"]#  0.974988269367966
@test JuMP.value(WiNnat._jump_model[Symbol("PY")][:wrh]) ≈ WNDCnat["PY.wrh","Countermge"]#  0.969736198017531
@test JuMP.value(WiNnat._jump_model[Symbol("PY")][:ott]) ≈ WNDCnat["PY.ott","Countermge"]#  0.975257967255208
@test JuMP.value(WiNnat._jump_model[Symbol("PY")][:che]) ≈ WNDCnat["PY.che","Countermge"]#  0.961769823191389
@test JuMP.value(WiNnat._jump_model[Symbol("PY")][:air]) ≈ WNDCnat["PY.air","Countermge"]#  0.952383918119173
@test JuMP.value(WiNnat._jump_model[Symbol("PY")][:mmf]) ≈ WNDCnat["PY.mmf","Countermge"]#  0.970327488602595
@test JuMP.value(WiNnat._jump_model[Symbol("PY")][:otr]) ≈ WNDCnat["PY.otr","Countermge"]#  0.962834479756785
@test JuMP.value(WiNnat._jump_model[Symbol("PY")][:min]) ≈ WNDCnat["PY.min","Countermge"]#  0.962596136701183
@test JuMP.value(WiNnat._jump_model[Symbol("PVA")][:compen]) ≈ WNDCnat["PVA.compen","Countermge"]#  0.991599582233126
@test JuMP.value(WiNnat._jump_model[Symbol("PVA")][:surplus]) ≈ WNDCnat["PVA.surplus","Countermge"]#  0.984209754998423
@test JuMP.value(WiNnat._jump_model[Symbol("PM")][:trn]) ≈ WNDCnat["PM.trn","Countermge"]#  0.957631151575373
@test JuMP.value(WiNnat._jump_model[Symbol("PM")][:trd]) ≈ WNDCnat["PM.trd","Countermge"]#  0.975541250089501
@test JuMP.value(WiNnat._jump_model[Symbol("PFX")]) ≈ WNDCnat["PFX.missing","Countermge"]#  0.973859561546895
@test JuMP.value(WiNnat._jump_model[Symbol("RA")]) ≈ WNDCnat["RA.missing","Countermge"]#  12453.8963154469


end