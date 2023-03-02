@testitem "TWOBYTWO (macro version)" begin
    using XLSX, MPSGE.JuMP.Containers
    
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

    @demand(m, RA, 1., [Demand(PU, 150)], [Endowment(PL, :(35 * $endow)), Endowment(PK, 80)])

    avm = algebraic_version(m)
    @test typeof(avm) == MPSGE.AlgebraicWrapper

    solve!(m)

    gams_results = XLSX.readxlsx(joinpath(@__DIR__, "MPSGEresults.xlsx"))
    a_table = gams_results["TwoxTwoScalar"][:]  # Generated from TwoByTwo_Scalar_Algeb-MPSGE.gms
    two_by_two_scalar_results = DenseAxisArray(a_table[2:end,2:end],a_table[2:end,1],a_table[1,2:end])

    @test value(m, :X) ≈ two_by_two_scalar_results["X.L","benchmark"]#    1.
    @test MPSGE.Complementarity.result_value(m._jump_model[:Y]) ≈ two_by_two_scalar_results["Y.L","benchmark"]#    1.
    @test MPSGE.Complementarity.result_value(m._jump_model[:U]) ≈ two_by_two_scalar_results["U.L","benchmark"]#    1.
    @test MPSGE.Complementarity.result_value(m._jump_model[:RA]) ≈ two_by_two_scalar_results["RA.L","benchmark"]#    150.
    @test MPSGE.Complementarity.result_value(m._jump_model[:PX]) ≈ two_by_two_scalar_results["PX.L","benchmark"]#    1.
    @test MPSGE.Complementarity.result_value(m._jump_model[:PY]) ≈ two_by_two_scalar_results["PY.L","benchmark"]#    1.
    @test MPSGE.Complementarity.result_value(m._jump_model[:PU]) ≈ two_by_two_scalar_results["PU.L","benchmark"]#    1.
    @test MPSGE.Complementarity.result_value(m._jump_model[:PL]) ≈ two_by_two_scalar_results["PL.L","benchmark"]#    1.
    @test MPSGE.Complementarity.result_value(m._jump_model[:PK]) ≈ two_by_two_scalar_results["PK.L","benchmark"]#    1.
# Implicit Variables
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PL†X")]) ≈ two_by_two_scalar_results["LX.L","benchmark"]#    50.
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PL†Y")]) ≈ two_by_two_scalar_results["LY.L","benchmark"]#    20.
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PK†X")]) ≈ two_by_two_scalar_results["KX.L","benchmark"]#    50.
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PK†Y")]) ≈ two_by_two_scalar_results["KY.L","benchmark"]#    30.
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX†U")]) ≈ two_by_two_scalar_results["DX.L","benchmark"]#    100.
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PY†U")]) ≈ two_by_two_scalar_results["DY.L","benchmark"]#    50.

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

    @test value(m, :X) ≈ two_by_two_scalar_results["X.L","PX=1"]#    1.04880885
    @test MPSGE.Complementarity.result_value(m._jump_model[:Y]) ≈ two_by_two_scalar_results["Y.L","PX=1"]
    @test MPSGE.Complementarity.result_value(m._jump_model[:U]) ≈ two_by_two_scalar_results["U.L","PX=1"]#    1.04548206
    @test MPSGE.Complementarity.result_value(m._jump_model[:RA]) ≈ two_by_two_scalar_results["RA.L","PX=1"]#    157.321327225523
    @test MPSGE.Complementarity.result_value(m._jump_model[:PX]) ≈ two_by_two_scalar_results["PX.L","PX=1"]#    1.0000000000
    @test MPSGE.Complementarity.result_value(m._jump_model[:PY]) ≈ two_by_two_scalar_results["PY.L","PX=1"]#    1.00957658
    @test MPSGE.Complementarity.result_value(m._jump_model[:PU]) ≈ two_by_two_scalar_results["PU.L","PX=1"]#    1.00318206
    @test MPSGE.Complementarity.result_value(m._jump_model[:PL]) ≈ two_by_two_scalar_results["PL.L","PX=1"]#    0.95346259
    @test MPSGE.Complementarity.result_value(m._jump_model[:PK]) ≈ two_by_two_scalar_results["PK.L","PX=1"]#    1.04880885
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PL†X")]) ≈ two_by_two_scalar_results["LX.L","PX=1"]#    52.4404424085075
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PL†Y")]) ≈ two_by_two_scalar_results["LY.L","PX=1"]#    21.1770570584356
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PK†X")]) ≈ two_by_two_scalar_results["KX.L","PX=1"]#    47.6731294622795
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PK†Y")]) ≈ two_by_two_scalar_results["KY.L","PX=1"]#    28.877805079685
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX†U")]) ≈ two_by_two_scalar_results["DX.L","PX=1"]#    100.318205802571
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PY†U")]) ≈ two_by_two_scalar_results["DY.L","PX=1"]#    49.6833066029729
    
    set_fixed!(PX, false)
    set_fixed!(PL, true)
    solve!(m)

    @test value(m, :X) ≈ two_by_two_scalar_results["X.L","PX=1"]#    1.04880885
    @test MPSGE.Complementarity.result_value(m._jump_model[:Y]) ≈ two_by_two_scalar_results["Y.L","PL=1"]#    1.038860118
    @test MPSGE.Complementarity.result_value(m._jump_model[:U]) ≈ two_by_two_scalar_results["U.L","PL=1"]#    1.04548206
    @test MPSGE.Complementarity.result_value(m._jump_model[:RA]) ≈ two_by_two_scalar_results["RA.L","PL=1"]#    165
    @test MPSGE.Complementarity.result_value(m._jump_model[:PX]) ≈ two_by_two_scalar_results["PX.L","PL=1"]#    1.048808848
    @test MPSGE.Complementarity.result_value(m._jump_model[:PY]) ≈ two_by_two_scalar_results["PY.L","PL=1"]#    1.058852853
    @test MPSGE.Complementarity.result_value(m._jump_model[:PU]) ≈ two_by_two_scalar_results["PU.L","PL=1"]#    1.052146219
    @test MPSGE.Complementarity.result_value(m._jump_model[:PL]) ≈ two_by_two_scalar_results["PL.L","PL=1"]#    1.0
    @test MPSGE.Complementarity.result_value(m._jump_model[:PK]) ≈ two_by_two_scalar_results["PK.L","PL=1"]#    1.1
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PL†X")]) ≈ two_by_two_scalar_results["LX.L","PL=1"]#    52.4404424085075
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PL†Y")]) ≈ two_by_two_scalar_results["LY.L","PL=1"]#    21.1770570584356
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PK†X")]) ≈ two_by_two_scalar_results["KX.L","PL=1"]#    47.6731294622795
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PK†Y")]) ≈ two_by_two_scalar_results["KY.L","PL=1"]#    28.877805079685
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX†U")]) ≈ two_by_two_scalar_results["DX.L","PL=1"]#    100.318205802571
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PY†U")]) ≈ two_by_two_scalar_results["DY.L","PL=1"]#    49.6833066029729

end

@testitem "TWOBYTWO with Transformation Elasticities (macro version)" begin
    using XLSX, MPSGE.JuMP.Containers

    m = Model()

    @parameter(m, diff, 0.0)
    @parameter(m, sub_elas_a, 1.)
    @parameter(m, sub_elas_b, 1.)
    @parameter(m, sub_elas_w, 1.)
    @parameter(m, t_elas_a, 0.0)
    @parameter(m, t_elas_b, 0.0)

    @sector(m, A)
    @sector(m, B)
    @sector(m, W)

    @commodity(m, PX)
    @commodity(m, PY)
    @commodity(m, PW)
    @commodity(m, PL)
    @commodity(m, PK)

    @consumer(m, CONS, benchmark=200.0)

    # @production(m, A, 0, 1, [Output(PX, 80),          Output(PY, 20)], [Input(PL, 40), Input(PK, 60)])
    @production(m, A, :($t_elas_a*1.), :($sub_elas_a*1.), [Output(PX, 80),          Output(PY, 20)], [Input(PL, 40), Input(PK, 60)])
    # @production(m, B, 0, 1, [Output(PX, 20), Output(PY, 80)], [Input(PL, 60), Input(PK, 40)])
    # @production(m, B, :($t_elas_b*1.), 1, [Output(PX, 20), Output(PY, 80)], [Input(PL, 60), Input(PK, 40)])
    @production(m, B, :($t_elas_b*1.), :($sub_elas_b*1.), [Output(PX, :(20+$diff)), Output(PY, 80)], [Input(PL, 60), Input(PK, 40)])
    @production(m, W, 0, :($sub_elas_w*1.), [Output(PW, 200.0)],[Input(PX, :(100.0+$diff)), Input(PY, 100.0)])
    # @production(m, W, 0, 1, [Output(PW, 200.0)], [Input(PX, 100.0), Input(PY, 100.0)])
    # @production(m, W, 0.,1, [Output(PW, :(200.0+$diff))], [Input(PX, :(100.0+$diff)), Input(PY, 100.0)])

    @demand(m, CONS, 1., [Demand(PW, 200.)], [Endowment(PL, 100.0), Endowment(PK, 100.0)])

    solve!(m, cumulative_iteration_limit=0)
    algebraic_version(m)

    gams_results = XLSX.readxlsx(joinpath(@__DIR__, "MPSGEresults.xlsx"))
    a_table = gams_results["TwoxTwoCET-Scalar"][:]  # Generated from TwoByTwo_Scalar_MPSGE_forCETTests.gms
    two_by_two_scalar_results = DenseAxisArray(a_table[2:end,2:end],a_table[2:end,1],a_table[1,2:end])

    @test value(m, :A) ≈ two_by_two_scalar_results["A.L","benchmark"]#    1.
    @test MPSGE.Complementarity.result_value(m._jump_model[:B]) ≈ two_by_two_scalar_results["B.L","benchmark"]#    1.
    @test MPSGE.Complementarity.result_value(m._jump_model[:W]) ≈ two_by_two_scalar_results["W.L","benchmark"]#    1.
    @test MPSGE.Complementarity.result_value(m._jump_model[:CONS]) ≈ two_by_two_scalar_results["CONS.L","benchmark"]#    200.
    @test MPSGE.Complementarity.result_value(m._jump_model[:PX]) ≈ two_by_two_scalar_results["PX.L","benchmark"]#    1.
    @test MPSGE.Complementarity.result_value(m._jump_model[:PY]) ≈ two_by_two_scalar_results["PY.L","benchmark"]#    1.
    @test MPSGE.Complementarity.result_value(m._jump_model[:PW]) ≈ two_by_two_scalar_results["PW.L","benchmark"]#    1.
    @test MPSGE.Complementarity.result_value(m._jump_model[:PL]) ≈ two_by_two_scalar_results["PL.L","benchmark"]#    1.
    @test MPSGE.Complementarity.result_value(m._jump_model[:PK]) ≈ two_by_two_scalar_results["PK.L","benchmark"]#    1.
    # Implicit Variables
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PL†A")]) ≈ two_by_two_scalar_results["DAL.L","benchmark"]#    40.
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PL†B")]) ≈ two_by_two_scalar_results["DBL.L","benchmark"]#    60.
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PK†A")]) ≈ two_by_two_scalar_results["DAK.L","benchmark"]#    60.
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PK†B")]) ≈ two_by_two_scalar_results["DBK.L","benchmark"]#    40.
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX†W")]) ≈ two_by_two_scalar_results["DWX.L","benchmark"]#    100.
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PY†W")]) ≈ two_by_two_scalar_results["DWY.L","benchmark"]#    100.
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX‡A")]) ≈ two_by_two_scalar_results["SAX.L","benchmark"]#    40.
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PY‡A")]) ≈ two_by_two_scalar_results["SAY.L","benchmark"]#    60.
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX‡B")]) ≈ two_by_two_scalar_results["SBX.L","benchmark"]#    60.
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PY‡B")]) ≈ two_by_two_scalar_results["SBY.L","benchmark"]#    40.
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PW‡W")]) ≈ two_by_two_scalar_results["SW.L","benchmark"]#    100.
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PWρCONS")]) ≈ two_by_two_scalar_results["DW.L","benchmark"]#    100.

    set_value(diff, 10.0)
    # set_value(CONS, 200.0)
    set_fixed!(CONS, true)
    solve!(m)

    @test value(m, :A) ≈ two_by_two_scalar_results["A.L","diff=10"] # 0.84841618
    @test MPSGE.Complementarity.result_value(m._jump_model[:B]) ≈ two_by_two_scalar_results["B.L","diff=10"]#1.1506325096039884
    @test MPSGE.Complementarity.result_value(m._jump_model[:W]) ≈ two_by_two_scalar_results["W.L","diff=10"]#1.0035850931326258
    @test MPSGE.Complementarity.result_value(m._jump_model[:CONS]) ≈ two_by_two_scalar_results["CONS.L","diff=10"]#    200.
    @test MPSGE.Complementarity.result_value(m._jump_model[:PX]) ≈ two_by_two_scalar_results["PX.L","diff=10"]# 1.0231427182799986
    @test MPSGE.Complementarity.result_value(m._jump_model[:PY]) ≈ two_by_two_scalar_results["PY.L","diff=10"]# 0.8735923221649244
    @test MPSGE.Complementarity.result_value(m._jump_model[:PW]) ≈ two_by_two_scalar_results["PW.L","diff=10"]# 0.99642771
    @test MPSGE.Complementarity.result_value(m._jump_model[:PL]) ≈ two_by_two_scalar_results["PL.L","diff=10"]# 1.03146507
    @test MPSGE.Complementarity.result_value(m._jump_model[:PK]) ≈ two_by_two_scalar_results["PK.L","diff=10"]# 0.96853493
    # Implicit Variables
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PL†A")]) ≈ two_by_two_scalar_results["DAL.L","diff=10"]# 38.51735423
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PL†B")]) ≈ two_by_two_scalar_results["DBL.L","diff=10"]# 58.50804067
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PK†A")]) ≈ two_by_two_scalar_results["DAK.L","diff=10"]# 61.5300044
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PK†B")]) ≈ two_by_two_scalar_results["DBK.L","diff=10"]# 41.53971715
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX†W")]) ≈ two_by_two_scalar_results["DWX.L","diff=10"]# 102.026494817672
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PY†W")]) ≈ two_by_two_scalar_results["DWY.L","diff=10"]# 108.629477488623
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX‡A")]) ≈ two_by_two_scalar_results["SAX.L","diff=10"]#80.00000000000001
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PY‡A")]) ≈ two_by_two_scalar_results["SAY.L","diff=10"]#20.000000000000004
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX‡B")]) ≈ two_by_two_scalar_results["SBX.L","diff=10"]# 30.00000000
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PY‡B")]) ≈ two_by_two_scalar_results["SBY.L","diff=10"]# 80.00000000
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PW‡W")]) ≈ two_by_two_scalar_results["SW.L","diff=10"]# 200
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PWρCONS")]) ≈ two_by_two_scalar_results["DW.L","diff=10"]# 200.7170

    # set_value(PW, 1.0)
    set_fixed!(PW, true)
    # set_fixed!(CONS, false)
    solve!(m)

    @test MPSGE.Complementarity.result_value(m._jump_model[:A]) ≈ two_by_two_scalar_results["A.L","PW.FX=1"]#  0.84841618
    @test MPSGE.Complementarity.result_value(m._jump_model[:B]) ≈ two_by_two_scalar_results["B.L","PW.FX=1"]#  1.15063251
    @test MPSGE.Complementarity.result_value(m._jump_model[:W]) ≈ two_by_two_scalar_results["W.L","PW.FX=1"]#  1.00358509
    @test MPSGE.Complementarity.result_value(m._jump_model[:PX]) ≈ two_by_two_scalar_results["PX.L","PW.FX=1"]#  1.02681078
    @test MPSGE.Complementarity.result_value(m._jump_model[:PY]) ≈ two_by_two_scalar_results["PY.L","PW.FX=1"]#  0.87672423
    @test MPSGE.Complementarity.result_value(m._jump_model[:PW]) ≈ two_by_two_scalar_results["PW.L","PW.FX=1"]#  1
    @test MPSGE.Complementarity.result_value(m._jump_model[:PL]) ≈ two_by_two_scalar_results["PL.L","PW.FX=1"]#  1.03516297
    @test MPSGE.Complementarity.result_value(m._jump_model[:PK]) ≈ two_by_two_scalar_results["PK.L","PW.FX=1"]#  0.97200722
    @test MPSGE.Complementarity.result_value(m._jump_model[:CONS]) ≈ two_by_two_scalar_results["CONS.L","PW.FX=1"]#  200
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX‡A")]) ≈ two_by_two_scalar_results["SAX.L","PW.FX=1"]#  80
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PY‡A")]) ≈ two_by_two_scalar_results["SAY.L","PW.FX=1"]#  20
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX‡B")]) ≈ two_by_two_scalar_results["SBX.L","PW.FX=1"]#  30
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PY‡B")]) ≈ two_by_two_scalar_results["SBY.L","PW.FX=1"]#  80
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PL†A")]) ≈ two_by_two_scalar_results["DAL.L","PW.FX=1"]#  38.51735422
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PK†A")]) ≈ two_by_two_scalar_results["DAK.L","PW.FX=1"]#  61.53000441
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PL†B")]) ≈ two_by_two_scalar_results["DBL.L","PW.FX=1"]#  58.50804066
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PK†B")]) ≈ two_by_two_scalar_results["DBK.L","PW.FX=1"]#  41.53971716
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PW‡W")]) ≈ two_by_two_scalar_results["SW.L","PW.FX=1"]#  200
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX†W")]) ≈ two_by_two_scalar_results["DWX.L","PW.FX=1"]#  102.0265
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PY†W")]) ≈ two_by_two_scalar_results["DWY.L","PW.FX=1"]#  108.6295
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PWρCONS")]) ≈ two_by_two_scalar_results["DW.L","PW.FX=1"]#  200
    # CWI ")]) ≈ two_by_two_scalar_results["CWI.L","PW.FX=1"]#  1

    set_value(t_elas_a, 2.0)
    set_value(t_elas_b, 1.5)
    set_fixed!(CONS, true)
    solve!(m)

    @test MPSGE.Complementarity.result_value(m._jump_model[:A]) ≈ two_by_two_scalar_results["A.L","TA=2B=1.5"]#  0.70716516
    @test MPSGE.Complementarity.result_value(m._jump_model[:B]) ≈ two_by_two_scalar_results["B.L","TA=2B=1.5"]#  1.28930597
    @test MPSGE.Complementarity.result_value(m._jump_model[:W]) ≈ two_by_two_scalar_results["W.L","TA=2B=1.5"]#  1.0068915
    @test MPSGE.Complementarity.result_value(m._jump_model[:PX]) ≈ two_by_two_scalar_results["PX.L","TA=2B=1.5"]#  1.01618551
    @test MPSGE.Complementarity.result_value(m._jump_model[:PY]) ≈ two_by_two_scalar_results["PY.L","TA=2B=1.5"]#  0.88681326
    @test MPSGE.Complementarity.result_value(m._jump_model[:PW]) ≈ two_by_two_scalar_results["PW.L","TA=2B=1.5"]#  1
    @test MPSGE.Complementarity.result_value(m._jump_model[:PL]) ≈ two_by_two_scalar_results["PL.L","TA=2B=1.5"]#  1.06783563
    @test MPSGE.Complementarity.result_value(m._jump_model[:PK]) ≈ two_by_two_scalar_results["PK.L","TA=2B=1.5"]#  0.94594737
    @test MPSGE.Complementarity.result_value(m._jump_model[:CONS]) ≈ two_by_two_scalar_results["CONS.L","TA=2B=1.5"]#  200
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX‡A")]) ≈ two_by_two_scalar_results["SAX.L","TA=2B=1.5"]#  83.78997942
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PY‡A")]) ≈ two_by_two_scalar_results["SAY.L","TA=2B=1.5"]#  15.9532971
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX‡B")]) ≈ two_by_two_scalar_results["SBX.L","TA=2B=1.5"]#  34.5537849
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PY‡B")]) ≈ two_by_two_scalar_results["SBY.L","TA=2B=1.5"]#  75.11957607
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PL†A")]) ≈ two_by_two_scalar_results["DAL.L","TA=2B=1.5"]#  37.19439785
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PK†A")]) ≈ two_by_two_scalar_results["DAK.L","TA=2B=1.5"]#  62.98051725
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PL†B")]) ≈ two_by_two_scalar_results["DBL.L","TA=2B=1.5"]#  57.16053403
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PK†B")]) ≈ two_by_two_scalar_results["DBK.L","TA=2B=1.5"]#  43.01723089
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PW‡W")]) ≈ two_by_two_scalar_results["SW.L","TA=2B=1.5"]#  200
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX†W")]) ≈ two_by_two_scalar_results["DWX.L","TA=2B=1.5"]#  103.0933
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PY†W")]) ≈ two_by_two_scalar_results["DWY.L","TA=2B=1.5"]#  107.3936
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PWρCONS")]) ≈ two_by_two_scalar_results["DW.L","TA=2B=1.5"]#  200
    # CWI ")]) ≈ two_by_two_scalar_results["CWI.L","TA=2B=1.5"]#  1

    set_value(t_elas_a, 3.0)
    set_value(t_elas_b, 1.0)
    solve!(m)

    @test MPSGE.Complementarity.result_value(m._jump_model[:A]) ≈ two_by_two_scalar_results["A.L","TrA=3B=1"]#  0.72509467
    @test MPSGE.Complementarity.result_value(m._jump_model[:B]) ≈ two_by_two_scalar_results["B.L","TrA=3B=1"]#  1.27179295
    @test MPSGE.Complementarity.result_value(m._jump_model[:W]) ≈ two_by_two_scalar_results["W.L","TrA=3B=1"]#  1.0066737
    @test MPSGE.Complementarity.result_value(m._jump_model[:PX]) ≈ two_by_two_scalar_results["PX.L","TrA=3B=1"]#  1.01553137
    @test MPSGE.Complementarity.result_value(m._jump_model[:PY]) ≈ two_by_two_scalar_results["PY.L","TrA=3B=1"]#  0.88744163
    @test MPSGE.Complementarity.result_value(m._jump_model[:PW]) ≈ two_by_two_scalar_results["PW.L","TrA=3B=1"]#  1
    @test MPSGE.Complementarity.result_value(m._jump_model[:PL]) ≈ two_by_two_scalar_results["PL.L","TrA=3B=1"]#  1.06390753
    @test MPSGE.Complementarity.result_value(m._jump_model[:PK]) ≈ two_by_two_scalar_results["PK.L","TrA=3B=1"]#  0.94943988
    @test MPSGE.Complementarity.result_value(m._jump_model[:CONS]) ≈ two_by_two_scalar_results["CONS.L","TrA=3B=1"]#  200
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX‡A")]) ≈ two_by_two_scalar_results["SAX.L","TrA=3B=1"]#  85.39725456
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PY‡A")]) ≈ two_by_two_scalar_results["SAY.L","TrA=3B=1"]#  14.24699517
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX‡B")]) ≈ two_by_two_scalar_results["SBX.L","TrA=3B=1"]#  32.96688891
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PY‡B")]) ≈ two_by_two_scalar_results["SBY.L","TrA=3B=1"]#  76.82333387
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PL†A")]) ≈ two_by_two_scalar_results["DAL.L","TrA=3B=1"]#  37.35924957
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PK†A")]) ≈ two_by_two_scalar_results["DAK.L","TrA=3B=1"]#  62.79510852
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PL†B")]) ≈ two_by_two_scalar_results["DBL.L","TrA=3B=1"]#  57.32930614
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PK†B")]) ≈ two_by_two_scalar_results["DBK.L","TrA=3B=1"]#  42.82741272
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PW‡W")]) ≈ two_by_two_scalar_results["SW.L","TrA=3B=1"]#  200
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX†W")]) ≈ two_by_two_scalar_results["DWX.L","TrA=3B=1"]#  103.1597
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PY†W")]) ≈ two_by_two_scalar_results["DWY.L","TrA=3B=1"]#  107.3176
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PWρCONS")]) ≈ two_by_two_scalar_results["DW.L","TrA=3B=1"]#  200
    # CWI ")]) ≈ two_by_two_scalar_results["CWI.L","TrA=3B=1"]#  1

    set_value(t_elas_a, 1.0)
    set_value(t_elas_b, 1.0)
    solve!(m)

    @test MPSGE.Complementarity.result_value(m._jump_model[:A]) ≈ two_by_two_scalar_results["A.L","TrA/B=1"]#  0.75612889
    @test MPSGE.Complementarity.result_value(m._jump_model[:B]) ≈ two_by_two_scalar_results["B.L","TrA/B=1"]#  1.24141851
    @test MPSGE.Complementarity.result_value(m._jump_model[:W]) ≈ two_by_two_scalar_results["W.L","TrA/B=1"]#  1.00571358
    @test MPSGE.Complementarity.result_value(m._jump_model[:PX]) ≈ two_by_two_scalar_results["PX.L","TrA/B=1"]#  1.02029254
    @test MPSGE.Complementarity.result_value(m._jump_model[:PY]) ≈ two_by_two_scalar_results["PY.L","TrA/B=1"]#  0.88288734
    @test MPSGE.Complementarity.result_value(m._jump_model[:PW]) ≈ two_by_two_scalar_results["PW.L","TrA/B=1"]#  1
    @test MPSGE.Complementarity.result_value(m._jump_model[:PL]) ≈ two_by_two_scalar_results["PL.L","TrA/B=1"]#  1.05648771
    @test MPSGE.Complementarity.result_value(m._jump_model[:PK]) ≈ two_by_two_scalar_results["PK.L","TrA/B=1"]#  0.95493944
    @test MPSGE.Complementarity.result_value(m._jump_model[:CONS]) ≈ two_by_two_scalar_results["CONS.L","TrA/B=1"]#  200
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX‡A")]) ≈ two_by_two_scalar_results["SAX.L","TrA/B=1"]#  82.0887076
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PY‡A")]) ≈ two_by_two_scalar_results["SAY.L","TrA/B=1"]#  17.75840706
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX‡B")]) ≈ two_by_two_scalar_results["SBX.L","TrA/B=1"]#  33.18406977
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PY‡B")]) ≈ two_by_two_scalar_results["SBY.L","TrA/B=1"]#  76.57358141
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PL†A")]) ≈ two_by_two_scalar_results["DAL.L","TrA/B=1"]#  37.64669204
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PK†A")]) ≈ two_by_two_scalar_results["DAK.L","TrA/B=1"]#  62.47506218
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PL†B")]) ≈ two_by_two_scalar_results["DBL.L","TrA/B=1"]#  57.62299187
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PK†B")]) ≈ two_by_two_scalar_results["DBK.L","TrA/B=1"]#  42.50041407
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PW‡W")]) ≈ two_by_two_scalar_results["SW.L","TrA/B=1"]#  200
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX†W")]) ≈ two_by_two_scalar_results["DWX.L","TrA/B=1"]#  102.6783
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PY†W")]) ≈ two_by_two_scalar_results["DWY.L","TrA/B=1"]#  107.8712
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PWρCONS")]) ≈ two_by_two_scalar_results["DW.L","TrA/B=1"]#  200
    # CWI ")]) ≈ two_by_two_scalar_results["CWI.L","TrA/B=1"]#  1

    # Re-set with Leontief/Complement Substitution Elasticities

    "NOTE!! When GAMS version with s:0 for all 3 sectors is not run !FIRST!, these results don't all match. That is, if other sub elasticites were run first,
    and then changed to s:0, GAMS MPSGE gets different results than it does if it starts at s:0. MPSGE.jl does not change results based on the order."

    set_value(diff, 0.0)
    set_value(sub_elas_a, 0.0)
    set_value(sub_elas_b, 0.)
    set_value(sub_elas_w, 0.)
    set_value(t_elas_a, 0.0)
    set_value(t_elas_b, 0.0)
    solve!(m, cumulative_iteration_limit=0)

    @test value(m, :A) ≈ two_by_two_scalar_results["A.L","benchmark"]#    1.
    @test MPSGE.Complementarity.result_value(m._jump_model[:B]) ≈ two_by_two_scalar_results["B.L","benchmark"]#    1.
    @test MPSGE.Complementarity.result_value(m._jump_model[:W]) ≈ two_by_two_scalar_results["W.L","benchmark"]#    1.
    @test MPSGE.Complementarity.result_value(m._jump_model[:CONS]) ≈ two_by_two_scalar_results["CONS.L","benchmark"]#    200.
    @test MPSGE.Complementarity.result_value(m._jump_model[:PX]) ≈ two_by_two_scalar_results["PX.L","benchmark"]#    1.
    @test MPSGE.Complementarity.result_value(m._jump_model[:PY]) ≈ two_by_two_scalar_results["PY.L","benchmark"]#    1.
    @test MPSGE.Complementarity.result_value(m._jump_model[:PW]) ≈ two_by_two_scalar_results["PW.L","benchmark"]#    1.
    @test MPSGE.Complementarity.result_value(m._jump_model[:PL]) ≈ two_by_two_scalar_results["PL.L","benchmark"]#    1.
    @test MPSGE.Complementarity.result_value(m._jump_model[:PK]) ≈ two_by_two_scalar_results["PK.L","benchmark"]#    1.
    # Implicit Variables
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PL†A")]) ≈ two_by_two_scalar_results["DAL.L","benchmark"]#    40.
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PL†B")]) ≈ two_by_two_scalar_results["DBL.L","benchmark"]#    60.
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PK†A")]) ≈ two_by_two_scalar_results["DAK.L","benchmark"]#    60.
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PK†B")]) ≈ two_by_two_scalar_results["DBK.L","benchmark"]#    40.
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX†W")]) ≈ two_by_two_scalar_results["DWX.L","benchmark"]#    100.
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PY†W")]) ≈ two_by_two_scalar_results["DWY.L","benchmark"]#    100.
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX‡A")]) ≈ two_by_two_scalar_results["SAX.L","benchmark"]#    40.
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PY‡A")]) ≈ two_by_two_scalar_results["SAY.L","benchmark"]#    60.
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX‡B")]) ≈ two_by_two_scalar_results["SBX.L","benchmark"]#    60.
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PY‡B")]) ≈ two_by_two_scalar_results["SBY.L","benchmark"]#    40.
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PW‡W")]) ≈ two_by_two_scalar_results["SW.L","benchmark"]#    100.
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PWρCONS")]) ≈ two_by_two_scalar_results["DW.L","benchmark"]#    100.

    set_value(diff, 10.0)
    set_fixed!(CONS, true)
    set_fixed!(PW, true)
    set_value(sub_elas_a, 1.5)
    set_value(sub_elas_b, 2.)
    set_value(sub_elas_w, 0.5)
    solve!(m)

    @test MPSGE.Complementarity.result_value(m._jump_model[:A]) ≈ two_by_two_scalar_results["A.L","1.52,.5T0"]#  0.91659821
    @test MPSGE.Complementarity.result_value(m._jump_model[:B]) ≈ two_by_two_scalar_results["B.L","1.52,.5T0"]#  1.08323854
    @test MPSGE.Complementarity.result_value(m._jump_model[:W]) ≈ two_by_two_scalar_results["W.L","1.52,.5T0"]#  1.00197574
    @test MPSGE.Complementarity.result_value(m._jump_model[:PX]) ≈ two_by_two_scalar_results["PX.L","1.52,.5T0"]#  1.03307968
    @test MPSGE.Complementarity.result_value(m._jump_model[:PY]) ≈ two_by_two_scalar_results["PY.L","1.52,.5T0"]#  0.86740231
    @test MPSGE.Complementarity.result_value(m._jump_model[:PW]) ≈ two_by_two_scalar_results["PW.L","1.52,.5T0"]#  1
    @test MPSGE.Complementarity.result_value(m._jump_model[:PL]) ≈ two_by_two_scalar_results["PL.L","1.52,.5T0"]#  1.01178793
    @test MPSGE.Complementarity.result_value(m._jump_model[:PK]) ≈ two_by_two_scalar_results["PK.L","1.52,.5T0"]#  0.99216354
    @test MPSGE.Complementarity.result_value(m._jump_model[:CONS]) ≈ two_by_two_scalar_results["CONS.L","1.52,.5T0"]#  200
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX‡A")]) ≈ two_by_two_scalar_results["SAX.L","1.52,.5T0"]#  80
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PY‡A")]) ≈ two_by_two_scalar_results["SAY.L","1.52,.5T0"]#  20
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX‡B")]) ≈ two_by_two_scalar_results["SBX.L","1.52,.5T0"]#  30
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PY‡B")]) ≈ two_by_two_scalar_results["SBY.L","1.52,.5T0"]#  80
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PL†A")]) ≈ two_by_two_scalar_results["DAL.L","1.52,.5T0"]#  39.29971476
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PK†A")]) ≈ two_by_two_scalar_results["DAK.L","1.52,.5T0"]#  60.70717236
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PL†B")]) ≈ two_by_two_scalar_results["DBL.L","1.52,.5T0"]#  59.06173874
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PK†B")]) ≈ two_by_two_scalar_results["DBK.L","1.52,.5T0"]#  40.94750382
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PW‡W")]) ≈ two_by_two_scalar_results["SW.L","1.52,.5T0"]#  200
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX†W")]) ≈ two_by_two_scalar_results["DWX.L","1.52,.5T0"]#  105.6163
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PY†W")]) ≈ two_by_two_scalar_results["DWY.L","1.52,.5T0"]#  104.784
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PWρCONS")]) ≈ two_by_two_scalar_results["DW.L","1.52,.5T0"]#  200


    set_value(sub_elas_a, 0.0)
    set_value(sub_elas_b, 0.)
    set_value(sub_elas_w, 0.)
    solve!(m)

    @test MPSGE.Complementarity.result_value(m._jump_model[:A]) ≈ two_by_two_scalar_results["A.L","Sub=0Tr=0"]#  1
    @test MPSGE.Complementarity.result_value(m._jump_model[:B]) ≈ two_by_two_scalar_results["B.L","Sub=0Tr=0"]#  1
    @test MPSGE.Complementarity.result_value(m._jump_model[:W]) ≈ two_by_two_scalar_results["W.L","Sub=0Tr=0"]#  1
    @test MPSGE.Complementarity.result_value(m._jump_model[:PX]) ≈ two_by_two_scalar_results["PX.L","Sub=0Tr=0"]#  1.02469785 ->GAMS returns 1.01705867 if sub_elas all 0 *after* were all 1
    @test MPSGE.Complementarity.result_value(m._jump_model[:PY]) ≈ two_by_two_scalar_results["PY.L","Sub=0Tr=0"]#  0.87283237 ->GAMS returns 0.88123547 if sub_elas all 0 *after* were all 1
    @test MPSGE.Complementarity.result_value(m._jump_model[:PW]) ≈ two_by_two_scalar_results["PW.L","Sub=0Tr=0"]#  1
    @test MPSGE.Complementarity.result_value(m._jump_model[:PL]) ≈ two_by_two_scalar_results["PL.L","Sub=0Tr=0"]#  1.028376251 ->GAMS returns 1.05052987 if sub_elas all 0 *after* were all 1 
    @test MPSGE.Complementarity.result_value(m._jump_model[:PK]) ≈ two_by_two_scalar_results["PK.L","Sub=0Tr=0"]#  0.971623754 ->GAMS returns 0.94947013 if sub_elas all 0 *after* were all 1 
    @test MPSGE.Complementarity.result_value(m._jump_model[:CONS]) ≈ two_by_two_scalar_results["CONS.L","Sub=0Tr=0"]#  200
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX‡A")]) ≈ two_by_two_scalar_results["SAX.L","Sub=0Tr=0"]#  80
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PY‡A")]) ≈ two_by_two_scalar_results["SAY.L","Sub=0Tr=0"]#  20
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX‡B")]) ≈ two_by_two_scalar_results["SBX.L","Sub=0Tr=0"]#  30
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PY‡B")]) ≈ two_by_two_scalar_results["SBY.L","Sub=0Tr=0"]#  80
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PL†A")]) ≈ two_by_two_scalar_results["DAL.L","Sub=0Tr=0"]#  40
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PK†A")]) ≈ two_by_two_scalar_results["DAK.L","Sub=0Tr=0"]#  60
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PL†B")]) ≈ two_by_two_scalar_results["DBL.L","Sub=0Tr=0"]#  60
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PK†B")]) ≈ two_by_two_scalar_results["DBK.L","Sub=0Tr=0"]#  40
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PW‡W")]) ≈ two_by_two_scalar_results["SW.L","Sub=0Tr=0"]#  200
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX†W")]) ≈ two_by_two_scalar_results["DWX.L","Sub=0Tr=0"]#  110
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PY†W")]) ≈ two_by_two_scalar_results["DWY.L","Sub=0Tr=0"]#  100
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PWρCONS")]) ≈ two_by_two_scalar_results["DW.L","Sub=0Tr=0"]#  200
    # CWI ")]) ≈ two_by_two_scalar_results["CWI.L","Sub=0Tr=0"]#  1

    set_value(t_elas_a, 2.0)
    set_value(t_elas_b, 1.5)
    solve!(m)

    @test MPSGE.Complementarity.result_value(m._jump_model[:A]) ≈ two_by_two_scalar_results["A.L","S0Tr2,1.5"]#  1
    @test MPSGE.Complementarity.result_value(m._jump_model[:B]) ≈ two_by_two_scalar_results["B.L","S0Tr2,1.5"]#  1
    @test MPSGE.Complementarity.result_value(m._jump_model[:W]) ≈ two_by_two_scalar_results["W.L","S0Tr2,1.5"]#  1
    @test MPSGE.Complementarity.result_value(m._jump_model[:PX]) ≈ two_by_two_scalar_results["PX.L","S0Tr2,1.5"]#  0.95238095
    @test MPSGE.Complementarity.result_value(m._jump_model[:PY]) ≈ two_by_two_scalar_results["PY.L","S0Tr2,1.5"]#  0.95238095
    @test MPSGE.Complementarity.result_value(m._jump_model[:PW]) ≈ two_by_two_scalar_results["PW.L","S0Tr2,1.5"]#  1
    @test MPSGE.Complementarity.result_value(m._jump_model[:PL]) ≈ two_by_two_scalar_results["PL.L","S0Tr2,1.5"]#  1.23809524
    @test MPSGE.Complementarity.result_value(m._jump_model[:PK]) ≈ two_by_two_scalar_results["PK.L","S0Tr2,1.5"]#  0.76190476
    @test MPSGE.Complementarity.result_value(m._jump_model[:CONS]) ≈ two_by_two_scalar_results["CONS.L","S0Tr2,1.5"]#  200
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX‡A")]) ≈ two_by_two_scalar_results["SAX.L","S0Tr2,1.5"]#  80
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PY‡A")]) ≈ two_by_two_scalar_results["SAY.L","S0Tr2,1.5"]#  20
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX‡B")]) ≈ two_by_two_scalar_results["SBX.L","S0Tr2,1.5"]#  30
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PY‡B")]) ≈ two_by_two_scalar_results["SBY.L","S0Tr2,1.5"]#  80
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PL†A")]) ≈ two_by_two_scalar_results["DAL.L","S0Tr2,1.5"]#  40
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PK†A")]) ≈ two_by_two_scalar_results["DAK.L","S0Tr2,1.5"]#  60
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PL†B")]) ≈ two_by_two_scalar_results["DBL.L","S0Tr2,1.5"]#  60
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PK†B")]) ≈ two_by_two_scalar_results["DBK.L","S0Tr2,1.5"]#  40
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PW‡W")]) ≈ two_by_two_scalar_results["SW.L","S0Tr2,1.5"]#  200
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX†W")]) ≈ two_by_two_scalar_results["DWX.L","S0Tr2,1.5"]#  110
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PY†W")]) ≈ two_by_two_scalar_results["DWY.L","S0Tr2,1.5"]#  100
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PWρCONS")]) ≈ two_by_two_scalar_results["DW.L","S0Tr2,1.5"]#  200
    # CWI ")]) ≈ two_by_two_scalar_results["CWI.L","S0Tr2,1.5"]#  1

    set_value(t_elas_a, 3.0)
    set_value(t_elas_b, 1.0)
    solve!(m)

    @test MPSGE.Complementarity.result_value(m._jump_model[:A]) ≈ two_by_two_scalar_results["A.L","S0Tr=3,1"]#  1
    @test MPSGE.Complementarity.result_value(m._jump_model[:B]) ≈ two_by_two_scalar_results["B.L","S0Tr=3,1"]#  1
    @test MPSGE.Complementarity.result_value(m._jump_model[:W]) ≈ two_by_two_scalar_results["W.L","S0Tr=3,1"]#  1
    @test MPSGE.Complementarity.result_value(m._jump_model[:PX]) ≈ two_by_two_scalar_results["PX.L","S0Tr=3,1"]#  0.95238095
    @test MPSGE.Complementarity.result_value(m._jump_model[:PY]) ≈ two_by_two_scalar_results["PY.L","S0Tr=3,1"]#  0.95238095
    @test MPSGE.Complementarity.result_value(m._jump_model[:PW]) ≈ two_by_two_scalar_results["PW.L","S0Tr=3,1"]#  1
    @test MPSGE.Complementarity.result_value(m._jump_model[:PL]) ≈ two_by_two_scalar_results["PL.L","S0Tr=3,1"]#  1.23809524
    @test MPSGE.Complementarity.result_value(m._jump_model[:PK]) ≈ two_by_two_scalar_results["PK.L","S0Tr=3,1"]#  0.76190476
    @test MPSGE.Complementarity.result_value(m._jump_model[:CONS]) ≈ two_by_two_scalar_results["CONS.L","S0Tr=3,1"]#  200
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX‡A")]) ≈ two_by_two_scalar_results["SAX.L","S0Tr=3,1"]#  80
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PY‡A")]) ≈ two_by_two_scalar_results["SAY.L","S0Tr=3,1"]#  20
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX‡B")]) ≈ two_by_two_scalar_results["SBX.L","S0Tr=3,1"]#  30
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PY‡B")]) ≈ two_by_two_scalar_results["SBY.L","S0Tr=3,1"]#  80
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PL†A")]) ≈ two_by_two_scalar_results["DAL.L","S0Tr=3,1"]#  40
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PK†A")]) ≈ two_by_two_scalar_results["DAK.L","S0Tr=3,1"]#  60
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PL†B")]) ≈ two_by_two_scalar_results["DBL.L","S0Tr=3,1"]#  60
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PK†B")]) ≈ two_by_two_scalar_results["DBK.L","S0Tr=3,1"]#  40
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PW‡W")]) ≈ two_by_two_scalar_results["SW.L","S0Tr=3,1"]#  200
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX†W")]) ≈ two_by_two_scalar_results["DWX.L","S0Tr=3,1"]#  110
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PY†W")]) ≈ two_by_two_scalar_results["DWY.L","S0Tr=3,1"]#  100
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PWρCONS")]) ≈ two_by_two_scalar_results["DW.L","S0Tr=3,1"]#  200
    # CWI ")]) ≈ two_by_two_scalar_results["CWI.L","S0Tr=3,1"]#  1

    set_value(t_elas_a, 1.0)
    set_value(t_elas_b, 1.0)
    solve!(m)

    @test MPSGE.Complementarity.result_value(m._jump_model[:A]) ≈ two_by_two_scalar_results["A.L","Sub=0Tr=1"]#  1
    @test MPSGE.Complementarity.result_value(m._jump_model[:B]) ≈ two_by_two_scalar_results["B.L","Sub=0Tr=1"]#  1
    @test MPSGE.Complementarity.result_value(m._jump_model[:W]) ≈ two_by_two_scalar_results["W.L","Sub=0Tr=1"]#  1
    @test MPSGE.Complementarity.result_value(m._jump_model[:PX]) ≈ two_by_two_scalar_results["PX.L","Sub=0Tr=1"]#  0.95238095
    @test MPSGE.Complementarity.result_value(m._jump_model[:PY]) ≈ two_by_two_scalar_results["PY.L","Sub=0Tr=1"]#  0.95238095
    @test MPSGE.Complementarity.result_value(m._jump_model[:PW]) ≈ two_by_two_scalar_results["PW.L","Sub=0Tr=1"]#  1
    @test MPSGE.Complementarity.result_value(m._jump_model[:PL]) ≈ two_by_two_scalar_results["PL.L","Sub=0Tr=1"]#  1.23809524
    @test MPSGE.Complementarity.result_value(m._jump_model[:PK]) ≈ two_by_two_scalar_results["PK.L","Sub=0Tr=1"]#  0.76190476
    @test MPSGE.Complementarity.result_value(m._jump_model[:CONS]) ≈ two_by_two_scalar_results["CONS.L","Sub=0Tr=1"]#  200
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX‡A")]) ≈ two_by_two_scalar_results["SAX.L","Sub=0Tr=1"]#  80
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PY‡A")]) ≈ two_by_two_scalar_results["SAY.L","Sub=0Tr=1"]#  20
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX‡B")]) ≈ two_by_two_scalar_results["SBX.L","Sub=0Tr=1"]#  30
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PY‡B")]) ≈ two_by_two_scalar_results["SBY.L","Sub=0Tr=1"]#  80
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PL†A")]) ≈ two_by_two_scalar_results["DAL.L","Sub=0Tr=1"]#  40
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PK†A")]) ≈ two_by_two_scalar_results["DAK.L","Sub=0Tr=1"]#  60
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PL†B")]) ≈ two_by_two_scalar_results["DBL.L","Sub=0Tr=1"]#  60
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PK†B")]) ≈ two_by_two_scalar_results["DBK.L","Sub=0Tr=1"]#  40
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PW‡W")]) ≈ two_by_two_scalar_results["SW.L","Sub=0Tr=1"]#  200
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX†W")]) ≈ two_by_two_scalar_results["DWX.L","Sub=0Tr=1"]#  110
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PY†W")]) ≈ two_by_two_scalar_results["DWY.L","Sub=0Tr=1"]#  100
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PWρCONS")]) ≈ two_by_two_scalar_results["DW.L","Sub=0Tr=1"]#  200
    # CWI ")]) ≈ two_by_two_scalar_results["CWI.L","Sub=0Tr=1"]#  1

    # Re-set with CES Substitution Elasticities
    m = Model()

    @parameter(m, diff, 0.0)
    @parameter(m, sub_elas_a, 1.5)
    @parameter(m, sub_elas_b, 2.)
    @parameter(m, sub_elas_w, .5)
    @parameter(m, t_elas_a, 0.0)
    @parameter(m, t_elas_b, 0.0)

    @sector(m, A)
    @sector(m, B)
    @sector(m, W)

    @commodity(m, PX)
    @commodity(m, PY)
    @commodity(m, PW)
    @commodity(m, PL)
    @commodity(m, PK)

    @consumer(m, CONS, benchmark=200.0)

    # @production(m, A, 0, 1, [Output(PX, 80),          Output(PY, 20)], [Input(PL, 40), Input(PK, 60)])
    @production(m, A, :($t_elas_a*1.), :($sub_elas_a*1.), [Output(PX, 80),          Output(PY, 20)], [Input(PL, 40), Input(PK, 60)])
    # @production(m, B, 0, 1, [Output(PX, 20), Output(PY, 80)], [Input(PL, 60), Input(PK, 40)])
    # @production(m, B, :($t_elas_b*1.), 1, [Output(PX, 20), Output(PY, 80)], [Input(PL, 60), Input(PK, 40)])
    @production(m, B, :($t_elas_b*1.), :($sub_elas_b*1.), [Output(PX, :(20+$diff)), Output(PY, 80)], [Input(PL, 60), Input(PK, 40)])
    @production(m, W, 0, :($sub_elas_w*1.), [Output(PW, 200.0)],[Input(PX, :(100.0+$diff)), Input(PY, 100.0)])
    # @production(m, W, 0, 1, [Output(PW, 200.0)], [Input(PX, 100.0), Input(PY, 100.0)])
    # @production(m, W, 0.,1, [Output(PW, :(200.0+$diff))], [Input(PX, :(100.0+$diff)), Input(PY, 100.0)])

    @demand(m, CONS, 1., [Demand(PW, 200.)], [Endowment(PL, 100.0), Endowment(PK, 100.0)])

    solve!(m, cumulative_iteration_limit=0)

    @test value(m, :A) ≈ two_by_two_scalar_results["A.L","benchmark"]#    1.
    @test MPSGE.Complementarity.result_value(m._jump_model[:B]) ≈ two_by_two_scalar_results["B.L","benchmark"]#    1.
    @test MPSGE.Complementarity.result_value(m._jump_model[:W]) ≈ two_by_two_scalar_results["W.L","benchmark"]#    1.
    @test MPSGE.Complementarity.result_value(m._jump_model[:CONS]) ≈ two_by_two_scalar_results["CONS.L","benchmark"]#    200.
    @test MPSGE.Complementarity.result_value(m._jump_model[:PX]) ≈ two_by_two_scalar_results["PX.L","benchmark"]#    1.
    @test MPSGE.Complementarity.result_value(m._jump_model[:PY]) ≈ two_by_two_scalar_results["PY.L","benchmark"]#    1.
    @test MPSGE.Complementarity.result_value(m._jump_model[:PW]) ≈ two_by_two_scalar_results["PW.L","benchmark"]#    1.
    @test MPSGE.Complementarity.result_value(m._jump_model[:PL]) ≈ two_by_two_scalar_results["PL.L","benchmark"]#    1.
    @test MPSGE.Complementarity.result_value(m._jump_model[:PK]) ≈ two_by_two_scalar_results["PK.L","benchmark"]#    1.
    # Implicit Variables
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PL†A")]) ≈ two_by_two_scalar_results["DAL.L","benchmark"]#    40.
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PL†B")]) ≈ two_by_two_scalar_results["DBL.L","benchmark"]#    60.
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PK†A")]) ≈ two_by_two_scalar_results["DAK.L","benchmark"]#    60.
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PK†B")]) ≈ two_by_two_scalar_results["DBK.L","benchmark"]#    40.
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX†W")]) ≈ two_by_two_scalar_results["DWX.L","benchmark"]#    100.
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PY†W")]) ≈ two_by_two_scalar_results["DWY.L","benchmark"]#    100.
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX‡A")]) ≈ two_by_two_scalar_results["SAX.L","benchmark"]#    40.
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PY‡A")]) ≈ two_by_two_scalar_results["SAY.L","benchmark"]#    60.
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX‡B")]) ≈ two_by_two_scalar_results["SBX.L","benchmark"]#    60.
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PY‡B")]) ≈ two_by_two_scalar_results["SBY.L","benchmark"]#    40.
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PW‡W")]) ≈ two_by_two_scalar_results["SW.L","benchmark"]#    100.
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PWρCONS")]) ≈ two_by_two_scalar_results["DW.L","benchmark"]#    100.

    set_value(diff, 10.0)
    set_fixed!(PW, true)
    set_fixed!(CONS, true)
    solve!(m)

    @test MPSGE.Complementarity.result_value(m._jump_model[:A]) ≈ two_by_two_scalar_results["A.L","1.52,.5T0"]#  0.91659821
    @test MPSGE.Complementarity.result_value(m._jump_model[:B]) ≈ two_by_two_scalar_results["B.L","1.52,.5T0"]#  1.08323854
    @test MPSGE.Complementarity.result_value(m._jump_model[:W]) ≈ two_by_two_scalar_results["W.L","1.52,.5T0"]#  1.00197574
    @test MPSGE.Complementarity.result_value(m._jump_model[:PX]) ≈ two_by_two_scalar_results["PX.L","1.52,.5T0"]#  1.03307968
    @test MPSGE.Complementarity.result_value(m._jump_model[:PY]) ≈ two_by_two_scalar_results["PY.L","1.52,.5T0"]#  0.86740231
    @test MPSGE.Complementarity.result_value(m._jump_model[:PW]) ≈ two_by_two_scalar_results["PW.L","1.52,.5T0"]#  1
    @test MPSGE.Complementarity.result_value(m._jump_model[:PL]) ≈ two_by_two_scalar_results["PL.L","1.52,.5T0"]#  1.01178793
    @test MPSGE.Complementarity.result_value(m._jump_model[:PK]) ≈ two_by_two_scalar_results["PK.L","1.52,.5T0"]#  0.99216354
    @test MPSGE.Complementarity.result_value(m._jump_model[:CONS]) ≈ two_by_two_scalar_results["CONS.L","1.52,.5T0"]#  200
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX‡A")]) ≈ two_by_two_scalar_results["SAX.L","1.52,.5T0"]#  80
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PY‡A")]) ≈ two_by_two_scalar_results["SAY.L","1.52,.5T0"]#  20
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX‡B")]) ≈ two_by_two_scalar_results["SBX.L","1.52,.5T0"]#  30
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PY‡B")]) ≈ two_by_two_scalar_results["SBY.L","1.52,.5T0"]#  80
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PL†A")]) ≈ two_by_two_scalar_results["DAL.L","1.52,.5T0"]#  39.29971476
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PK†A")]) ≈ two_by_two_scalar_results["DAK.L","1.52,.5T0"]#  60.70717236
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PL†B")]) ≈ two_by_two_scalar_results["DBL.L","1.52,.5T0"]#  59.06173874
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PK†B")]) ≈ two_by_two_scalar_results["DBK.L","1.52,.5T0"]#  40.94750382
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PW‡W")]) ≈ two_by_two_scalar_results["SW.L","1.52,.5T0"]#  200
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX†W")]) ≈ two_by_two_scalar_results["DWX.L","1.52,.5T0"]#  105.6163
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PY†W")]) ≈ two_by_two_scalar_results["DWY.L","1.52,.5T0"]#  104.784
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PWρCONS")]) ≈ two_by_two_scalar_results["DW.L","1.52,.5T0"]#  200
    # CWI ")]) ≈ two_by_two_scalar_results["CWI.L","1.52,.5T0"]#  1

    set_value(t_elas_a, 2.0)
    set_value(t_elas_b, 1.5)
    solve!(m)

    @test MPSGE.Complementarity.result_value(m._jump_model[:A]) ≈ two_by_two_scalar_results["A.L","S..T2,1.5"]#  0.73369015
    @test MPSGE.Complementarity.result_value(m._jump_model[:B]) ≈ two_by_two_scalar_results["B.L","S..T2,1.5"]#  1.26469651
    @test MPSGE.Complementarity.result_value(m._jump_model[:W]) ≈ two_by_two_scalar_results["W.L","S..T2,1.5"]#  1.00625374
    @test MPSGE.Complementarity.result_value(m._jump_model[:PX]) ≈ two_by_two_scalar_results["PX.L","S..T2,1.5"]#  1.02630741
    @test MPSGE.Complementarity.result_value(m._jump_model[:PY]) ≈ two_by_two_scalar_results["PY.L","S..T2,1.5"]#  0.87425307
    @test MPSGE.Complementarity.result_value(m._jump_model[:PW]) ≈ two_by_two_scalar_results["PW.L","S..T2,1.5"]#  1
    @test MPSGE.Complementarity.result_value(m._jump_model[:PL]) ≈ two_by_two_scalar_results["PL.L","S..T2,1.5"]#  1.03677841
    @test MPSGE.Complementarity.result_value(m._jump_model[:PK]) ≈ two_by_two_scalar_results["PK.L","S..T2,1.5"]#  0.97572906
    @test MPSGE.Complementarity.result_value(m._jump_model[:CONS]) ≈ two_by_two_scalar_results["CONS.L","S..T2,1.5"]#  200
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX‡A")]) ≈ two_by_two_scalar_results["SAX.L","S..T2,1.5"]#  84.35146263
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PY‡A")]) ≈ two_by_two_scalar_results["SAY.L","S..T2,1.5"]#  15.30213508
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX‡B")]) ≈ two_by_two_scalar_results["SBX.L","S..T2,1.5"]#  35.3753402
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PY‡B")]) ≈ two_by_two_scalar_results["SBY.L","S..T2,1.5"]#  74.16669241
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PL†A")]) ≈ two_by_two_scalar_results["DAL.L","S..T2,1.5"]#  37.8612801
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PK†A")]) ≈ two_by_two_scalar_results["DAK.L","S..T2,1.5"]#  62.20447225
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PL†B")]) ≈ two_by_two_scalar_results["DBL.L","S..T2,1.5"]#  57.10583598
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PK†B")]) ≈ two_by_two_scalar_results["DBK.L","S..T2,1.5"]#  42.98358596
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PW‡W")]) ≈ two_by_two_scalar_results["SW.L","S..T2,1.5"]#  200
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX†W")]) ≈ two_by_two_scalar_results["DWX.L","S..T2,1.5"]#  105.9642
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PY†W")]) ≈ two_by_two_scalar_results["DWY.L","S..T2,1.5"]#  104.3727
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PWρCONS")]) ≈ two_by_two_scalar_results["DW.L","S..T2,1.5"]#  200
    # CWI ")]) ≈ two_by_two_scalar_results["CWI.L","S..T2,1.5"]#  1

    set_value(t_elas_a, 3.0)
    set_value(t_elas_b, 1.0)
    solve!(m)

    @test MPSGE.Complementarity.result_value(m._jump_model[:A]) ≈ two_by_two_scalar_results["A.L","S...T3,1"]#  0.75685955
    @test MPSGE.Complementarity.result_value(m._jump_model[:B]) ≈ two_by_two_scalar_results["B.L","S...T3,1"]#  1.24179035
    @test MPSGE.Complementarity.result_value(m._jump_model[:W]) ≈ two_by_two_scalar_results["W.L","S...T3,1"]#  1.00597499
    @test MPSGE.Complementarity.result_value(m._jump_model[:PX]) ≈ two_by_two_scalar_results["PX.L","S...T3,1"]#  1.02454966
    @test MPSGE.Complementarity.result_value(m._jump_model[:PY]) ≈ two_by_two_scalar_results["PY.L","S...T3,1"]#  0.8760393
    @test MPSGE.Complementarity.result_value(m._jump_model[:PW]) ≈ two_by_two_scalar_results["PW.L","S...T3,1"]#  1
    @test MPSGE.Complementarity.result_value(m._jump_model[:PL]) ≈ two_by_two_scalar_results["PL.L","S...T3,1"]#  1.03394362
    @test MPSGE.Complementarity.result_value(m._jump_model[:PK]) ≈ two_by_two_scalar_results["PK.L","S...T3,1"]#  0.97800636
    @test MPSGE.Complementarity.result_value(m._jump_model[:CONS]) ≈ two_by_two_scalar_results["CONS.L","S...T3,1"]#  200
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX‡A")]) ≈ two_by_two_scalar_results["SAX.L","S...T3,1"]#  86.0833472
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PY‡A")]) ≈ two_by_two_scalar_results["SAY.L","S...T3,1"]#  13.45336364
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX‡B")]) ≈ two_by_two_scalar_results["SBX.L","S...T3,1"]#  33.44829341
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PY‡B")]) ≈ two_by_two_scalar_results["SBY.L","S...T3,1"]#  76.26640445
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PL†A")]) ≈ two_by_two_scalar_results["DAL.L","S...T3,1"]#  38.03642075
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PK†A")]) ≈ two_by_two_scalar_results["DAK.L","S...T3,1"]#  62.01884459
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PL†B")]) ≈ two_by_two_scalar_results["DBL.L","S...T3,1"]#  57.34605002
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PK†B")]) ≈ two_by_two_scalar_results["DBK.L","S...T3,1"]#  42.7289882
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PW‡W")]) ≈ two_by_two_scalar_results["SW.L","S...T3,1"]#  200
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX†W")]) ≈ two_by_two_scalar_results["DWX.L","S...T3,1"]#  106.0551
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PY†W")]) ≈ two_by_two_scalar_results["DWY.L","S...T3,1"]#  104.2662
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PWρCONS")]) ≈ two_by_two_scalar_results["DW.L","S...T3,1"]#  200
    # CWI ")]) ≈ two_by_two_scalar_results["CWI.L","S...T3,1"]#  1

    set_value(t_elas_a, 1.0)
    set_value(t_elas_b, 1.0)
    solve!(m)

    @test MPSGE.Complementarity.result_value(m._jump_model[:A]) ≈ two_by_two_scalar_results["A.L","S...T1,1"]#  0.8007181
    @test MPSGE.Complementarity.result_value(m._jump_model[:B]) ≈ two_by_two_scalar_results["B.L","S...T1,1"]#  1.19836817
    @test MPSGE.Complementarity.result_value(m._jump_model[:W]) ≈ two_by_two_scalar_results["W.L","S...T1,1"]#  1.0046559
    @test MPSGE.Complementarity.result_value(m._jump_model[:PX]) ≈ two_by_two_scalar_results["PX.L","S...T1,1"]#  1.02926607
    @test MPSGE.Complementarity.result_value(m._jump_model[:PY]) ≈ two_by_two_scalar_results["PY.L","S...T1,1"]#  0.87125403
    @test MPSGE.Complementarity.result_value(m._jump_model[:PW]) ≈ two_by_two_scalar_results["PW.L","S...T1,1"]#  1
    @test MPSGE.Complementarity.result_value(m._jump_model[:PL]) ≈ two_by_two_scalar_results["PL.L","S...T1,1"]#  1.02771668
    @test MPSGE.Complementarity.result_value(m._jump_model[:PK]) ≈ two_by_two_scalar_results["PK.L","S...T1,1"]#  0.98159512
    @test MPSGE.Complementarity.result_value(m._jump_model[:CONS]) ≈ two_by_two_scalar_results["CONS.L","S...T1,1"]#  200
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX‡A")]) ≈ two_by_two_scalar_results["SAX.L","S...T1,1"]#  82.36898138
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PY‡A")]) ≈ two_by_two_scalar_results["SAY.L","S...T1,1"]#  17.43094164
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX‡B")]) ≈ two_by_two_scalar_results["SBX.L","S...T1,1"]#  33.6709054
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PY‡B")]) ≈ two_by_two_scalar_results["SBY.L","S...T1,1"]#  76.00473896
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PL†A")]) ≈ two_by_two_scalar_results["DAL.L","S...T1,1"]#  38.37344599
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PK†A")]) ≈ two_by_two_scalar_results["DAK.L","S...T1,1"]#  61.66426821
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PL†B")]) ≈ two_by_two_scalar_results["DBL.L","S...T1,1"]#  57.80668129
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PK†B")]) ≈ two_by_two_scalar_results["DBK.L","S...T1,1"]#  42.244367
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PW‡W")]) ≈ two_by_two_scalar_results["SW.L","S...T1,1"]#  200
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX†W")]) ≈ two_by_two_scalar_results["DWX.L","S...T1,1"]#  105.8118
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PY†W")]) ≈ two_by_two_scalar_results["DWY.L","S...T1,1"]#  104.5521
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PWρCONS")]) ≈ two_by_two_scalar_results["DW.L","S...T1,1"]#  200
    # CWI ")]) ≈ two_by_two_scalar_results["CWI.L","S...T1,1"]#  1


end