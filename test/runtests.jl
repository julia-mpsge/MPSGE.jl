using MPSGE
using Test

@testset "MPSGE" begin

    @testset "TWOBYTWO" begin
        m = Model()
       
        inputcoeff = add!(m, Parameter(:inputcoeff, 2.))
        endow = add!(m, Parameter(:endow, 2.))
        
        add!(m, Sector(:X))
        add!(m, Sector(:Y))
        add!(m, Sector(:U))

        add!(m, Commodity(:PX))
        add!(m, Commodity(:PY))
        add!(m, Commodity(:PU))
        add!(m, Commodity(:PL))
        add!(m, Commodity(:PK))

        add!(m, Consumer(:RA, benchmark=150.))

        add!(m, Production(:X, 1, :PX, 100, [Input(:PL, :(25 * $inputcoeff)), Input(:PK, 50)]))
        add!(m, Production(:Y, 1, :PY, 50, [Input(:PL, 20), Input(:PK, 30)]))
        add!(m, Production(:U, 1, :PU, 150, [Input(:PX, 100), Input(:PY, 50)]))

        add!(m, Demand(:RA, :PU, [Endowment(:PL, :(35 * $endow)), Endowment(:PK, 80)]))

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
