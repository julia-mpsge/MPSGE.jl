using MPSGE, MPSGE.JuMP.Containers

    m = Model()
        goods = [:x, :y]
        factors = [:l, :k]
        consumers = [:ra]
        factor = DenseAxisArray(Float64[50 50; 20 30], goods, factors)
        supply = DenseAxisArray(Float64[100, 50], goods)
        cons   = DenseAxisArray(Float64[75, 75], factors)
        pricepu = add!(m, Parameter(:pricepu, indices=(factors,), value=1.))#value=DenseAxisArray(Float64[1., 1.])))
        endow    = add!(m, Parameter(:endow, indices=(factors,), value=1.0)) 
        
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
                Input(PU[f], cons[f], [Tax(0.,C[:ra])] ,:($(pricepu[f])*1.)) for f in factors
            ]
            ),150. )],
                # PU[f], cons[f], :($(pricepu[f])*1.)) for f in factors], 
            [Endowment(PF[:l], :(70 * $(endow[:l]))), Endowment(PF[:k], :(80. * $(endow[:k])))]))

# solve!(m, cumulative_iteration_limit=0)

# gams_results = XLSX.readxlsx(joinpath(@__DIR__, "MPSGEresults.xlsx"))
# a_table = gams_results["TwoxTwo_DemandIndPrice_Nest"][:]                                                                                # Generated from TowbyTwo_Indexed_wDemand-non-1price_nest.gms
# TwoxTwo_DemandIndPrice_Nest = DenseAxisArray(a_table[2:end,2:end],string.(a_table[2:end,1],".",a_table[2:end,2]),a_table[1,2:end])

# # benchmark
# @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PF[l]†Y[x]")]) ≈ TwoxTwo_DemandIndPrice_Nest["x.L","benchmark"]#  50
# @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PF[k]†Y[x]")]) ≈ TwoxTwo_DemandIndPrice_Nest["x.K","benchmark"]#  50
# @test MPSGE.Complementarity.result_value(m._jump_model[:Y][:x]) ≈ TwoxTwo_DemandIndPrice_Nest["y.x","benchmark"]#  1
# @test MPSGE.Complementarity.result_value(m._jump_model[:Y][:y]) ≈ TwoxTwo_DemandIndPrice_Nest["y.y","benchmark"]#  1
# @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PF[l]†Y[y]")]) ≈ TwoxTwo_DemandIndPrice_Nest["y.L","benchmark"]#  20
# @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PF[k]†Y[y]")]) ≈ TwoxTwo_DemandIndPrice_Nest["y.K","benchmark"]#  30
# @test MPSGE.Complementarity.result_value(m._jump_model[:U]) ≈ TwoxTwo_DemandIndPrice_Nest["U._","benchmark"]#  1
# @test MPSGE.Complementarity.result_value(m._jump_model[:C][:ra]) ≈ TwoxTwo_DemandIndPrice_Nest["RA._","benchmark"]#  150
# @test MPSGE.Complementarity.result_value(m._jump_model[:PC][:x]) ≈ TwoxTwo_DemandIndPrice_Nest["PC.x","benchmark"]#  1
# @test MPSGE.Complementarity.result_value(m._jump_model[:PC][:y]) ≈ TwoxTwo_DemandIndPrice_Nest["PC.y","benchmark"]#  1
# @test MPSGE.Complementarity.result_value(m._jump_model[:PF][:l]) ≈ TwoxTwo_DemandIndPrice_Nest["PF.L","benchmark"]#  1
# @test MPSGE.Complementarity.result_value(m._jump_model[:PF][:k]) ≈ TwoxTwo_DemandIndPrice_Nest["PF.K","benchmark"]#  1
# @test MPSGE.Complementarity.result_value(m._jump_model[:PU][:l]) ≈ TwoxTwo_DemandIndPrice_Nest["PU.L","benchmark"]#  1
# @test MPSGE.Complementarity.result_value(m._jump_model[:PU][:k]) ≈ TwoxTwo_DemandIndPrice_Nest["PU.K","benchmark"]#  1
# @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PC[x]†U")]) ≈ TwoxTwo_DemandIndPrice_Nest["DU.x","benchmark"]#  100
# @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PC[y]†U")]) ≈ TwoxTwo_DemandIndPrice_Nest["DU.y","benchmark"]#  50
# @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PU[l]‡U")]) ≈ TwoxTwo_DemandIndPrice_Nest["SU.L","benchmark"]#  75
# @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PU[k]‡U")]) ≈ TwoxTwo_DemandIndPrice_Nest["SU.K","benchmark"]#  75
# @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PC[x]‡Y[x]")]) ≈ TwoxTwo_DemandIndPrice_Nest["SY.x","benchmark"]#  100
# @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PC[y]‡Y[y]")]) ≈ TwoxTwo_DemandIndPrice_Nest["SY.y","benchmark"]#  50
# @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PC→CUρC[ra]")]) ≈ TwoxTwo_DemandIndPrice_Nest["FDRA.L","benchmark"] + TwoxTwo_DemandIndPrice_Nest["FDRA.K","benchmark"] # 75 + 75
# # @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PU[k]ρC[ra]")]) ≈ TwoxTwo_DemandIndPrice_Nest["FDRA.K","benchmark"]#  75

set_value(endow[:l], get_value(endow[:l])*1.1)
set_value(C[:ra], 157.)
set_fixed!(C[:ra], true)
# solve!(m)
# # RA=157
# @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PF[l]†Y[x]")]) ≈ TwoxTwo_DemandIndPrice_Nest["x.L","RA=157"]#  52.4404424
# @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PF[k]†Y[x]")]) ≈ TwoxTwo_DemandIndPrice_Nest["x.K","RA=157"]#  47.6731295
# @test MPSGE.Complementarity.result_value(m._jump_model[:Y][:x]) ≈ TwoxTwo_DemandIndPrice_Nest["y.x","RA=157"]#  1.0488088
# @test MPSGE.Complementarity.result_value(m._jump_model[:Y][:y]) ≈ TwoxTwo_DemandIndPrice_Nest["y.y","RA=157"]#  1.0388601
# @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PF[l]†Y[y]")]) ≈ TwoxTwo_DemandIndPrice_Nest["y.L","RA=157"]#  21.1770571
# @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PF[k]†Y[y]")]) ≈ TwoxTwo_DemandIndPrice_Nest["y.K","RA=157"]#  28.8778051
# @test MPSGE.Complementarity.result_value(m._jump_model[:U]) ≈ TwoxTwo_DemandIndPrice_Nest["U._","RA=157"]#  1.0454821
# @test MPSGE.Complementarity.result_value(m._jump_model[:C][:ra]) ≈ TwoxTwo_DemandIndPrice_Nest["RA._","RA=157"]#  157
# @test MPSGE.Complementarity.result_value(m._jump_model[:PC][:x]) ≈ TwoxTwo_DemandIndPrice_Nest["PC.x","RA=157"]#  0.9979575
# @test MPSGE.Complementarity.result_value(m._jump_model[:PC][:y]) ≈ TwoxTwo_DemandIndPrice_Nest["PC.y","RA=157"]#  1.0075145
# @test MPSGE.Complementarity.result_value(m._jump_model[:PF][:l]) ≈ TwoxTwo_DemandIndPrice_Nest["PF.L","RA=157"]#  0.9515152
# @test MPSGE.Complementarity.result_value(m._jump_model[:PF][:k]) ≈ TwoxTwo_DemandIndPrice_Nest["PF.K","RA=157"]#  1.0466667
# @test MPSGE.Complementarity.result_value(m._jump_model[:PU][:l]) ≈ TwoxTwo_DemandIndPrice_Nest["PU.L","RA=157"]#  1.0011331
# @test MPSGE.Complementarity.result_value(m._jump_model[:PU][:k]) ≈ TwoxTwo_DemandIndPrice_Nest["PU.K","RA=157"]#  1.0011331
# @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PC[x]†U")]) ≈ TwoxTwo_DemandIndPrice_Nest["DU.x","RA=157"]#  100.3182058
# @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PC[y]†U")]) ≈ TwoxTwo_DemandIndPrice_Nest["DU.y","RA=157"]#  49.6833066
# @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PU[l]‡U")]) ≈ TwoxTwo_DemandIndPrice_Nest["SU.L","RA=157"]#  75
# @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PU[k]‡U")]) ≈ TwoxTwo_DemandIndPrice_Nest["SU.K","RA=157"]#  75
# @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PC[x]‡Y[x]")]) ≈ TwoxTwo_DemandIndPrice_Nest["SY.x","RA=157"]#  100
# @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PC[y]‡Y[y]")]) ≈ TwoxTwo_DemandIndPrice_Nest["SY.y","RA=157"]#  50
# @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PC→CUρC[ra]")]) ≈ TwoxTwo_DemandIndPrice_Nest["FDRA.L","RA=157"] + TwoxTwo_DemandIndPrice_Nest["FDRA.K","RA=157"] # 78.4111548 + 78.4111548
# # @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PU[k]ρC[ra]")]) ≈ TwoxTwo_DemandIndPrice_Nest["FDRA.K","RA=157"]#  78.4111548

set_fixed!(C[:ra], false)
set_fixed!(PU[:k], true)
# solve!(m)
# # PC.x=1
# @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PF[l]†Y[x]")]) ≈ TwoxTwo_DemandIndPrice_Nest["x.L","PC.x=1"]#  52.4404424
# @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PF[k]†Y[x]")]) ≈ TwoxTwo_DemandIndPrice_Nest["x.K","PC.x=1"]#  47.6731295
# @test MPSGE.Complementarity.result_value(m._jump_model[:Y][:x]) ≈ TwoxTwo_DemandIndPrice_Nest["y.x","PC.x=1"]#  1.0488088
# @test MPSGE.Complementarity.result_value(m._jump_model[:Y][:y]) ≈ TwoxTwo_DemandIndPrice_Nest["y.y","PC.x=1"]#  1.0388601
# @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PF[l]†Y[y]")]) ≈ TwoxTwo_DemandIndPrice_Nest["y.L","PC.x=1"]#  21.1770571
# @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PF[k]†Y[y]")]) ≈ TwoxTwo_DemandIndPrice_Nest["y.K","PC.x=1"]#  28.8778051
# @test MPSGE.Complementarity.result_value(m._jump_model[:U]) ≈ TwoxTwo_DemandIndPrice_Nest["U._","PC.x=1"]#  1.0454821
# @test MPSGE.Complementarity.result_value(m._jump_model[:C][:ra]) ≈ TwoxTwo_DemandIndPrice_Nest["RA._","PC.x=1"]#  156.8223095
# @test MPSGE.Complementarity.result_value(m._jump_model[:PC][:x]) ≈ TwoxTwo_DemandIndPrice_Nest["PC.x","PC.x=1"]#  0.996828
# @test MPSGE.Complementarity.result_value(m._jump_model[:PC][:y]) ≈ TwoxTwo_DemandIndPrice_Nest["PC.y","PC.x=1"]#  1.0063742
# @test MPSGE.Complementarity.result_value(m._jump_model[:PF][:l]) ≈ TwoxTwo_DemandIndPrice_Nest["PF.L","PC.x=1"]#  0.9504382
# @test MPSGE.Complementarity.result_value(m._jump_model[:PF][:k]) ≈ TwoxTwo_DemandIndPrice_Nest["PF.K","PC.x=1"]#  1.0454821
# @test MPSGE.Complementarity.result_value(m._jump_model[:PU][:l]) ≈ TwoxTwo_DemandIndPrice_Nest["PU.L","PC.x=1"]#  1
# @test MPSGE.Complementarity.result_value(m._jump_model[:PU][:k]) ≈ TwoxTwo_DemandIndPrice_Nest["PU.K","PC.x=1"]#  1
# @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PC[x]†U")]) ≈ TwoxTwo_DemandIndPrice_Nest["DU.x","PC.x=1"]#  100.3182058
# @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PC[y]†U")]) ≈ TwoxTwo_DemandIndPrice_Nest["DU.y","PC.x=1"]#  49.6833066
# @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PU[l]‡U")]) ≈ TwoxTwo_DemandIndPrice_Nest["SU.L","PC.x=1"]#  75
# @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PU[k]‡U")]) ≈ TwoxTwo_DemandIndPrice_Nest["SU.K","PC.x=1"]#  75
# @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PC[x]‡Y[x]")]) ≈ TwoxTwo_DemandIndPrice_Nest["SY.x","PC.x=1"]#  100
# @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PC[y]‡Y[y]")]) ≈ TwoxTwo_DemandIndPrice_Nest["SY.y","PC.x=1"]#  50
# @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PC→CUρC[ra]")]) ≈ TwoxTwo_DemandIndPrice_Nest["FDRA.L","PC.x=1"] + TwoxTwo_DemandIndPrice_Nest["FDRA.K","PC.x=1"] # 78.4111548 + 78.4111548
# # @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PU[k]ρC[ra]")]) ≈ TwoxTwo_DemandIndPrice_Nest["FDRA.K","PC.x=1"]#  78.4111548

set_value(pricepu[:l] , 1.5)
solve!(m)
# # Pr.l=2
# @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PF[l]†Y[x]")]) ≈ TwoxTwo_DemandIndPrice_Nest["x.L","Pr.l=1.5"]#  52.4404424
# @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PF[k]†Y[x]")]) ≈ TwoxTwo_DemandIndPrice_Nest["x.K","Pr.l=1.5"]#  47.6731295
# @test MPSGE.Complementarity.result_value(m._jump_model[:Y][:x]) ≈ TwoxTwo_DemandIndPrice_Nest["y.x","Pr.l=1.5"]#  1.0488088
# @test MPSGE.Complementarity.result_value(m._jump_model[:Y][:y]) ≈ TwoxTwo_DemandIndPrice_Nest["y.y","Pr.l=1.5"]#  1.0388601
# @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PF[l]†Y[y]")]) ≈ TwoxTwo_DemandIndPrice_Nest["y.L","Pr.l=1.5"]#  21.1770571
# @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PF[k]†Y[y]")]) ≈ TwoxTwo_DemandIndPrice_Nest["y.K","Pr.l=1.5"]#  28.8778051
# @test MPSGE.Complementarity.result_value(m._jump_model[:U]) ≈ TwoxTwo_DemandIndPrice_Nest["U._","Pr.l=1.5"]#  1.0454821
# @test MPSGE.Complementarity.result_value(m._jump_model[:C][:ra]) ≈ TwoxTwo_DemandIndPrice_Nest["RA._","Pr.l=1.5"]#  196.0278842
# @test MPSGE.Complementarity.result_value(m._jump_model[:PC][:x]) ≈ TwoxTwo_DemandIndPrice_Nest["PC.x","Pr.l=1.5"]#  1.246035
# @test MPSGE.Complementarity.result_value(m._jump_model[:PC][:y]) ≈ TwoxTwo_DemandIndPrice_Nest["PC.y","Pr.l=1.5"]#  1.2579678
# @test MPSGE.Complementarity.result_value(m._jump_model[:PF][:l]) ≈ TwoxTwo_DemandIndPrice_Nest["PF.L","Pr.l=1.5"]#  1.1880478
# @test MPSGE.Complementarity.result_value(m._jump_model[:PF][:k]) ≈ TwoxTwo_DemandIndPrice_Nest["PF.K","Pr.l=1.5"]#  1.3068526
# @test MPSGE.Complementarity.result_value(m._jump_model[:PU][:l]) ≈ TwoxTwo_DemandIndPrice_Nest["PU.L","Pr.l=1.5"] atol= 1e-7 #  1.5 
# @test MPSGE.Complementarity.result_value(m._jump_model[:PU][:k]) ≈ TwoxTwo_DemandIndPrice_Nest["PU.K","Pr.l=1.5"]#  1
# @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PC[x]†U")]) ≈ TwoxTwo_DemandIndPrice_Nest["DU.x","Pr.l=1.5"]#  100.3182058
# @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PC[y]†U")]) ≈ TwoxTwo_DemandIndPrice_Nest["DU.y","Pr.l=1.5"]#  49.6833066
# @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PU[l]‡U")]) ≈ TwoxTwo_DemandIndPrice_Nest["SU.L","Pr.l=1.5"]#  75
# @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PU[k]‡U")]) ≈ TwoxTwo_DemandIndPrice_Nest["SU.K","Pr.l=1.5"]#  75
# @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PC[x]‡Y[x]")]) ≈ TwoxTwo_DemandIndPrice_Nest["SY.x","Pr.l=1.5"]#  100
# @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PC[y]‡Y[y]")]) ≈ TwoxTwo_DemandIndPrice_Nest["SY.y","Pr.l=1.5"]#  50
# @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PC→CUρC[ra]")]) ≈ TwoxTwo_DemandIndPrice_Nest["FDRA.L","Pr.l=1.5"]+TwoxTwo_DemandIndPrice_Nest["FDRA.K","Pr.l=1.5"]#  78.4111555 + 78.4111555
# # @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PU[k]ρC[ra]")]) ≈ TwoxTwo_DemandIndPrice_Nest["FDRA.K","Pr.l=1.5"]#  78.4111537

set_fixed!(PC[:x], false)
set_fixed!(PF[:l], true)
solve!(m)
# # PF.l=1
# @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PF[l]†Y[x]")]) ≈ TwoxTwo_DemandIndPrice_Nest["x.L","PF.l=1"]#  56.5057343
# @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PF[k]†Y[x]")]) ≈ TwoxTwo_DemandIndPrice_Nest["x.K","PF.l=1"]#  44.2432973
# @test MPSGE.Complementarity.result_value(m._jump_model[:Y][:x]) ≈ TwoxTwo_DemandIndPrice_Nest["y.x","PF.l=1"]#  1.1301147
# @test MPSGE.Complementarity.result_value(m._jump_model[:Y][:y]) ≈ TwoxTwo_DemandIndPrice_Nest["y.y","PF.l=1"]#  1.1028032
# @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PF[l]†Y[y]")]) ≈ TwoxTwo_DemandIndPrice_Nest["y.L","PF.l=1"]#  23.1620512
# @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PF[k]†Y[y]")]) ≈ TwoxTwo_DemandIndPrice_Nest["y.K","PF.l=1"]#  27.2034033
# @test MPSGE.Complementarity.result_value(m._jump_model[:U]) ≈ TwoxTwo_DemandIndPrice_Nest["U._","PF.l=1"]#  1.1209365
# @test MPSGE.Complementarity.result_value(m._jump_model[:C][:ra]) ≈ TwoxTwo_DemandIndPrice_Nest["RA._","PF.l=1"]#  179.1727363
# @test MPSGE.Complementarity.result_value(m._jump_model[:PC][:x]) ≈ TwoxTwo_DemandIndPrice_Nest["PC.x","PF.l=1"]#  1.1301147
# @test MPSGE.Complementarity.result_value(m._jump_model[:PC][:y]) ≈ TwoxTwo_DemandIndPrice_Nest["PC.y","PF.l=1"]#  1.1581026
# @test MPSGE.Complementarity.result_value(m._jump_model[:PF][:l]) ≈ TwoxTwo_DemandIndPrice_Nest["PF.L","PF.l=1"]#  1
# @test MPSGE.Complementarity.result_value(m._jump_model[:PF][:k]) ≈ TwoxTwo_DemandIndPrice_Nest["PF.K","PF.l=1"]#  1.2771592
# @test MPSGE.Complementarity.result_value(m._jump_model[:PU][:l]) ≈ TwoxTwo_DemandIndPrice_Nest["PU.L","PF.l=1"]#  1.278736
# @test MPSGE.Complementarity.result_value(m._jump_model[:PU][:k]) ≈ TwoxTwo_DemandIndPrice_Nest["PU.K","PF.l=1"]#  1
# @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PC[x]†U")]) ≈ TwoxTwo_DemandIndPrice_Nest["DU.x","PF.l=1"]#  100.8187947
# @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PC[y]†U")]) ≈ TwoxTwo_DemandIndPrice_Nest["DU.y","PF.l=1"]#  49.191153
# @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PU[l]‡U")]) ≈ TwoxTwo_DemandIndPrice_Nest["SU.L","PF.l=1"]#  75
# @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PU[k]‡U")]) ≈ TwoxTwo_DemandIndPrice_Nest["SU.K","PF.l=1"]#  75
# @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PC[x]‡Y[x]")]) ≈ TwoxTwo_DemandIndPrice_Nest["SY.x","PF.l=1"]#  100
# @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PC[y]‡Y[y]")]) ≈ TwoxTwo_DemandIndPrice_Nest["SY.y","PF.l=1"]#  50
# For the counterfacturals where there two nested final demands are equal, summing matches our results, but for this they are different and summing the two doesn't match
# @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PC→CUρC[ra]")]) ≈ TwoxTwo_DemandIndPrice_Nest["FDRA.L","PF.l=1"]+TwoxTwo_DemandIndPrice_Nest["FDRA.K","PF.l=1"]#  84.0702388 +  71.6690945
# @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PU[k]ρC[ra]")]) ≈ TwoxTwo_DemandIndPrice_Nest["FDRA.K","PF.l=1"]#  71.6690945
