@testitem "TWOBYTWO outputdiff ThetaTest (macro version)" begin
    using XLSX, MPSGE.JuMP.Containers
    import JuMP

m = Model()

@parameter(m, endow, 1.0)
@parameter(m, diff, 0.0)

@sector(m, X)
@sector(m, Y)
@sector(m, U)

@commodity(m, PX)
@commodity(m, PY)
@commodity(m, PU)
@commodity(m, PL)
@commodity(m, PK)

@consumer(m, RA, benchmark = 150.)

@production(m, X, 0, 1, [Output(PX, :(100+$diff))], [Input(PL, 50), Input(PK, 50)])
@production(m, Y, 0, 1, [Output(PY, 50)], [Input(PL, 20), Input(PK, 30)])
@production(m, U, 0, 1, [Output(PU, 150)], [Input(PX, 100), Input(PY, 50)])

@demand(m, RA, 1.0, [Demand(PU, 150)], [Endowment(PL, :(70 * $endow)), Endowment(PK, 80.)])
solve!(m, cumulative_iteration_limit=0)

@test value(m, :X) ≈ 1.
    @test JuMP.value(m._jump_model[:Y]) ≈ 1.
    @test JuMP.value(m._jump_model[:U]) ≈ 1.
    @test JuMP.value(m._jump_model[:RA]) ≈  150.
    @test JuMP.value(m._jump_model[:PX]) ≈  1.
    @test JuMP.value(m._jump_model[:PY]) ≈  1.
    @test JuMP.value(m._jump_model[:PU]) ≈  1.
    @test JuMP.value(m._jump_model[:PL]) ≈  1.
    @test JuMP.value(m._jump_model[:PK]) ≈  1.
# Implicit Variables
    @test JuMP.value(m._jump_model[Symbol("PL†X")]) ≈  50.
    @test JuMP.value(m._jump_model[Symbol("PL†Y")]) ≈  20.
    @test JuMP.value(m._jump_model[Symbol("PK†X")]) ≈  50.
    @test JuMP.value(m._jump_model[Symbol("PK†Y")]) ≈  30.
    @test JuMP.value(m._jump_model[Symbol("PX†U")]) ≈  100.
    @test JuMP.value(m._jump_model[Symbol("PY†U")]) ≈  50.

set_value(diff, 10.)
set_value(endow, 1.1)
set_value(RA, 157.0)
set_fixed!(RA, true)
solve!(m)

        @test value(m, :X) ≈ 1.04880885
        @test JuMP.value(m._jump_model[:Y]) ≈ 1.03886012
        @test JuMP.value(m._jump_model[:U]) ≈ 1.11406803
        @test JuMP.value(m._jump_model[:PX]) ≈ 0.90723410
        @test JuMP.value(m._jump_model[:PY]) ≈ 1.00751453
        @test JuMP.value(m._jump_model[:PU]) ≈ 0.93949978
        @test JuMP.value(m._jump_model[:PL]) ≈ 0.95151515
        @test JuMP.value(m._jump_model[:PK]) ≈ 1.04666667
        @test JuMP.value(m._jump_model[Symbol("PL†X")]) ≈ 52.44044241
        @test JuMP.value(m._jump_model[Symbol("PK†X")]) ≈ 47.67312946
        @test JuMP.value(m._jump_model[Symbol("PL†Y")]) ≈ 21.17705706
        @test JuMP.value(m._jump_model[Symbol("PK†Y")]) ≈ 28.87780508
        @test JuMP.value(m._jump_model[Symbol("PX†U")]) ≈ 103.5565 atol=1.0e-4
        @test JuMP.value(m._jump_model[Symbol("PY†U")]) ≈ 46.62462680
        @test JuMP.value(m._jump_model[Symbol("PX‡X")]) ≈ 110
        @test JuMP.value(m._jump_model[Symbol("PY‡Y")]) ≈ 50
        @test JuMP.value(m._jump_model[Symbol("PU‡U")]) ≈ 150
        @test JuMP.value(m._jump_model[:RA]) ≈ 157
        @test JuMP.value(m._jump_model[Symbol("PUρRA")]) ≈ 167.1102 atol=1.0e-5

end

@testitem "TWOBYTWO Inputs ThetaTest (macro version)" begin
    using XLSX, MPSGE.JuMP.Containers
    import JuMP

m = Model()

@parameter(m, endow, 1.0)
@parameter(m, diff, 0.0)

@sector(m, X)
@sector(m, Y)
@sector(m, U)

@commodity(m, PX)
@commodity(m, PY)
@commodity(m, PU)
@commodity(m, PL)
@commodity(m, PK)

@consumer(m, RA, benchmark = 150.)

@production(m, X, 0, 1, [Output(PX, 100)], [Input(PL, :(50+$diff)), Input(PK, 50)])
@production(m, Y, 0, 1, [Output(PY, 50)], [Input(PL, 20), Input(PK, 30)])
@production(m, U, 0, 1, [Output(PU, 150)], [Input(PX, 100), Input(PY, 50)])

@demand(m, RA, 1.0, [Demand(PU, 150)], [Endowment(PL, :(70 * $endow)), Endowment(PK, 80.)])
solve!(m, cumulative_iteration_limit=0)

@test value(m, :X) ≈ 1.
    @test JuMP.value(m._jump_model[:Y]) ≈ 1.
    @test JuMP.value(m._jump_model[:U]) ≈ 1.
    @test JuMP.value(m._jump_model[:RA]) ≈  150.
    @test JuMP.value(m._jump_model[:PX]) ≈  1.
    @test JuMP.value(m._jump_model[:PY]) ≈  1.
    @test JuMP.value(m._jump_model[:PU]) ≈  1.
    @test JuMP.value(m._jump_model[:PL]) ≈  1.
    @test JuMP.value(m._jump_model[:PK]) ≈  1.
# Implicit Variables
    @test JuMP.value(m._jump_model[Symbol("PL†X")]) ≈  50.
    @test JuMP.value(m._jump_model[Symbol("PL†Y")]) ≈  20.
    @test JuMP.value(m._jump_model[Symbol("PK†X")]) ≈  50.
    @test JuMP.value(m._jump_model[Symbol("PK†Y")]) ≈  30.
    @test JuMP.value(m._jump_model[Symbol("PX†U")]) ≈  100.
    @test JuMP.value(m._jump_model[Symbol("PY†U")]) ≈  50.

set_value(diff, 10.)
set_fixed!(RA, true)
solve!(m)

        @test value(m, :X) ≈ 0.90209303
        @test JuMP.value(m._jump_model[:Y]) ≈ 1.00998168
        @test JuMP.value(m._jump_model[:U]) ≈ 0.93671049
        @test JuMP.value(m._jump_model[:PX]) ≈ 1.10853311
        @test JuMP.value(m._jump_model[:PY]) ≈ 0.99011696
        @test JuMP.value(m._jump_model[:PU]) ≈ 1.06756571
        @test JuMP.value(m._jump_model[:PL]) ≈ 1.06493506
        @test JuMP.value(m._jump_model[:PK]) ≈ 0.94318182
        @test JuMP.value(m._jump_model[Symbol("PL†X")]) ≈ 56.77852579
        @test JuMP.value(m._jump_model[Symbol("PK†X")]) ≈ 53.42328265
        @test JuMP.value(m._jump_model[Symbol("PL†Y")]) ≈ 18.59487971
        @test JuMP.value(m._jump_model[Symbol("PK†Y")]) ≈ 31.49287695
        @test JuMP.value(m._jump_model[Symbol("PX†U")]) ≈ 96.30435869        #atol=1.0e-4
        @test JuMP.value(m._jump_model[Symbol("PY†U")]) ≈ 53.91109057
        @test JuMP.value(m._jump_model[Symbol("PX‡X")]) ≈ 100
        @test JuMP.value(m._jump_model[Symbol("PY‡Y")]) ≈ 50
        @test JuMP.value(m._jump_model[Symbol("PU‡U")]) ≈ 150
        @test JuMP.value(m._jump_model[:RA]) ≈ 150
        @test JuMP.value(m._jump_model[Symbol("PUρRA")]) ≈ 140.5066 atol=1.0e-4

        set_value(endow, 1.1)
        set_value(RA,157.0)
        set_fixed!(RA, true)
        solve!(m)
        
                @test value(m, :X) ≈ 0.95023091
                @test JuMP.value(m._jump_model[:Y]) ≈ 1.04922969
                @test JuMP.value(m._jump_model[:U]) ≈ 0.98214655
                @test JuMP.value(m._jump_model[:PX]) ≈ 1.10148665
                @test JuMP.value(m._jump_model[:PY]) ≈ 0.99755723
                @test JuMP.value(m._jump_model[:PU]) ≈ 1.06569297
                @test JuMP.value(m._jump_model[:PL]) ≈ 1.01330185
                @test JuMP.value(m._jump_model[:PK]) ≈ 0.98719697
                @test JuMP.value(m._jump_model[Symbol("PL†X")]) ≈ 59.29239153
                @test JuMP.value(m._jump_model[Symbol("PK†X")]) ≈ 50.71690507
                @test JuMP.value(m._jump_model[Symbol("PL†Y")]) ≈ 19.68924135
                @test JuMP.value(m._jump_model[Symbol("PK†Y")]) ≈ 30.31483881
                @test JuMP.value(m._jump_model[Symbol("PX†U")]) ≈ 96.75042055                #atol=1.0e-4
                @test JuMP.value(m._jump_model[Symbol("PY†U")]) ≈ 53.41512898
                @test JuMP.value(m._jump_model[Symbol("PX‡X")]) ≈ 100
                @test JuMP.value(m._jump_model[Symbol("PY‡Y")]) ≈ 50
                @test JuMP.value(m._jump_model[Symbol("PU‡U")]) ≈ 150
                @test JuMP.value(m._jump_model[:RA]) ≈ 157
                @test JuMP.value(m._jump_model[Symbol("PUρRA")]) ≈ 147.322 atol=1.0e-4
        
    end