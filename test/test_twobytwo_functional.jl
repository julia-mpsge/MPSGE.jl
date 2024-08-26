@testitem "TWOBYTWO (functional version)" begin
    using XLSX, MPSGE.JuMP.Containers
    import JuMP

    m = MPSGEModel()
    # Here parameter values are doubled and input data halved from MPSGE version       
    @parameters(m, begin
        inputcoeff, 2
        endow, 2
        elascoeff, 2
        outputmult, 2
    end)

    @sectors(m, begin
        X
        Y
        U
    end)

    @commodities(m, begin
        PX
        PY
        PU
        PL
        PK
    end)

    @consumer(m, RA)

    @production(m, X, [t = 0, s = 1], begin
        @output(PX,100, t)
        @input(PL, inputcoeff * 25, s) 
        @input(PK, 50, s)
    end)

    @production(m, Y, [t = 0, s = elascoeff*.5], begin
        @output(PY,50, t)
        @input(PL, 20, s)
        @input(PK, 30, s)
    end)

    @production(m, U, [t = 0, s = 1], begin
        @output(PU, outputmult * 75, t)
        @input(PX, 100, s) 
        @input(PY, 50, s)
    end)

    @demand(m, RA, begin
            @final_demand(PU,150)
        end,begin
            @endowment(PL, endow * 35)
            @endowment(PK, 80) 
    end)

    solve!(m)

    gams_results = XLSX.readxlsx(joinpath(@__DIR__, "MPSGEresults.xlsx"))
    a_table = gams_results["TwoxTwoScalar"][:]  # Generated from TwoByTwo_Scalar_Algeb-MPSGE.gms
    two_by_two_scalar_results = DenseAxisArray(a_table[2:end,2:end],a_table[2:end,1],a_table[1,2:end])

    @test value(X) ≈ two_by_two_scalar_results["X.L","benchmark"]#    1.0
    @test value(Y) ≈ two_by_two_scalar_results["Y.L","benchmark"]#    1.0
    @test value(U) ≈ two_by_two_scalar_results["U.L","benchmark"]#    1.0
    @test value(RA) ≈ two_by_two_scalar_results["RA.L","benchmark"]#    150.0
    @test value(PX) ≈ two_by_two_scalar_results["PX.L","benchmark"]#    1.0
    @test value(PY) ≈ two_by_two_scalar_results["PY.L","benchmark"]#    1.0
    @test value(PU) ≈ two_by_two_scalar_results["PU.L","benchmark"]#    1.0
    @test value(PL) ≈ two_by_two_scalar_results["PL.L","benchmark"]#    1.0
    @test value(PK) ≈ two_by_two_scalar_results["PK.L","benchmark"]#    1.0
    #Implicit variables
    @test value(compensated_demand(X,PL)) ≈ two_by_two_scalar_results["LX.L","benchmark"]#    50.
    @test value(compensated_demand(Y,PL)) ≈ two_by_two_scalar_results["LY.L","benchmark"]#    20.
    @test value(compensated_demand(X,PK)) ≈ two_by_two_scalar_results["KX.L","benchmark"]#    50.
    @test value(compensated_demand(Y,PK)) ≈ two_by_two_scalar_results["KY.L","benchmark"]#    30.
    @test value(compensated_demand(U,PX)) ≈ two_by_two_scalar_results["DX.L","benchmark"]#    100.
    @test value(compensated_demand(U,PY)) ≈ two_by_two_scalar_results["DY.L","benchmark"]#    50.

    fix(PX, 1)
    set_value!(endow, 2.2)
    solve!(m)

    @test value(X) ≈ two_by_two_scalar_results["X.L","PX=1"]#    1.04880885
    @test value(Y) ≈ two_by_two_scalar_results["Y.L","PX=1"]
    @test value(U) ≈ two_by_two_scalar_results["U.L","PX=1"]#    1.04548206
    @test value(RA) ≈ two_by_two_scalar_results["RA.L","PX=1"]#    157.321327225523
    @test value(PX) ≈ two_by_two_scalar_results["PX.L","PX=1"]#    1.0000000000
    @test value(PY) ≈ two_by_two_scalar_results["PY.L","PX=1"]#    1.00957658
    @test value(PU) ≈ two_by_two_scalar_results["PU.L","PX=1"]#    1.00318206
    @test value(PL) ≈ two_by_two_scalar_results["PL.L","PX=1"]#    0.95346259
    @test value(PK) ≈ two_by_two_scalar_results["PK.L","PX=1"]#    1.04880885
    @test value(compensated_demand(X,PL)) ≈ two_by_two_scalar_results["LX.L","PX=1"]#    52.4404424085075
    @test value(compensated_demand(Y,PL)) ≈ two_by_two_scalar_results["LY.L","PX=1"]#    21.1770570584356
    @test value(compensated_demand(X,PK)) ≈ two_by_two_scalar_results["KX.L","PX=1"]#    47.6731294622795
    @test value(compensated_demand(Y,PK)) ≈ two_by_two_scalar_results["KY.L","PX=1"]#    28.877805079685
    @test value(compensated_demand(U,PX)) ≈ two_by_two_scalar_results["DX.L","PX=1"]#    100.318205802571
    @test value(compensated_demand(U,PY)) ≈ two_by_two_scalar_results["DY.L","PX=1"]#    49.6833066029729

    unfix(PX)
    fix(PL, 1)
    solve!(m)

    @test value(X) ≈ two_by_two_scalar_results["X.L","PX=1"]#    1.04880885
    @test value(Y) ≈ two_by_two_scalar_results["Y.L","PL=1"]#    1.038860118
    @test value(U) ≈ two_by_two_scalar_results["U.L","PL=1"]#    1.04548206
    @test value(RA) ≈ two_by_two_scalar_results["RA.L","PL=1"]#    165
    @test value(PX) ≈ two_by_two_scalar_results["PX.L","PL=1"]#    1.048808848
    @test value(PY) ≈ two_by_two_scalar_results["PY.L","PL=1"]#    1.058852853
    @test value(PU) ≈ two_by_two_scalar_results["PU.L","PL=1"]#    1.052146219
    @test value(PL) ≈ two_by_two_scalar_results["PL.L","PL=1"]#    1.0
    @test value(PK) ≈ two_by_two_scalar_results["PK.L","PL=1"]#    1.1
    @test value(compensated_demand(X,PL)) ≈ two_by_two_scalar_results["LX.L","PL=1"]#    52.4404424085075
    @test value(compensated_demand(Y,PL)) ≈ two_by_two_scalar_results["LY.L","PL=1"]#    21.1770570584356
    @test value(compensated_demand(X,PK)) ≈ two_by_two_scalar_results["KX.L","PL=1"]#    47.6731294622795
    @test value(compensated_demand(Y,PK)) ≈ two_by_two_scalar_results["KY.L","PL=1"]#    28.877805079685
    @test value(compensated_demand(U,PX)) ≈ two_by_two_scalar_results["DX.L","PL=1"]#    100.318205802571
    @test value(compensated_demand(U,PY)) ≈ two_by_two_scalar_results["DY.L","PL=1"]#    49.6833066029729

end
