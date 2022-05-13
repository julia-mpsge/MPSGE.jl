using MPSGE
using Test
using MPSGE.JuMP.Containers
using XLSX

@testset "MPSGE" begin

    @testset "TWOBYTWO (functional version)" begin
        m = Model()
# Here parameter values are doubled and input data halved from MPSGE version       
        inputcoeff = add!(m, Parameter(:inputcoeff, value=2.))
        endow = add!(m, Parameter(:endow, value=2.))
        elascoeff = add!(m, Parameter(:elascoeff, value=2.))
        outputmult = add!(m, Parameter(:outputmult, value=2.))

        X = add!(m, Sector(:X))
        Y = add!(m, Sector(:Y))
        U = add!(m, Sector(:U))

        PX = add!(m, Commodity(:PX))
        PY = add!(m, Commodity(:PY))
        PU = add!(m, Commodity(:PU))
        PL = add!(m, Commodity(:PL))
        PK = add!(m, Commodity(:PK))

        RA = add!(m, Consumer(:RA, benchmark=150.))

        add!(m, Production(X, 0, 1, [Output(PX, 100)], [Input(PL, :(25 * $inputcoeff)), Input(PK, 50)]))
        add!(m, Production(Y, 0, :(0.5 * $elascoeff), [Output(PY, 50)], [Input(PL, 20), Input(PK, 30)]))
        add!(m, Production(U, 0, 1, [Output(PU, :(75 * $outputmult))], [Input(PX, 100), Input(PY, 50)]))

        add!(m, DemandFunction(RA, [Demand(PU,150)], [Endowment(PL, :(35 * $endow)), Endowment(PK, 80)]))

        avm = algebraic_version(m)
        @test typeof(avm) == MPSGE.AlgebraicWrapper

        solve!(m)

        MPSGEResults = XLSX.readxlsx("test\\MPSGEresults.xlsx")
        ATable = MPSGEResults[1][:]
        TwobyTwoScalarResults = DenseAxisArray(ATable[2:end,2:end],ATable[2:end,1], ATable[1,2:end])

        @test value(m, :X) ≈ 1.
        @test MPSGE.Complementarity.result_value(m._jump_model[:Y]) ≈ TwobyTwoScalarResults["Y.L","benchmark"]
        @test MPSGE.Complementarity.result_value(m._jump_model[:U]) ≈ 1.
        @test MPSGE.Complementarity.result_value(m._jump_model[:RA]) ≈ 150.

        @test MPSGE.Complementarity.result_value(m._jump_model[:PX]) ≈ 1.
        @test MPSGE.Complementarity.result_value(m._jump_model[:PY]) ≈ 1.
        @test MPSGE.Complementarity.result_value(m._jump_model[:PU]) ≈ 1.
        @test MPSGE.Complementarity.result_value(m._jump_model[:PL]) ≈ 1.
        @test MPSGE.Complementarity.result_value(m._jump_model[:PK]) ≈ 1.

        @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PL†X")]) ≈ 50.
        @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PL†Y")]) ≈ 20.
        @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PK†X")]) ≈ 50.
        @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PK†Y")]) ≈ 30.
        @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX†U")]) ≈ 100.
        @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PY†U")]) ≈ 50.

        avm2 = algebraic_version(m)
        @test typeof(avm2) == MPSGE.AlgebraicWrapper

        # For now just run these functions, we might add tests for the results
        # at a later point
        repr(MIME("text/plain"), m)
        repr(MIME("text/plain"), avm2)
        repr(MIME("text/latex"), avm2)

        set_fixed!(PX, true)
        set_value(endow, 2.2)
        solve!(m)

        @test value(m, :X) ≈ 1.04880885
        @test MPSGE.Complementarity.result_value(m._jump_model[:Y]) ≈ TwobyTwoScalarResults["Y.L","PX=1"]
        @test MPSGE.Complementarity.result_value(m._jump_model[:U]) ≈ 1.04548206
        @test MPSGE.Complementarity.result_value(m._jump_model[:RA]) ≈ 157.321327225523
        @test MPSGE.Complementarity.result_value(m._jump_model[:PX]) ≈ 1.0000000000
        @test MPSGE.Complementarity.result_value(m._jump_model[:PY]) ≈ 1.00957658
        @test MPSGE.Complementarity.result_value(m._jump_model[:PU]) ≈ 1.00318206
        @test MPSGE.Complementarity.result_value(m._jump_model[:PL]) ≈ 0.95346259
        @test MPSGE.Complementarity.result_value(m._jump_model[:PK]) ≈ 1.04880885
        @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PL†X")]) ≈ 52.4404424085075
        @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PL†Y")]) ≈ 21.1770570584356
        @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PK†X")]) ≈ 47.6731294622795
        @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PK†Y")]) ≈ 28.877805079685
        @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX†U")]) ≈ 100.318205802571
        @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PY†U")]) ≈ 49.6833066029729
    end

    @testset "TWOBYTWO (functional version copied, with non-1 elasticities of substitution in production)" begin
        m = Model()
# Here parameter values are doubled and input data halved from MPSGE version       
        inputcoeff = add!(m, Parameter(:inputcoeff, value=2.))
        endow = add!(m, Parameter(:endow, value=2.))
        elascoeff = add!(m, Parameter(:elascoeff, value=2.))
        outputmult = add!(m, Parameter(:outputmult, value=2.))
        
        X = add!(m, Sector(:X))
        Y = add!(m, Sector(:Y))
        U = add!(m, Sector(:U))

        PX = add!(m, Commodity(:PX))
        PY = add!(m, Commodity(:PY))
        PU = add!(m, Commodity(:PU))
        PL = add!(m, Commodity(:PL))
        PK = add!(m, Commodity(:PK))

        RA = add!(m, Consumer(:RA, benchmark=150.))

        add!(m, Production(X, 0, 0.5, [Output(PX, 100)], [Input(PL, :(25 * $inputcoeff)), Input(PK, 50)]))
        add!(m, Production(Y, 0, :(0.3 * $elascoeff), [Output(PY, 50)], [Input(PL, 20), Input(PK, 30)]))
        add!(m, Production(U, 0, 1, [Output(PU, :(75 * $outputmult))], [Input(PX, 100), Input(PY, 50)]))

        add!(m, DemandFunction(RA, [Demand(PU,150)], [Endowment(PL, :(35 * $endow)), Endowment(PK, 80)]))

        avm = algebraic_version(m)
        @test typeof(avm) == MPSGE.AlgebraicWrapper

        solve!(m)

        @test value(m, :X) ≈ 1.
        @test MPSGE.Complementarity.result_value(m._jump_model[:Y]) ≈ 1.
        @test MPSGE.Complementarity.result_value(m._jump_model[:U]) ≈ 1.
        @test MPSGE.Complementarity.result_value(m._jump_model[:RA]) ≈ 150.
        @test MPSGE.Complementarity.result_value(m._jump_model[:PX]) ≈ 1.
        @test MPSGE.Complementarity.result_value(m._jump_model[:PY]) ≈ 1.
        @test MPSGE.Complementarity.result_value(m._jump_model[:PU]) ≈ 1.
        @test MPSGE.Complementarity.result_value(m._jump_model[:PL]) ≈ 1.
        @test MPSGE.Complementarity.result_value(m._jump_model[:PK]) ≈ 1.
        @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PL†X")]) ≈ 50.
        @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PL†Y")]) ≈ 20.
        @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PK†X")]) ≈ 50.
        @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PK†Y")]) ≈ 30.
        @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX†U")]) ≈ 100.
        @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PY†U")]) ≈ 50.

        avm2 = algebraic_version(m)
        @test typeof(avm2) == MPSGE.AlgebraicWrapper

        # For now just run these functions, we might add tests for the results
        # at a later point
        repr(MIME("text/plain"), m)
        repr(MIME("text/plain"), avm2)
        repr(MIME("text/latex"), avm2)

        set_fixed!(PX, true)
        set_value(endow, 2.2)
        set_value(RA, 35. * get_value(endow) + 80.)
        solve!(m)

        @test value(m, :X) ≈ 1.05050654
        @test MPSGE.Complementarity.result_value(m._jump_model[:Y]) ≈ 1.03248042
        @test MPSGE.Complementarity.result_value(m._jump_model[:U]) ≈ 1.04446313
        @test MPSGE.Complementarity.result_value(m._jump_model[:RA]) ≈ 157.5759807
        @test MPSGE.Complementarity.result_value(m._jump_model[:PX]) ≈ 1.00000000
        @test MPSGE.Complementarity.result_value(m._jump_model[:PY]) ≈ 1.01745904
        @test MPSGE.Complementarity.result_value(m._jump_model[:PU]) ≈ 1.00578614
        @test MPSGE.Complementarity.result_value(m._jump_model[:PL]) ≈ 0.91316396
        @test MPSGE.Complementarity.result_value(m._jump_model[:PK]) ≈ 1.09077945
        @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PL†X")]) ≈ 52.32335975
        @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PL†Y")]) ≈ 21.34080999
        @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PK†X")]) ≈ 47.87420013
        @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PK†Y")]) ≈ 28.7732718
        @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX†U")]) ≈ 100.5786137
        @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PY†U")]) ≈ 49.42636977

    end

    @testset "TWOBYTWO (macro version)" begin
        m = Model()
# Here again, parameter values are doubled and input data halved from MPSGE version       
        inputcoeff = @parameter(m, inputcoeff, 2.)
        endow = @parameter(m, endow, 2.)
        elascoeff = @parameter(m, elascoeff, 2.)
        outputmult = @parameter(m, outputmult, 2.)

        
        @sector(m, X)
        @sector(m, Y)
        @sector(m, U)

        @commodity(m, PX)
        @commodity(m, PY)
        @commodity(m, PU)
        @commodity(m, PL)
        @commodity(m, PK)

        @consumer(m, RA, benchmark=150.)

        @production(m, X, 0, 1, [Output(PX, 100)], [Input(PL, :(25 * $inputcoeff)), Input(PK, 50)])
        @production(m, Y, 0, :(0.5 * $elascoeff), [Output(PY, 50)], [Input(PL, 20), Input(PK, 30)])
        @production(m, U, 0, 1, [Output(PU, :(75 * $outputmult))], [Input(PX, 100), Input(PY, 50)])

        @demand(m, RA, [Demand(PU, 150)], [Endowment(PL, :(35 * $endow)), Endowment(PK, 80)])

        avm = algebraic_version(m)
        @test typeof(avm) == MPSGE.AlgebraicWrapper

        solve!(m)

        @test value(m, :X) ≈ 1.
        @test MPSGE.Complementarity.result_value(m._jump_model[:Y]) ≈ 1.
        @test MPSGE.Complementarity.result_value(m._jump_model[:U]) ≈ 1.
        @test MPSGE.Complementarity.result_value(m._jump_model[:RA]) ≈ 150.

        @test MPSGE.Complementarity.result_value(m._jump_model[:PX]) ≈ 1.
        @test MPSGE.Complementarity.result_value(m._jump_model[:PY]) ≈ 1.
        @test MPSGE.Complementarity.result_value(m._jump_model[:PU]) ≈ 1.
        @test MPSGE.Complementarity.result_value(m._jump_model[:PL]) ≈ 1.
        @test MPSGE.Complementarity.result_value(m._jump_model[:PK]) ≈ 1.

        @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PL†X")]) ≈ 50.
        @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PL†Y")]) ≈ 20.
        @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PK†X")]) ≈ 50.
        @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PK†Y")]) ≈ 30.
        @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX†U")]) ≈ 100.
        @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PY†U")]) ≈ 50.

        avm2 = algebraic_version(m)
        @test typeof(avm2) == MPSGE.AlgebraicWrapper

        # For now just run these functions, we might add tests for the results
        # at a later point
        repr(MIME("text/plain"), m)
        repr(MIME("text/plain"), avm2)
        repr(MIME("text/latex"), avm2)

        set_fixed!(PX, true)
        set_value(endow, 2.2)
        solve!(m)

        @test value(m, :X) ≈ 1.04880885
        @test MPSGE.Complementarity.result_value(m._jump_model[:Y]) ≈ 1.03886012
        @test MPSGE.Complementarity.result_value(m._jump_model[:U]) ≈ 1.04548206
        @test MPSGE.Complementarity.result_value(m._jump_model[:RA]) ≈ 157.321327225523
        @test MPSGE.Complementarity.result_value(m._jump_model[:PX]) ≈ 1.0000000000
        @test MPSGE.Complementarity.result_value(m._jump_model[:PY]) ≈ 1.00957658
        @test MPSGE.Complementarity.result_value(m._jump_model[:PU]) ≈ 1.00318206
        @test MPSGE.Complementarity.result_value(m._jump_model[:PL]) ≈ 0.95346259
        @test MPSGE.Complementarity.result_value(m._jump_model[:PK]) ≈ 1.04880885
        @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PL†X")]) ≈ 52.4404424085075
        @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PL†Y")]) ≈ 21.1770570584356
        @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PK†X")]) ≈ 47.6731294622795
        @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PK†Y")]) ≈ 28.877805079685
        @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX†U")]) ≈ 100.318205802571
        @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PY†U")]) ≈ 49.6833066029729
    end
    
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
        @demand(m, RA, [Demand(PU, 150)], [Endowment(PF[:l], :(70 * $(endow[:l]))), Endowment(PF[:k], :(80. * $(endow[:k])))])

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

    @testset "JPMGE (Joint Production Intermediate Demand)" begin

        m = Model()
        goods = [:g1, :g2]
        factors = [:l, :k]
        sectors = [:s1, :s2]
        make0 = DenseAxisArray(Float64[6 2; 2 10], goods, sectors)
        use0 = DenseAxisArray(Float64[4 2; 2 6], goods, sectors)
        fd0 = DenseAxisArray(Float64[1 3; 1 1], factors, sectors)
        c0 = DenseAxisArray(Float64[2, 4], goods)
        e0 = DenseAxisArray(Float64[sum(fd0[f,:]) for f in factors], factors)
        endow = add!(m, Parameter(:endow, indices=(factors,), value=1.0)) 
        X = add!(m, Sector(:X, indices=(sectors,)))
        P = add!(m, Commodity(:P, indices=(goods,)))
        PF = add!(m, Commodity(:PF, indices=(factors,)))
        Y = add!(m, Consumer(:Y, benchmark=sum(fd0)))#example 4 has sum e0
        for j in sectors
            @production(m, X[j], 0, 1, [Output(P[i], make0[i,j]) for i in goods], [[Input(P[i], use0[i,j]) for i in goods]; [Input(PF[f], fd0[f,j]) for f in factors]])
        end

        @demand(m, Y, [Demand(P[i], c0[i]) for i in goods], [Endowment(PF[:k], :($(endow[:k]) * $(e0[:k]))), Endowment(PF[:l], :($(endow[:l]) * $(e0[:l])))])

        avm = algebraic_version(m)
        @test typeof(avm) == MPSGE.AlgebraicWrapper

        solve!(m)

        @test MPSGE.Complementarity.result_value(m._jump_model[:X][:s1]) ≈ 1.
        @test MPSGE.Complementarity.result_value(m._jump_model[:X][:s2]) ≈ 1.
        @test MPSGE.Complementarity.result_value(m._jump_model[:P][:g1]) ≈ 1.
        @test MPSGE.Complementarity.result_value(m._jump_model[:P][:g2]) ≈ 1.
        @test MPSGE.Complementarity.result_value(m._jump_model[:PF][:l]) ≈ 1.
        @test MPSGE.Complementarity.result_value(m._jump_model[:PF][:k]) ≈ 1.
        @test MPSGE.Complementarity.result_value(m._jump_model[:Y]) ≈ 6.
        @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("P[g1]‡X[s1]")]) ≈ 6.
        @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("P[g2]‡X[s1]")]) ≈ 2.
        @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("P[g1]‡X[s2]")]) ≈ 2.
        @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("P[g2]‡X[s2]")]) ≈10.
        @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("P[g1]†X[s1]")]) ≈ 4.
        @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("P[g2]†X[s1]")]) ≈ 2.
        @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PF[l]†X[s1]")]) ≈ 1.
        @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PF[k]†X[s1]")]) ≈ 1.
        @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("P[g1]†X[s2]")]) ≈ 2.
        @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("P[g2]†X[s2]")]) ≈ 6.
        @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PF[l]†X[s2]")]) ≈ 3.
        @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PF[k]†X[s2]")]) ≈ 1.
        @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("P[g1]ρY")]) ≈ 2.
        @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("P[g2]ρY")]) ≈ 4.
        

        #Counter-factual 1
        set_value(endow[:l], 1.1*get_value(endow[:l]))
        fd1 = fd0 .* convert(Vector, get_value.(endow))
        set_value(Y, sum(DenseAxisArray(Float64[sum(fd1[f,:]) for f in factors], factors)))
        set_fixed!(Y, true)

        solve!(m)
        @test MPSGE.Complementarity.result_value(m._jump_model[:X][:s1]) ≈ 0.99692562
        @test MPSGE.Complementarity.result_value(m._jump_model[:X][:s2]) ≈ 1.09975731
        @test MPSGE.Complementarity.result_value(m._jump_model[:P][:g1]) ≈ 1.01306317
        @test MPSGE.Complementarity.result_value(m._jump_model[:P][:g2]) ≈ 0.99467892
        @test MPSGE.Complementarity.result_value(m._jump_model[:PF][:l]) ≈ 0.97665932
        @test MPSGE.Complementarity.result_value(m._jump_model[:PF][:k]) ≈ 1.0513495
        @test MPSGE.Complementarity.result_value(m._jump_model[:Y]) ≈ 6.4   
        @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("P[g1]‡X[s1]")]) ≈ 6.0271570795595
        @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("P[g2]‡X[s1]")]) ≈ 1.97259368637181
        @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("P[g1]‡X[s2]")]) ≈ 2.03066186698742
        @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("P[g2]‡X[s2]")]) ≈ 9.96905522562002 #note - digits after 9.969 added from MPSGE.jl results bc GAMS not showing
        @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("P[g1]†X[s1]")]) ≈ 3.98197684247759
        @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("P[g2]†X[s1]")]) ≈ 2.02778707866119
        @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PF[l]†X[s1]")]) ≈ 1.03260012599366
        @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PF[k]†X[s1]")]) ≈ 0.959241925360056
        @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("P[g1]†X[s2]")]) ≈ 1.96980110341978
        @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("P[g2]†X[s2]")]) ≈ 6.018624497730061 #note - digits after 6.0186 added from MPSGE.jl results bc GAMS not showing
        @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PF[l]†X[s2]")]) ≈ 3.06483480444652
        @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PF[k]†X[s2]")]) ≈ 0.94903406
        @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("P[g1]ρY")]) ≈ 2.1058245831306
        @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("P[g2]ρY")]) ≈ 4.28949135539776

        set_fixed!(Y,false)

        set_fixed!(P[:g1], true)
        solve!(m)
        
        @test MPSGE.Complementarity.result_value(m._jump_model[:X][:s1]) ≈ 0.996925617439043 # not quite…0.99692552
        @test MPSGE.Complementarity.result_value(m._jump_model[:X][:s2]) ≈ 1.09975731474277 # not quite…1.09975733
        @test MPSGE.Complementarity.result_value(m._jump_model[:P][:g1]) ≈ 1
        @test MPSGE.Complementarity.result_value(m._jump_model[:P][:g2]) ≈ 0.981852806861767#note - digits after 0.9818528 added from MPSGE.jl results bc GAMS not showing
        @test MPSGE.Complementarity.result_value(m._jump_model[:PF][:l]) ≈ 0.964065561173485 # not quite…0.96406555
        @test MPSGE.Complementarity.result_value(m._jump_model[:PF][:k]) ≈ 1.0377926401152#note - digits after 1.0377926 added from MPSGE.jl results bc GAMS not showing
        @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("P[g1]‡X[s1]")]) ≈ 6.02715706941587#note - digits after 6.0272 added from MPSGE.jl results bc GAMS not showing
        @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("P[g2]‡X[s1]")]) ≈ 1.97259369533833#note - digits after 1.9726 added from MPSGE.jl results bc GAMS not showing
        @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("P[g1]‡X[s2]")]) ≈ 2.03066185804686#note - digits after 2.0307 added from MPSGE.jl results bc GAMS not showing
        @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("P[g2]‡X[s2]")]) ≈ 9.96905522562263#note - digits after 9.9691 added from MPSGE.jl results bc GAMS not showing
        @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("P[g1]†X[s1]")]) ≈ 3.98197686300985#note - digits after 3.982 added from MPSGE.jl results bc GAMS not showing
        @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("P[g2]†X[s1]")]) ≈ 2.02778707519236#note - digits after 2.0278 added from MPSGE.jl results bc GAMS not showing
        @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PF[l]†X[s1]")]) ≈ 1.0326001216173 # not quite…1.03260013
        @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PF[k]†X[s1]")]) ≈ 0.959241930675824#note - digits after 0.95924193 added from MPSGE.jl results bc GAMS not showing
        @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("P[g1]†X[s2]")]) ≈ 1.96980111885957#note - digits after 1.9698 added from MPSGE.jl results bc GAMS not showing
        @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("P[g2]†X[s2]")]) ≈ 6.01862449776752#note - digits after 6.0186 added from MPSGE.jl results bc GAMS not showing
        @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PF[l]†X[s2]")]) ≈ 3.06483479672782#note - digits after 3.0648348 added from MPSGE.jl results bc GAMS not showing
        @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PF[k]†X[s2]")]) ≈ 0.949034056851536#note - digits after 0.94903405 added from MPSGE.jl results bc GAMS not showing
        @test MPSGE.Complementarity.result_value(m._jump_model[:Y]) ≈ 6.31747374939373 # not quite…6.31747363
        @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("P[g1]ρY")]) ≈ 2.10582458313124 # not quite…2.10582454
        @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("P[g2]ρY")]) ≈ 4.28949139508602 # not quite…4.28949136
                     
        set_fixed!(P[:g1], false)
        set_fixed!(PF[:l], true)
        solve!(m)

        @test MPSGE.Complementarity.result_value(m._jump_model[:X][:s1]) ≈ 0.996925617406936# not quite…0.9969255
        @test MPSGE.Complementarity.result_value(m._jump_model[:X][:s2]) ≈ 1.09975731471521# not quite…1.09975741
        @test MPSGE.Complementarity.result_value(m._jump_model[:P][:g1]) ≈ 1.03727385383628# not quite…1.03727374
        @test MPSGE.Complementarity.result_value(m._jump_model[:P][:g2]) ≈ 1.01845024488441# not quite…1.01845009
        @test MPSGE.Complementarity.result_value(m._jump_model[:PF][:l]) ≈ 1
        @test MPSGE.Complementarity.result_value(m._jump_model[:PF][:k]) ≈ 1.07647517126301# not quite…1.07647514
        @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("P[g1]‡X[s1]")]) ≈ 6.02715706940364#note - digits after 6.0272 added from MPSGE.jl results bc GAMS not showing
        @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("P[g2]‡X[s1]")]) ≈ 1.97259369534545#note - digits after 1.9726 added from MPSGE.jl results bc GAMS not showing
        @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("P[g1]‡X[s2]")]) ≈ 2.03066185804338#note - digits after 2.0307 added from MPSGE.jl results bc GAMS not showing
        @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("P[g2]‡X[s2]")]) ≈ 9.96905522562005#note - digits after 9.9691 added from MPSGE.jl results bc GAMS not showing
        @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("P[g1]†X[s1]")]) ≈ 3.98197686299145#note - digits after 3.982 added from MPSGE.jl results bc GAMS not showing
        @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("P[g2]†X[s1]")]) ≈ 2.02778707517633#note - digits after 2.0278 added from MPSGE.jl results bc GAMS not showing
        @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PF[l]†X[s1]")]) ≈ 1.03260012164254# not quite…1.03260003
        @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PF[k]†X[s1]")]) ≈ 0.959241930707878# not quite…0.9592419
        @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("P[g1]†X[s2]")]) ≈ 1.96980111885675#note - digits after 1.9698 added from MPSGE.jl results bc GAMS not showing
        @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("P[g2]†X[s2]")]) ≈ 6.01862449771423#note - digits after 6.0186 added from MPSGE.jl results bc GAMS not showing
        @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PF[l]†X[s2]")]) ≈ 3.06483479678299# not quite…3.06483456
        @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PF[k]†X[s2]")]) ≈ 0.949034056889784# not quite…0.94903402
        @test MPSGE.Complementarity.result_value(m._jump_model[:Y]) ≈ 6.55295034252603# not quite…6.55295028
        @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("P[g1]ρY")]) ≈ 2.10582458311357# not quite…2.10582449
        @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("P[g2]ρY")]) ≈ 4.28949139501026# not quite…4.28949135
                                                         
    end
end