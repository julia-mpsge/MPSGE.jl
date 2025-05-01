@testitem "TWOBYTWOwTax" begin
    using XLSX, MPSGE.JuMP.Containers
    import JuMP

    # A replication of the Two By Two Scalar, with an output Tax in counterfactual: TwoByTwo_Scalar_wTax_MPSGE.gms
    m = MPSGEModel()
    @parameters(m, begin
        esub_x, 1
        esub_y, 1
        endow, 1
        otax, 0
    end)

    @sectors(m,begin
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
    
    @production(m, X, [t=0, s = esub_x], begin
        @output(PX, 100, t, taxes=[Tax(RA, otax)])
        @input(PL, 50, s)
        @input(PK, 50, s)
    end)


    @production(m, Y, [t = 0, s = esub_y], begin
        @output(PY, 50, t)
        @input(PL, 20, s) 
        @input(PK, 30, s)
    end)

    @production(m, U, [t = 0, s = 1], begin    
        @output(PU,150, t)
        @input(PX, 100, s) 
        @input(PY, 50,  s)
    end)

    @demand(m, RA, begin
            @final_demand(PU, 150. )            
            @endowment(PL, endow*70)
            @endowment(PK, 80)
    end)

    gams_results = XLSX.readxlsx(joinpath(@__DIR__, "MPSGEresults.xlsx"))
    a_table = gams_results["TwoxTwowOTax"][:]  # Generated from TwoByTwo_Scalar_wTax-MPSGE.gms
    two_by_two_scalar_results = DenseAxisArray(a_table[2:end,2:end],a_table[2:end,1],a_table[1,2:end])

    solve!(m, cumulative_iteration_limit=0)

    @test value(X) ≈ two_by_two_scalar_results["X.L","benchmark"]#    1.
    @test value(Y) ≈ two_by_two_scalar_results["Y.L","benchmark"]#    1.
    @test value(U) ≈ two_by_two_scalar_results["U.L","benchmark"]#    1.
    @test value(RA) ≈ two_by_two_scalar_results["RA.L","benchmark"]#    150.
    @test value(PX) ≈ two_by_two_scalar_results["PX.L","benchmark"]#    1.
    @test value(PY) ≈ two_by_two_scalar_results["PY.L","benchmark"]#    1.
    @test value(PU) ≈ two_by_two_scalar_results["PU.L","benchmark"]#    1.
    @test value(PL) ≈ two_by_two_scalar_results["PL.L","benchmark"]#    1.
    @test value(PK) ≈ two_by_two_scalar_results["PK.L","benchmark"]#    1.
# Implicit Variables
    @test value(compensated_demand(X, PL)) ≈ two_by_two_scalar_results["DXL.L","benchmark"]#    50.
    @test value(compensated_demand(Y, PL)) ≈ two_by_two_scalar_results["DYL.L","benchmark"]#    20.
    @test value(compensated_demand(X, PK)) ≈ two_by_two_scalar_results["DXK.L","benchmark"]#    50.
    @test value(compensated_demand(Y, PK)) ≈ two_by_two_scalar_results["DYK.L","benchmark"]#    30.
    @test value(compensated_demand(U, PX)) ≈ two_by_two_scalar_results["DUX.L","benchmark"]#    100.
    @test value(compensated_demand(U, PY)) ≈ two_by_two_scalar_results["DUY.L","benchmark"]#    50.
    @test value(compensated_demand(X, PX, :t)) ≈ -two_by_two_scalar_results["SX.L","benchmark"]#    50.
    @test value(compensated_demand(Y, PY, :t)) ≈ -two_by_two_scalar_results["SY.L","benchmark"]#    50.
    @test value(compensated_demand(U, PU, :t)) ≈ -two_by_two_scalar_results["SU.L","benchmark"]#    50.
    @test value(demand(RA, PU)) ≈ two_by_two_scalar_results["CWI.L","benchmark"] # 100.3182058

    
    #Counterfactual 1, increase labour endowment by 10%, default normalisation of price: fix RA income at initial prices
    set_value!(endow, 1.1*value(endow))
    fix(RA, 157)
    solve!(m)

    @test value(X) ≈ two_by_two_scalar_results["X.L","RA=157"]#    1.
    @test value(Y) ≈ two_by_two_scalar_results["Y.L","RA=157"]#    1.
    @test value(U) ≈ two_by_two_scalar_results["U.L","RA=157"]#    1.
    @test value(RA) ≈ two_by_two_scalar_results["RA.L","RA=157"]#    150.
    @test value(PX) ≈ two_by_two_scalar_results["PX.L","RA=157"]#    1.
    @test value(PY) ≈ two_by_two_scalar_results["PY.L","RA=157"]#    1.
    @test value(PU) ≈ two_by_two_scalar_results["PU.L","RA=157"]#    1.
    @test value(PL) ≈ two_by_two_scalar_results["PL.L","RA=157"]#    1.
    @test value(PK) ≈ two_by_two_scalar_results["PK.L","RA=157"]#    1.
# Implicit Variables
    @test value(compensated_demand(X, PL)) ≈ two_by_two_scalar_results["DXL.L","RA=157"]#    50.
    @test value(compensated_demand(Y, PL)) ≈ two_by_two_scalar_results["DYL.L","RA=157"]#    20.
    @test value(compensated_demand(X, PK)) ≈ two_by_two_scalar_results["DXK.L","RA=157"]#    50.
    @test value(compensated_demand(Y, PK)) ≈ two_by_two_scalar_results["DYK.L","RA=157"]#    30.
    @test value(compensated_demand(U, PX)) ≈ two_by_two_scalar_results["DUX.L","RA=157"]#    100.
    @test value(compensated_demand(U, PY)) ≈ two_by_two_scalar_results["DUY.L","RA=157"]#    50.
    @test value(compensated_demand(X, PX, :t)) ≈ -two_by_two_scalar_results["SX.L","RA=157"]#    50.
    @test value(compensated_demand(Y, PY, :t)) ≈ -two_by_two_scalar_results["SY.L","RA=157"]#    50.
    @test value(compensated_demand(U, PU, :t)) ≈ -two_by_two_scalar_results["SU.L","RA=157"]#    50.
    @test value(demand(RA, PU)) ≈ two_by_two_scalar_results["CWI.L","RA=157"] # 156.8223095


    #Counterfactual 2, fix price of x as numeraire, unfix RA
    fix(PX, 1)
    unfix(RA)
    solve!(m)
    
    @test value(X)                                          ≈ two_by_two_scalar_results["X.L","PX=1"]#    1.0488088481702906
    @test value(Y) ≈ two_by_two_scalar_results["Y.L","PX=1"]#    1.038860118253863
    @test value(U) ≈ two_by_two_scalar_results["U.L","PX=1"]#    1.0454820635787618
    @test value(RA) ≈ two_by_two_scalar_results["RA.L","PX=1"]#  157.32132722551978
    @test value(PX) ≈ two_by_two_scalar_results["PX.L","PX=1"]#    1.
    @test value(PY) ≈ two_by_two_scalar_results["PY.L","PX=1"]#    1.0095765827768821
    @test value(PU) ≈ two_by_two_scalar_results["PU.L","PX=1"]#   1.0031820580257127
    @test value(PL) ≈ two_by_two_scalar_results["PL.L","PX=1"]#   0.953462589245595
    @test value(PK) ≈ two_by_two_scalar_results["PK.L","PX=1"]#   1.0488088481701119
    # Implicit Variables
    @test value(compensated_demand(X, PL)) ≈ two_by_two_scalar_results["DXL.L","PX=1"]#    52.44044240850651
    @test value(compensated_demand(Y, PL)) ≈ two_by_two_scalar_results["DYL.L","PX=1"]#    21.177057058435174
    @test value(compensated_demand(X, PK)) ≈ two_by_two_scalar_results["DXK.L","PX=1"]#    47.67312946228059
    @test value(compensated_demand(Y, PK)) ≈ two_by_two_scalar_results["DYK.L","PX=1"]#    28.8778050796855
    @test value(compensated_demand(U, PX)) ≈ two_by_two_scalar_results["DUX.L","PX=1"]#    100.31820580257127
    @test value(compensated_demand(U, PY)) ≈ two_by_two_scalar_results["DUY.L","PX=1"]#    49.68330660297305
    @test value(compensated_demand(X, PX, :t)) ≈ -two_by_two_scalar_results["SX.L","PX=1"]#    50.
    @test value(compensated_demand(Y, PY, :t)) ≈ -two_by_two_scalar_results["SY.L","PX=1"]#    50.
    @test value(compensated_demand(U, PU, :t)) ≈ -two_by_two_scalar_results["SU.L","PX=1"]#    50.
    @test value(demand(RA, PU)) ≈ two_by_two_scalar_results["CWI.L","PX=1"] # 156.8223095

    #Counterfactual #3 Use wages/labour price as numeraire
    unfix(PX)
    fix(PL, 1)
    solve!(m)
    
    @test value(X)                                          ≈ two_by_two_scalar_results["X.L","PL=1"]#    1.0488088481593985
    @test value(Y) ≈ two_by_two_scalar_results["Y.L","PL=1"]#    1.0388601182505193
    @test value(U) ≈ two_by_two_scalar_results["U.L","PL=1"]#    1.0454820635708377
    @test value(RA) ≈ two_by_two_scalar_results["RA.L","PL=1"]#    164.9999999917842
    @test value(PX) ≈ two_by_two_scalar_results["PX.L","PL=1"]#    1.0488088481386348
    @test value(PY) ≈ two_by_two_scalar_results["PY.L","PL=1"]#    1.058852852879376
    @test value(PU) ≈ two_by_two_scalar_results["PU.L","PL=1"]#    1.0521462187479675
    @test value(PL) ≈ two_by_two_scalar_results["PL.L","PL=1"]#    1.
    @test value(PK) ≈ two_by_two_scalar_results["PK.L","PL=1"]#    1.0999999998973022
    # Implicit Variables
    @test value(compensated_demand(X, PL)) ≈ two_by_two_scalar_results["DXL.L","PL=1"]#    52.44044240605962
    @test value(compensated_demand(Y, PL)) ≈ two_by_two_scalar_results["DYL.L","PL=1"]#    21.177057057249414
    @test value(compensated_demand(X, PK)) ≈ two_by_two_scalar_results["DXK.L","PL=1"]#    47.67312946450504
    @test value(compensated_demand(Y, PK)) ≈ two_by_two_scalar_results["DYK.L","PL=1"]#    28.877805080763462
    @test value(compensated_demand(U, PX)) ≈ two_by_two_scalar_results["DUX.L","PL=1"]#    100.31820580223697
    @test value(compensated_demand(U, PY)) ≈ two_by_two_scalar_results["DUY.L","PL=1"]#    49.68330660330415
    @test value(compensated_demand(X, PX, :t)) ≈ -two_by_two_scalar_results["SX.L","PL=1"]#    50.
    @test value(compensated_demand(Y, PY, :t)) ≈ -two_by_two_scalar_results["SY.L","PL=1"]#    50.
    @test value(compensated_demand(U, PU, :t)) ≈ -two_by_two_scalar_results["SU.L","PL=1"]#    50.
    @test value(demand(RA, PU)) ≈ two_by_two_scalar_results["CWI.L","PL=1"] # 156.8223095

    set_value!(otax, 0.1)
    solve!(m)

    @test value(X)                                          ≈ two_by_two_scalar_results["X.L","Otax=.1"]#    1.0116855688658395
    @test value(Y) ≈ two_by_two_scalar_results["Y.L","Otax=.1"]#    1.1123672179049628
    @test value(U) ≈ two_by_two_scalar_results["U.L","Otax=.1"]#    1.0441905629409307
    @test value(RA) ≈ two_by_two_scalar_results["RA.L","Otax=.1"]#    177.69230689285564
    @test value(PX) ≈ two_by_two_scalar_results["PX.L","Otax=.1"]#    1.170932369505204
    @test value(PY) ≈ two_by_two_scalar_results["PY.L","Otax=.1"]#    1.064949920418856
    @test value(PU) ≈ two_by_two_scalar_results["PU.L","Otax=.1"]#    1.1344819828665367
    @test value(PL) ≈ two_by_two_scalar_results["PL.L","Otax=.1"]#    1.
    @test value(PK) ≈ two_by_two_scalar_results["PK.L","Otax=.1"]#    1.1105769136174084
# Implicit Variables
    @test value(compensated_demand(X, PL)) ≈ two_by_two_scalar_results["DXL.L","Otax=.1"]#    52.69195654028726
    @test value(compensated_demand(Y, PL)) ≈ two_by_two_scalar_results["DYL.L","Otax=.1"]#    21.298998374443727
    @test value(compensated_demand(X, PK)) ≈ two_by_two_scalar_results["DXK.L","Otax=.1"]#    47.44557166118035
    @test value(compensated_demand(Y, PK)) ≈ two_by_two_scalar_results["DYK.L","Otax=.1"]#    28.767478568955543
    @test value(compensated_demand(U, PX)) ≈ two_by_two_scalar_results["DUX.L","Otax=.1"]#    96.88706302697432
    @test value(compensated_demand(U, PY)) ≈ two_by_two_scalar_results["DUY.L","Otax=.1"]#    53.26456958649977
    @test value(compensated_demand(X, PX, :t)) ≈ -two_by_two_scalar_results["SX.L","Otax=.1"]#    101.16855688658394
    @test value(compensated_demand(Y, PY, :t)) ≈ -two_by_two_scalar_results["SY.L","Otax=.1"]#    50.
    @test value(compensated_demand(U, PU, :t)) ≈ -two_by_two_scalar_results["SU.L","Otax=.1"]#    50.
    @test value(demand(RA, PU)) ≈ two_by_two_scalar_results["CWI.L","Otax=.1"] # 156.6285843


    
    set_value!(otax, 0.2)
    solve!(m)

    @test value(X)                                          ≈ two_by_two_scalar_results["X.L","Otax=.2"]#    0.9688481110216813
    @test value(Y) ≈ two_by_two_scalar_results["Y.L","Otax=.2"]#    1.197101452804781
    @test value(U) ≈ two_by_two_scalar_results["U.L","Otax=.2"]#    1.039634741431309
    @test value(RA) ≈ two_by_two_scalar_results["RA.L","Otax=.2"]#   192.49999801341977
    @test value(PX) ≈ two_by_two_scalar_results["PX.L","Otax=.2"]#    1.3245970219534051
    @test value(PY) ≈ two_by_two_scalar_results["PY.L","Otax=.2"]#    1.0720338858305598
    @test value(PU) ≈ two_by_two_scalar_results["PU.L","Otax=.2"]#    1.2344078852090752
    @test value(PL) ≈ two_by_two_scalar_results["PL.L","Otax=.2"]#    1.
    @test value(PK) ≈ two_by_two_scalar_results["PK.L","Otax=.2"] atol=1.0e-7#    1.122916644521622
    # Implicit Variables
    @test value(compensated_demand(X, PL)) ≈ two_by_two_scalar_results["DXL.L","Otax=.2"]#    52.98388067425842
    @test value(compensated_demand(Y, PL)) ≈ two_by_two_scalar_results["DYL.L","Otax=.2"]#    21.44067763741017
    @test value(compensated_demand(X, PK)) ≈ two_by_two_scalar_results["DXK.L","Otax=.2"]#    47.184161827817846
    @test value(compensated_demand(Y, PK)) ≈ two_by_two_scalar_results["DYK.L","Otax=.2"]#    28.640608911640356
    @test value(compensated_demand(U, PX)) ≈ two_by_two_scalar_results["DUX.L","Otax=.2"]#    93.19120190502586
    @test value(compensated_demand(U, PY)) ≈ two_by_two_scalar_results["DUY.L","Otax=.2"]#    57.57317476024549
    @test value(compensated_demand(X, PX, :t)) ≈ -two_by_two_scalar_results["SX.L","Otax=.2"]#    50.
    @test value(compensated_demand(Y, PY, :t)) ≈ -two_by_two_scalar_results["SY.L","Otax=.2"]#    50.
    @test value(compensated_demand(U, PU, :t)) ≈ -two_by_two_scalar_results["SU.L","Otax=.2"]#    50.
    @test value(demand(RA, PU)) ≈ two_by_two_scalar_results["CWI.L","Otax=.2"] # 155.9452109

    set_value!(otax, 0.5)
    solve!(m)

    @test value(X)                                          ≈ two_by_two_scalar_results["X.L","Otax=.5"]#    0.7888106357533915
    @test value(Y) ≈ two_by_two_scalar_results["Y.L","Otax=.5"]#    1.5521999426621624
    @test value(U) ≈ two_by_two_scalar_results["U.L","Otax=.5"]#    0.9884720495748968
    @test value(RA) ≈ two_by_two_scalar_results["RA.L","Otax=.5"]#    256.6666666666296
    @test value(PX) ≈ two_by_two_scalar_results["PX.L","Otax=.5"]#    2.1692292538029863
    @test value(PY) ≈ two_by_two_scalar_results["PY.L","Otax=.5"]#    1.102378027521483
    @test value(PU) ≈ two_by_two_scalar_results["PU.L","Otax=.5"]#    1.731066762936565
    @test value(PL) ≈ two_by_two_scalar_results["PL.L","Otax=.5"]#    1.
    @test value(PK) ≈ two_by_two_scalar_results["PK.L","Otax=.5"]#    1.1763888888885616
    # Implicit Variables
    @test value(compensated_demand(X, PL)) ≈ two_by_two_scalar_results["DXL.L","Otax=.5"]#    54.23073134507227
    @test value(compensated_demand(Y, PL)) ≈ two_by_two_scalar_results["DYL.L","Otax=.5"]#    22.04756055042873
    @test value(compensated_demand(X, PK)) ≈ two_by_two_scalar_results["DXK.L","Otax=.5"]#    46.09932298519823
    @test value(compensated_demand(Y, PK)) ≈ two_by_two_scalar_results["DYK.L","Otax=.5"]#    28.112591965135366
    @test value(compensated_demand(U, PX)) ≈ two_by_two_scalar_results["DUX.L","Otax=.5"]#    79.80100581355073
    @test value(compensated_demand(U, PY)) ≈ two_by_two_scalar_results["DUY.L","Otax=.5"]#    78.5151154921232
    @test value(compensated_demand(X, PX, :t)) ≈ -two_by_two_scalar_results["SX.L","Otax=.5"]#    50.
    @test value(compensated_demand(Y, PY, :t)) ≈ -two_by_two_scalar_results["SY.L","Otax=.5"]#    50.
    @test value(compensated_demand(U, PU, :t)) ≈ -two_by_two_scalar_results["SU.L","Otax=.5"]#    50.
    @test value(demand(RA, PU)) ≈ two_by_two_scalar_results["CWI.L","Otax=.5"] # 148.2708074

    
    set_value!(otax, 0.9)

    ### Bug if not set. Not certain what the issue is.
    ### This only breaks if run in this order, if you set otax to .9 before
    ### solving with otax = .5 then it's fine. 
    #fix(RA,462)

    solve!(m)

    @test value(X) ≈ two_by_two_scalar_results["X.L","Otax=.9"]#    0.2653299831628428
    @test value(Y) ≈ two_by_two_scalar_results["Y.L","Otax=.9"]#    2.575333351676288
    @test value(U) ≈ two_by_two_scalar_results["U.L","Otax=.9"]#    0.5659812410319296
    @test value(RA) ≈ two_by_two_scalar_results["RA.L","Otax=.9"]#    461.9999999777376
    @test value(PX) ≈ two_by_two_scalar_results["PX.L","Otax=.9"]#    11.608186765877146
    @test value(PY) ≈ two_by_two_scalar_results["PY.L","Otax=.9"]#    1.195961679231847
    @test value(PU) ≈ two_by_two_scalar_results["PU.L","Otax=.9"]#   5.441876473230442
    @test value(PL) ≈ two_by_two_scalar_results["PL.L","Otax=.9"]#    1.
    @test value(PK) ≈ two_by_two_scalar_results["PK.L","Otax=.9"]#    1.347499999874207
    # Implicit Variables
    @test value(compensated_demand(X, PL)) ≈ two_by_two_scalar_results["DXL.L","Otax=.9"]#    58.040933828510354
    @test value(compensated_demand(Y, PL)) ≈ two_by_two_scalar_results["DYL.L","Otax=.9"]#    23.919233584290627
    @test value(compensated_demand(X, PK)) ≈ two_by_two_scalar_results["DXK.L","Otax=.9"]#    43.0730492274053
    @test value(compensated_demand(Y, PK)) ≈ two_by_two_scalar_results["DYK.L","Otax=.9"]#    26.62623404807817
    @test value(compensated_demand(U, PX)) ≈ two_by_two_scalar_results["DUX.L","Otax=.9"]#    46.879642643468536
    @test value(compensated_demand(U, PY)) ≈ two_by_two_scalar_results["DUY.L","Otax=.9"]#    227.51048665392318
    @test value(compensated_demand(X, PX, :t)) ≈ -two_by_two_scalar_results["SX.L","Otax=.9"]#    50.
    @test value(compensated_demand(Y, PY, :t)) ≈ -two_by_two_scalar_results["SY.L","Otax=.9"]#    50.
    @test value(compensated_demand(U, PU, :t)) ≈ -two_by_two_scalar_results["SU.L","Otax=.9"]#    50.
    @test value(demand(RA, PU)) ≈ two_by_two_scalar_results["CWI.L","Otax=.9"] # 84.89718615

    

end



@testset "TWOBYTWOwOTax_IndCons" begin
    using XLSX, MPSGE.JuMP.Containers
    import JuMP
    
    # A replication of the Two By Two, with an output Tax in one consumer counterfactual: TwoByTwo_wTax_IndexRA.gms
    m = MPSGEModel()
    
    consumers = [:a, :b]
    consumption = DenseAxisArray(Float64[75, 75], consumers)

    @parameters(m, begin
        esub_x, 1
        esub_y, 1
        endow, 1
        otaxa, 0
        otaxb, 0
    end)

    @sectors(m,begin
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
    
    @consumer(m, RA, index = [consumers])
    
    @production(m, X, [t = 0, s = esub_x], begin
        @output(PX, 100, t, taxes=[Tax(RA[:a], otaxa)])
        @input(PL, 50, s) 
        @input(PK, 50, s)
    end)
    
    @production(m, Y, [t = 0, s = esub_y], begin
        @output(PY, 50, t, taxes = [Tax(RA[:b], otaxb)])
        @input(PL, 20, s) 
        @input(PK, 30, s)
    end)
    
    @production(m, U, [t = 0, s = 1], begin
        @output(PU,150, t)
        @input(PX, 100, s) 
        @input(PY, 50,  s)
    end)

    for r in consumers
        @demand(m, RA[r], begin
                @final_demand(PU, 75. )                
                @endowment(PL, endow*35)
                @endowment(PK, 40)
        end)
    end

 
    gams_results = XLSX.readxlsx(joinpath(@__DIR__, "MPSGEresults.xlsx"))
    a_table = gams_results["TwoxTwowOTax_IndCon"][:]  # Generated from TwoByTwo_wTax_IndexRA.gms
    two_by_two_scalar_results = DenseAxisArray(a_table[2:end,2:end],a_table[2:end,1],a_table[1,2:end])
 
    solve!(m, cumulative_iteration_limit=0)



    @test value(X) ≈ two_by_two_scalar_results["X.L","benchmark"]#    1.
    @test value(Y) ≈ two_by_two_scalar_results["Y.L","benchmark"]#    1.
    @test value(U) ≈ two_by_two_scalar_results["U.L","benchmark"]#    1.
    @test value(RA[:a]) ≈ two_by_two_scalar_results["RAA.L","benchmark"]#    75.
    @test value(RA[:b]) ≈ two_by_two_scalar_results["RAB.L","benchmark"]#    75.
    @test value(PX) ≈ two_by_two_scalar_results["PX.L","benchmark"]#    1.
    @test value(PY) ≈ two_by_two_scalar_results["PY.L","benchmark"]#    1.
    @test value(PU) ≈ two_by_two_scalar_results["PU.L","benchmark"]#    1.
    @test value(PL) ≈ two_by_two_scalar_results["PL.L","benchmark"]#    1.
    @test value(PK) ≈ two_by_two_scalar_results["PK.L","benchmark"]#    1.
# Implicit Variables
    @test value(compensated_demand(X, PL)) ≈ two_by_two_scalar_results["DXL.L","benchmark"]#    50.
    @test value(compensated_demand(Y, PL)) ≈ two_by_two_scalar_results["DYL.L","benchmark"]#    20.
    @test value(compensated_demand(X, PK)) ≈ two_by_two_scalar_results["DXK.L","benchmark"]#    50.
    @test value(compensated_demand(Y, PK)) ≈ two_by_two_scalar_results["DYK.L","benchmark"]#    30.
    @test value(compensated_demand(U, PX)) ≈ two_by_two_scalar_results["DUX.L","benchmark"]#    100.
    @test value(compensated_demand(U, PY)) ≈ two_by_two_scalar_results["DUY.L","benchmark"]#    50.
    @test value(compensated_demand(X, PX, :t)) ≈ -two_by_two_scalar_results["SX.L","benchmark"]#    50.
    @test value(compensated_demand(Y, PY, :t)) ≈ -two_by_two_scalar_results["SY.L","benchmark"]#    50.
    @test value(compensated_demand(U, PU, :t)) ≈ -two_by_two_scalar_results["SU.L","benchmark"]#    50.
    @test value(demand(RA[:a], PU)) ≈ two_by_two_scalar_results["DURAA.L","benchmark"] # 75.
    @test value(demand(RA[:b], PU)) ≈ two_by_two_scalar_results["DURAA.L","benchmark"] # 75.

    #Counterfactual 1, increase labour endowment by 10%, default normalisation of price: fix RA income at initial prices
    set_value!(endow, 1.1 * value(endow))

    fix(RA[:a], 78.5)
    fix(RA[:b], 78.5)
    solve!(m)

    @test value(X) ≈ two_by_two_scalar_results["X.L","RA=157"]#    1.04880885
    @test value(Y) ≈ two_by_two_scalar_results["Y.L","RA=157"]#    1.03886012
    @test value(U) ≈ two_by_two_scalar_results["U.L","RA=157"]#  1.04548206
    @test value(RA[:a]) ≈ two_by_two_scalar_results["RAA.L","RA=157"]#   78.50000000
    @test value(RA[:b]) ≈ two_by_two_scalar_results["RAB.L","RA=157"]#    78.49999994
    @test value(PX) ≈ two_by_two_scalar_results["PX.L","RA=157"]#   0.99795751
    @test value(PY) ≈ two_by_two_scalar_results["PY.L","RA=157"]#    1.00751453
    @test value(PU) ≈ two_by_two_scalar_results["PU.L","RA=157"]#    1.00113307
    @test value(PL) ≈ two_by_two_scalar_results["PL.L","RA=157"]#    0.95151515
    @test value(PK) ≈ two_by_two_scalar_results["PK.L","RA=157"]#  1.04666667
# Implicit Variables
    @test value(compensated_demand(X, PL)) ≈ two_by_two_scalar_results["DXL.L","RA=157"]#    52.44044243
    @test value(compensated_demand(Y, PL)) ≈ two_by_two_scalar_results["DYL.L","RA=157"]#    21.1770570
    @test value(compensated_demand(X, PK)) ≈ two_by_two_scalar_results["DXK.L","RA=157"]#    47.67312946200557
    @test value(compensated_demand(Y, PK)) ≈ two_by_two_scalar_results["DYK.L","RA=157"]#    28.877805080093896
    @test value(compensated_demand(U, PX)) ≈ two_by_two_scalar_results["DUX.L","RA=157"]#    100.31820580267068
    @test value(compensated_demand(U, PY)) ≈ two_by_two_scalar_results["DUY.L","RA=157"]#    49.683306602880336
    @test value(compensated_demand(X, PX, :t)) ≈ -two_by_two_scalar_results["SX.L","RA=157"]#    100.
    @test value(compensated_demand(Y, PY, :t)) ≈ -two_by_two_scalar_results["SY.L","RA=157"]#    50.
    @test value(compensated_demand(U, PU, :t)) ≈ -two_by_two_scalar_results["SU.L","RA=157"]#    150.
    @test value(demand(RA[:a], PU)) ≈ two_by_two_scalar_results["DURAA.L","RA=157"] # 78.41115476890819
    @test value(demand(RA[:b], PU)) ≈ two_by_two_scalar_results["DURAB.L","RA=157"] # 78.41115476890819

    #Counterfactual 2, fix price of x as numeraire, unfix RA
    fix(PX, 1)
    unfix(RA[:a])
    unfix(RA[:b])
    solve!(m)
    
    @test value(X) ≈ two_by_two_scalar_results["X.L","PX=1"]#    1.0488088485
    @test value(Y) ≈ two_by_two_scalar_results["Y.L","PX=1"]#    1.03886012
    @test value(U) ≈ two_by_two_scalar_results["U.L","PX=1"]#    1.04548206
    @test value(RA[:a]) ≈ two_by_two_scalar_results["RAA.L","PX=1"]#  78.66066361
    @test value(RA[:b]) ≈ two_by_two_scalar_results["RAB.L","PX=1"]#  78.66066361
    @test value(PX) ≈ two_by_two_scalar_results["PX.L","PX=1"]#    1.
    @test value(PY) ≈ two_by_two_scalar_results["PY.L","PX=1"]#    1.00957658
    @test value(PU) ≈ two_by_two_scalar_results["PU.L","PX=1"]#   1.00318206
    @test value(PL) ≈ two_by_two_scalar_results["PL.L","PX=1"]#   0.95346259
    @test value(PK) ≈ two_by_two_scalar_results["PK.L","PX=1"]#   1.04880885
# Implicit Variables
    @test value(compensated_demand(X, PL)) ≈ two_by_two_scalar_results["DXL.L","PX=1"]#    52.44044241
    @test value(compensated_demand(Y, PL)) ≈ two_by_two_scalar_results["DYL.L","PX=1"]#    21.17705706
    @test value(compensated_demand(X, PK)) ≈ two_by_two_scalar_results["DXK.L","PX=1"]#    47.67312946
    @test value(compensated_demand(Y, PK)) ≈ two_by_two_scalar_results["DYK.L","PX=1"]#    28.87780508
    @test value(compensated_demand(U, PX)) ≈ two_by_two_scalar_results["DUX.L","PX=1"]#    100.3182
    @test value(compensated_demand(U, PY)) ≈ two_by_two_scalar_results["DUY.L","PX=1"]#    49.68330660
    @test value(compensated_demand(X, PX, :t)) ≈ -two_by_two_scalar_results["SX.L","PX=1"]#    100.
    @test value(compensated_demand(Y, PY, :t)) ≈ -two_by_two_scalar_results["SY.L","PX=1"]#    50.
    @test value(compensated_demand(U, PU, :t)) ≈ -two_by_two_scalar_results["SU.L","PX=1"]#    150.
    @test value(demand(RA[:a], PU)) ≈ two_by_two_scalar_results["DURAA.L","PX=1"] # 78.41115477
    @test value(demand(RA[:b], PU)) ≈ two_by_two_scalar_results["DURAB.L","PX=1"] # 78.41115477

    #Counterfactual #3 Use wages/labour price as numeraire
    unfix(PX)
    fix(PL, 1)
    solve!(m)

    @test value(X)                                          ≈ two_by_two_scalar_results["X.L","PL=1"]	#	1.04880885
    @test value(Y) ≈ two_by_two_scalar_results["Y.L","PL=1"]	#	1.03886012
    @test value(U) ≈ two_by_two_scalar_results["U.L","PL=1"]	#	1.04548206
    @test value(RA[:a]) ≈ two_by_two_scalar_results["RAA.L","PL=1"]	#	82.5
    @test value(RA[:b]) ≈ two_by_two_scalar_results["RAB.L","PL=1"]	#	82.5
    @test value(PX) ≈ two_by_two_scalar_results["PX.L","PL=1"]	#	1.04880885
    @test value(PY) ≈ two_by_two_scalar_results["PY.L","PL=1"]	#	1.05885285
    @test value(PU) ≈ two_by_two_scalar_results["PU.L","PL=1"]	#	1.05214622
    @test value(PL) ≈ two_by_two_scalar_results["PL.L","PL=1"]	#	1
    @test value(PK) ≈ two_by_two_scalar_results["PK.L","PL=1"]	#	1.1
	#	 Implicit Variables
    @test value(compensated_demand(X, PL)) ≈ two_by_two_scalar_results["DXL.L","PL=1"]	#	52.44044241
    @test value(compensated_demand(Y, PL)) ≈ two_by_two_scalar_results["DYL.L","PL=1"]	#	47.67312946
    @test value(compensated_demand(X, PK)) ≈ two_by_two_scalar_results["DXK.L","PL=1"]	#	21.17705706
    @test value(compensated_demand(Y, PK)) ≈ two_by_two_scalar_results["DYK.L","PL=1"]	#	28.87780508
    @test value(compensated_demand(U, PX)) ≈ two_by_two_scalar_results["DUX.L","PL=1"]	#	100.3182
    @test value(compensated_demand(U, PY)) ≈ two_by_two_scalar_results["DUY.L","PL=1"]	#	49.6833066
    @test value(compensated_demand(X, PX, :t)) ≈ -two_by_two_scalar_results["SX.L","PL=1"]	#	100
    @test value(compensated_demand(Y, PY, :t)) ≈ -two_by_two_scalar_results["SY.L","PL=1"]	#	50
    @test value(compensated_demand(U, PU, :t)) ≈ -two_by_two_scalar_results["SU.L","PL=1"]	#	150
    @test value(demand(RA[:a], PU)) ≈ two_by_two_scalar_results["DURAA.L","PL=1"] 	#	78.41115477
    @test value(demand(RA[:b], PU)) ≈ two_by_two_scalar_results["DURAB.L","PL=1"] 	#	78.41115477

    set_value!(otaxa, 0.1)		
    solve!(m)		

    @test value(X)                                          ≈ two_by_two_scalar_results["X.L","Otaxa=.1"]	#	1.01168557
    @test value(Y) ≈ two_by_two_scalar_results["Y.L","Otaxa=.1"]	#	1.11236722
    @test value(U) ≈ two_by_two_scalar_results["U.L","Otaxa=.1"]	#	1.04419056
    @test value(RA[:a]) ≈ two_by_two_scalar_results["RAA.L","Otaxa=.1"]	#	94.76923035
    @test value(RA[:b]) ≈ two_by_two_scalar_results["RAB.L","Otaxa=.1"]	#	82.92307654
    @test value(PX) ≈ two_by_two_scalar_results["PX.L","Otaxa=.1"]	#	1.17093237
    @test value(PY) ≈ two_by_two_scalar_results["PY.L","Otaxa=.1"]	#	1.06494992
    @test value(PU) ≈ two_by_two_scalar_results["PU.L","Otaxa=.1"]	#	1.13448198
    @test value(PL) ≈ two_by_two_scalar_results["PL.L","Otaxa=.1"]	#	1
    @test value(PK) ≈ two_by_two_scalar_results["PK.L","Otaxa=.1"]	#	1.11057691
	#	 Implicit Variables
    @test value(compensated_demand(X, PL)) ≈ two_by_two_scalar_results["DXL.L","Otaxa=.1"]	#	52.69195654
    @test value(compensated_demand(Y, PL)) ≈ two_by_two_scalar_results["DYL.L","Otaxa=.1"]	#	47.44557166
    @test value(compensated_demand(X, PK)) ≈ two_by_two_scalar_results["DXK.L","Otaxa=.1"]	#	21.29899837
    @test value(compensated_demand(Y, PK)) ≈ two_by_two_scalar_results["DYK.L","Otaxa=.1"]	#	28.76747857
    @test value(compensated_demand(U, PX)) ≈ two_by_two_scalar_results["DUX.L","Otaxa=.1"]	#	96.88706303
    @test value(compensated_demand(U, PY)) ≈ two_by_two_scalar_results["DUY.L","Otaxa=.1"]	#	53.26456959
    @test value(compensated_demand(X, PX, :t)) ≈ -two_by_two_scalar_results["SX.L","Otaxa=.1"]	#	100
    @test value(compensated_demand(Y, PY, :t)) ≈ -two_by_two_scalar_results["SY.L","Otaxa=.1"]	#	50
    @test value(compensated_demand(U, PU, :t)) ≈ -two_by_two_scalar_results["SU.L","Otaxa=.1"]	#	150
    @test value(demand(RA[:a], PU)) ≈ two_by_two_scalar_results["DURAA.L","Otaxa=.1"] 	#	83.53524497
    @test value(demand(RA[:b], PU)) ≈ two_by_two_scalar_results["DURAB.L","Otaxa=.1"] 	#	73.09333934
		
    set_value!(otaxa, 0.2)		
    solve!(m)		
		
    @test value(X)                                          ≈ two_by_two_scalar_results["X.L","Otaxa=.2"]	#	0.96884811
    @test value(Y) ≈ two_by_two_scalar_results["Y.L","Otaxa=.2"]	#	1.19710145
    @test value(U) ≈ two_by_two_scalar_results["U.L","Otaxa=.2"]	#	1.03963474
    @test value(RA[:a]) ≈ two_by_two_scalar_results["RAA.L","Otaxa=.2"]	#	109.0833
    @test value(RA[:b]) ≈ two_by_two_scalar_results["RAB.L","Otaxa=.2"]	#	83.41666578
    @test value(PX) ≈ two_by_two_scalar_results["PX.L","Otaxa=.2"]	#	1.32459702
    @test value(PY) ≈ two_by_two_scalar_results["PY.L","Otaxa=.2"]	#	1.07203389
    @test value(PU) ≈ two_by_two_scalar_results["PU.L","Otaxa=.2"]	#	1.23440789
    @test value(PL) ≈ two_by_two_scalar_results["PL.L","Otaxa=.2"]	#	1
    @test value(PK) ≈ two_by_two_scalar_results["PK.L","Otaxa=.2"] atol=1.0e-7	#	1.12291664
	#	 Implicit Variables
    @test value(compensated_demand(X, PL)) ≈ two_by_two_scalar_results["DXL.L","Otaxa=.2"]	#	52.98388067
    @test value(compensated_demand(Y, PL)) ≈ two_by_two_scalar_results["DYL.L","Otaxa=.2"]	#	47.18416183
    @test value(compensated_demand(X, PK)) ≈ two_by_two_scalar_results["DXK.L","Otaxa=.2"]	#	21.44067764
    @test value(compensated_demand(Y, PK)) ≈ two_by_two_scalar_results["DYK.L","Otaxa=.2"]	#	28.64060891
    @test value(compensated_demand(U, PX)) ≈ two_by_two_scalar_results["DUX.L","Otaxa=.2"]	#	93.19120191
    @test value(compensated_demand(U, PY)) ≈ two_by_two_scalar_results["DUY.L","Otaxa=.2"]	#	57.57317476
    @test value(compensated_demand(X, PX, :t)) ≈ -two_by_two_scalar_results["SX.L","Otaxa=.2"]	#	100
    @test value(compensated_demand(Y, PY, :t)) ≈ -two_by_two_scalar_results["SY.L","Otaxa=.2"]	#	50
    @test value(compensated_demand(U, PU, :t)) ≈ -two_by_two_scalar_results["SU.L","Otaxa=.2"]	#	150
    @test value(demand(RA[:a], PU)) ≈ two_by_two_scalar_results["DURAA.L","Otaxa=.2"] 	#	88.36895287
    @test value(demand(RA[:b], PU)) ≈ two_by_two_scalar_results["DURAB.L","Otaxa=.2"] 	#	67.57625804
		
    set_value!(otaxa, 0.5)		
    solve!(m)		
		
    @test value(X)                                          ≈ two_by_two_scalar_results["X.L","Otaxa=.5"]	#	0.78881064
    @test value(Y) ≈ two_by_two_scalar_results["Y.L","Otaxa=.5"]	#	1.55219994
    @test value(U) ≈ two_by_two_scalar_results["U.L","Otaxa=.5"]	#	0.98847205
    @test value(RA[:a]) ≈ two_by_two_scalar_results["RAA.L","Otaxa=.5"]	#	171.1111
    @test value(RA[:b]) ≈ two_by_two_scalar_results["RAB.L","Otaxa=.5"]	#	85.55555556
    @test value(PX) ≈ two_by_two_scalar_results["PX.L","Otaxa=.5"]	#	2.16922925
    @test value(PY) ≈ two_by_two_scalar_results["PY.L","Otaxa=.5"]	#	1.10237803
    @test value(PU) ≈ two_by_two_scalar_results["PU.L","Otaxa=.5"]	#	1.73106676
    @test value(PL) ≈ two_by_two_scalar_results["PL.L","Otaxa=.5"]	#	1
    @test value(PK) ≈ two_by_two_scalar_results["PK.L","Otaxa=.5"]	#	1.17638889
	#	 Implicit Variables
    @test value(compensated_demand(X, PL)) ≈ two_by_two_scalar_results["DXL.L","Otaxa=.5"]	#	54.23073135
    @test value(compensated_demand(Y, PL)) ≈ two_by_two_scalar_results["DYL.L","Otaxa=.5"]	#	46.09932299
    @test value(compensated_demand(X, PK)) ≈ two_by_two_scalar_results["DXK.L","Otaxa=.5"]	#	22.04756055
    @test value(compensated_demand(Y, PK)) ≈ two_by_two_scalar_results["DYK.L","Otaxa=.5"]	#	28.11259197
    @test value(compensated_demand(U, PX)) ≈ two_by_two_scalar_results["DUX.L","Otaxa=.5"]	#	79.80100581
    @test value(compensated_demand(U, PY)) ≈ two_by_two_scalar_results["DUY.L","Otaxa=.5"]	#	78.51511549
    @test value(compensated_demand(X, PX, :t)) ≈ -two_by_two_scalar_results["SX.L","Otaxa=.5"]	#	100
    @test value(compensated_demand(Y, PY, :t)) ≈ -two_by_two_scalar_results["SY.L","Otaxa=.5"]	#	50
    @test value(compensated_demand(U, PU, :t)) ≈ -two_by_two_scalar_results["SU.L","Otaxa=.5"]	#	150
    @test value(demand(RA[:a], PU)) ≈ two_by_two_scalar_results["DURAA.L","Otaxa=.5"] 	#	98.84720496
    @test value(demand(RA[:b], PU)) ≈ two_by_two_scalar_results["DURAB.L","Otaxa=.5"] 	#	49.42360248
		

 
    set_value!(otaxa, 0.9)	
    solve!(m)		
		
    @test value(X) ≈ two_by_two_scalar_results["X.L","Otaxa=.9"]	#	0.26532998
    @test value(Y) ≈ two_by_two_scalar_results["Y.L","Otaxa=.9"]	#	2.57533335
    @test value(U) ≈ two_by_two_scalar_results["U.L","Otaxa=.9"]	#	0.56598124
    @test value(RA[:a]) ≈ two_by_two_scalar_results["RAA.L","Otaxa=.9"]	#	369.6
    @test value(RA[:b]) ≈ two_by_two_scalar_results["RAB.L","Otaxa=.9"]	#	92.39999999
    @test value(PX) ≈ two_by_two_scalar_results["PX.L","Otaxa=.9"]	#	11.60818677
    @test value(PY) ≈ two_by_two_scalar_results["PY.L","Otaxa=.9"]	#	1.19596168
    @test value(PU) ≈ two_by_two_scalar_results["PU.L","Otaxa=.9"]	#	5.44187647
    @test value(PL) ≈ two_by_two_scalar_results["PL.L","Otaxa=.9"]	#	1
    @test value(PK) ≈ two_by_two_scalar_results["PK.L","Otaxa=.9"]	#	1.3475
	#	 Implicit Variables
    @test value(compensated_demand(X, PL)) ≈ two_by_two_scalar_results["DXL.L","Otaxa=.9"]	#	58.04093383
    @test value(compensated_demand(Y, PL)) ≈ two_by_two_scalar_results["DYL.L","Otaxa=.9"]	#	43.07304923
    @test value(compensated_demand(X, PK)) ≈ two_by_two_scalar_results["DXK.L","Otaxa=.9"]	#	23.91923358
    @test value(compensated_demand(Y, PK)) ≈ two_by_two_scalar_results["DYK.L","Otaxa=.9"]	#	26.62623405
    @test value(compensated_demand(U, PX)) ≈ two_by_two_scalar_results["DUX.L","Otaxa=.9"]	#	46.87964264
    @test value(compensated_demand(U, PY)) ≈ two_by_two_scalar_results["DUY.L","Otaxa=.9"]	#	227.5105
    @test value(compensated_demand(X, PX, :t)) ≈ -two_by_two_scalar_results["SX.L","Otaxa=.9"]	#	100
    @test value(compensated_demand(Y, PY, :t)) ≈ -two_by_two_scalar_results["SY.L","Otaxa=.9"]	#	50
    @test value(compensated_demand(U, PU, :t)) ≈ -two_by_two_scalar_results["SU.L","Otaxa=.9"]	#	150
    @test value(demand(RA[:a], PU)) ≈ two_by_two_scalar_results["DURAA.L","Otaxa=.9"] 	#	67.91774892
    @test value(demand(RA[:b], PU)) ≈ two_by_two_scalar_results["DURAB.L","Otaxa=.9"] 	#	16.97943723

    set_value!(otaxa, 0.1)		
    set_value!(otaxb, 0.1)		
    solve!(m)		
		
    @test value(X)                                          ≈ two_by_two_scalar_results["X.L","Otax=.1"]	#	1.04880885
    @test value(Y) ≈ two_by_two_scalar_results["Y.L","Otax=.1"]	#	1.03886012
    @test value(U) ≈ two_by_two_scalar_results["U.L","Otax=.1"]	#	1.04548206
    @test value(RA[:a]) ≈ two_by_two_scalar_results["RAA.L","Otax=.1"]	#	94.72222205
    @test value(RA[:b]) ≈ two_by_two_scalar_results["RAB.L","Otax=.1"]	#	88.61111095
    @test value(PX) ≈ two_by_two_scalar_results["PX.L","Otax=.1"]	#	1.16534316
    @test value(PY) ≈ two_by_two_scalar_results["PY.L","Otax=.1"]	#	1.17650317
    @test value(PU) ≈ two_by_two_scalar_results["PU.L","Otax=.1"]	#	1.16905135
    @test value(PL) ≈ two_by_two_scalar_results["PL.L","Otax=.1"]	#	1
    @test value(PK) ≈ two_by_two_scalar_results["PK.L","Otax=.1"]	#	1.1
	#	 Implicit Variables
    @test value(compensated_demand(X, PL)) ≈ two_by_two_scalar_results["DXL.L","Otax=.1"]	#	52.44044232
    @test value(compensated_demand(Y, PL)) ≈ two_by_two_scalar_results["DYL.L","Otax=.1"]	#	47.67312955
    @test value(compensated_demand(X, PK)) ≈ two_by_two_scalar_results["DXK.L","Otax=.1"]	#	21.17705701
    @test value(compensated_demand(Y, PK)) ≈ two_by_two_scalar_results["DYK.L","Otax=.1"]	#	28.87780512
    @test value(compensated_demand(U, PX)) ≈ two_by_two_scalar_results["DUX.L","Otax=.1"]	#	100.3182
    @test value(compensated_demand(U, PY)) ≈ two_by_two_scalar_results["DUY.L","Otax=.1"]	#	49.68330662
    @test value(compensated_demand(X, PX, :t)) ≈ -two_by_two_scalar_results["SX.L","Otax=.1"]	#	100
    @test value(compensated_demand(Y, PY, :t)) ≈ -two_by_two_scalar_results["SY.L","Otax=.1"]	#	50
    @test value(compensated_demand(U, PU, :t)) ≈ -two_by_two_scalar_results["SU.L","Otax=.1"]	#	150
    @test value(demand(RA[:a], PU)) ≈ two_by_two_scalar_results["DURAA.L","Otax=.1"] 	#	81.02485989
    @test value(demand(RA[:b], PU)) ≈ two_by_two_scalar_results["DURAB.L","Otax=.1"] 	#	75.79744957
		
    set_value!(otaxa, 0.2)		
    set_value!(otaxb, 0.2)		
    solve!(m)		
		
    @test value(X)                                          ≈ two_by_two_scalar_results["X.L","Otax=.2"]	#	1.04880885
    @test value(Y) ≈ two_by_two_scalar_results["Y.L","Otax=.2"]	#	1.03886012
    @test value(U) ≈ two_by_two_scalar_results["U.L","Otax=.2"]	#	1.04548206
    @test value(RA[:a]) ≈ two_by_two_scalar_results["RAA.L","Otax=.2"]	#	110
    @test value(RA[:b]) ≈ two_by_two_scalar_results["RAB.L","Otax=.2"]	#	96.25
    @test value(PX) ≈ two_by_two_scalar_results["PX.L","Otax=.2"]	#	1.31101106
    @test value(PY) ≈ two_by_two_scalar_results["PY.L","Otax=.2"]	#	1.32356607
    @test value(PU) ≈ two_by_two_scalar_results["PU.L","Otax=.2"]	#	1.31518277
    @test value(PL) ≈ two_by_two_scalar_results["PL.L","Otax=.2"]	#	1
    @test value(PK) ≈ two_by_two_scalar_results["PK.L","Otax=.2"] atol=1.0e-7	#	1.1
	#	 Implicit Variables
    @test value(compensated_demand(X, PL)) ≈ two_by_two_scalar_results["DXL.L","Otax=.2"]	#	52.44044241
    @test value(compensated_demand(Y, PL)) ≈ two_by_two_scalar_results["DYL.L","Otax=.2"]	#	47.67312946
    @test value(compensated_demand(X, PK)) ≈ two_by_two_scalar_results["DXK.L","Otax=.2"]	#	21.17705706
    @test value(compensated_demand(Y, PK)) ≈ two_by_two_scalar_results["DYK.L","Otax=.2"]	#	28.87780508
    @test value(compensated_demand(U, PX)) ≈ two_by_two_scalar_results["DUX.L","Otax=.2"]	#	100.3182
    @test value(compensated_demand(U, PY)) ≈ two_by_two_scalar_results["DUY.L","Otax=.2"]	#	49.6833066
    @test value(compensated_demand(X, PX, :t)) ≈ -two_by_two_scalar_results["SX.L","Otax=.2"]	#	100
    @test value(compensated_demand(Y, PY, :t)) ≈ -two_by_two_scalar_results["SY.L","Otax=.2"]	#	50
    @test value(compensated_demand(U, PU, :t)) ≈ -two_by_two_scalar_results["SU.L","Otax=.2"]	#	150
    @test value(demand(RA[:a], PU)) ≈ two_by_two_scalar_results["DURAA.L","Otax=.2"] 	#	83.63856509
    @test value(demand(RA[:b], PU)) ≈ two_by_two_scalar_results["DURAB.L","Otax=.2"] 	#	73.18374445
		
    set_value!(otaxa, 0.5)		
    set_value!(otaxb, 0.5)		
    solve!(m)		
		
    @test value(X) ≈ two_by_two_scalar_results["X.L","Otax=.5"]	#	1.04880885
    @test value(Y) ≈ two_by_two_scalar_results["Y.L","Otax=.5"]	#	1.03886012
    @test value(U) ≈ two_by_two_scalar_results["U.L","Otax=.5"]	#	1.04548206
    @test value(RA[:a]) ≈ two_by_two_scalar_results["RAA.L","Otax=.5"]	#	192.5
    @test value(RA[:b]) ≈ two_by_two_scalar_results["RAB.L","Otax=.5"]	#	137.5
    @test value(PX) ≈ two_by_two_scalar_results["PX.L","Otax=.5"]	#	2.0976177
    @test value(PY) ≈ two_by_two_scalar_results["PY.L","Otax=.5"]	#	2.11770571
    @test value(PU) ≈ two_by_two_scalar_results["PU.L","Otax=.5"]	#	2.10429244
    @test value(PL) ≈ two_by_two_scalar_results["PL.L","Otax=.5"]	#	1
    @test value(PK) ≈ two_by_two_scalar_results["PK.L","Otax=.5"]	#	1.1
	#	 Implicit Variables
    @test value(compensated_demand(X, PL)) ≈ two_by_two_scalar_results["DXL.L","Otax=.5"]	#	52.4404424
    @test value(compensated_demand(Y, PL)) ≈ two_by_two_scalar_results["DYL.L","Otax=.5"]	#	47.67312947
    @test value(compensated_demand(X, PK)) ≈ two_by_two_scalar_results["DXK.L","Otax=.5"]	#	21.17705706
    @test value(compensated_demand(Y, PK)) ≈ two_by_two_scalar_results["DYK.L","Otax=.5"]	#	28.87780508
    @test value(compensated_demand(U, PX)) ≈ two_by_two_scalar_results["DUX.L","Otax=.5"]	#	100.3182
    @test value(compensated_demand(U, PY)) ≈ two_by_two_scalar_results["DUY.L","Otax=.5"]	#	49.6833066
    @test value(compensated_demand(X, PX, :t)) ≈ -two_by_two_scalar_results["SX.L","Otax=.5"]	#	100
    @test value(compensated_demand(Y, PY, :t)) ≈ -two_by_two_scalar_results["SY.L","Otax=.5"]	#	50
    @test value(compensated_demand(U, PU, :t)) ≈ -two_by_two_scalar_results["SU.L","Otax=.5"]	#	150
    @test value(demand(RA[:a], PU)) ≈ two_by_two_scalar_results["DURAA.L","Otax=.5"] 	#	91.47968056
    @test value(demand(RA[:b], PU)) ≈ two_by_two_scalar_results["DURAB.L","Otax=.5"] 	#	65.34262897
		
    set_value!(otaxa, 0.9)		
    set_value!(otaxb, 0.9)		
    solve!(m)		
		
    @test value(X) ≈ two_by_two_scalar_results["X.L","Otax=.9"]	#	1.04880885
    @test value(Y) ≈ two_by_two_scalar_results["Y.L","Otax=.9"]	#	1.03886012
    @test value(U) ≈ two_by_two_scalar_results["U.L","Otax=.9"]	#	1.04548206
    @test value(RA[:a]) ≈ two_by_two_scalar_results["RAA.L","Otax=.9"]	#	1072.5
    @test value(RA[:b]) ≈ two_by_two_scalar_results["RAB.L","Otax=.9"]	#	577.5
    @test value(PX) ≈ two_by_two_scalar_results["PX.L","Otax=.9"]	#	10.48808848
    @test value(PY) ≈ two_by_two_scalar_results["PY.L","Otax=.9"]	#	10.58852853
    @test value(PU) ≈ two_by_two_scalar_results["PU.L","Otax=.9"]	#	10.52146219
    @test value(PL) ≈ two_by_two_scalar_results["PL.L","Otax=.9"]	#	1
    @test value(PK) ≈ two_by_two_scalar_results["PK.L","Otax=.9"]	#	1.1
	#	 Implicit Variables
    @test value(compensated_demand(X, PL)) ≈ two_by_two_scalar_results["DXL.L","Otax=.9"]	#	52.44044241
    @test value(compensated_demand(Y, PL)) ≈ two_by_two_scalar_results["DYL.L","Otax=.9"]	#	47.67312946
    @test value(compensated_demand(X, PK)) ≈ two_by_two_scalar_results["DXK.L","Otax=.9"]	#	21.17705706
    @test value(compensated_demand(Y, PK)) ≈ two_by_two_scalar_results["DYK.L","Otax=.9"]	#	28.87780508
    @test value(compensated_demand(U, PX)) ≈ two_by_two_scalar_results["DUX.L","Otax=.9"]	#	100.3182
    @test value(compensated_demand(U, PY)) ≈ two_by_two_scalar_results["DUY.L","Otax=.9"]	#	49.6833066
    @test value(compensated_demand(X, PX, :t)) ≈ -two_by_two_scalar_results["SX.L","Otax=.9"]	#	100
    @test value(compensated_demand(Y, PY, :t)) ≈ -two_by_two_scalar_results["SY.L","Otax=.9"]	#	50
    @test value(compensated_demand(U, PU, :t)) ≈ -two_by_two_scalar_results["SU.L","Otax=.9"]	#	150
    @test value(demand(RA[:a], PU)) ≈ two_by_two_scalar_results["DURAA.L","Otax=.9"] 	#	101.9345
    @test value(demand(RA[:b], PU)) ≈ two_by_two_scalar_results["DURAB.L","Otax=.9"] 	#	54.88780834
  		
    
end		



@testitem "TWObyTWOwOutTax_tr_elas" begin

    using XLSX, MPSGE.JuMP.Containers
    import JuMP
    
    # A replication of the Two By Two Scalar, with an output Tax and non-0 transformation elasticities in counterfactual: TwobyTwo_OutTax1-2Sectors.gms
    m = MPSGEModel()
    

    @parameter(m, diff, 0.0)
    @parameter(m, sub_elas_a, 0.)
    @parameter(m, sub_elas_b, 0.)
    @parameter(m, sub_elas_w, 0.)
    @parameter(m, t_elas_a, 0.0)
    @parameter(m, t_elas_b, 0.0)
    @parameter(m, otax1, 0.0)
    @parameter(m, otax2, 0.0)
    @parameter(m, otax3, 0.0)
    @parameter(m, otax4, 0.0)
    @parameter(m, itax, 0.0)
    
    
    @sector(m, A)
    @sector(m, B)
    @sector(m, W)
    
    @commodity(m, PX)
    @commodity(m, PY)
    @commodity(m, PW)
    @commodity(m, PL)
    @commodity(m, PK)
    
    @consumer(m, CONS)
    
    @production(m, A, [t = t_elas_a, s = sub_elas_a], begin
        @output(PX, 80, t, taxes=[Tax(CONS, otax1)]) 
        @output(PY, 20, t, taxes=[Tax(CONS, otax2)])
        @input(PL, 40, s, taxes=[Tax(CONS, itax)])
        @input(PK, 60, s, taxes=[Tax(CONS, itax)])
    end)

    @production(m, B, [t = t_elas_b, s = sub_elas_b], begin
        @output(PX, 20, t, taxes=[Tax(CONS, otax3)])
        @output(PY, 80, t, taxes=[Tax(CONS, otax4)])
        @input(PL, 60, s)
        @input(PK, 40, s)
    end)
            

    @production(m, W, [t = 0, s = sub_elas_w], begin
        @output(PW, 200, t)
        @input(PX, 100, s) 
        @input(PY, 100, s)
    end)


    @demand(m, CONS, begin
            @final_demand(PW, 200.)
            @endowment(PL, 100.0)
            @endowment(PK, 100.0)
    end)
    
    solve!(m, cumulative_iteration_limit=0)

    gams_results = XLSX.readxlsx(joinpath(@__DIR__, "MPSGEresults.xlsx"))
    a_table = gams_results["TwoxTwoOutTax_1-2"][:]  # Generated from TwoxTwoOutTax_1-2.gms
    two_by_two_scalar_results = DenseAxisArray(a_table[2:end,2:end],a_table[2:end,1],a_table[1,2:end])

    @test value(A) ≈ two_by_two_scalar_results["A.L","benchmark"]#  1
    @test value(B) ≈ two_by_two_scalar_results["B.L","benchmark"]#  1
    @test value(W) ≈ two_by_two_scalar_results["W.L","benchmark"]#  1
    @test value(PX) ≈ two_by_two_scalar_results["PX.L","benchmark"]#  1
    @test value(PY) ≈ two_by_two_scalar_results["PY.L","benchmark"]#  1
    @test value(PW) ≈ two_by_two_scalar_results["PW.L","benchmark"]#  1
    @test value(PL) ≈ two_by_two_scalar_results["PL.L","benchmark"]#  1
    @test value(PK) ≈ two_by_two_scalar_results["PK.L","benchmark"]#  1
    @test value(CONS) ≈ two_by_two_scalar_results["CONS.L","benchmark"]#  200
    @test value(compensated_demand(A, PX, :t)) ≈ -two_by_two_scalar_results["SAX.L","benchmark"]#  80
    @test value(compensated_demand(A, PY, :t)) ≈ -two_by_two_scalar_results["SAY.L","benchmark"]#  20
    @test value(compensated_demand(B, PX, :t)) ≈ -two_by_two_scalar_results["SBX.L","benchmark"]#  20
    @test value(compensated_demand(B, PY, :t)) ≈ -two_by_two_scalar_results["SBY.L","benchmark"]#  80
    @test value(compensated_demand(A, PL)) ≈ two_by_two_scalar_results["DAL.L","benchmark"]#  40
    @test value(compensated_demand(A, PK)) ≈ two_by_two_scalar_results["DAK.L","benchmark"]#  60
    @test value(compensated_demand(B, PL)) ≈ two_by_two_scalar_results["DBL.L","benchmark"]#  60
    @test value(compensated_demand(B, PK)) ≈ two_by_two_scalar_results["DBK.L","benchmark"]#  40
    @test value(compensated_demand(W, PW, :t)) ≈ -two_by_two_scalar_results["SW.L","benchmark"]#  200
    @test value(compensated_demand(W, PX)) ≈ two_by_two_scalar_results["DWX.L","benchmark"]#  100
    @test value(compensated_demand(W, PY)) ≈ two_by_two_scalar_results["DWY.L","benchmark"]#  100
    @test value(demand(CONS, PW)) ≈ two_by_two_scalar_results["DW.L","benchmark"]#  200
    # CWI ")]) ≈ two_by_two_scalar_results["CWI.L","benchmark"]#  1
        
    set_value!(otax1, 0.1)
    fix(CONS, 200)
    fix(PW, 1)
    solve!(m)

    @test value(A) ≈ two_by_two_scalar_results["A.L","OUTTAX=0.1"]#  1
    @test value(B) ≈ two_by_two_scalar_results["B.L","OUTTAX=0.1"]#  1
    @test value(W) ≈ two_by_two_scalar_results["W.L","OUTTAX=0.1"]#  1
    @test value(PX) ≈ two_by_two_scalar_results["PX.L","OUTTAX=0.1"]#  1.06382979
    @test value(PY) ≈ two_by_two_scalar_results["PY.L","OUTTAX=0.1"]#  0.93617021
    @test value(PW) ≈ two_by_two_scalar_results["PW.L","OUTTAX=0.1"]#  1
    @test value(PL) ≈ two_by_two_scalar_results["PL.L","OUTTAX=0.1"]#  0.9787234
    @test value(PK) ≈ two_by_two_scalar_results["PK.L","OUTTAX=0.1"]#  0.93617021
    @test value(CONS) ≈ two_by_two_scalar_results["CONS.L","OUTTAX=0.1"]#  200
    @test value(compensated_demand(A, PX, :t)) ≈ -two_by_two_scalar_results["SAX.L","OUTTAX=0.1"]#  80
    @test value(compensated_demand(A, PY, :t)) ≈ -two_by_two_scalar_results["SAY.L","OUTTAX=0.1"]#  20
    @test value(compensated_demand(B, PX, :t)) ≈ -two_by_two_scalar_results["SBX.L","OUTTAX=0.1"]#  20
    @test value(compensated_demand(B, PY, :t)) ≈ -two_by_two_scalar_results["SBY.L","OUTTAX=0.1"]#  80
    @test value(compensated_demand(A, PL)) ≈ two_by_two_scalar_results["DAL.L","OUTTAX=0.1"]#  40
    @test value(compensated_demand(A, PK)) ≈ two_by_two_scalar_results["DAK.L","OUTTAX=0.1"]#  60
    @test value(compensated_demand(B, PL)) ≈ two_by_two_scalar_results["DBL.L","OUTTAX=0.1"]#  60
    @test value(compensated_demand(B, PK)) ≈ two_by_two_scalar_results["DBK.L","OUTTAX=0.1"]#  40
    @test value(compensated_demand(W, PW, :t)) ≈ -two_by_two_scalar_results["SW.L","OUTTAX=0.1"]#  200
    @test value(compensated_demand(W, PX)) ≈ two_by_two_scalar_results["DWX.L","OUTTAX=0.1"]#  100
    @test value(compensated_demand(W, PY)) ≈ two_by_two_scalar_results["DWY.L","OUTTAX=0.1"]#  100
    @test value(demand(CONS, PW)) ≈ two_by_two_scalar_results["DW.L","OUTTAX=0.1"]#  200
    # CWI ")]) ≈ two_by_two_scalar_results["CWI.L","OUTTAX=0.1"]#  1
    
    
    unfix(PW)
    set_value!(sub_elas_a, 1.0)
    set_value!(sub_elas_b, 1.)
    set_value!(sub_elas_w, 1.)
    solve!(m)
    
    @test value(A) ≈ two_by_two_scalar_results["A.L","SUBes=1"]#  0.89337249
    @test value(B) ≈ two_by_two_scalar_results["B.L","SUBes=1"]#  1.1061559
    @test value(W) ≈ two_by_two_scalar_results["W.L","SUBes=1"]#  0.99772418
    @test value(PX) ≈ two_by_two_scalar_results["PX.L","SUBes=1"]#  1.06845692
    @test value(PY) ≈ two_by_two_scalar_results["PY.L","SUBes=1"]#  0.94020378
    @test value(PW) ≈ two_by_two_scalar_results["PW.L","SUBes=1"]#  1.00228101
    @test value(PL) ≈ two_by_two_scalar_results["PL.L","SUBes=1"]#  0.98313215
    @test value(PK) ≈ two_by_two_scalar_results["PK.L","SUBes=1"]#  0.94050545
    @test value(CONS) ≈ two_by_two_scalar_results["CONS.L","SUBes=1"]#  200
    @test value(compensated_demand(A, PX, :t)) ≈ -two_by_two_scalar_results["SAX.L","SUBes=1"]#  80
    @test value(compensated_demand(A, PY, :t)) ≈ -two_by_two_scalar_results["SAY.L","SUBes=1"]#  20
    @test value(compensated_demand(B, PX, :t)) ≈ -two_by_two_scalar_results["SBX.L","SUBes=1"]#  20
    @test value(compensated_demand(B, PY, :t)) ≈ -two_by_two_scalar_results["SBY.L","SUBes=1"]#  80
    @test value(compensated_demand(A, PL)) ≈ two_by_two_scalar_results["DAL.L","SUBes=1"]#  38.95019557
    @test value(compensated_demand(A, PK)) ≈ two_by_two_scalar_results["DAK.L","SUBes=1"]#  61.07331347
    @test value(compensated_demand(B, PL)) ≈ two_by_two_scalar_results["DBL.L","SUBes=1"]#  58.94554913
    @test value(compensated_demand(B, PK)) ≈ two_by_two_scalar_results["DBK.L","SUBes=1"]#  41.07809926
    @test value(compensated_demand(W, PW, :t)) ≈ -two_by_two_scalar_results["SW.L","SUBes=1"]#  200
    @test value(compensated_demand(W, PX)) ≈ two_by_two_scalar_results["DWX.L","SUBes=1"]#  93.8064041
    @test value(compensated_demand(W, PY)) ≈ two_by_two_scalar_results["DWY.L","SUBes=1"]#  106.6025
    @test value(demand(CONS, PW)) ≈ two_by_two_scalar_results["DW.L","SUBes=1"]#  199.5448
    # CWI ")]) ≈ two_by_two_scalar_results["CWI.L","SUBes=1"]#  0.99772418
        
    fix(PW, 1)
    unfix(CONS)
    solve!(m)
    
    @test value(A) ≈ two_by_two_scalar_results["A.L","PW.FX=1"]#  0.89337249
    @test value(B) ≈ two_by_two_scalar_results["B.L","PW.FX=1"]#  1.1061559
    @test value(W) ≈ two_by_two_scalar_results["W.L","PW.FX=1"]#  0.99772418
    @test value(PX) ≈ two_by_two_scalar_results["PX.L","PW.FX=1"]#  1.0660253
    @test value(PY) ≈ two_by_two_scalar_results["PY.L","PW.FX=1"]#  0.93806404
    @test value(PW) ≈ two_by_two_scalar_results["PW.L","PW.FX=1"]#  1
    @test value(PL) ≈ two_by_two_scalar_results["PL.L","PW.FX=1"]#  0.98089471
    @test value(PK) ≈ two_by_two_scalar_results["PK.L","PW.FX=1"]#  0.93836503
    @test value(CONS) ≈ two_by_two_scalar_results["CONS.L","PW.FX=1"]#  199.5448
    @test value(compensated_demand(A, PX, :t)) ≈ -two_by_two_scalar_results["SAX.L","PW.FX=1"]#  80
    @test value(compensated_demand(A, PY, :t)) ≈ -two_by_two_scalar_results["SAY.L","PW.FX=1"]#  20
    @test value(compensated_demand(B, PX, :t)) ≈ -two_by_two_scalar_results["SBX.L","PW.FX=1"]#  20
    @test value(compensated_demand(B, PY, :t)) ≈ -two_by_two_scalar_results["SBY.L","PW.FX=1"]#  80
    @test value(compensated_demand(A, PL)) ≈ two_by_two_scalar_results["DAL.L","PW.FX=1"]#  38.95019557
    @test value(compensated_demand(A, PK)) ≈ two_by_two_scalar_results["DAK.L","PW.FX=1"]#  61.07331347
    @test value(compensated_demand(B, PL)) ≈ two_by_two_scalar_results["DBL.L","PW.FX=1"]#  58.94554913
    @test value(compensated_demand(B, PK)) ≈ two_by_two_scalar_results["DBK.L","PW.FX=1"]#  41.07809926
    @test value(compensated_demand(W, PW, :t)) ≈ -two_by_two_scalar_results["SW.L","PW.FX=1"]#  200
    @test value(compensated_demand(W, PX)) ≈ two_by_two_scalar_results["DWX.L","PW.FX=1"]#  93.8064041
    @test value(compensated_demand(W, PY)) ≈ two_by_two_scalar_results["DWY.L","PW.FX=1"]#  106.6025
    @test value(demand(CONS, PW)) ≈ two_by_two_scalar_results["DW.L","PW.FX=1"]#  199.5448
    # CWI ")]) ≈ two_by_two_scalar_results["CWI.L","PW.FX=1"]#  0.99772418

    set_value!(otax1, 0.2)
    solve!(m)
    
    @test value(A) ≈ two_by_two_scalar_results["A.L","OUTTAX=0.2"]#  0.77047179
    @test value(B) ≈ two_by_two_scalar_results["B.L","OUTTAX=0.2"]#  1.22735428
    @test value(W) ≈ two_by_two_scalar_results["W.L","OUTTAX=0.2"]#  0.98946476
    @test value(PX) ≈ two_by_two_scalar_results["PX.L","OUTTAX=0.2"]#  1.14807301
    @test value(PY) ≈ two_by_two_scalar_results["PY.L","OUTTAX=0.2"]#  0.87102475
    @test value(PW) ≈ two_by_two_scalar_results["PW.L","OUTTAX=0.2"]#  1
    @test value(PL) ≈ two_by_two_scalar_results["PL.L","OUTTAX=0.2"]#  0.96237275
    @test value(PK) ≈ two_by_two_scalar_results["PK.L","OUTTAX=0.2"]#  0.87502751
    @test value(CONS) ≈ two_by_two_scalar_results["CONS.L","OUTTAX=0.2"]#  197.893
    @test value(compensated_demand(A, PX, :t)) ≈ -two_by_two_scalar_results["SAX.L","OUTTAX=0.2"]#  80
    @test value(compensated_demand(A, PY, :t)) ≈ -two_by_two_scalar_results["SAY.L","OUTTAX=0.2"]#  20
    @test value(compensated_demand(B, PX, :t)) ≈ -two_by_two_scalar_results["SBX.L","OUTTAX=0.2"]#  20
    @test value(compensated_demand(B, PY, :t)) ≈ -two_by_two_scalar_results["SBY.L","OUTTAX=0.2"]#  80
    @test value(compensated_demand(A, PL)) ≈ two_by_two_scalar_results["DAL.L","OUTTAX=0.2"]#  37.78044124
    @test value(compensated_demand(A, PK)) ≈ two_by_two_scalar_results["DAK.L","OUTTAX=0.2"]#  62.32752679
    @test value(compensated_demand(B, PL)) ≈ two_by_two_scalar_results["DBL.L","OUTTAX=0.2"]#  57.75939116
    @test value(compensated_demand(B, PK)) ≈ two_by_two_scalar_results["DBK.L","OUTTAX=0.2"]#  42.34995536
    @test value(compensated_demand(W, PW, :t)) ≈ -two_by_two_scalar_results["SW.L","OUTTAX=0.2"]#  200
    @test value(compensated_demand(W, PX)) ≈ two_by_two_scalar_results["DWX.L","OUTTAX=0.2"]#  87.10247453
    @test value(compensated_demand(W, PY)) ≈ two_by_two_scalar_results["DWY.L","OUTTAX=0.2"]#  114.8073
    @test value(demand(CONS, PW)) ≈ two_by_two_scalar_results["DW.L","OUTTAX=0.2"]#  197.893
    # CWI ")]) ≈ two_by_two_scalar_results["CWI.L","OUTTAX=0.2"]#  0.98946476

    set_value!(t_elas_a, 3.0)
    set_value!(t_elas_b, 1.0)
    solve!(m)

    @test value(A) ≈ two_by_two_scalar_results["A.L","TrA=3B=1"]#  0.64533631
    @test value(B) ≈ two_by_two_scalar_results["B.L","TrA=3B=1"]#  1.34950119
    @test value(W) ≈ two_by_two_scalar_results["W.L","TrA=3B=1"]#  0.9838439
    @test value(PX) ≈ two_by_two_scalar_results["PX.L","TrA=3B=1"]#  1.14393203
    @test value(PY) ≈ two_by_two_scalar_results["PY.L","TrA=3B=1"]#  0.87417782
    @test value(PW) ≈ two_by_two_scalar_results["PW.L","TrA=3B=1"]#  1
    @test value(PL) ≈ two_by_two_scalar_results["PL.L","TrA=3B=1"]#  0.99079613
    @test value(PK) ≈ two_by_two_scalar_results["PK.L","TrA=3B=1"]#  0.85572088
    @test value(CONS) ≈ two_by_two_scalar_results["CONS.L","TrA=3B=1"]#  196.7688
    @test value(compensated_demand(A, PX, :t)) ≈ -two_by_two_scalar_results["SAX.L","TrA=3B=1"]#  82.06946612
    @test value(compensated_demand(A, PY, :t)) ≈ -two_by_two_scalar_results["SAY.L","TrA=3B=1"]#  17.88341039
    @test value(compensated_demand(B, PX, :t)) ≈ -two_by_two_scalar_results["SBX.L","TrA=3B=1"]#  24.48537622
    @test value(compensated_demand(B, PY, :t)) ≈ -two_by_two_scalar_results["SBY.L","TrA=3B=1"]#  74.84561046
    @test value(compensated_demand(A, PL)) ≈ two_by_two_scalar_results["DAL.L","TrA=3B=1"]#  36.63267965
    @test value(compensated_demand(A, PK)) ≈ two_by_two_scalar_results["DAK.L","TrA=3B=1"]#  63.62270345
    @test value(compensated_demand(B, PL)) ≈ two_by_two_scalar_results["DBL.L","TrA=3B=1"]#  56.5835748
    @test value(compensated_demand(B, PK)) ≈ two_by_two_scalar_results["DBK.L","TrA=3B=1"]#  43.67684852
    @test value(compensated_demand(W, PW, :t)) ≈ -two_by_two_scalar_results["SW.L","TrA=3B=1"]#  200
    @test value(compensated_demand(W, PX)) ≈ two_by_two_scalar_results["DWX.L","TrA=3B=1"]#  87.41778159
    @test value(compensated_demand(W, PY)) ≈ two_by_two_scalar_results["DWY.L","TrA=3B=1"]#  114.3932
    @test value(demand(CONS, PW)) ≈ two_by_two_scalar_results["DW.L","TrA=3B=1"]#  196.7688
    # CWI ")]) ≈ two_by_two_scalar_results["CWI.L","TrA=3B=1"]#  0.9838439

    set_value!(t_elas_a, 1.0)
    set_value!(t_elas_b, 1.0)
    solve!(m)

    @test value(A) ≈ two_by_two_scalar_results["A.L","TrA/B=1"]#  0.65743472
    @test value(B) ≈ two_by_two_scalar_results["B.L","TrA/B=1"]#  1.33774645
    @test value(W) ≈ two_by_two_scalar_results["W.L","TrA/B=1"]#  0.98388691
    @test value(PX) ≈ two_by_two_scalar_results["PX.L","TrA/B=1"]#  1.14538803
    @test value(PY) ≈ two_by_two_scalar_results["PY.L","TrA/B=1"]#  0.87306657
    @test value(PW) ≈ two_by_two_scalar_results["PW.L","TrA/B=1"]#  1
    @test value(PL) ≈ two_by_two_scalar_results["PL.L","TrA/B=1"]#  0.98833168
    @test value(PK) ≈ two_by_two_scalar_results["PK.L","TrA/B=1"]#  0.85783333
    @test value(CONS) ≈ two_by_two_scalar_results["CONS.L","TrA/B=1"]#  196.7774
    @test value(compensated_demand(A, PX, :t)) ≈ -two_by_two_scalar_results["SAX.L","TrA/B=1"]#  80.74762872
    @test value(compensated_demand(A, PY, :t)) ≈ -two_by_two_scalar_results["SAY.L","TrA/B=1"]#  19.23421727
    @test value(compensated_demand(B, PX, :t)) ≈ -two_by_two_scalar_results["SBX.L","TrA/B=1"]#  24.52899978
    @test value(compensated_demand(B, PY, :t)) ≈ -two_by_two_scalar_results["SBY.L","TrA/B=1"]#  74.78845284
    @test value(compensated_demand(A, PL)) ≈ two_by_two_scalar_results["DAL.L","TrA/B=1"]#  36.74177319
    @test value(compensated_demand(A, PK)) ≈ two_by_two_scalar_results["DAK.L","TrA/B=1"]#  63.49670218
    @test value(compensated_demand(B, PL)) ≈ two_by_two_scalar_results["DBL.L","TrA/B=1"]#  56.69585784
    @test value(compensated_demand(B, PK)) ≈ two_by_two_scalar_results["DBK.L","TrA/B=1"]#  43.54716338
    @test value(compensated_demand(W, PW, :t)) ≈ -two_by_two_scalar_results["SW.L","TrA/B=1"]#  200
    @test value(compensated_demand(W, PX)) ≈ two_by_two_scalar_results["DWX.L","TrA/B=1"]#  87.30665698
    @test value(compensated_demand(W, PY)) ≈ two_by_two_scalar_results["DWY.L","TrA/B=1"]#  114.5388
    @test value(demand(CONS, PW)) ≈ two_by_two_scalar_results["DW.L","TrA/B=1"]#  196.7774
    # CWI ")]) ≈ two_by_two_scalar_results["CWI.L","TrA/B=1"]#  0.98388691

    set_value!(t_elas_a, 2.0)
    set_value!(t_elas_b, 1.5)
    solve!(m)

    @test value(A) ≈ two_by_two_scalar_results["A.L","S1Tr2,1.5"]#  0.59043553
    @test value(B) ≈ two_by_two_scalar_results["B.L","S1Tr2,1.5"]#  1.40269647
    @test value(W) ≈ two_by_two_scalar_results["W.L","S1Tr2,1.5"]#  0.98045634
    @test value(PX) ≈ two_by_two_scalar_results["PX.L","S1Tr2,1.5"]#  1.14305464
    @test value(PY) ≈ two_by_two_scalar_results["PY.L","S1Tr2,1.5"]#  0.87484882
    @test value(PW) ≈ two_by_two_scalar_results["PW.L","S1Tr2,1.5"]#  1
    @test value(PL) ≈ two_by_two_scalar_results["PL.L","S1Tr2,1.5"]#  1.0035789
    @test value(PK) ≈ two_by_two_scalar_results["PK.L","S1Tr2,1.5"]#  0.84752137
    @test value(CONS) ≈ two_by_two_scalar_results["CONS.L","S1Tr2,1.5"]#  196.0913
    @test value(compensated_demand(A, PX, :t)) ≈ -two_by_two_scalar_results["SAX.L","S1Tr2,1.5"]#  81.35456661
    @test value(compensated_demand(A, PY, :t)) ≈ -two_by_two_scalar_results["SAY.L","S1Tr2,1.5"]#  18.61547012
    @test value(compensated_demand(B, PX, :t)) ≈ -two_by_two_scalar_results["SBX.L","S1Tr2,1.5"]#  26.90566422
    @test value(compensated_demand(B, PY, :t)) ≈ -two_by_two_scalar_results["SBY.L","S1Tr2,1.5"]#  72.06140704
    @test value(compensated_demand(A, PL)) ≈ two_by_two_scalar_results["DAL.L","S1Tr2,1.5"]#  36.14260684
    @test value(compensated_demand(A, PK)) ≈ two_by_two_scalar_results["DAK.L","S1Tr2,1.5"]#  64.19653617
    @test value(compensated_demand(B, PL)) ≈ two_by_two_scalar_results["DBL.L","S1Tr2,1.5"]#  56.07779197
    @test value(compensated_demand(B, PK)) ≈ two_by_two_scalar_results["DBK.L","S1Tr2,1.5"]#  44.26908128
    @test value(compensated_demand(W, PW, :t)) ≈ -two_by_two_scalar_results["SW.L","S1Tr2,1.5"]#  200
    @test value(compensated_demand(W, PX)) ≈ two_by_two_scalar_results["DWX.L","S1Tr2,1.5"]#  87.48488182
    @test value(compensated_demand(W, PY)) ≈ two_by_two_scalar_results["DWY.L","S1Tr2,1.5"]#  114.3055
    @test value(demand(CONS, PW)) ≈ two_by_two_scalar_results["DW.L","S1Tr2,1.5"]#  196.0913
    # CWI ")]) ≈ two_by_two_scalar_results["CWI.L","S1Tr2,1.5"]#  0.98045634

    set_value!(sub_elas_a, 0.)
    set_value!(sub_elas_b, 0.)
    set_value!(sub_elas_w, 0.)
    set_value!(t_elas_a, 3.0)
    set_value!(t_elas_b, 1.0)
    solve!(m)
     
    @test value(A) ≈ two_by_two_scalar_results["A.L","S0Tr=3,1"]#  1
    @test value(B) ≈ two_by_two_scalar_results["B.L","S0Tr=3,1"]#  1
    @test value(W) ≈ two_by_two_scalar_results["W.L","S0Tr=3,1"]#  0.99836642
    @test value(PX) ≈ two_by_two_scalar_results["PX.L","S0Tr=3,1"]#  1.08317338
    @test value(PY) ≈ two_by_two_scalar_results["PY.L","S0Tr=3,1"]#  0.91682662
    @test value(PW) ≈ two_by_two_scalar_results["PW.L","S0Tr=3,1"]#  1
    @test value(PL) ≈ two_by_two_scalar_results["PL.L","S0Tr=3,1"]#  1.10266152
    @test value(PK) ≈ two_by_two_scalar_results["PK.L","S0Tr=3,1"]#  0.72706546
    @test value(CONS) ≈ two_by_two_scalar_results["CONS.L","S0Tr=3,1"]#  199.6733
    @test value(compensated_demand(A, PX, :t)) ≈ -two_by_two_scalar_results["SAX.L","S0Tr=3,1"]#  77.09100751
    @test value(compensated_demand(A, PY, :t)) ≈ -two_by_two_scalar_results["SAY.L","S0Tr=3,1"]#  22.82661349
    @test value(compensated_demand(B, PX, :t)) ≈ -two_by_two_scalar_results["SBX.L","S0Tr=3,1"]#  22.74563436
    @test value(compensated_demand(B, PY, :t)) ≈ -two_by_two_scalar_results["SBY.L","S0Tr=3,1"]#  77.01002838
    @test value(compensated_demand(A, PL)) ≈ two_by_two_scalar_results["DAL.L","S0Tr=3,1"]#  40
    @test value(compensated_demand(A, PK)) ≈ two_by_two_scalar_results["DAK.L","S0Tr=3,1"]#  60
    @test value(compensated_demand(B, PL)) ≈ two_by_two_scalar_results["DBL.L","S0Tr=3,1"]#  60
    @test value(compensated_demand(B, PK)) ≈ two_by_two_scalar_results["DBK.L","S0Tr=3,1"]#  40
    @test value(compensated_demand(W, PW, :t)) ≈ -two_by_two_scalar_results["SW.L","S0Tr=3,1"]#  200
    @test value(compensated_demand(W, PX)) ≈ two_by_two_scalar_results["DWX.L","S0Tr=3,1"]#  100
    @test value(compensated_demand(W, PY)) ≈ two_by_two_scalar_results["DWY.L","S0Tr=3,1"]#  100
    @test value(demand(CONS, PW)) ≈ two_by_two_scalar_results["DW.L","S0Tr=3,1"]#  199.6733
    # CWI ")]) ≈ two_by_two_scalar_results["CWI.L","S0Tr=3,1"]#  0.99836642

    set_value!(t_elas_a, 1.0)
    set_value!(t_elas_b, 1.0)
    solve!(m)
    
    @test value(A) ≈ two_by_two_scalar_results["A.L","Sub=0Tr=1"]#  1
    @test value(B) ≈ two_by_two_scalar_results["B.L","Sub=0Tr=1"]#  1
    @test value(W) ≈ two_by_two_scalar_results["W.L","Sub=0Tr=1"]#  0.99893795
    @test value(PX) ≈ two_by_two_scalar_results["PX.L","Sub=0Tr=1"]#  1.05572809
    @test value(PY) ≈ two_by_two_scalar_results["PY.L","Sub=0Tr=1"]#  0.94427191
    @test value(PW) ≈ two_by_two_scalar_results["PW.L","Sub=0Tr=1"]#  1
    @test value(PL) ≈ two_by_two_scalar_results["PL.L","Sub=0Tr=1"]#  1.17189333
    @test value(PK) ≈ two_by_two_scalar_results["PK.L","Sub=0Tr=1"]#  0.66113695
    @test value(CONS) ≈ two_by_two_scalar_results["CONS.L","Sub=0Tr=1"]#  199.7876
    @test value(compensated_demand(A, PX, :t)) ≈ -two_by_two_scalar_results["SAX.L","Sub=0Tr=1"]#  78.07200584
    @test value(compensated_demand(A, PY, :t)) ≈ -two_by_two_scalar_results["SAY.L","Sub=0Tr=1"]#  21.82178902
    @test value(compensated_demand(B, PX, :t)) ≈ -two_by_two_scalar_results["SBX.L","Sub=0Tr=1"]#  21.82178903
    @test value(compensated_demand(B, PY, :t)) ≈ -two_by_two_scalar_results["SBY.L","Sub=0Tr=1"]#  78.07200583
    @test value(compensated_demand(A, PL)) ≈ two_by_two_scalar_results["DAL.L","Sub=0Tr=1"]#  40
    @test value(compensated_demand(A, PK)) ≈ two_by_two_scalar_results["DAK.L","Sub=0Tr=1"]#  60
    @test value(compensated_demand(B, PL)) ≈ two_by_two_scalar_results["DBL.L","Sub=0Tr=1"]#  60
    @test value(compensated_demand(B, PK)) ≈ two_by_two_scalar_results["DBK.L","Sub=0Tr=1"]#  40
    @test value(compensated_demand(W, PW, :t)) ≈ -two_by_two_scalar_results["SW.L","Sub=0Tr=1"]#  200
    @test value(compensated_demand(W, PX)) ≈ two_by_two_scalar_results["DWX.L","Sub=0Tr=1"]#  100
    @test value(compensated_demand(W, PY)) ≈ two_by_two_scalar_results["DWY.L","Sub=0Tr=1"]#  100
    @test value(demand(CONS, PW)) ≈ two_by_two_scalar_results["DW.L","Sub=0Tr=1"]#  199.7876
    # CWI ")]) ≈ two_by_two_scalar_results["CWI.L","Sub=0Tr=1"]#  0.99893795


    set_value!(sub_elas_a, 1.5)
    set_value!(sub_elas_b, 2.)
    set_value!(sub_elas_w, 0.5)
    set_value!(t_elas_a, 0.0)
    set_value!(t_elas_b, 0.0)
    solve!(m)

    @test value(A) ≈ two_by_two_scalar_results["A.L","1.52,.5T0"]#  0.87514262
    @test value(B) ≈ two_by_two_scalar_results["B.L","1.52,.5T0"]#  1.12449411
    @test value(W) ≈ two_by_two_scalar_results["W.L","1.52,.5T0"]#  0.99422149
    @test value(PX) ≈ two_by_two_scalar_results["PX.L","1.52,.5T0"]#  1.15523596
    @test value(PY) ≈ two_by_two_scalar_results["PY.L","1.52,.5T0"]#  0.85595982
    @test value(PW) ≈ two_by_two_scalar_results["PW.L","1.52,.5T0"]#  1
    @test value(PL) ≈ two_by_two_scalar_results["PL.L","1.52,.5T0"]#  0.92664016
    @test value(PK) ≈ two_by_two_scalar_results["PK.L","1.52,.5T0"]#  0.90004343
    @test value(CONS) ≈ two_by_two_scalar_results["CONS.L","1.52,.5T0"]#  198.8443
    @test value(compensated_demand(A, PX, :t)) ≈ -two_by_two_scalar_results["SAX.L","1.52,.5T0"]#  80
    @test value(compensated_demand(A, PY, :t)) ≈ -two_by_two_scalar_results["SAY.L","1.52,.5T0"]#  20
    @test value(compensated_demand(B, PX, :t)) ≈ -two_by_two_scalar_results["SBX.L","1.52,.5T0"]#  20
    @test value(compensated_demand(B, PY, :t)) ≈ -two_by_two_scalar_results["SBY.L","1.52,.5T0"]#  80
    @test value(compensated_demand(A, PL)) ≈ two_by_two_scalar_results["DAL.L","1.52,.5T0"]#  38.9622461
    @test value(compensated_demand(A, PK)) ≈ two_by_two_scalar_results["DAK.L","1.52,.5T0"]#  61.0529602
    @test value(compensated_demand(B, PL)) ≈ two_by_two_scalar_results["DBL.L","1.52,.5T0"]#  58.60633444
    @test value(compensated_demand(B, PK)) ≈ two_by_two_scalar_results["DBK.L","1.52,.5T0"]#  41.41413634
    @test value(compensated_demand(W, PW, :t)) ≈ -two_by_two_scalar_results["SW.L","1.52,.5T0"]#  200
    @test value(compensated_demand(W, PX)) ≈ two_by_two_scalar_results["DWX.L","1.52,.5T0"]#  93.03891791
    @test value(compensated_demand(W, PY)) ≈ two_by_two_scalar_results["DWY.L","1.52,.5T0"]#  108.087
    @test value(demand(CONS, PW)) ≈ two_by_two_scalar_results["DW.L","1.52,.5T0"]#  198.8443
    # CWI ")]) ≈ two_by_two_scalar_results["CWI.L","1.52,.5T0"]#  0.99422149
    
       
    set_value!(t_elas_a, 2.0)
    set_value!(t_elas_b, 1.5)
    solve!(m)
        
    @test value(A) ≈ two_by_two_scalar_results["A.L","S..T2,1.5"]#  0.65301554
    @test value(B) ≈ two_by_two_scalar_results["B.L","S..T2,1.5"]#  1.34428248
    @test value(W) ≈ two_by_two_scalar_results["W.L","S..T2,1.5"]#  0.98334631
    @test value(PX) ≈ two_by_two_scalar_results["PX.L","S..T2,1.5"]#  1.15814902
    @test value(PY) ≈ two_by_two_scalar_results["PY.L","S..T2,1.5"]#  0.85345573
    @test value(PW) ≈ two_by_two_scalar_results["PW.L","S..T2,1.5"]#  1
    @test value(PL) ≈ two_by_two_scalar_results["PL.L","S..T2,1.5"]#  0.95693303
    @test value(PK) ≈ two_by_two_scalar_results["PK.L","S..T2,1.5"]#  0.88509599
    @test value(CONS) ≈ two_by_two_scalar_results["CONS.L","S..T2,1.5"]#  196.6693
    @test value(compensated_demand(A, PX, :t)) ≈ -two_by_two_scalar_results["SAX.L","S..T2,1.5"]#  82.41792731
    @test value(compensated_demand(A, PY, :t)) ≈ -two_by_two_scalar_results["SAY.L","S..T2,1.5"]#  17.48295499
    @test value(compensated_demand(B, PX, :t)) ≈ -two_by_two_scalar_results["SBX.L","S..T2,1.5"]#  27.93620902
    @test value(compensated_demand(B, PY, :t)) ≈ -two_by_two_scalar_results["SBY.L","S..T2,1.5"]#  70.6890752
    @test value(compensated_demand(A, PL)) ≈ two_by_two_scalar_results["DAL.L","S..T2,1.5"]#  37.26666598
    @test value(compensated_demand(A, PK)) ≈ two_by_two_scalar_results["DAK.L","S..T2,1.5"]#  62.84179114
    @test value(compensated_demand(B, PL)) ≈ two_by_two_scalar_results["DBL.L","S..T2,1.5"]#  56.28600301
    @test value(compensated_demand(B, PK)) ≈ two_by_two_scalar_results["DBK.L","S..T2,1.5"]#  43.86230905
    @test value(compensated_demand(W, PW, :t)) ≈ -two_by_two_scalar_results["SW.L","S..T2,1.5"]#  200
    @test value(compensated_demand(W, PX)) ≈ two_by_two_scalar_results["DWX.L","S..T2,1.5"]#  92.92183527
    @test value(compensated_demand(W, PY)) ≈ two_by_two_scalar_results["DWY.L","S..T2,1.5"]#  108.2454
    @test value(demand(CONS, PW)) ≈ two_by_two_scalar_results["DW.L","S..T2,1.5"]#  196.6693
    # CWI ")]) ≈ two_by_two_scalar_results["CWI.L","S..T2,1.5"]#  0.98334631

    set_value!(t_elas_a, 3.0)
    set_value!(t_elas_b, 1.0)
    solve!(m)

    @test value(A) ≈ two_by_two_scalar_results["A.L","S...T3,1"]#  0.717787
    @test value(B) ≈ two_by_two_scalar_results["B.L","S...T3,1"]#  1.28040608
    @test value(W) ≈ two_by_two_scalar_results["W.L","S...T3,1"]#  0.98762504
    @test value(PX) ≈ two_by_two_scalar_results["PX.L","S...T3,1"]#  1.15559805
    @test value(PY) ≈ two_by_two_scalar_results["PY.L","S...T3,1"]#  0.85564819
    @test value(PW) ≈ two_by_two_scalar_results["PW.L","S...T3,1"]#  1
    @test value(PL) ≈ two_by_two_scalar_results["PL.L","S...T3,1"]#  0.94793634
    @test value(PK) ≈ two_by_two_scalar_results["PK.L","S...T3,1"]#  0.88903973
    @test value(CONS) ≈ two_by_two_scalar_results["CONS.L","S...T3,1"]#  197.525
    @test value(compensated_demand(A, PX, :t)) ≈ -two_by_two_scalar_results["SAX.L","S...T3,1"]#  83.35049624
    @test value(compensated_demand(A, PY, :t)) ≈ -two_by_two_scalar_results["SAY.L","S...T3,1"]#  16.52127468
    @test value(compensated_demand(B, PX, :t)) ≈ -two_by_two_scalar_results["SBX.L","S...T3,1"]#  25.0274236
    @test value(compensated_demand(B, PY, :t)) ≈ -two_by_two_scalar_results["SBY.L","S...T3,1"]#  74.12497738
    @test value(compensated_demand(A, PL)) ≈ two_by_two_scalar_results["DAL.L","S...T3,1"]#  37.7422087
    @test value(compensated_demand(A, PK)) ≈ two_by_two_scalar_results["DAK.L","S...T3,1"]#  62.33121254
    @test value(compensated_demand(B, PL)) ≈ two_by_two_scalar_results["DBL.L","S...T3,1"]#  56.94219551
    @test value(compensated_demand(B, PK)) ≈ two_by_two_scalar_results["DBK.L","S...T3,1"]#  43.15776592
    @test value(compensated_demand(W, PW, :t)) ≈ -two_by_two_scalar_results["SW.L","S...T3,1"]#  200
    @test value(compensated_demand(W, PX)) ≈ two_by_two_scalar_results["DWX.L","S...T3,1"]#  93.02434064
    @test value(compensated_demand(W, PY)) ≈ two_by_two_scalar_results["DWY.L","S...T3,1"]#  108.1066
    @test value(demand(CONS, PW)) ≈ two_by_two_scalar_results["DW.L","S...T3,1"]#  197.525
    # CWI ")]) ≈ two_by_two_scalar_results["CWI.L","S...T3,1"]#  0.98762504

    set_value!(t_elas_a, 1.0)
    set_value!(t_elas_b, 1.0)
    solve!(m)

    @test value(A) ≈ two_by_two_scalar_results["A.L","S...T1"]#  0.74236189
    @test value(B) ≈ two_by_two_scalar_results["B.L","S...T1"]#  1.25612592
    @test value(W) ≈ two_by_two_scalar_results["W.L","S...T1"]#  0.98786685
    @test value(PX) ≈ two_by_two_scalar_results["PX.L","S...T1"]#  1.15758898
    @test value(PY) ≈ two_by_two_scalar_results["PY.L","S...T1"]#  0.85393661
    @test value(PW) ≈ two_by_two_scalar_results["PW.L","S...T1"]#  1
    @test value(PL) ≈ two_by_two_scalar_results["PL.L","S...T1"]#  0.94504732
    @test value(PK) ≈ two_by_two_scalar_results["PK.L","S...T1"]#  0.8910844
    @test value(CONS) ≈ two_by_two_scalar_results["CONS.L","S...T1"]#  197.5734
    @test value(compensated_demand(A, PX, :t)) ≈ -two_by_two_scalar_results["SAX.L","S...T1"]#  81.22533941
    @test value(compensated_demand(A, PY, :t)) ≈ -two_by_two_scalar_results["SAY.L","S...T1"]#  18.72461106
    @test value(compensated_demand(B, PX, :t)) ≈ -two_by_two_scalar_results["SBX.L","S...T1"]#  25.09143825
    @test value(compensated_demand(B, PY, :t)) ≈ -two_by_two_scalar_results["SBY.L","S...T1"]#  74.03836104
    @test value(compensated_demand(A, PL)) ≈ two_by_two_scalar_results["DAL.L","S...T1"]#  37.92659869
    @test value(compensated_demand(A, PK)) ≈ two_by_two_scalar_results["DAK.L","S...T1"]#  62.13513247
    @test value(compensated_demand(B, PL)) ≈ two_by_two_scalar_results["DBL.L","S...T1"]#  57.19549083
    @test value(compensated_demand(B, PK)) ≈ two_by_two_scalar_results["DBK.L","S...T1"]#  42.8884117
    @test value(compensated_demand(W, PW, :t)) ≈ -two_by_two_scalar_results["SW.L","S...T1"]#  200
    @test value(compensated_demand(W, PX)) ≈ two_by_two_scalar_results["DWX.L","S...T1"]#  92.94430997
    @test value(compensated_demand(W, PY)) ≈ two_by_two_scalar_results["DWY.L","S...T1"]#  108.2149
    @test value(demand(CONS, PW)) ≈ two_by_two_scalar_results["DW.L","S...T1"]#  197.5734
    # CWI ")]) ≈ two_by_two_scalar_results["CWI.L","S...T1,1"]#  0.98786685

    set_value!(otax2, 0.1)
    solve!(m)

    @test value(A) ≈ two_by_two_scalar_results["A.L","S.T1,O2=.1"]#  0.69377214
    @test value(B) ≈ two_by_two_scalar_results["B.L","S.T1,O2=.1"]#  1.30410892
    @test value(W) ≈ two_by_two_scalar_results["W.L","S.T1,O2=.1"]#  0.98418612
    @test value(PX) ≈ two_by_two_scalar_results["PX.L","S.T1,O2=.1"]#  1.17251766
    @test value(PY) ≈ two_by_two_scalar_results["PY.L","S.T1,O2=.1"]#  0.84120348
    @test value(PW) ≈ two_by_two_scalar_results["PW.L","S.T1,O2=.1"]#  1
    @test value(PL) ≈ two_by_two_scalar_results["PL.L","S.T1,O2=.1"]#  0.94342778
    @test value(PK) ≈ two_by_two_scalar_results["PK.L","S.T1,O2=.1"]#  0.88023493
    @test value(CONS) ≈ two_by_two_scalar_results["CONS.L","S.T1,O2=.1"]#  196.8372
    @test value(compensated_demand(A, PX, :t)) ≈ -two_by_two_scalar_results["SAX.L","S.T1,O2=.1"]#  82.94337454
    @test value(compensated_demand(A, PY, :t)) ≈ -two_by_two_scalar_results["SAY.L","S.T1,O2=.1"]#  16.73616309
    @test value(compensated_demand(B, PX, :t)) ≈ -two_by_two_scalar_results["SBX.L","S.T1,O2=.1"]#  25.57033231
    @test value(compensated_demand(B, PY, :t)) ≈ -two_by_two_scalar_results["SBY.L","S.T1,O2=.1"]#  73.38005467
    @test value(compensated_demand(A, PL)) ≈ two_by_two_scalar_results["DAL.L","S.T1,O2=.1"]#  37.56414425
    @test value(compensated_demand(A, PK)) ≈ two_by_two_scalar_results["DAK.L","S.T1,O2=.1"]#  62.52156613
    @test value(compensated_demand(B, PL)) ≈ two_by_two_scalar_results["DBL.L","S.T1,O2=.1"]#  56.6969846
    @test value(compensated_demand(B, PK)) ≈ two_by_two_scalar_results["DBK.L","S.T1,O2=.1"]#  43.41990034
    @test value(compensated_demand(W, PW, :t)) ≈ -two_by_two_scalar_results["SW.L","S.T1,O2=.1"]#  200
    @test value(compensated_demand(W, PX)) ≈ two_by_two_scalar_results["DWX.L","S.T1,O2=.1"]#  92.3507239
    @test value(compensated_demand(W, PY)) ≈ two_by_two_scalar_results["DWY.L","S.T1,O2=.1"]#  109.0309
    @test value(demand(CONS, PW)) ≈ two_by_two_scalar_results["DW.L","S.T1,O2=.1"]#  196.8372
    # CWI ")]) ≈ two_by_two_scalar_results["CWI.L","S.T1,O2=.1"]#  0.98418612

    set_value!(otax2, 0.)
    set_value!(otax3, 0.1)
    solve!(m)

    @test value(A) ≈ two_by_two_scalar_results["A.L","S.T1,O3=.1"]#  0.8361865
    @test value(B) ≈ two_by_two_scalar_results["B.L","S.T1,O3=.1"]#  1.16319234
    @test value(W) ≈ two_by_two_scalar_results["W.L","S.T1,O3=.1"]#  0.99442372
    @test value(PX) ≈ two_by_two_scalar_results["PX.L","S.T1,O3=.1"]#  1.13192563
    @test value(PY) ≈ two_by_two_scalar_results["PY.L","S.T1,O3=.1"]#  0.87624589
    @test value(PW) ≈ two_by_two_scalar_results["PW.L","S.T1,O3=.1"]#  1
    @test value(PL) ≈ two_by_two_scalar_results["PL.L","S.T1,O3=.1"]#  0.92056787
    @test value(PK) ≈ two_by_two_scalar_results["PK.L","S.T1,O3=.1"]#  0.88627413
    @test value(CONS) ≈ two_by_two_scalar_results["CONS.L","S.T1,O3=.1"]#  198.8847
    @test value(compensated_demand(A, PX, :t)) ≈ -two_by_two_scalar_results["SAX.L","S.T1,O3=.1"]#  80.51414876
    @test value(compensated_demand(A, PY, :t)) ≈ -two_by_two_scalar_results["SAY.L","S.T1,O3=.1"]#  19.47737052
    @test value(compensated_demand(B, PX, :t)) ≈ -two_by_two_scalar_results["SBX.L","S.T1,O3=.1"]#  22.47527322
    @test value(compensated_demand(B, PY, :t)) ≈ -two_by_two_scalar_results["SBY.L","S.T1,O3=.1"]#  77.32689296
    @test value(compensated_demand(A, PL)) ≈ two_by_two_scalar_results["DAL.L","S.T1,O3=.1"]#  38.65135847
    @test value(compensated_demand(A, PK)) ≈ two_by_two_scalar_results["DAK.L","S.T1,O3=.1"]#  61.37445248
    @test value(compensated_demand(B, PL)) ≈ two_by_two_scalar_results["DBL.L","S.T1,O3=.1"]#  58.18492236
    @test value(compensated_demand(B, PK)) ≈ two_by_two_scalar_results["DBK.L","S.T1,O3=.1"]#  41.84992453
    @test value(compensated_demand(W, PW, :t)) ≈ -two_by_two_scalar_results["SW.L","S.T1,O3=.1"]#  200
    @test value(compensated_demand(W, PX)) ≈ two_by_two_scalar_results["DWX.L","S.T1,O3=.1"]#  93.99203514
    @test value(compensated_demand(W, PY)) ≈ two_by_two_scalar_results["DWY.L","S.T1,O3=.1"]#  106.8285
    @test value(demand(CONS, PW)) ≈ two_by_two_scalar_results["DW.L","S.T1,O3=.1"]#  198.8847
    # CWI ")]) ≈ two_by_two_scalar_results["CWI.L","S.T1,O3=.1"]#  0.99442372



    set_value!(otax3, 0.)
    set_value!(otax4, 0.1)
    solve!(m)

    @test value(A) ≈ two_by_two_scalar_results["A.L","S.T1,O4=.1"]#  0.85040405
    @test value(B) ≈ two_by_two_scalar_results["B.L","S.T1,O4=.1"]#  1.14907667
    @test value(W) ≈ two_by_two_scalar_results["W.L","S.T1,O4=.1"]#  0.99396862
    @test value(PX) ≈ two_by_two_scalar_results["PX.L","S.T1,O4=.1"]#  1.08496248
    @test value(PY) ≈ two_by_two_scalar_results["PY.L","S.T1,O4=.1"]#  0.91850119
    @test value(PW) ≈ two_by_two_scalar_results["PW.L","S.T1,O4=.1"]#  1
    @test value(PL) ≈ two_by_two_scalar_results["PL.L","S.T1,O4=.1"]#  0.89687906
    @test value(PK) ≈ two_by_two_scalar_results["PK.L","S.T1,O4=.1"]#  0.86624727
    @test value(CONS) ≈ two_by_two_scalar_results["CONS.L","S.T1,O4=.1"]#  198.7937
    @test value(compensated_demand(A, PX, :t)) ≈ -two_by_two_scalar_results["SAX.L","S.T1,O4=.1"]#  79.05829527
    @test value(compensated_demand(A, PY, :t)) ≈ -two_by_two_scalar_results["SAY.L","S.T1,O4=.1"]#  20.91522142
    @test value(compensated_demand(B, PX, :t)) ≈ -two_by_two_scalar_results["SBX.L","S.T1,O4=.1"]#  24.53639262
    @test value(compensated_demand(B, PY, :t)) ≈ -two_by_two_scalar_results["SBY.L","S.T1,O4=.1"]#  74.77875199
    @test value(compensated_demand(A, PL)) ≈ two_by_two_scalar_results["DAL.L","S.T1,O4=.1"]#  38.76412959
    @test value(compensated_demand(A, PK)) ≈ two_by_two_scalar_results["DAK.L","S.T1,O4=.1"]#  61.25750586
    @test value(compensated_demand(B, PL)) ≈ two_by_two_scalar_results["DBL.L","S.T1,O4=.1"]#  58.3379934
    @test value(compensated_demand(B, PK)) ≈ two_by_two_scalar_results["DBK.L","S.T1,O4=.1"]#  41.69118576
    @test value(compensated_demand(W, PW, :t)) ≈ -two_by_two_scalar_results["SW.L","S.T1,O4=.1"]#  200
    @test value(compensated_demand(W, PX)) ≈ two_by_two_scalar_results["DWX.L","S.T1,O4=.1"]#  96.0047319
    @test value(compensated_demand(W, PY)) ≈ two_by_two_scalar_results["DWY.L","S.T1,O4=.1"]#  104.3422
    @test value(demand(CONS, PW)) ≈ two_by_two_scalar_results["DW.L","S.T1,O4=.1"]#  198.7937
    # CWI ")]) ≈ two_by_two_scalar_results["CWI.L","S.T1,O4=.1"]#  0.99396862


    set_value!(itax, 0.1)
    solve!(m)    
    
    @test value(A) ≈ two_by_two_scalar_results["A.L","O4,I=0.1"]#  0.63672356
    @test value(B) ≈ two_by_two_scalar_results["B.L","O4,I=0.1"]#  1.36032283
    @test value(W) ≈ two_by_two_scalar_results["W.L","O4,I=0.1"]#  0.97648969
    @test value(PX) ≈ two_by_two_scalar_results["PX.L","O4,I=0.1"]#  1.18245598
    @test value(PY) ≈ two_by_two_scalar_results["PY.L","O4,I=0.1"]#  0.83282431
    @test value(PW) ≈ two_by_two_scalar_results["PW.L","O4,I=0.1"]#  1
    @test value(PL) ≈ two_by_two_scalar_results["PL.L","O4,I=0.1"]#  0.88286437
    @test value(PK) ≈ two_by_two_scalar_results["PK.L","O4,I=0.1"]#  0.81377744
    @test value(CONS) ≈ two_by_two_scalar_results["CONS.L","O4,I=0.1"]#  195.2979
    @test value(compensated_demand(A, PX, :t)) ≈ -two_by_two_scalar_results["SAX.L","O4,I=0.1"]#  81.8622781
    @test value(compensated_demand(A, PY, :t)) ≈ -two_by_two_scalar_results["SAY.L","O4,I=0.1"]#  18.01782051
    @test value(compensated_demand(B, PX, :t)) ≈ -two_by_two_scalar_results["SBX.L","O4,I=0.1"]#  27.69645309
    @test value(compensated_demand(B, PY, :t)) ≈ -two_by_two_scalar_results["SBY.L","O4,I=0.1"]#  70.22553628
    @test value(compensated_demand(A, PL)) ≈ two_by_two_scalar_results["DAL.L","O4,I=0.1"]#  37.1493891
    @test value(compensated_demand(A, PK)) ≈ two_by_two_scalar_results["DAK.L","O4,I=0.1"]#  62.96880528
    @test value(compensated_demand(B, PL)) ≈ two_by_two_scalar_results["DBL.L","O4,I=0.1"]#  56.12352231
    @test value(compensated_demand(B, PK)) ≈ two_by_two_scalar_results["DBK.L","O4,I=0.1"]#  44.03828026
    @test value(compensated_demand(W, PW, :t)) ≈ -two_by_two_scalar_results["SW.L","O4,I=0.1"]#  200
    @test value(compensated_demand(W, PX)) ≈ two_by_two_scalar_results["DWX.L","O4,I=0.1"]#  91.96180957
    @test value(compensated_demand(W, PY)) ≈ two_by_two_scalar_results["DWY.L","O4,I=0.1"]#  109.578
    @test value(demand(CONS, PW)) ≈ two_by_two_scalar_results["DW.L","O4,I=0.1"]#  195.2979
    # CWI ")]) ≈ two_by_two_scalar_results["CWI.L","O4,I=0.1"]#  0.97648969


    set_value!(otax4, 0.0)
    solve!(m)    

    @test value(A) ≈ two_by_two_scalar_results["A.L","ITAX=0.1"]#  0.54435839
    @test value(B) ≈ two_by_two_scalar_results["B.L","ITAX=0.1"]#  1.45106586
    @test value(W) ≈ two_by_two_scalar_results["W.L","ITAX=0.1"]#  0.96551295
    @test value(PX) ≈ two_by_two_scalar_results["PX.L","ITAX=0.1"]#  1.25371686
    @test value(PY) ≈ two_by_two_scalar_results["PY.L","ITAX=0.1"]#  0.77493692
    @test value(PW) ≈ two_by_two_scalar_results["PW.L","ITAX=0.1"]#  1
    @test value(PL) ≈ two_by_two_scalar_results["PL.L","ITAX=0.1"]#  0.92927845
    @test value(PK) ≈ two_by_two_scalar_results["PK.L","ITAX=0.1"]#  0.84027402
    @test value(CONS) ≈ two_by_two_scalar_results["CONS.L","ITAX=0.1"]#  193.1026
    @test value(compensated_demand(A, PX, :t)) ≈ -two_by_two_scalar_results["SAX.L","ITAX=0.1"]#  83.43323254
    @test value(compensated_demand(A, PY, :t)) ≈ -two_by_two_scalar_results["SAY.L","ITAX=0.1"]#  16.11595257
    @test value(compensated_demand(B, PX, :t)) ≈ -two_by_two_scalar_results["SBX.L","ITAX=0.1"]#  28.12581929
    @test value(compensated_demand(B, PY, :t)) ≈ -two_by_two_scalar_results["SBY.L","ITAX=0.1"]#  69.53957979
    @test value(compensated_demand(A, PL)) ≈ two_by_two_scalar_results["DAL.L","ITAX=0.1"]#  36.5016685
    @test value(compensated_demand(A, PK)) ≈ two_by_two_scalar_results["DAK.L","ITAX=0.1"]#  63.6782873
    @test value(compensated_demand(B, PL)) ≈ two_by_two_scalar_results["DBL.L","ITAX=0.1"]#  55.22148407
    @test value(compensated_demand(B, PK)) ≈ two_by_two_scalar_results["DBK.L","ITAX=0.1"]#  45.02634343
    @test value(compensated_demand(W, PW, :t)) ≈ -two_by_two_scalar_results["SW.L","ITAX=0.1"]#  200
    @test value(compensated_demand(W, PX)) ≈ two_by_two_scalar_results["DWX.L","ITAX=0.1"]#  89.31003664
    @test value(compensated_demand(W, PY)) ≈ two_by_two_scalar_results["DWY.L","ITAX=0.1"]#  113.597
    @test value(demand(CONS, PW)) ≈ two_by_two_scalar_results["DW.L","ITAX=0.1"]#  193.1026
    # CWI ")]) ≈ two_by_two_scalar_results["CWI.L","ITAX=0.1"]#  0.96551295

    set_value!(otax2, 0.3 )
    set_value!(itax, 0.2 )
    solve!(m)    
    
    @test value(A) ≈ two_by_two_scalar_results["A.L","O2=.3,I=.2"]#  0.26298582
    @test value(B) ≈ two_by_two_scalar_results["B.L","O2=.3,I=.2"]#  1.72557704
    @test value(W) ≈ two_by_two_scalar_results["W.L","O2=.3,I=.2"]#  0.91527149
    @test value(PX) ≈ two_by_two_scalar_results["PX.L","O2=.3,I=.2"]#  1.37998382
    @test value(PY) ≈ two_by_two_scalar_results["PY.L","O2=.3,I=.2"]#  0.68107531
    @test value(PW) ≈ two_by_two_scalar_results["PW.L","O2=.3,I=.2"]#  1
    @test value(PL) ≈ two_by_two_scalar_results["PL.L","O2=.3,I=.2"]#  0.92558632
    @test value(PK) ≈ two_by_two_scalar_results["PK.L","O2=.3,I=.2"]#  0.79214911
    @test value(CONS) ≈ two_by_two_scalar_results["CONS.L","O2=.3,I=.2"]#  183.0543
    @test value(compensated_demand(A, PX, :t)) ≈ -two_by_two_scalar_results["SAX.L","O2=.3,I=.2"]#  87.42786978
    @test value(compensated_demand(A, PY, :t)) ≈ -two_by_two_scalar_results["SAY.L","O2=.3,I=.2"]#  9.43885039
    @test value(compensated_demand(B, PX, :t)) ≈ -two_by_two_scalar_results["SBX.L","O2=.3,I=.2"]#  31.82775909
    @test value(compensated_demand(B, PY, :t)) ≈ -two_by_two_scalar_results["SBY.L","O2=.3,I=.2"]#  62.83291339
    @test value(compensated_demand(A, PL)) ≈ two_by_two_scalar_results["DAL.L","O2=.3,I=.2"]#  34.6951557
    @test value(compensated_demand(A, PK)) ≈ two_by_two_scalar_results["DAK.L","O2=.3,I=.2"]#  65.73173321
    @test value(compensated_demand(B, PL)) ≈ two_by_two_scalar_results["DBL.L","O2=.3,I=.2"]#  52.66392871
    @test value(compensated_demand(B, PK)) ≈ two_by_two_scalar_results["DBK.L","O2=.3,I=.2"]#  47.93381262
    @test value(compensated_demand(W, PW, :t)) ≈ -two_by_two_scalar_results["SW.L","O2=.3,I=.2"]#  200
    @test value(compensated_demand(W, PX)) ≈ two_by_two_scalar_results["DWX.L","O2=.3,I=.2"]#  85.12615199
    @test value(compensated_demand(W, PY)) ≈ two_by_two_scalar_results["DWY.L","O2=.3,I=.2"]#  121.172
    @test value(demand(CONS, PW)) ≈ two_by_two_scalar_results["DW.L","O2=.3,I=.2"]#  183.0543
    # CWI ")]) ≈ two_by_two_scalar_results["CWI.L","O2=.3,I=.2"]#  0.91527149
    

    
    set_value!(itax, 1.0)
    solve!(m)

    @test value(A) ≈ 0 #two_by_two_scalar_results["A.L","ITAX=100%"]#  NULL
    @test value(B) ≈ two_by_two_scalar_results["B.L","ITAX=100%"]#  1.9797959
    @test value(W) ≈ two_by_two_scalar_results["W.L","ITAX=100%"]#  0.85094166
    @test value(PX) ≈ two_by_two_scalar_results["PX.L","ITAX=100%"]#  1.50558687
    @test value(PY) ≈ two_by_two_scalar_results["PY.L","ITAX=100%"]#  0.59749254
    @test value(PW) ≈ two_by_two_scalar_results["PW.L","ITAX=100%"]#  1
    @test value(PL) ≈ two_by_two_scalar_results["PL.L","ITAX=100%"]#  0.93690422
    @test value(PK) ≈ two_by_two_scalar_results["PK.L","ITAX=100%"]#  0.76497909
    @test value(CONS) ≈ two_by_two_scalar_results["CONS.L","ITAX=100%"]#  170.1883
    # @test value(compensated_demand(A, PX, :t)) ≈ -0 # two_by_two_scalar_results["SAX.L","ITAX=100%"]# UNDF in GAMS, but has a value in Julia
    # @test value(compensated_demand(A, PY, :t)) ≈ -0 # two_by_two_scalar_results["SAY.L","ITAX=100%"]# UNDF in GAMS, but has a value in Julia
    @test value(compensated_demand(B, PX, :t)) ≈ -two_by_two_scalar_results["SBX.L","ITAX=100%"]#  35.0288964
    @test value(compensated_demand(B, PY, :t)) ≈ -two_by_two_scalar_results["SBY.L","ITAX=100%"]#  55.60490686
    # @test value(compensated_demand(A, PL)) ≈ 0 # two_by_two_scalar_results["DAL.L","ITAX=100%"]# UNDF in GAMS, but has a value in Julia
    # @test value(compensated_demand(A, PK)) ≈ 0 # two_by_two_scalar_results["DAK.L","ITAX=100%"]#  UNDF in GAMS, but has a value in Julia
    @test value(compensated_demand(B, PL)) ≈ two_by_two_scalar_results["DBL.L","ITAX=100%"]#  50.51025716
    @test value(compensated_demand(B, PK)) ≈ two_by_two_scalar_results["DBK.L","ITAX=100%"]#  50.51025729
    @test value(compensated_demand(W, PW, :t)) ≈ -two_by_two_scalar_results["SW.L","ITAX=100%"]#  200
    @test value(compensated_demand(W, PX)) ≈ two_by_two_scalar_results["DWX.L","ITAX=100%"]#  81.49802621
    @test value(compensated_demand(W, PY)) ≈ two_by_two_scalar_results["DWY.L","ITAX=100%"]#  129.3701
    @test value(demand(CONS, PW)) ≈ two_by_two_scalar_results["DW.L","ITAX=100%"]#  170.1883
    # CWI ")]) ≈ two_by_two_scalar_results["CWI.L","ITAX=100%"]#  0.85094165

    
    
end



@testitem "TWObyTWO_wAuxinDemand" begin
    using XLSX, MPSGE.JuMP.Containers
    import JuMP
    
    # A replication of an adapted version (taking out non-1 prices) of the Markusen MS_8s model, with Auxiliary Variable/Constraint in the Demand function: TwobyTwo_AuxinDemand.gms
    m = MPSGEModel()
    # Here parameter values are doubled and input data halved from MPSGE version
    @parameters(m, begin
        tx, .1
        ty, 0
        tlx, 0
        tkx, 0
        uo, 0.2, (description = "Initial unemployment rate",)
    end)       
    
    @sectors(m,begin
        X
        Y
        W
    end)
    
    @commodities(m, begin
        PX
        PY
        PW
        PL
        PK
    end)
    
    @consumer(m, CONS)
    
    @auxiliary(m, U) #benchmark = .2
    
    #@parameter(m, U, 0.2)
    
    @production(m, X, [t = 0, s = 1], begin
            @output(PX, 100, t, taxes = [Tax(CONS, tx)])
            @input(PK, 50, s, taxes = [Tax(CONS,tkx)])
            @input(PL, 40, s)
    end)
    
    @production(m, Y, [t = 0, s = 1], begin
        @output(PY, 100, t, taxes = [Tax(CONS, ty)])
        @input(PL, 60, s) 
        @input(PK, 40, s)
    end)
    
    @production(m, W, [t = 0, s = 1], begin
        @output(PW, 200, t)
        @input(PX, 100, s) 
        @input(PY, 100, s)
    end)
    
    @demand(m, CONS, begin
            @final_demand(PW,200)
            @endowment(PL, 120 + -80/(1-uo)*U)
            @endowment(PK, 90)
    end)
    
    @aux_constraint(m, U, PL - PW)

    
    set_start_value(U,.2)
    

    solve!(m)

    gams_results = XLSX.readxlsx(joinpath(@__DIR__, "MPSGEresults.xlsx"))
    a_table = gams_results["TwoxTwowAuxDem"][:]  # Generated from TwoByTwo_Scalar_Algeb-MPSGE.gms
    two_by_two_AuxinDemand = DenseAxisArray(a_table[2:end,2:end],a_table[2:end,1],a_table[1,2:end])
    
    solve!(m, cumulative_iteration_limit=0)

    # benchmark
    @test value(X) ≈ two_by_two_AuxinDemand["X.L","benchmark"]#  1
    @test value(Y) ≈ two_by_two_AuxinDemand["Y.L","benchmark"]#  1
    @test value(W) ≈ two_by_two_AuxinDemand["W.L","benchmark"]#  1
    @test value(PX) ≈ two_by_two_AuxinDemand["PX.L","benchmark"]#  1
    @test value(PY) ≈ two_by_two_AuxinDemand["PY.L","benchmark"]#  1
    @test value(PW) ≈ two_by_two_AuxinDemand["PW.L","benchmark"]#  1
    @test value(PL) ≈ two_by_two_AuxinDemand["PL.L","benchmark"]#  1
    @test value(PK) ≈ two_by_two_AuxinDemand["PK.L","benchmark"]#  1
    @test value(U) ≈ two_by_two_AuxinDemand["U.L","benchmark"]#  0.2
    @test value(compensated_demand(X, PX, :t)) ≈ -two_by_two_AuxinDemand["SXX.L","benchmark"]#  100
    @test value(compensated_demand(Y, PY, :t)) ≈ -two_by_two_AuxinDemand["SYY.L","benchmark"]#  100
    @test value(compensated_demand(W, PW, :t)) ≈ -two_by_two_AuxinDemand["SWW.L","benchmark"]#  200
    @test value(compensated_demand(X, PK)) ≈ two_by_two_AuxinDemand["DKX.L","benchmark"]#  50
    @test value(compensated_demand(X, PL)) ≈ two_by_two_AuxinDemand["DLX.L","benchmark"]#  40
    @test value(compensated_demand(Y, PL)) ≈ two_by_two_AuxinDemand["DLY.L","benchmark"]#  60
    @test value(compensated_demand(Y, PK)) ≈ two_by_two_AuxinDemand["DKY.L","benchmark"]#  40
    @test value(compensated_demand(W, PX)) ≈ two_by_two_AuxinDemand["DXW.L","benchmark"]#  100
    @test value(compensated_demand(W, PY)) ≈ two_by_two_AuxinDemand["DYW.L","benchmark"]#  100
    @test value(CONS) ≈ two_by_two_AuxinDemand["CONS.L","benchmark"]#  200
    @test value(demand(CONS, PW)) ≈ two_by_two_AuxinDemand["CWCONS.L","benchmark"]#  200

    set_start_value(U, .1)
    fix(CONS, 210)
    solve!(m)

    # UnEmp=.1
    @test value(X) ≈ two_by_two_AuxinDemand["X.L","UnEmp=.1"]#  1
    @test value(Y) ≈ two_by_two_AuxinDemand["Y.L","UnEmp=.1"]#  1
    @test value(W) ≈ two_by_two_AuxinDemand["W.L","UnEmp=.1"]#  1
    @test value(PX) ≈ two_by_two_AuxinDemand["PX.L","UnEmp=.1"]#  1.05
    @test value(PY) ≈ two_by_two_AuxinDemand["PY.L","UnEmp=.1"]#  1.05
    @test value(PW) ≈ two_by_two_AuxinDemand["PW.L","UnEmp=.1"]#  1.05
    @test value(PL) ≈ two_by_two_AuxinDemand["PL.L","UnEmp=.1"]#  1.05
    @test value(PK) ≈ two_by_two_AuxinDemand["PK.L","UnEmp=.1"]#  1.05
    @test value(U) ≈ two_by_two_AuxinDemand["U.L","UnEmp=.1"]#  0.2
    @test value(compensated_demand(X, PX, :t)) ≈ -two_by_two_AuxinDemand["SXX.L","UnEmp=.1"]#  100
    @test value(compensated_demand(Y, PY, :t)) ≈ -two_by_two_AuxinDemand["SYY.L","UnEmp=.1"]#  100
    @test value(compensated_demand(W, PW, :t)) ≈ -two_by_two_AuxinDemand["SWW.L","UnEmp=.1"]#  200
    @test value(compensated_demand(X, PK)) ≈ two_by_two_AuxinDemand["DKX.L","UnEmp=.1"]#  50
    @test value(compensated_demand(X, PL)) ≈ two_by_two_AuxinDemand["DLX.L","UnEmp=.1"]#  40
    @test value(compensated_demand(Y, PL)) ≈ two_by_two_AuxinDemand["DLY.L","UnEmp=.1"]#  60
    @test value(compensated_demand(Y, PK)) ≈ two_by_two_AuxinDemand["DKY.L","UnEmp=.1"]#  40
    @test value(compensated_demand(W, PX)) ≈ two_by_two_AuxinDemand["DXW.L","UnEmp=.1"]#  100
    @test value(compensated_demand(W, PY)) ≈ two_by_two_AuxinDemand["DYW.L","UnEmp=.1"]#  100
    @test value(CONS) ≈ two_by_two_AuxinDemand["CONS.L","UnEmp=.1"]#  210
    @test value(demand(CONS, PW)) ≈ two_by_two_AuxinDemand["CWCONS.L","UnEmp=.1"]#  200
        

    
    set_value!(tkx, 0.25)
    set_value!(tx, 0.0)
    unfix(CONS)
    fix(PX, 1)
    solve!(m)

    # TKX=0.25
    @test value(X) ≈ two_by_two_AuxinDemand["X.L","TKX=0.25"]#  1.0371253
    @test value(Y) ≈ two_by_two_AuxinDemand["Y.L","TKX=0.25"]#  1.05340908
    @test value(W) ≈ two_by_two_AuxinDemand["W.L","TKX=0.25"]#  1.04523548
    @test value(PX) ≈ two_by_two_AuxinDemand["PX.L","TKX=0.25"]#  1
    @test value(PY) ≈ two_by_two_AuxinDemand["PY.L","TKX=0.25"]#  0.98454183
    @test value(PW) ≈ two_by_two_AuxinDemand["PW.L","TKX=0.25"]#  0.99224081
    @test value(PL) ≈ two_by_two_AuxinDemand["PL.L","TKX=0.25"]#  0.99224081
    @test value(PK) ≈ two_by_two_AuxinDemand["PK.L","TKX=0.25"]#  0.97310522
    @test value(U) ≈ two_by_two_AuxinDemand["U.L","TKX=0.25"]#  0.10830961
    @test value(compensated_demand(X, PX, :t)) ≈ -two_by_two_AuxinDemand["SXX.L","TKX=0.25"]#  100
    @test value(compensated_demand(Y, PY, :t)) ≈ -two_by_two_AuxinDemand["SYY.L","TKX=0.25"]#  100
    @test value(compensated_demand(W, PW, :t)) ≈ -two_by_two_AuxinDemand["SWW.L","TKX=0.25"]#  200
    @test value(compensated_demand(X, PK)) ≈ two_by_two_AuxinDemand["DKX.L","TKX=0.25"]#  45.67280459
    @test value(compensated_demand(X, PL)) ≈ two_by_two_AuxinDemand["DLX.L","TKX=0.25"]#  44.79199395
    @test value(compensated_demand(Y, PL)) ≈ two_by_two_AuxinDemand["DLY.L","TKX=0.25"]#  59.53444871
    @test value(compensated_demand(Y, PK)) ≈ two_by_two_AuxinDemand["DKY.L","TKX=0.25"]#  40.4701079
    @test value(compensated_demand(W, PX)) ≈ two_by_two_AuxinDemand["DXW.L","TKX=0.25"]#  99.22408119
    @test value(compensated_demand(W, PY)) ≈ two_by_two_AuxinDemand["DYW.L","TKX=0.25"]#  100.782
    @test value(CONS) ≈ two_by_two_AuxinDemand["CONS.L","TKX=0.25"]#  207.4251
    @test value(demand(CONS, PW)) ≈ two_by_two_AuxinDemand["CWCONS.L","TKX=0.25"]#  209.0471

    set_value!(ty, 0.5)
    solve!(m)

    # &TY=.5
    @test value(X) ≈ two_by_two_AuxinDemand["X.L","&TY=.5"]#  0.98447088
    @test value(Y) ≈ two_by_two_AuxinDemand["Y.L","&TY=.5"]#  0.44661553
    @test value(W) ≈ two_by_two_AuxinDemand["W.L","&TY=.5"]#  0.66308369
    @test value(PX) ≈ two_by_two_AuxinDemand["PX.L","&TY=.5"]#  1
    @test value(PY) ≈ two_by_two_AuxinDemand["PY.L","&TY=.5"]#  2.20429163
    @test value(PW) ≈ two_by_two_AuxinDemand["PW.L","&TY=.5"]#  1.4846857
    @test value(PL) ≈ two_by_two_AuxinDemand["PL.L","&TY=.5"]#  1.4846857
    @test value(PK) ≈ two_by_two_AuxinDemand["PK.L","&TY=.5"]#  0.70492977
    @test value(U) ≈ two_by_two_AuxinDemand["U.L","&TY=.5"]#  0.70637103
    @test value(compensated_demand(X, PX, :t)) ≈ -two_by_two_AuxinDemand["SXX.L","&TY=.5"]#  100
    @test value(compensated_demand(Y, PY, :t)) ≈ -two_by_two_AuxinDemand["SYY.L","&TY=.5"]#  100
    @test value(compensated_demand(W, PW, :t)) ≈ -two_by_two_AuxinDemand["SWW.L","&TY=.5"]#  200
    @test value(compensated_demand(X, PK)) ≈ two_by_two_AuxinDemand["DKX.L","&TY=.5"]#  63.04804615
    @test value(compensated_demand(X, PL)) ≈ two_by_two_AuxinDemand["DLX.L","&TY=.5"]#  29.9352546
    @test value(compensated_demand(Y, PL)) ≈ two_by_two_AuxinDemand["DLY.L","&TY=.5"]#  44.54057096
    @test value(compensated_demand(Y, PK)) ≈ two_by_two_AuxinDemand["DKY.L","&TY=.5"]#  62.53932609
    @test value(compensated_demand(W, PX)) ≈ two_by_two_AuxinDemand["DXW.L","&TY=.5"]#  148.4686
    @test value(compensated_demand(W, PY)) ≈ two_by_two_AuxinDemand["DYW.L","&TY=.5"]#  67.35432289
    @test value(CONS) ≈ two_by_two_AuxinDemand["CONS.L","&TY=.5"]#  196.8942
    @test value(demand(CONS, PW)) ≈ two_by_two_AuxinDemand["CWCONS.L","&TY=.5"]#  132.6167

    set_value!(tkx, 0.0)
    solve!(m)

    # TY=0.5
    @test value(X) ≈ two_by_two_AuxinDemand["X.L","TY=0.5"]#  1.00693677
    @test value(Y) ≈ two_by_two_AuxinDemand["Y.L","TY=0.5"]#  0.41177381
    @test value(W) ≈ two_by_two_AuxinDemand["W.L","TY=0.5"]#  0.64391785
    @test value(PX) ≈ two_by_two_AuxinDemand["PX.L","TY=0.5"]#  1
    @test value(PY) ≈ two_by_two_AuxinDemand["PY.L","TY=0.5"]#  2.44536378
    @test value(PW) ≈ two_by_two_AuxinDemand["PW.L","TY=0.5"]#  1.5637659
    @test value(PL) ≈ two_by_two_AuxinDemand["PL.L","TY=0.5"]#  1.5637659
    @test value(PK) ≈ two_by_two_AuxinDemand["PK.L","TY=0.5"]#  0.84532963
    @test value(U) ≈ two_by_two_AuxinDemand["U.L","TY=0.5"]#  0.72063894
    @test value(compensated_demand(X, PX, :t)) ≈ -two_by_two_AuxinDemand["SXX.L","TY=0.5"]#  100
    @test value(compensated_demand(Y, PY, :t)) ≈ -two_by_two_AuxinDemand["SYY.L","TY=0.5"]#  100
    @test value(compensated_demand(W, PW, :t)) ≈ -two_by_two_AuxinDemand["SWW.L","TY=0.5"]#  200
    @test value(compensated_demand(X, PK)) ≈ two_by_two_AuxinDemand["DKX.L","TY=0.5"]#  65.7205822
    @test value(compensated_demand(X, PL)) ≈ two_by_two_AuxinDemand["DLX.L","TY=0.5"]#  28.42141815
    @test value(compensated_demand(Y, PL)) ≈ two_by_two_AuxinDemand["DLY.L","TY=0.5"]#  46.91297691
    @test value(compensated_demand(Y, PK)) ≈ two_by_two_AuxinDemand["DKY.L","TY=0.5"]#  57.85586329
    @test value(compensated_demand(W, PX)) ≈ two_by_two_AuxinDemand["DXW.L","TY=0.5"]#  156.3766
    @test value(compensated_demand(W, PY)) ≈ two_by_two_AuxinDemand["DYW.L","TY=0.5"]#  63.94819083
    @test value(CONS) ≈ two_by_two_AuxinDemand["CONS.L","TY=0.5"]#  201.3874
    @test value(demand(CONS, PW)) ≈ two_by_two_AuxinDemand["CWCONS.L","TY=0.5"]#  128.7836

    

end




@testitem "TWObyTWO_wAuxinInputs" begin
    using XLSX, MPSGE.JuMP.Containers
    import JuMP
    gams_results = XLSX.readxlsx(joinpath(@__DIR__, "MPSGEresults.xlsx"))
    a_table = gams_results["two_by_two_AuxinInput"][:]  # Generated from TwoByTwo_Scalar_Algeb-MPSGE.gms
    two_by_two_AuxinInput = DenseAxisArray(a_table[2:end,2:end],a_table[2:end,1],a_table[1,2:end])
        
    # A replication of the Markusen M2_3S model, with Auxiliary constraint in associated with Inputs: AuxinProdTest.gms

    m = MPSGEModel()
    # A set up to test N: Endogenous taxes (and M: the multiplier), the Auxiliary Variable in Production blocks (applied to Inputs or Outputs)       
    @parameters(m, begin
        txl, 0.2
        txk, 0.2
    end)       

    @sectors(m,begin
        X
        Y
        W
        TL
        TK
    end)

    @commodities(m, begin
        PX
        PY
        PW
        PL
        PK
        PKS
        PLS
    end)

    @consumer(m, CONS)

    @auxiliary(m, TAU) #benchmark = .2

    #@parameter(m, U, 0.2)

    @production(m, X, [t = 0, s = 1], begin
        @output(PX, 120, t)
        @input(PLS, 48, s)
        @input(PKS, 72, s)
    end)

    @production(m, Y, [t = 0, s = 1], begin
        @output(PY, 120, t)
        @input(PLS, 72, s) 
        @input(PKS, 48, s)
    end)

    @production(m, W, [t = 0, s = .7, AW => s = 1], begin
        @output(PW, 340, t)
        @input(PL, 100, s)
        @input(PX, 120, AW)
        @input(PY, 120, AW)
    end)


    @production(m, TL, [t = 0, s = 1], begin
        @output(PLS, 120, t)
        @input(PL, 100, s, taxes=[Tax(CONS, txl*TAU)])
    end)
            
    @production(m, TK, [t = 0, s = 1], begin
        @output(PKS, 120, t)
        @input(PK, 100, s, taxes=[Tax(CONS, txk*TAU)])
    end)    
            
    @demand(m, CONS, begin
            @final_demand(PW,340)            
            @endowment(PL, 200.)
            @endowment(PK, 100)
    end)

    @aux_constraint(m, TAU, 
        W*PW*340 - PL * 200 - PK * 100  - 40 * (PX + PY)/2
    )


    set_start_value(TAU, 1)

    fix(CONS, 340)
    solve!(m, cumulative_iteration_limit=0)

    # benchmark
    @test value(X) ≈ two_by_two_AuxinInput["X","benchmark"]#  1
    @test value(Y) ≈ two_by_two_AuxinInput["Y","benchmark"]#  1
    @test value(W) ≈ two_by_two_AuxinInput["W","benchmark"]#  1
    @test value(TL) ≈ two_by_two_AuxinInput["TL","benchmark"]#  1
    @test value(TK) ≈ two_by_two_AuxinInput["TK","benchmark"]#  1
    @test value(PX) ≈ two_by_two_AuxinInput["PX","benchmark"]#  1
    @test value(PY) ≈ two_by_two_AuxinInput["PY","benchmark"]#  1
    @test value(PW) ≈ two_by_two_AuxinInput["PW","benchmark"]#  1
    @test value(PL) ≈ two_by_two_AuxinInput["PL","benchmark"]#  1
    @test value(PK) ≈ two_by_two_AuxinInput["PK","benchmark"]#  1
    @test value(PKS) ≈ two_by_two_AuxinInput["PKS","benchmark"]#  1
    @test value(PLS) ≈ two_by_two_AuxinInput["PLS","benchmark"]#  1
    @test value(TAU) ≈ two_by_two_AuxinInput["TAU","benchmark"]#  1
    @test value(compensated_demand(X, PX, :t)) ≈ -two_by_two_AuxinInput["SXX","benchmark"]#  120
    @test value(compensated_demand(Y, PY, :t)) ≈ -two_by_two_AuxinInput["SYY","benchmark"]#  120
    @test value(compensated_demand(W, PW, :t)) ≈ -two_by_two_AuxinInput["SWW","benchmark"]#  340
    @test value(compensated_demand(TL, PLS, :t)) ≈ -two_by_two_AuxinInput["SLSTL","benchmark"]#  120
    @test value(compensated_demand(TK, PKS, :t)) ≈ -two_by_two_AuxinInput["SKSTK","benchmark"]#  120
    @test value(compensated_demand(X, PLS)) ≈ two_by_two_AuxinInput["DLSX","benchmark"]#  48
    @test value(compensated_demand(X, PKS)) ≈ two_by_two_AuxinInput["DKSX","benchmark"]#  72
    @test value(compensated_demand(Y, PLS)) ≈ two_by_two_AuxinInput["DLSY","benchmark"]#  72
    @test value(compensated_demand(Y, PKS)) ≈ two_by_two_AuxinInput["DKSY","benchmark"]#  48
    # @test value(m._jump_model[Symbol("PX†W→AW")]) ≈ two_by_two_AuxinInput["DXW","benchmark"]#  120# Not clear how to report equivalent values from nests in GAMS
    # @test value(m._jump_model[Symbol("PY†W→AW")]) ≈ two_by_two_AuxinInput["DYW","benchmark"]#  120# Not clear how to report equivalent values from nests in GAMS
    @test value(compensated_demand(W, PL)) ≈ two_by_two_AuxinInput["DLW","benchmark"]#  100
    @test value(compensated_demand(TL, PL)) ≈ two_by_two_AuxinInput["DLTL","benchmark"]#  100
    @test value(compensated_demand(TK, PK)) ≈ two_by_two_AuxinInput["DKTK","benchmark"]#  100
    @test value(CONS) ≈ two_by_two_AuxinInput["CONS","benchmark"]#  340
    @test value(demand(CONS, PW)) ≈ two_by_two_AuxinInput["CWCONS","benchmark"]#  340

    set_value!(txl, 0.15)
    set_value!(txk, 0.25)
    solve!(m)
    # L.15,K.25
    @test value(X) ≈ two_by_two_AuxinInput["X","L.15,K.25"]#  1.0063876
    @test value(Y) ≈ two_by_two_AuxinInput["Y","L.15,K.25"]#  1.0095966
    @test value(W) ≈ two_by_two_AuxinInput["W","L.15,K.25"]#  1.000835
    @test value(TL) ≈ two_by_two_AuxinInput["TL","L.15,K.25"]#  1.0160455
    @test value(TK) ≈ two_by_two_AuxinInput["TK","L.15,K.25"]#  1
    @test value(PX) ≈ two_by_two_AuxinInput["PX","L.15,K.25"]#  0.9906237
    @test value(PY) ≈ two_by_two_AuxinInput["PY","L.15,K.25"]#  0.9874749
    @test value(PW) ≈ two_by_two_AuxinInput["PW","L.15,K.25"]#  0.9991657
    @test value(PL) ≈ two_by_two_AuxinInput["PL","L.15,K.25"]#  1.0237433
    @test value(PK) ≈ two_by_two_AuxinInput["PK","L.15,K.25"]#  0.9568937
    @test value(PKS) ≈ two_by_two_AuxinInput["PKS","L.15,K.25"]#  0.9969513
    @test value(PLS) ≈ two_by_two_AuxinInput["PLS","L.15,K.25"]#  0.9812074
    @test value(TAU) ≈ two_by_two_AuxinInput["TAU","L.15,K.25"]#  1.0009382
    @test value(compensated_demand(X, PX, :t)) ≈ -two_by_two_AuxinInput["SXX","L.15,K.25"]#  120
    @test value(compensated_demand(Y, PY, :t)) ≈ -two_by_two_AuxinInput["SYY","L.15,K.25"]#  120
    @test value(compensated_demand(W, PW, :t)) ≈ -two_by_two_AuxinInput["SWW","L.15,K.25"]#  340
    @test value(compensated_demand(TL, PLS, :t)) ≈ -two_by_two_AuxinInput["SLSTL","L.15,K.25"]#  120
    @test value(compensated_demand(TK, PKS, :t)) ≈ -two_by_two_AuxinInput["SKSTK","L.15,K.25"]#  120
    @test value(compensated_demand(X, PLS)) ≈ two_by_two_AuxinInput["DLSX","L.15,K.25"]#  48.4606391
    @test value(compensated_demand(X, PKS)) ≈ two_by_two_AuxinInput["DKSX","L.15,K.25"]#  71.5430136
    @test value(compensated_demand(Y, PLS)) ≈ two_by_two_AuxinInput["DLSY","L.15,K.25"]#  72.4599054
    @test value(compensated_demand(Y, PKS)) ≈ two_by_two_AuxinInput["DKSY","L.15,K.25"]#  47.5437395
    # @test value(m._jump_model[Symbol("PX†W→AW")]) ≈ two_by_two_AuxinInput["DXW","L.15,K.25"]#  120.6657499# Not clear how to report equivalent values from nests in GAMS
    # @test value(m._jump_model[Symbol("PY†W→AW")]) ≈ two_by_two_AuxinInput["DYW","L.15,K.25"]#  121.0505173# Not clear how to report equivalent values from nests in GAMS
    @test value(compensated_demand(W, PL)) ≈ two_by_two_AuxinInput["DLW","L.15,K.25"]#  98.3133534
    @test value(compensated_demand(TL, PL)) ≈ two_by_two_AuxinInput["DLTL","L.15,K.25"]#  100
    @test value(compensated_demand(TK, PK)) ≈ two_by_two_AuxinInput["DKTK","L.15,K.25"]#  100
    @test value(CONS) ≈ two_by_two_AuxinInput["CONS","L.15,K.25"]#  340
    @test value(demand(CONS, PW)) ≈ two_by_two_AuxinInput["CWCONS","L.15,K.25"]#  340.2839092

    fix(CONS,339.5832292)
    set_value!(txl, 0.1)
    set_value!(txk, 0.3)
    solve!(m)
    # L.1,K.3
    @test value(X) ≈ two_by_two_AuxinInput["X","L.1,K.3"]#  1.0126853
    @test value(Y) ≈ two_by_two_AuxinInput["Y","L.1,K.3"]#  1.0190881
    @test value(W) ≈ two_by_two_AuxinInput["W","L.1,K.3"]#  1.0014491
    @test value(TL) ≈ two_by_two_AuxinInput["TL","L.1,K.3"]#  1.0320155
    @test value(TK) ≈ two_by_two_AuxinInput["TK","L.1,K.3"]#  1
    @test value(PX) ≈ two_by_two_AuxinInput["PX","L.1,K.3"]#  0.9802336
    @test value(PY) ≈ two_by_two_AuxinInput["PY","L.1,K.3"]#  0.9740749
    @test value(PW) ≈ two_by_two_AuxinInput["PW","L.1,K.3"]#  0.997329
    @test value(PL) ≈ two_by_two_AuxinInput["PL","L.1,K.3"]#  1.0469473
    @test value(PK) ≈ two_by_two_AuxinInput["PK","L.1,K.3"]#  0.9110759
    @test value(PKS) ≈ two_by_two_AuxinInput["PKS","L.1,K.3"]#  0.9926681
    @test value(PLS) ≈ two_by_two_AuxinInput["PLS","L.1,K.3"]#  0.9618733
    @test value(TAU) ≈ two_by_two_AuxinInput["TAU","L.1,K.3"]#  1.0248901
    @test value(compensated_demand(X, PX, :t)) ≈ -two_by_two_AuxinInput["SXX","L.1,K.3"]#  120
    @test value(compensated_demand(Y, PY, :t)) ≈ -two_by_two_AuxinInput["SYY","L.1,K.3"]#  120
    @test value(compensated_demand(W, PW, :t)) ≈ -two_by_two_AuxinInput["SWW","L.1,K.3"]#  340
    @test value(compensated_demand(TL, PLS, :t)) ≈ -two_by_two_AuxinInput["SLSTL","L.1,K.3"]#  120
    @test value(compensated_demand(TK, PKS, :t)) ≈ -two_by_two_AuxinInput["SKSTK","L.1,K.3"]#  120
    @test value(compensated_demand(X, PLS)) ≈ two_by_two_AuxinInput["DLSX","L.1,K.3"]#  48.916229
    @test value(compensated_demand(X, PKS)) ≈ two_by_two_AuxinInput["DKSX","L.1,K.3"]#  71.0981022
    @test value(compensated_demand(Y, PLS)) ≈ two_by_two_AuxinInput["DLSY","L.1,K.3"]#  72.9133386
    @test value(compensated_demand(Y, PKS)) ≈ two_by_two_AuxinInput["DKSY","L.1,K.3"]#  47.1009325
    # @test value(m._jump_model[Symbol("PX†W→AW")]) ≈ two_by_two_AuxinInput["DXW","L.1,K.3"]#  121.3463868# Not clear how to report equivalent values from nests in GAMS
    # @test value(m._jump_model[Symbol("PY†W→AW")]) ≈ two_by_two_AuxinInput["DYW","L.1,K.3"]#  122.1136165# Not clear how to report equivalent values from nests in GAMS
    @test value(compensated_demand(W, PL)) ≈ two_by_two_AuxinInput["DLW","L.1,K.3"]#  96.6583816
    @test value(compensated_demand(TL, PL)) ≈ two_by_two_AuxinInput["DLTL","L.1,K.3"]#  100
    @test value(compensated_demand(TK, PK)) ≈ two_by_two_AuxinInput["DKTK","L.1,K.3"]#  100
    @test value(CONS) ≈ two_by_two_AuxinInput["CONS","L.1,K.3"]#  339.5832292
    @test value(demand(CONS, PW)) ≈ two_by_two_AuxinInput["CWCONS","L.1,K.3"]#  340.492697

    fix(CONS,338.7151989)
    set_value!(txl, 0.05)
    set_value!(txk, 0.35)
    solve!(m)
    # L.05,K.35
    @test value(X) ≈ two_by_two_AuxinInput["X","L.05,K.35"]#  1.0193022
    @test value(Y) ≈ two_by_two_AuxinInput["Y","L.05,K.35"]#  1.0290926
    @test value(W) ≈ two_by_two_AuxinInput["W","L.05,K.35"]#  1.0018622
    @test value(TL) ≈ two_by_two_AuxinInput["TL","L.05,K.35"]#  1.0489564
    @test value(TK) ≈ two_by_two_AuxinInput["TK","L.05,K.35"]#  1
    @test value(PX) ≈ two_by_two_AuxinInput["PX","L.05,K.35"]#  0.9681687
    @test value(PY) ≈ two_by_two_AuxinInput["PY","L.05,K.35"]#  0.958958
    @test value(PW) ≈ two_by_two_AuxinInput["PW","L.05,K.35"]#  0.9943695
    @test value(PL) ≈ two_by_two_AuxinInput["PL","L.05,K.35"]#  1.0711352
    @test value(PK) ≈ two_by_two_AuxinInput["PK","L.05,K.35"]#  0.8594563
    @test value(PKS) ≈ two_by_two_AuxinInput["PKS","L.05,K.35"]#  0.9868565
    @test value(PLS) ≈ two_by_two_AuxinInput["PLS","L.05,K.35"]#  0.9407985
    @test value(TAU) ≈ two_by_two_AuxinInput["TAU","L.05,K.35"]#  1.0796579
    @test value(compensated_demand(X, PX, :t)) ≈ -two_by_two_AuxinInput["SXX","L.05,K.35"]#  120
    @test value(compensated_demand(Y, PY, :t)) ≈ -two_by_two_AuxinInput["SYY","L.05,K.35"]#  120
    @test value(compensated_demand(W, PW, :t)) ≈ -two_by_two_AuxinInput["SWW","L.05,K.35"]#  340
    @test value(compensated_demand(TL, PLS, :t)) ≈ -two_by_two_AuxinInput["SLSTL","L.05,K.35"]#  120
    @test value(compensated_demand(TK, PKS, :t)) ≈ -two_by_two_AuxinInput["SKSTK","L.05,K.35"]#  120
    @test value(compensated_demand(X, PLS)) ≈ two_by_two_AuxinInput["DLSX","L.05,K.35"]#  49.3964451
    @test value(compensated_demand(X, PKS)) ≈ two_by_two_AuxinInput["DKSX","L.05,K.35"]#  70.6365574
    @test value(compensated_demand(Y, PLS)) ≈ two_by_two_AuxinInput["DLSY","L.05,K.35"]#  73.3897601
    @test value(compensated_demand(Y, PKS)) ≈ two_by_two_AuxinInput["DKSY","L.05,K.35"]#  46.6430327
    # @test value(m._jump_model[Symbol("PX†W→AW")]) ≈ two_by_two_AuxinInput["DXW","L.05,K.35"]#  122.0889143# Not clear how to report equivalent values from nests in GAMS
    # @test value(m._jump_model[Symbol("PY†W→AW")]) ≈ two_by_two_AuxinInput["DYW","L.05,K.35"]#  123.2615764# Not clear how to report equivalent values from nests in GAMS
    @test value(compensated_demand(W, PL)) ≈ two_by_two_AuxinInput["DLW","L.05,K.35"]#  94.9275888
    @test value(compensated_demand(TL, PL)) ≈ two_by_two_AuxinInput["DLTL","L.05,K.35"]#  100
    @test value(compensated_demand(TK, PK)) ≈ two_by_two_AuxinInput["DKTK","L.05,K.35"]#  100
    @test value(CONS) ≈ two_by_two_AuxinInput["CONS","L.05,K.35"]#  338.7151989
    @test value(demand(CONS, PW)) ≈ two_by_two_AuxinInput["CWCONS","L.05,K.35"]#  340.6331441

    fix(CONS,337.2894147)
    set_value!(txl, 0.)
    set_value!(txk, 0.4)
    solve!(m)
    # L.0,K.4
    @test value(X) ≈ two_by_two_AuxinInput["X","L.0,K.4"]#  1.0269283
    @test value(Y) ≈ two_by_two_AuxinInput["Y","L.0,K.4"]#  1.0406632
    @test value(W) ≈ two_by_two_AuxinInput["W","L.0,K.4"]#  1.0020312
    @test value(TL) ≈ two_by_two_AuxinInput["TL","L.0,K.4"]#  1.0686865
    @test value(TK) ≈ two_by_two_AuxinInput["TK","L.0,K.4"]#  1
    @test value(PX) ≈ two_by_two_AuxinInput["PX","L.0,K.4"]#  0.9531893
    @test value(PY) ≈ two_by_two_AuxinInput["PY","L.0,K.4"]#  0.9406089
    @test value(PW) ≈ two_by_two_AuxinInput["PW","L.0,K.4"]#  0.9900167
    @test value(PL) ≈ two_by_two_AuxinInput["PL","L.0,K.4"]#  1.0991329
    @test value(PK) ≈ two_by_two_AuxinInput["PK","L.0,K.4"]#  0.7958688
    @test value(PKS) ≈ two_by_two_AuxinInput["PKS","L.0,K.4"]#  0.978857
    @test value(PLS) ≈ two_by_two_AuxinInput["PLS","L.0,K.4"]#  0.915944
    @test value(TAU) ≈ two_by_two_AuxinInput["TAU","L.0,K.4"] atol=1.0e-6 #  1.1897678 May be related to numerical precision on copying the fix value for CONS 
    @test value(compensated_demand(X, PX, :t)) ≈ -two_by_two_AuxinInput["SXX","L.0,K.4"]#  120
    @test value(compensated_demand(Y, PY, :t)) ≈ -two_by_two_AuxinInput["SYY","L.0,K.4"]#  120
    @test value(compensated_demand(W, PW, :t)) ≈ -two_by_two_AuxinInput["SWW","L.0,K.4"]#  340
    @test value(compensated_demand(TL, PLS, :t)) ≈ -two_by_two_AuxinInput["SLSTL","L.0,K.4"]#  120
    @test value(compensated_demand(TK, PKS, :t)) ≈ -two_by_two_AuxinInput["SKSTK","L.0,K.4"]#  120
    @test value(compensated_demand(X, PLS)) ≈ two_by_two_AuxinInput["DLSX","L.0,K.4"]#  49.9518331
    @test value(compensated_demand(X, PKS)) ≈ two_by_two_AuxinInput["DKSX","L.0,K.4"]#  70.1120019
    @test value(compensated_demand(Y, PLS)) ≈ two_by_two_AuxinInput["DLSY","L.0,K.4"]#  73.9388387
    @test value(compensated_demand(Y, PKS)) ≈ two_by_two_AuxinInput["DKSY","L.0,K.4"]#  46.1244334
    # @test value(m._jump_model[Symbol("PX†W→AW")]) ≈ two_by_two_AuxinInput["DXW","L.0,K.4"]#  122.9815938# Not clear how to report equivalent values from nests in GAMS
    # @test value(m._jump_model[Symbol("PY†W→AW")]) ≈ two_by_two_AuxinInput["DYW","L.0,K.4"]#  124.6264376# Not clear how to report equivalent values from nests in GAMS
    @test value(compensated_demand(W, PL)) ≈ two_by_two_AuxinInput["DLW","L.0,K.4"]#  92.9425627
    @test value(compensated_demand(TL, PL)) ≈ two_by_two_AuxinInput["DLTL","L.0,K.4"]#  100
    @test value(compensated_demand(TK, PK)) ≈ two_by_two_AuxinInput["DKTK","L.0,K.4"]#  100
    @test value(CONS) ≈ two_by_two_AuxinInput["CONS","L.0,K.4"]#  337.2894147
    @test value(demand(CONS, PW)) ≈ two_by_two_AuxinInput["CWCONS","L.0,K.4"]#  340.6906185

    fix(CONS,335.0362347)
    set_value!(txl, -0.05)
    set_value!(txk, 0.45)
    solve!(m)
    # L-.05,K.45
    @test value(X) ≈ two_by_two_AuxinInput["X","L-.05,K.45"]#  1.0377546
    @test value(Y) ≈ two_by_two_AuxinInput["Y","L-.05,K.45"]#  1.0571631
    @test value(W) ≈ two_by_two_AuxinInput["W","L-.05,K.45"]#  1.0016777
    @test value(TL) ≈ two_by_two_AuxinInput["TL","L-.05,K.45"]#  1.0970758
    @test value(TK) ≈ two_by_two_AuxinInput["TK","L-.05,K.45"]#  1
    @test value(PX) ≈ two_by_two_AuxinInput["PX","L-.05,K.45"]#  0.9315541
    @test value(PY) ≈ two_by_two_AuxinInput["PY","L-.05,K.45"]#  0.9144517
    @test value(PW) ≈ two_by_two_AuxinInput["PW","L-.05,K.45"]#  0.9837502
    @test value(PL) ≈ two_by_two_AuxinInput["PL","L-.05,K.45"]#  1.1409856
    @test value(PK) ≈ two_by_two_AuxinInput["PK","L-.05,K.45"]#  0.69919
    @test value(PKS) ≈ two_by_two_AuxinInput["PKS","L-.05,K.45"]#  0.9667245
    @test value(PLS) ≈ two_by_two_AuxinInput["PLS","L-.05,K.45"]#  0.881183
    @test value(TAU) ≈ two_by_two_AuxinInput["TAU","L-.05,K.45"]#  1.4648042
    @test value(compensated_demand(X, PX, :t)) ≈ -two_by_two_AuxinInput["SXX","L-.05,K.45"]#  120
    @test value(compensated_demand(Y, PY, :t)) ≈ -two_by_two_AuxinInput["SYY","L-.05,K.45"]#  120
    @test value(compensated_demand(W, PW, :t)) ≈ -two_by_two_AuxinInput["SWW","L-.05,K.45"]#  340
    @test value(compensated_demand(TL, PLS, :t)) ≈ -two_by_two_AuxinInput["SLSTL","L-.05,K.45"]#  120
    @test value(compensated_demand(TK, PKS, :t)) ≈ -two_by_two_AuxinInput["SKSTK","L-.05,K.45"]#  120
    @test value(compensated_demand(X, PLS)) ≈ two_by_two_AuxinInput["DLSX","L-.05,K.45"]#  50.743827
    @test value(compensated_demand(X, PKS)) ≈ two_by_two_AuxinInput["DKSX","L-.05,K.45"]#  69.3805667
    @test value(compensated_demand(Y, PLS)) ≈ two_by_two_AuxinInput["DLSY","L-.05,K.45"]#  74.7183289
    @test value(compensated_demand(Y, PKS)) ≈ two_by_two_AuxinInput["DKSY","L-.05,K.45"]#  45.4045376
    # @test value(m._jump_model[Symbol("PX†W→AW")]) ≈ two_by_two_AuxinInput["DXW","L-.05,K.45"]#  124.3219708# Not clear how to report equivalent values from nests in GAMS
    # @test value(m._jump_model[Symbol("PY†W→AW")]) ≈ two_by_two_AuxinInput["DYW","L-.05,K.45"]#  126.6470893# Not clear how to report equivalent values from nests in GAMS
    @test value(compensated_demand(W, PL)) ≈ two_by_two_AuxinInput["DLW","L-.05,K.45"]#  90.1411886
    @test value(compensated_demand(TL, PL)) ≈ two_by_two_AuxinInput["DLTL","L-.05,K.45"]#  100
    @test value(compensated_demand(TK, PK)) ≈ two_by_two_AuxinInput["DKTK","L-.05,K.45"]#  100
    @test value(CONS) ≈ two_by_two_AuxinInput["CONS","L-.05,K.45"]#  335.0362347
    @test value(demand(CONS, PW)) ≈ two_by_two_AuxinInput["CWCONS","L-.05,K.45"]#  340.5704246
end





@testitem "TWObyTWO_wAuxinOutputs" begin
    using XLSX, MPSGE.JuMP.Containers
    import JuMP
    gams_results = XLSX.readxlsx(joinpath(@__DIR__, "MPSGEresults.xlsx"))
    a_table = gams_results["two_by_two_AuxinOutput"][:]  # Generated from AuxinOutputTest.gms
    two_by_two_AuxinOutput = DenseAxisArray(a_table[2:end,2:end],a_table[2:end,1],a_table[1,2:end])
        
    m = MPSGEModel()
    # A set up to test N: Endogenous taxes (and M: the multiplier), the Auxiliary Variable in Production blocks (applied to Outputs)       
    
    @parameter(m, sigma, 9)       
    
    @sectors(m,begin
        X
        Y
        W
    end)
    
    @commodities(m, begin
        PX
        PY
        PW
        PL
        PK
    end)
    
    @consumer(m, CONS)
    
    @auxiliary(m, SHAREX) #benchmark = .5
    @auxiliary(m, MARKUP[i = [:a,:b]]) #benchmark = .2
    
    
    @production(m, X, [t = 0, s = 1], begin
        @output(PX, 80, t, taxes = [Tax(CONS, MARKUP[:a])])
        @input(PL, 14, s)
        @input(PK, 50, s)
    end)
    
    @production(m, Y, [t = 0, s = 1], begin
        @output(PY, 100, t)
        @input(PL, 60, s) 
        @input(PK, 40, s)
    end)
    
    @production(m, W, [t = 0, s = 9], begin
        @output(PW, 180, t)
        @input(PX, 80,  s)
        @input(PY, 100, s)
    end)
    
    @demand(m, CONS, begin
            @final_demand(PW, 180)
            @endowment(PL, 74)
            @endowment(PK, 90)
    end)
    
    @aux_constraint(m, SHAREX, 
        SHAREX - 100*PX*X / (100*PX*X + 100*PY*Y)
    )
    
    @aux_constraint(m, MARKUP[:a],
        (MARKUP[:a]) - 1 / (sigma - (sigma-1) * SHAREX)
    )
    
    @aux_constraint(m, MARKUP[:b],
        MARKUP[:b] - MARKUP[:b]
    )
    
    
    
    set_start_value(SHAREX, .5)
    
    set_start_value(MARKUP[:a], .2)
    set_start_value(MARKUP[:b], .2)

    fix(CONS, 180)
    solve!(m, cumulative_iteration_limit=0)
    # benchmark
    @test value(X) ≈ two_by_two_AuxinOutput["X","benchmark"]#  1
    @test value(Y) ≈ two_by_two_AuxinOutput["Y","benchmark"]#  1
    @test value(W) ≈ two_by_two_AuxinOutput["W","benchmark"]#  1
    @test value(PX) ≈ two_by_two_AuxinOutput["PX","benchmark"]#  1
    @test value(PY) ≈ two_by_two_AuxinOutput["PY","benchmark"]#  1
    @test value(PW) ≈ two_by_two_AuxinOutput["PW","benchmark"]#  1
    @test value(PL) ≈ two_by_two_AuxinOutput["PL","benchmark"]#  1
    @test value(PK) ≈ two_by_two_AuxinOutput["PK","benchmark"]#  1
    @test value(SHAREX) ≈ two_by_two_AuxinOutput["SHAREX","benchmark"]#  0.5
    @test value(MARKUP[:a]) ≈ two_by_two_AuxinOutput["MARKUP","benchmark"]#  0.2
    @test value(compensated_demand(X, PX, :t)) ≈ -two_by_two_AuxinOutput["SXX","benchmark"]#  80
    @test value(compensated_demand(Y, PY, :t)) ≈ -two_by_two_AuxinOutput["SYY","benchmark"]#  100
    @test value(compensated_demand(W, PW, :t)) ≈ -two_by_two_AuxinOutput["SWW","benchmark"]#  180
    @test value(compensated_demand(X, PL)) ≈ two_by_two_AuxinOutput["DLX","benchmark"]#  14
    @test value(compensated_demand(X, PK)) ≈ two_by_two_AuxinOutput["DKX","benchmark"]#  50
    @test value(compensated_demand(Y, PL)) ≈ two_by_two_AuxinOutput["DLY","benchmark"]#  60
    @test value(compensated_demand(Y, PK)) ≈ two_by_two_AuxinOutput["DKY","benchmark"]#  40
    @test value(compensated_demand(W, PX)) ≈ two_by_two_AuxinOutput["DXW","benchmark"]#  80
    @test value(compensated_demand(W, PY)) ≈ two_by_two_AuxinOutput["DYW","benchmark"]#  100
    @test value(CONS) ≈ two_by_two_AuxinOutput["CONS","benchmark"]#  180
    @test value(demand(CONS, PW)) ≈ two_by_two_AuxinOutput["CWCONS","benchmark"]#  180

    fix(CONS, 164.)
    fix(MARKUP[:a], 0)
    
    solve!(m)
    # S.5,M.FX=0
    @test value(X) ≈ two_by_two_AuxinOutput["X","S.5,M.FX=0"]#  1.47532914
    @test value(Y) ≈ two_by_two_AuxinOutput["Y","S.5,M.FX=0"]#  0.67462967
    @test value(W) ≈ two_by_two_AuxinOutput["W","S.5,M.FX=0"]#  1.02198842
    @test value(PX) ≈ two_by_two_AuxinOutput["PX","S.5,M.FX=0"]#  0.85587331
    @test value(PY) ≈ two_by_two_AuxinOutput["PY","S.5,M.FX=0"]#  0.93361463
    @test value(PW) ≈ two_by_two_AuxinOutput["PW","S.5,M.FX=0"]#  0.89150825
    @test value(PL) ≈ two_by_two_AuxinOutput["PL","S.5,M.FX=0"]#  0.8092947
    @test value(PK) ≈ two_by_two_AuxinOutput["PK","S.5,M.FX=0"]#  1.15680214
    @test value(SHAREX) ≈ two_by_two_AuxinOutput["SHAREX","S.5,M.FX=0"] atol = 1e-7#  0.66719622
    @test value(MARKUP[:a]) ≈0 # two_by_two_AuxinOutput["MARKUP","S.5,M.FX=0"]#  
    @test value(compensated_demand(X, PX, :t)) ≈ -two_by_two_AuxinOutput["SXX","S.5,M.FX=0"]#  80
    @test value(compensated_demand(Y, PY, :t)) ≈ -two_by_two_AuxinOutput["SYY","S.5,M.FX=0"]#  100
    @test value(compensated_demand(W, PW, :t)) ≈ -two_by_two_AuxinOutput["SWW","S.5,M.FX=0"]#  180
    @test value(compensated_demand(X, PL)) ≈ two_by_two_AuxinOutput["DLX","S.5,M.FX=0"]#  18.50720517
    @test value(compensated_demand(X, PK)) ≈ two_by_two_AuxinOutput["DKX","S.5,M.FX=0"]#  46.2413409
    @test value(compensated_demand(Y, PL)) ≈ two_by_two_AuxinOutput["DLY","S.5,M.FX=0"]#  69.21690976
    @test value(compensated_demand(Y, PK)) ≈ two_by_two_AuxinOutput["DKY","S.5,M.FX=0"]#  32.28260394
    @test value(compensated_demand(W, PX)) ≈ two_by_two_AuxinOutput["DXW","S.5,M.FX=0"]#  115.4869552
    @test value(compensated_demand(W, PY)) ≈ two_by_two_AuxinOutput["DYW","S.5,M.FX=0"]#  66.01147878
    @test value(CONS) ≈ two_by_two_AuxinOutput["CONS","S.5,M.FX=0"]#  164
    @test value(demand(CONS, PW)) ≈ two_by_two_AuxinOutput["CWCONS","S.5,M.FX=0"]#  183.9579158


    fix(CONS,214.5077935)
    #set_value!(SHAREX, 0.2)
    fix(SHAREX, .2)
    unfix(MARKUP[:a])
    set_start_value(MARKUP[:a], 0.5)
    solve!(m)
    # S.FX.2,M.5
    @test value(X) ≈ two_by_two_AuxinOutput["X","S.FX.2,M.5"]#  1.17202012
    @test value(Y) ≈ two_by_two_AuxinOutput["Y","S.FX.2,M.5"]#  0.8873001
    @test value(W) ≈ two_by_two_AuxinOutput["W","S.FX.2,M.5"]#  1.01275399
    @test value(PX) ≈ two_by_two_AuxinOutput["PX","S.FX.2,M.5"]#  1.15776045
    @test value(PY) ≈ two_by_two_AuxinOutput["PY","S.FX.2,M.5"]#  1.19412035
    @test value(PW) ≈ two_by_two_AuxinOutput["PW","S.FX.2,M.5"]#  1.17670232
    @test value(PL) ≈ two_by_two_AuxinOutput["PL","S.FX.2,M.5"]#  1.136618
    @test value(PK) ≈ two_by_two_AuxinOutput["PK","S.FX.2,M.5"]#  1.28587413
    @test value(SHAREX) ≈ two_by_two_AuxinOutput["SHAREX","S.FX.2,M.5"]#  0.2
    @test value(MARKUP[:a]) ≈ two_by_two_AuxinOutput["MARKUP","S.FX.2,M.5"]#  0.13513514
    @test value(compensated_demand(X, PX, :t)) ≈ -two_by_two_AuxinOutput["SXX","S.FX.2,M.5"]#  80
    @test value(compensated_demand(Y, PY, :t)) ≈ -two_by_two_AuxinOutput["SYY","S.FX.2,M.5"]#  100
    @test value(compensated_demand(W, PW, :t)) ≈ -two_by_two_AuxinOutput["SWW","S.FX.2,M.5"]#  180
    @test value(compensated_demand(X, PL)) ≈ two_by_two_AuxinOutput["DLX","S.FX.2,M.5"]#  15.41666668
    @test value(compensated_demand(X, PK)) ≈ two_by_two_AuxinOutput["DKX","S.FX.2,M.5"]#  48.66856253
    @test value(compensated_demand(Y, PL)) ≈ two_by_two_AuxinOutput["DLY","S.FX.2,M.5"]#  63.03544503
    @test value(compensated_demand(Y, PK)) ≈ two_by_two_AuxinOutput["DKY","S.FX.2,M.5"]#  37.14579281
    @test value(compensated_demand(W, PX)) ≈ two_by_two_AuxinOutput["DXW","S.FX.2,M.5"]#  92.58083471
    @test value(compensated_demand(W, PY)) ≈ two_by_two_AuxinOutput["DYW","S.FX.2,M.5"]#  87.6125997
    @test value(CONS) ≈ two_by_two_AuxinOutput["CONS","S.FX.2,M.5"]#  214.5077935
    @test value(demand(CONS, PW)) ≈ two_by_two_AuxinOutput["CWCONS","S.FX.2,M.5"]#  182.2957177

end
