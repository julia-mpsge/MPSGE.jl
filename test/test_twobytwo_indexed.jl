@testitem "TWOBYTWO (indexed version)" begin 
    using XLSX, MPSGE.JuMP.Containers
    import JuMP
    
    m = MPSGEModel()
    goods = [:x, :y]
    factors = [:l, :k]
    consumers = [:ra]
    factor = DenseAxisArray(Float64[50 50; 20 30], goods, factors)
    supply = DenseAxisArray(Float64[100, 50], goods)
    raw_endow = DenseAxisArray([70,80], factors)
    raw_outax = DenseAxisArray([0,0], goods)
    raw_intax = DenseAxisArray([0,0], goods)
    
    @parameters(m, begin
        endow, raw_endow, (index = [factors],)
        outax, raw_outax, (index = [goods],)
        intax, raw_intax, (index = [goods],)
    end)

    @sectors(m, begin
        Y, (index = [goods],)
        U
    end)

    @commodities(m, begin
        PC, (index = [goods],)
        PU
        PF, (index = [factors],)
    end)

    @consumer(m, C, index = [consumers])

    for i in goods
        @production(m, Y[i], [t = 0, s = 1], begin
            @output(PC[i], supply[i],    t, taxes = [Tax(C[:ra], outax[i])])
            @input(PF[:l], factor[i,:l], s, taxes = [Tax(C[:ra], intax[i])]) 
            @input(PF[:k], factor[i,:k], s)
        end)      
    end

    @production(m, U, [t = 0, s = 1], begin
        @output(PU, 150, t)
        @input(PC[:x], 100, s)
        @input(PC[:y], 50, s)
    end)
    
    @demand(m, C[:ra], begin
            @final_demand(PU,150)            
            @endowment(PF[:l], endow[:l])
            @endowment(PF[:k], endow[:k]) 
    end)

    solve!(m, cumulative_iteration_limit=0)
    gams_results = XLSX.readxlsx(joinpath(@__DIR__, "MPSGEresults.xlsx"))
    a_table = gams_results["TwoxTwoScalar"][:]  # Generated from TwoByTwo_Scalar_Algeb-MPSGE.gms
    two_by_two_scalar_results = DenseAxisArray(a_table[2:end,2:end],a_table[2:end,1],a_table[1,2:end])

    @test value(Y[:x]) ≈ two_by_two_scalar_results["Y.L","benchmark"] # 1.
    @test value(Y[:y]) ≈ two_by_two_scalar_results["X.L","benchmark"] # 1.
    @test value(U) ≈ two_by_two_scalar_results["U.L","benchmark"] # 1.
    @test value(C[:ra]) ≈ two_by_two_scalar_results["RA.L","benchmark"] # 150.
    @test value(PC[:x]) ≈ two_by_two_scalar_results["PX.L","benchmark"] # 1.
    @test value(PC[:y]) ≈ two_by_two_scalar_results["PY.L","benchmark"] # 1.
    @test value(PU) ≈ two_by_two_scalar_results["PU.L","benchmark"] # 1.
    @test value(PF[:l]) ≈ two_by_two_scalar_results["PL.L","benchmark"] # 1.
    @test value(PF[:k]) ≈ two_by_two_scalar_results["PK.L","benchmark"] # 1.
    @test value(compensated_demand(Y[:x], PF[:l])) ≈ two_by_two_scalar_results["LX.L","benchmark"] # 50.
    @test value(compensated_demand(Y[:y], PF[:l])) ≈ two_by_two_scalar_results["LY.L","benchmark"] # 20.
    @test value(compensated_demand(Y[:x], PF[:k])) ≈ two_by_two_scalar_results["KX.L","benchmark"] # 50.
    @test value(compensated_demand(Y[:y], PF[:k])) ≈ two_by_two_scalar_results["KY.L","benchmark"] # 30.
    @test value(compensated_demand(U, PC[:x])) ≈ two_by_two_scalar_results["DX.L","benchmark"] # 100.
    @test value(compensated_demand(U, PC[:y])) ≈ two_by_two_scalar_results["DY.L","benchmark"] # 50.


    fix(PC[:x], 1)
    set_value!(endow[:l], value(endow[:l]).*1.1)
    fix(C[:ra], 157)
    solve!(m)

    @test value(Y[:x]) ≈ two_by_two_scalar_results["X.L","RA=157"] # 1.04986567
    @test value(Y[:y]) ≈ two_by_two_scalar_results["Y.L","RA=157"] # 1.03676649
    @test value(U) ≈ two_by_two_scalar_results["U.L","RA=157"] # 1.04335615
    @test value(C[:ra]) ≈ two_by_two_scalar_results["RA.L","RA=157"] # 157
    @test value(PC[:x]) ≈ two_by_two_scalar_results["PX.L","RA=157"] # 1.
    @test value(PC[:y]) ≈ two_by_two_scalar_results["PY.L","RA=157"] # 1.00954909
    @test value(PU) ≈ two_by_two_scalar_results["PU.L","RA=157"] # 1.00317295
    @test value(PF[:l]) ≈ two_by_two_scalar_results["PL.L","RA=157"] # 0.95359243
    @test value(PF[:k]) ≈ two_by_two_scalar_results["PK.L","RA=157"] # 1.04866605
    @test value(compensated_demand(Y[:x], PF[:l])) ≈ two_by_two_scalar_results["LX.L","RA=157"] # 52.43330226
    @test value(compensated_demand(Y[:y], PF[:l])) ≈ two_by_two_scalar_results["LY.L","RA=157"] # 21.17359701
    @test value(compensated_demand(Y[:x], PF[:k])) ≈ two_by_two_scalar_results["KX.L","RA=157"] # 47.67962139
    @test value(compensated_demand(Y[:y], PF[:k])) ≈ two_by_two_scalar_results["KY.L","RA=157"] # 28.880951
    @test value(compensated_demand(U, PC[:x])) ≈ two_by_two_scalar_results["DX.L","RA=157"] # 100.3172951
    @test value(compensated_demand(U, PC[:y])) ≈ two_by_two_scalar_results["DY.L","RA=157"] # 49.68420864

    unfix(C[:ra])
    fix(PC[:x],1)

    solve!(m)
    @test value(Y[:x]) ≈ two_by_two_scalar_results["X.L","PX=1"] # 1.04880885
    @test value(Y[:y]) ≈ two_by_two_scalar_results["Y.L","PX=1"] # 1.03886012
    @test value(U) ≈ two_by_two_scalar_results["U.L","PX=1"] # 1.04548206
    @test value(C[:ra]) ≈ two_by_two_scalar_results["RA.L","PX=1"] # 157.321327225523
    @test value(PC[:x]) ≈ two_by_two_scalar_results["PX.L","PX=1"] # 1.0000000000
    @test value(PC[:y]) ≈ two_by_two_scalar_results["PY.L","PX=1"] # 1.00957658
    @test value(PU) ≈ two_by_two_scalar_results["PU.L","PX=1"] # 1.00318206
    @test value(PF[:l]) ≈ two_by_two_scalar_results["PL.L","PX=1"] # 0.95346259
    @test value(PF[:k]) ≈ two_by_two_scalar_results["PK.L","PX=1"] # 1.04880885
    @test value(compensated_demand(Y[:x], PF[:l])) ≈ two_by_two_scalar_results["LX.L","PX=1"] # 52.4404424085075
    @test value(compensated_demand(Y[:y], PF[:l])) ≈ two_by_two_scalar_results["LY.L","PX=1"] # 21.1770570584356
    @test value(compensated_demand(Y[:x], PF[:k])) ≈ two_by_two_scalar_results["KX.L","PX=1"] # 47.6731294622795
    @test value(compensated_demand(Y[:y], PF[:k])) ≈ two_by_two_scalar_results["KY.L","PX=1"] # 28.877805079685
    @test value(compensated_demand(U, PC[:x])) ≈ two_by_two_scalar_results["DX.L","PX=1"] # 100.318205802571
    @test value(compensated_demand(U, PC[:y])) ≈ two_by_two_scalar_results["DY.L","PX=1"] # 49.6833066029729

    unfix(PC[:x])
    fix(PF[:l], 1)
    solve!(m)
            
    @test value(Y[:x]) ≈ two_by_two_scalar_results["X.L","PL=1"] # 1.04880885
    @test value(Y[:y]) ≈ two_by_two_scalar_results["Y.L","PL=1"] # 1.03886012
    @test value(U) ≈ two_by_two_scalar_results["U.L","PL=1"] # 1.04548206
    @test value(C[:ra]) ≈ two_by_two_scalar_results["RA.L","PL=1"] # 165
    @test value(PC[:x]) ≈ two_by_two_scalar_results["PX.L","PL=1"] # 1.04880885
    @test value(PC[:y]) ≈ two_by_two_scalar_results["PY.L","PL=1"] # 1.05885285
    @test value(PU) ≈ two_by_two_scalar_results["PU.L","PL=1"] # 1.05214622
    @test value(PF[:l]) ≈ two_by_two_scalar_results["PL.L","PL=1"] # 1.
    @test value(PF[:k]) ≈ two_by_two_scalar_results["PK.L","PL=1"] # 1.1
    @test value(compensated_demand(Y[:x], PF[:l])) ≈ two_by_two_scalar_results["LX.L","PL=1"] # 52.44044241
    @test value(compensated_demand(Y[:y], PF[:l])) ≈ two_by_two_scalar_results["LY.L","PL=1"] # 21.17705706
    @test value(compensated_demand(Y[:x], PF[:k])) ≈ two_by_two_scalar_results["KX.L","PL=1"] # 47.67312946
    @test value(compensated_demand(Y[:y], PF[:k])) ≈ two_by_two_scalar_results["KY.L","PL=1"] # 28.87780508
    @test value(compensated_demand(U, PC[:x])) ≈ two_by_two_scalar_results["DX.L","PL=1"] # 100.3182058
    @test value(compensated_demand(U, PC[:y])) ≈ two_by_two_scalar_results["DY.L","PL=1"] # 49.6833066

    # Test indexed Taxes, Output taxes, then Input Taxes
    gams_results = XLSX.readxlsx(joinpath(@__DIR__, "MPSGEresults.xlsx"))
    a_table = gams_results["TwoxTwowOTax"][:]  # Generated from TwoByTwo_Scalar_wTax-MPSGE.gms
    two_by_two_scalar_results = DenseAxisArray(a_table[2:end,2:end],a_table[2:end,1],a_table[1,2:end])

    set_value!(outax[:x], 0.1)
    solve!(m)

    @test value(Y[:x]) ≈ two_by_two_scalar_results["X.L","Otax=.1"]#    1.0116855688658395
    @test value(Y[:y]) ≈ two_by_two_scalar_results["Y.L","Otax=.1"]#    1.1123672179049628
    @test value(U) ≈ two_by_two_scalar_results["U.L","Otax=.1"]#    1.0441905629409307
    @test value(C[:ra]) ≈ two_by_two_scalar_results["RA.L","Otax=.1"]#    177.69230689285564
    @test value(PC[:x]) ≈ two_by_two_scalar_results["PX.L","Otax=.1"]#    1.170932369505204
    @test value(PC[:y]) ≈ two_by_two_scalar_results["PY.L","Otax=.1"]#    1.064949920418856
    @test value(PU) ≈ two_by_two_scalar_results["PU.L","Otax=.1"]#    1.1344819828665367
    @test value(PF[:l]) ≈ two_by_two_scalar_results["PL.L","Otax=.1"]#    1.
    @test value(PF[:k]) ≈ two_by_two_scalar_results["PK.L","Otax=.1"]#    1.1105769136174084
# Implicit Variables
    @test value(compensated_demand(Y[:x], PF[:l])) ≈ two_by_two_scalar_results["DXL.L","Otax=.1"]#    52.69195654028726
    @test value(compensated_demand(Y[:y], PF[:l])) ≈ two_by_two_scalar_results["DYL.L","Otax=.1"]#    21.298998374443727
    @test value(compensated_demand(Y[:x], PF[:k])) ≈ two_by_two_scalar_results["DXK.L","Otax=.1"]#    47.44557166118035
    @test value(compensated_demand(Y[:y], PF[:k])) ≈ two_by_two_scalar_results["DYK.L","Otax=.1"]#    28.767478568955543
    @test value(compensated_demand(U, PC[:x])) ≈ two_by_two_scalar_results["DUX.L","Otax=.1"]#    96.88706302697432
    @test value(compensated_demand(U, PC[:y])) ≈ two_by_two_scalar_results["DUY.L","Otax=.1"]#    53.26456958649977
    @test value(compensated_demand(Y[:x], PC[:x], :t)) ≈ -two_by_two_scalar_results["SX.L","Otax=.1"]#    101.16855688658394
    @test value(compensated_demand(Y[:y], PC[:y], :t)) ≈ -two_by_two_scalar_results["SY.L","Otax=.1"]#    50.
    @test value(compensated_demand(U, PU, :t)) ≈ -two_by_two_scalar_results["SU.L","Otax=.1"]#    50.
    @test value(demand(C[:ra], PU)) ≈ two_by_two_scalar_results["CWI.L","Otax=.1"] # 156.6285843

    #Tax on labor for good/sector x (single output sector) 
    set_value!(outax[:x], 0.0)
    set_value!(intax[:x], 0.1)
    solve!(m)
    
    @test value(Y[:x]) ≈ two_by_two_scalar_results["X.L","Itax=.1"] # 1.03413947
    @test value(Y[:y]) ≈ two_by_two_scalar_results["Y.L","Itax=.1"] # 1.06713746
    @test value(U) ≈ two_by_two_scalar_results["U.L","Itax=.1"] # 1.04502384
    @test value(C[:ra]) ≈ two_by_two_scalar_results["RA.L","Itax=.1"] # 176.4583
    @test value(PC[:x]) ≈ two_by_two_scalar_results["PX.L","Itax=.1"] # 1.13755342
    @test value(PC[:y]) ≈ two_by_two_scalar_results["PY.L","Itax=.1"] # 1.10237802
    @test value(PU) ≈ two_by_two_scalar_results["PU.L","Itax=.1"] # 1.12570531
    @test value(PF[:l]) ≈ two_by_two_scalar_results["PL.L","Itax=.1"] # 1
    @test value(PF[:k]) ≈ two_by_two_scalar_results["PK.L","Itax=.1"] # 1.17638888
    # Implicit Variables # 
    @test value(compensated_demand(Y[:x], PF[:l])) ≈ two_by_two_scalar_results["DXL.L","Itax=.1"] # 100
    @test value(compensated_demand(Y[:y], PF[:l])) ≈ two_by_two_scalar_results["DYL.L","Itax=.1"] # 50
    @test value(compensated_demand(Y[:x], PF[:k])) ≈ two_by_two_scalar_results["DXK.L","Itax=.1"] # 51.70697336
    @test value(compensated_demand(Y[:y], PF[:k])) ≈ two_by_two_scalar_results["DYK.L","Itax=.1"] # 48.349378
    @test value(compensated_demand(U, PC[:x])) ≈ two_by_two_scalar_results["DUX.L","Itax=.1"] # 22.04756047
    @test value(compensated_demand(U, PC[:y])) ≈ two_by_two_scalar_results["DUY.L","Itax=.1"] # 28.11259204
    @test value(compensated_demand(Y[:x], PC[:x], :t)) ≈ -two_by_two_scalar_results["SX.L","Itax=.1"] # 150
    @test value(compensated_demand(Y[:y], PC[:y], :t)) ≈ -two_by_two_scalar_results["SY.L","Itax=.1"] # 98.95845727
    @test value(compensated_demand(U, PU, :t)) ≈ -two_by_two_scalar_results["SU.L","Itax=.1"] # 51.05804385
    @test value(demand(C[:ra], PU)) ≈ two_by_two_scalar_results["CWI.L","Itax=.1"] # 150
end


@testitem "TWOBYTWO (indexed w non-1 Input prices)" begin 
    using XLSX, MPSGE.JuMP.Containers
    import JuMP

    m = MPSGEModel()
    goods = [:x, :y]
    factors = [:l, :k]
    consumers = [:ra]
    factor = DenseAxisArray(Float64[50 50; 20 30], goods, factors)
    supply = DenseAxisArray(Float64[100, 50], goods)
    raw_pricepci = DenseAxisArray([1,1], goods)
    raw_endow = DenseAxisArray([70,80], factors)
    
    @parameters(m, begin
        endow, raw_endow, (index = [factors],)
        pricepci, raw_pricepci, (index = [goods],)
    end)
    
    @sectors(m, begin
        Y, (index = [goods],)
        U
    end)

    @commodities(m, begin
        PC, (index = [goods],)
        PU
        PF, (index = [factors],)
    end)

    @consumer(m, C, index = [consumers])


    for i in goods
        @production(m, Y[i], [t = 0, s = 1], begin 
            @output(PC[i], supply[i], t)
            @input(PF[:l], factor[i,:l], s)
            @input(PF[:k], factor[i,:k], s)
        end)      
    end

    @production(m, U, [t = 0, s = 1], begin
            @output(PU, 150, t)
            [@input(PC[i], supply[i], s, reference_price = pricepci[i]) for i∈goods]...
    end)
    
    @demand(m, C[:ra], begin
            @final_demand(PU,150)            
            @endowment(PF[:l], endow[:l])
            @endowment(PF[:k], endow[:k])
    end)

    solve!(m, cumulative_iteration_limit=0)

    gams_results = XLSX.readxlsx(joinpath(@__DIR__, "MPSGEresults.xlsx"))
    a_table = gams_results["TwoxTwowOTax_IndPrice_Nest"][:]  # Generated from TwoByTwo_Scalar_Algeb-MPSGE.gms
    TwoxTwowOTax_IndPrice_Nest = DenseAxisArray(a_table[2:end,2:end],string.(a_table[2:end,1],".",a_table[2:end,2]),a_table[1,2:end])

    # benchmark
    @test value(compensated_demand(Y[:x], PF[:l])) ≈ TwoxTwowOTax_IndPrice_Nest["x.L","benchmark"]#  50
    @test value(compensated_demand(Y[:x], PF[:k])) ≈ TwoxTwowOTax_IndPrice_Nest["x.K","benchmark"]#  50
    @test value(compensated_demand(Y[:y], PF[:l])) ≈ TwoxTwowOTax_IndPrice_Nest["y.L","benchmark"]#  20
    @test value(compensated_demand(Y[:y], PF[:k])) ≈ TwoxTwowOTax_IndPrice_Nest["y.K","benchmark"]#  30
    @test value(Y[:x]) ≈ TwoxTwowOTax_IndPrice_Nest["Y.L.x","benchmark"]#  1
    @test value(Y[:y]) ≈ TwoxTwowOTax_IndPrice_Nest["Y.L.y","benchmark"]#  1
    @test value(U) ≈ TwoxTwowOTax_IndPrice_Nest["U.L._","benchmark"]#  1
    @test value(PC[:x]) ≈ TwoxTwowOTax_IndPrice_Nest["PC.L.x","benchmark"]#  1
    @test value(PC[:y]) ≈ TwoxTwowOTax_IndPrice_Nest["PC.L.y","benchmark"]#  1
    @test value(PF[:l]) ≈ TwoxTwowOTax_IndPrice_Nest["PF.L.L","benchmark"]#  1
    @test value(PF[:k]) ≈ TwoxTwowOTax_IndPrice_Nest["PF.L.K","benchmark"]#  1
    @test value(PU) ≈ TwoxTwowOTax_IndPrice_Nest["PU.L._","benchmark"]#  1
    @test value(compensated_demand(U, PC[:x])) ≈ TwoxTwowOTax_IndPrice_Nest["DU.L.x","benchmark"]#  100
    @test value(compensated_demand(U, PC[:y])) ≈ TwoxTwowOTax_IndPrice_Nest["DU.L.y","benchmark"]#  50
    @test value(compensated_demand(U, PU, :t)) ≈ -TwoxTwowOTax_IndPrice_Nest["SU.L._","benchmark"]#  150
    @test value(compensated_demand(Y[:x], PC[:x], :t)) ≈ -TwoxTwowOTax_IndPrice_Nest["SY.L(i).x","benchmark"]#  100
    @test value(compensated_demand(Y[:y], PC[:y], :t)) ≈ -TwoxTwowOTax_IndPrice_Nest["SY.L(i).y","benchmark"]#  50
    @test value(C[:ra]) ≈ TwoxTwowOTax_IndPrice_Nest["RA.L._","benchmark"]#  150
    @test value(demand(C[:ra], PU)) ≈ TwoxTwowOTax_IndPrice_Nest["FDRA.L._","benchmark"]#  150	

    set_value!(endow[:l], value(endow[:l])*1.1)
    fix(C[:ra], 157)
    solve!(m)

    # RA=157
    @test value(compensated_demand(Y[:x], PF[:l])) ≈ TwoxTwowOTax_IndPrice_Nest["x.L","RA=157"]#  52.4404424
    @test value(compensated_demand(Y[:x], PF[:k])) ≈ TwoxTwowOTax_IndPrice_Nest["x.K","RA=157"]#  47.6731295
    @test value(compensated_demand(Y[:y], PF[:l])) ≈ TwoxTwowOTax_IndPrice_Nest["y.L","RA=157"]#  21.1770571
    @test value(compensated_demand(Y[:y], PF[:k])) ≈ TwoxTwowOTax_IndPrice_Nest["y.K","RA=157"]#  28.8778051
    @test value(Y[:x]) ≈ TwoxTwowOTax_IndPrice_Nest["Y.L.x","RA=157"]#  1.0488088
    @test value(Y[:y]) ≈ TwoxTwowOTax_IndPrice_Nest["Y.L.y","RA=157"]#  1.0388601
    @test value(U) ≈ TwoxTwowOTax_IndPrice_Nest["U.L._","RA=157"]#  1.0454821
    @test value(PC[:x]) ≈ TwoxTwowOTax_IndPrice_Nest["PC.L.x","RA=157"]#  0.9979575
    @test value(PC[:y]) ≈ TwoxTwowOTax_IndPrice_Nest["PC.L.y","RA=157"]#  1.0075145
    @test value(PF[:l]) ≈ TwoxTwowOTax_IndPrice_Nest["PF.L.L","RA=157"]#  0.9515152
    @test value(PF[:k]) ≈ TwoxTwowOTax_IndPrice_Nest["PF.L.K","RA=157"]#  1.0466667
    @test value(PU) ≈ TwoxTwowOTax_IndPrice_Nest["PU.L._","RA=157"]#  1.0011331
    @test value(compensated_demand(U, PC[:x])) ≈ TwoxTwowOTax_IndPrice_Nest["DU.L.x","RA=157"]#  100.3182058
    @test value(compensated_demand(U, PC[:y])) ≈ TwoxTwowOTax_IndPrice_Nest["DU.L.y","RA=157"]#  49.6833066
    @test value(compensated_demand(U, PU, :t)) ≈ -TwoxTwowOTax_IndPrice_Nest["SU.L._","RA=157"]#  150
    @test value(compensated_demand(Y[:x], PC[:x], :t)) ≈ -TwoxTwowOTax_IndPrice_Nest["SY.L(i).x","RA=157"]#  100
    @test value(compensated_demand(Y[:y], PC[:y], :t)) ≈ -TwoxTwowOTax_IndPrice_Nest["SY.L(i).y","RA=157"]#  50
    @test value(C[:ra]) ≈ TwoxTwowOTax_IndPrice_Nest["RA.L._","RA=157"]#  157
    @test value(demand(C[:ra], PU)) ≈ TwoxTwowOTax_IndPrice_Nest["FDRA.L._","RA=157"]#  156.8223095	

    unfix(C[:ra])
    fix(PC[:x], 1)
    solve!(m)

    # PC.x=1
    @test value(compensated_demand(Y[:x], PF[:l])) ≈ TwoxTwowOTax_IndPrice_Nest["x.L","PC.x=1"]#  52.4404424
    @test value(compensated_demand(Y[:x], PF[:k])) ≈ TwoxTwowOTax_IndPrice_Nest["x.K","PC.x=1"]#  47.6731295
    @test value(compensated_demand(Y[:y], PF[:l])) ≈ TwoxTwowOTax_IndPrice_Nest["y.L","PC.x=1"]#  21.1770571
    @test value(compensated_demand(Y[:y], PF[:k])) ≈ TwoxTwowOTax_IndPrice_Nest["y.K","PC.x=1"]#  28.8778051
    @test value(Y[:x]) ≈ TwoxTwowOTax_IndPrice_Nest["Y.L.x","PC.x=1"]#  1.0488088
    @test value(Y[:y]) ≈ TwoxTwowOTax_IndPrice_Nest["Y.L.y","PC.x=1"]#  1.0388601
    @test value(U) ≈ TwoxTwowOTax_IndPrice_Nest["U.L._","PC.x=1"]#  1.0454821
    @test value(PC[:x]) ≈ TwoxTwowOTax_IndPrice_Nest["PC.L.x","PC.x=1"]#  1
    @test value(PC[:y]) ≈ TwoxTwowOTax_IndPrice_Nest["PC.L.y","PC.x=1"]#  1.0095766
    @test value(PF[:l]) ≈ TwoxTwowOTax_IndPrice_Nest["PF.L.L","PC.x=1"]#  0.9534626
    @test value(PF[:k]) ≈ TwoxTwowOTax_IndPrice_Nest["PF.L.K","PC.x=1"]#  1.0488088
    @test value(PU) ≈ TwoxTwowOTax_IndPrice_Nest["PU.L._","PC.x=1"]#  1.0031821
    @test value(compensated_demand(U, PC[:x])) ≈ TwoxTwowOTax_IndPrice_Nest["DU.L.x","PC.x=1"]#  100.3182058
    @test value(compensated_demand(U, PC[:y])) ≈ TwoxTwowOTax_IndPrice_Nest["DU.L.y","PC.x=1"]#  49.6833066
    @test value(compensated_demand(U, PU, :t)) ≈ -TwoxTwowOTax_IndPrice_Nest["SU.L._","PC.x=1"]#  150
    @test value(compensated_demand(Y[:x], PC[:x], :t)) ≈ -TwoxTwowOTax_IndPrice_Nest["SY.L(i).x","PC.x=1"]#  100
    @test value(compensated_demand(Y[:y], PC[:y], :t)) ≈ -TwoxTwowOTax_IndPrice_Nest["SY.L(i).y","PC.x=1"]#  50
    @test value(C[:ra]) ≈ TwoxTwowOTax_IndPrice_Nest["RA.L._","PC.x=1"]#  157.3213272
    @test value(demand(C[:ra], PU)) ≈ TwoxTwowOTax_IndPrice_Nest["FDRA.L._","PC.x=1"]#  156.8223095	

    unfix(PC[:x])
    fix(PF[:l], 1)
    solve!(m)

    # PF.l=1
    @test value(compensated_demand(Y[:x], PF[:l])) ≈ TwoxTwowOTax_IndPrice_Nest["x.L","PF.l=1"]#  52.4404424
    @test value(compensated_demand(Y[:x], PF[:k])) ≈ TwoxTwowOTax_IndPrice_Nest["x.K","PF.l=1"]#  47.6731295
    @test value(compensated_demand(Y[:y], PF[:l])) ≈ TwoxTwowOTax_IndPrice_Nest["y.L","PF.l=1"]#  21.1770571
    @test value(compensated_demand(Y[:y], PF[:k])) ≈ TwoxTwowOTax_IndPrice_Nest["y.K","PF.l=1"]#  28.8778051
    @test value(Y[:x]) ≈ TwoxTwowOTax_IndPrice_Nest["Y.L.x","PF.l=1"]#  1.0488088
    @test value(Y[:y]) ≈ TwoxTwowOTax_IndPrice_Nest["Y.L.y","PF.l=1"]#  1.0388601
    @test value(U) ≈ TwoxTwowOTax_IndPrice_Nest["U.L._","PF.l=1"]#  1.0454821
    @test value(PC[:x]) ≈ TwoxTwowOTax_IndPrice_Nest["PC.L.x","PF.l=1"]#  1.0488088
    @test value(PC[:y]) ≈ TwoxTwowOTax_IndPrice_Nest["PC.L.y","PF.l=1"]#  1.0588529
    @test value(PF[:l]) ≈ TwoxTwowOTax_IndPrice_Nest["PF.L.L","PF.l=1"]#  1
    @test value(PF[:k]) ≈ TwoxTwowOTax_IndPrice_Nest["PF.L.K","PF.l=1"]#  1.1
    @test value(PU) ≈ TwoxTwowOTax_IndPrice_Nest["PU.L._","PF.l=1"]#  1.0521462
    @test value(compensated_demand(U, PC[:x])) ≈ TwoxTwowOTax_IndPrice_Nest["DU.L.x","PF.l=1"]#  100.3182058
    @test value(compensated_demand(U, PC[:y])) ≈ TwoxTwowOTax_IndPrice_Nest["DU.L.y","PF.l=1"]#  49.6833066
    @test value(compensated_demand(U, PU, :t)) ≈ -TwoxTwowOTax_IndPrice_Nest["SU.L._","PF.l=1"]#  150
    @test value(compensated_demand(Y[:x], PC[:x], :t)) ≈ -TwoxTwowOTax_IndPrice_Nest["SY.L(i).x","PF.l=1"]#  100
    @test value(compensated_demand(Y[:y], PC[:y], :t)) ≈ -TwoxTwowOTax_IndPrice_Nest["SY.L(i).y","PF.l=1"]#  50
    @test value(C[:ra]) ≈ TwoxTwowOTax_IndPrice_Nest["RA.L._","PF.l=1"]#  165
    @test value(demand(C[:ra], PU)) ≈ TwoxTwowOTax_IndPrice_Nest["FDRA.L._","PF.l=1"]#  156.8223095	

    set_value!(pricepci[:x] , 2)
    solve!(m)
    
    # Pr.x=2
    @test value(compensated_demand(Y[:x], PF[:l])) ≈ TwoxTwowOTax_IndPrice_Nest["x.L","Pr.x=2"]#  51.0565454
    @test value(compensated_demand(Y[:x], PF[:k])) ≈ TwoxTwowOTax_IndPrice_Nest["x.K","Pr.x=2"]#  48.9653184
    @test value(compensated_demand(Y[:y], PF[:l])) ≈ TwoxTwowOTax_IndPrice_Nest["y.L","Pr.x=2"]#  20.5082074
    @test value(compensated_demand(Y[:y], PF[:k])) ≈ TwoxTwowOTax_IndPrice_Nest["y.K","Pr.x=2"]#  29.5023165
    @test value(Y[:x]) ≈ TwoxTwowOTax_IndPrice_Nest["Y.L.x","Pr.x=2"]#  1.2567765
    @test value(Y[:y]) ≈ TwoxTwowOTax_IndPrice_Nest["Y.L.y","Pr.x=2"]#  0.6257657
    @test value(U) ≈ TwoxTwowOTax_IndPrice_Nest["U.L._","Pr.x=2"]#  1.0931727
    @test value(PC[:x]) ≈ TwoxTwowOTax_IndPrice_Nest["PC.L.x","Pr.x=2"]#  1.0211309
    @test value(PC[:y]) ≈ TwoxTwowOTax_IndPrice_Nest["PC.L.y","Pr.x=2"]#  1.0254104
    @test value(PF[:l]) ≈ TwoxTwowOTax_IndPrice_Nest["PF.L.L","Pr.x=2"]#  1
    @test value(PF[:k]) ≈ TwoxTwowOTax_IndPrice_Nest["PF.L.K","Pr.x=2"]#  1.0427083
    @test value(PU) ≈ TwoxTwowOTax_IndPrice_Nest["PU.L._","Pr.x=2"]#  0.9782941
    @test value(compensated_demand(U, PC[:x])) ≈ TwoxTwowOTax_IndPrice_Nest["DU.L.x","Pr.x=2"]#  114.9659562
    @test value(compensated_demand(U, PC[:y])) ≈ TwoxTwowOTax_IndPrice_Nest["DU.L.y","Pr.x=2"]#  28.6215389
    @test value(compensated_demand(U, PU, :t)) ≈ -TwoxTwowOTax_IndPrice_Nest["SU.L._","Pr.x=2"]#  150
    @test value(compensated_demand(Y[:x], PC[:x], :t)) ≈ -TwoxTwowOTax_IndPrice_Nest["SY.L(i).x","Pr.x=2"]#  100
    @test value(compensated_demand(Y[:y], PC[:y], :t)) ≈ -TwoxTwowOTax_IndPrice_Nest["SY.L(i).y","Pr.x=2"]#  50
    @test value(C[:ra]) ≈ TwoxTwowOTax_IndPrice_Nest["RA.L._","Pr.x=2"]#  160.4166664
    @test value(demand(C[:ra], PU)) ≈ TwoxTwowOTax_IndPrice_Nest["FDRA.L._","Pr.x=2"]#  163.9759121

end

@testitem "TWOBYTWO (indexed w non-1 Input prices and input nesting)" begin 
    using XLSX, MPSGE.JuMP.Containers
    import JuMP

    m = MPSGEModel()
    goods = [:x, :y]
    factors = [:l, :k]
    consumers = [:ra]
    factor = DenseAxisArray(Float64[50 50; 20 30], goods, factors)
    supply = DenseAxisArray(Float64[100, 50], goods)
    raw_pricepci = DenseAxisArray([1,1], goods)
    raw_endow = DenseAxisArray([70,80], factors)
    
    @parameters(m, begin
        endow, raw_endow, (index = [factors],)
        pricepci, raw_pricepci, (index = [goods],)
    end)
    
    @sectors(m, begin
        Y, (index = [goods],)
        U
    end)

    @commodities(m, begin
        PC, (index = [goods],)
        PU
        PF, (index = [factors],)
    end)

    @consumer(m, C, index = [consumers])

    for i in goods
        @production(m, Y[i], [t = 0, s = 1], begin
            @output(PC[i], supply[i], t)
            @input(PF[:l], factor[i,:l], s)
            @input(PF[:k], factor[i,:k], s)
        end)      
    end
    
    @production(m, U, [t = 0, s = 1, PCi => s = 1], begin
        @output(PU, 150, t)
        [@input(PC[i], supply[i], PCi, reference_price = pricepci[i]) for i∈goods]...
    end)
    
    @demand(m, C[:ra], begin
            @final_demand(PU,150)            
            @endowment(PF[:l], endow[:l])
            @endowment(PF[:k], endow[:k])
    end)

    solve!(m, cumulative_iteration_limit=0)

    gams_results = XLSX.readxlsx(joinpath(@__DIR__, "MPSGEresults.xlsx"))
    a_table = gams_results["TwoxTwowOTax_IndPrice_Nest"][:]  # Generated from TwoByTwo_Scalar_Algeb-MPSGE.gms
    TwoxTwowOTax_IndPrice_Nest = DenseAxisArray(a_table[2:end,2:end],string.(a_table[2:end,1],".",a_table[2:end,2]),a_table[1,2:end])

    # benchmark
    @test value(compensated_demand(Y[:x], PF[:l])) ≈ TwoxTwowOTax_IndPrice_Nest["x.L","benchmark"]#  50
    @test value(compensated_demand(Y[:x], PF[:k])) ≈ TwoxTwowOTax_IndPrice_Nest["x.K","benchmark"]#  50
    @test value(compensated_demand(Y[:y], PF[:l])) ≈ TwoxTwowOTax_IndPrice_Nest["y.L","benchmark"]#  20
    @test value(compensated_demand(Y[:y], PF[:k])) ≈ TwoxTwowOTax_IndPrice_Nest["y.K","benchmark"]#  30
    @test value(Y[:x]) ≈ TwoxTwowOTax_IndPrice_Nest["Y.L.x","benchmark"]#  1
    @test value(Y[:y]) ≈ TwoxTwowOTax_IndPrice_Nest["Y.L.y","benchmark"]#  1
    @test value(U) ≈ TwoxTwowOTax_IndPrice_Nest["U.L._","benchmark"]#  1
    @test value(PC[:x]) ≈ TwoxTwowOTax_IndPrice_Nest["PC.L.x","benchmark"]#  1
    @test value(PC[:y]) ≈ TwoxTwowOTax_IndPrice_Nest["PC.L.y","benchmark"]#  1
    @test value(PF[:l]) ≈ TwoxTwowOTax_IndPrice_Nest["PF.L.L","benchmark"]#  1
    @test value(PF[:k]) ≈ TwoxTwowOTax_IndPrice_Nest["PF.L.K","benchmark"]#  1
    @test value(PU) ≈ TwoxTwowOTax_IndPrice_Nest["PU.L._","benchmark"]#  1
    @test value(compensated_demand(U,PC[:x])) ≈ TwoxTwowOTax_IndPrice_Nest["DU.L.x","benchmark"]#  100
    @test value(compensated_demand(U,PC[:y])) ≈ TwoxTwowOTax_IndPrice_Nest["DU.L.y","benchmark"]#  50
    @test value(compensated_demand(U, PU, :t)) ≈ -TwoxTwowOTax_IndPrice_Nest["SU.L._","benchmark"]#  150
    @test value(compensated_demand(Y[:x], PC[:x], :t)) ≈ -TwoxTwowOTax_IndPrice_Nest["SY.L(i).x","benchmark"]#  100
    @test value(compensated_demand(Y[:y], PC[:y], :t)) ≈ -TwoxTwowOTax_IndPrice_Nest["SY.L(i).y","benchmark"]#  50
    @test value(C[:ra]) ≈ TwoxTwowOTax_IndPrice_Nest["RA.L._","benchmark"]#  150
    @test value(demand(C[:ra], PU)) ≈ TwoxTwowOTax_IndPrice_Nest["FDRA.L._","benchmark"]#  150	

    set_value!(endow[:l], value(endow[:l])*1.1)
    fix(C[:ra], 157)
    solve!(m)

    # RA=157
    @test value(compensated_demand(Y[:x], PF[:l])) ≈ TwoxTwowOTax_IndPrice_Nest["x.L","RA=157"]#  52.4404424
    @test value(compensated_demand(Y[:x], PF[:k])) ≈ TwoxTwowOTax_IndPrice_Nest["x.K","RA=157"]#  47.6731295
    @test value(compensated_demand(Y[:y], PF[:l])) ≈ TwoxTwowOTax_IndPrice_Nest["y.L","RA=157"]#  21.1770571
    @test value(compensated_demand(Y[:y], PF[:k])) ≈ TwoxTwowOTax_IndPrice_Nest["y.K","RA=157"]#  28.8778051
    @test value(Y[:x]) ≈ TwoxTwowOTax_IndPrice_Nest["Y.L.x","RA=157"]#  1.0488088
    @test value(Y[:y]) ≈ TwoxTwowOTax_IndPrice_Nest["Y.L.y","RA=157"]#  1.0388601
    @test value(U) ≈ TwoxTwowOTax_IndPrice_Nest["U.L._","RA=157"]#  1.0454821
    @test value(PC[:x]) ≈ TwoxTwowOTax_IndPrice_Nest["PC.L.x","RA=157"]#  0.9979575
    @test value(PC[:y]) ≈ TwoxTwowOTax_IndPrice_Nest["PC.L.y","RA=157"]#  1.0075145
    @test value(PF[:l]) ≈ TwoxTwowOTax_IndPrice_Nest["PF.L.L","RA=157"]#  0.9515152
    @test value(PF[:k]) ≈ TwoxTwowOTax_IndPrice_Nest["PF.L.K","RA=157"]#  1.0466667
    @test value(PU) ≈ TwoxTwowOTax_IndPrice_Nest["PU.L._","RA=157"]#  1.0011331
    @test value(compensated_demand(U,PC[:x])) ≈ TwoxTwowOTax_IndPrice_Nest["DU.L.x","RA=157"]#  100.3182058
    @test value(compensated_demand(U,PC[:y])) ≈ TwoxTwowOTax_IndPrice_Nest["DU.L.y","RA=157"]#  49.6833066
    @test value(compensated_demand(U, PU, :t)) ≈ -TwoxTwowOTax_IndPrice_Nest["SU.L._","RA=157"]#  150
    @test value(compensated_demand(Y[:x], PC[:x], :t)) ≈ -TwoxTwowOTax_IndPrice_Nest["SY.L(i).x","RA=157"]#  100
    @test value(compensated_demand(Y[:y], PC[:y], :t)) ≈ -TwoxTwowOTax_IndPrice_Nest["SY.L(i).y","RA=157"]#  50
    @test value(C[:ra]) ≈ TwoxTwowOTax_IndPrice_Nest["RA.L._","RA=157"]#  157
    @test value(demand(C[:ra], PU)) ≈ TwoxTwowOTax_IndPrice_Nest["FDRA.L._","RA=157"]#  156.8223095	

    unfix(C[:ra])
    fix(PC[:x], 1)
    solve!(m)

    # PC.x=1
    @test value(compensated_demand(Y[:x], PF[:l])) ≈ TwoxTwowOTax_IndPrice_Nest["x.L","PC.x=1"]#  52.4404424
    @test value(compensated_demand(Y[:x], PF[:k])) ≈ TwoxTwowOTax_IndPrice_Nest["x.K","PC.x=1"]#  47.6731295
    @test value(compensated_demand(Y[:y], PF[:l])) ≈ TwoxTwowOTax_IndPrice_Nest["y.L","PC.x=1"]#  21.1770571
    @test value(compensated_demand(Y[:y], PF[:k])) ≈ TwoxTwowOTax_IndPrice_Nest["y.K","PC.x=1"]#  28.8778051
    @test value(Y[:x]) ≈ TwoxTwowOTax_IndPrice_Nest["Y.L.x","PC.x=1"]#  1.0488088
    @test value(Y[:y]) ≈ TwoxTwowOTax_IndPrice_Nest["Y.L.y","PC.x=1"]#  1.0388601
    @test value(U) ≈ TwoxTwowOTax_IndPrice_Nest["U.L._","PC.x=1"]#  1.0454821
    @test value(PC[:x]) ≈ TwoxTwowOTax_IndPrice_Nest["PC.L.x","PC.x=1"]#  1
    @test value(PC[:y]) ≈ TwoxTwowOTax_IndPrice_Nest["PC.L.y","PC.x=1"]#  1.0095766
    @test value(PF[:l]) ≈ TwoxTwowOTax_IndPrice_Nest["PF.L.L","PC.x=1"]#  0.9534626
    @test value(PF[:k]) ≈ TwoxTwowOTax_IndPrice_Nest["PF.L.K","PC.x=1"]#  1.0488088
    @test value(PU) ≈ TwoxTwowOTax_IndPrice_Nest["PU.L._","PC.x=1"]#  1.0031821
    @test value(compensated_demand(U,PC[:x])) ≈ TwoxTwowOTax_IndPrice_Nest["DU.L.x","PC.x=1"]#  100.3182058
    @test value(compensated_demand(U,PC[:y])) ≈ TwoxTwowOTax_IndPrice_Nest["DU.L.y","PC.x=1"]#  49.6833066
    @test value(compensated_demand(U, PU, :t)) ≈ -TwoxTwowOTax_IndPrice_Nest["SU.L._","PC.x=1"]#  150
    @test value(compensated_demand(Y[:x], PC[:x], :t)) ≈ -TwoxTwowOTax_IndPrice_Nest["SY.L(i).x","PC.x=1"]#  100
    @test value(compensated_demand(Y[:y], PC[:y], :t)) ≈ -TwoxTwowOTax_IndPrice_Nest["SY.L(i).y","PC.x=1"]#  50
    @test value(C[:ra]) ≈ TwoxTwowOTax_IndPrice_Nest["RA.L._","PC.x=1"]#  157.3213272
    @test value(demand(C[:ra], PU)) ≈ TwoxTwowOTax_IndPrice_Nest["FDRA.L._","PC.x=1"]#  156.8223095	

    unfix(PC[:x])
    fix(PF[:l], 1)
    solve!(m)

    # PF.l=1
    @test value(compensated_demand(Y[:x], PF[:l])) ≈ TwoxTwowOTax_IndPrice_Nest["x.L","PF.l=1"]#  52.4404424
    @test value(compensated_demand(Y[:x], PF[:k])) ≈ TwoxTwowOTax_IndPrice_Nest["x.K","PF.l=1"]#  47.6731295
    @test value(compensated_demand(Y[:y], PF[:l])) ≈ TwoxTwowOTax_IndPrice_Nest["y.L","PF.l=1"]#  21.1770571
    @test value(compensated_demand(Y[:y], PF[:k])) ≈ TwoxTwowOTax_IndPrice_Nest["y.K","PF.l=1"]#  28.8778051
    @test value(Y[:x]) ≈ TwoxTwowOTax_IndPrice_Nest["Y.L.x","PF.l=1"]#  1.0488088
    @test value(Y[:y]) ≈ TwoxTwowOTax_IndPrice_Nest["Y.L.y","PF.l=1"]#  1.0388601
    @test value(U) ≈ TwoxTwowOTax_IndPrice_Nest["U.L._","PF.l=1"]#  1.0454821
    @test value(PC[:x]) ≈ TwoxTwowOTax_IndPrice_Nest["PC.L.x","PF.l=1"]#  1.0488088
    @test value(PC[:y]) ≈ TwoxTwowOTax_IndPrice_Nest["PC.L.y","PF.l=1"]#  1.0588529
    @test value(PF[:l]) ≈ TwoxTwowOTax_IndPrice_Nest["PF.L.L","PF.l=1"]#  1
    @test value(PF[:k]) ≈ TwoxTwowOTax_IndPrice_Nest["PF.L.K","PF.l=1"]#  1.1
    @test value(PU) ≈ TwoxTwowOTax_IndPrice_Nest["PU.L._","PF.l=1"]#  1.0521462
    @test value(compensated_demand(U,PC[:x])) ≈ TwoxTwowOTax_IndPrice_Nest["DU.L.x","PF.l=1"]#  100.3182058
    @test value(compensated_demand(U,PC[:y])) ≈ TwoxTwowOTax_IndPrice_Nest["DU.L.y","PF.l=1"]#  49.6833066
    @test value(compensated_demand(U, PU, :t)) ≈ -TwoxTwowOTax_IndPrice_Nest["SU.L._","PF.l=1"]#  150
    @test value(compensated_demand(Y[:x], PC[:x], :t)) ≈ -TwoxTwowOTax_IndPrice_Nest["SY.L(i).x","PF.l=1"]#  100
    @test value(compensated_demand(Y[:y], PC[:y], :t)) ≈ -TwoxTwowOTax_IndPrice_Nest["SY.L(i).y","PF.l=1"]#  50
    @test value(C[:ra]) ≈ TwoxTwowOTax_IndPrice_Nest["RA.L._","PF.l=1"]#  165
    @test value(demand(C[:ra], PU)) ≈ TwoxTwowOTax_IndPrice_Nest["FDRA.L._","PF.l=1"]#  156.8223095	

    set_value!(pricepci[:x] , 2)
    solve!(m)
    
    # Pr.x=2
    @test value(compensated_demand(Y[:x], PF[:l])) ≈ TwoxTwowOTax_IndPrice_Nest["x.L","Pr.x=2"]#  51.0565454
    @test value(compensated_demand(Y[:x], PF[:k])) ≈ TwoxTwowOTax_IndPrice_Nest["x.K","Pr.x=2"]#  48.9653184
    @test value(compensated_demand(Y[:y], PF[:l])) ≈ TwoxTwowOTax_IndPrice_Nest["y.L","Pr.x=2"]#  20.5082074
    @test value(compensated_demand(Y[:y], PF[:k])) ≈ TwoxTwowOTax_IndPrice_Nest["y.K","Pr.x=2"]#  29.5023165
    @test value(Y[:x]) ≈ TwoxTwowOTax_IndPrice_Nest["Y.L.x","Pr.x=2"]#  1.2567765
    @test value(Y[:y]) ≈ TwoxTwowOTax_IndPrice_Nest["Y.L.y","Pr.x=2"]#  0.6257657
    @test value(U) ≈ TwoxTwowOTax_IndPrice_Nest["U.L._","Pr.x=2"]#  1.0931727
    @test value(PC[:x]) ≈ TwoxTwowOTax_IndPrice_Nest["PC.L.x","Pr.x=2"]#  1.0211309
    @test value(PC[:y]) ≈ TwoxTwowOTax_IndPrice_Nest["PC.L.y","Pr.x=2"]#  1.0254104
    @test value(PF[:l]) ≈ TwoxTwowOTax_IndPrice_Nest["PF.L.L","Pr.x=2"]#  1
    @test value(PF[:k]) ≈ TwoxTwowOTax_IndPrice_Nest["PF.L.K","Pr.x=2"]#  1.0427083
    @test value(PU) ≈ TwoxTwowOTax_IndPrice_Nest["PU.L._","Pr.x=2"]#  0.9782941
    @test value(compensated_demand(U,PC[:x])) ≈ TwoxTwowOTax_IndPrice_Nest["DU.L.x","Pr.x=2"]#  114.9659562
    @test value(compensated_demand(U,PC[:y])) ≈ TwoxTwowOTax_IndPrice_Nest["DU.L.y","Pr.x=2"]#  28.6215389
    @test value(compensated_demand(U, PU, :t)) ≈ -TwoxTwowOTax_IndPrice_Nest["SU.L._","Pr.x=2"]#  150
    @test value(compensated_demand(Y[:x], PC[:x], :t)) ≈ -TwoxTwowOTax_IndPrice_Nest["SY.L(i).x","Pr.x=2"]#  100
    @test value(compensated_demand(Y[:y], PC[:y], :t)) ≈ -TwoxTwowOTax_IndPrice_Nest["SY.L(i).y","Pr.x=2"]#  50
    @test value(C[:ra]) ≈ TwoxTwowOTax_IndPrice_Nest["RA.L._","Pr.x=2"]#  160.4166664
    @test value(demand(C[:ra], PU)) ≈ TwoxTwowOTax_IndPrice_Nest["FDRA.L._","Pr.x=2"]#  163.9759121

end




@testitem "TWOBYTWO (indexed w non-1 Demand prices)" begin 
    using XLSX, MPSGE.JuMP.Containers
    import JuMP
  
    m = MPSGEModel()
    goods = [:x, :y]
    factors = [:l, :k]
    consumers = [:ra]
    factor = DenseAxisArray(Float64[50 50; 20 30], goods, factors)
    supply = DenseAxisArray(Float64[100, 50], goods)
    cons   = DenseAxisArray(Float64[75, 75], factors)
    raw_endow = DenseAxisArray([70,80], factors)
    raw_pricepu = DenseAxisArray([1, 1], factors)
    
    @parameters(m, begin
        endow, raw_endow, (index = [factors],)
        pricepu, raw_pricepu, (index = [factors],)
    end)

    @sectors(m, begin
        Y, (index = [goods],)
        U
    end)

    @commodities(m, begin
        PC, (index = [goods],)
        PU, (index = [factors],)
        PF, (index = [factors],)
    end)

    @consumer(m, C, index = [consumers])

    for i in goods
        @production(m, Y[i], [t = 0, s = 1], begin
            @output(PC[i], supply[i], t)
            @input(PF[:l], factor[i,:l], s)
            @input(PF[:k], factor[i,:k], s)
        end)      
    end

    @production(m, U, [t =0, s = 1], begin
        [@output(PU[f], cons[f],  t) for f∈factors]...
        [@input(PC[i], supply[i], s) for i∈goods]...
    end)

    @demand(m, C[:ra], begin
            [@final_demand(PU[f], cons[f], reference_price = pricepu[f]) for f∈factors]...
            [@endowment(PF[f], endow[f]) for f∈factors]...
    end)

    solve!(m, cumulative_iteration_limit=0)

    gams_results = XLSX.readxlsx(joinpath(@__DIR__, "MPSGEresults.xlsx"))
    a_table = gams_results["TwoxTwo_DemandIndPrice_Nest"][:]                                                                                # Generated from TowbyTwo_Indexed_wDemand-non-1price_nest.gms
    TwoxTwo_DemandIndPrice_Nest = DenseAxisArray(a_table[2:end,2:end],string.(a_table[2:end,1],".",a_table[2:end,2]),a_table[1,2:end])

    # benchmark
    @test value(compensated_demand(Y[:x], PF[:l])) ≈ TwoxTwo_DemandIndPrice_Nest["x.L","benchmark"]#  50
    @test value(compensated_demand(Y[:x], PF[:k])) ≈ TwoxTwo_DemandIndPrice_Nest["x.K","benchmark"]#  50
    @test value(Y[:x]) ≈ TwoxTwo_DemandIndPrice_Nest["y.x","benchmark"]#  1
    @test value(Y[:y]) ≈ TwoxTwo_DemandIndPrice_Nest["y.y","benchmark"]#  1
    @test value(compensated_demand(Y[:y], PF[:l])) ≈ TwoxTwo_DemandIndPrice_Nest["y.L","benchmark"]#  20
    @test value(compensated_demand(Y[:y], PF[:k])) ≈ TwoxTwo_DemandIndPrice_Nest["y.K","benchmark"]#  30
    @test value(U) ≈ TwoxTwo_DemandIndPrice_Nest["U._","benchmark"]#  1
    @test value(C[:ra]) ≈ TwoxTwo_DemandIndPrice_Nest["RA._","benchmark"]#  150
    @test value(PC[:x]) ≈ TwoxTwo_DemandIndPrice_Nest["PC.x","benchmark"]#  1
    @test value(PC[:y]) ≈ TwoxTwo_DemandIndPrice_Nest["PC.y","benchmark"]#  1
    @test value(PF[:l]) ≈ TwoxTwo_DemandIndPrice_Nest["PF.L","benchmark"]#  1
    @test value(PF[:k]) ≈ TwoxTwo_DemandIndPrice_Nest["PF.K","benchmark"]#  1
    @test value(PU[:l]) ≈ TwoxTwo_DemandIndPrice_Nest["PU.L","benchmark"]#  1
    @test value(PU[:k]) ≈ TwoxTwo_DemandIndPrice_Nest["PU.K","benchmark"]#  1
    @test value(compensated_demand(U, PC[:x])) ≈ TwoxTwo_DemandIndPrice_Nest["DU.x","benchmark"]#  100
    @test value(compensated_demand(U, PC[:y])) ≈ TwoxTwo_DemandIndPrice_Nest["DU.y","benchmark"]#  50
    @test value(compensated_demand(U, PU[:l], :t)) ≈ -TwoxTwo_DemandIndPrice_Nest["SU.L","benchmark"]#  75
    @test value(compensated_demand(U, PU[:k], :t)) ≈ -TwoxTwo_DemandIndPrice_Nest["SU.K","benchmark"]#  75
    @test value(compensated_demand(Y[:x], PC[:x], :t)) ≈ -TwoxTwo_DemandIndPrice_Nest["SY.x","benchmark"]#  100
    @test value(compensated_demand(Y[:y], PC[:y], :t)) ≈ -TwoxTwo_DemandIndPrice_Nest["SY.y","benchmark"]#  50
    @test value(demand(C[:ra], PU[:l])) ≈ TwoxTwo_DemandIndPrice_Nest["FDRA.L","benchmark"]#  75
    @test value(demand(C[:ra], PU[:k])) ≈ TwoxTwo_DemandIndPrice_Nest["FDRA.K","benchmark"]#  75

    set_value!(endow[:l], value(endow[:l])*1.1)
    
    fix(C[:ra], 157)
    solve!(m)
    # RA=157
    @test value(compensated_demand(Y[:x], PF[:l])) ≈ TwoxTwo_DemandIndPrice_Nest["x.L","RA=157"]#  52.4404424
    @test value(compensated_demand(Y[:x], PF[:k])) ≈ TwoxTwo_DemandIndPrice_Nest["x.K","RA=157"]#  47.6731295
    @test value(Y[:x]) ≈ TwoxTwo_DemandIndPrice_Nest["y.x","RA=157"]#  1.0488088
    @test value(Y[:y]) ≈ TwoxTwo_DemandIndPrice_Nest["y.y","RA=157"]#  1.0388601
    @test value(compensated_demand(Y[:y], PF[:l])) ≈ TwoxTwo_DemandIndPrice_Nest["y.L","RA=157"]#  21.1770571
    @test value(compensated_demand(Y[:y], PF[:k])) ≈ TwoxTwo_DemandIndPrice_Nest["y.K","RA=157"]#  28.8778051
    @test value(U) ≈ TwoxTwo_DemandIndPrice_Nest["U._","RA=157"]#  1.0454821
    @test value(C[:ra]) ≈ TwoxTwo_DemandIndPrice_Nest["RA._","RA=157"]#  157
    @test value(PC[:x]) ≈ TwoxTwo_DemandIndPrice_Nest["PC.x","RA=157"]#  0.9979575
    @test value(PC[:y]) ≈ TwoxTwo_DemandIndPrice_Nest["PC.y","RA=157"]#  1.0075145
    @test value(PF[:l]) ≈ TwoxTwo_DemandIndPrice_Nest["PF.L","RA=157"]#  0.9515152
    @test value(PF[:k]) ≈ TwoxTwo_DemandIndPrice_Nest["PF.K","RA=157"]#  1.0466667
    @test value(PU[:l]) ≈ TwoxTwo_DemandIndPrice_Nest["PU.L","RA=157"]#  1.0011331
    @test value(PU[:k]) ≈ TwoxTwo_DemandIndPrice_Nest["PU.K","RA=157"]#  1.0011331
    @test value(compensated_demand(U, PC[:x])) ≈ TwoxTwo_DemandIndPrice_Nest["DU.x","RA=157"]#  100.3182058
    @test value(compensated_demand(U, PC[:y])) ≈ TwoxTwo_DemandIndPrice_Nest["DU.y","RA=157"]#  49.6833066
    @test value(compensated_demand(U, PU[:l], :t)) ≈ -TwoxTwo_DemandIndPrice_Nest["SU.L","RA=157"]#  75
    @test value(compensated_demand(U, PU[:k], :t)) ≈ -TwoxTwo_DemandIndPrice_Nest["SU.K","RA=157"]#  75
    @test value(compensated_demand(Y[:x], PC[:x], :t)) ≈ -TwoxTwo_DemandIndPrice_Nest["SY.x","RA=157"]#  100
    @test value(compensated_demand(Y[:y], PC[:y], :t)) ≈ -TwoxTwo_DemandIndPrice_Nest["SY.y","RA=157"]#  50
    @test value(demand(C[:ra], PU[:l])) ≈ TwoxTwo_DemandIndPrice_Nest["FDRA.L","RA=157"]#  78.4111548
    @test value(demand(C[:ra], PU[:k])) ≈ TwoxTwo_DemandIndPrice_Nest["FDRA.K","RA=157"]#  78.4111548

    unfix(C[:ra])
    fix(PU[:k], 1)
    solve!(m)
    # PC.x=1
    @test value(compensated_demand(Y[:x], PF[:l])) ≈ TwoxTwo_DemandIndPrice_Nest["x.L","PC.x=1"]#  52.4404424
    @test value(compensated_demand(Y[:x], PF[:k])) ≈ TwoxTwo_DemandIndPrice_Nest["x.K","PC.x=1"]#  47.6731295
    @test value(Y[:x]) ≈ TwoxTwo_DemandIndPrice_Nest["y.x","PC.x=1"]#  1.0488088
    @test value(Y[:y]) ≈ TwoxTwo_DemandIndPrice_Nest["y.y","PC.x=1"]#  1.0388601
    @test value(compensated_demand(Y[:y], PF[:l])) ≈ TwoxTwo_DemandIndPrice_Nest["y.L","PC.x=1"]#  21.1770571
    @test value(compensated_demand(Y[:y], PF[:k])) ≈ TwoxTwo_DemandIndPrice_Nest["y.K","PC.x=1"]#  28.8778051
    @test value(U) ≈ TwoxTwo_DemandIndPrice_Nest["U._","PC.x=1"]#  1.0454821
    @test value(C[:ra]) ≈ TwoxTwo_DemandIndPrice_Nest["RA._","PC.x=1"]#  156.8223095
    @test value(PC[:x]) ≈ TwoxTwo_DemandIndPrice_Nest["PC.x","PC.x=1"]#  0.996828
    @test value(PC[:y]) ≈ TwoxTwo_DemandIndPrice_Nest["PC.y","PC.x=1"]#  1.0063742
    @test value(PF[:l]) ≈ TwoxTwo_DemandIndPrice_Nest["PF.L","PC.x=1"]#  0.9504382
    @test value(PF[:k]) ≈ TwoxTwo_DemandIndPrice_Nest["PF.K","PC.x=1"]#  1.0454821
    @test value(PU[:l]) ≈ TwoxTwo_DemandIndPrice_Nest["PU.L","PC.x=1"]#  1
    @test value(PU[:k]) ≈ TwoxTwo_DemandIndPrice_Nest["PU.K","PC.x=1"]#  1
    @test value(compensated_demand(U, PC[:x])) ≈ TwoxTwo_DemandIndPrice_Nest["DU.x","PC.x=1"]#  100.3182058
    @test value(compensated_demand(U, PC[:y])) ≈ TwoxTwo_DemandIndPrice_Nest["DU.y","PC.x=1"]#  49.6833066
    @test value(compensated_demand(U, PU[:l], :t)) ≈ -TwoxTwo_DemandIndPrice_Nest["SU.L","PC.x=1"]#  75
    @test value(compensated_demand(U, PU[:k], :t)) ≈ -TwoxTwo_DemandIndPrice_Nest["SU.K","PC.x=1"]#  75
    @test value(compensated_demand(Y[:x], PC[:x], :t)) ≈ -TwoxTwo_DemandIndPrice_Nest["SY.x","PC.x=1"]#  100
    @test value(compensated_demand(Y[:y], PC[:y], :t)) ≈ -TwoxTwo_DemandIndPrice_Nest["SY.y","PC.x=1"]#  50
    @test value(demand(C[:ra], PU[:l])) ≈ TwoxTwo_DemandIndPrice_Nest["FDRA.L","PC.x=1"]#  78.4111548
    @test value(demand(C[:ra], PU[:k])) ≈ TwoxTwo_DemandIndPrice_Nest["FDRA.K","PC.x=1"]#  78.4111548

    set_value!(pricepu[:l] , 1.5)
    solve!(m)
    # Pr.l=2
    @test value(compensated_demand(Y[:x], PF[:l])) ≈ TwoxTwo_DemandIndPrice_Nest["x.L","Pr.l=1.5"]#  52.4404424
    @test value(compensated_demand(Y[:x], PF[:k])) ≈ TwoxTwo_DemandIndPrice_Nest["x.K","Pr.l=1.5"]#  47.6731295
    @test value(Y[:x]) ≈ TwoxTwo_DemandIndPrice_Nest["y.x","Pr.l=1.5"]#  1.0488088
    @test value(Y[:y]) ≈ TwoxTwo_DemandIndPrice_Nest["y.y","Pr.l=1.5"]#  1.0388601
    @test value(compensated_demand(Y[:y], PF[:l])) ≈ TwoxTwo_DemandIndPrice_Nest["y.L","Pr.l=1.5"]#  21.1770571
    @test value(compensated_demand(Y[:y], PF[:k])) ≈ TwoxTwo_DemandIndPrice_Nest["y.K","Pr.l=1.5"]#  28.8778051
    @test value(U) ≈ TwoxTwo_DemandIndPrice_Nest["U._","Pr.l=1.5"]#  1.0454821
    @test value(C[:ra]) ≈ TwoxTwo_DemandIndPrice_Nest["RA._","Pr.l=1.5"]#  196.0278842
    @test value(PC[:x]) ≈ TwoxTwo_DemandIndPrice_Nest["PC.x","Pr.l=1.5"]#  1.246035
    @test value(PC[:y]) ≈ TwoxTwo_DemandIndPrice_Nest["PC.y","Pr.l=1.5"]#  1.2579678
    @test value(PF[:l]) ≈ TwoxTwo_DemandIndPrice_Nest["PF.L","Pr.l=1.5"]#  1.1880478
    @test value(PF[:k]) ≈ TwoxTwo_DemandIndPrice_Nest["PF.K","Pr.l=1.5"]#  1.3068526
    @test value(PU[:l]) ≈ TwoxTwo_DemandIndPrice_Nest["PU.L","Pr.l=1.5"] atol=1e-7 #  1.5
    @test value(PU[:k]) ≈ TwoxTwo_DemandIndPrice_Nest["PU.K","Pr.l=1.5"]#  1
    @test value(compensated_demand(U, PC[:x])) ≈ TwoxTwo_DemandIndPrice_Nest["DU.x","Pr.l=1.5"]#  100.3182058
    @test value(compensated_demand(U, PC[:y])) ≈ TwoxTwo_DemandIndPrice_Nest["DU.y","Pr.l=1.5"]#  49.6833066
    @test value(compensated_demand(U, PU[:l], :t)) ≈ -TwoxTwo_DemandIndPrice_Nest["SU.L","Pr.l=1.5"]#  75
    @test value(compensated_demand(U, PU[:k], :t)) ≈ -TwoxTwo_DemandIndPrice_Nest["SU.K","Pr.l=1.5"]#  75
    @test value(compensated_demand(Y[:x], PC[:x], :t)) ≈ -TwoxTwo_DemandIndPrice_Nest["SY.x","Pr.l=1.5"]#  100
    @test value(compensated_demand(Y[:y], PC[:y], :t)) ≈ -TwoxTwo_DemandIndPrice_Nest["SY.y","Pr.l=1.5"]#  50
    @test value(demand(C[:ra], PU[:l])) ≈ TwoxTwo_DemandIndPrice_Nest["FDRA.L","Pr.l=1.5"]#  78.4111555
    @test value(demand(C[:ra], PU[:k])) ≈ TwoxTwo_DemandIndPrice_Nest["FDRA.K","Pr.l=1.5"]#  78.4111537

    #unfix(PC[:x])
    fix(PF[:l], 1)
    solve!(m)
    #PF.l=1
    @test value(compensated_demand(Y[:x], PF[:l])) ≈ TwoxTwo_DemandIndPrice_Nest["x.L","PF.l=1"]#  56.5057343
    @test value(compensated_demand(Y[:x], PF[:k])) ≈ TwoxTwo_DemandIndPrice_Nest["x.K","PF.l=1"]#  44.2432973
    @test value(Y[:x]) ≈ TwoxTwo_DemandIndPrice_Nest["y.x","PF.l=1"]#  1.1301147
    @test value(Y[:y]) ≈ TwoxTwo_DemandIndPrice_Nest["y.y","PF.l=1"]#  1.1028032
    @test value(compensated_demand(Y[:y], PF[:l])) ≈ TwoxTwo_DemandIndPrice_Nest["y.L","PF.l=1"]#  23.1620512
    @test value(compensated_demand(Y[:y], PF[:k])) ≈ TwoxTwo_DemandIndPrice_Nest["y.K","PF.l=1"]#  27.2034033
    @test value(U) ≈ TwoxTwo_DemandIndPrice_Nest["U._","PF.l=1"]#  1.1209365
    @test value(C[:ra]) ≈ TwoxTwo_DemandIndPrice_Nest["RA._","PF.l=1"]#  179.1727363
    @test value(PC[:x]) ≈ TwoxTwo_DemandIndPrice_Nest["PC.x","PF.l=1"]#  1.1301147
    @test value(PC[:y]) ≈ TwoxTwo_DemandIndPrice_Nest["PC.y","PF.l=1"]#  1.1581026
    @test value(PF[:l]) ≈ TwoxTwo_DemandIndPrice_Nest["PF.L","PF.l=1"]#  1
    @test value(PF[:k]) ≈ TwoxTwo_DemandIndPrice_Nest["PF.K","PF.l=1"]#  1.2771592
    @test value(PU[:l]) ≈ TwoxTwo_DemandIndPrice_Nest["PU.L","PF.l=1"]#  1.278736
    @test value(PU[:k]) ≈ TwoxTwo_DemandIndPrice_Nest["PU.K","PF.l=1"]#  1
    @test value(compensated_demand(U, PC[:x])) ≈ TwoxTwo_DemandIndPrice_Nest["DU.x","PF.l=1"]#  100.8187947
    @test value(compensated_demand(U, PC[:y])) ≈ TwoxTwo_DemandIndPrice_Nest["DU.y","PF.l=1"]#  49.191153
    @test value(compensated_demand(U, PU[:l], :t)) ≈ -TwoxTwo_DemandIndPrice_Nest["SU.L","PF.l=1"]#  75
    @test value(compensated_demand(U, PU[:k], :t)) ≈ -TwoxTwo_DemandIndPrice_Nest["SU.K","PF.l=1"]#  75
    @test value(compensated_demand(Y[:x], PC[:x], :t)) ≈ -TwoxTwo_DemandIndPrice_Nest["SY.x","PF.l=1"]#  100
    @test value(compensated_demand(Y[:y], PC[:y], :t)) ≈ -TwoxTwo_DemandIndPrice_Nest["SY.y","PF.l=1"]#  50
    @test value(demand(C[:ra], PU[:l])) ≈ TwoxTwo_DemandIndPrice_Nest["FDRA.L","PF.l=1"]#  84.0702388
    @test value(demand(C[:ra], PU[:k])) ≈ TwoxTwo_DemandIndPrice_Nest["FDRA.K","PF.l=1"]#  71.6690945

end


#=
## Test excluded. Demand nesting should be replaced with another production block

@testitem "TWOBYTWO (indexed w non-1 Demand prices w Nest)" begin 
    using XLSX, MPSGE.JuMP.Containers
    import JuMP      


    m = MPSGEModel()
    goods = [:x, :y]
    factors = [:l, :k]
    consumers = [:ra]
    factor = DenseAxisArray(Float64[50 50; 20 30], goods, factors)
    supply = DenseAxisArray(Float64[100, 50], goods)
    cons   = DenseAxisArray(Float64[75, 75], factors)

    raw_pricepci = DenseAxisArray([1,1], goods)
    raw_endow = DenseAxisArray([70,80], factors)
    
    @parameters(m, begin
        endow, raw_endow, (index = [factors],)
        pricepci, raw_pricepci, (index = [goods],)
    end)
    

    pricepu = add!(m, Parameter(:pricepu, indices=(factors,), value=[1.,1]))
    endow    = add!(m, Parameter(:endow, indices=(factors,), value=[1,1.0])) 
    
    Y = add!(m, Sector(:Y, indices=(goods,)))
    U = add!(m, Sector(:U))
    PC = add!(m, Commodity(:PC, indices=(goods,)))
    PU = add!(m, Commodity(:PU, indices=(factors,)))
    PF = add!(m, Commodity(:PF, indices=(factors,)))
    C = add!(m, Consumer(:C, indices=(consumers,), benchmark=150.))

    for i in goods
        @production(m, Y[i], 0, 1, [Output(PC[i], supply[i])], [Input(PF[:l], factor[i,:l]), Input(PF[:k], factor[i,:k])])
    end
        add!(m, Production(U, 0., 1, [Output(PU[f], cons[f]) for f in factors], [Input(PC[i], supply[i]) for i in goods]))
        # @demand(m, C[:ra], 1., [Demand(PU[f], cons[f], :($(pricepu[f])*1.)) for f in factors], [Endowment(PF[:l], :(70 * $(endow[:l]))), Endowment(PF[:k], :(80. * $(endow[:k])))])

        add!(m,DemandFunction(C[:ra], 1., [Demand(Nest(:CU, 1., 150.,
        [
            Input(PU[f], cons[f],  price=:($(pricepu[f])*1.)) for f in factors
        ]
        ),150. )],
            # PU[f], cons[f], :($(pricepu[f])*1.)) for f in factors], 
        [Endowment(PF[:l], :(70 * $(endow[:l]))), Endowment(PF[:k], :(80. * $(endow[:k])))]))

    solve!(m, cumulative_iteration_limit=0)

    gams_results = XLSX.readxlsx(joinpath(@__DIR__, "MPSGEresults.xlsx"))
    a_table = gams_results["TwoxTwo_DemandIndPrice_Nest"][:]                                                                                # Generated from TowbyTwo_Indexed_wDemand-non-1price_nest.gms
    TwoxTwo_DemandIndPrice_Nest = DenseAxisArray(a_table[2:end,2:end],string.(a_table[2:end,1],".",a_table[2:end,2]),a_table[1,2:end])

    # benchmark
    @test value(compensated_demand(Y[:x], PF[:l])) ≈ TwoxTwo_DemandIndPrice_Nest["x.L","benchmark"]#  50
    @test value(compensated_demand(Y[:x], PF[:k])) ≈ TwoxTwo_DemandIndPrice_Nest["x.K","benchmark"]#  50
    @test value(Y[:x]) ≈ TwoxTwo_DemandIndPrice_Nest["y.x","benchmark"]#  1
    @test value(Y[:y]) ≈ TwoxTwo_DemandIndPrice_Nest["y.y","benchmark"]#  1
    @test value(compensated_demand(Y[:y], PF[:l])) ≈ TwoxTwo_DemandIndPrice_Nest["y.L","benchmark"]#  20
    @test value(compensated_demand(Y[:y], PF[:k])) ≈ TwoxTwo_DemandIndPrice_Nest["y.K","benchmark"]#  30
    @test value(U) ≈ TwoxTwo_DemandIndPrice_Nest["U._","benchmark"]#  1
    @test value(C[:ra]) ≈ TwoxTwo_DemandIndPrice_Nest["RA._","benchmark"]#  150
    @test value(PC[:x]) ≈ TwoxTwo_DemandIndPrice_Nest["PC.x","benchmark"]#  1
    @test value(PC[:y]) ≈ TwoxTwo_DemandIndPrice_Nest["PC.y","benchmark"]#  1
    @test value(PF[:l]) ≈ TwoxTwo_DemandIndPrice_Nest["PF.L","benchmark"]#  1
    @test value(PF[:k]) ≈ TwoxTwo_DemandIndPrice_Nest["PF.K","benchmark"]#  1
    @test value(PU[:l]) ≈ TwoxTwo_DemandIndPrice_Nest["PU.L","benchmark"]#  1
    @test value(PU[:k]) ≈ TwoxTwo_DemandIndPrice_Nest["PU.K","benchmark"]#  1
    @test value(compensated_demand(U, PC[:x])) ≈ TwoxTwo_DemandIndPrice_Nest["DU.x","benchmark"]#  100
    @test value(compensated_demand(U, PC[:y])) ≈ TwoxTwo_DemandIndPrice_Nest["DU.y","benchmark"]#  50
    @test value(compensated_demand(U, PU[:l], :t)) ≈ -TwoxTwo_DemandIndPrice_Nest["SU.L","benchmark"]#  75
    @test value(compensated_demand(U, PU[:k], :t)) ≈ -TwoxTwo_DemandIndPrice_Nest["SU.K","benchmark"]#  75
    @test value(compensated_demand(Y[:x], PC[:x], :t)) ≈ -TwoxTwo_DemandIndPrice_Nest["SY.x","benchmark"]#  100
    @test value(compensated_demand(Y[:y], PC[:y], :t)) ≈ -TwoxTwo_DemandIndPrice_Nest["SY.y","benchmark"]#  50
    #@test value(m._jump_model[Symbol("PC→CUρC[ra]")]) ≈ TwoxTwo_DemandIndPrice_Nest["FDRA.L","benchmark"] + TwoxTwo_DemandIndPrice_Nest["FDRA.K","benchmark"] # 75 + 75
    # @test value(demand(C[:ra], PU[:k])) ≈ TwoxTwo_DemandIndPrice_Nest["FDRA.K","benchmark"]#  75

    set_value!(endow[:l], get_value(endow[:l])*1.1)
    set_value(C[:ra], 157.)
    fix(C[:ra], 1)
    solve!(m)
    # RA=157
    @test value(compensated_demand(Y[:x], PF[:l])) ≈ TwoxTwo_DemandIndPrice_Nest["x.L","RA=157"]#  52.4404424
    @test value(compensated_demand(Y[:x], PF[:k])) ≈ TwoxTwo_DemandIndPrice_Nest["x.K","RA=157"]#  47.6731295
    @test value(Y[:x]) ≈ TwoxTwo_DemandIndPrice_Nest["y.x","RA=157"]#  1.0488088
    @test value(Y[:y]) ≈ TwoxTwo_DemandIndPrice_Nest["y.y","RA=157"]#  1.0388601
    @test value(compensated_demand(Y[:y], PF[:l])) ≈ TwoxTwo_DemandIndPrice_Nest["y.L","RA=157"]#  21.1770571
    @test value(compensated_demand(Y[:y], PF[:k])) ≈ TwoxTwo_DemandIndPrice_Nest["y.K","RA=157"]#  28.8778051
    @test value(U) ≈ TwoxTwo_DemandIndPrice_Nest["U._","RA=157"]#  1.0454821
    @test value(C[:ra]) ≈ TwoxTwo_DemandIndPrice_Nest["RA._","RA=157"]#  157
    @test value(PC[:x]) ≈ TwoxTwo_DemandIndPrice_Nest["PC.x","RA=157"]#  0.9979575
    @test value(PC[:y]) ≈ TwoxTwo_DemandIndPrice_Nest["PC.y","RA=157"]#  1.0075145
    @test value(PF[:l]) ≈ TwoxTwo_DemandIndPrice_Nest["PF.L","RA=157"]#  0.9515152
    @test value(PF[:k]) ≈ TwoxTwo_DemandIndPrice_Nest["PF.K","RA=157"]#  1.0466667
    @test value(PU[:l]) ≈ TwoxTwo_DemandIndPrice_Nest["PU.L","RA=157"]#  1.0011331
    @test value(PU[:k]) ≈ TwoxTwo_DemandIndPrice_Nest["PU.K","RA=157"]#  1.0011331
    @test value(compensated_demand(U, PC[:x])) ≈ TwoxTwo_DemandIndPrice_Nest["DU.x","RA=157"]#  100.3182058
    @test value(compensated_demand(U, PC[:y])) ≈ TwoxTwo_DemandIndPrice_Nest["DU.y","RA=157"]#  49.6833066
    @test value(compensated_demand(U, PU[:l], :t)) ≈ -TwoxTwo_DemandIndPrice_Nest["SU.L","RA=157"]#  75
    @test value(compensated_demand(U, PU[:k], :t)) ≈ -TwoxTwo_DemandIndPrice_Nest["SU.K","RA=157"]#  75
    @test value(compensated_demand(Y[:x], PC[:x], :t)) ≈ -TwoxTwo_DemandIndPrice_Nest["SY.x","RA=157"]#  100
    @test value(compensated_demand(Y[:y], PC[:y], :t)) ≈ -TwoxTwo_DemandIndPrice_Nest["SY.y","RA=157"]#  50
    # @test value(m._jump_model[Symbol("PC→CUρC[ra]")]) ≈ TwoxTwo_DemandIndPrice_Nest["FDRA.L","RA=157"] + TwoxTwo_DemandIndPrice_Nest["FDRA.K","RA=157"] # 78.4111548 + 78.4111548
    # @test value(demand(C[:ra], PU[:k])) ≈ TwoxTwo_DemandIndPrice_Nest["FDRA.K","RA=157"]#  78.4111548

    unfix(C[:ra])
    fix(PU[:k], 1)
    solve!(m)
    # PC.x=1
    @test value(compensated_demand(Y[:x], PF[:l])) ≈ TwoxTwo_DemandIndPrice_Nest["x.L","PC.x=1"]#  52.4404424
    @test value(compensated_demand(Y[:x], PF[:k])) ≈ TwoxTwo_DemandIndPrice_Nest["x.K","PC.x=1"]#  47.6731295
    @test value(Y[:x]) ≈ TwoxTwo_DemandIndPrice_Nest["y.x","PC.x=1"]#  1.0488088
    @test value(Y[:y]) ≈ TwoxTwo_DemandIndPrice_Nest["y.y","PC.x=1"]#  1.0388601
    @test value(compensated_demand(Y[:y], PF[:l])) ≈ TwoxTwo_DemandIndPrice_Nest["y.L","PC.x=1"]#  21.1770571
    @test value(compensated_demand(Y[:y], PF[:k])) ≈ TwoxTwo_DemandIndPrice_Nest["y.K","PC.x=1"]#  28.8778051
    @test value(U) ≈ TwoxTwo_DemandIndPrice_Nest["U._","PC.x=1"]#  1.0454821
    @test value(C[:ra]) ≈ TwoxTwo_DemandIndPrice_Nest["RA._","PC.x=1"]#  156.8223095
    @test value(PC[:x]) ≈ TwoxTwo_DemandIndPrice_Nest["PC.x","PC.x=1"]#  0.996828
    @test value(PC[:y]) ≈ TwoxTwo_DemandIndPrice_Nest["PC.y","PC.x=1"]#  1.0063742
    @test value(PF[:l]) ≈ TwoxTwo_DemandIndPrice_Nest["PF.L","PC.x=1"]#  0.9504382
    @test value(PF[:k]) ≈ TwoxTwo_DemandIndPrice_Nest["PF.K","PC.x=1"]#  1.0454821
    @test value(PU[:l]) ≈ TwoxTwo_DemandIndPrice_Nest["PU.L","PC.x=1"]#  1
    @test value(PU[:k]) ≈ TwoxTwo_DemandIndPrice_Nest["PU.K","PC.x=1"]#  1
    @test value(compensated_demand(U, PC[:x])) ≈ TwoxTwo_DemandIndPrice_Nest["DU.x","PC.x=1"]#  100.3182058
    @test value(compensated_demand(U, PC[:y])) ≈ TwoxTwo_DemandIndPrice_Nest["DU.y","PC.x=1"]#  49.6833066
    @test value(compensated_demand(U, PU[:l], :t)) ≈ -TwoxTwo_DemandIndPrice_Nest["SU.L","PC.x=1"]#  75
    @test value(compensated_demand(U, PU[:k], :t)) ≈ -TwoxTwo_DemandIndPrice_Nest["SU.K","PC.x=1"]#  75
    @test value(compensated_demand(Y[:x], PC[:x], :t)) ≈ -TwoxTwo_DemandIndPrice_Nest["SY.x","PC.x=1"]#  100
    @test value(compensated_demand(Y[:y], PC[:y], :t)) ≈ -TwoxTwo_DemandIndPrice_Nest["SY.y","PC.x=1"]#  50
    # @test value(m._jump_model[Symbol("PC→CUρC[ra]")]) ≈ TwoxTwo_DemandIndPrice_Nest["FDRA.L","PC.x=1"] + TwoxTwo_DemandIndPrice_Nest["FDRA.K","PC.x=1"] # 78.4111548 + 78.4111548
    # @test value(demand(C[:ra], PU[:k])) ≈ TwoxTwo_DemandIndPrice_Nest["FDRA.K","PC.x=1"]#  78.4111548

    set_value(pricepu[:l] , 1.5)
    solve!(m)
    # Pr.l=2
    @test value(compensated_demand(Y[:x], PF[:l])) ≈ TwoxTwo_DemandIndPrice_Nest["x.L","Pr.l=1.5"]#  52.4404424
    @test value(compensated_demand(Y[:x], PF[:k])) ≈ TwoxTwo_DemandIndPrice_Nest["x.K","Pr.l=1.5"]#  47.6731295
    @test value(Y[:x]) ≈ TwoxTwo_DemandIndPrice_Nest["y.x","Pr.l=1.5"]#  1.0488088
    @test value(Y[:y]) ≈ TwoxTwo_DemandIndPrice_Nest["y.y","Pr.l=1.5"]#  1.0388601
    @test value(compensated_demand(Y[:y], PF[:l])) ≈ TwoxTwo_DemandIndPrice_Nest["y.L","Pr.l=1.5"]#  21.1770571
    @test value(compensated_demand(Y[:y], PF[:k])) ≈ TwoxTwo_DemandIndPrice_Nest["y.K","Pr.l=1.5"]#  28.8778051
    @test value(U) ≈ TwoxTwo_DemandIndPrice_Nest["U._","Pr.l=1.5"]#  1.0454821
    @test value(C[:ra]) ≈ TwoxTwo_DemandIndPrice_Nest["RA._","Pr.l=1.5"]#  196.0278842
    @test value(PC[:x]) ≈ TwoxTwo_DemandIndPrice_Nest["PC.x","Pr.l=1.5"]#  1.246035
    @test value(PC[:y]) ≈ TwoxTwo_DemandIndPrice_Nest["PC.y","Pr.l=1.5"]#  1.2579678
    @test value(PF[:l]) ≈ TwoxTwo_DemandIndPrice_Nest["PF.L","Pr.l=1.5"]#  1.1880478
    @test value(PF[:k]) ≈ TwoxTwo_DemandIndPrice_Nest["PF.K","Pr.l=1.5"]#  1.3068526
    @test value(PU[:l]) ≈ TwoxTwo_DemandIndPrice_Nest["PU.L","Pr.l=1.5"] atol= 1e-7 #  1.5 
    @test value(PU[:k]) ≈ TwoxTwo_DemandIndPrice_Nest["PU.K","Pr.l=1.5"]#  1
    @test value(compensated_demand(U, PC[:x])) ≈ TwoxTwo_DemandIndPrice_Nest["DU.x","Pr.l=1.5"]#  100.3182058
    @test value(compensated_demand(U, PC[:y])) ≈ TwoxTwo_DemandIndPrice_Nest["DU.y","Pr.l=1.5"]#  49.6833066
    @test value(compensated_demand(U, PU[:l], :t)) ≈ -TwoxTwo_DemandIndPrice_Nest["SU.L","Pr.l=1.5"]#  75
    @test value(compensated_demand(U, PU[:k], :t)) ≈ -TwoxTwo_DemandIndPrice_Nest["SU.K","Pr.l=1.5"]#  75
    @test value(compensated_demand(Y[:x], PC[:x], :t)) ≈ -TwoxTwo_DemandIndPrice_Nest["SY.x","Pr.l=1.5"]#  100
    @test value(compensated_demand(Y[:y], PC[:y], :t)) ≈ -TwoxTwo_DemandIndPrice_Nest["SY.y","Pr.l=1.5"]#  50
    # @test value(m._jump_model[Symbol("PC→CUρC[ra]")]) ≈ TwoxTwo_DemandIndPrice_Nest["FDRA.L","Pr.l=1.5"]+TwoxTwo_DemandIndPrice_Nest["FDRA.K","Pr.l=1.5"]#  78.4111555 + 78.4111555
    # @test value(demand(C[:ra], PU[:k])) ≈ TwoxTwo_DemandIndPrice_Nest["FDRA.K","Pr.l=1.5"]#  78.4111537

    unfix(PC[:x])
    fix(PF[:l], 1)
    solve!(m)
    # PF.l=1
    @test value(compensated_demand(Y[:x], PF[:l])) ≈ TwoxTwo_DemandIndPrice_Nest["x.L","PF.l=1"]#  56.5057343
    @test value(compensated_demand(Y[:x], PF[:k])) ≈ TwoxTwo_DemandIndPrice_Nest["x.K","PF.l=1"]#  44.2432973
    @test value(Y[:x]) ≈ TwoxTwo_DemandIndPrice_Nest["y.x","PF.l=1"]#  1.1301147
    @test value(Y[:y]) ≈ TwoxTwo_DemandIndPrice_Nest["y.y","PF.l=1"]#  1.1028032
    @test value(compensated_demand(Y[:y], PF[:l])) ≈ TwoxTwo_DemandIndPrice_Nest["y.L","PF.l=1"]#  23.1620512
    @test value(compensated_demand(Y[:y], PF[:k])) ≈ TwoxTwo_DemandIndPrice_Nest["y.K","PF.l=1"]#  27.2034033
    @test value(U) ≈ TwoxTwo_DemandIndPrice_Nest["U._","PF.l=1"]#  1.1209365
    @test value(C[:ra]) ≈ TwoxTwo_DemandIndPrice_Nest["RA._","PF.l=1"]#  179.1727363
    @test value(PC[:x]) ≈ TwoxTwo_DemandIndPrice_Nest["PC.x","PF.l=1"]#  1.1301147
    @test value(PC[:y]) ≈ TwoxTwo_DemandIndPrice_Nest["PC.y","PF.l=1"]#  1.1581026
    @test value(PF[:l]) ≈ TwoxTwo_DemandIndPrice_Nest["PF.L","PF.l=1"]#  1
    @test value(PF[:k]) ≈ TwoxTwo_DemandIndPrice_Nest["PF.K","PF.l=1"]#  1.2771592
    @test value(PU[:l]) ≈ TwoxTwo_DemandIndPrice_Nest["PU.L","PF.l=1"]#  1.278736
    @test value(PU[:k]) ≈ TwoxTwo_DemandIndPrice_Nest["PU.K","PF.l=1"]#  1
    @test value(compensated_demand(U, PC[:x])) ≈ TwoxTwo_DemandIndPrice_Nest["DU.x","PF.l=1"]#  100.8187947
    @test value(compensated_demand(U, PC[:y])) ≈ TwoxTwo_DemandIndPrice_Nest["DU.y","PF.l=1"]#  49.191153
    @test value(compensated_demand(U, PU[:l], :t)) ≈ -TwoxTwo_DemandIndPrice_Nest["SU.L","PF.l=1"]#  75
    @test value(compensated_demand(U, PU[:k], :t)) ≈ -TwoxTwo_DemandIndPrice_Nest["SU.K","PF.l=1"]#  75
    @test value(compensated_demand(Y[:x], PC[:x], :t)) ≈ -TwoxTwo_DemandIndPrice_Nest["SY.x","PF.l=1"]#  100
    @test value(compensated_demand(Y[:y], PC[:y], :t)) ≈ -TwoxTwo_DemandIndPrice_Nest["SY.y","PF.l=1"]#  50
    # For the counterfacturals where there two nested final demands are equal, summing matches our results, but for this they are different and summing the two doesn't match
    # @test value(m._jump_model[Symbol("PC→CUρC[ra]")]) ≈ TwoxTwo_DemandIndPrice_Nest["FDRA.L","PF.l=1"]+TwoxTwo_DemandIndPrice_Nest["FDRA.K","PF.l=1"]#  84.0702388 +  71.6690945
    # @test value(demand(C[:ra], PU[:k])) ≈ TwoxTwo_DemandIndPrice_Nest["FDRA.K","PF.l=1"]#  71.6690945

end
=#
