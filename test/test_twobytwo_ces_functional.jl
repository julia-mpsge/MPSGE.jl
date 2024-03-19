@testset "TWOBYTWO (functional version copied, with non-1 elasticities of substitution in production)" begin
    using XLSX, MPSGE_MP.JuMP.Containers
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

    @production(m, X, [t = 0, s = .5], begin
        @Output(PX,100, t)
        @Input(PL, 25 * inputcoeff, s)
        @Input(PK, 50, s)
    end)

    @production(m, Y, [t = 0, s = .3*elascoeff], begin
        @Output(PY,50, t)
        @Input(PL, 20, s) 
        @Input(PK, 30, s)
    end)

    @production(m, U, [t = 0, s = 1], begin
        @Output(PU, 75 * outputmult, t)
        @Input(PX, 100, s)
        @Input(PY, 50,  s)
    end)

    @demand(m, RA, begin
            @final_demand(PU,150)
        end, begin
            @endowment(PL, 35 * endow)
            @endowment(PK, 80)
    end)


    solve!(m)
    gams_results = XLSX.readxlsx(joinpath(@__DIR__, "MPSGEresults.xlsx"))
    a_table = gams_results["TwoxTwoCESProd"][:]  # Generated with TwoByTwo_wElas_Scalar_Algeb-MPSGE.gms
    two_by_two_CES = DenseAxisArray(a_table[2:end,2:end],a_table[2:end,1],a_table[1,2:end])


    @test value(X) ≈  two_by_two_CES["X.L","benchmark"] # 1.
    @test value(Y) ≈ two_by_two_CES["Y.L","benchmark"] # 1.
    @test value(U) ≈ two_by_two_CES["U.L","benchmark"] # 1.
    @test value(RA) ≈ two_by_two_CES["RA.L","benchmark"] # 150.
    @test value(PX) ≈ two_by_two_CES["PX.L","benchmark"] # 1.
    @test value(PY) ≈ two_by_two_CES["PY.L","benchmark"] # 1.
    @test value(PU) ≈ two_by_two_CES["PU.L","benchmark"] # 1.
    @test value(PL) ≈ two_by_two_CES["PL.L","benchmark"] # 1.
    @test value(PK) ≈ two_by_two_CES["PK.L","benchmark"] # 1.
    @test value(compensated_demand(X,PL)) ≈ two_by_two_CES["LX.L","benchmark"] # 50.
    @test value(compensated_demand(Y,PL)) ≈ two_by_two_CES["LY.L","benchmark"] # 20.
    @test value(compensated_demand(X,PK)) ≈ two_by_two_CES["KX.L","benchmark"] # 50.
    @test value(compensated_demand(Y,PK)) ≈ two_by_two_CES["KY.L","benchmark"] # 30.
    @test value(compensated_demand(U,PX)) ≈ two_by_two_CES["DX.L","benchmark"] # 100.
    @test value(compensated_demand(U,PY,:s)) ≈ two_by_two_CES["DY.L","benchmark"] # 50.


    set_value!(endow, 2.2)
    fix(RA, 157)
    
    solve!(m)

    @test value(X) ≈ two_by_two_CES["X.L","RA=157"] # 1.05050654
    @test value(Y) ≈ two_by_two_CES["Y.L","RA=157"] # 1.03248042
    @test value(U) ≈ two_by_two_CES["U.L","RA=157"] # 1.04446313
    @test value(RA) ≈ two_by_two_CES["RA.L","RA=157"] # 157.
    @test value(PX) ≈ two_by_two_CES["PX.L","RA=157"] # 0.996344742
    @test value(PY) ≈ two_by_two_CES["PY.L","RA=157"] # 1.013739967
    @test value(PU) ≈ two_by_two_CES["PU.L","RA=157"] # 1.002109729
    @test value(PL) ≈ two_by_two_CES["PL.L","RA=157"] # 0.90982611
    @test value(PK) ≈ two_by_two_CES["PK.L","RA=157"] # 1.086792368
    @test value(compensated_demand(X,PL)) ≈ two_by_two_CES["LX.L","RA=157"] # 52.32335975
    @test value(compensated_demand(Y,PL)) ≈ two_by_two_CES["LY.L","RA=157"] # 21.34081
    @test value(compensated_demand(X,PK)) ≈ two_by_two_CES["KX.L","RA=157"] # 47.87420013
    @test value(compensated_demand(Y,PK)) ≈ two_by_two_CES["KY.L","RA=157"] # 28.7732718
    @test value(compensated_demand(U,PX)) ≈ two_by_two_CES["DX.L","RA=157"] # 100.5786137
    @test value(compensated_demand(U,PY,:s)) ≈ two_by_two_CES["DY.L","RA=157"] # 49.42636977

    unfix(RA)
    fix(PX, 1)

    # Just testing for bunctionality, not effecting the results
    #Scalar Consumer
    #set_lower_bound(RA, 10e100)
    #set_lower_bound(RA, 0.)
    #set_upper_bound(RA, 0.)
    #set_upper_bound(RA, 10e100)
    # Scalar Sector
    #set_lower_bound(Y, 1.)
    #set_lower_bound(Y, 0.)
    #set_upper_bound(Y, 1.)
    #set_upper_bound(Y, 10e100)
    #set_fixed!(Y, true)
    #set_fixed!(Y, false)
    # Scalar Commodity
    #set_lower_bound(PY, 1.)
    #set_lower_bound(PY, 0.)
    #set_upper_bound(PY, 1.)
    #set_upper_bound(PY, 10e100)

    solve!(m)

    @test value(X) ≈ two_by_two_CES["X.L","PX=1"] # 1.05050654
    @test value(Y) ≈ two_by_two_CES["Y.L","PX=1"] # 1.03248042
    @test value(U) ≈ two_by_two_CES["U.L","PX=1"] # 1.0
    @test value(RA) ≈ two_by_two_CES["RA.L","PX=1"] # 157.5759807
    @test value(PX) ≈ two_by_two_CES["PX.L","PX=1"] # 1.0
    @test value(PY) ≈ two_by_two_CES["PY.L","PX=1"] # 1.01745904
    @test value(PU) ≈ two_by_two_CES["PU.L","PX=1"] # 1.00578614
    @test value(PL) ≈ two_by_two_CES["PL.L","PX=1"] # 0.91316396
    @test value(PK) ≈ two_by_two_CES["PK.L","PX=1"] # 1.09077945
    @test value(compensated_demand(X,PL)) ≈ two_by_two_CES["LX.L","PX=1"] # 52.32335975
    @test value(compensated_demand(Y,PL)) ≈ two_by_two_CES["LY.L","PX=1"] # 21.34080999
    @test value(compensated_demand(X,PK)) ≈ two_by_two_CES["KX.L","PX=1"] # 47.87420013
    @test value(compensated_demand(Y,PK)) ≈ two_by_two_CES["KY.L","PX=1"] # 28.7732718
    @test value(compensated_demand(U,PX)) ≈ two_by_two_CES["DX.L","PX=1"] # 100.5786137
    @test value(compensated_demand(U,PY,:s)) ≈ two_by_two_CES["DY.L","PX=1"] # 49.42636977

    unfix(PX)
    fix(PL, 1)
    solve!(m)

    @test value(X) ≈ two_by_two_CES["X.L","PX=1"] # 1.05050654
    @test value(Y) ≈ two_by_two_CES["Y.L","PL=1"] # 1.03248042
    @test value(U) ≈ two_by_two_CES["U.L","PL=1"] # 1.0
    @test value(RA) ≈ two_by_two_CES["RA.L","PL=1"] # 172.5604466
    @test value(PX) ≈ two_by_two_CES["PX.L","PL=1"] # 1.095093591
    @test value(PY) ≈ two_by_two_CES["PY.L","PL=1"] # 1.114212876
    @test value(PU) ≈ two_by_two_CES["PU.L","PL=1"] # 1.101429952
    @test value(PL) ≈ two_by_two_CES["PL.L","PL=1"] # 1.0
    @test value(PK) ≈ two_by_two_CES["PK.L","PL=1"] # 1.194505582
    @test value(compensated_demand(X,PL)) ≈ two_by_two_CES["LX.L","PL=1"] # 52.32335975
    @test value(compensated_demand(Y,PL)) ≈ two_by_two_CES["LY.L","PL=1"] # 21.34080999
    @test value(compensated_demand(X,PK)) ≈ two_by_two_CES["KX.L","PL=1"] # 47.87420013
    @test value(compensated_demand(Y,PK)) ≈ two_by_two_CES["KY.L","PL=1"] # 28.7732718
    @test value(compensated_demand(U,PX)) ≈ two_by_two_CES["DX.L","PL=1"] # 100.5786137
    @test value(compensated_demand(U,PY,:s)) ≈ two_by_two_CES["DY.L","PL=1"] # 49.42636977

end
