@testset "TWOBYTWO (indexed version)" begin
    m = Model()
    goods = [:x, :y]
    factors = [:l, :k]
    factor = DenseAxisArray(Float64[50 50; 20 30], goods, factors)
    supply = DenseAxisArray(Float64[100, 50], goods)
    endow = add!(m, Parameter(:endow, indices=(factors,), value=1.0)) 
    Y = add!(m, Sector(:Y, indices=(goods,)))
    U = add!(m, Sector(:U))
    PC = add!(m, Commodity(:PC, indices=(goods,)))
    PU = add!(m, Commodity(:PU))
    PF = add!(m, Commodity(:PF, indices=(factors,)))
    RA = add!(m, Consumer(:RA, benchmark=150.))

    for i in goods
        @production(m, Y[i], 0, 1, [Output(PC[i], supply[i])], [Input(PF[:l], factor[i,:l]), Input(PF[:k], factor[i,:k])])
    end
    @production(m, U, 0, 1, [Output(PU, 150)], [Input(PC[:x], 100), Input(PC[:y], 50)])
    @demand(m, RA, 1., [Demand(PU, 150)], [Endowment(PF[:l], :(70 * $(endow[:l]))), Endowment(PF[:k], :(80. * $(endow[:k])))])

    solve!(m, cumulative_iteration_limit=0)
    
    @test MPSGE.Complementarity.result_value(m._jump_model[:Y][:x]) ≈ 1.
    @test MPSGE.Complementarity.result_value(m._jump_model[:Y][:y]) ≈ 1.
    @test MPSGE.Complementarity.result_value(m._jump_model[:U]) ≈ 1.
    @test MPSGE.Complementarity.result_value(m._jump_model[:RA]) ≈ 150.
    @test MPSGE.Complementarity.result_value(m._jump_model[:PC][:x]) ≈ 1.
    @test MPSGE.Complementarity.result_value(m._jump_model[:PC][:y]) ≈ 1.
    @test MPSGE.Complementarity.result_value(m._jump_model[:PU]) ≈ 1.
    @test MPSGE.Complementarity.result_value(m._jump_model[:PF][:l]) ≈ 1.
    @test MPSGE.Complementarity.result_value(m._jump_model[:PF][:k]) ≈ 1.
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PF[l]†Y[x]")]) ≈ 50.
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PF[l]†Y[y]")]) ≈ 20.
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PF[k]†Y[x]")]) ≈ 50.
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PF[k]†Y[y]")]) ≈ 30.
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PC[x]†U")]) ≈ 100.
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PC[y]†U")]) ≈ 50.

    set_fixed!(PC[:x], false)
    set_value(endow[:l], get_value(endow[:l]).*1.1)
    set_value(RA, (get_value(endow[:k]) * 80. + get_value(endow[:l]) * 70.))
    set_fixed!(RA, true)
    solve!(m)
    
    # TODO #67 What is the status of these commented lines here? Can they be removed?
    # @test MPSGE.Complementarity.result_value(m._jump_model[:Y][:x]) ≈ 1.04986567
    # @test MPSGE.Complementarity.result_value(m._jump_model[:Y][:y]) ≈ 1.03676649
    # @test MPSGE.Complementarity.result_value(m._jump_model[:U]) ≈ 1.04335615
    # @test MPSGE.Complementarity.result_value(m._jump_model[:PC][:x]) ≈ 1
    # @test MPSGE.Complementarity.result_value(m._jump_model[:PC][:y]) ≈ 1.00954909
    # @test MPSGE.Complementarity.result_value(m._jump_model[:PU]) ≈ 1.00317295
    # @test MPSGE.Complementarity.result_value(m._jump_model[:PF][:l]) ≈ 0.95359243
    # @test MPSGE.Complementarity.result_value(m._jump_model[:PF][:k]) ≈ 1.04866605
    @test MPSGE.Complementarity.result_value(m._jump_model[:Y][:x]) ≈ 1.04880884820911
    @test MPSGE.Complementarity.result_value(m._jump_model[:Y][:y]) ≈ 1.03886011829462
    @test MPSGE.Complementarity.result_value(m._jump_model[:U]) ≈ 1.04548206361865
    @test MPSGE.Complementarity.result_value(m._jump_model[:PC][:x]) ≈ 0.99795751002834
    @test MPSGE.Complementarity.result_value(m._jump_model[:PC][:y]) ≈ 1.0075145327343
    @test MPSGE.Complementarity.result_value(m._jump_model[:PU]) ≈ 1.00113306873355
    @test MPSGE.Complementarity.result_value(m._jump_model[:PF][:l]) ≈ 0.951515151456072
    @test MPSGE.Complementarity.result_value(m._jump_model[:PF][:k]) ≈ 1.04666666668683
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PF[l]†Y[x]")]) ≈ 52.44044241 #note - digits after 52.4404 added from MPSGE.jl results bc GAMS not showing 
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PF[l]†Y[y]")]) ≈ 21.17705706 #note - digits after 21.1771 added from MPSGE.jl results bc GAMS not showing
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PF[k]†Y[x]")]) ≈ 47.67312946 #note - digits after 47.6731 added from MPSGE.jl results bc GAMS not showing
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PF[k]†Y[y]")]) ≈ 28.877805079685
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PC[x]†U")]) ≈ 100.318205802571
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PC[y]†U")]) ≈ 49.6833066029729
    @test MPSGE.Complementarity.result_value(m._jump_model[:RA]) ≈ 157
          
    set_fixed!(RA, false)
    set_fixed!(PC[:x], true)

    solve!(m)
    @test MPSGE.Complementarity.result_value(m._jump_model[:Y][:x]) ≈ 1.04880885
    @test MPSGE.Complementarity.result_value(m._jump_model[:Y][:y]) ≈ 1.03886012
    @test MPSGE.Complementarity.result_value(m._jump_model[:U]) ≈ 1.04548206
    @test MPSGE.Complementarity.result_value(m._jump_model[:RA]) ≈ 157.321327225523
    @test MPSGE.Complementarity.result_value(m._jump_model[:PC][:x]) ≈ 1.0000000000
    @test MPSGE.Complementarity.result_value(m._jump_model[:PC][:y]) ≈ 1.00957658
    @test MPSGE.Complementarity.result_value(m._jump_model[:PU]) ≈ 1.00318206
    @test MPSGE.Complementarity.result_value(m._jump_model[:PF][:l]) ≈ 0.95346259
    @test MPSGE.Complementarity.result_value(m._jump_model[:PF][:k]) ≈ 1.04880885
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PF[l]†Y[x]")]) ≈ 52.4404424085075
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PF[l]†Y[y]")]) ≈ 21.1770570584356
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PF[k]†Y[x]")]) ≈ 47.6731294622795
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PF[k]†Y[y]")]) ≈ 28.877805079685
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PC[x]†U")]) ≈ 100.318205802571
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PC[y]†U")]) ≈ 49.6833066029729

    set_fixed!(PC[:x], false)
    set_fixed!(PF[:l], true)
    solve!(m)
            
    @test MPSGE.Complementarity.result_value(m._jump_model[:Y][:x]) ≈ 1.04880885
    @test MPSGE.Complementarity.result_value(m._jump_model[:Y][:y]) ≈ 1.03886012
    @test MPSGE.Complementarity.result_value(m._jump_model[:U]) ≈ 1.04548206
    @test MPSGE.Complementarity.result_value(m._jump_model[:PC][:x]) ≈ 1.04880885
    @test MPSGE.Complementarity.result_value(m._jump_model[:PC][:y]) ≈ 1.05885285
    @test MPSGE.Complementarity.result_value(m._jump_model[:PU]) ≈ 1.05214622
    @test MPSGE.Complementarity.result_value(m._jump_model[:PF][:l]) ≈ 1
    @test MPSGE.Complementarity.result_value(m._jump_model[:PF][:k]) ≈ 1.1
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PF[l]†Y[x]")]) ≈ 52.44044241 #note - digits after 52.4404 added from MPSGE.jl results bc GAMS not showing
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PF[l]†Y[y]")]) ≈ 21.17705706 #note - digits after 21.1771 added from MPSGE.jl results bc GAMS not showing
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PF[k]†Y[x]")]) ≈ 47.67312946 #note - digits after 47.6731 added from MPSGE.jl results bc GAMS not showing
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PF[k]†Y[y]")]) ≈ 28.87780508 #note - digits after 28.8778 added from MPSGE.jl results bc GAMS not showing
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PC[x]†U")]) ≈ 100.3182058 #note - digits after 100.3182 added from MPSGE.jl results bc GAMS not showing
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PC[y]†U")]) ≈ 49.6833066 #note - digits after 49.6833 added from MPSGE.jl results bc GAMS not showing
    @test MPSGE.Complementarity.result_value(m._jump_model[:RA]) ≈ 165                            
end
