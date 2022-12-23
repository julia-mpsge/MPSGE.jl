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
@production(m, A, :($t_elas_a*1.), 1, [Output(PX, 80),          Output(PY, 20)], [Input(PL, 40), Input(PK, 60)])
# @production(m, B, 0, 1, [Output(PX, 20), Output(PY, 80)], [Input(PL, 60), Input(PK, 40)])
# @production(m, B, :($t_elas_b*1.), 1, [Output(PX, 20), Output(PY, 80)], [Input(PL, 60), Input(PK, 40)])
@production(m, B, :($t_elas_b*1.), 1, [Output(PX, :(20+$diff)), Output(PY, 80)], [Input(PL, 60), Input(PK, 40)])
@production(m, W, 0, 1, [Output(PW, 200.0)],[Input(PX, :(100.0+$diff)), Input(PY, 100.0)])
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

set_value(PW, 1.0)
set_fixed!(PW, true)
# set_fixed!(CONS, false)
solve!(m)

@test value(m, :A) ≈ two_by_two_scalar_results["A.L","PW.FX=1"]#
@test MPSGE.Complementarity.result_value(m._jump_model[:B]) ≈ two_by_two_scalar_results["B.L","PW.FX=1"]#
@test MPSGE.Complementarity.result_value(m._jump_model[:W]) ≈ two_by_two_scalar_results["W.L","PW.FX=1"]#
@test MPSGE.Complementarity.result_value(m._jump_model[:CONS]) ≈ two_by_two_scalar_results["CONS.L","PW.FX=1"]#
@test MPSGE.Complementarity.result_value(m._jump_model[:PX]) ≈ two_by_two_scalar_results["PX.L","PW.FX=1"]#
@test MPSGE.Complementarity.result_value(m._jump_model[:PY]) ≈ two_by_two_scalar_results["PY.L","PW.FX=1"]#
@test MPSGE.Complementarity.result_value(m._jump_model[:PW]) ≈ two_by_two_scalar_results["PW.L","PW.FX=1"]#
@test MPSGE.Complementarity.result_value(m._jump_model[:PL]) ≈ two_by_two_scalar_results["PL.L","PW.FX=1"]#
@test MPSGE.Complementarity.result_value(m._jump_model[:PK]) ≈ two_by_two_scalar_results["PK.L","PW.FX=1"]#
# Implicit Variables
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PL†A")]) ≈ two_by_two_scalar_results["DAL.L","PW.FX=1"]#
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PL†B")]) ≈ two_by_two_scalar_results["DBL.L","PW.FX=1"]#
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PK†A")]) ≈ two_by_two_scalar_results["DAK.L","PW.FX=1"]#
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PK†B")]) ≈ two_by_two_scalar_results["DBK.L","PW.FX=1"]#
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX†W")]) ≈ two_by_two_scalar_results["DWX.L","PW.FX=1"]#
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PY†W")]) ≈ two_by_two_scalar_results["DWY.L","PW.FX=1"]#
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX‡A")]) ≈ two_by_two_scalar_results["SAX.L","PW.FX=1"]#
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PY‡A")]) ≈ two_by_two_scalar_results["SAY.L","PW.FX=1"]#
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX‡B")]) ≈ two_by_two_scalar_results["SBX.L","PW.FX=1"]#
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PY‡B")]) ≈ two_by_two_scalar_results["SBY.L","PW.FX=1"]#
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PW‡W")]) ≈ two_by_two_scalar_results["SW.L","PW.FX=1"]#
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PWρCONS")]) ≈ two_by_two_scalar_results["DW.L","PW.FX=1"]#

set_value(t_elas_a, 2.0)
set_value(t_elas_b, 1.5)
set_fixed!(CONS, true)
solve!(m)

@test value(m, :A) ≈ two_by_two_scalar_results["A.L","TrA=2, TrB=1.5"]# 0.707165157355153
@test MPSGE.Complementarity.result_value(m._jump_model[:B]) ≈ two_by_two_scalar_results["B.L","TrA=2, TrB=1.5"]# 1.28930597023436
@test MPSGE.Complementarity.result_value(m._jump_model[:W]) ≈ two_by_two_scalar_results["W.L","TrA=2, TrB=1.5"]# 1.00689149966672
@test MPSGE.Complementarity.result_value(m._jump_model[:CONS]) ≈ two_by_two_scalar_results["CONS.L","TrA=2, TrB=1.5"]# 200
@test MPSGE.Complementarity.result_value(m._jump_model[:PX]) ≈ two_by_two_scalar_results["PX.L","TrA=2, TrB=1.5"]# 1.01618550543442
@test MPSGE.Complementarity.result_value(m._jump_model[:PY]) ≈ two_by_two_scalar_results["PY.L","TrA=2, TrB=1.5"]# 0.886813256204911
@test MPSGE.Complementarity.result_value(m._jump_model[:PW]) ≈ two_by_two_scalar_results["PW.L","TrA=2, TrB=1.5"]# 1
@test MPSGE.Complementarity.result_value(m._jump_model[:PL]) ≈ two_by_two_scalar_results["PL.L","TrA=2, TrB=1.5"]# 1.06783562768997
@test MPSGE.Complementarity.result_value(m._jump_model[:PK]) ≈ two_by_two_scalar_results["PK.L","TrA=2, TrB=1.5"]# 0.945947371643436
# Implicit Variables
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PL†A")]) ≈ two_by_two_scalar_results["DAL.L","TrA=2, TrB=1.5"]# 37.1943978496302
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PL†B")]) ≈ two_by_two_scalar_results["DBL.L","TrA=2, TrB=1.5"]# 57.1605340340898
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PK†A")]) ≈ two_by_two_scalar_results["DAK.L","TrA=2, TrB=1.5"]# 62.9805172543175
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PK†B")]) ≈ two_by_two_scalar_results["DBK.L","TrA=2, TrB=1.5"]# 43.0172308869871
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX†W")]) ≈ two_by_two_scalar_results["DWX.L","TrA=2, TrB=1.5"]# 103.093287792093
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PY†W")]) ≈ two_by_two_scalar_results["DWY.L","TrA=2, TrB=1.5"]# 107.393630588771
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX‡A")]) ≈ two_by_two_scalar_results["SAX.L","TrA=2, TrB=1.5"]# 83.7899794183074
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PY‡A")]) ≈ two_by_two_scalar_results["SAY.L","TrA=2, TrB=1.5"]# 15.9532971020169
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX‡B")]) ≈ two_by_two_scalar_results["SBX.L","TrA=2, TrB=1.5"]# 34.5537849036118
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PY‡B")]) ≈ two_by_two_scalar_results["SBY.L","TrA=2, TrB=1.5"]# 75.1195760654815
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PW‡W")]) ≈ two_by_two_scalar_results["SW.L","TrA=2, TrB=1.5"]# 200
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PWρCONS")]) ≈ two_by_two_scalar_results["DW.L","TrA=2, TrB=1.5"]# 200


end