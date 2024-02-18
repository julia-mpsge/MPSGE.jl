@testitem "WiNDC national model" begin
    # Replication of the WiNDC national MGE model
    using XLSX, MPSGE.JuMP.Containers
    # using JLD2
    # import JuMP
    using CSV
    
    # New data from Mitch Oct 11
    set_names = [:m,:va,:j,:fd,:ts,:yr,:i]; 
    S = Dict(); for set in set_names
    S[set] = [Symbol(a) for (a,b) in CSV.File(joinpath(@__DIR__,"./gams/national_ls/$set.csv"),stringtype=String)]
    end
    parm_names = [  (:a_0, (:yr, :i)), # (:tax_0, (:yr, :i)), Not in this model
                (:id_0, (:yr, :i, :j)),
                (:ys_0, (:yr, :j, :i)),
                (:ms_0, (:yr, :i, :m)),
                (:x_0, (:yr, :i)),
                (:s_0, (:yr, :i)),
                (:fs_0, (:yr, :i)), # (:duty_0, (:yr, :i)), Not in this model # (:trn_0, (:yr, :i)), Not in this model
                (:tm_0, (:yr, :i)),
                (:va_0, (:yr, :va, :j)),
                (:md_0, (:yr, :m, :i)),
                (:fd_0, (:yr, :i, :fd)),
                (:m_0, (:yr, :i)), # (:mrg_0, (:yr, :i)), Not in this model
                (:ty_0, (:yr, :j)),
                (:bopdef_0, (:yr,)), # (:sbd_0, (:yr, :i)), Not in this model
                (:ta_0, (:yr, :i)),
                (:y_0, (:yr, :i)), # (:ts_0, (:yr, :ts, :j)) Not in this model
                ];
    # Using the indices from S (from csv files), load the data from the csvs as DenseAxisArrays
    P= Dict(); 
    for (parm,parm_domain) in parm_names
        X = DenseAxisArray{Float64}(undef,[S[elm] for elm in parm_domain]...)
        fill!(X,0.0)
        for row in CSV.File(joinpath(@__DIR__,"gams/national_ls/$parm.csv"),stringtype=String)
            element = [Symbol(row[elm]) for elm in parm_domain]
            X[element...] = row[:value]
        end
        P[parm] = X
    end
    # JLD2 data causes an issue with the tests on Github
    # P= load(joinpath(@__DIR__,"./gams/DAAData.jld2"))["data"] # load in date from saved Notebook output Dict, named P
     # S= load(joinpath(@__DIR__,"./gams/Indices.jld2"))["data"] # load in date from saved Notebook output Dict, named S
    # Alternate, Julia WiNDC generated data
    # PJ= load(joinpath(@__DIR__,"./gams/JDAAData.jld2"))["data"] # load in date from saved Notebook output Dict, named P
    # SJ= load(joinpath(@__DIR__,"./gams/JIndices.jld2"))["data"] # load in date from saved Notebook output Dict, named S
    
    y_ = filter!(x -> x != :oth && x!= :use, S[:i][:]) # These 2 sectors 'use' & 'oth' are in the indices list, but have no data (and therefore cause problems)
    a_ = filter!(x -> x != :fbt && x != :mvt && x != :gmt, copy(y_))
    
    # Indexes (set from the data files, via the notebook)
    sectorsi = S[:i]#[:] # "BEA Goods and sectors categories", is "i" in GAMS
    sectorsj = copy(sectorsi) # "BEA Goods and sectors categories", is "j" in GAMS, for iterating over double index
    xfd = filter!(x -> x != :pce, copy(S[:fd])) # "BEA Final demand categories",
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
        ta = add!(WiNnat, MPSGE.Parameter(:ta, indices = (a_,), value=P[:ta_0][yr,a_].data)) #	"Tax net subsidy rate on intermediate demand",
        tm = add!(WiNnat, MPSGE.Parameter(:tm, indices = (a_,), value=P[:tm_0][yr,a_].data)) #	"Import tariff";
    
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
        A = add!(WiNnat, Sector(:A, indices=(a_,)))
    
        MS = add!(WiNnat, Sector(:MS, indices=(margin,)))
    
        # commodities:
        PA  = add!(WiNnat, Commodity(:PA, indices=(a_, ))) #	Armington price
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
    
        add!(WiNnat, DemandFunction(RA, :($(d_elas_ra)*1),
            [Demand(PA[i], fd_0[i,:pce]) for i in a_],
            [
                [Endowment(PY[i], fs_0[i]) for i in a_];
                [Endowment(PA[i], -sum(fd_0[i,xfd])) for i in a_];  
                [Endowment(PVA[va], sum(va_0[va,sectorsi])) for va in valueadded];
                Endowment(PFX, bopdef_0)
            ]
            ))
    
    
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
    # @test JuMP.value(WiNnat._jump_model[Symbol("A")][:fbt]) ≈ WNDCnat["A.fbt","benchmarkmge"]#  1
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
    # @test JuMP.value(WiNnat._jump_model[Symbol("A")][:mvt]) ≈ WNDCnat["A.mvt","benchmarkmge"]#  1
    @test JuMP.value(WiNnat._jump_model[Symbol("A")][:cep]) ≈ WNDCnat["A.cep","benchmarkmge"]#  1
    @test JuMP.value(WiNnat._jump_model[Symbol("A")][:wst]) ≈ WNDCnat["A.wst","benchmarkmge"]#  1
    @test JuMP.value(WiNnat._jump_model[Symbol("A")][:mot]) ≈ WNDCnat["A.mot","benchmarkmge"]#  1
    @test JuMP.value(WiNnat._jump_model[Symbol("A")][:adm]) ≈ WNDCnat["A.adm","benchmarkmge"]#  1
    @test JuMP.value(WiNnat._jump_model[Symbol("A")][:soc]) ≈ WNDCnat["A.soc","benchmarkmge"]#  1
    @test JuMP.value(WiNnat._jump_model[Symbol("A")][:alt]) ≈ WNDCnat["A.alt","benchmarkmge"]#  1
    @test JuMP.value(WiNnat._jump_model[Symbol("A")][:pmt]) ≈ WNDCnat["A.pmt","benchmarkmge"]#  1
    @test JuMP.value(WiNnat._jump_model[Symbol("A")][:trk]) ≈ WNDCnat["A.trk","benchmarkmge"]#  1
    @test JuMP.value(WiNnat._jump_model[Symbol("A")][:fdd]) ≈ WNDCnat["A.fdd","benchmarkmge"]#  1
    # @test JuMP.value(WiNnat._jump_model[Symbol("A")][:gmt]) ≈ WNDCnat["A.gmt","benchmarkmge"]#  1
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
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[wrh]ρRA")]) ≈ WNDCnat["DPARA.wrh","benchmarkmge"] atol=1.0e-8 #  0.0873265562585818
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
    @test JuMP.value(WiNnat._jump_model[Symbol("PY[pip]†A→dmpip")]) ≈ WNDCnat["DPYA.pip","benchmarkmge"] atol=1.0e-7 #  0.551520281
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
    # @test JuMP.value(WiNnat._jump_model[Symbol("PA")][:fbt]) ≈ WNDCnat["PA.fbt","benchmarkmge"]#  1
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
    # @test JuMP.value(WiNnat._jump_model[Symbol("PA")][:mvt]) ≈ WNDCnat["PA.mvt","benchmarkmge"]#  1
    @test JuMP.value(WiNnat._jump_model[Symbol("PA")][:cep]) ≈ WNDCnat["PA.cep","benchmarkmge"]#  1
    @test JuMP.value(WiNnat._jump_model[Symbol("PA")][:wst]) ≈ WNDCnat["PA.wst","benchmarkmge"]#  1
    @test JuMP.value(WiNnat._jump_model[Symbol("PA")][:mot]) ≈ WNDCnat["PA.mot","benchmarkmge"]#  1
    @test JuMP.value(WiNnat._jump_model[Symbol("PA")][:adm]) ≈ WNDCnat["PA.adm","benchmarkmge"]#  1
    @test JuMP.value(WiNnat._jump_model[Symbol("PA")][:soc]) ≈ WNDCnat["PA.soc","benchmarkmge"]#  1
    @test JuMP.value(WiNnat._jump_model[Symbol("PA")][:alt]) ≈ WNDCnat["PA.alt","benchmarkmge"]#  1
    @test JuMP.value(WiNnat._jump_model[Symbol("PA")][:pmt]) ≈ WNDCnat["PA.pmt","benchmarkmge"]#  1
    @test JuMP.value(WiNnat._jump_model[Symbol("PA")][:trk]) ≈ WNDCnat["PA.trk","benchmarkmge"]#  1
    @test JuMP.value(WiNnat._jump_model[Symbol("PA")][:fdd]) ≈ WNDCnat["PA.fdd","benchmarkmge"]#  1
    # @test JuMP.value(WiNnat._jump_model[Symbol("PA")][:gmt]) ≈ WNDCnat["PA.gmt","benchmarkmge"]#  1
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
    for i in a_
        set_value(ta[i], 0.)
        set_value(tm[i], 0.)
    end
    set_value(RA,  12453.8963154469) #So far, this updated default normalization value needs to be set, value from GAMS output. 12453.8963
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
    # @test JuMP.value(WiNnat._jump_model[Symbol("A")][:fbt]) ≈ WNDCnat["A.fbt","Countermge"]#  1
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
    @test JuMP.value(WiNnat._jump_model[Symbol("A")][:pip]) ≈ WNDCnat["A.pip","Countermge"] atol=1.0e-7 #  1.06222612169058
    @test JuMP.value(WiNnat._jump_model[Symbol("A")][:sle]) ≈ WNDCnat["A.sle","Countermge"]#  0.996996456841127
    @test JuMP.value(WiNnat._jump_model[Symbol("A")][:osv]) ≈ WNDCnat["A.osv","Countermge"]#  0.999043118120281
    @test JuMP.value(WiNnat._jump_model[Symbol("A")][:trn]) ≈ WNDCnat["A.trn","Countermge"]#  0.986965551382337
    @test JuMP.value(WiNnat._jump_model[Symbol("A")][:smn]) ≈ WNDCnat["A.smn","Countermge"]#  1.00731962935406
    @test JuMP.value(WiNnat._jump_model[Symbol("A")][:fmt]) ≈ WNDCnat["A.fmt","Countermge"]#  1.00894214241408
    @test JuMP.value(WiNnat._jump_model[Symbol("A")][:pet]) ≈ WNDCnat["A.pet","Countermge"]#  1.07877535469425
    # @test JuMP.value(WiNnat._jump_model[Symbol("A")][:mvt]) ≈ WNDCnat["A.mvt","Countermge"]#  1
    @test JuMP.value(WiNnat._jump_model[Symbol("A")][:cep]) ≈ WNDCnat["A.cep","Countermge"]#  0.998660303572017
    @test JuMP.value(WiNnat._jump_model[Symbol("A")][:wst]) ≈ WNDCnat["A.wst","Countermge"]#  1.00298117291499
    @test JuMP.value(WiNnat._jump_model[Symbol("A")][:mot]) ≈ WNDCnat["A.mot","Countermge"]#  1.01595926766198
    @test JuMP.value(WiNnat._jump_model[Symbol("A")][:adm]) ≈ WNDCnat["A.adm","Countermge"]#  1.00241194482332
    @test JuMP.value(WiNnat._jump_model[Symbol("A")][:soc]) ≈ WNDCnat["A.soc","Countermge"]#  0.978118116258101
    @test JuMP.value(WiNnat._jump_model[Symbol("A")][:alt]) ≈ WNDCnat["A.alt","Countermge"]#  1.07760725354631
    @test JuMP.value(WiNnat._jump_model[Symbol("A")][:pmt]) ≈ WNDCnat["A.pmt","Countermge"]#  1.01403892070354
    @test JuMP.value(WiNnat._jump_model[Symbol("A")][:trk]) ≈ WNDCnat["A.trk","Countermge"]#  1.01810679824243
    @test JuMP.value(WiNnat._jump_model[Symbol("A")][:fdd]) ≈ WNDCnat["A.fdd","Countermge"]#  1
    # @test JuMP.value(WiNnat._jump_model[Symbol("A")][:gmt]) ≈ WNDCnat["A.gmt","Countermge"]#  1
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
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[wrh]ρRA")]) ≈ WNDCnat["DPARA.wrh","Countermge"] atol=1.0e-8 #  0.0854605630590118
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[ott]ρRA")]) ≈ WNDCnat["DPARA.ott","Countermge"]#  5.31473768111257
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[che]ρRA")]) ≈ WNDCnat["DPARA.che","Countermge"]#  632.508582230469
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[air]ρRA")]) ≈ WNDCnat["DPARA.air","Countermge"]#  143.422732837925
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[mmf]ρRA")]) ≈ WNDCnat["DPARA.mmf","Countermge"]#  268.65901078116
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[otr]ρRA")]) ≈ WNDCnat["DPARA.otr","Countermge"]#  23.0291158739367
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[min]ρRA")]) ≈ WNDCnat["DPARA.min","Countermge"] atol = 1.0e-7 #  0.653932358001658
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
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[pip]‡A[pip]")]) ≈ WNDCnat["SPAA.pip","Countermge"] atol=1.0e-7 #  0.379117207466209
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
    @test JuMP.value(WiNnat._jump_model[Symbol("PY[pip]†A→dmpip")]) ≈ WNDCnat["DPYA.pip","Countermge"] atol=1.0e-7 #  0.551520281
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
    # @test JuMP.value(WiNnat._jump_model[Symbol("PA")][:fbt]) ≈ WNDCnat["PA.fbt","Countermge"]#  1
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
    @test JuMP.value(WiNnat._jump_model[Symbol("PA")][:pip]) ≈ WNDCnat["PA.pip","Countermge"] atol=1.0e-7 #  0.779861393418628
    @test JuMP.value(WiNnat._jump_model[Symbol("PA")][:sle]) ≈ WNDCnat["PA.sle","Countermge"]#  0.955519878838054
    @test JuMP.value(WiNnat._jump_model[Symbol("PA")][:osv]) ≈ WNDCnat["PA.osv","Countermge"]#  0.951762529497917
    @test JuMP.value(WiNnat._jump_model[Symbol("PA")][:trn]) ≈ WNDCnat["PA.trn","Countermge"]#  1.1424298822833
    @test JuMP.value(WiNnat._jump_model[Symbol("PA")][:smn]) ≈ WNDCnat["PA.smn","Countermge"]#  0.966755543366378
    @test JuMP.value(WiNnat._jump_model[Symbol("PA")][:fmt]) ≈ WNDCnat["PA.fmt","Countermge"]#  0.947009244551105
    @test JuMP.value(WiNnat._jump_model[Symbol("PA")][:pet]) ≈ WNDCnat["PA.pet","Countermge"]#  0.820924987727197
    # @test JuMP.value(WiNnat._jump_model[Symbol("PA")][:mvt]) ≈ WNDCnat["PA.mvt","Countermge"]#  1
    @test JuMP.value(WiNnat._jump_model[Symbol("PA")][:cep]) ≈ WNDCnat["PA.cep","Countermge"]#  0.957657289208879
    @test JuMP.value(WiNnat._jump_model[Symbol("PA")][:wst]) ≈ WNDCnat["PA.wst","Countermge"]#  0.954004512414617
    @test JuMP.value(WiNnat._jump_model[Symbol("PA")][:mot]) ≈ WNDCnat["PA.mot","Countermge"]#  0.929958821668799
    @test JuMP.value(WiNnat._jump_model[Symbol("PA")][:adm]) ≈ WNDCnat["PA.adm","Countermge"]#  0.967722383012059
    @test JuMP.value(WiNnat._jump_model[Symbol("PA")][:soc]) ≈ WNDCnat["PA.soc","Countermge"]#  0.969159093871482
    @test JuMP.value(WiNnat._jump_model[Symbol("PA")][:alt]) ≈ WNDCnat["PA.alt","Countermge"]#  0.87606610546441
    @test JuMP.value(WiNnat._jump_model[Symbol("PA")][:pmt]) ≈ WNDCnat["PA.pmt","Countermge"]#  0.95970014637895
    @test JuMP.value(WiNnat._jump_model[Symbol("PA")][:trk]) ≈ WNDCnat["PA.trk","Countermge"]#  0.942049354860982
    @test JuMP.value(WiNnat._jump_model[Symbol("PA")][:fdd]) ≈ WNDCnat["PA.fdd","Countermge"]#  0.975397084495546
    # @test JuMP.value(WiNnat._jump_model[Symbol("PA")][:gmt]) ≈ WNDCnat["PA.gmt","Countermge"]#  1
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
    
    set_value(d_elas_ra, 0.)
    set_value(RA, 12453.8764709011)
    set_fixed!(RA, true)
    solve!(WiNnat, convergence_tolerance=1e-6, cumulative_iteration_limit=10000);
    
    # delas=0
    @test JuMP.value(WiNnat._jump_model[Symbol("Y")][:ppd]) ≈ WNDCnat["Y.ppd","delas=0"]#  1.00578589079367
    @test JuMP.value(WiNnat._jump_model[Symbol("Y")][:res]) ≈ WNDCnat["Y.res","delas=0"]#  1.00015838522817
    @test JuMP.value(WiNnat._jump_model[Symbol("Y")][:com]) ≈ WNDCnat["Y.com","delas=0"]#  0.997520496119753
    @test JuMP.value(WiNnat._jump_model[Symbol("Y")][:amb]) ≈ WNDCnat["Y.amb","delas=0"]#  1.00005865489064
    @test JuMP.value(WiNnat._jump_model[Symbol("Y")][:fbp]) ≈ WNDCnat["Y.fbp","delas=0"]#  1.0023229758102
    @test JuMP.value(WiNnat._jump_model[Symbol("Y")][:rec]) ≈ WNDCnat["Y.rec","delas=0"]#  0.99994812697087
    @test JuMP.value(WiNnat._jump_model[Symbol("Y")][:con]) ≈ WNDCnat["Y.con","delas=0"]#  1.00008477485541
    @test JuMP.value(WiNnat._jump_model[Symbol("Y")][:agr]) ≈ WNDCnat["Y.agr","delas=0"]#  1.00631987026395
    @test JuMP.value(WiNnat._jump_model[Symbol("Y")][:eec]) ≈ WNDCnat["Y.eec","delas=0"]#  0.986176053048123
    @test JuMP.value(WiNnat._jump_model[Symbol("Y")][:fnd]) ≈ WNDCnat["Y.fnd","delas=0"]#  1
    @test JuMP.value(WiNnat._jump_model[Symbol("Y")][:pub]) ≈ WNDCnat["Y.pub","delas=0"]#  0.997608186148661
    @test JuMP.value(WiNnat._jump_model[Symbol("Y")][:hou]) ≈ WNDCnat["Y.hou","delas=0"]#  1.00006146198153
    @test JuMP.value(WiNnat._jump_model[Symbol("Y")][:fbt]) ≈ WNDCnat["Y.fbt","delas=0"]#  1.00182371543356
    @test JuMP.value(WiNnat._jump_model[Symbol("Y")][:ins]) ≈ WNDCnat["Y.ins","delas=0"]#  1.0002826599843
    @test JuMP.value(WiNnat._jump_model[Symbol("Y")][:tex]) ≈ WNDCnat["Y.tex","delas=0"]#  0.961127651076228
    @test JuMP.value(WiNnat._jump_model[Symbol("Y")][:leg]) ≈ WNDCnat["Y.leg","delas=0"]#  0.999165037648243
    @test JuMP.value(WiNnat._jump_model[Symbol("Y")][:fen]) ≈ WNDCnat["Y.fen","delas=0"]#  1.00071893230265
    @test JuMP.value(WiNnat._jump_model[Symbol("Y")][:uti]) ≈ WNDCnat["Y.uti","delas=0"]#  1.00081551974773
    @test JuMP.value(WiNnat._jump_model[Symbol("Y")][:nmp]) ≈ WNDCnat["Y.nmp","delas=0"]#  0.992091281550323
    @test JuMP.value(WiNnat._jump_model[Symbol("Y")][:brd]) ≈ WNDCnat["Y.brd","delas=0"]#  1.00043906885958
    @test JuMP.value(WiNnat._jump_model[Symbol("Y")][:bnk]) ≈ WNDCnat["Y.bnk","delas=0"]#  0.998928561425469
    @test JuMP.value(WiNnat._jump_model[Symbol("Y")][:ore]) ≈ WNDCnat["Y.ore","delas=0"]#  1.00043017494107
    @test JuMP.value(WiNnat._jump_model[Symbol("Y")][:edu]) ≈ WNDCnat["Y.edu","delas=0"]#  1.0000198568203
    @test JuMP.value(WiNnat._jump_model[Symbol("Y")][:ote]) ≈ WNDCnat["Y.ote","delas=0"]#  1.00035950284685
    @test JuMP.value(WiNnat._jump_model[Symbol("Y")][:man]) ≈ WNDCnat["Y.man","delas=0"]#  1.00034630219051
    @test JuMP.value(WiNnat._jump_model[Symbol("Y")][:mch]) ≈ WNDCnat["Y.mch","delas=0"]#  1.00124556921544
    @test JuMP.value(WiNnat._jump_model[Symbol("Y")][:dat]) ≈ WNDCnat["Y.dat","delas=0"]#  1.00003676407003
    @test JuMP.value(WiNnat._jump_model[Symbol("Y")][:amd]) ≈ WNDCnat["Y.amd","delas=0"]#  0.999975508134657
    @test JuMP.value(WiNnat._jump_model[Symbol("Y")][:oil]) ≈ WNDCnat["Y.oil","delas=0"]#  1.00688094090657
    @test JuMP.value(WiNnat._jump_model[Symbol("Y")][:hos]) ≈ WNDCnat["Y.hos","delas=0"]#  1.00007774098847
    @test JuMP.value(WiNnat._jump_model[Symbol("Y")][:rnt]) ≈ WNDCnat["Y.rnt","delas=0"]#  0.996929114791862
    @test JuMP.value(WiNnat._jump_model[Symbol("Y")][:pla]) ≈ WNDCnat["Y.pla","delas=0"]#  0.996917704223255
    @test JuMP.value(WiNnat._jump_model[Symbol("Y")][:fof]) ≈ WNDCnat["Y.fof","delas=0"]#  0.999082102369011
    @test JuMP.value(WiNnat._jump_model[Symbol("Y")][:fin]) ≈ WNDCnat["Y.fin","delas=0"]#  1.00008695060261
    @test JuMP.value(WiNnat._jump_model[Symbol("Y")][:tsv]) ≈ WNDCnat["Y.tsv","delas=0"]#  0.999019469149103
    @test JuMP.value(WiNnat._jump_model[Symbol("Y")][:nrs]) ≈ WNDCnat["Y.nrs","delas=0"]#  1.0000610303432
    @test JuMP.value(WiNnat._jump_model[Symbol("Y")][:sec]) ≈ WNDCnat["Y.sec","delas=0"]#  0.999353621669405
    @test JuMP.value(WiNnat._jump_model[Symbol("Y")][:art]) ≈ WNDCnat["Y.art","delas=0"]#  0.999817562233491
    @test JuMP.value(WiNnat._jump_model[Symbol("Y")][:mov]) ≈ WNDCnat["Y.mov","delas=0"]#  0.998063977004327
    @test JuMP.value(WiNnat._jump_model[Symbol("Y")][:fpd]) ≈ WNDCnat["Y.fpd","delas=0"]#  1.0076540663362
    @test JuMP.value(WiNnat._jump_model[Symbol("Y")][:slg]) ≈ WNDCnat["Y.slg","delas=0"]#  1
    @test JuMP.value(WiNnat._jump_model[Symbol("Y")][:pri]) ≈ WNDCnat["Y.pri","delas=0"]#  1.00148071732905
    @test JuMP.value(WiNnat._jump_model[Symbol("Y")][:grd]) ≈ WNDCnat["Y.grd","delas=0"]#  0.999931290943675
    @test JuMP.value(WiNnat._jump_model[Symbol("Y")][:pip]) ≈ WNDCnat["Y.pip","delas=0"]#  1.00326450376874
    @test JuMP.value(WiNnat._jump_model[Symbol("Y")][:sle]) ≈ WNDCnat["Y.sle","delas=0"]#  1.00009576452927
    @test JuMP.value(WiNnat._jump_model[Symbol("Y")][:osv]) ≈ WNDCnat["Y.osv","delas=0"]#  0.99976951325889
    @test JuMP.value(WiNnat._jump_model[Symbol("Y")][:trn]) ≈ WNDCnat["Y.trn","delas=0"]#  1.00352853796108
    @test JuMP.value(WiNnat._jump_model[Symbol("Y")][:smn]) ≈ WNDCnat["Y.smn","delas=0"]#  0.997626230786344
    @test JuMP.value(WiNnat._jump_model[Symbol("Y")][:fmt]) ≈ WNDCnat["Y.fmt","delas=0"]#  0.993767023918434
    @test JuMP.value(WiNnat._jump_model[Symbol("Y")][:pet]) ≈ WNDCnat["Y.pet","delas=0"]#  1.00932260447634
    @test JuMP.value(WiNnat._jump_model[Symbol("Y")][:mvt]) ≈ WNDCnat["Y.mvt","delas=0"]#  1.00179248074627
    @test JuMP.value(WiNnat._jump_model[Symbol("Y")][:cep]) ≈ WNDCnat["Y.cep","delas=0"]#  0.98250356176541
    @test JuMP.value(WiNnat._jump_model[Symbol("Y")][:wst]) ≈ WNDCnat["Y.wst","delas=0"]#  1.00037940734138
    @test JuMP.value(WiNnat._jump_model[Symbol("Y")][:mot]) ≈ WNDCnat["Y.mot","delas=0"]#  1.01286044673038
    @test JuMP.value(WiNnat._jump_model[Symbol("Y")][:adm]) ≈ WNDCnat["Y.adm","delas=0"]#  1.00018069177495
    @test JuMP.value(WiNnat._jump_model[Symbol("Y")][:soc]) ≈ WNDCnat["Y.soc","delas=0"]#  1.00006363630375
    @test JuMP.value(WiNnat._jump_model[Symbol("Y")][:alt]) ≈ WNDCnat["Y.alt","delas=0"]#  0.779459441770819
    @test JuMP.value(WiNnat._jump_model[Symbol("Y")][:pmt]) ≈ WNDCnat["Y.pmt","delas=0"]#  1.00653119885377
    @test JuMP.value(WiNnat._jump_model[Symbol("Y")][:trk]) ≈ WNDCnat["Y.trk","delas=0"]#  1.00332203819389
    @test JuMP.value(WiNnat._jump_model[Symbol("Y")][:fdd]) ≈ WNDCnat["Y.fdd","delas=0"]#  1
    @test JuMP.value(WiNnat._jump_model[Symbol("Y")][:gmt]) ≈ WNDCnat["Y.gmt","delas=0"]#  1.00179548366021
    @test JuMP.value(WiNnat._jump_model[Symbol("Y")][:wtt]) ≈ WNDCnat["Y.wtt","delas=0"]#  1.00503703147539
    @test JuMP.value(WiNnat._jump_model[Symbol("Y")][:wpd]) ≈ WNDCnat["Y.wpd","delas=0"]#  1.00147176303385
    @test JuMP.value(WiNnat._jump_model[Symbol("Y")][:wht]) ≈ WNDCnat["Y.wht","delas=0"]#  1.00185887017073
    @test JuMP.value(WiNnat._jump_model[Symbol("Y")][:wrh]) ≈ WNDCnat["Y.wrh","delas=0"]#  1.0003341719639
    @test JuMP.value(WiNnat._jump_model[Symbol("Y")][:ott]) ≈ WNDCnat["Y.ott","delas=0"]#  1.0018269547206
    @test JuMP.value(WiNnat._jump_model[Symbol("Y")][:che]) ≈ WNDCnat["Y.che","delas=0"]#  1.00157112042515
    @test JuMP.value(WiNnat._jump_model[Symbol("Y")][:air]) ≈ WNDCnat["Y.air","delas=0"]#  1.01424711754209
    @test JuMP.value(WiNnat._jump_model[Symbol("Y")][:mmf]) ≈ WNDCnat["Y.mmf","delas=0"]#  0.988861232088761
    @test JuMP.value(WiNnat._jump_model[Symbol("Y")][:otr]) ≈ WNDCnat["Y.otr","delas=0"]#  1.00390948064932
    @test JuMP.value(WiNnat._jump_model[Symbol("Y")][:min]) ≈ WNDCnat["Y.min","delas=0"]#  1.00439416273447
    @test JuMP.value(WiNnat._jump_model[Symbol("A")][:ppd]) ≈ WNDCnat["A.ppd","delas=0"]#  1.00362378204928
    @test JuMP.value(WiNnat._jump_model[Symbol("A")][:res]) ≈ WNDCnat["A.res","delas=0"]#  1.00021957182702
    @test JuMP.value(WiNnat._jump_model[Symbol("A")][:com]) ≈ WNDCnat["A.com","delas=0"]#  0.999135522921707
    @test JuMP.value(WiNnat._jump_model[Symbol("A")][:amb]) ≈ WNDCnat["A.amb","delas=0"]#  1.0000606151002
    @test JuMP.value(WiNnat._jump_model[Symbol("A")][:fbp]) ≈ WNDCnat["A.fbp","delas=0"]#  1.0014980432638
    @test JuMP.value(WiNnat._jump_model[Symbol("A")][:rec]) ≈ WNDCnat["A.rec","delas=0"]#  1.00006293674556
    @test JuMP.value(WiNnat._jump_model[Symbol("A")][:con]) ≈ WNDCnat["A.con","delas=0"]#  1.00010710990035
    @test JuMP.value(WiNnat._jump_model[Symbol("A")][:agr]) ≈ WNDCnat["A.agr","delas=0"]#  1.00420938079824
    @test JuMP.value(WiNnat._jump_model[Symbol("A")][:eec]) ≈ WNDCnat["A.eec","delas=0"]#  1.00177129917099
    @test JuMP.value(WiNnat._jump_model[Symbol("A")][:fnd]) ≈ WNDCnat["A.fnd","delas=0"]#  1
    @test JuMP.value(WiNnat._jump_model[Symbol("A")][:pub]) ≈ WNDCnat["A.pub","delas=0"]#  0.998003914523451
    @test JuMP.value(WiNnat._jump_model[Symbol("A")][:hou]) ≈ WNDCnat["A.hou","delas=0"]#  1.0000619068896
    # @test JuMP.value(WiNnat._jump_model[Symbol("A")][:fbt]) ≈ WNDCnat["A.fbt","delas=0"]#  1
    @test JuMP.value(WiNnat._jump_model[Symbol("A")][:ins]) ≈ WNDCnat["A.ins","delas=0"]#  1.00026112351513
    @test JuMP.value(WiNnat._jump_model[Symbol("A")][:tex]) ≈ WNDCnat["A.tex","delas=0"]#  0.998802020561824
    @test JuMP.value(WiNnat._jump_model[Symbol("A")][:leg]) ≈ WNDCnat["A.leg","delas=0"]#  0.999342267833263
    @test JuMP.value(WiNnat._jump_model[Symbol("A")][:fen]) ≈ WNDCnat["A.fen","delas=0"]#  1.00074025721027
    @test JuMP.value(WiNnat._jump_model[Symbol("A")][:uti]) ≈ WNDCnat["A.uti","delas=0"]#  1.00059423502693
    @test JuMP.value(WiNnat._jump_model[Symbol("A")][:nmp]) ≈ WNDCnat["A.nmp","delas=0"]#  1.0009885464123
    @test JuMP.value(WiNnat._jump_model[Symbol("A")][:brd]) ≈ WNDCnat["A.brd","delas=0"]#  1.00043476267719
    @test JuMP.value(WiNnat._jump_model[Symbol("A")][:bnk]) ≈ WNDCnat["A.bnk","delas=0"]#  0.998959725612476
    @test JuMP.value(WiNnat._jump_model[Symbol("A")][:ore]) ≈ WNDCnat["A.ore","delas=0"]#  1.00041450733429
    @test JuMP.value(WiNnat._jump_model[Symbol("A")][:edu]) ≈ WNDCnat["A.edu","delas=0"]#  1.00001464570266
    @test JuMP.value(WiNnat._jump_model[Symbol("A")][:ote]) ≈ WNDCnat["A.ote","delas=0"]#  1.00145870713754
    @test JuMP.value(WiNnat._jump_model[Symbol("A")][:man]) ≈ WNDCnat["A.man","delas=0"]#  1.00034630219051
    @test JuMP.value(WiNnat._jump_model[Symbol("A")][:mch]) ≈ WNDCnat["A.mch","delas=0"]#  1.00291322551238
    @test JuMP.value(WiNnat._jump_model[Symbol("A")][:dat]) ≈ WNDCnat["A.dat","delas=0"]#  0.999784975131571
    @test JuMP.value(WiNnat._jump_model[Symbol("A")][:amd]) ≈ WNDCnat["A.amd","delas=0"]#  0.999982449448896
    @test JuMP.value(WiNnat._jump_model[Symbol("A")][:oil]) ≈ WNDCnat["A.oil","delas=0"]#  1.00809275865993
    @test JuMP.value(WiNnat._jump_model[Symbol("A")][:hos]) ≈ WNDCnat["A.hos","delas=0"]#  1.00006202409019
    @test JuMP.value(WiNnat._jump_model[Symbol("A")][:rnt]) ≈ WNDCnat["A.rnt","delas=0"]#  0.997645383602863
    @test JuMP.value(WiNnat._jump_model[Symbol("A")][:pla]) ≈ WNDCnat["A.pla","delas=0"]#  1.0029625518548
    @test JuMP.value(WiNnat._jump_model[Symbol("A")][:fof]) ≈ WNDCnat["A.fof","delas=0"]#  1.00188241254111
    @test JuMP.value(WiNnat._jump_model[Symbol("A")][:fin]) ≈ WNDCnat["A.fin","delas=0"]#  1.00007338941603
    @test JuMP.value(WiNnat._jump_model[Symbol("A")][:tsv]) ≈ WNDCnat["A.tsv","delas=0"]#  0.999340056528015
    @test JuMP.value(WiNnat._jump_model[Symbol("A")][:nrs]) ≈ WNDCnat["A.nrs","delas=0"]#  1.00006105936276
    @test JuMP.value(WiNnat._jump_model[Symbol("A")][:sec]) ≈ WNDCnat["A.sec","delas=0"]#  0.999329312333588
    @test JuMP.value(WiNnat._jump_model[Symbol("A")][:art]) ≈ WNDCnat["A.art","delas=0"]#  0.999920748448576
    @test JuMP.value(WiNnat._jump_model[Symbol("A")][:mov]) ≈ WNDCnat["A.mov","delas=0"]#  0.998623985708231
    @test JuMP.value(WiNnat._jump_model[Symbol("A")][:fpd]) ≈ WNDCnat["A.fpd","delas=0"]#  1.00040655132139
    @test JuMP.value(WiNnat._jump_model[Symbol("A")][:slg]) ≈ WNDCnat["A.slg","delas=0"]#  1
    @test JuMP.value(WiNnat._jump_model[Symbol("A")][:pri]) ≈ WNDCnat["A.pri","delas=0"]#  1.00049602112227
    @test JuMP.value(WiNnat._jump_model[Symbol("A")][:grd]) ≈ WNDCnat["A.grd","delas=0"]#  0.999977083962352
    @test JuMP.value(WiNnat._jump_model[Symbol("A")][:pip]) ≈ WNDCnat["A.pip","delas=0"] atol=1.0e-7 #  0.985989854394285
    @test JuMP.value(WiNnat._jump_model[Symbol("A")][:sle]) ≈ WNDCnat["A.sle","delas=0"]#  1.0001079732021
    @test JuMP.value(WiNnat._jump_model[Symbol("A")][:osv]) ≈ WNDCnat["A.osv","delas=0"]#  1.0001830996395
    @test JuMP.value(WiNnat._jump_model[Symbol("A")][:trn]) ≈ WNDCnat["A.trn","delas=0"]#  1.00479861873786
    @test JuMP.value(WiNnat._jump_model[Symbol("A")][:smn]) ≈ WNDCnat["A.smn","delas=0"]#  1.00093202581705
    @test JuMP.value(WiNnat._jump_model[Symbol("A")][:fmt]) ≈ WNDCnat["A.fmt","delas=0"]#  1.00153471419173
    @test JuMP.value(WiNnat._jump_model[Symbol("A")][:pet]) ≈ WNDCnat["A.pet","delas=0"]#  1.00586750526947
    # @test JuMP.value(WiNnat._jump_model[Symbol("A")][:mvt]) ≈ WNDCnat["A.mvt","delas=0"]#  1
    @test JuMP.value(WiNnat._jump_model[Symbol("A")][:cep]) ≈ WNDCnat["A.cep","delas=0"]#  0.998378112853963
    @test JuMP.value(WiNnat._jump_model[Symbol("A")][:wst]) ≈ WNDCnat["A.wst","delas=0"]#  1.00037374106843
    @test JuMP.value(WiNnat._jump_model[Symbol("A")][:mot]) ≈ WNDCnat["A.mot","delas=0"]#  1.00631492828117
    @test JuMP.value(WiNnat._jump_model[Symbol("A")][:adm]) ≈ WNDCnat["A.adm","delas=0"]#  1.00017323601709
    @test JuMP.value(WiNnat._jump_model[Symbol("A")][:soc]) ≈ WNDCnat["A.soc","delas=0"]#  1.00006168614886
    @test JuMP.value(WiNnat._jump_model[Symbol("A")][:alt]) ≈ WNDCnat["A.alt","delas=0"]#  1.00069686488033
    @test JuMP.value(WiNnat._jump_model[Symbol("A")][:pmt]) ≈ WNDCnat["A.pmt","delas=0"]#  1.00348211375039
    @test JuMP.value(WiNnat._jump_model[Symbol("A")][:trk]) ≈ WNDCnat["A.trk","delas=0"]#  1.00314533277182
    @test JuMP.value(WiNnat._jump_model[Symbol("A")][:fdd]) ≈ WNDCnat["A.fdd","delas=0"]#  1
    # @test JuMP.value(WiNnat._jump_model[Symbol("A")][:gmt]) ≈ WNDCnat["A.gmt","delas=0"]#  1
    @test JuMP.value(WiNnat._jump_model[Symbol("A")][:wtt]) ≈ WNDCnat["A.wtt","delas=0"]#  1.0061511410938
    @test JuMP.value(WiNnat._jump_model[Symbol("A")][:wpd]) ≈ WNDCnat["A.wpd","delas=0"]#  1.00184795265916
    @test JuMP.value(WiNnat._jump_model[Symbol("A")][:wht]) ≈ WNDCnat["A.wht","delas=0"]#  1.00062798270384
    @test JuMP.value(WiNnat._jump_model[Symbol("A")][:wrh]) ≈ WNDCnat["A.wrh","delas=0"]#  1.00047090752075
    @test JuMP.value(WiNnat._jump_model[Symbol("A")][:ott]) ≈ WNDCnat["A.ott","delas=0"]#  1.00048317729974
    @test JuMP.value(WiNnat._jump_model[Symbol("A")][:che]) ≈ WNDCnat["A.che","delas=0"]#  1.00161061450511
    @test JuMP.value(WiNnat._jump_model[Symbol("A")][:air]) ≈ WNDCnat["A.air","delas=0"]#  1.00766093250638
    @test JuMP.value(WiNnat._jump_model[Symbol("A")][:mmf]) ≈ WNDCnat["A.mmf","delas=0"]#  1.00040257705607
    @test JuMP.value(WiNnat._jump_model[Symbol("A")][:otr]) ≈ WNDCnat["A.otr","delas=0"]#  1.00367228893136
    @test JuMP.value(WiNnat._jump_model[Symbol("A")][:min]) ≈ WNDCnat["A.min","delas=0"]#  1.00401399928603
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[ppd]ρRA")]) ≈ WNDCnat["DPARA.ppd","delas=0"]#  44.9945365993808
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[res]ρRA")]) ≈ WNDCnat["DPARA.res","delas=0"]#  739.686766872371
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[amb]ρRA")]) ≈ WNDCnat["DPARA.amb","delas=0"]#  1051.5603648016
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[fbp]ρRA")]) ≈ WNDCnat["DPARA.fbp","delas=0"]#  1032.70108735466
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[rec]ρRA")]) ≈ WNDCnat["DPARA.rec","delas=0"]#  198.985950838732
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[agr]ρRA")]) ≈ WNDCnat["DPARA.agr","delas=0"]#  147.869919600117
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[eec]ρRA")]) ≈ WNDCnat["DPARA.eec","delas=0"]#  86.2991216794809
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[pub]ρRA")]) ≈ WNDCnat["DPARA.pub","delas=0"]#  130.566354456531
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[hou]ρRA")]) ≈ WNDCnat["DPARA.hou","delas=0"]#  2035.2383474762
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[ins]ρRA")]) ≈ WNDCnat["DPARA.ins","delas=0"]#  387.00875602523
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[tex]ρRA")]) ≈ WNDCnat["DPARA.tex","delas=0"]#  72.7468150502661
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[leg]ρRA")]) ≈ WNDCnat["DPARA.leg","delas=0"]#  104.845945284567
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[fen]ρRA")]) ≈ WNDCnat["DPARA.fen","delas=0"]#  6.15763031614277
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[uti]ρRA")]) ≈ WNDCnat["DPARA.uti","delas=0"]#  264.769880065077
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[nmp]ρRA")]) ≈ WNDCnat["DPARA.nmp","delas=0"]#  20.8812969161211
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[brd]ρRA")]) ≈ WNDCnat["DPARA.brd","delas=0"]#  330.931479670374
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[bnk]ρRA")]) ≈ WNDCnat["DPARA.bnk","delas=0"]#  279.364610523514
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[ore]ρRA")]) ≈ WNDCnat["DPARA.ore","delas=0"]#  5.63104820910038
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[edu]ρRA")]) ≈ WNDCnat["DPARA.edu","delas=0"]#  351.715247249131
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[ote]ρRA")]) ≈ WNDCnat["DPARA.ote","delas=0"]#  32.6181905657221
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[mch]ρRA")]) ≈ WNDCnat["DPARA.mch","delas=0"]#  24.0993923260659
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[dat]ρRA")]) ≈ WNDCnat["DPARA.dat","delas=0"]#  55.6203913722785
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[amd]ρRA")]) ≈ WNDCnat["DPARA.amd","delas=0"]#  157.455010946577
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[hos]ρRA")]) ≈ WNDCnat["DPARA.hos","delas=0"]#  1066.51713067113
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[rnt]ρRA")]) ≈ WNDCnat["DPARA.rnt","delas=0"]#  105.372006849386
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[pla]ρRA")]) ≈ WNDCnat["DPARA.pla","delas=0"]#  67.3747264015542
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[fof]ρRA")]) ≈ WNDCnat["DPARA.fof","delas=0"]#  11.7890180762624
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[fin]ρRA")]) ≈ WNDCnat["DPARA.fin","delas=0"]#  162.347930833277
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[tsv]ρRA")]) ≈ WNDCnat["DPARA.tsv","delas=0"]#  72.8077220205937
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[nrs]ρRA")]) ≈ WNDCnat["DPARA.nrs","delas=0"]#  242.31260789127
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[sec]ρRA")]) ≈ WNDCnat["DPARA.sec","delas=0"]#  224.469566352445
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[art]ρRA")]) ≈ WNDCnat["DPARA.art","delas=0"]#  78.2371598193933
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[mov]ρRA")]) ≈ WNDCnat["DPARA.mov","delas=0"]#  32.5361842892829
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[fpd]ρRA")]) ≈ WNDCnat["DPARA.fpd","delas=0"]#  119.65836621871
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[pri]ρRA")]) ≈ WNDCnat["DPARA.pri","delas=0"]#  8.42139342000007
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[grd]ρRA")]) ≈ WNDCnat["DPARA.grd","delas=0"]#  45.8941685893515
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[sle]ρRA")]) ≈ WNDCnat["DPARA.sle","delas=0"]#  70.8549198361681
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[osv]ρRA")]) ≈ WNDCnat["DPARA.osv","delas=0"]#  615.338507334926
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[trn]ρRA")]) ≈ WNDCnat["DPARA.trn","delas=0"]#  1.50811298680475
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[fmt]ρRA")]) ≈ WNDCnat["DPARA.fmt","delas=0"]#  40.6909273928131
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[pet]ρRA")]) ≈ WNDCnat["DPARA.pet","delas=0"]#  310.703777513767
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[cep]ρRA")]) ≈ WNDCnat["DPARA.cep","delas=0"]#  164.529587884519
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[wst]ρRA")]) ≈ WNDCnat["DPARA.wst","delas=0"]#  27.0315947383601
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[mot]ρRA")]) ≈ WNDCnat["DPARA.mot","delas=0"]#  338.081915304201
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[adm]ρRA")]) ≈ WNDCnat["DPARA.adm","delas=0"]#  63.9163383167582
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[soc]ρRA")]) ≈ WNDCnat["DPARA.soc","delas=0"]#  210.509513182473
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[alt]ρRA")]) ≈ WNDCnat["DPARA.alt","delas=0"]#  399.722630052903
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[pmt]ρRA")]) ≈ WNDCnat["DPARA.pmt","delas=0"]#  1.74003550351761
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[trk]ρRA")]) ≈ WNDCnat["DPARA.trk","delas=0"]#  12.2901422973838
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[wtt]ρRA")]) ≈ WNDCnat["DPARA.wtt","delas=0"]#  21.4086095583859
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[wpd]ρRA")]) ≈ WNDCnat["DPARA.wpd","delas=0"]#  7.89464284252885
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[wrh]ρRA")]) ≈ WNDCnat["DPARA.wrh","delas=0"] atol=1.0e-8 #  0.0873319624154803
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[ott]ρRA")]) ≈ WNDCnat["DPARA.ott","delas=0"]#  5.46861401392708
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[che]ρRA")]) ≈ WNDCnat["DPARA.che","delas=0"]#  630.391967190115
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[air]ρRA")]) ≈ WNDCnat["DPARA.air","delas=0"]#  129.282761998234
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[mmf]ρRA")]) ≈ WNDCnat["DPARA.mmf","delas=0"]#  264.640159034949
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[otr]ρRA")]) ≈ WNDCnat["DPARA.otr","delas=0"]#  23.3484934431293
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[min]ρRA")]) ≈ WNDCnat["DPARA.min","delas=0"]#  0.643986262718571
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[ppd]‡A[ppd]")]) ≈ WNDCnat["SPAA.ppd","delas=0"]#  237.095668402558
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[res]‡A[res]")]) ≈ WNDCnat["SPAA.res","delas=0"]#  959.313391569356
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[com]‡A[com]")]) ≈ WNDCnat["SPAA.com","delas=0"]#  525.388253527651
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[amb]‡A[amb]")]) ≈ WNDCnat["SPAA.amb","delas=0"]#  1093.38061747821
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[fbp]‡A[fbp]")]) ≈ WNDCnat["SPAA.fbp","delas=0"]#  1516.0675363974
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[rec]‡A[rec]")]) ≈ WNDCnat["SPAA.rec","delas=0"]#  204.693237
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[con]‡A[con]")]) ≈ WNDCnat["SPAA.con","delas=0"]#  1661.39244764186
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[agr]‡A[agr]")]) ≈ WNDCnat["SPAA.agr","delas=0"]#  516.449182571726
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[eec]‡A[eec]")]) ≈ WNDCnat["SPAA.eec","delas=0"]#  298.345645152308
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[fnd]‡A[fnd]")]) ≈ WNDCnat["SPAA.fnd","delas=0"]#  380.898129
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[pub]‡A[pub]")]) ≈ WNDCnat["SPAA.pub","delas=0"]#  349.054406441761
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[hou]‡A[hou]")]) ≈ WNDCnat["SPAA.hou","delas=0"]#  2035.11236
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[ins]‡A[ins]")]) ≈ WNDCnat["SPAA.ins","delas=0"]#  1174.62489838087
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[tex]‡A[tex]")]) ≈ WNDCnat["SPAA.tex","delas=0"]#  145.384700102198
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[leg]‡A[leg]")]) ≈ WNDCnat["SPAA.leg","delas=0"]#  348.543208876288
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[fen]‡A[fen]")]) ≈ WNDCnat["SPAA.fen","delas=0"]#  70.4842836606326
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[uti]‡A[uti]")]) ≈ WNDCnat["SPAA.uti","delas=0"]#  652.064819413625
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[nmp]‡A[nmp]")]) ≈ WNDCnat["SPAA.nmp","delas=0"]#  214.170730815099
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[brd]‡A[brd]")]) ≈ WNDCnat["SPAA.brd","delas=0"]#  706.92158293153
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[bnk]‡A[bnk]")]) ≈ WNDCnat["SPAA.bnk","delas=0"]#  792.928809423471
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[ore]‡A[ore]")]) ≈ WNDCnat["SPAA.ore","delas=0"]#  1255.22670672849
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[edu]‡A[edu]")]) ≈ WNDCnat["SPAA.edu","delas=0"]#  392.721177238059
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[ote]‡A[ote]")]) ≈ WNDCnat["SPAA.ote","delas=0"]#  277.512122111029
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[man]‡A[man]")]) ≈ WNDCnat["SPAA.man","delas=0"]#  579.534061485011
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[mch]‡A[mch]")]) ≈ WNDCnat["SPAA.mch","delas=0"]#  587.302459128392
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[dat]‡A[dat]")]) ≈ WNDCnat["SPAA.dat","delas=0"]#  245.676944264987
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[amd]‡A[amd]")]) ≈ WNDCnat["SPAA.amd","delas=0"]#  229.587824
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[oil]‡A[oil]")]) ≈ WNDCnat["SPAA.oil","delas=0"]#  411.497048603792
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[hos]‡A[hos]")]) ≈ WNDCnat["SPAA.hos","delas=0"]#  1073.11603511482
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[rnt]‡A[rnt]")]) ≈ WNDCnat["SPAA.rnt","delas=0"]#  368.878804478233
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[pla]‡A[pla]")]) ≈ WNDCnat["SPAA.pla","delas=0"]#  362.323320781291
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[fof]‡A[fof]")]) ≈ WNDCnat["SPAA.fof","delas=0"]#  92.1228989157354
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[fin]‡A[fin]")]) ≈ WNDCnat["SPAA.fin","delas=0"]#  183.495134
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[tsv]‡A[tsv]")]) ≈ WNDCnat["SPAA.tsv","delas=0"]#  1989.37691817216
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[nrs]‡A[nrs]")]) ≈ WNDCnat["SPAA.nrs","delas=0"]#  245.658333
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[sec]‡A[sec]")]) ≈ WNDCnat["SPAA.sec","delas=0"]#  514.224717426736
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[art]‡A[art]")]) ≈ WNDCnat["SPAA.art","delas=0"]#  174.641390742409
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[mov]‡A[mov]")]) ≈ WNDCnat["SPAA.mov","delas=0"]#  146.569456555932
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[fpd]‡A[fpd]")]) ≈ WNDCnat["SPAA.fpd","delas=0"]#  221.278857788401
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[slg]‡A[slg]")]) ≈ WNDCnat["SPAA.slg","delas=0"]#  1744.23136
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[pri]‡A[pri]")]) ≈ WNDCnat["SPAA.pri","delas=0"]#  89.2867852003098
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[grd]‡A[grd]")]) ≈ WNDCnat["SPAA.grd","delas=0"]#  93.1481825
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[pip]‡A[pip]")]) ≈ WNDCnat["SPAA.pip","delas=0"] atol=1.0e-7 #  0.382187262062218
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[sle]‡A[sle]")]) ≈ WNDCnat["SPAA.sle","delas=0"]#  104.176032
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[osv]‡A[osv]")]) ≈ WNDCnat["SPAA.osv","delas=0"]#  868.463326892784
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[trn]‡A[trn]")]) ≈ WNDCnat["SPAA.trn","delas=0"]#  7.92415074551477
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[smn]‡A[smn]")]) ≈ WNDCnat["SPAA.smn","delas=0"]#  124.258768865999
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[fmt]‡A[fmt]")]) ≈ WNDCnat["SPAA.fmt","delas=0"]#  477.223423179182
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[pet]‡A[pet]")]) ≈ WNDCnat["SPAA.pet","delas=0"]#  754.140207758403
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[cep]‡A[cep]")]) ≈ WNDCnat["SPAA.cep","delas=0"]#  754.889357739978
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[wst]‡A[wst]")]) ≈ WNDCnat["SPAA.wst","delas=0"]#  117.576542647166
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[mot]‡A[mot]")]) ≈ WNDCnat["SPAA.mot","delas=0"]#  1115.85632282281
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[adm]‡A[adm]")]) ≈ WNDCnat["SPAA.adm","delas=0"]#  929.237345902182
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[soc]‡A[soc]")]) ≈ WNDCnat["SPAA.soc","delas=0"]#  211.263869
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[alt]‡A[alt]")]) ≈ WNDCnat["SPAA.alt","delas=0"]#  428.649715680174
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[pmt]‡A[pmt]")]) ≈ WNDCnat["SPAA.pmt","delas=0"]#  306.557469719843
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[trk]‡A[trk]")]) ≈ WNDCnat["SPAA.trk","delas=0"]#  37.635985494279
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[fdd]‡A[fdd]")]) ≈ WNDCnat["SPAA.fdd","delas=0"]#  598.321003
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[wtt]‡A[wtt]")]) ≈ WNDCnat["SPAA.wtt","delas=0"]#  24.7107318426004
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[wpd]‡A[wpd]")]) ≈ WNDCnat["SPAA.wpd","delas=0"]#  169.441222157702
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[wht]‡A[wht]")]) ≈ WNDCnat["SPAA.wht","delas=0"]#  101.048663092556
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[wrh]‡A[wrh]")]) ≈ WNDCnat["SPAA.wrh","delas=0"]#  141.955218141518
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[ott]‡A[ott]")]) ≈ WNDCnat["SPAA.ott","delas=0"]#  7.216437
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[che]‡A[che]")]) ≈ WNDCnat["SPAA.che","delas=0"]#  1316.08916247908
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[air]‡A[air]")]) ≈ WNDCnat["SPAA.air","delas=0"]#  206.906400189041
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[mmf]‡A[mmf]")]) ≈ WNDCnat["SPAA.mmf","delas=0"]#  432.903209984379
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[otr]‡A[otr]")]) ≈ WNDCnat["SPAA.otr","delas=0"]#  234.249449781175
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[min]‡A[min]")]) ≈ WNDCnat["SPAA.min","delas=0"]#  110.7701129422
    @test JuMP.value(WiNnat._jump_model[Symbol("PY[ppd]†A→dmppd")]) ≈ WNDCnat["DPYA.ppd","delas=0"]#  178.21075049051
    @test JuMP.value(WiNnat._jump_model[Symbol("PY[res]†A→dmres")]) ≈ WNDCnat["DPYA.res","delas=0"]#  899.582049
    @test JuMP.value(WiNnat._jump_model[Symbol("PY[com]†A→dmcom")]) ≈ WNDCnat["DPYA.com","delas=0"]#  516.642196501858
    @test JuMP.value(WiNnat._jump_model[Symbol("PY[amb]†A→dmamb")]) ≈ WNDCnat["DPYA.amb","delas=0"]#  1092.93382
    @test JuMP.value(WiNnat._jump_model[Symbol("PY[fbp]†A→dmfbp")]) ≈ WNDCnat["DPYA.fbp","delas=0"]#  931.00345778859
    @test JuMP.value(WiNnat._jump_model[Symbol("PY[rec]†A→dmrec")]) ≈ WNDCnat["DPYA.rec","delas=0"]#  195.091973
    @test JuMP.value(WiNnat._jump_model[Symbol("PY[con]†A→dmcon")]) ≈ WNDCnat["DPYA.con","delas=0"]#  1659.55143
    @test JuMP.value(WiNnat._jump_model[Symbol("PY[agr]†A→dmagr")]) ≈ WNDCnat["DPYA.agr","delas=0"]#  396.877165615111
    @test JuMP.value(WiNnat._jump_model[Symbol("PY[eec]†A→dmeec")]) ≈ WNDCnat["DPYA.eec","delas=0"]#  116.115975355055
    @test JuMP.value(WiNnat._jump_model[Symbol("PY[fnd]†A→dmfnd")]) ≈ WNDCnat["DPYA.fnd","delas=0"]#  380.898129
    @test JuMP.value(WiNnat._jump_model[Symbol("PY[pub]†A→dmpub")]) ≈ WNDCnat["DPYA.pub","delas=0"]#  279.081932129493
    @test JuMP.value(WiNnat._jump_model[Symbol("PY[hou]†A→dmhou")]) ≈ WNDCnat["DPYA.hou","delas=0"]#  2073.31916
    @test JuMP.value(WiNnat._jump_model[Symbol("PY[ins]†A→dmins")]) ≈ WNDCnat["DPYA.ins","delas=0"]#  1122.4038138215
    @test JuMP.value(WiNnat._jump_model[Symbol("PY[tex]†A→dmtex")]) ≈ WNDCnat["DPYA.tex","delas=0"]#  44.6512497935603
    @test JuMP.value(WiNnat._jump_model[Symbol("PY[leg]†A→dmleg")]) ≈ WNDCnat["DPYA.leg","delas=0"]#  342.931208808951
    @test JuMP.value(WiNnat._jump_model[Symbol("PY[fen]†A→dmfen")]) ≈ WNDCnat["DPYA.fen","delas=0"]#  70.8983536965506
    @test JuMP.value(WiNnat._jump_model[Symbol("PY[uti]†A→dmuti")]) ≈ WNDCnat["DPYA.uti","delas=0"]#  624.227774668326
    @test JuMP.value(WiNnat._jump_model[Symbol("PY[nmp]†A→dmnmp")]) ≈ WNDCnat["DPYA.nmp","delas=0"]#  122.525922980665
    @test JuMP.value(WiNnat._jump_model[Symbol("PY[brd]†A→dmbrd")]) ≈ WNDCnat["DPYA.brd","delas=0"]#  683.421349297816
    @test JuMP.value(WiNnat._jump_model[Symbol("PY[bnk]†A→dmbnk")]) ≈ WNDCnat["DPYA.bnk","delas=0"]#  852.551368068504
    @test JuMP.value(WiNnat._jump_model[Symbol("PY[ore]†A→dmore")]) ≈ WNDCnat["DPYA.ore","delas=0"]#  1259.29276
    @test JuMP.value(WiNnat._jump_model[Symbol("PY[edu]†A→dmedu")]) ≈ WNDCnat["DPYA.edu","delas=0"]#  393.241182081057
    @test JuMP.value(WiNnat._jump_model[Symbol("PY[ote]†A→dmote")]) ≈ WNDCnat["DPYA.ote","delas=0"]#  317.472450892451
    @test JuMP.value(WiNnat._jump_model[Symbol("PY[man]†A→dmman")]) ≈ WNDCnat["DPYA.man","delas=0"]#  582.277441
    @test JuMP.value(WiNnat._jump_model[Symbol("PY[mch]†A→dmmch")]) ≈ WNDCnat["DPYA.mch","delas=0"]#  350.621153933213
    @test JuMP.value(WiNnat._jump_model[Symbol("PY[dat]†A→dmdat")]) ≈ WNDCnat["DPYA.dat","delas=0"]#  249.628668046696
    @test JuMP.value(WiNnat._jump_model[Symbol("PY[amd]†A→dmamd")]) ≈ WNDCnat["DPYA.amd","delas=0"]#  211.274527
    @test JuMP.value(WiNnat._jump_model[Symbol("PY[oil]†A→dmoil")]) ≈ WNDCnat["DPYA.oil","delas=0"]#  231.642002005523
    @test JuMP.value(WiNnat._jump_model[Symbol("PY[hos]†A→dmhos")]) ≈ WNDCnat["DPYA.hos","delas=0"]#  1069.65355419784
    @test JuMP.value(WiNnat._jump_model[Symbol("PY[rnt]†A→dmrnt")]) ≈ WNDCnat["DPYA.rnt","delas=0"]#  433.205937
    @test JuMP.value(WiNnat._jump_model[Symbol("PY[pla]†A→dmpla")]) ≈ WNDCnat["DPYA.pla","delas=0"]#  229.566295840274
    @test JuMP.value(WiNnat._jump_model[Symbol("PY[fof]†A→dmfof")]) ≈ WNDCnat["DPYA.fof","delas=0"]#  65.7273275023142
    @test JuMP.value(WiNnat._jump_model[Symbol("PY[fin]†A→dmfin")]) ≈ WNDCnat["DPYA.fin","delas=0"]#  183.457238
    @test JuMP.value(WiNnat._jump_model[Symbol("PY[tsv]†A→dmtsv")]) ≈ WNDCnat["DPYA.tsv","delas=0"]#  2035.15069283442
    @test JuMP.value(WiNnat._jump_model[Symbol("PY[nrs]†A→dmnrs")]) ≈ WNDCnat["DPYA.nrs","delas=0"]#  242.743749
    @test JuMP.value(WiNnat._jump_model[Symbol("PY[sec]†A→dmsec")]) ≈ WNDCnat["DPYA.sec","delas=0"]#  584.314692597079
    @test JuMP.value(WiNnat._jump_model[Symbol("PY[art]†A→dmart")]) ≈ WNDCnat["DPYA.art","delas=0"]#  169.247278606401
    @test JuMP.value(WiNnat._jump_model[Symbol("PY[mov]†A→dmmov")]) ≈ WNDCnat["DPYA.mov","delas=0"]#  145.054508466726
    @test JuMP.value(WiNnat._jump_model[Symbol("PY[fpd]†A→dmfpd")]) ≈ WNDCnat["DPYA.fpd","delas=0"]#  72.0340376373278
    @test JuMP.value(WiNnat._jump_model[Symbol("PY[slg]†A→dmslg")]) ≈ WNDCnat["DPYA.slg","delas=0"]#  1744.23136
    @test JuMP.value(WiNnat._jump_model[Symbol("PY[pri]†A→dmpri")]) ≈ WNDCnat["DPYA.pri","delas=0"]#  71.1498911232477
    @test JuMP.value(WiNnat._jump_model[Symbol("PY[grd]†A→dmgrd")]) ≈ WNDCnat["DPYA.grd","delas=0"]#  92.1405807
    @test JuMP.value(WiNnat._jump_model[Symbol("PY[pip]†A→dmpip")]) ≈ WNDCnat["DPYA.pip","delas=0"] atol=1.0e-7 #  0.551520281
    @test JuMP.value(WiNnat._jump_model[Symbol("PY[sle]†A→dmsle")]) ≈ WNDCnat["DPYA.sle","delas=0"]#  104.176032
    @test JuMP.value(WiNnat._jump_model[Symbol("PY[osv]†A→dmosv")]) ≈ WNDCnat["DPYA.osv","delas=0"]#  843.612078140922
    @test JuMP.value(WiNnat._jump_model[Symbol("PY[trn]†A→dmtrn")]) ≈ WNDCnat["DPYA.trn","delas=0"]#  10.818151
    @test JuMP.value(WiNnat._jump_model[Symbol("PY[smn]†A→dmsmn")]) ≈ WNDCnat["DPYA.smn","delas=0"]#  126.300856150821
    @test JuMP.value(WiNnat._jump_model[Symbol("PY[fmt]†A→dmfmt")]) ≈ WNDCnat["DPYA.fmt","delas=0"]#  326.674921247834
    @test JuMP.value(WiNnat._jump_model[Symbol("PY[pet]†A→dmpet")]) ≈ WNDCnat["DPYA.pet","delas=0"]#  530.135768600117
    @test JuMP.value(WiNnat._jump_model[Symbol("PY[cep]†A→dmcep")]) ≈ WNDCnat["DPYA.cep","delas=0"]#  293.672381307298
    @test JuMP.value(WiNnat._jump_model[Symbol("PY[wst]†A→dmwst")]) ≈ WNDCnat["DPYA.wst","delas=0"]#  115.755819924613
    @test JuMP.value(WiNnat._jump_model[Symbol("PY[mot]†A→dmmot")]) ≈ WNDCnat["DPYA.mot","delas=0"]#  661.976681705433
    @test JuMP.value(WiNnat._jump_model[Symbol("PY[adm]†A→dmadm")]) ≈ WNDCnat["DPYA.adm","delas=0"]#  923.37937571617
    @test JuMP.value(WiNnat._jump_model[Symbol("PY[soc]†A→dmsoc")]) ≈ WNDCnat["DPYA.soc","delas=0"]#  210.448152
    @test JuMP.value(WiNnat._jump_model[Symbol("PY[alt]†A→dmalt")]) ≈ WNDCnat["DPYA.alt","delas=0"]#  15.1266248122091
    @test JuMP.value(WiNnat._jump_model[Symbol("PY[pmt]†A→dmpmt")]) ≈ WNDCnat["DPYA.pmt","delas=0"]#  209.112552452253
    @test JuMP.value(WiNnat._jump_model[Symbol("PY[trk]†A→dmtrk")]) ≈ WNDCnat["DPYA.trk","delas=0"]#  38.934866
    @test JuMP.value(WiNnat._jump_model[Symbol("PY[fdd]†A→dmfdd")]) ≈ WNDCnat["DPYA.fdd","delas=0"]#  598.321003
    @test JuMP.value(WiNnat._jump_model[Symbol("PY[wtt]†A→dmwtt")]) ≈ WNDCnat["DPYA.wtt","delas=0"]#  29.5450418
    @test JuMP.value(WiNnat._jump_model[Symbol("PY[wpd]†A→dmwpd")]) ≈ WNDCnat["DPYA.wpd","delas=0"]#  110.717249634737
    @test JuMP.value(WiNnat._jump_model[Symbol("PY[wht]†A→dmwht")]) ≈ WNDCnat["DPYA.wht","delas=0"]#  103.418245
    @test JuMP.value(WiNnat._jump_model[Symbol("PY[wrh]†A→dmwrh")]) ≈ WNDCnat["DPYA.wrh","delas=0"]#  141.952358
    @test JuMP.value(WiNnat._jump_model[Symbol("PY[ott]†A→dmott")]) ≈ WNDCnat["DPYA.ott","delas=0"]#  7.216437
    @test JuMP.value(WiNnat._jump_model[Symbol("PY[che]†A→dmche")]) ≈ WNDCnat["DPYA.che","delas=0"]#  747.766537670418
    @test JuMP.value(WiNnat._jump_model[Symbol("PY[air]†A→dmair")]) ≈ WNDCnat["DPYA.air","delas=0"]#  191.205489940419
    @test JuMP.value(WiNnat._jump_model[Symbol("PY[mmf]†A→dmmmf")]) ≈ WNDCnat["DPYA.mmf","delas=0"]#  144.225723685467
    @test JuMP.value(WiNnat._jump_model[Symbol("PY[otr]†A→dmotr")]) ≈ WNDCnat["DPYA.otr","delas=0"]#  244.239910468167
    @test JuMP.value(WiNnat._jump_model[Symbol("PY[min]†A→dmmin")]) ≈ WNDCnat["DPYA.min","delas=0"]#  83.8238663779317
    @test JuMP.value(WiNnat._jump_model[Symbol("PM[trn]‡MS[trn]")]) ≈ WNDCnat["SPMMS.trn","delas=0"]#  441.38467
    @test JuMP.value(WiNnat._jump_model[Symbol("PM[trd]‡MS[trd]")]) ≈ WNDCnat["SPMMS.trd","delas=0"]#  2963.50744
    @test JuMP.value(WiNnat._jump_model[Symbol("MS")][:trn]) ≈ WNDCnat["MS.trn","delas=0"]#  1.00331384764837
    @test JuMP.value(WiNnat._jump_model[Symbol("MS")][:trd]) ≈ WNDCnat["MS.trd","delas=0"]#  1.00176499491427
    @test JuMP.value(WiNnat._jump_model[Symbol("PA")][:ppd]) ≈ WNDCnat["PA.ppd","delas=0"]#  0.944559101695778
    @test JuMP.value(WiNnat._jump_model[Symbol("PA")][:res]) ≈ WNDCnat["PA.res","delas=0"]#  0.903708550522949
    @test JuMP.value(WiNnat._jump_model[Symbol("PA")][:com]) ≈ WNDCnat["PA.com","delas=0"]#  0.971450632063904
    @test JuMP.value(WiNnat._jump_model[Symbol("PA")][:amb]) ≈ WNDCnat["PA.amb","delas=0"]#  0.974885056949802
    @test JuMP.value(WiNnat._jump_model[Symbol("PA")][:fbp]) ≈ WNDCnat["PA.fbp","delas=0"]#  0.904807082769487
    @test JuMP.value(WiNnat._jump_model[Symbol("PA")][:rec]) ≈ WNDCnat["PA.rec","delas=0"]#  0.922449169782505
    @test JuMP.value(WiNnat._jump_model[Symbol("PA")][:con]) ≈ WNDCnat["PA.con","delas=0"]#  0.960504292390402
    @test JuMP.value(WiNnat._jump_model[Symbol("PA")][:agr]) ≈ WNDCnat["PA.agr","delas=0"]#  0.969158177798507
    @test JuMP.value(WiNnat._jump_model[Symbol("PA")][:eec]) ≈ WNDCnat["PA.eec","delas=0"]#  0.936130220504458
    @test JuMP.value(WiNnat._jump_model[Symbol("PA")][:fnd]) ≈ WNDCnat["PA.fnd","delas=0"]#  0.978735209313508
    @test JuMP.value(WiNnat._jump_model[Symbol("PA")][:pub]) ≈ WNDCnat["PA.pub","delas=0"]#  0.955274641335733
    @test JuMP.value(WiNnat._jump_model[Symbol("PA")][:hou]) ≈ WNDCnat["PA.hou","delas=0"]#  1.00356800607814
    # @test JuMP.value(WiNnat._jump_model[Symbol("PA")][:fbt]) ≈ WNDCnat["PA.fbt","delas=0"]#  1
    @test JuMP.value(WiNnat._jump_model[Symbol("PA")][:ins]) ≈ WNDCnat["PA.ins","delas=0"]#  0.954574299699064
    @test JuMP.value(WiNnat._jump_model[Symbol("PA")][:tex]) ≈ WNDCnat["PA.tex","delas=0"]#  0.911106201550666
    @test JuMP.value(WiNnat._jump_model[Symbol("PA")][:leg]) ≈ WNDCnat["PA.leg","delas=0"]#  0.934421555499732
    @test JuMP.value(WiNnat._jump_model[Symbol("PA")][:fen]) ≈ WNDCnat["PA.fen","delas=0"]#  0.973948881811649
    @test JuMP.value(WiNnat._jump_model[Symbol("PA")][:uti]) ≈ WNDCnat["PA.uti","delas=0"]#  0.919543606852853
    @test JuMP.value(WiNnat._jump_model[Symbol("PA")][:nmp]) ≈ WNDCnat["PA.nmp","delas=0"]#  0.938417126742624
    @test JuMP.value(WiNnat._jump_model[Symbol("PA")][:brd]) ≈ WNDCnat["PA.brd","delas=0"]#  0.913682137056211
    @test JuMP.value(WiNnat._jump_model[Symbol("PA")][:bnk]) ≈ WNDCnat["PA.bnk","delas=0"]#  0.978995433429131
    @test JuMP.value(WiNnat._jump_model[Symbol("PA")][:ore]) ≈ WNDCnat["PA.ore","delas=0"]#  0.965298564593069
    @test JuMP.value(WiNnat._jump_model[Symbol("PA")][:edu]) ≈ WNDCnat["PA.edu","delas=0"]#  0.976288086368048
    @test JuMP.value(WiNnat._jump_model[Symbol("PA")][:ote]) ≈ WNDCnat["PA.ote","delas=0"]#  0.961321229467476
    @test JuMP.value(WiNnat._jump_model[Symbol("PA")][:man]) ≈ WNDCnat["PA.man","delas=0"]#  0.973004483189782
    @test JuMP.value(WiNnat._jump_model[Symbol("PA")][:mch]) ≈ WNDCnat["PA.mch","delas=0"]#  0.946113722980971
    @test JuMP.value(WiNnat._jump_model[Symbol("PA")][:dat]) ≈ WNDCnat["PA.dat","delas=0"]#  0.969263532807564
    @test JuMP.value(WiNnat._jump_model[Symbol("PA")][:amd]) ≈ WNDCnat["PA.amd","delas=0"]#  0.891754914733735
    @test JuMP.value(WiNnat._jump_model[Symbol("PA")][:oil]) ≈ WNDCnat["PA.oil","delas=0"]#  0.944525058471408
    @test JuMP.value(WiNnat._jump_model[Symbol("PA")][:hos]) ≈ WNDCnat["PA.hos","delas=0"]#  0.968942512768636
    @test JuMP.value(WiNnat._jump_model[Symbol("PA")][:rnt]) ≈ WNDCnat["PA.rnt","delas=0"]#  0.934171829314441
    @test JuMP.value(WiNnat._jump_model[Symbol("PA")][:pla]) ≈ WNDCnat["PA.pla","delas=0"]#  0.935499824635909
    @test JuMP.value(WiNnat._jump_model[Symbol("PA")][:fof]) ≈ WNDCnat["PA.fof","delas=0"]#  0.964188851356017
    @test JuMP.value(WiNnat._jump_model[Symbol("PA")][:fin]) ≈ WNDCnat["PA.fin","delas=0"]#  0.969344521130822
    @test JuMP.value(WiNnat._jump_model[Symbol("PA")][:tsv]) ≈ WNDCnat["PA.tsv","delas=0"]#  0.972641058003388
    @test JuMP.value(WiNnat._jump_model[Symbol("PA")][:nrs]) ≈ WNDCnat["PA.nrs","delas=0"]#  0.958483264421221
    @test JuMP.value(WiNnat._jump_model[Symbol("PA")][:sec]) ≈ WNDCnat["PA.sec","delas=0"]#  0.971353363818214
    @test JuMP.value(WiNnat._jump_model[Symbol("PA")][:art]) ≈ WNDCnat["PA.art","delas=0"]#  0.945372401757906
    @test JuMP.value(WiNnat._jump_model[Symbol("PA")][:mov]) ≈ WNDCnat["PA.mov","delas=0"]#  0.950767401553106
    @test JuMP.value(WiNnat._jump_model[Symbol("PA")][:fpd]) ≈ WNDCnat["PA.fpd","delas=0"]#  0.925102758032725
    @test JuMP.value(WiNnat._jump_model[Symbol("PA")][:slg]) ≈ WNDCnat["PA.slg","delas=0"]#  0.968358481331393
    @test JuMP.value(WiNnat._jump_model[Symbol("PA")][:pri]) ≈ WNDCnat["PA.pri","delas=0"]#  0.951960665701127
    @test JuMP.value(WiNnat._jump_model[Symbol("PA")][:grd]) ≈ WNDCnat["PA.grd","delas=0"]#  0.96055265642299
    @test JuMP.value(WiNnat._jump_model[Symbol("PA")][:pip]) ≈ WNDCnat["PA.pip","delas=0"] atol=1.0e-7 #  0.784186918977728
    @test JuMP.value(WiNnat._jump_model[Symbol("PA")][:sle]) ≈ WNDCnat["PA.sle","delas=0"]#  0.950692169697937
    @test JuMP.value(WiNnat._jump_model[Symbol("PA")][:osv]) ≈ WNDCnat["PA.osv","delas=0"]#  0.949741104856439
    @test JuMP.value(WiNnat._jump_model[Symbol("PA")][:trn]) ≈ WNDCnat["PA.trn","delas=0"]#  1.14207648268644
    @test JuMP.value(WiNnat._jump_model[Symbol("PA")][:smn]) ≈ WNDCnat["PA.smn","delas=0"]#  0.965099589925666
    @test JuMP.value(WiNnat._jump_model[Symbol("PA")][:fmt]) ≈ WNDCnat["PA.fmt","delas=0"]#  0.945421509797243
    @test JuMP.value(WiNnat._jump_model[Symbol("PA")][:pet]) ≈ WNDCnat["PA.pet","delas=0"]#  0.820970005125599
    # @test JuMP.value(WiNnat._jump_model[Symbol("PA")][:mvt]) ≈ WNDCnat["PA.mvt","delas=0"]#  1
    @test JuMP.value(WiNnat._jump_model[Symbol("PA")][:cep]) ≈ WNDCnat["PA.cep","delas=0"]#  0.955919309753241
    @test JuMP.value(WiNnat._jump_model[Symbol("PA")][:wst]) ≈ WNDCnat["PA.wst","delas=0"]#  0.952738240187138
    @test JuMP.value(WiNnat._jump_model[Symbol("PA")][:mot]) ≈ WNDCnat["PA.mot","delas=0"]#  0.928379686984239
    @test JuMP.value(WiNnat._jump_model[Symbol("PA")][:adm]) ≈ WNDCnat["PA.adm","delas=0"]#  0.965713837842447
    @test JuMP.value(WiNnat._jump_model[Symbol("PA")][:soc]) ≈ WNDCnat["PA.soc","delas=0"]#  0.966436120944972
    @test JuMP.value(WiNnat._jump_model[Symbol("PA")][:alt]) ≈ WNDCnat["PA.alt","delas=0"]#  0.874242668909815
    @test JuMP.value(WiNnat._jump_model[Symbol("PA")][:pmt]) ≈ WNDCnat["PA.pmt","delas=0"]#  0.958374533466304
    @test JuMP.value(WiNnat._jump_model[Symbol("PA")][:trk]) ≈ WNDCnat["PA.trk","delas=0"]#  0.940931376144473
    @test JuMP.value(WiNnat._jump_model[Symbol("PA")][:fdd]) ≈ WNDCnat["PA.fdd","delas=0"]#  0.974149507995964
    # @test JuMP.value(WiNnat._jump_model[Symbol("PA")][:gmt]) ≈ WNDCnat["PA.gmt","delas=0"]#  1
    @test JuMP.value(WiNnat._jump_model[Symbol("PA")][:wtt]) ≈ WNDCnat["PA.wtt","delas=0"]#  0.946378878378482
    @test JuMP.value(WiNnat._jump_model[Symbol("PA")][:wpd]) ≈ WNDCnat["PA.wpd","delas=0"]#  0.943466452964732
    @test JuMP.value(WiNnat._jump_model[Symbol("PA")][:wht]) ≈ WNDCnat["PA.wht","delas=0"]#  0.973973514940118
    @test JuMP.value(WiNnat._jump_model[Symbol("PA")][:wrh]) ≈ WNDCnat["PA.wrh","delas=0"]#  0.966541101359892
    @test JuMP.value(WiNnat._jump_model[Symbol("PA")][:ott]) ≈ WNDCnat["PA.ott","delas=0"]#  0.973893652791651
    @test JuMP.value(WiNnat._jump_model[Symbol("PA")][:che]) ≈ WNDCnat["PA.che","delas=0"]#  0.944176796655244
    @test JuMP.value(WiNnat._jump_model[Symbol("PA")][:air]) ≈ WNDCnat["PA.air","delas=0"]#  0.853951457339014
    @test JuMP.value(WiNnat._jump_model[Symbol("PA")][:mmf]) ≈ WNDCnat["PA.mmf","delas=0"]#  0.932150543608111
    @test JuMP.value(WiNnat._jump_model[Symbol("PA")][:otr]) ≈ WNDCnat["PA.otr","delas=0"]#  0.959121965158609
    @test JuMP.value(WiNnat._jump_model[Symbol("PA")][:min]) ≈ WNDCnat["PA.min","delas=0"]#  0.9337776664743
    @test JuMP.value(WiNnat._jump_model[Symbol("PY")][:ppd]) ≈ WNDCnat["PY.ppd","delas=0"]#  0.956792715838143
    @test JuMP.value(WiNnat._jump_model[Symbol("PY")][:res]) ≈ WNDCnat["PY.res","delas=0"]#  0.966658926492167
    @test JuMP.value(WiNnat._jump_model[Symbol("PY")][:com]) ≈ WNDCnat["PY.com","delas=0"]#  0.979062089261254
    @test JuMP.value(WiNnat._jump_model[Symbol("PY")][:amb]) ≈ WNDCnat["PY.amb","delas=0"]#  0.975360089005644
    @test JuMP.value(WiNnat._jump_model[Symbol("PY")][:fbp]) ≈ WNDCnat["PY.fbp","delas=0"]#  0.954856775861678
    @test JuMP.value(WiNnat._jump_model[Symbol("PY")][:rec]) ≈ WNDCnat["PY.rec","delas=0"]#  0.967846619351907
    @test JuMP.value(WiNnat._jump_model[Symbol("PY")][:con]) ≈ WNDCnat["PY.con","delas=0"]#  0.961628798303551
    @test JuMP.value(WiNnat._jump_model[Symbol("PY")][:agr]) ≈ WNDCnat["PY.agr","delas=0"]#  0.958793009499625
    @test JuMP.value(WiNnat._jump_model[Symbol("PY")][:eec]) ≈ WNDCnat["PY.eec","delas=0"]#  0.966261139348885
    @test JuMP.value(WiNnat._jump_model[Symbol("PY")][:fnd]) ≈ WNDCnat["PY.fnd","delas=0"]#  0.978735209313508
    @test JuMP.value(WiNnat._jump_model[Symbol("PY")][:pub]) ≈ WNDCnat["PY.pub","delas=0"]#  0.979182673734003
    @test JuMP.value(WiNnat._jump_model[Symbol("PY")][:hou]) ≈ WNDCnat["PY.hou","delas=0"]#  0.985074412407487
    @test JuMP.value(WiNnat._jump_model[Symbol("PY")][:fbt]) ≈ WNDCnat["PY.fbt","delas=0"]#  0.974887404513812
    @test JuMP.value(WiNnat._jump_model[Symbol("PY")][:ins]) ≈ WNDCnat["PY.ins","delas=0"]#  0.970354622012185
    @test JuMP.value(WiNnat._jump_model[Symbol("PY")][:tex]) ≈ WNDCnat["PY.tex","delas=0"]#  0.954834196282788
    @test JuMP.value(WiNnat._jump_model[Symbol("PY")][:leg]) ≈ WNDCnat["PY.leg","delas=0"]#  0.978208688795886
    @test JuMP.value(WiNnat._jump_model[Symbol("PY")][:fen]) ≈ WNDCnat["PY.fen","delas=0"]#  0.973928759455097
    @test JuMP.value(WiNnat._jump_model[Symbol("PY")][:uti]) ≈ WNDCnat["PY.uti","delas=0"]#  0.963151569334982
    @test JuMP.value(WiNnat._jump_model[Symbol("PY")][:nmp]) ≈ WNDCnat["PY.nmp","delas=0"]#  0.963327800769308
    @test JuMP.value(WiNnat._jump_model[Symbol("PY")][:brd]) ≈ WNDCnat["PY.brd","delas=0"]#  0.963537345547161
    @test JuMP.value(WiNnat._jump_model[Symbol("PY")][:bnk]) ≈ WNDCnat["PY.bnk","delas=0"]#  0.977778253482725
    @test JuMP.value(WiNnat._jump_model[Symbol("PY")][:ore]) ≈ WNDCnat["PY.ore","delas=0"]#  0.964736218577388
    @test JuMP.value(WiNnat._jump_model[Symbol("PY")][:edu]) ≈ WNDCnat["PY.edu","delas=0"]#  0.976952920174631
    @test JuMP.value(WiNnat._jump_model[Symbol("PY")][:ote]) ≈ WNDCnat["PY.ote","delas=0"]#  0.969588573915453
    @test JuMP.value(WiNnat._jump_model[Symbol("PY")][:man]) ≈ WNDCnat["PY.man","delas=0"]#  0.975509483821164
    @test JuMP.value(WiNnat._jump_model[Symbol("PY")][:mch]) ≈ WNDCnat["PY.mch","delas=0"]#  0.964434809622883
    @test JuMP.value(WiNnat._jump_model[Symbol("PY")][:dat]) ≈ WNDCnat["PY.dat","delas=0"]#  0.97253494283897
    @test JuMP.value(WiNnat._jump_model[Symbol("PY")][:amd]) ≈ WNDCnat["PY.amd","delas=0"]#  0.969052319378871
    @test JuMP.value(WiNnat._jump_model[Symbol("PY")][:oil]) ≈ WNDCnat["PY.oil","delas=0"]#  0.971133839245036
    @test JuMP.value(WiNnat._jump_model[Symbol("PY")][:hos]) ≈ WNDCnat["PY.hos","delas=0"]#  0.970529301558178
    @test JuMP.value(WiNnat._jump_model[Symbol("PY")][:rnt]) ≈ WNDCnat["PY.rnt","delas=0"]#  0.977069926278026
    @test JuMP.value(WiNnat._jump_model[Symbol("PY")][:pla]) ≈ WNDCnat["PY.pla","delas=0"]#  0.957914996803299
    @test JuMP.value(WiNnat._jump_model[Symbol("PY")][:fof]) ≈ WNDCnat["PY.fof","delas=0"]#  0.974299563337718
    @test JuMP.value(WiNnat._jump_model[Symbol("PY")][:fin]) ≈ WNDCnat["PY.fin","delas=0"]#  0.969544754604155
    @test JuMP.value(WiNnat._jump_model[Symbol("PY")][:tsv]) ≈ WNDCnat["PY.tsv","delas=0"]#  0.975009673295218
    @test JuMP.value(WiNnat._jump_model[Symbol("PY")][:nrs]) ≈ WNDCnat["PY.nrs","delas=0"]#  0.969991614268573
    @test JuMP.value(WiNnat._jump_model[Symbol("PY")][:sec]) ≈ WNDCnat["PY.sec","delas=0"]#  0.97342173573989
    @test JuMP.value(WiNnat._jump_model[Symbol("PY")][:art]) ≈ WNDCnat["PY.art","delas=0"]#  0.976529030169516
    @test JuMP.value(WiNnat._jump_model[Symbol("PY")][:mov]) ≈ WNDCnat["PY.mov","delas=0"]#  0.974625051181186
    @test JuMP.value(WiNnat._jump_model[Symbol("PY")][:fpd]) ≈ WNDCnat["PY.fpd","delas=0"]#  0.959812821471709
    @test JuMP.value(WiNnat._jump_model[Symbol("PY")][:slg]) ≈ WNDCnat["PY.slg","delas=0"]#  0.968358481331393
    @test JuMP.value(WiNnat._jump_model[Symbol("PY")][:pri]) ≈ WNDCnat["PY.pri","delas=0"]#  0.961223409030763
    @test JuMP.value(WiNnat._jump_model[Symbol("PY")][:grd]) ≈ WNDCnat["PY.grd","delas=0"]#  0.971056764148964
    @test JuMP.value(WiNnat._jump_model[Symbol("PY")][:pip]) ≈ WNDCnat["PY.pip","delas=0"]#  0.982765720409024
    @test JuMP.value(WiNnat._jump_model[Symbol("PY")][:sle]) ≈ WNDCnat["PY.sle","delas=0"]#  0.950692169697937
    @test JuMP.value(WiNnat._jump_model[Symbol("PY")][:osv]) ≈ WNDCnat["PY.osv","delas=0"]#  0.972266365835301
    @test JuMP.value(WiNnat._jump_model[Symbol("PY")][:trn]) ≈ WNDCnat["PY.trn","delas=0"]#  0.960853177432763
    @test JuMP.value(WiNnat._jump_model[Symbol("PY")][:smn]) ≈ WNDCnat["PY.smn","delas=0"]#  0.965186454635132
    @test JuMP.value(WiNnat._jump_model[Symbol("PY")][:fmt]) ≈ WNDCnat["PY.fmt","delas=0"]#  0.967934476021085
    @test JuMP.value(WiNnat._jump_model[Symbol("PY")][:pet]) ≈ WNDCnat["PY.pet","delas=0"]#  0.95090734150171
    @test JuMP.value(WiNnat._jump_model[Symbol("PY")][:mvt]) ≈ WNDCnat["PY.mvt","delas=0"]#  0.976135119587273
    @test JuMP.value(WiNnat._jump_model[Symbol("PY")][:cep]) ≈ WNDCnat["PY.cep","delas=0"]#  0.982444249688533
    @test JuMP.value(WiNnat._jump_model[Symbol("PY")][:wst]) ≈ WNDCnat["PY.wst","delas=0"]#  0.967101417684808
    @test JuMP.value(WiNnat._jump_model[Symbol("PY")][:mot]) ≈ WNDCnat["PY.mot","delas=0"]#  0.949160347406224
    @test JuMP.value(WiNnat._jump_model[Symbol("PY")][:adm]) ≈ WNDCnat["PY.adm","delas=0"]#  0.97234771138567
    @test JuMP.value(WiNnat._jump_model[Symbol("PY")][:soc]) ≈ WNDCnat["PY.soc","delas=0"]#  0.970182119024674
    @test JuMP.value(WiNnat._jump_model[Symbol("PY")][:alt]) ≈ WNDCnat["PY.alt","delas=0"]#  0.956355540362678
    @test JuMP.value(WiNnat._jump_model[Symbol("PY")][:pmt]) ≈ WNDCnat["PY.pmt","delas=0"]#  0.961264065170689
    @test JuMP.value(WiNnat._jump_model[Symbol("PY")][:trk]) ≈ WNDCnat["PY.trk","delas=0"]#  0.95176491870528
    @test JuMP.value(WiNnat._jump_model[Symbol("PY")][:fdd]) ≈ WNDCnat["PY.fdd","delas=0"]#  0.974149507995964
    @test JuMP.value(WiNnat._jump_model[Symbol("PY")][:gmt]) ≈ WNDCnat["PY.gmt","delas=0"]#  0.975054414528506
    @test JuMP.value(WiNnat._jump_model[Symbol("PY")][:wtt]) ≈ WNDCnat["PY.wtt","delas=0"]#  0.955998169561914
    @test JuMP.value(WiNnat._jump_model[Symbol("PY")][:wpd]) ≈ WNDCnat["PY.wpd","delas=0"]#  0.961003943715435
    @test JuMP.value(WiNnat._jump_model[Symbol("PY")][:wht]) ≈ WNDCnat["PY.wht","delas=0"]#  0.973894387535495
    @test JuMP.value(WiNnat._jump_model[Symbol("PY")][:wrh]) ≈ WNDCnat["PY.wrh","delas=0"]#  0.967702169555874
    @test JuMP.value(WiNnat._jump_model[Symbol("PY")][:ott]) ≈ WNDCnat["PY.ott","delas=0"]#  0.973893652791651
    @test JuMP.value(WiNnat._jump_model[Symbol("PY")][:che]) ≈ WNDCnat["PY.che","delas=0"]#  0.96204513129435
    @test JuMP.value(WiNnat._jump_model[Symbol("PY")][:air]) ≈ WNDCnat["PY.air","delas=0"]#  0.951831466519571
    @test JuMP.value(WiNnat._jump_model[Symbol("PY")][:mmf]) ≈ WNDCnat["PY.mmf","delas=0"]#  0.969069627087884
    @test JuMP.value(WiNnat._jump_model[Symbol("PY")][:otr]) ≈ WNDCnat["PY.otr","delas=0"]#  0.960930067711432
    @test JuMP.value(WiNnat._jump_model[Symbol("PY")][:min]) ≈ WNDCnat["PY.min","delas=0"]#  0.962909289551694
    @test JuMP.value(WiNnat._jump_model[Symbol("PVA")][:compen]) ≈ WNDCnat["PVA.compen","delas=0"]#  0.987058107194174
    @test JuMP.value(WiNnat._jump_model[Symbol("PVA")][:surplus]) ≈ WNDCnat["PVA.surplus","delas=0"]#  0.987738426310087
    @test JuMP.value(WiNnat._jump_model[Symbol("PM")][:trn]) ≈ WNDCnat["PM.trn","delas=0"]#  0.956766602494605
    @test JuMP.value(WiNnat._jump_model[Symbol("PM")][:trd]) ≈ WNDCnat["PM.trd","delas=0"]#  0.974162073506261
    @test JuMP.value(WiNnat._jump_model[Symbol("PFX")]) ≈ WNDCnat["PFX.missing","delas=0"]#  0.970531966783069
    @test JuMP.value(WiNnat._jump_model[Symbol("RA")]) ≈ WNDCnat["RA.missing","delas=0"]#  12453.8764709011
    
    set_value(d_elas_ra, 0.5)
    set_value(RA, 12453.8764709011)
    set_fixed!(RA, true)
    solve!(WiNnat, convergence_tolerance=1e-6, cumulative_iteration_limit=10000);
    
    # delas=0.5
    @test JuMP.value(WiNnat._jump_model[Symbol("Y")][:ppd]) ≈ WNDCnat["Y.ppd","delas=0.5"]#  1.01243676672209
    @test JuMP.value(WiNnat._jump_model[Symbol("Y")][:res]) ≈ WNDCnat["Y.res","delas=0.5"]#  1.01988597601756
    @test JuMP.value(WiNnat._jump_model[Symbol("Y")][:com]) ≈ WNDCnat["Y.com","delas=0.5"]#  0.998357459839861
    @test JuMP.value(WiNnat._jump_model[Symbol("Y")][:amb]) ≈ WNDCnat["Y.amb","delas=0.5"]#  0.985097164034131
    @test JuMP.value(WiNnat._jump_model[Symbol("Y")][:fbp]) ≈ WNDCnat["Y.fbp","delas=0.5"]#  1.02318805328515
    @test JuMP.value(WiNnat._jump_model[Symbol("Y")][:rec]) ≈ WNDCnat["Y.rec","delas=0.5"]#  1.01310336651876
    @test JuMP.value(WiNnat._jump_model[Symbol("Y")][:con]) ≈ WNDCnat["Y.con","delas=0.5"]#  0.999395887634254
    @test JuMP.value(WiNnat._jump_model[Symbol("Y")][:agr]) ≈ WNDCnat["Y.agr","delas=0.5"]#  1.01644798491717
    @test JuMP.value(WiNnat._jump_model[Symbol("Y")][:eec]) ≈ WNDCnat["Y.eec","delas=0.5"]#  0.989975970504904
    @test JuMP.value(WiNnat._jump_model[Symbol("Y")][:fnd]) ≈ WNDCnat["Y.fnd","delas=0.5"]#  1
    @test JuMP.value(WiNnat._jump_model[Symbol("Y")][:pub]) ≈ WNDCnat["Y.pub","delas=0.5"]#  0.996421056594617
    @test JuMP.value(WiNnat._jump_model[Symbol("Y")][:hou]) ≈ WNDCnat["Y.hou","delas=0.5"]#  0.97239492264923
    @test JuMP.value(WiNnat._jump_model[Symbol("Y")][:fbt]) ≈ WNDCnat["Y.fbt","delas=0.5"]#  1.01259002967415
    @test JuMP.value(WiNnat._jump_model[Symbol("Y")][:ins]) ≈ WNDCnat["Y.ins","delas=0.5"]#  0.997966168822418
    @test JuMP.value(WiNnat._jump_model[Symbol("Y")][:tex]) ≈ WNDCnat["Y.tex","delas=0.5"]#  0.974610499448548
    @test JuMP.value(WiNnat._jump_model[Symbol("Y")][:leg]) ≈ WNDCnat["Y.leg","delas=0.5"]#  1.00236064390243
    @test JuMP.value(WiNnat._jump_model[Symbol("Y")][:fen]) ≈ WNDCnat["Y.fen","delas=0.5"]#  1.00263877847833
    @test JuMP.value(WiNnat._jump_model[Symbol("Y")][:uti]) ≈ WNDCnat["Y.uti","delas=0.5"]#  1.01421165005993
    @test JuMP.value(WiNnat._jump_model[Symbol("Y")][:nmp]) ≈ WNDCnat["Y.nmp","delas=0.5"]#  0.994961995841088
    @test JuMP.value(WiNnat._jump_model[Symbol("Y")][:brd]) ≈ WNDCnat["Y.brd","delas=0.5"]#  1.01163988478686
    @test JuMP.value(WiNnat._jump_model[Symbol("Y")][:bnk]) ≈ WNDCnat["Y.bnk","delas=0.5"]#  0.990349347083891
    @test JuMP.value(WiNnat._jump_model[Symbol("Y")][:ore]) ≈ WNDCnat["Y.ore","delas=0.5"]#  1.00251307694888
    @test JuMP.value(WiNnat._jump_model[Symbol("Y")][:edu]) ≈ WNDCnat["Y.edu","delas=0.5"]#  0.98123437658592
    @test JuMP.value(WiNnat._jump_model[Symbol("Y")][:ote]) ≈ WNDCnat["Y.ote","delas=0.5"]#  1.0015930889444
    @test JuMP.value(WiNnat._jump_model[Symbol("Y")][:man]) ≈ WNDCnat["Y.man","delas=0.5"]#  1.00813373330034
    @test JuMP.value(WiNnat._jump_model[Symbol("Y")][:mch]) ≈ WNDCnat["Y.mch","delas=0.5"]#  1.00356199425038
    @test JuMP.value(WiNnat._jump_model[Symbol("Y")][:dat]) ≈ WNDCnat["Y.dat","delas=0.5"]#  0.998548168433061
    @test JuMP.value(WiNnat._jump_model[Symbol("Y")][:amd]) ≈ WNDCnat["Y.amd","delas=0.5"]#  1.02848814483197
    @test JuMP.value(WiNnat._jump_model[Symbol("Y")][:oil]) ≈ WNDCnat["Y.oil","delas=0.5"]#  1.04054785057702
    @test JuMP.value(WiNnat._jump_model[Symbol("Y")][:hos]) ≈ WNDCnat["Y.hos","delas=0.5"]#  0.985553557159185
    @test JuMP.value(WiNnat._jump_model[Symbol("Y")][:rnt]) ≈ WNDCnat["Y.rnt","delas=0.5"]#  1.00840868669164
    @test JuMP.value(WiNnat._jump_model[Symbol("Y")][:pla]) ≈ WNDCnat["Y.pla","delas=0.5"]#  1.00263350861923
    @test JuMP.value(WiNnat._jump_model[Symbol("Y")][:fof]) ≈ WNDCnat["Y.fof","delas=0.5"]#  1.00566785073444
    @test JuMP.value(WiNnat._jump_model[Symbol("Y")][:fin]) ≈ WNDCnat["Y.fin","delas=0.5"]#  0.986841711447615
    @test JuMP.value(WiNnat._jump_model[Symbol("Y")][:tsv]) ≈ WNDCnat["Y.tsv","delas=0.5"]#  1.00034535996551
    @test JuMP.value(WiNnat._jump_model[Symbol("Y")][:nrs]) ≈ WNDCnat["Y.nrs","delas=0.5"]#  0.993876986225821
    @test JuMP.value(WiNnat._jump_model[Symbol("Y")][:sec]) ≈ WNDCnat["Y.sec","delas=0.5"]#  0.990887207357132
    @test JuMP.value(WiNnat._jump_model[Symbol("Y")][:art]) ≈ WNDCnat["Y.art","delas=0.5"]#  1.00322784203326
    @test JuMP.value(WiNnat._jump_model[Symbol("Y")][:mov]) ≈ WNDCnat["Y.mov","delas=0.5"]#  1.00253668803782
    @test JuMP.value(WiNnat._jump_model[Symbol("Y")][:fpd]) ≈ WNDCnat["Y.fpd","delas=0.5"]#  1.01366546527586
    @test JuMP.value(WiNnat._jump_model[Symbol("Y")][:slg]) ≈ WNDCnat["Y.slg","delas=0.5"]#  1
    @test JuMP.value(WiNnat._jump_model[Symbol("Y")][:pri]) ≈ WNDCnat["Y.pri","delas=0.5"]#  1.00277548202722
    @test JuMP.value(WiNnat._jump_model[Symbol("Y")][:grd]) ≈ WNDCnat["Y.grd","delas=0.5"]#  0.995708639842001
    @test JuMP.value(WiNnat._jump_model[Symbol("Y")][:pip]) ≈ WNDCnat["Y.pip","delas=0.5"]#  1.01548018613236
    @test JuMP.value(WiNnat._jump_model[Symbol("Y")][:sle]) ≈ WNDCnat["Y.sle","delas=0.5"]#  0.999134023218203
    @test JuMP.value(WiNnat._jump_model[Symbol("Y")][:osv]) ≈ WNDCnat["Y.osv","delas=0.5"]#  0.996735662574078
    @test JuMP.value(WiNnat._jump_model[Symbol("Y")][:trn]) ≈ WNDCnat["Y.trn","delas=0.5"]#  1.01248674745598
    @test JuMP.value(WiNnat._jump_model[Symbol("Y")][:smn]) ≈ WNDCnat["Y.smn","delas=0.5"]#  0.984385184623502
    @test JuMP.value(WiNnat._jump_model[Symbol("Y")][:fmt]) ≈ WNDCnat["Y.fmt","delas=0.5"]#  0.997882112422253
    @test JuMP.value(WiNnat._jump_model[Symbol("Y")][:pet]) ≈ WNDCnat["Y.pet","delas=0.5"]#  1.04578927053345
    @test JuMP.value(WiNnat._jump_model[Symbol("Y")][:mvt]) ≈ WNDCnat["Y.mvt","delas=0.5"]#  1.01247340694856
    @test JuMP.value(WiNnat._jump_model[Symbol("Y")][:cep]) ≈ WNDCnat["Y.cep","delas=0.5"]#  0.984030689369513
    @test JuMP.value(WiNnat._jump_model[Symbol("Y")][:wst]) ≈ WNDCnat["Y.wst","delas=0.5"]#  1.00186758476926
    @test JuMP.value(WiNnat._jump_model[Symbol("Y")][:mot]) ≈ WNDCnat["Y.mot","delas=0.5"]#  1.01863694578436
    @test JuMP.value(WiNnat._jump_model[Symbol("Y")][:adm]) ≈ WNDCnat["Y.adm","delas=0.5"]#  1.00142859539338
    @test JuMP.value(WiNnat._jump_model[Symbol("Y")][:soc]) ≈ WNDCnat["Y.soc","delas=0.5"]#  0.989411138455745
    @test JuMP.value(WiNnat._jump_model[Symbol("Y")][:alt]) ≈ WNDCnat["Y.alt","delas=0.5"]#  0.814008535651438
    @test JuMP.value(WiNnat._jump_model[Symbol("Y")][:pmt]) ≈ WNDCnat["Y.pmt","delas=0.5"]#  1.0126612383107
    @test JuMP.value(WiNnat._jump_model[Symbol("Y")][:trk]) ≈ WNDCnat["Y.trk","delas=0.5"]#  1.01479977203563
    @test JuMP.value(WiNnat._jump_model[Symbol("Y")][:fdd]) ≈ WNDCnat["Y.fdd","delas=0.5"]#  1
    @test JuMP.value(WiNnat._jump_model[Symbol("Y")][:gmt]) ≈ WNDCnat["Y.gmt","delas=0.5"]#  1.01248373473656
    @test JuMP.value(WiNnat._jump_model[Symbol("Y")][:wtt]) ≈ WNDCnat["Y.wtt","delas=0.5"]#  1.01036613884684
    @test JuMP.value(WiNnat._jump_model[Symbol("Y")][:wpd]) ≈ WNDCnat["Y.wpd","delas=0.5"]#  1.00405332945149
    @test JuMP.value(WiNnat._jump_model[Symbol("Y")][:wht]) ≈ WNDCnat["Y.wht","delas=0.5"]#  1.01247943081767
    @test JuMP.value(WiNnat._jump_model[Symbol("Y")][:wrh]) ≈ WNDCnat["Y.wrh","delas=0.5"]#  1.00990645546212
    @test JuMP.value(WiNnat._jump_model[Symbol("Y")][:ott]) ≈ WNDCnat["Y.ott","delas=0.5"]#  1.01268633136744
    @test JuMP.value(WiNnat._jump_model[Symbol("Y")][:che]) ≈ WNDCnat["Y.che","delas=0.5"]#  1.00378197892127
    @test JuMP.value(WiNnat._jump_model[Symbol("Y")][:air]) ≈ WNDCnat["Y.air","delas=0.5"]#  1.04904035477477
    @test JuMP.value(WiNnat._jump_model[Symbol("Y")][:mmf]) ≈ WNDCnat["Y.mmf","delas=0.5"]#  0.993235621486512
    @test JuMP.value(WiNnat._jump_model[Symbol("Y")][:otr]) ≈ WNDCnat["Y.otr","delas=0.5"]#  1.01313067892542
    @test JuMP.value(WiNnat._jump_model[Symbol("Y")][:min]) ≈ WNDCnat["Y.min","delas=0.5"]#  1.01065794826323
    @test JuMP.value(WiNnat._jump_model[Symbol("A")][:ppd]) ≈ WNDCnat["A.ppd","delas=0.5"]#  1.00995102143583
    @test JuMP.value(WiNnat._jump_model[Symbol("A")][:res]) ≈ WNDCnat["A.res","delas=0.5"]#  1.0186642125745
    @test JuMP.value(WiNnat._jump_model[Symbol("A")][:com]) ≈ WNDCnat["A.com","delas=0.5"]#  1.00006903401578
    @test JuMP.value(WiNnat._jump_model[Symbol("A")][:amb]) ≈ WNDCnat["A.amb","delas=0.5"]#  0.985636876656064
    @test JuMP.value(WiNnat._jump_model[Symbol("A")][:fbp]) ≈ WNDCnat["A.fbp","delas=0.5"]#  1.02169915520047
    @test JuMP.value(WiNnat._jump_model[Symbol("A")][:rec]) ≈ WNDCnat["A.rec","delas=0.5"]#  1.01305192001064
    @test JuMP.value(WiNnat._jump_model[Symbol("A")][:con]) ≈ WNDCnat["A.con","delas=0.5"]#  0.999286302451195
    @test JuMP.value(WiNnat._jump_model[Symbol("A")][:agr]) ≈ WNDCnat["A.agr","delas=0.5"]#  1.01392324038891
    @test JuMP.value(WiNnat._jump_model[Symbol("A")][:eec]) ≈ WNDCnat["A.eec","delas=0.5"]#  1.00467254607232
    @test JuMP.value(WiNnat._jump_model[Symbol("A")][:fnd]) ≈ WNDCnat["A.fnd","delas=0.5"]#  1
    @test JuMP.value(WiNnat._jump_model[Symbol("A")][:pub]) ≈ WNDCnat["A.pub","delas=0.5"]#  0.996779968938176
    @test JuMP.value(WiNnat._jump_model[Symbol("A")][:hou]) ≈ WNDCnat["A.hou","delas=0.5"]#  0.972740417586429
    # @test JuMP.value(WiNnat._jump_model[Symbol("A")][:fbt]) ≈ WNDCnat["A.fbt","delas=0.5"]#  1
    @test JuMP.value(WiNnat._jump_model[Symbol("A")][:ins]) ≈ WNDCnat["A.ins","delas=0.5"]#  0.997827384586593
    @test JuMP.value(WiNnat._jump_model[Symbol("A")][:tex]) ≈ WNDCnat["A.tex","delas=0.5"]#  1.01187871537137
    @test JuMP.value(WiNnat._jump_model[Symbol("A")][:leg]) ≈ WNDCnat["A.leg","delas=0.5"]#  1.00250270879963
    @test JuMP.value(WiNnat._jump_model[Symbol("A")][:fen]) ≈ WNDCnat["A.fen","delas=0.5"]#  1.00264304777137
    @test JuMP.value(WiNnat._jump_model[Symbol("A")][:uti]) ≈ WNDCnat["A.uti","delas=0.5"]#  1.01052675062657
    @test JuMP.value(WiNnat._jump_model[Symbol("A")][:nmp]) ≈ WNDCnat["A.nmp","delas=0.5"]#  1.00342639060623
    @test JuMP.value(WiNnat._jump_model[Symbol("A")][:brd]) ≈ WNDCnat["A.brd","delas=0.5"]#  1.01163385236238
    @test JuMP.value(WiNnat._jump_model[Symbol("A")][:bnk]) ≈ WNDCnat["A.bnk","delas=0.5"]#  0.990512368289017
    @test JuMP.value(WiNnat._jump_model[Symbol("A")][:ore]) ≈ WNDCnat["A.ore","delas=0.5"]#  1.00247560580001
    @test JuMP.value(WiNnat._jump_model[Symbol("A")][:edu]) ≈ WNDCnat["A.edu","delas=0.5"]#  0.986371396728823
    @test JuMP.value(WiNnat._jump_model[Symbol("A")][:ote]) ≈ WNDCnat["A.ote","delas=0.5"]#  1.00237101071941
    @test JuMP.value(WiNnat._jump_model[Symbol("A")][:man]) ≈ WNDCnat["A.man","delas=0.5"]#  1.00813373330034
    @test JuMP.value(WiNnat._jump_model[Symbol("A")][:mch]) ≈ WNDCnat["A.mch","delas=0.5"]#  1.00472731195032
    @test JuMP.value(WiNnat._jump_model[Symbol("A")][:dat]) ≈ WNDCnat["A.dat","delas=0.5"]#  0.998458073271863
    @test JuMP.value(WiNnat._jump_model[Symbol("A")][:amd]) ≈ WNDCnat["A.amd","delas=0.5"]#  1.02107320620759
    @test JuMP.value(WiNnat._jump_model[Symbol("A")][:oil]) ≈ WNDCnat["A.oil","delas=0.5"]#  1.0398956433845
    @test JuMP.value(WiNnat._jump_model[Symbol("A")][:hos]) ≈ WNDCnat["A.hos","delas=0.5"]#  0.988467046116498
    @test JuMP.value(WiNnat._jump_model[Symbol("A")][:rnt]) ≈ WNDCnat["A.rnt","delas=0.5"]#  1.00523696640568
    @test JuMP.value(WiNnat._jump_model[Symbol("A")][:pla]) ≈ WNDCnat["A.pla","delas=0.5"]#  1.00821966079609
    @test JuMP.value(WiNnat._jump_model[Symbol("A")][:fof]) ≈ WNDCnat["A.fof","delas=0.5"]#  1.00859952645722
    @test JuMP.value(WiNnat._jump_model[Symbol("A")][:fin]) ≈ WNDCnat["A.fin","delas=0.5"]#  0.988894183313094
    @test JuMP.value(WiNnat._jump_model[Symbol("A")][:tsv]) ≈ WNDCnat["A.tsv","delas=0.5"]#  1.00073177759008
    @test JuMP.value(WiNnat._jump_model[Symbol("A")][:nrs]) ≈ WNDCnat["A.nrs","delas=0.5"]#  0.993831917665359
    @test JuMP.value(WiNnat._jump_model[Symbol("A")][:sec]) ≈ WNDCnat["A.sec","delas=0.5"]#  0.990877043763559
    @test JuMP.value(WiNnat._jump_model[Symbol("A")][:art]) ≈ WNDCnat["A.art","delas=0.5"]#  1.00326917610518
    @test JuMP.value(WiNnat._jump_model[Symbol("A")][:mov]) ≈ WNDCnat["A.mov","delas=0.5"]#  1.00295491637687
    @test JuMP.value(WiNnat._jump_model[Symbol("A")][:fpd]) ≈ WNDCnat["A.fpd","delas=0.5"]#  1.00581404880909
    @test JuMP.value(WiNnat._jump_model[Symbol("A")][:slg]) ≈ WNDCnat["A.slg","delas=0.5"]#  1
    @test JuMP.value(WiNnat._jump_model[Symbol("A")][:pri]) ≈ WNDCnat["A.pri","delas=0.5"]#  1.00171498070511
    @test JuMP.value(WiNnat._jump_model[Symbol("A")][:grd]) ≈ WNDCnat["A.grd","delas=0.5"]#  0.996410010461494
    @test JuMP.value(WiNnat._jump_model[Symbol("A")][:pip]) ≈ WNDCnat["A.pip","delas=0.5"] atol=1.0e-7 #  1.02328548396755
    @test JuMP.value(WiNnat._jump_model[Symbol("A")][:sle]) ≈ WNDCnat["A.sle","delas=0.5"]#  0.999389927007246
    @test JuMP.value(WiNnat._jump_model[Symbol("A")][:osv]) ≈ WNDCnat["A.osv","delas=0.5"]#  1.0000210940405
    @test JuMP.value(WiNnat._jump_model[Symbol("A")][:trn]) ≈ WNDCnat["A.trn","delas=0.5"]#  0.995116615781495
    @test JuMP.value(WiNnat._jump_model[Symbol("A")][:smn]) ≈ WNDCnat["A.smn","delas=0.5"]#  1.00404400644595
    @test JuMP.value(WiNnat._jump_model[Symbol("A")][:fmt]) ≈ WNDCnat["A.fmt","delas=0.5"]#  1.00532856239972
    @test JuMP.value(WiNnat._jump_model[Symbol("A")][:pet]) ≈ WNDCnat["A.pet","delas=0.5"]#  1.04116741918214
    # @test JuMP.value(WiNnat._jump_model[Symbol("A")][:mvt]) ≈ WNDCnat["A.mvt","delas=0.5"]#  1
    @test JuMP.value(WiNnat._jump_model[Symbol("A")][:cep]) ≈ WNDCnat["A.cep","delas=0.5"]#  0.998653134088926
    @test JuMP.value(WiNnat._jump_model[Symbol("A")][:wst]) ≈ WNDCnat["A.wst","delas=0.5"]#  1.00186350559656
    @test JuMP.value(WiNnat._jump_model[Symbol("A")][:mot]) ≈ WNDCnat["A.mot","delas=0.5"]#  1.01131721833419
    @test JuMP.value(WiNnat._jump_model[Symbol("A")][:adm]) ≈ WNDCnat["A.adm","delas=0.5"]#  1.00142621852353
    @test JuMP.value(WiNnat._jump_model[Symbol("A")][:soc]) ≈ WNDCnat["A.soc","delas=0.5"]#  0.989698429646106
    @test JuMP.value(WiNnat._jump_model[Symbol("A")][:alt]) ≈ WNDCnat["A.alt","delas=0.5"]#  1.03892356791105
    @test JuMP.value(WiNnat._jump_model[Symbol("A")][:pmt]) ≈ WNDCnat["A.pmt","delas=0.5"]#  1.00885505257068
    @test JuMP.value(WiNnat._jump_model[Symbol("A")][:trk]) ≈ WNDCnat["A.trk","delas=0.5"]#  1.01070649923203
    @test JuMP.value(WiNnat._jump_model[Symbol("A")][:fdd]) ≈ WNDCnat["A.fdd","delas=0.5"]#  1
    # @test JuMP.value(WiNnat._jump_model[Symbol("A")][:gmt]) ≈ WNDCnat["A.gmt","delas=0.5"]#  1
    @test JuMP.value(WiNnat._jump_model[Symbol("A")][:wtt]) ≈ WNDCnat["A.wtt","delas=0.5"]#  1.00680656426112
    @test JuMP.value(WiNnat._jump_model[Symbol("A")][:wpd]) ≈ WNDCnat["A.wpd","delas=0.5"]#  1.00416021405889
    @test JuMP.value(WiNnat._jump_model[Symbol("A")][:wht]) ≈ WNDCnat["A.wht","delas=0.5"]#  1.01025813822442
    @test JuMP.value(WiNnat._jump_model[Symbol("A")][:wrh]) ≈ WNDCnat["A.wrh","delas=0.5"]#  1.01010472217285
    @test JuMP.value(WiNnat._jump_model[Symbol("A")][:ott]) ≈ WNDCnat["A.ott","delas=0.5"]#  0.992613210099542
    @test JuMP.value(WiNnat._jump_model[Symbol("A")][:che]) ≈ WNDCnat["A.che","delas=0.5"]#  1.00443188613084
    @test JuMP.value(WiNnat._jump_model[Symbol("A")][:air]) ≈ WNDCnat["A.air","delas=0.5"]#  1.04206464412903
    @test JuMP.value(WiNnat._jump_model[Symbol("A")][:mmf]) ≈ WNDCnat["A.mmf","delas=0.5"]#  1.00407319647858
    @test JuMP.value(WiNnat._jump_model[Symbol("A")][:otr]) ≈ WNDCnat["A.otr","delas=0.5"]#  1.01237698718806
    @test JuMP.value(WiNnat._jump_model[Symbol("A")][:min]) ≈ WNDCnat["A.min","delas=0.5"]#  1.01021085069484
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[ppd]ρRA")]) ≈ WNDCnat["DPARA.ppd","delas=0.5"]#  45.0601240268544
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[res]ρRA")]) ≈ WNDCnat["DPARA.res","delas=0.5"]#  757.159852022435
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[amb]ρRA")]) ≈ WNDCnat["DPARA.amb","delas=0.5"]#  1036.26147061985
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[fbp]ρRA")]) ≈ WNDCnat["DPARA.fbp","delas=0.5"]#  1056.76295080827
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[rec]ρRA")]) ≈ WNDCnat["DPARA.rec","delas=0.5"]#  201.622836574546
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[agr]ρRA")]) ≈ WNDCnat["DPARA.agr","delas=0.5"]#  146.243621187287
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[eec]ρRA")]) ≈ WNDCnat["DPARA.eec","delas=0.5"]#  86.797819897891
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[pub]ρRA")]) ≈ WNDCnat["DPARA.pub","delas=0.5"]#  130.040069459569
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[hou]ρRA")]) ≈ WNDCnat["DPARA.hou","delas=0.5"]#  1979.63604680992
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[ins]ρRA")]) ≈ WNDCnat["DPARA.ins","delas=0.5"]#  385.566129845515
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[tex]ρRA")]) ≈ WNDCnat["DPARA.tex","delas=0.5"]#  74.1659091322046
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[leg]ρRA")]) ≈ WNDCnat["DPARA.leg","delas=0.5"]#  105.577046670679
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[fen]ρRA")]) ≈ WNDCnat["DPARA.fen","delas=0.5"]#  6.06867376929024
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[uti]ρRA")]) ≈ WNDCnat["DPARA.uti","delas=0.5"]#  268.845203837184
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[nmp]ρRA")]) ≈ WNDCnat["DPARA.nmp","delas=0.5"]#  20.9808628913747
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[brd]ρRA")]) ≈ WNDCnat["DPARA.brd","delas=0.5"]#  337.157926326524
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[bnk]ρRA")]) ≈ WNDCnat["DPARA.bnk","delas=0.5"]#  274.89115487289
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[ore]ρRA")]) ≈ WNDCnat["DPARA.ore","delas=0.5"]#  5.5803628866489
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[edu]ρRA")]) ≈ WNDCnat["DPARA.edu","delas=0.5"]#  346.338341665916
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[ote]ρRA")]) ≈ WNDCnat["DPARA.ote","delas=0.5"]#  32.3881248792287
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[mch]ρRA")]) ≈ WNDCnat["DPARA.mch","delas=0.5"]#  24.1116591528413
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[dat]ρRA")]) ≈ WNDCnat["DPARA.dat","delas=0.5"]#  55.0248135435681
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[amd]ρRA")]) ≈ WNDCnat["DPARA.amd","delas=0.5"]#  162.283228323791
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[hos]ρRA")]) ≈ WNDCnat["DPARA.hos","delas=0.5"]#  1054.16888132703
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[rnt]ρRA")]) ≈ WNDCnat["DPARA.rnt","delas=0.5"]#  106.208566618766
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[pla]ρRA")]) ≈ WNDCnat["DPARA.pla","delas=0.5"]#  67.7954100210675
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[fof]ρRA")]) ≈ WNDCnat["DPARA.fof","delas=0.5"]#  11.6825512065375
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[fin]ρRA")]) ≈ WNDCnat["DPARA.fin","delas=0.5"]#  160.488498183504
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[tsv]ρRA")]) ≈ WNDCnat["DPARA.tsv","delas=0.5"]#  71.843019788449
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[nrs]ρRA")]) ≈ WNDCnat["DPARA.nrs","delas=0.5"]#  240.782367299231
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[sec]ρRA")]) ≈ WNDCnat["DPARA.sec","delas=0.5"]#  221.599693829797
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[art]ρRA")]) ≈ WNDCnat["DPARA.art","delas=0.5"]#  78.332736118235
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[mov]ρRA")]) ≈ WNDCnat["DPARA.mov","delas=0.5"]#  32.4892083513815
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[fpd]ρRA")]) ≈ WNDCnat["DPARA.fpd","delas=0.5"]#  121.062232092821
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[pri]ρRA")]) ≈ WNDCnat["DPARA.pri","delas=0.5"]#  8.40015228867906
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[grd]ρRA")]) ≈ WNDCnat["DPARA.grd","delas=0.5"]#  45.5828317793725
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[sle]ρRA")]) ≈ WNDCnat["DPARA.sle","delas=0.5"]#  70.6524090594336
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[osv]ρRA")]) ≈ WNDCnat["DPARA.osv","delas=0.5"]#  614.384644587196
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[trn]ρRA")]) ≈ WNDCnat["DPARA.trn","delas=0.5"]#  1.37381536268478
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[fmt]ρRA")]) ≈ WNDCnat["DPARA.fmt","delas=0.5"]#  40.7257821156265
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[pet]ρRA")]) ≈ WNDCnat["DPARA.pet","delas=0.5"]#  333.867745419442
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[cep]ρRA")]) ≈ WNDCnat["DPARA.cep","delas=0.5"]#  163.759555533644
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[wst]ρRA")]) ≈ WNDCnat["DPARA.wst","delas=0.5"]#  26.9531426343918
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[mot]ρRA")]) ≈ WNDCnat["DPARA.mot","delas=0.5"]#  341.464580579289
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[adm]ρRA")]) ≈ WNDCnat["DPARA.adm","delas=0.5"]#  63.2880744886363
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[soc]ρRA")]) ≈ WNDCnat["DPARA.soc","delas=0.5"]#  208.320131495183
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[alt]ρRA")]) ≈ WNDCnat["DPARA.alt","delas=0.5"]#  415.991408372126
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[pmt]ρRA")]) ≈ WNDCnat["DPARA.pmt","delas=0.5"]#  1.7298687899749
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[trk]ρRA")]) ≈ WNDCnat["DPARA.trk","delas=0.5"]#  12.3315496707354
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[wtt]ρRA")]) ≈ WNDCnat["DPARA.wtt","delas=0.5"]#  21.4185797442208
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[wpd]ρRA")]) ≈ WNDCnat["DPARA.wpd","delas=0.5"]#  7.90974168013956
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[wrh]ρRA")]) ≈ WNDCnat["DPARA.wrh","delas=0.5"] atol=1.0e-8 #  0.0864360974265916
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[ott]ρRA")]) ≈ WNDCnat["DPARA.ott","delas=0.5"]#  5.39308235257145
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[che]ρRA")]) ≈ WNDCnat["DPARA.che","delas=0.5"]#  631.55244405337
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[air]ρRA")]) ≈ WNDCnat["DPARA.air","delas=0.5"]#  136.190640936229
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[mmf]ρRA")]) ≈ WNDCnat["DPARA.mmf","delas=0.5"]#  266.752381548512
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[otr]ρRA")]) ≈ WNDCnat["DPARA.otr","delas=0.5"]#  23.1992665259564
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[min]ρRA")]) ≈ WNDCnat["DPARA.min","delas=0.5"] atol=1.0e-7#  0.648907418888096
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[ppd]‡A[ppd]")]) ≈ WNDCnat["SPAA.ppd","delas=0.5"]#  237.042258809771
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[res]‡A[res]")]) ≈ WNDCnat["SPAA.res","delas=0.5"]#  959.30920358167
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[com]‡A[com]")]) ≈ WNDCnat["SPAA.com","delas=0.5"]#  525.381541371094
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[amb]‡A[amb]")]) ≈ WNDCnat["SPAA.amb","delas=0.5"]#  1093.38052789571
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[fbp]‡A[fbp]")]) ≈ WNDCnat["SPAA.fbp","delas=0.5"]#  1515.85960332083
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[rec]‡A[rec]")]) ≈ WNDCnat["SPAA.rec","delas=0.5"]#  204.693237
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[con]‡A[con]")]) ≈ WNDCnat["SPAA.con","delas=0.5"]#  1661.39225288267
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[agr]‡A[agr]")]) ≈ WNDCnat["SPAA.agr","delas=0.5"]#  516.24630188779
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[eec]‡A[eec]")]) ≈ WNDCnat["SPAA.eec","delas=0.5"]#  298.28950099067
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[fnd]‡A[fnd]")]) ≈ WNDCnat["SPAA.fnd","delas=0.5"]#  380.898129
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[pub]‡A[pub]")]) ≈ WNDCnat["SPAA.pub","delas=0.5"]#  348.938289320993
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[hou]‡A[hou]")]) ≈ WNDCnat["SPAA.hou","delas=0.5"]#  2035.11236
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[ins]‡A[ins]")]) ≈ WNDCnat["SPAA.ins","delas=0.5"]#  1174.57356283324
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[tex]‡A[tex]")]) ≈ WNDCnat["SPAA.tex","delas=0.5"]#  145.366271676348
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[leg]‡A[leg]")]) ≈ WNDCnat["SPAA.leg","delas=0.5"]#  348.505781910617
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[fen]‡A[fen]")]) ≈ WNDCnat["SPAA.fen","delas=0.5"]#  70.484605514581
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[uti]‡A[uti]")]) ≈ WNDCnat["SPAA.uti","delas=0.5"]#  652.048199468549
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[nmp]‡A[nmp]")]) ≈ WNDCnat["SPAA.nmp","delas=0.5"]#  214.143191827356
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[brd]‡A[brd]")]) ≈ WNDCnat["SPAA.brd","delas=0.5"]#  706.859057988137
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[bnk]‡A[bnk]")]) ≈ WNDCnat["SPAA.bnk","delas=0.5"]#  792.736754302412
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[ore]‡A[ore]")]) ≈ WNDCnat["SPAA.ore","delas=0.5"]#  1255.2142585677
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[edu]‡A[edu]")]) ≈ WNDCnat["SPAA.edu","delas=0.5"]#  392.718862367539
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[ote]‡A[ote]")]) ≈ WNDCnat["SPAA.ote","delas=0.5"]#  277.22539563263
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[man]‡A[man]")]) ≈ WNDCnat["SPAA.man","delas=0.5"]#  579.531360390116
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[mch]‡A[mch]")]) ≈ WNDCnat["SPAA.mch","delas=0.5"]#  587.112660860874
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[dat]‡A[dat]")]) ≈ WNDCnat["SPAA.dat","delas=0.5"]#  245.647070841696
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[amd]‡A[amd]")]) ≈ WNDCnat["SPAA.amd","delas=0.5"]#  229.587824
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[oil]‡A[oil]")]) ≈ WNDCnat["SPAA.oil","delas=0.5"]#  411.376147896077
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[hos]‡A[hos]")]) ≈ WNDCnat["SPAA.hos","delas=0.5"]#  1073.11371300456
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[rnt]‡A[rnt]")]) ≈ WNDCnat["SPAA.rnt","delas=0.5"]#  368.467575126058
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[pla]‡A[pla]")]) ≈ WNDCnat["SPAA.pla","delas=0.5"]#  362.263068479548
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[fof]‡A[fof]")]) ≈ WNDCnat["SPAA.fof","delas=0.5"]#  92.1131343757475
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[fin]‡A[fin]")]) ≈ WNDCnat["SPAA.fin","delas=0.5"]#  183.495134
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[tsv]‡A[tsv]")]) ≈ WNDCnat["SPAA.tsv","delas=0.5"]#  1989.13386888999
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[nrs]‡A[nrs]")]) ≈ WNDCnat["SPAA.nrs","delas=0.5"]#  245.658333
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[sec]‡A[sec]")]) ≈ WNDCnat["SPAA.sec","delas=0.5"]#  514.165906249902
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[art]‡A[art]")]) ≈ WNDCnat["SPAA.art","delas=0.5"]#  174.636633032318
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[mov]‡A[mov]")]) ≈ WNDCnat["SPAA.mov","delas=0.5"]#  146.493343776654
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[fpd]‡A[fpd]")]) ≈ WNDCnat["SPAA.fpd","delas=0.5"]#  221.271403128093
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[slg]‡A[slg]")]) ≈ WNDCnat["SPAA.slg","delas=0.5"]#  1744.23136
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[pri]‡A[pri]")]) ≈ WNDCnat["SPAA.pri","delas=0.5"]#  89.2821943716604
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[grd]‡A[grd]")]) ≈ WNDCnat["SPAA.grd","delas=0.5"]#  93.1481825
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[pip]‡A[pip]")]) ≈ WNDCnat["SPAA.pip","delas=0.5"] atol=1.0e-7 #  0.380571076520651
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[sle]‡A[sle]")]) ≈ WNDCnat["SPAA.sle","delas=0.5"]#  104.176032
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[osv]‡A[osv]")]) ≈ WNDCnat["SPAA.osv","delas=0.5"]#  868.463235119891
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[trn]‡A[trn]")]) ≈ WNDCnat["SPAA.trn","delas=0.5"]#  7.92090092170896
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[smn]‡A[smn]")]) ≈ WNDCnat["SPAA.smn","delas=0.5"]#  124.253788843119
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[fmt]‡A[fmt]")]) ≈ WNDCnat["SPAA.fmt","delas=0.5"]#  477.156574865818
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[pet]‡A[pet]")]) ≈ WNDCnat["SPAA.pet","delas=0.5"]#  753.75904815071
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[cep]‡A[cep]")]) ≈ WNDCnat["SPAA.cep","delas=0.5"]#  754.719744960267
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[wst]‡A[wst]")]) ≈ WNDCnat["SPAA.wst","delas=0.5"]#  117.576207274571
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[mot]‡A[mot]")]) ≈ WNDCnat["SPAA.mot","delas=0.5"]#  1115.65463827953
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[adm]‡A[adm]")]) ≈ WNDCnat["SPAA.adm","delas=0.5"]#  929.23430111397
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[soc]‡A[soc]")]) ≈ WNDCnat["SPAA.soc","delas=0.5"]#  211.263869
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[alt]‡A[alt]")]) ≈ WNDCnat["SPAA.alt","delas=0.5"]#  428.63988823013
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[pmt]‡A[pmt]")]) ≈ WNDCnat["SPAA.pmt","delas=0.5"]#  306.493613096515
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[trk]‡A[trk]")]) ≈ WNDCnat["SPAA.trk","delas=0.5"]#  37.6322704279848
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[fdd]‡A[fdd]")]) ≈ WNDCnat["SPAA.fdd","delas=0.5"]#  598.321003
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[wtt]‡A[wtt]")]) ≈ WNDCnat["SPAA.wtt","delas=0.5"]#  24.7014719142186
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[wpd]‡A[wpd]")]) ≈ WNDCnat["SPAA.wpd","delas=0.5"]#  169.42858714196
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[wht]‡A[wht]")]) ≈ WNDCnat["SPAA.wht","delas=0.5"]#  101.043210787764
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[wrh]‡A[wrh]")]) ≈ WNDCnat["SPAA.wrh","delas=0.5"]#  141.955011912645
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[ott]‡A[ott]")]) ≈ WNDCnat["SPAA.ott","delas=0.5"]#  7.216437
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[che]‡A[che]")]) ≈ WNDCnat["SPAA.che","delas=0.5"]#  1315.58772751069
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[air]‡A[air]")]) ≈ WNDCnat["SPAA.air","delas=0.5"]#  206.785758150423
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[mmf]‡A[mmf]")]) ≈ WNDCnat["SPAA.mmf","delas=0.5"]#  432.825451495033
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[otr]‡A[otr]")]) ≈ WNDCnat["SPAA.otr","delas=0.5"]#  234.235207264151
    @test JuMP.value(WiNnat._jump_model[Symbol("PA[min]‡A[min]")]) ≈ WNDCnat["SPAA.min","delas=0.5"]#  110.707702826321
    @test JuMP.value(WiNnat._jump_model[Symbol("PY[ppd]†A→dmppd")]) ≈ WNDCnat["DPYA.ppd","delas=0.5"]#  178.256813902463
    @test JuMP.value(WiNnat._jump_model[Symbol("PY[res]†A→dmres")]) ≈ WNDCnat["DPYA.res","delas=0.5"]#  899.582049
    @test JuMP.value(WiNnat._jump_model[Symbol("PY[com]†A→dmcom")]) ≈ WNDCnat["DPYA.com","delas=0.5"]#  516.649898560368
    @test JuMP.value(WiNnat._jump_model[Symbol("PY[amb]†A→dmamb")]) ≈ WNDCnat["DPYA.amb","delas=0.5"]#  1092.93382
    @test JuMP.value(WiNnat._jump_model[Symbol("PY[fbp]†A→dmfbp")]) ≈ WNDCnat["DPYA.fbp","delas=0.5"]#  931.251070587899
    @test JuMP.value(WiNnat._jump_model[Symbol("PY[rec]†A→dmrec")]) ≈ WNDCnat["DPYA.rec","delas=0.5"]#  195.091973
    @test JuMP.value(WiNnat._jump_model[Symbol("PY[con]†A→dmcon")]) ≈ WNDCnat["DPYA.con","delas=0.5"]#  1659.55143
    @test JuMP.value(WiNnat._jump_model[Symbol("PY[agr]†A→dmagr")]) ≈ WNDCnat["DPYA.agr","delas=0.5"]#  397.024445520014
    @test JuMP.value(WiNnat._jump_model[Symbol("PY[eec]†A→dmeec")]) ≈ WNDCnat["DPYA.eec","delas=0.5"]#  116.224602225512
    @test JuMP.value(WiNnat._jump_model[Symbol("PY[fnd]†A→dmfnd")]) ≈ WNDCnat["DPYA.fnd","delas=0.5"]#  380.898129
    @test JuMP.value(WiNnat._jump_model[Symbol("PY[pub]†A→dmpub")]) ≈ WNDCnat["DPYA.pub","delas=0.5"]#  279.094208134003
    @test JuMP.value(WiNnat._jump_model[Symbol("PY[hou]†A→dmhou")]) ≈ WNDCnat["DPYA.hou","delas=0.5"]#  2073.31916
    @test JuMP.value(WiNnat._jump_model[Symbol("PY[ins]†A→dmins")]) ≈ WNDCnat["DPYA.ins","delas=0.5"]#  1122.53945097812
    @test JuMP.value(WiNnat._jump_model[Symbol("PY[tex]†A→dmtex")]) ≈ WNDCnat["DPYA.tex","delas=0.5"]#  44.6835445946073
    @test JuMP.value(WiNnat._jump_model[Symbol("PY[leg]†A→dmleg")]) ≈ WNDCnat["DPYA.leg","delas=0.5"]#  342.941202554652
    @test JuMP.value(WiNnat._jump_model[Symbol("PY[fen]†A→dmfen")]) ≈ WNDCnat["DPYA.fen","delas=0.5"]#  70.8982207884942
    @test JuMP.value(WiNnat._jump_model[Symbol("PY[uti]†A→dmuti")]) ≈ WNDCnat["DPYA.uti","delas=0.5"]#  624.237086740571
    @test JuMP.value(WiNnat._jump_model[Symbol("PY[nmp]†A→dmnmp")]) ≈ WNDCnat["DPYA.nmp","delas=0.5"]#  122.588272442773
    @test JuMP.value(WiNnat._jump_model[Symbol("PY[brd]†A→dmbrd")]) ≈ WNDCnat["DPYA.brd","delas=0.5"]#  683.422053280957
    @test JuMP.value(WiNnat._jump_model[Symbol("PY[bnk]†A→dmbnk")]) ≈ WNDCnat["DPYA.bnk","delas=0.5"]#  852.551516138285
    @test JuMP.value(WiNnat._jump_model[Symbol("PY[ore]†A→dmore")]) ≈ WNDCnat["DPYA.ore","delas=0.5"]#  1259.29276
    @test JuMP.value(WiNnat._jump_model[Symbol("PY[edu]†A→dmedu")]) ≈ WNDCnat["DPYA.edu","delas=0.5"]#  393.242773982239
    @test JuMP.value(WiNnat._jump_model[Symbol("PY[ote]†A→dmote")]) ≈ WNDCnat["DPYA.ote","delas=0.5"]#  317.58715531611
    @test JuMP.value(WiNnat._jump_model[Symbol("PY[man]†A→dmman")]) ≈ WNDCnat["DPYA.man","delas=0.5"]#  582.277441
    @test JuMP.value(WiNnat._jump_model[Symbol("PY[mch]†A→dmmch")]) ≈ WNDCnat["DPYA.mch","delas=0.5"]#  350.820648889152
    @test JuMP.value(WiNnat._jump_model[Symbol("PY[dat]†A→dmdat")]) ≈ WNDCnat["DPYA.dat","delas=0.5"]#  249.63483299757
    @test JuMP.value(WiNnat._jump_model[Symbol("PY[amd]†A→dmamd")]) ≈ WNDCnat["DPYA.amd","delas=0.5"]#  211.274527
    @test JuMP.value(WiNnat._jump_model[Symbol("PY[oil]†A→dmoil")]) ≈ WNDCnat["DPYA.oil","delas=0.5"]#  232.058988306448
    @test JuMP.value(WiNnat._jump_model[Symbol("PY[hos]†A→dmhos")]) ≈ WNDCnat["DPYA.hos","delas=0.5"]#  1069.65732716006
    @test JuMP.value(WiNnat._jump_model[Symbol("PY[rnt]†A→dmrnt")]) ≈ WNDCnat["DPYA.rnt","delas=0.5"]#  433.205937
    @test JuMP.value(WiNnat._jump_model[Symbol("PY[pla]†A→dmpla")]) ≈ WNDCnat["DPYA.pla","delas=0.5"]#  229.66487257659
    @test JuMP.value(WiNnat._jump_model[Symbol("PY[fof]†A→dmfof")]) ≈ WNDCnat["DPYA.fof","delas=0.5"]#  65.745918634565
    @test JuMP.value(WiNnat._jump_model[Symbol("PY[fin]†A→dmfin")]) ≈ WNDCnat["DPYA.fin","delas=0.5"]#  183.457238
    @test JuMP.value(WiNnat._jump_model[Symbol("PY[tsv]†A→dmtsv")]) ≈ WNDCnat["DPYA.tsv","delas=0.5"]#  2035.31278550717
    @test JuMP.value(WiNnat._jump_model[Symbol("PY[nrs]†A→dmnrs")]) ≈ WNDCnat["DPYA.nrs","delas=0.5"]#  242.743749
    @test JuMP.value(WiNnat._jump_model[Symbol("PY[sec]†A→dmsec")]) ≈ WNDCnat["DPYA.sec","delas=0.5"]#  584.314739652457
    @test JuMP.value(WiNnat._jump_model[Symbol("PY[art]†A→dmart")]) ≈ WNDCnat["DPYA.art","delas=0.5"]#  169.25132985919
    @test JuMP.value(WiNnat._jump_model[Symbol("PY[mov]†A→dmmov")]) ≈ WNDCnat["DPYA.mov","delas=0.5"]#  145.086764881248
    @test JuMP.value(WiNnat._jump_model[Symbol("PY[fpd]†A→dmfpd")]) ≈ WNDCnat["DPYA.fpd","delas=0.5"]#  72.0740621404007
    @test JuMP.value(WiNnat._jump_model[Symbol("PY[slg]†A→dmslg")]) ≈ WNDCnat["DPYA.slg","delas=0.5"]#  1744.23136
    @test JuMP.value(WiNnat._jump_model[Symbol("PY[pri]†A→dmpri")]) ≈ WNDCnat["DPYA.pri","delas=0.5"]#  71.1547479575622
    @test JuMP.value(WiNnat._jump_model[Symbol("PY[grd]†A→dmgrd")]) ≈ WNDCnat["DPYA.grd","delas=0.5"]#  92.1405807
    @test JuMP.value(WiNnat._jump_model[Symbol("PY[pip]†A→dmpip")]) ≈ WNDCnat["DPYA.pip","delas=0.5"] atol=1.0e-7 #  0.551520281
    @test JuMP.value(WiNnat._jump_model[Symbol("PY[sle]†A→dmsle")]) ≈ WNDCnat["DPYA.sle","delas=0.5"]#  104.176032
    @test JuMP.value(WiNnat._jump_model[Symbol("PY[osv]†A→dmosv")]) ≈ WNDCnat["DPYA.osv","delas=0.5"]#  843.617845888317
    @test JuMP.value(WiNnat._jump_model[Symbol("PY[trn]†A→dmtrn")]) ≈ WNDCnat["DPYA.trn","delas=0.5"]#  10.818151
    @test JuMP.value(WiNnat._jump_model[Symbol("PY[smn]†A→dmsmn")]) ≈ WNDCnat["DPYA.smn","delas=0.5"]#  126.30253012871
    @test JuMP.value(WiNnat._jump_model[Symbol("PY[fmt]†A→dmfmt")]) ≈ WNDCnat["DPYA.fmt","delas=0.5"]#  326.770351755691
    @test JuMP.value(WiNnat._jump_model[Symbol("PY[pet]†A→dmpet")]) ≈ WNDCnat["DPYA.pet","delas=0.5"]#  530.314023931433
    @test JuMP.value(WiNnat._jump_model[Symbol("PY[cep]†A→dmcep")]) ≈ WNDCnat["DPYA.cep","delas=0.5"]#  294.0555382098
    @test JuMP.value(WiNnat._jump_model[Symbol("PY[wst]†A→dmwst")]) ≈ WNDCnat["DPYA.wst","delas=0.5"]#  115.756304435511
    @test JuMP.value(WiNnat._jump_model[Symbol("PY[mot]†A→dmmot")]) ≈ WNDCnat["DPYA.mot","delas=0.5"]#  662.445547589631
    @test JuMP.value(WiNnat._jump_model[Symbol("PY[adm]†A→dmadm")]) ≈ WNDCnat["DPYA.adm","delas=0.5"]#  923.381795523787
    @test JuMP.value(WiNnat._jump_model[Symbol("PY[soc]†A→dmsoc")]) ≈ WNDCnat["DPYA.soc","delas=0.5"]#  210.448152
    @test JuMP.value(WiNnat._jump_model[Symbol("PY[alt]†A→dmalt")]) ≈ WNDCnat["DPYA.alt","delas=0.5"]#  15.1340936958987
    @test JuMP.value(WiNnat._jump_model[Symbol("PY[pmt]†A→dmpmt")]) ≈ WNDCnat["DPYA.pmt","delas=0.5"]#  209.257117915282
    @test JuMP.value(WiNnat._jump_model[Symbol("PY[trk]†A→dmtrk")]) ≈ WNDCnat["DPYA.trk","delas=0.5"]#  38.934866
    @test JuMP.value(WiNnat._jump_model[Symbol("PY[fdd]†A→dmfdd")]) ≈ WNDCnat["DPYA.fdd","delas=0.5"]#  598.321003
    @test JuMP.value(WiNnat._jump_model[Symbol("PY[wtt]†A→dmwtt")]) ≈ WNDCnat["DPYA.wtt","delas=0.5"]#  29.5450418
    @test JuMP.value(WiNnat._jump_model[Symbol("PY[wpd]†A→dmwpd")]) ≈ WNDCnat["DPYA.wpd","delas=0.5"]#  110.751311022094
    @test JuMP.value(WiNnat._jump_model[Symbol("PY[wht]†A→dmwht")]) ≈ WNDCnat["DPYA.wht","delas=0.5"]#  103.418245
    @test JuMP.value(WiNnat._jump_model[Symbol("PY[wrh]†A→dmwrh")]) ≈ WNDCnat["DPYA.wrh","delas=0.5"]#  141.952358
    @test JuMP.value(WiNnat._jump_model[Symbol("PY[ott]†A→dmott")]) ≈ WNDCnat["DPYA.ott","delas=0.5"]#  7.216437
    @test JuMP.value(WiNnat._jump_model[Symbol("PY[che]†A→dmche")]) ≈ WNDCnat["DPYA.che","delas=0.5"]#  748.468424078777
    @test JuMP.value(WiNnat._jump_model[Symbol("PY[air]†A→dmair")]) ≈ WNDCnat["DPYA.air","delas=0.5"]#  191.300045170429
    @test JuMP.value(WiNnat._jump_model[Symbol("PY[mmf]†A→dmmmf")]) ≈ WNDCnat["DPYA.mmf","delas=0.5"]#  144.347624373182
    @test JuMP.value(WiNnat._jump_model[Symbol("PY[otr]†A→dmotr")]) ≈ WNDCnat["DPYA.otr","delas=0.5"]#  244.239969510576
    @test JuMP.value(WiNnat._jump_model[Symbol("PY[min]†A→dmmin")]) ≈ WNDCnat["DPYA.min","delas=0.5"]#  83.8292439906876
    @test JuMP.value(WiNnat._jump_model[Symbol("PM[trn]‡MS[trn]")]) ≈ WNDCnat["SPMMS.trn","delas=0.5"]#  441.38467
    @test JuMP.value(WiNnat._jump_model[Symbol("PM[trd]‡MS[trd]")]) ≈ WNDCnat["SPMMS.trd","delas=0.5"]#  2963.50744
    @test JuMP.value(WiNnat._jump_model[Symbol("MS")][:trn]) ≈ WNDCnat["MS.trn","delas=0.5"]#  1.01527815024853
    @test JuMP.value(WiNnat._jump_model[Symbol("MS")][:trd]) ≈ WNDCnat["MS.trd","delas=0.5"]#  1.01230852907687
    @test JuMP.value(WiNnat._jump_model[Symbol("PA")][:ppd]) ≈ WNDCnat["PA.ppd","delas=0.5"]#  0.945140197709488
    @test JuMP.value(WiNnat._jump_model[Symbol("PA")][:res]) ≈ WNDCnat["PA.res","delas=0.5"]#  0.904652892905589
    @test JuMP.value(WiNnat._jump_model[Symbol("PA")][:com]) ≈ WNDCnat["PA.com","delas=0.5"]#  0.973046864300211
    @test JuMP.value(WiNnat._jump_model[Symbol("PA")][:amb]) ≈ WNDCnat["PA.amb","delas=0.5"]#  0.976092887866181
    @test JuMP.value(WiNnat._jump_model[Symbol("PA")][:fbp]) ≈ WNDCnat["PA.fbp","delas=0.5"]#  0.905222925282818
    @test JuMP.value(WiNnat._jump_model[Symbol("PA")][:rec]) ≈ WNDCnat["PA.rec","delas=0.5"]#  0.923265955812877
    @test JuMP.value(WiNnat._jump_model[Symbol("PA")][:con]) ≈ WNDCnat["PA.con","delas=0.5"]#  0.961278520486227
    @test JuMP.value(WiNnat._jump_model[Symbol("PA")][:agr]) ≈ WNDCnat["PA.agr","delas=0.5"]#  0.96909698486413
    @test JuMP.value(WiNnat._jump_model[Symbol("PA")][:eec]) ≈ WNDCnat["PA.eec","delas=0.5"]#  0.937036591197483
    @test JuMP.value(WiNnat._jump_model[Symbol("PA")][:fnd]) ≈ WNDCnat["PA.fnd","delas=0.5"]#  0.979463374001478
    @test JuMP.value(WiNnat._jump_model[Symbol("PA")][:pub]) ≈ WNDCnat["PA.pub","delas=0.5"]#  0.955585617217787
    @test JuMP.value(WiNnat._jump_model[Symbol("PA")][:hou]) ≈ WNDCnat["PA.hou","delas=0.5"]#  1.00189285811208
    # @test JuMP.value(WiNnat._jump_model[Symbol("PA")][:fbt]) ≈ WNDCnat["PA.fbt","delas=0.5"]#  1
    @test JuMP.value(WiNnat._jump_model[Symbol("PA")][:ins]) ≈ WNDCnat["PA.ins","delas=0.5"]#  0.955004159021877
    @test JuMP.value(WiNnat._jump_model[Symbol("PA")][:tex]) ≈ WNDCnat["PA.tex","delas=0.5"]#  0.911970420038665
    @test JuMP.value(WiNnat._jump_model[Symbol("PA")][:leg]) ≈ WNDCnat["PA.leg","delas=0.5"]#  0.934815046709346
    @test JuMP.value(WiNnat._jump_model[Symbol("PA")][:fen]) ≈ WNDCnat["PA.fen","delas=0.5"]#  0.975890460905855
    @test JuMP.value(WiNnat._jump_model[Symbol("PA")][:uti]) ≈ WNDCnat["PA.uti","delas=0.5"]#  0.91937778259042
    @test JuMP.value(WiNnat._jump_model[Symbol("PA")][:nmp]) ≈ WNDCnat["PA.nmp","delas=0.5"]#  0.938922355190893
    @test JuMP.value(WiNnat._jump_model[Symbol("PA")][:brd]) ≈ WNDCnat["PA.brd","delas=0.5"]#  0.91321039734632
    @test JuMP.value(WiNnat._jump_model[Symbol("PA")][:bnk]) ≈ WNDCnat["PA.bnk","delas=0.5"]#  0.978999974911223
    @test JuMP.value(WiNnat._jump_model[Symbol("PA")][:ore]) ≈ WNDCnat["PA.ore","delas=0.5"]#  0.965194949931579
    @test JuMP.value(WiNnat._jump_model[Symbol("PA")][:edu]) ≈ WNDCnat["PA.edu","delas=0.5"]#  0.97755832559901
    @test JuMP.value(WiNnat._jump_model[Symbol("PA")][:ote]) ≈ WNDCnat["PA.ote","delas=0.5"]#  0.961412035279279
    @test JuMP.value(WiNnat._jump_model[Symbol("PA")][:man]) ≈ WNDCnat["PA.man","delas=0.5"]#  0.97440623147216
    @test JuMP.value(WiNnat._jump_model[Symbol("PA")][:mch]) ≈ WNDCnat["PA.mch","delas=0.5"]#  0.946933379047208
    @test JuMP.value(WiNnat._jump_model[Symbol("PA")][:dat]) ≈ WNDCnat["PA.dat","delas=0.5"]#  0.968528389047219
    @test JuMP.value(WiNnat._jump_model[Symbol("PA")][:amd]) ≈ WNDCnat["PA.amd","delas=0.5"]#  0.892333359181414
    @test JuMP.value(WiNnat._jump_model[Symbol("PA")][:oil]) ≈ WNDCnat["PA.oil","delas=0.5"]#  0.944735721853549
    @test JuMP.value(WiNnat._jump_model[Symbol("PA")][:hos]) ≈ WNDCnat["PA.hos","delas=0.5"]#  0.970234516593953
    @test JuMP.value(WiNnat._jump_model[Symbol("PA")][:rnt]) ≈ WNDCnat["PA.rnt","delas=0.5"]#  0.933024055181551
    @test JuMP.value(WiNnat._jump_model[Symbol("PA")][:pla]) ≈ WNDCnat["PA.pla","delas=0.5"]#  0.936170343563667
    @test JuMP.value(WiNnat._jump_model[Symbol("PA")][:fof]) ≈ WNDCnat["PA.fof","delas=0.5"]#  0.965253342086377
    @test JuMP.value(WiNnat._jump_model[Symbol("PA")][:fin]) ≈ WNDCnat["PA.fin","delas=0.5"]#  0.969989700476859
    @test JuMP.value(WiNnat._jump_model[Symbol("PA")][:tsv]) ≈ WNDCnat["PA.tsv","delas=0.5"]#  0.973525120066279
    @test JuMP.value(WiNnat._jump_model[Symbol("PA")][:nrs]) ≈ WNDCnat["PA.nrs","delas=0.5"]#  0.959984225635516
    @test JuMP.value(WiNnat._jump_model[Symbol("PA")][:sec]) ≈ WNDCnat["PA.sec","delas=0.5"]#  0.972608490404801
    @test JuMP.value(WiNnat._jump_model[Symbol("PA")][:art]) ≈ WNDCnat["PA.art","delas=0.5"]#  0.945585911333066
    @test JuMP.value(WiNnat._jump_model[Symbol("PA")][:mov]) ≈ WNDCnat["PA.mov","delas=0.5"]#  0.950640720981328
    @test JuMP.value(WiNnat._jump_model[Symbol("PA")][:fpd]) ≈ WNDCnat["PA.fpd","delas=0.5"]#  0.926041003688575
    @test JuMP.value(WiNnat._jump_model[Symbol("PA")][:slg]) ≈ WNDCnat["PA.slg","delas=0.5"]#  0.969916200670407
    @test JuMP.value(WiNnat._jump_model[Symbol("PA")][:pri]) ≈ WNDCnat["PA.pri","delas=0.5"]#  0.952697504196913
    @test JuMP.value(WiNnat._jump_model[Symbol("PA")][:grd]) ≈ WNDCnat["PA.grd","delas=0.5"]#  0.960890375138728
    @test JuMP.value(WiNnat._jump_model[Symbol("PA")][:pip]) ≈ WNDCnat["PA.pip","delas=0.5"] atol=1.0e-7 #  0.781868345526557
    @test JuMP.value(WiNnat._jump_model[Symbol("PA")][:sle]) ≈ WNDCnat["PA.sle","delas=0.5"]#  0.953339320633534
    @test JuMP.value(WiNnat._jump_model[Symbol("PA")][:osv]) ≈ WNDCnat["PA.osv","delas=0.5"]#  0.950843222439624
    @test JuMP.value(WiNnat._jump_model[Symbol("PA")][:trn]) ≈ WNDCnat["PA.trn","delas=0.5"]#  1.14227969214863
    @test JuMP.value(WiNnat._jump_model[Symbol("PA")][:smn]) ≈ WNDCnat["PA.smn","delas=0.5"]#  0.966004078681194
    @test JuMP.value(WiNnat._jump_model[Symbol("PA")][:fmt]) ≈ WNDCnat["PA.fmt","delas=0.5"]#  0.946275819441559
    @test JuMP.value(WiNnat._jump_model[Symbol("PA")][:pet]) ≈ WNDCnat["PA.pet","delas=0.5"]#  0.820928950163508
    # @test JuMP.value(WiNnat._jump_model[Symbol("PA")][:mvt]) ≈ WNDCnat["PA.mvt","delas=0.5"]#  1
    @test JuMP.value(WiNnat._jump_model[Symbol("PA")][:cep]) ≈ WNDCnat["PA.cep","delas=0.5"]#  0.956833013401351
    @test JuMP.value(WiNnat._jump_model[Symbol("PA")][:wst]) ≈ WNDCnat["PA.wst","delas=0.5"]#  0.953423714285322
    @test JuMP.value(WiNnat._jump_model[Symbol("PA")][:mot]) ≈ WNDCnat["PA.mot","delas=0.5"]#  0.929210245629629
    @test JuMP.value(WiNnat._jump_model[Symbol("PA")][:adm]) ≈ WNDCnat["PA.adm","delas=0.5"]#  0.966810685540033
    @test JuMP.value(WiNnat._jump_model[Symbol("PA")][:soc]) ≈ WNDCnat["PA.soc","delas=0.5"]#  0.967926555601326
    @test JuMP.value(WiNnat._jump_model[Symbol("PA")][:alt]) ≈ WNDCnat["PA.alt","delas=0.5"]#  0.87520579330517
    @test JuMP.value(WiNnat._jump_model[Symbol("PA")][:pmt]) ≈ WNDCnat["PA.pmt","delas=0.5"]#  0.959072252096919
    @test JuMP.value(WiNnat._jump_model[Symbol("PA")][:trk]) ≈ WNDCnat["PA.trk","delas=0.5"]#  0.941542531256691
    @test JuMP.value(WiNnat._jump_model[Symbol("PA")][:fdd]) ≈ WNDCnat["PA.fdd","delas=0.5"]#  0.974826342493881
    # @test JuMP.value(WiNnat._jump_model[Symbol("PA")][:gmt]) ≈ WNDCnat["PA.gmt","delas=0.5"]#  1
    @test JuMP.value(WiNnat._jump_model[Symbol("PA")][:wtt]) ≈ WNDCnat["PA.wtt","delas=0.5"]#  0.947015348260372
    @test JuMP.value(WiNnat._jump_model[Symbol("PA")][:wpd]) ≈ WNDCnat["PA.wpd","delas=0.5"]#  0.944282207961669
    @test JuMP.value(WiNnat._jump_model[Symbol("PA")][:wht]) ≈ WNDCnat["PA.wht","delas=0.5"]#  0.974539149389098
    @test JuMP.value(WiNnat._jump_model[Symbol("PA")][:wrh]) ≈ WNDCnat["PA.wrh","delas=0.5"]#  0.967648373728616
    @test JuMP.value(WiNnat._jump_model[Symbol("PA")][:ott]) ≈ WNDCnat["PA.ott","delas=0.5"]#  0.974634704152285
    @test JuMP.value(WiNnat._jump_model[Symbol("PA")][:che]) ≈ WNDCnat["PA.che","delas=0.5"]#  0.944417300106697
    @test JuMP.value(WiNnat._jump_model[Symbol("PA")][:air]) ≈ WNDCnat["PA.air","delas=0.5"]#  0.854177543307008
    @test JuMP.value(WiNnat._jump_model[Symbol("PA")][:mmf]) ≈ WNDCnat["PA.mmf","delas=0.5"]#  0.932945598568183
    @test JuMP.value(WiNnat._jump_model[Symbol("PA")][:otr]) ≈ WNDCnat["PA.otr","delas=0.5"]#  0.960131350744643
    @test JuMP.value(WiNnat._jump_model[Symbol("PA")][:min]) ≈ WNDCnat["PA.min","delas=0.5"]#  0.933574887500853
    @test JuMP.value(WiNnat._jump_model[Symbol("PY")][:ppd]) ≈ WNDCnat["PY.ppd","delas=0.5"]#  0.957371237581366
    @test JuMP.value(WiNnat._jump_model[Symbol("PY")][:res]) ≈ WNDCnat["PY.res","delas=0.5"]#  0.967671161954627
    @test JuMP.value(WiNnat._jump_model[Symbol("PY")][:com]) ≈ WNDCnat["PY.com","delas=0.5"]#  0.980669782754909
    @test JuMP.value(WiNnat._jump_model[Symbol("PY")][:amb]) ≈ WNDCnat["PY.amb","delas=0.5"]#  0.976568548467505
    @test JuMP.value(WiNnat._jump_model[Symbol("PY")][:fbp]) ≈ WNDCnat["PY.fbp","delas=0.5"]#  0.955130562237221
    @test JuMP.value(WiNnat._jump_model[Symbol("PY")][:rec]) ≈ WNDCnat["PY.rec","delas=0.5"]#  0.968703602721967
    @test JuMP.value(WiNnat._jump_model[Symbol("PY")][:con]) ≈ WNDCnat["PY.con","delas=0.5"]#  0.962403989232918
    @test JuMP.value(WiNnat._jump_model[Symbol("PY")][:agr]) ≈ WNDCnat["PY.agr","delas=0.5"]#  0.958576177666825
    @test JuMP.value(WiNnat._jump_model[Symbol("PY")][:eec]) ≈ WNDCnat["PY.eec","delas=0.5"]#  0.966990579307507
    @test JuMP.value(WiNnat._jump_model[Symbol("PY")][:fnd]) ≈ WNDCnat["PY.fnd","delas=0.5"]#  0.979463374001478
    @test JuMP.value(WiNnat._jump_model[Symbol("PY")][:pub]) ≈ WNDCnat["PY.pub","delas=0.5"]#  0.979550430840125
    @test JuMP.value(WiNnat._jump_model[Symbol("PY")][:hou]) ≈ WNDCnat["PY.hou","delas=0.5"]#  0.983430133805168
    @test JuMP.value(WiNnat._jump_model[Symbol("PY")][:fbt]) ≈ WNDCnat["PY.fbt","delas=0.5"]#  0.975973643994495
    @test JuMP.value(WiNnat._jump_model[Symbol("PY")][:ins]) ≈ WNDCnat["PY.ins","delas=0.5"]#  0.970754148038202
    @test JuMP.value(WiNnat._jump_model[Symbol("PY")][:tex]) ≈ WNDCnat["PY.tex","delas=0.5"]#  0.955691958041676
    @test JuMP.value(WiNnat._jump_model[Symbol("PY")][:leg]) ≈ WNDCnat["PY.leg","delas=0.5"]#  0.978658905987505
    @test JuMP.value(WiNnat._jump_model[Symbol("PY")][:fen]) ≈ WNDCnat["PY.fen","delas=0.5"]#  0.975868985069321
    @test JuMP.value(WiNnat._jump_model[Symbol("PY")][:uti]) ≈ WNDCnat["PY.uti","delas=0.5"]#  0.962982970876244
    @test JuMP.value(WiNnat._jump_model[Symbol("PY")][:nmp]) ≈ WNDCnat["PY.nmp","delas=0.5"]#  0.963634970108683
    @test JuMP.value(WiNnat._jump_model[Symbol("PY")][:brd]) ≈ WNDCnat["PY.brd","delas=0.5"]#  0.963081960971072
    @test JuMP.value(WiNnat._jump_model[Symbol("PY")][:bnk]) ≈ WNDCnat["PY.bnk","delas=0.5"]#  0.977901140187266
    @test JuMP.value(WiNnat._jump_model[Symbol("PY")][:ore]) ≈ WNDCnat["PY.ore","delas=0.5"]#  0.964637447473895
    @test JuMP.value(WiNnat._jump_model[Symbol("PY")][:edu]) ≈ WNDCnat["PY.edu","delas=0.5"]#  0.978224927465962
    @test JuMP.value(WiNnat._jump_model[Symbol("PY")][:ote]) ≈ WNDCnat["PY.ote","delas=0.5"]#  0.969996638283914
    @test JuMP.value(WiNnat._jump_model[Symbol("PY")][:man]) ≈ WNDCnat["PY.man","delas=0.5"]#  0.97691711751733
    @test JuMP.value(WiNnat._jump_model[Symbol("PY")][:mch]) ≈ WNDCnat["PY.mch","delas=0.5"]#  0.965255364634832
    @test JuMP.value(WiNnat._jump_model[Symbol("PY")][:dat]) ≈ WNDCnat["PY.dat","delas=0.5"]#  0.971844406255276
    @test JuMP.value(WiNnat._jump_model[Symbol("PY")][:amd]) ≈ WNDCnat["PY.amd","delas=0.5"]#  0.969680903448769
    @test JuMP.value(WiNnat._jump_model[Symbol("PY")][:oil]) ≈ WNDCnat["PY.oil","delas=0.5"]#  0.970593516024889
    @test JuMP.value(WiNnat._jump_model[Symbol("PY")][:hos]) ≈ WNDCnat["PY.hos","delas=0.5"]#  0.971822758755271
    @test JuMP.value(WiNnat._jump_model[Symbol("PY")][:rnt]) ≈ WNDCnat["PY.rnt","delas=0.5"]#  0.976413854349883
    @test JuMP.value(WiNnat._jump_model[Symbol("PY")][:pla]) ≈ WNDCnat["PY.pla","delas=0.5"]#  0.9584923100911
    @test JuMP.value(WiNnat._jump_model[Symbol("PY")][:fof]) ≈ WNDCnat["PY.fof","delas=0.5"]#  0.975374151899061
    @test JuMP.value(WiNnat._jump_model[Symbol("PY")][:fin]) ≈ WNDCnat["PY.fin","delas=0.5"]#  0.970190067222211
    @test JuMP.value(WiNnat._jump_model[Symbol("PY")][:tsv]) ≈ WNDCnat["PY.tsv","delas=0.5"]#  0.975916644650378
    @test JuMP.value(WiNnat._jump_model[Symbol("PY")][:nrs]) ≈ WNDCnat["PY.nrs","delas=0.5"]#  0.971510597275635
    @test JuMP.value(WiNnat._jump_model[Symbol("PY")][:sec]) ≈ WNDCnat["PY.sec","delas=0.5"]#  0.974735236862947
    @test JuMP.value(WiNnat._jump_model[Symbol("PY")][:art]) ≈ WNDCnat["PY.art","delas=0.5"]#  0.976751191194228
    @test JuMP.value(WiNnat._jump_model[Symbol("PY")][:mov]) ≈ WNDCnat["PY.mov","delas=0.5"]#  0.974595761015874
    @test JuMP.value(WiNnat._jump_model[Symbol("PY")][:fpd]) ≈ WNDCnat["PY.fpd","delas=0.5"]#  0.960794876800887
    @test JuMP.value(WiNnat._jump_model[Symbol("PY")][:slg]) ≈ WNDCnat["PY.slg","delas=0.5"]#  0.969916200670407
    @test JuMP.value(WiNnat._jump_model[Symbol("PY")][:pri]) ≈ WNDCnat["PY.pri","delas=0.5"]#  0.961979246880187
    @test JuMP.value(WiNnat._jump_model[Symbol("PY")][:grd]) ≈ WNDCnat["PY.grd","delas=0.5"]#  0.971398175982146
    @test JuMP.value(WiNnat._jump_model[Symbol("PY")][:pip]) ≈ WNDCnat["PY.pip","delas=0.5"]#  0.981938417029131
    @test JuMP.value(WiNnat._jump_model[Symbol("PY")][:sle]) ≈ WNDCnat["PY.sle","delas=0.5"]#  0.953339320633534
    @test JuMP.value(WiNnat._jump_model[Symbol("PY")][:osv]) ≈ WNDCnat["PY.osv","delas=0.5"]#  0.973391346546706
    @test JuMP.value(WiNnat._jump_model[Symbol("PY")][:trn]) ≈ WNDCnat["PY.trn","delas=0.5"]#  0.961221268344908
    @test JuMP.value(WiNnat._jump_model[Symbol("PY")][:smn]) ≈ WNDCnat["PY.smn","delas=0.5"]#  0.966103982502013
    @test JuMP.value(WiNnat._jump_model[Symbol("PY")][:fmt]) ≈ WNDCnat["PY.fmt","delas=0.5"]#  0.968802149589158
    @test JuMP.value(WiNnat._jump_model[Symbol("PY")][:pet]) ≈ WNDCnat["PY.pet","delas=0.5"]#  0.950793445388338
    @test JuMP.value(WiNnat._jump_model[Symbol("PY")][:mvt]) ≈ WNDCnat["PY.mvt","delas=0.5"]#  0.97721968022921
    @test JuMP.value(WiNnat._jump_model[Symbol("PY")][:cep]) ≈ WNDCnat["PY.cep","delas=0.5"]#  0.982965019595103
    @test JuMP.value(WiNnat._jump_model[Symbol("PY")][:wst]) ≈ WNDCnat["PY.wst","delas=0.5"]#  0.967796580618928
    @test JuMP.value(WiNnat._jump_model[Symbol("PY")][:mot]) ≈ WNDCnat["PY.mot","delas=0.5"]#  0.949811632208893
    @test JuMP.value(WiNnat._jump_model[Symbol("PY")][:adm]) ≈ WNDCnat["PY.adm","delas=0.5"]#  0.97345241308982
    @test JuMP.value(WiNnat._jump_model[Symbol("PY")][:soc]) ≈ WNDCnat["PY.soc","delas=0.5"]#  0.971678330747137
    @test JuMP.value(WiNnat._jump_model[Symbol("PY")][:alt]) ≈ WNDCnat["PY.alt","delas=0.5"]#  0.957776289877319
    @test JuMP.value(WiNnat._jump_model[Symbol("PY")][:pmt]) ≈ WNDCnat["PY.pmt","delas=0.5"]#  0.961755781425041
    @test JuMP.value(WiNnat._jump_model[Symbol("PY")][:trk]) ≈ WNDCnat["PY.trk","delas=0.5"]#  0.952430119010462
    @test JuMP.value(WiNnat._jump_model[Symbol("PY")][:fdd]) ≈ WNDCnat["PY.fdd","delas=0.5"]#  0.974826342493881
    @test JuMP.value(WiNnat._jump_model[Symbol("PY")][:gmt]) ≈ WNDCnat["PY.gmt","delas=0.5"]#  0.976529160437046
    @test JuMP.value(WiNnat._jump_model[Symbol("PY")][:wtt]) ≈ WNDCnat["PY.wtt","delas=0.5"]#  0.956820401627842
    @test JuMP.value(WiNnat._jump_model[Symbol("PY")][:wpd]) ≈ WNDCnat["PY.wpd","delas=0.5"]#  0.961780697173675
    @test JuMP.value(WiNnat._jump_model[Symbol("PY")][:wht]) ≈ WNDCnat["PY.wht","delas=0.5"]#  0.97448626666803
    @test JuMP.value(WiNnat._jump_model[Symbol("PY")][:wrh]) ≈ WNDCnat["PY.wrh","delas=0.5"]#  0.968811475780097
    @test JuMP.value(WiNnat._jump_model[Symbol("PY")][:ott]) ≈ WNDCnat["PY.ott","delas=0.5"]#  0.974634704152285
    @test JuMP.value(WiNnat._jump_model[Symbol("PY")][:che]) ≈ WNDCnat["PY.che","delas=0.5"]#  0.961877509706166
    @test JuMP.value(WiNnat._jump_model[Symbol("PY")][:air]) ≈ WNDCnat["PY.air","delas=0.5"]#  0.95212576189474
    @test JuMP.value(WiNnat._jump_model[Symbol("PY")][:mmf]) ≈ WNDCnat["PY.mmf","delas=0.5"]#  0.969747703671534
    @test JuMP.value(WiNnat._jump_model[Symbol("PY")][:otr]) ≈ WNDCnat["PY.otr","delas=0.5"]#  0.961970484538815
    @test JuMP.value(WiNnat._jump_model[Symbol("PY")][:min]) ≈ WNDCnat["PY.min","delas=0.5"]#  0.962723933015537
    @test JuMP.value(WiNnat._jump_model[Symbol("PVA")][:compen]) ≈ WNDCnat["PVA.compen","delas=0.5"]#  0.98955309837526
    @test JuMP.value(WiNnat._jump_model[Symbol("PVA")][:surplus]) ≈ WNDCnat["PVA.surplus","delas=0.5"]#  0.985772741023506
    @test JuMP.value(WiNnat._jump_model[Symbol("PM")][:trn]) ≈ WNDCnat["PM.trn","delas=0.5"]#  0.957232419396773
    @test JuMP.value(WiNnat._jump_model[Symbol("PM")][:trd]) ≈ WNDCnat["PM.trd","delas=0.5"]#  0.974911343510673
    @test JuMP.value(WiNnat._jump_model[Symbol("PFX")]) ≈ WNDCnat["PFX.missing","delas=0.5"]#  0.972241725345085
    @test JuMP.value(WiNnat._jump_model[Symbol("RA")]) ≈ WNDCnat["RA.missing","delas=0.5"]#  12453.8764709011
    
end