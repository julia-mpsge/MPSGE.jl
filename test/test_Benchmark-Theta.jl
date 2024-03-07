@testset "TWOBYTWO outputdiff ThetaTest (macro version)" begin
    using XLSX, MPSGE_MP.JuMP.Containers
    import JuMP

    m = MPSGEModel()

    @parameter(m, endow, 1)
    @parameter(m, diff, 0)
    
    @sector(m, X)
    @sector(m, Y)
    @sector(m, U)
    
    @commodity(m, PX)
    @commodity(m, PY)
    @commodity(m, PU)
    @commodity(m, PL)
    @commodity(m, PK)
    
    @consumer(m, RA)
    
    @production(m, X, 
        ScalarNest(:t; elasticity = 0, children = [
            ScalarOutput(PX, 100 + diff)
        ]),
        ScalarNest(:s; elasticity = 1, children = [
            ScalarInput(PL, 50), ScalarInput(PK, 50)
        ])
    )
    
    @production(m, Y, 
        ScalarNest(:t; elasticity = 0, children = [
            ScalarOutput(PY, 50)
        ]), 
        ScalarNest(:s; elasticity = 1, children = [
            ScalarInput(PL, 20), ScalarInput(PK, 30)
        ])
    )
    
    
    @production(m, U, 
        ScalarNest(:t; elasticity = 0, children = [ScalarOutput(PU, 150)]), 
        ScalarNest(:s; elasticity = 1, children = [ScalarInput(PX, 100), ScalarInput(PY, 50)])
    )
    
    @demand(m, RA, [ScalarDem(PU, 150)], [ScalarEndowment(PL, endow * 70), ScalarEndowment(PK, 80.)])
    

    solve!(m, cumulative_iteration_limit=0)

    @test value(X) ≈ 1.
    @test value(Y) ≈ 1.
    @test value(U) ≈ 1.
    @test value(RA) ≈  150.
    @test value(PX) ≈  1.
    @test value(PY) ≈  1.
    @test value(PU) ≈  1.
    @test value(PL) ≈  1.
    @test value(PK) ≈  1.
    # Implicit Variables
    @test value(compensated_demand(X,PL)) ≈  50.
    @test value(compensated_demand(Y,PL)) ≈  20.
    @test value(compensated_demand(X,PK)) ≈  50.
    @test value(compensated_demand(Y,PK)) ≈  30.
    @test value(compensated_demand(U,PX)) ≈  100.
    @test value(compensated_demand(U,PY)) ≈  50.

    set_value!(diff,  10)
    set_value!(endow, 1.1)
    fix(RA, 157.0)
    
    solve!(m)

    @test value(X) ≈ 1.04880885
    @test value(Y) ≈ 1.03886012
    @test value(U) ≈ 1.11406803
    @test value(PX) ≈ 0.90723410
    @test value(PY) ≈ 1.00751453
    @test value(PU) ≈ 0.93949978
    @test value(PL) ≈ 0.95151515
    @test value(PK) ≈ 1.04666667
    @test value(compensated_demand(X,PL)) ≈ 52.44044241
    @test value(compensated_demand(X,PK)) ≈ 47.67312946
    @test value(compensated_demand(Y,PL)) ≈ 21.17705706
    @test value(compensated_demand(Y,PK)) ≈ 28.87780508
    @test value(compensated_demand(U,PX)) ≈ 103.5565 atol=1.0e-4
    @test value(compensated_demand(U,PY)) ≈ 46.62462680
    @test value(compensated_demand(X,PX)) ≈ -110
    @test value(compensated_demand(Y,PY)) ≈ -50
    @test value(compensated_demand(U,PU)) ≈ -150
    @test value(RA) ≈ 157
    @test value(demand(RA,PU)) ≈ 167.1102 atol=1.0e-5

end



@testset "TWOBYTWO Inputs ThetaTest (macro version)" begin
    using XLSX, MPSGE_MP.JuMP.Containers
    import JuMP

    m = MPSGEModel()

    @parameter(m, endow, 1)
    @parameter(m, diff, 0)

    @sector(m, X)
    @sector(m, Y)
    @sector(m, U)

    @commodity(m, PX)
    @commodity(m, PY)
    @commodity(m, PU)
    @commodity(m, PL)
    @commodity(m, PK)

    @consumer(m, RA)

    @production(m, X, 
        ScalarNest(:t; elasticity = 0, children = [
            ScalarOutput(PX,100)
        ]),
        ScalarNest(:s; elasticity = 1, children = [
            ScalarInput(PL, 50 + diff), ScalarInput(PK, 50)
        ])
    )

    @production(m, Y, 
        ScalarNest(:t; elasticity = 0, children = [
            ScalarOutput(PY, 50)
        ]), 
        ScalarNest(:s; elasticity = 1, children = [
            ScalarInput(PL, 20), ScalarInput(PK, 30)
        ])
    )


    @production(m, U, 
        ScalarNest(:t; elasticity = 0, children = [ScalarOutput(PU, 150)]), 
        ScalarNest(:s; elasticity = 1, children = [ScalarInput(PX, 100), ScalarInput(PY, 50)])
    )

    @demand(m, RA, [ScalarDem(PU, 150)], [ScalarEndowment(PL, endow * 70), ScalarEndowment(PK, 80.)])

    solve!(m, cumulative_iteration_limit=0)

    @test value(X) ≈ 1.
    @test value(Y) ≈ 1.
    @test value(U) ≈ 1.
    @test value(RA) ≈  150.
    @test value(PX) ≈  1.
    @test value(PY) ≈  1.
    @test value(PU) ≈  1.
    @test value(PL) ≈  1.
    @test value(PK) ≈  1.
    # Implicit Variables
    @test value(compensated_demand(X,PL)) ≈  50.
    @test value(compensated_demand(Y,PL)) ≈  20.
    @test value(compensated_demand(X,PK)) ≈  50.
    @test value(compensated_demand(Y,PK)) ≈  30.
    @test value(compensated_demand(U,PX)) ≈  100.
    @test value(compensated_demand(U,PY)) ≈  50.

    set_value!(diff, 10.)
    fix(RA, 150)
    solve!(m)

    @test value(X) ≈ 0.90209303
    @test value(Y) ≈ 1.00998168
    @test value(U) ≈ 0.93671049
    @test value(PX) ≈ 1.10853311
    @test value(PY) ≈ 0.99011696
    @test value(PU) ≈ 1.06756571
    @test value(PL) ≈ 1.06493506
    @test value(PK) ≈ 0.94318182
    @test value(compensated_demand(X,PL)) ≈ 56.77852579
    @test value(compensated_demand(X,PK)) ≈ 53.42328265
    @test value(compensated_demand(Y,PL)) ≈ 18.59487971
    @test value(compensated_demand(Y,PK)) ≈ 31.49287695
    @test value(compensated_demand(U,PX)) ≈ 96.30435869        #atol=1.0e-4
    @test value(compensated_demand(U,PY)) ≈ 53.91109057
    @test value(compensated_demand(X,PX)) ≈ -100
    @test value(compensated_demand(Y,PY)) ≈ -50
    @test value(compensated_demand(U,PU)) ≈ -150
    @test value(RA) ≈ 150
    @test value(demand(RA,PU)) ≈ 140.5066 atol=1.0e-4

    set_value!(endow, 1.1)
    fix(RA,157.0)
    
    solve!(m)

    @test value(X) ≈ 0.95023091
    @test value(Y) ≈ 1.04922969
    @test value(U) ≈ 0.98214655
    @test value(PX) ≈ 1.10148665
    @test value(PY) ≈ 0.99755723
    @test value(PU) ≈ 1.06569297
    @test value(PL) ≈ 1.01330185
    @test value(PK) ≈ 0.98719697
    @test value(compensated_demand(X,PL)) ≈ 59.29239153
    @test value(compensated_demand(X,PK)) ≈ 50.71690507
    @test value(compensated_demand(Y,PL)) ≈ 19.68924135
    @test value(compensated_demand(Y,PK)) ≈ 30.31483881
    @test value(compensated_demand(U,PX)) ≈ 96.75042055                #atol=1.0e-4
    @test value(compensated_demand(U,PY)) ≈ 53.41512898
    @test value(compensated_demand(X,PX)) ≈ -100
    @test value(compensated_demand(Y,PY)) ≈ -50
    @test value(compensated_demand(U,PU)) ≈ -150
    @test value(RA) ≈ 157
    @test value(demand(RA,PU)) ≈ 147.322 atol=1.0e-4

end
