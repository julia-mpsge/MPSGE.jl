using MPSGE
using Test

@testset "MPSGE" begin

    m = Model()

    add!(m, Sector(:X, 1, 100, :L, 50, :K, 50))
    add!(m, Sector(:Y, 1, 50, :L, 20, :K, 30))
    add!(m, Sector(:U, 1, 150, :X, 100, :Y, 50))
    
    add!(m, Consumer(
        name=:RA,
        demand_name=:U,
        endowments=[Endowment(:L, 70), Endowment(:K, 80)])
    )
    
    solve!(m)

    @test MPSGE.Complementarity.result_value(m._jump_model[:X]) ≈ 1.
    @test MPSGE.Complementarity.result_value(m._jump_model[:Y]) ≈ 1.
    @test MPSGE.Complementarity.result_value(m._jump_model[:U]) ≈ 1.
    @test MPSGE.Complementarity.result_value(m._jump_model[:RA]) ≈ 150.

    @test MPSGE.Complementarity.result_value(m._jump_model[:PX]) ≈ 1.
    @test MPSGE.Complementarity.result_value(m._jump_model[:PY]) ≈ 1.
    @test MPSGE.Complementarity.result_value(m._jump_model[:PU]) ≈ 1.
    @test MPSGE.Complementarity.result_value(m._jump_model[:PL]) ≈ 1.
    @test MPSGE.Complementarity.result_value(m._jump_model[:PK]) ≈ 1.

    @test MPSGE.Complementarity.result_value(m._jump_model[:LX]) ≈ 50.
    @test MPSGE.Complementarity.result_value(m._jump_model[:LY]) ≈ 20.
    @test MPSGE.Complementarity.result_value(m._jump_model[:KX]) ≈ 50.
    @test MPSGE.Complementarity.result_value(m._jump_model[:KY]) ≈ 30.
    @test MPSGE.Complementarity.result_value(m._jump_model[:XU]) ≈ 100.
    @test MPSGE.Complementarity.result_value(m._jump_model[:YU]) ≈ 50.
    
end
