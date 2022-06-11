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
