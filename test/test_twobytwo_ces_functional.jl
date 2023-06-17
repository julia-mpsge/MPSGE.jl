@testitem "TWOBYTWO (functional version copied, with non-1 elasticities of substitution in production)" begin
    using XLSX, MPSGE.JuMP.Containers
    
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

    add!(m, DemandFunction(RA, 1., [Demand(PU,150)], [Endowment(PL, :(35 * $endow)), Endowment(PK, 80)]))

    avm = algebraic_version(m)
    @test typeof(avm) == MPSGE.AlgebraicWrapper

    solve!(m)
    gams_results = XLSX.readxlsx(joinpath(@__DIR__, "MPSGEresults.xlsx"))
    a_table = gams_results["TwoxTwoCESProd"][:]  # Generated with TwoByTwo_wElas_Scalar_Algeb-MPSGE.gms
    two_by_two_CES = DenseAxisArray(a_table[2:end,2:end],a_table[2:end,1],a_table[1,2:end])


    @test value(m, :X) ≈  two_by_two_CES["X.L","benchmark"] # 1.
    @test MPSGE.Complementarity.result_value(m._jump_model[:Y]) ≈ two_by_two_CES["Y.L","benchmark"] # 1.
    @test MPSGE.Complementarity.result_value(m._jump_model[:U]) ≈ two_by_two_CES["U.L","benchmark"] # 1.
    @test MPSGE.Complementarity.result_value(m._jump_model[:RA]) ≈ two_by_two_CES["RA.L","benchmark"] # 150.
    @test MPSGE.Complementarity.result_value(m._jump_model[:PX]) ≈ two_by_two_CES["PX.L","benchmark"] # 1.
    @test MPSGE.Complementarity.result_value(m._jump_model[:PY]) ≈ two_by_two_CES["PY.L","benchmark"] # 1.
    @test MPSGE.Complementarity.result_value(m._jump_model[:PU]) ≈ two_by_two_CES["PU.L","benchmark"] # 1.
    @test MPSGE.Complementarity.result_value(m._jump_model[:PL]) ≈ two_by_two_CES["PL.L","benchmark"] # 1.
    @test MPSGE.Complementarity.result_value(m._jump_model[:PK]) ≈ two_by_two_CES["PK.L","benchmark"] # 1.
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PL†X")]) ≈ two_by_two_CES["LX.L","benchmark"] # 50.
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PL†Y")]) ≈ two_by_two_CES["LY.L","benchmark"] # 20.
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PK†X")]) ≈ two_by_two_CES["KX.L","benchmark"] # 50.
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PK†Y")]) ≈ two_by_two_CES["KY.L","benchmark"] # 30.
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX†U")]) ≈ two_by_two_CES["DX.L","benchmark"] # 100.
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PY†U")]) ≈ two_by_two_CES["DY.L","benchmark"] # 50.

    avm2 = algebraic_version(m)
    @test typeof(avm2) == MPSGE.AlgebraicWrapper

    # For now just run these functions, we might add tests for the results
    # at a later point
    repr(MIME("text/plain"), m)
    repr(MIME("text/plain"), avm2)
    repr(MIME("text/latex"), avm2)

    set_value(endow, 2.2)
    set_value(RA, 157.)
    set_fixed!(RA, true)
    solve!(m)

    @test value(m, :X) ≈ two_by_two_CES["X.L","RA=157"] # 1.05050654
    @test MPSGE.Complementarity.result_value(m._jump_model[:Y]) ≈ two_by_two_CES["Y.L","RA=157"] # 1.03248042
    @test MPSGE.Complementarity.result_value(m._jump_model[:U]) ≈ two_by_two_CES["U.L","RA=157"] # 1.04446313
    @test MPSGE.Complementarity.result_value(m._jump_model[:RA]) ≈ two_by_two_CES["RA.L","RA=157"] # 157.
    @test MPSGE.Complementarity.result_value(m._jump_model[:PX]) ≈ two_by_two_CES["PX.L","RA=157"] # 0.996344742
    @test MPSGE.Complementarity.result_value(m._jump_model[:PY]) ≈ two_by_two_CES["PY.L","RA=157"] # 1.013739967
    @test MPSGE.Complementarity.result_value(m._jump_model[:PU]) ≈ two_by_two_CES["PU.L","RA=157"] # 1.002109729
    @test MPSGE.Complementarity.result_value(m._jump_model[:PL]) ≈ two_by_two_CES["PL.L","RA=157"] # 0.90982611
    @test MPSGE.Complementarity.result_value(m._jump_model[:PK]) ≈ two_by_two_CES["PK.L","RA=157"] # 1.086792368
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PL†X")]) ≈ two_by_two_CES["LX.L","RA=157"] # 52.32335975
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PL†Y")]) ≈ two_by_two_CES["LY.L","RA=157"] # 21.34081
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PK†X")]) ≈ two_by_two_CES["KX.L","RA=157"] # 47.87420013
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PK†Y")]) ≈ two_by_two_CES["KY.L","RA=157"] # 28.7732718
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX†U")]) ≈ two_by_two_CES["DX.L","RA=157"] # 100.5786137
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PY†U")]) ≈ two_by_two_CES["DY.L","RA=157"] # 49.42636977

    set_fixed!(RA, false)
    set_fixed!(PX, true)
    # Just testing for bunctionality, not effecting the results
#Scalar Consumer
set_lower_bound(RA, 10e100)
set_lower_bound(RA, 0.)
set_upper_bound(RA, 0.)
set_upper_bound(RA, 10e100)
# Scalar Sector
set_lower_bound(Y, 1.)
set_lower_bound(Y, 0.)
set_upper_bound(Y, 1.)
set_upper_bound(Y, 10e100)
# Scalar Commodity
set_lower_bound(PY, 1.)
set_lower_bound(PY, 0.)
set_upper_bound(PY, 1.)
set_upper_bound(PY, 10e100)

solve!(m)

    @test value(m, :X) ≈ two_by_two_CES["X.L","PX=1"] # 1.05050654
    @test MPSGE.Complementarity.result_value(m._jump_model[:Y]) ≈ two_by_two_CES["Y.L","PX=1"] # 1.03248042
    @test MPSGE.Complementarity.result_value(m._jump_model[:U]) ≈ two_by_two_CES["U.L","PX=1"] # 1.0
    @test MPSGE.Complementarity.result_value(m._jump_model[:RA]) ≈ two_by_two_CES["RA.L","PX=1"] # 157.5759807
    @test MPSGE.Complementarity.result_value(m._jump_model[:PX]) ≈ two_by_two_CES["PX.L","PX=1"] # 1.0
    @test MPSGE.Complementarity.result_value(m._jump_model[:PY]) ≈ two_by_two_CES["PY.L","PX=1"] # 1.01745904
    @test MPSGE.Complementarity.result_value(m._jump_model[:PU]) ≈ two_by_two_CES["PU.L","PX=1"] # 1.00578614
    @test MPSGE.Complementarity.result_value(m._jump_model[:PL]) ≈ two_by_two_CES["PL.L","PX=1"] # 0.91316396
    @test MPSGE.Complementarity.result_value(m._jump_model[:PK]) ≈ two_by_two_CES["PK.L","PX=1"] # 1.09077945
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PL†X")]) ≈ two_by_two_CES["LX.L","PX=1"] # 52.32335975
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PL†Y")]) ≈ two_by_two_CES["LY.L","PX=1"] # 21.34080999
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PK†X")]) ≈ two_by_two_CES["KX.L","PX=1"] # 47.87420013
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PK†Y")]) ≈ two_by_two_CES["KY.L","PX=1"] # 28.7732718
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX†U")]) ≈ two_by_two_CES["DX.L","PX=1"] # 100.5786137
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PY†U")]) ≈ two_by_two_CES["DY.L","PX=1"] # 49.42636977

    set_fixed!(PX, false)
    set_fixed!(PL, true)
    solve!(m)

    @test value(m, :X) ≈ two_by_two_CES["X.L","PX=1"] # 1.05050654
    @test MPSGE.Complementarity.result_value(m._jump_model[:Y]) ≈ two_by_two_CES["Y.L","PL=1"] # 1.03248042
    @test MPSGE.Complementarity.result_value(m._jump_model[:U]) ≈ two_by_two_CES["U.L","PL=1"] # 1.0
    @test MPSGE.Complementarity.result_value(m._jump_model[:RA]) ≈ two_by_two_CES["RA.L","PL=1"] # 172.5604466
    @test MPSGE.Complementarity.result_value(m._jump_model[:PX]) ≈ two_by_two_CES["PX.L","PL=1"] # 1.095093591
    @test MPSGE.Complementarity.result_value(m._jump_model[:PY]) ≈ two_by_two_CES["PY.L","PL=1"] # 1.114212876
    @test MPSGE.Complementarity.result_value(m._jump_model[:PU]) ≈ two_by_two_CES["PU.L","PL=1"] # 1.101429952
    @test MPSGE.Complementarity.result_value(m._jump_model[:PL]) ≈ two_by_two_CES["PL.L","PL=1"] # 1.0
    @test MPSGE.Complementarity.result_value(m._jump_model[:PK]) ≈ two_by_two_CES["PK.L","PL=1"] # 1.194505582
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PL†X")]) ≈ two_by_two_CES["LX.L","PL=1"] # 52.32335975
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PL†Y")]) ≈ two_by_two_CES["LY.L","PL=1"] # 21.34080999
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PK†X")]) ≈ two_by_two_CES["KX.L","PL=1"] # 47.87420013
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PK†Y")]) ≈ two_by_two_CES["KY.L","PL=1"] # 28.7732718
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX†U")]) ≈ two_by_two_CES["DX.L","PL=1"] # 100.5786137
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PY†U")]) ≈ two_by_two_CES["DY.L","PL=1"] # 49.42636977

end
