@testitem "TWOBYTWO (indexed version)" begin 
    using XLSX, MPSGE.JuMP.Containers
    
    m = Model()
    goods = [:x, :y]
    factors = [:l, :k]
    consumers = [:ra]
    factor = DenseAxisArray(Float64[50 50; 20 30], goods, factors)
    supply = DenseAxisArray(Float64[100, 50], goods)
    endow = add!(m, Parameter(:endow, indices=(factors,), value=1.0)) 
    outax = add!(m, Parameter(:outax, indices=(goods,), value=0.))
    intax = add!(m, Parameter(:intax, indices=(goods,), value=0.))

    Y = add!(m, Sector(:Y, indices=(goods,)))
    U = add!(m, Sector(:U))
    PC = add!(m, Commodity(:PC, indices=(goods,)))
    PU = add!(m, Commodity(:PU))
    PF = add!(m, Commodity(:PF, indices=(factors,)))
    C = add!(m, Consumer(:C, indices=(consumers,), benchmark=150.))

    for i in goods
        @production(m, Y[i], 0, 1, [Output(PC[i], supply[i], [Tax(:(1 * $(outax[i])), C[:ra])])], [Input(PF[:l], factor[i,:l], [Tax(:(1 * $(intax[i])), C[:ra])]), Input(PF[:k], factor[i,:k])])
    end
    @production(m, U, 0, 1, [Output(PU, 150)], [Input(PC[:x], 100), Input(PC[:y], 50)])
    @demand(m, C[:ra], 1., [Demand(PU, 150)], [Endowment(PF[:l], :(70 * $(endow[:l]))), Endowment(PF[:k], :(80. * $(endow[:k])))])

    solve!(m, cumulative_iteration_limit=0)
    gams_results = XLSX.readxlsx(joinpath(@__DIR__, "MPSGEresults.xlsx"))
    a_table = gams_results["TwoxTwoScalar"][:]  # Generated from TwoByTwo_Scalar_Algeb-MPSGE.gms
    two_by_two_scalar_results = DenseAxisArray(a_table[2:end,2:end],a_table[2:end,1],a_table[1,2:end])

    @test MPSGE.Complementarity.result_value(m._jump_model[:Y][:x]) ≈ two_by_two_scalar_results["Y.L","benchmark"] # 1.
    @test MPSGE.Complementarity.result_value(m._jump_model[:Y][:y]) ≈ two_by_two_scalar_results["X.L","benchmark"] # 1.
    @test MPSGE.Complementarity.result_value(m._jump_model[:U]) ≈ two_by_two_scalar_results["U.L","benchmark"] # 1.
    @test MPSGE.Complementarity.result_value(m._jump_model[:C][:ra]) ≈ two_by_two_scalar_results["RA.L","benchmark"] # 150.
    @test MPSGE.Complementarity.result_value(m._jump_model[:PC][:x]) ≈ two_by_two_scalar_results["PX.L","benchmark"] # 1.
    @test MPSGE.Complementarity.result_value(m._jump_model[:PC][:y]) ≈ two_by_two_scalar_results["PY.L","benchmark"] # 1.
    @test MPSGE.Complementarity.result_value(m._jump_model[:PU]) ≈ two_by_two_scalar_results["PU.L","benchmark"] # 1.
    @test MPSGE.Complementarity.result_value(m._jump_model[:PF][:l]) ≈ two_by_two_scalar_results["PL.L","benchmark"] # 1.
    @test MPSGE.Complementarity.result_value(m._jump_model[:PF][:k]) ≈ two_by_two_scalar_results["PK.L","benchmark"] # 1.
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PF[l]†Y[x]")]) ≈ two_by_two_scalar_results["LX.L","benchmark"] # 50.
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PF[l]†Y[y]")]) ≈ two_by_two_scalar_results["LY.L","benchmark"] # 20.
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PF[k]†Y[x]")]) ≈ two_by_two_scalar_results["KX.L","benchmark"] # 50.
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PF[k]†Y[y]")]) ≈ two_by_two_scalar_results["KY.L","benchmark"] # 30.
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PC[x]†U")]) ≈ two_by_two_scalar_results["DX.L","benchmark"] # 100.
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PC[y]†U")]) ≈ two_by_two_scalar_results["DY.L","benchmark"] # 50.

set_fixed!(PC[:x], true)
set_value(endow[:l], get_value(endow[:l]).*1.1)
set_value(C[:ra], 157.)
set_fixed!(C[:ra], true)
solve!(m)

    @test MPSGE.Complementarity.result_value(m._jump_model[:Y][:x]) ≈ two_by_two_scalar_results["X.L","RA=157"] # 1.04986567
    @test MPSGE.Complementarity.result_value(m._jump_model[:Y][:y]) ≈ two_by_two_scalar_results["Y.L","RA=157"] # 1.03676649
    @test MPSGE.Complementarity.result_value(m._jump_model[:U]) ≈ two_by_two_scalar_results["U.L","RA=157"] # 1.04335615
    @test MPSGE.Complementarity.result_value(m._jump_model[:C][:ra]) ≈ two_by_two_scalar_results["RA.L","RA=157"] # 157
    @test MPSGE.Complementarity.result_value(m._jump_model[:PC][:x]) ≈ two_by_two_scalar_results["PX.L","RA=157"] # 1.
    @test MPSGE.Complementarity.result_value(m._jump_model[:PC][:y]) ≈ two_by_two_scalar_results["PY.L","RA=157"] # 1.00954909
    @test MPSGE.Complementarity.result_value(m._jump_model[:PU]) ≈ two_by_two_scalar_results["PU.L","RA=157"] # 1.00317295
    @test MPSGE.Complementarity.result_value(m._jump_model[:PF][:l]) ≈ two_by_two_scalar_results["PL.L","RA=157"] # 0.95359243
    @test MPSGE.Complementarity.result_value(m._jump_model[:PF][:k]) ≈ two_by_two_scalar_results["PK.L","RA=157"] # 1.04866605
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PF[l]†Y[x]")]) ≈ two_by_two_scalar_results["LX.L","RA=157"] # 52.43330226
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PF[l]†Y[y]")]) ≈ two_by_two_scalar_results["LY.L","RA=157"] # 21.17359701
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PF[k]†Y[x]")]) ≈ two_by_two_scalar_results["KX.L","RA=157"] # 47.67962139
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PF[k]†Y[y]")]) ≈ two_by_two_scalar_results["KY.L","RA=157"] # 28.880951
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PC[x]†U")]) ≈ two_by_two_scalar_results["DX.L","RA=157"] # 100.3172951
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PC[y]†U")]) ≈ two_by_two_scalar_results["DY.L","RA=157"] # 49.68420864

set_fixed!(C[:ra], false)
# Just testing for bunctionality, not effecting the results
#IndexedConsumer
set_lower_bound(C[:ra], 10e100)
set_lower_bound(C[:ra], 0.)
set_upper_bound(C[:ra], 0.)
set_upper_bound(C[:ra], 10e100)
# Indexed Sector
set_lower_bound(Y[:x], 1.)
set_lower_bound(Y[:x], 0.)
set_upper_bound(Y[:y], 1.)
set_upper_bound(Y[:y], 10e100)
set_fixed!(Y[:x], true)
set_fixed!(Y[:x], false)
# Indexed Commodity
set_lower_bound(PC[:x], 1.)
set_lower_bound(PC[:x], 0.)
set_upper_bound(PC[:y], 1.)
set_upper_bound(PC[:y], 10e100)
set_value(PC[:x],25.)
set_value(PC[:x], 1.)

set_fixed!(PC[:x], true)

    solve!(m)
    @test MPSGE.Complementarity.result_value(m._jump_model[:Y][:x]) ≈ two_by_two_scalar_results["X.L","PX=1"] # 1.04880885
    @test MPSGE.Complementarity.result_value(m._jump_model[:Y][:y]) ≈ two_by_two_scalar_results["Y.L","PX=1"] # 1.03886012
    @test MPSGE.Complementarity.result_value(m._jump_model[:U]) ≈ two_by_two_scalar_results["U.L","PX=1"] # 1.04548206
    @test MPSGE.Complementarity.result_value(m._jump_model[:C][:ra]) ≈ two_by_two_scalar_results["RA.L","PX=1"] # 157.321327225523
    @test MPSGE.Complementarity.result_value(m._jump_model[:PC][:x]) ≈ two_by_two_scalar_results["PX.L","PX=1"] # 1.0000000000
    @test MPSGE.Complementarity.result_value(m._jump_model[:PC][:y]) ≈ two_by_two_scalar_results["PY.L","PX=1"] # 1.00957658
    @test MPSGE.Complementarity.result_value(m._jump_model[:PU]) ≈ two_by_two_scalar_results["PU.L","PX=1"] # 1.00318206
    @test MPSGE.Complementarity.result_value(m._jump_model[:PF][:l]) ≈ two_by_two_scalar_results["PL.L","PX=1"] # 0.95346259
    @test MPSGE.Complementarity.result_value(m._jump_model[:PF][:k]) ≈ two_by_two_scalar_results["PK.L","PX=1"] # 1.04880885
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PF[l]†Y[x]")]) ≈ two_by_two_scalar_results["LX.L","PX=1"] # 52.4404424085075
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PF[l]†Y[y]")]) ≈ two_by_two_scalar_results["LY.L","PX=1"] # 21.1770570584356
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PF[k]†Y[x]")]) ≈ two_by_two_scalar_results["KX.L","PX=1"] # 47.6731294622795
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PF[k]†Y[y]")]) ≈ two_by_two_scalar_results["KY.L","PX=1"] # 28.877805079685
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PC[x]†U")]) ≈ two_by_two_scalar_results["DX.L","PX=1"] # 100.318205802571
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PC[y]†U")]) ≈ two_by_two_scalar_results["DY.L","PX=1"] # 49.6833066029729

    set_fixed!(PC[:x], false)
    set_fixed!(PF[:l], true)
    solve!(m)
            
    @test MPSGE.Complementarity.result_value(m._jump_model[:Y][:x]) ≈ two_by_two_scalar_results["X.L","PL=1"] # 1.04880885
    @test MPSGE.Complementarity.result_value(m._jump_model[:Y][:y]) ≈ two_by_two_scalar_results["Y.L","PL=1"] # 1.03886012
    @test MPSGE.Complementarity.result_value(m._jump_model[:U]) ≈ two_by_two_scalar_results["U.L","PL=1"] # 1.04548206
    @test MPSGE.Complementarity.result_value(m._jump_model[:C][:ra]) ≈ two_by_two_scalar_results["RA.L","PL=1"] # 165
    @test MPSGE.Complementarity.result_value(m._jump_model[:PC][:x]) ≈ two_by_two_scalar_results["PX.L","PL=1"] # 1.04880885
    @test MPSGE.Complementarity.result_value(m._jump_model[:PC][:y]) ≈ two_by_two_scalar_results["PY.L","PL=1"] # 1.05885285
    @test MPSGE.Complementarity.result_value(m._jump_model[:PU]) ≈ two_by_two_scalar_results["PU.L","PL=1"] # 1.05214622
    @test MPSGE.Complementarity.result_value(m._jump_model[:PF][:l]) ≈ two_by_two_scalar_results["PL.L","PL=1"] # 1.
    @test MPSGE.Complementarity.result_value(m._jump_model[:PF][:k]) ≈ two_by_two_scalar_results["PK.L","PL=1"] # 1.1
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PF[l]†Y[x]")]) ≈ two_by_two_scalar_results["LX.L","PL=1"] # 52.44044241
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PF[l]†Y[y]")]) ≈ two_by_two_scalar_results["LY.L","PL=1"] # 21.17705706
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PF[k]†Y[x]")]) ≈ two_by_two_scalar_results["KX.L","PL=1"] # 47.67312946
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PF[k]†Y[y]")]) ≈ two_by_two_scalar_results["KY.L","PL=1"] # 28.87780508
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PC[x]†U")]) ≈ two_by_two_scalar_results["DX.L","PL=1"] # 100.3182058
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PC[y]†U")]) ≈ two_by_two_scalar_results["DY.L","PL=1"] # 49.6833066

# Test indexed Taxes, Output taxes, then Input Taxes
gams_results = XLSX.readxlsx(joinpath(@__DIR__, "MPSGEresults.xlsx"))
a_table = gams_results["TwoxTwowOTax"][:]  # Generated from TwoByTwo_Scalar_wTax-MPSGE.gms
two_by_two_scalar_results = DenseAxisArray(a_table[2:end,2:end],a_table[2:end,1],a_table[1,2:end])

set_value(outax[:x], 0.1)
solve!(m)

    @test MPSGE.Complementarity.result_value(m._jump_model[:Y][:x]) ≈ two_by_two_scalar_results["X.L","Otax=.1"]#    1.0116855688658395
    @test MPSGE.Complementarity.result_value(m._jump_model[:Y][:y]) ≈ two_by_two_scalar_results["Y.L","Otax=.1"]#    1.1123672179049628
    @test MPSGE.Complementarity.result_value(m._jump_model[:U]) ≈ two_by_two_scalar_results["U.L","Otax=.1"]#    1.0441905629409307
    @test MPSGE.Complementarity.result_value(m._jump_model[:C][:ra]) ≈ two_by_two_scalar_results["RA.L","Otax=.1"]#    177.69230689285564
    @test MPSGE.Complementarity.result_value(m._jump_model[:PC][:x]) ≈ two_by_two_scalar_results["PX.L","Otax=.1"]#    1.170932369505204
    @test MPSGE.Complementarity.result_value(m._jump_model[:PC][:y]) ≈ two_by_two_scalar_results["PY.L","Otax=.1"]#    1.064949920418856
    @test MPSGE.Complementarity.result_value(m._jump_model[:PU]) ≈ two_by_two_scalar_results["PU.L","Otax=.1"]#    1.1344819828665367
    @test MPSGE.Complementarity.result_value(m._jump_model[:PF][:l]) ≈ two_by_two_scalar_results["PL.L","Otax=.1"]#    1.
    @test MPSGE.Complementarity.result_value(m._jump_model[:PF][:k]) ≈ two_by_two_scalar_results["PK.L","Otax=.1"]#    1.1105769136174084
# Implicit Variables
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PF[l]†Y[x]")]) ≈ two_by_two_scalar_results["DXL.L","Otax=.1"]#    52.69195654028726
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PF[l]†Y[y]")]) ≈ two_by_two_scalar_results["DYL.L","Otax=.1"]#    21.298998374443727
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PF[k]†Y[x]")]) ≈ two_by_two_scalar_results["DXK.L","Otax=.1"]#    47.44557166118035
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PF[k]†Y[y]")]) ≈ two_by_two_scalar_results["DYK.L","Otax=.1"]#    28.767478568955543
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PC[x]†U")]) ≈ two_by_two_scalar_results["DUX.L","Otax=.1"]#    96.88706302697432
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PC[y]†U")]) ≈ two_by_two_scalar_results["DUY.L","Otax=.1"]#    53.26456958649977
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PC[x]‡Y[x]")]) ≈ two_by_two_scalar_results["SX.L","Otax=.1"]#    101.16855688658394
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PC[y]‡Y[y]")]) ≈ two_by_two_scalar_results["SY.L","Otax=.1"]#    50.
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PU‡U")]) ≈ two_by_two_scalar_results["SU.L","Otax=.1"]#    50.
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PUρC[ra]")]) ≈ two_by_two_scalar_results["CWI.L","Otax=.1"] # 156.6285843

#Tax on labor for good/sector x (single output sector) 
set_value(outax[:x], 0.0)
set_value(intax[:x], 0.1)
solve!(m)
    
    @test MPSGE.Complementarity.result_value(m._jump_model[:Y][:x]) ≈ two_by_two_scalar_results["X.L","Itax=.1"] # 1.03413947
    @test MPSGE.Complementarity.result_value(m._jump_model[:Y][:y]) ≈ two_by_two_scalar_results["Y.L","Itax=.1"] # 1.06713746
    @test MPSGE.Complementarity.result_value(m._jump_model[:U]) ≈ two_by_two_scalar_results["U.L","Itax=.1"] # 1.04502384
    @test MPSGE.Complementarity.result_value(m._jump_model[:C][:ra]) ≈ two_by_two_scalar_results["RA.L","Itax=.1"] # 176.4583
    @test MPSGE.Complementarity.result_value(m._jump_model[:PC][:x]) ≈ two_by_two_scalar_results["PX.L","Itax=.1"] # 1.13755342
    @test MPSGE.Complementarity.result_value(m._jump_model[:PC][:y]) ≈ two_by_two_scalar_results["PY.L","Itax=.1"] # 1.10237802
    @test MPSGE.Complementarity.result_value(m._jump_model[:PU]) ≈ two_by_two_scalar_results["PU.L","Itax=.1"] # 1.12570531
    @test MPSGE.Complementarity.result_value(m._jump_model[:PF][:l]) ≈ two_by_two_scalar_results["PL.L","Itax=.1"] # 1
    @test MPSGE.Complementarity.result_value(m._jump_model[:PF][:k]) ≈ two_by_two_scalar_results["PK.L","Itax=.1"] # 1.17638888
    # Implicit Variables # 
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PF[l]†Y[x]")]) ≈ two_by_two_scalar_results["DXL.L","Itax=.1"] # 100
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PF[l]†Y[y]")]) ≈ two_by_two_scalar_results["DYL.L","Itax=.1"] # 50
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PF[k]†Y[x]")]) ≈ two_by_two_scalar_results["DXK.L","Itax=.1"] # 51.70697336
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PF[k]†Y[y]")]) ≈ two_by_two_scalar_results["DYK.L","Itax=.1"] # 48.349378
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PC[x]†U")]) ≈ two_by_two_scalar_results["DUX.L","Itax=.1"] # 22.04756047
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PC[y]†U")]) ≈ two_by_two_scalar_results["DUY.L","Itax=.1"] # 28.11259204
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PC[x]‡Y[x]")]) ≈ two_by_two_scalar_results["SX.L","Itax=.1"] # 150
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PC[y]‡Y[y]")]) ≈ two_by_two_scalar_results["SY.L","Itax=.1"] # 98.95845727
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PU‡U")]) ≈ two_by_two_scalar_results["SU.L","Itax=.1"] # 51.05804385
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PUρC[ra]")]) ≈ two_by_two_scalar_results["CWI.L","Itax=.1"] # 150
end

@testitem "TWOBYTWO (indexed w non-1 prices)" begin 
    using XLSX, MPSGE.JuMP.Containers
  

    m = Model()
        goods = [:x, :y]
        factors = [:l, :k]
        consumers = [:ra]
        factor = DenseAxisArray(Float64[50 50; 20 30], goods, factors)
        supply = DenseAxisArray(Float64[100, 50], goods)
        # pricepci = DenseAxisArray(Float64[1., 1.], goods)
        pricepci = add!(m, Parameter(:pricepci, indices=(goods,), value=1.))#value=DenseAxisArray(Float64[1., 1.])))
        endow    = add!(m, Parameter(:endow, indices=(factors,), value=1.0)) 
        
        Y = add!(m, Sector(:Y, indices=(goods,)))
        U = add!(m, Sector(:U))
        PC = add!(m, Commodity(:PC, indices=(goods,)))
        PU = add!(m, Commodity(:PU))
        PF = add!(m, Commodity(:PF, indices=(factors,)))
        C = add!(m, Consumer(:C, indices=(consumers,), benchmark=150.))
    
        for i in goods
            @production(m, Y[i], 0, 1, [Output(PC[i], supply[i])], [Input(PF[:l], factor[i,:l]), Input(PF[:k], factor[i,:k])])
        end
        add!(m, Production(U, 0., 1.0, [Output(PU, 150)], [Input(PC[i], supply[i], [Tax(0.,C[:ra])], :($(pricepci[i])*1.)) for i in goods]))
    
        @demand(m, C[:ra], 1., [Demand(PU, 150)], [Endowment(PF[:l], :(70 * $(endow[:l]))), Endowment(PF[:k], :(80. * $(endow[:k])))])
    
solve!(m, cumulative_iteration_limit=0)

gams_results = XLSX.readxlsx(joinpath(@__DIR__, "MPSGEresults.xlsx"))
a_table = gams_results["TwoxTwowOTax_IndPrice_Nest"][:]  # Generated from TwoByTwo_Scalar_Algeb-MPSGE.gms
TwoxTwowOTax_IndPrice_Nest = DenseAxisArray(a_table[2:end,2:end],string.(a_table[2:end,1],".",a_table[2:end,2]),a_table[1,2:end])

# benchmark
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PF[l]†Y[x]")]) ≈ TwoxTwowOTax_IndPrice_Nest["x.L","benchmark"]#  50
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PF[k]†Y[x]")]) ≈ TwoxTwowOTax_IndPrice_Nest["x.K","benchmark"]#  50
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PF[l]†Y[y]")]) ≈ TwoxTwowOTax_IndPrice_Nest["y.L","benchmark"]#  20
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PF[k]†Y[y]")]) ≈ TwoxTwowOTax_IndPrice_Nest["y.K","benchmark"]#  30
@test MPSGE.Complementarity.result_value(m._jump_model[:Y][:x]) ≈ TwoxTwowOTax_IndPrice_Nest["Y.L.x","benchmark"]#  1
@test MPSGE.Complementarity.result_value(m._jump_model[:Y][:y]) ≈ TwoxTwowOTax_IndPrice_Nest["Y.L.y","benchmark"]#  1
@test MPSGE.Complementarity.result_value(m._jump_model[:U]) ≈ TwoxTwowOTax_IndPrice_Nest["U.L._","benchmark"]#  1
@test MPSGE.Complementarity.result_value(m._jump_model[:PC][:x]) ≈ TwoxTwowOTax_IndPrice_Nest["PC.L.x","benchmark"]#  1
@test MPSGE.Complementarity.result_value(m._jump_model[:PC][:y]) ≈ TwoxTwowOTax_IndPrice_Nest["PC.L.y","benchmark"]#  1
@test MPSGE.Complementarity.result_value(m._jump_model[:PF][:l]) ≈ TwoxTwowOTax_IndPrice_Nest["PF.L.L","benchmark"]#  1
@test MPSGE.Complementarity.result_value(m._jump_model[:PF][:k]) ≈ TwoxTwowOTax_IndPrice_Nest["PF.L.K","benchmark"]#  1
@test MPSGE.Complementarity.result_value(m._jump_model[:PU]) ≈ TwoxTwowOTax_IndPrice_Nest["PU.L._","benchmark"]#  1
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PC[x]†U")]) ≈ TwoxTwowOTax_IndPrice_Nest["DU.L.x","benchmark"]#  100
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PC[y]†U")]) ≈ TwoxTwowOTax_IndPrice_Nest["DU.L.y","benchmark"]#  50
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PU‡U")]) ≈ TwoxTwowOTax_IndPrice_Nest["SU.L._","benchmark"]#  150
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PC[x]‡Y[x]")]) ≈ TwoxTwowOTax_IndPrice_Nest["SY.L(i).x","benchmark"]#  100
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PC[y]‡Y[y]")]) ≈ TwoxTwowOTax_IndPrice_Nest["SY.L(i).y","benchmark"]#  50
@test MPSGE.Complementarity.result_value(m._jump_model[:C][:ra]) ≈ TwoxTwowOTax_IndPrice_Nest["RA.L._","benchmark"]#  150

set_value(endow[:l], get_value(endow[:l])*1.1)
set_value(C[:ra], 157.)
set_fixed!(C[:ra], true)
solve!(m)

# RA=157
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PF[l]†Y[x]")]) ≈ TwoxTwowOTax_IndPrice_Nest["x.L","RA=157"]#  52.4404424
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PF[k]†Y[x]")]) ≈ TwoxTwowOTax_IndPrice_Nest["x.K","RA=157"]#  47.6731295
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PF[l]†Y[y]")]) ≈ TwoxTwowOTax_IndPrice_Nest["y.L","RA=157"]#  21.1770571
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PF[k]†Y[y]")]) ≈ TwoxTwowOTax_IndPrice_Nest["y.K","RA=157"]#  28.8778051
@test MPSGE.Complementarity.result_value(m._jump_model[:Y][:x]) ≈ TwoxTwowOTax_IndPrice_Nest["Y.L.x","RA=157"]#  1.0488088
@test MPSGE.Complementarity.result_value(m._jump_model[:Y][:y]) ≈ TwoxTwowOTax_IndPrice_Nest["Y.L.y","RA=157"]#  1.0388601
@test MPSGE.Complementarity.result_value(m._jump_model[:U]) ≈ TwoxTwowOTax_IndPrice_Nest["U.L._","RA=157"]#  1.0454821
@test MPSGE.Complementarity.result_value(m._jump_model[:PC][:x]) ≈ TwoxTwowOTax_IndPrice_Nest["PC.L.x","RA=157"]#  0.9979575
@test MPSGE.Complementarity.result_value(m._jump_model[:PC][:y]) ≈ TwoxTwowOTax_IndPrice_Nest["PC.L.y","RA=157"]#  1.0075145
@test MPSGE.Complementarity.result_value(m._jump_model[:PF][:l]) ≈ TwoxTwowOTax_IndPrice_Nest["PF.L.L","RA=157"]#  0.9515152
@test MPSGE.Complementarity.result_value(m._jump_model[:PF][:k]) ≈ TwoxTwowOTax_IndPrice_Nest["PF.L.K","RA=157"]#  1.0466667
@test MPSGE.Complementarity.result_value(m._jump_model[:PU]) ≈ TwoxTwowOTax_IndPrice_Nest["PU.L._","RA=157"]#  1.0011331
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PC[x]†U")]) ≈ TwoxTwowOTax_IndPrice_Nest["DU.L.x","RA=157"]#  100.3182058
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PC[y]†U")]) ≈ TwoxTwowOTax_IndPrice_Nest["DU.L.y","RA=157"]#  49.6833066
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PU‡U")]) ≈ TwoxTwowOTax_IndPrice_Nest["SU.L._","RA=157"]#  150
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PC[x]‡Y[x]")]) ≈ TwoxTwowOTax_IndPrice_Nest["SY.L(i).x","RA=157"]#  100
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PC[y]‡Y[y]")]) ≈ TwoxTwowOTax_IndPrice_Nest["SY.L(i).y","RA=157"]#  50
@test MPSGE.Complementarity.result_value(m._jump_model[:C][:ra]) ≈ TwoxTwowOTax_IndPrice_Nest["RA.L._","RA=157"]#  157

set_fixed!(C[:ra], false)
set_fixed!(PC[:x], true)
solve!(m)

# PC.x=1
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PF[l]†Y[x]")]) ≈ TwoxTwowOTax_IndPrice_Nest["x.L","PC.x=1"]#  52.4404424
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PF[k]†Y[x]")]) ≈ TwoxTwowOTax_IndPrice_Nest["x.K","PC.x=1"]#  47.6731295
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PF[l]†Y[y]")]) ≈ TwoxTwowOTax_IndPrice_Nest["y.L","PC.x=1"]#  21.1770571
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PF[k]†Y[y]")]) ≈ TwoxTwowOTax_IndPrice_Nest["y.K","PC.x=1"]#  28.8778051
@test MPSGE.Complementarity.result_value(m._jump_model[:Y][:x]) ≈ TwoxTwowOTax_IndPrice_Nest["Y.L.x","PC.x=1"]#  1.0488088
@test MPSGE.Complementarity.result_value(m._jump_model[:Y][:y]) ≈ TwoxTwowOTax_IndPrice_Nest["Y.L.y","PC.x=1"]#  1.0388601
@test MPSGE.Complementarity.result_value(m._jump_model[:U]) ≈ TwoxTwowOTax_IndPrice_Nest["U.L._","PC.x=1"]#  1.0454821
@test MPSGE.Complementarity.result_value(m._jump_model[:PC][:x]) ≈ TwoxTwowOTax_IndPrice_Nest["PC.L.x","PC.x=1"]#  1
@test MPSGE.Complementarity.result_value(m._jump_model[:PC][:y]) ≈ TwoxTwowOTax_IndPrice_Nest["PC.L.y","PC.x=1"]#  1.0095766
@test MPSGE.Complementarity.result_value(m._jump_model[:PF][:l]) ≈ TwoxTwowOTax_IndPrice_Nest["PF.L.L","PC.x=1"]#  0.9534626
@test MPSGE.Complementarity.result_value(m._jump_model[:PF][:k]) ≈ TwoxTwowOTax_IndPrice_Nest["PF.L.K","PC.x=1"]#  1.0488088
@test MPSGE.Complementarity.result_value(m._jump_model[:PU]) ≈ TwoxTwowOTax_IndPrice_Nest["PU.L._","PC.x=1"]#  1.0031821
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PC[x]†U")]) ≈ TwoxTwowOTax_IndPrice_Nest["DU.L.x","PC.x=1"]#  100.3182058
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PC[y]†U")]) ≈ TwoxTwowOTax_IndPrice_Nest["DU.L.y","PC.x=1"]#  49.6833066
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PU‡U")]) ≈ TwoxTwowOTax_IndPrice_Nest["SU.L._","PC.x=1"]#  150
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PC[x]‡Y[x]")]) ≈ TwoxTwowOTax_IndPrice_Nest["SY.L(i).x","PC.x=1"]#  100
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PC[y]‡Y[y]")]) ≈ TwoxTwowOTax_IndPrice_Nest["SY.L(i).y","PC.x=1"]#  50
@test MPSGE.Complementarity.result_value(m._jump_model[:C][:ra]) ≈ TwoxTwowOTax_IndPrice_Nest["RA.L._","PC.x=1"]#  157.3213272

set_fixed!(PC[:x], false)
set_fixed!(PF[:l], true)
solve!(m)

# PF.l=1
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PF[l]†Y[x]")]) ≈ TwoxTwowOTax_IndPrice_Nest["x.L","PF.l=1"]#  52.4404424
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PF[k]†Y[x]")]) ≈ TwoxTwowOTax_IndPrice_Nest["x.K","PF.l=1"]#  47.6731295
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PF[l]†Y[y]")]) ≈ TwoxTwowOTax_IndPrice_Nest["y.L","PF.l=1"]#  21.1770571
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PF[k]†Y[y]")]) ≈ TwoxTwowOTax_IndPrice_Nest["y.K","PF.l=1"]#  28.8778051
@test MPSGE.Complementarity.result_value(m._jump_model[:Y][:x]) ≈ TwoxTwowOTax_IndPrice_Nest["Y.L.x","PF.l=1"]#  1.0488088
@test MPSGE.Complementarity.result_value(m._jump_model[:Y][:y]) ≈ TwoxTwowOTax_IndPrice_Nest["Y.L.y","PF.l=1"]#  1.0388601
@test MPSGE.Complementarity.result_value(m._jump_model[:U]) ≈ TwoxTwowOTax_IndPrice_Nest["U.L._","PF.l=1"]#  1.0454821
@test MPSGE.Complementarity.result_value(m._jump_model[:PC][:x]) ≈ TwoxTwowOTax_IndPrice_Nest["PC.L.x","PF.l=1"]#  1.0488088
@test MPSGE.Complementarity.result_value(m._jump_model[:PC][:y]) ≈ TwoxTwowOTax_IndPrice_Nest["PC.L.y","PF.l=1"]#  1.0588529
@test MPSGE.Complementarity.result_value(m._jump_model[:PF][:l]) ≈ TwoxTwowOTax_IndPrice_Nest["PF.L.L","PF.l=1"]#  1
@test MPSGE.Complementarity.result_value(m._jump_model[:PF][:k]) ≈ TwoxTwowOTax_IndPrice_Nest["PF.L.K","PF.l=1"]#  1.1
@test MPSGE.Complementarity.result_value(m._jump_model[:PU]) ≈ TwoxTwowOTax_IndPrice_Nest["PU.L._","PF.l=1"]#  1.0521462
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PC[x]†U")]) ≈ TwoxTwowOTax_IndPrice_Nest["DU.L.x","PF.l=1"]#  100.3182058
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PC[y]†U")]) ≈ TwoxTwowOTax_IndPrice_Nest["DU.L.y","PF.l=1"]#  49.6833066
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PU‡U")]) ≈ TwoxTwowOTax_IndPrice_Nest["SU.L._","PF.l=1"]#  150
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PC[x]‡Y[x]")]) ≈ TwoxTwowOTax_IndPrice_Nest["SY.L(i).x","PF.l=1"]#  100
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PC[y]‡Y[y]")]) ≈ TwoxTwowOTax_IndPrice_Nest["SY.L(i).y","PF.l=1"]#  50
@test MPSGE.Complementarity.result_value(m._jump_model[:C][:ra]) ≈ TwoxTwowOTax_IndPrice_Nest["RA.L._","PF.l=1"]#  165

set_value(pricepci[:x] , 2.)
solve!(m)
   
# Pr.x=2
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PF[l]†Y[x]")]) ≈ TwoxTwowOTax_IndPrice_Nest["x.L","Pr.x=2"]#  51.0565454
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PF[k]†Y[x]")]) ≈ TwoxTwowOTax_IndPrice_Nest["x.K","Pr.x=2"]#  48.9653184
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PF[l]†Y[y]")]) ≈ TwoxTwowOTax_IndPrice_Nest["y.L","Pr.x=2"]#  20.5082074
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PF[k]†Y[y]")]) ≈ TwoxTwowOTax_IndPrice_Nest["y.K","Pr.x=2"]#  29.5023165
@test MPSGE.Complementarity.result_value(m._jump_model[:Y][:x]) ≈ TwoxTwowOTax_IndPrice_Nest["Y.L.x","Pr.x=2"]#  1.2567765
@test MPSGE.Complementarity.result_value(m._jump_model[:Y][:y]) ≈ TwoxTwowOTax_IndPrice_Nest["Y.L.y","Pr.x=2"]#  0.6257657
@test MPSGE.Complementarity.result_value(m._jump_model[:U]) ≈ TwoxTwowOTax_IndPrice_Nest["U.L._","Pr.x=2"]#  1.0931727
@test MPSGE.Complementarity.result_value(m._jump_model[:PC][:x]) ≈ TwoxTwowOTax_IndPrice_Nest["PC.L.x","Pr.x=2"]#  1.0211309
@test MPSGE.Complementarity.result_value(m._jump_model[:PC][:y]) ≈ TwoxTwowOTax_IndPrice_Nest["PC.L.y","Pr.x=2"]#  1.0254104
@test MPSGE.Complementarity.result_value(m._jump_model[:PF][:l]) ≈ TwoxTwowOTax_IndPrice_Nest["PF.L.L","Pr.x=2"]#  1
@test MPSGE.Complementarity.result_value(m._jump_model[:PF][:k]) ≈ TwoxTwowOTax_IndPrice_Nest["PF.L.K","Pr.x=2"]#  1.0427083
@test MPSGE.Complementarity.result_value(m._jump_model[:PU]) ≈ TwoxTwowOTax_IndPrice_Nest["PU.L._","Pr.x=2"]#  0.9782941
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PC[x]†U")]) ≈ TwoxTwowOTax_IndPrice_Nest["DU.L.x","Pr.x=2"]#  114.9659562
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PC[y]†U")]) ≈ TwoxTwowOTax_IndPrice_Nest["DU.L.y","Pr.x=2"]#  28.6215389
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PU‡U")]) ≈ TwoxTwowOTax_IndPrice_Nest["SU.L._","Pr.x=2"]#  150
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PC[x]‡Y[x]")]) ≈ TwoxTwowOTax_IndPrice_Nest["SY.L(i).x","Pr.x=2"]#  100
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PC[y]‡Y[y]")]) ≈ TwoxTwowOTax_IndPrice_Nest["SY.L(i).y","Pr.x=2"]#  50
@test MPSGE.Complementarity.result_value(m._jump_model[:C][:ra]) ≈ TwoxTwowOTax_IndPrice_Nest["RA.L._","Pr.x=2"]#  160.4166664

end

@testitem "TWOBYTWO (indexed w non-1 prices and input nesting)" begin 
    using XLSX, MPSGE.JuMP.Containers
  

    m = Model()
        goods = [:x, :y]
        factors = [:l, :k]
        consumers = [:ra]
        factor = DenseAxisArray(Float64[50 50; 20 30], goods, factors)
        supply = DenseAxisArray(Float64[100, 50], goods)
        # pricepci = DenseAxisArray(Float64[1., 1.], goods)
        pricepci = add!(m, Parameter(:pricepci, indices=(goods,), value=1.))#value=DenseAxisArray(Float64[1., 1.])))
        endow    = add!(m, Parameter(:endow, indices=(factors,), value=1.0)) 
        
        Y = add!(m, Sector(:Y, indices=(goods,)))
        U = add!(m, Sector(:U))
        PC = add!(m, Commodity(:PC, indices=(goods,)))
        PU = add!(m, Commodity(:PU))
        PF = add!(m, Commodity(:PF, indices=(factors,)))
        C = add!(m, Consumer(:C, indices=(consumers,), benchmark=150.))
    
        for i in goods
            @production(m, Y[i], 0, 1, [Output(PC[i], supply[i])], [Input(PF[:l], factor[i,:l]), Input(PF[:k], factor[i,:k])])
        end
        
        add!(m, Production(U, 0., 1.0, [Output(PU, 150)], [
            Input(
                Nest(
                    :PCi,
                     1.,
                      150.,
                      [
                        Input(PC[i], supply[i], [Tax(0.,C[:ra])], :($(pricepci[i])*1.)) for i in goods
                        ]
                        ), 150
                        )
                                                        ]
        ))
    
        @demand(m, C[:ra], 1., [Demand(PU, 150)], [Endowment(PF[:l], :(70 * $(endow[:l]))), Endowment(PF[:k], :(80. * $(endow[:k])))])
    
solve!(m, cumulative_iteration_limit=0)

gams_results = XLSX.readxlsx(joinpath(@__DIR__, "MPSGEresults.xlsx"))
a_table = gams_results["TwoxTwowOTax_IndPrice_Nest"][:]  # Generated from TwoByTwo_Scalar_Algeb-MPSGE.gms
TwoxTwowOTax_IndPrice_Nest = DenseAxisArray(a_table[2:end,2:end],string.(a_table[2:end,1],".",a_table[2:end,2]),a_table[1,2:end])

# benchmark
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PF[l]†Y[x]")]) ≈ TwoxTwowOTax_IndPrice_Nest["x.L","benchmark"]#  50
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PF[k]†Y[x]")]) ≈ TwoxTwowOTax_IndPrice_Nest["x.K","benchmark"]#  50
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PF[l]†Y[y]")]) ≈ TwoxTwowOTax_IndPrice_Nest["y.L","benchmark"]#  20
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PF[k]†Y[y]")]) ≈ TwoxTwowOTax_IndPrice_Nest["y.K","benchmark"]#  30
@test MPSGE.Complementarity.result_value(m._jump_model[:Y][:x]) ≈ TwoxTwowOTax_IndPrice_Nest["Y.L.x","benchmark"]#  1
@test MPSGE.Complementarity.result_value(m._jump_model[:Y][:y]) ≈ TwoxTwowOTax_IndPrice_Nest["Y.L.y","benchmark"]#  1
@test MPSGE.Complementarity.result_value(m._jump_model[:U]) ≈ TwoxTwowOTax_IndPrice_Nest["U.L._","benchmark"]#  1
@test MPSGE.Complementarity.result_value(m._jump_model[:PC][:x]) ≈ TwoxTwowOTax_IndPrice_Nest["PC.L.x","benchmark"]#  1
@test MPSGE.Complementarity.result_value(m._jump_model[:PC][:y]) ≈ TwoxTwowOTax_IndPrice_Nest["PC.L.y","benchmark"]#  1
@test MPSGE.Complementarity.result_value(m._jump_model[:PF][:l]) ≈ TwoxTwowOTax_IndPrice_Nest["PF.L.L","benchmark"]#  1
@test MPSGE.Complementarity.result_value(m._jump_model[:PF][:k]) ≈ TwoxTwowOTax_IndPrice_Nest["PF.L.K","benchmark"]#  1
@test MPSGE.Complementarity.result_value(m._jump_model[:PU]) ≈ TwoxTwowOTax_IndPrice_Nest["PU.L._","benchmark"]#  1
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PC[x]†U→PCi")]) ≈ TwoxTwowOTax_IndPrice_Nest["DU.L.x","benchmark"]#  100
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PC[y]†U→PCi")]) ≈ TwoxTwowOTax_IndPrice_Nest["DU.L.y","benchmark"]#  50
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PU‡U")]) ≈ TwoxTwowOTax_IndPrice_Nest["SU.L._","benchmark"]#  150
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PC[x]‡Y[x]")]) ≈ TwoxTwowOTax_IndPrice_Nest["SY.L(i).x","benchmark"]#  100
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PC[y]‡Y[y]")]) ≈ TwoxTwowOTax_IndPrice_Nest["SY.L(i).y","benchmark"]#  50
@test MPSGE.Complementarity.result_value(m._jump_model[:C][:ra]) ≈ TwoxTwowOTax_IndPrice_Nest["RA.L._","benchmark"]#  150

set_value(endow[:l], get_value(endow[:l])*1.1)
set_value(C[:ra], 157.)
set_fixed!(C[:ra], true)
solve!(m)

# RA=157
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PF[l]†Y[x]")]) ≈ TwoxTwowOTax_IndPrice_Nest["x.L","RA=157"]#  52.4404424
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PF[k]†Y[x]")]) ≈ TwoxTwowOTax_IndPrice_Nest["x.K","RA=157"]#  47.6731295
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PF[l]†Y[y]")]) ≈ TwoxTwowOTax_IndPrice_Nest["y.L","RA=157"]#  21.1770571
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PF[k]†Y[y]")]) ≈ TwoxTwowOTax_IndPrice_Nest["y.K","RA=157"]#  28.8778051
@test MPSGE.Complementarity.result_value(m._jump_model[:Y][:x]) ≈ TwoxTwowOTax_IndPrice_Nest["Y.L.x","RA=157"]#  1.0488088
@test MPSGE.Complementarity.result_value(m._jump_model[:Y][:y]) ≈ TwoxTwowOTax_IndPrice_Nest["Y.L.y","RA=157"]#  1.0388601
@test MPSGE.Complementarity.result_value(m._jump_model[:U]) ≈ TwoxTwowOTax_IndPrice_Nest["U.L._","RA=157"]#  1.0454821
@test MPSGE.Complementarity.result_value(m._jump_model[:PC][:x]) ≈ TwoxTwowOTax_IndPrice_Nest["PC.L.x","RA=157"]#  0.9979575
@test MPSGE.Complementarity.result_value(m._jump_model[:PC][:y]) ≈ TwoxTwowOTax_IndPrice_Nest["PC.L.y","RA=157"]#  1.0075145
@test MPSGE.Complementarity.result_value(m._jump_model[:PF][:l]) ≈ TwoxTwowOTax_IndPrice_Nest["PF.L.L","RA=157"]#  0.9515152
@test MPSGE.Complementarity.result_value(m._jump_model[:PF][:k]) ≈ TwoxTwowOTax_IndPrice_Nest["PF.L.K","RA=157"]#  1.0466667
@test MPSGE.Complementarity.result_value(m._jump_model[:PU]) ≈ TwoxTwowOTax_IndPrice_Nest["PU.L._","RA=157"]#  1.0011331
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PC[x]†U→PCi")]) ≈ TwoxTwowOTax_IndPrice_Nest["DU.L.x","RA=157"]#  100.3182058
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PC[y]†U→PCi")]) ≈ TwoxTwowOTax_IndPrice_Nest["DU.L.y","RA=157"]#  49.6833066
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PU‡U")]) ≈ TwoxTwowOTax_IndPrice_Nest["SU.L._","RA=157"]#  150
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PC[x]‡Y[x]")]) ≈ TwoxTwowOTax_IndPrice_Nest["SY.L(i).x","RA=157"]#  100
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PC[y]‡Y[y]")]) ≈ TwoxTwowOTax_IndPrice_Nest["SY.L(i).y","RA=157"]#  50
@test MPSGE.Complementarity.result_value(m._jump_model[:C][:ra]) ≈ TwoxTwowOTax_IndPrice_Nest["RA.L._","RA=157"]#  157

set_fixed!(C[:ra], false)
set_fixed!(PC[:x], true)
solve!(m)

# PC.x=1
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PF[l]†Y[x]")]) ≈ TwoxTwowOTax_IndPrice_Nest["x.L","PC.x=1"]#  52.4404424
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PF[k]†Y[x]")]) ≈ TwoxTwowOTax_IndPrice_Nest["x.K","PC.x=1"]#  47.6731295
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PF[l]†Y[y]")]) ≈ TwoxTwowOTax_IndPrice_Nest["y.L","PC.x=1"]#  21.1770571
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PF[k]†Y[y]")]) ≈ TwoxTwowOTax_IndPrice_Nest["y.K","PC.x=1"]#  28.8778051
@test MPSGE.Complementarity.result_value(m._jump_model[:Y][:x]) ≈ TwoxTwowOTax_IndPrice_Nest["Y.L.x","PC.x=1"]#  1.0488088
@test MPSGE.Complementarity.result_value(m._jump_model[:Y][:y]) ≈ TwoxTwowOTax_IndPrice_Nest["Y.L.y","PC.x=1"]#  1.0388601
@test MPSGE.Complementarity.result_value(m._jump_model[:U]) ≈ TwoxTwowOTax_IndPrice_Nest["U.L._","PC.x=1"]#  1.0454821
@test MPSGE.Complementarity.result_value(m._jump_model[:PC][:x]) ≈ TwoxTwowOTax_IndPrice_Nest["PC.L.x","PC.x=1"]#  1
@test MPSGE.Complementarity.result_value(m._jump_model[:PC][:y]) ≈ TwoxTwowOTax_IndPrice_Nest["PC.L.y","PC.x=1"]#  1.0095766
@test MPSGE.Complementarity.result_value(m._jump_model[:PF][:l]) ≈ TwoxTwowOTax_IndPrice_Nest["PF.L.L","PC.x=1"]#  0.9534626
@test MPSGE.Complementarity.result_value(m._jump_model[:PF][:k]) ≈ TwoxTwowOTax_IndPrice_Nest["PF.L.K","PC.x=1"]#  1.0488088
@test MPSGE.Complementarity.result_value(m._jump_model[:PU]) ≈ TwoxTwowOTax_IndPrice_Nest["PU.L._","PC.x=1"]#  1.0031821
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PC[x]†U→PCi")]) ≈ TwoxTwowOTax_IndPrice_Nest["DU.L.x","PC.x=1"]#  100.3182058
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PC[y]†U→PCi")]) ≈ TwoxTwowOTax_IndPrice_Nest["DU.L.y","PC.x=1"]#  49.6833066
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PU‡U")]) ≈ TwoxTwowOTax_IndPrice_Nest["SU.L._","PC.x=1"]#  150
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PC[x]‡Y[x]")]) ≈ TwoxTwowOTax_IndPrice_Nest["SY.L(i).x","PC.x=1"]#  100
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PC[y]‡Y[y]")]) ≈ TwoxTwowOTax_IndPrice_Nest["SY.L(i).y","PC.x=1"]#  50
@test MPSGE.Complementarity.result_value(m._jump_model[:C][:ra]) ≈ TwoxTwowOTax_IndPrice_Nest["RA.L._","PC.x=1"]#  157.3213272

set_fixed!(PC[:x], false)
set_fixed!(PF[:l], true)
solve!(m)

# PF.l=1
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PF[l]†Y[x]")]) ≈ TwoxTwowOTax_IndPrice_Nest["x.L","PF.l=1"]#  52.4404424
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PF[k]†Y[x]")]) ≈ TwoxTwowOTax_IndPrice_Nest["x.K","PF.l=1"]#  47.6731295
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PF[l]†Y[y]")]) ≈ TwoxTwowOTax_IndPrice_Nest["y.L","PF.l=1"]#  21.1770571
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PF[k]†Y[y]")]) ≈ TwoxTwowOTax_IndPrice_Nest["y.K","PF.l=1"]#  28.8778051
@test MPSGE.Complementarity.result_value(m._jump_model[:Y][:x]) ≈ TwoxTwowOTax_IndPrice_Nest["Y.L.x","PF.l=1"]#  1.0488088
@test MPSGE.Complementarity.result_value(m._jump_model[:Y][:y]) ≈ TwoxTwowOTax_IndPrice_Nest["Y.L.y","PF.l=1"]#  1.0388601
@test MPSGE.Complementarity.result_value(m._jump_model[:U]) ≈ TwoxTwowOTax_IndPrice_Nest["U.L._","PF.l=1"]#  1.0454821
@test MPSGE.Complementarity.result_value(m._jump_model[:PC][:x]) ≈ TwoxTwowOTax_IndPrice_Nest["PC.L.x","PF.l=1"]#  1.0488088
@test MPSGE.Complementarity.result_value(m._jump_model[:PC][:y]) ≈ TwoxTwowOTax_IndPrice_Nest["PC.L.y","PF.l=1"]#  1.0588529
@test MPSGE.Complementarity.result_value(m._jump_model[:PF][:l]) ≈ TwoxTwowOTax_IndPrice_Nest["PF.L.L","PF.l=1"]#  1
@test MPSGE.Complementarity.result_value(m._jump_model[:PF][:k]) ≈ TwoxTwowOTax_IndPrice_Nest["PF.L.K","PF.l=1"]#  1.1
@test MPSGE.Complementarity.result_value(m._jump_model[:PU]) ≈ TwoxTwowOTax_IndPrice_Nest["PU.L._","PF.l=1"]#  1.0521462
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PC[x]†U→PCi")]) ≈ TwoxTwowOTax_IndPrice_Nest["DU.L.x","PF.l=1"]#  100.3182058
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PC[y]†U→PCi")]) ≈ TwoxTwowOTax_IndPrice_Nest["DU.L.y","PF.l=1"]#  49.6833066
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PU‡U")]) ≈ TwoxTwowOTax_IndPrice_Nest["SU.L._","PF.l=1"]#  150
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PC[x]‡Y[x]")]) ≈ TwoxTwowOTax_IndPrice_Nest["SY.L(i).x","PF.l=1"]#  100
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PC[y]‡Y[y]")]) ≈ TwoxTwowOTax_IndPrice_Nest["SY.L(i).y","PF.l=1"]#  50
@test MPSGE.Complementarity.result_value(m._jump_model[:C][:ra]) ≈ TwoxTwowOTax_IndPrice_Nest["RA.L._","PF.l=1"]#  165

set_value(pricepci[:x] , 2.)
solve!(m)
   
# Pr.x=2
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PF[l]†Y[x]")]) ≈ TwoxTwowOTax_IndPrice_Nest["x.L","Pr.x=2"]#  51.0565454
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PF[k]†Y[x]")]) ≈ TwoxTwowOTax_IndPrice_Nest["x.K","Pr.x=2"]#  48.9653184
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PF[l]†Y[y]")]) ≈ TwoxTwowOTax_IndPrice_Nest["y.L","Pr.x=2"]#  20.5082074
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PF[k]†Y[y]")]) ≈ TwoxTwowOTax_IndPrice_Nest["y.K","Pr.x=2"]#  29.5023165
@test MPSGE.Complementarity.result_value(m._jump_model[:Y][:x]) ≈ TwoxTwowOTax_IndPrice_Nest["Y.L.x","Pr.x=2"]#  1.2567765
@test MPSGE.Complementarity.result_value(m._jump_model[:Y][:y]) ≈ TwoxTwowOTax_IndPrice_Nest["Y.L.y","Pr.x=2"]#  0.6257657
@test MPSGE.Complementarity.result_value(m._jump_model[:U]) ≈ TwoxTwowOTax_IndPrice_Nest["U.L._","Pr.x=2"]#  1.0931727
@test MPSGE.Complementarity.result_value(m._jump_model[:PC][:x]) ≈ TwoxTwowOTax_IndPrice_Nest["PC.L.x","Pr.x=2"]#  1.0211309
@test MPSGE.Complementarity.result_value(m._jump_model[:PC][:y]) ≈ TwoxTwowOTax_IndPrice_Nest["PC.L.y","Pr.x=2"]#  1.0254104
@test MPSGE.Complementarity.result_value(m._jump_model[:PF][:l]) ≈ TwoxTwowOTax_IndPrice_Nest["PF.L.L","Pr.x=2"]#  1
@test MPSGE.Complementarity.result_value(m._jump_model[:PF][:k]) ≈ TwoxTwowOTax_IndPrice_Nest["PF.L.K","Pr.x=2"]#  1.0427083
@test MPSGE.Complementarity.result_value(m._jump_model[:PU]) ≈ TwoxTwowOTax_IndPrice_Nest["PU.L._","Pr.x=2"]#  0.9782941
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PC[x]†U→PCi")]) ≈ TwoxTwowOTax_IndPrice_Nest["DU.L.x","Pr.x=2"]#  114.9659562
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PC[y]†U→PCi")]) ≈ TwoxTwowOTax_IndPrice_Nest["DU.L.y","Pr.x=2"]#  28.6215389
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PU‡U")]) ≈ TwoxTwowOTax_IndPrice_Nest["SU.L._","Pr.x=2"]#  150
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PC[x]‡Y[x]")]) ≈ TwoxTwowOTax_IndPrice_Nest["SY.L(i).x","Pr.x=2"]#  100
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PC[y]‡Y[y]")]) ≈ TwoxTwowOTax_IndPrice_Nest["SY.L(i).y","Pr.x=2"]#  50
@test MPSGE.Complementarity.result_value(m._jump_model[:C][:ra]) ≈ TwoxTwowOTax_IndPrice_Nest["RA.L._","Pr.x=2"]#  160.4166664

end