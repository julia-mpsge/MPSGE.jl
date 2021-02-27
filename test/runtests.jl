using MPSGE
using Test

@testset "MPSGE" begin

    m = Model()

    add!(m, Sector(:X))
    add!(m, Sector(:Y))
    add!(m, Sector(:U))

    add!(m, Commodity(:PX))
    add!(m, Commodity(:PY))
    add!(m, Commodity(:PU))
    add!(m, Commodity(:PL))
    add!(m, Commodity(:PK))

    add!(m, Consumer(:RA, benchmark=150.))

    add!(m, Production(:X, 1, :PX, 100, [Input(:PL, 50), Input(:PK, 50)]))
    add!(m, Production(:Y, 1, :PY, 50, [Input(:PL, 20), Input(:PK, 30)]))
    add!(m, Production(:U, 1, :PU, 150, [Input(:PX, 100), Input(:PY, 50)]))

    add!(m, Demand(:RA, :PU, [Endowment(:PL, 70), Endowment(:PK, 80)]))
    
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
    
end
