using MPSGE
using Test

@testset "MPSGE" begin

    @testset "TWOBYTWO (functional version)" begin
        m = Model()
       
        inputcoeff = add!(m, Parameter(:inputcoeff, 2.))
        endow = add!(m, Parameter(:endow, 2.))
        elascoeff = add!(m, Parameter(:elascoeff, 2.))
        outputmult = add!(m, Parameter(:outputmult, 2.))

        
        X = add!(m, Sector(:X))
        Y = add!(m, Sector(:Y))
        U = add!(m, Sector(:U))

        PX = add!(m, Commodity(:PX))
        PY = add!(m, Commodity(:PY))
        PU = add!(m, Commodity(:PU))
        PL = add!(m, Commodity(:PL))
        PK = add!(m, Commodity(:PK))

        RA = add!(m, Consumer(:RA, benchmark=150.))

        add!(m, Production(X, 1, PX, 100, [Input(PL, :(25 * $inputcoeff)), Input(PK, 50)]))
        add!(m, Production(Y, :(0.5 * $elascoeff), PY, 50, [Input(PL, 20), Input(PK, 30)]))
        add!(m, Production(U, 1, PU, :(75 * $outputmult), [Input(PX, 100), Input(PY, 50)]))

        add!(m, Demand(RA, PU, [Endowment(PL, :(35 * $endow)), Endowment(PK, 80)]))

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

        @test MPSGE.Complementarity.result_value(m._jump_model[:PLPX]) ≈ 50.
        @test MPSGE.Complementarity.result_value(m._jump_model[:PLPY]) ≈ 20.
        @test MPSGE.Complementarity.result_value(m._jump_model[:PKPX]) ≈ 50.
        @test MPSGE.Complementarity.result_value(m._jump_model[:PKPY]) ≈ 30.
        @test MPSGE.Complementarity.result_value(m._jump_model[:PXPU]) ≈ 100.
        @test MPSGE.Complementarity.result_value(m._jump_model[:PYPU]) ≈ 50.

        avm2 = algebraic_version(m)
        @test typeof(avm2) == MPSGE.AlgebraicWrapper

        # For now just run these functions, we might add tests for the results
        # at a later point
        repr(MIME("text/plain"), m)
        repr(MIME("text/plain"), avm2)
        repr(MIME("text/latex"), avm2)
    end

    @testset "TWOBYTWO (macro version)" begin
        m = Model()
       
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

        @production(m, X, 1, PX, 100, [Input(PL, :(25 * $inputcoeff)), Input(PK, 50)])
        @production(m, Y, :(0.5 * $elascoeff), PY, 50, [Input(PL, 20), Input(PK, 30)])
        @production(m, U, 1, PU, :(75 * $outputmult), [Input(PX, 100), Input(PY, 50)])

        @demand(m, RA, PU, [Endowment(PL, :(35 * $endow)), Endowment(PK, 80)])

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

        @test MPSGE.Complementarity.result_value(m._jump_model[:PLPX]) ≈ 50.
        @test MPSGE.Complementarity.result_value(m._jump_model[:PLPY]) ≈ 20.
        @test MPSGE.Complementarity.result_value(m._jump_model[:PKPX]) ≈ 50.
        @test MPSGE.Complementarity.result_value(m._jump_model[:PKPY]) ≈ 30.
        @test MPSGE.Complementarity.result_value(m._jump_model[:PXPU]) ≈ 100.
        @test MPSGE.Complementarity.result_value(m._jump_model[:PYPU]) ≈ 50.

        avm2 = algebraic_version(m)
        @test typeof(avm2) == MPSGE.AlgebraicWrapper

        # For now just run these functions, we might add tests for the results
        # at a later point
        repr(MIME("text/plain"), m)
        repr(MIME("text/plain"), avm2)
        repr(MIME("text/latex"), avm2)
    end
    
end
