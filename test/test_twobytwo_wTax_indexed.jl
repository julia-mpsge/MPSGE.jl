@testitem "TWOBYTWOwTax" begin
    using XLSX, MPSGE.JuMP.Containers
    
    # A replication of the Two By Two Scalar, with an output Tax in counterfactual: TwoByTwo_Scalar_wTax_MPSGE.gms
    m = Model()
    
    esub_x = add!(m, Parameter(:esub_x, value=1.0))    
    esub_y = add!(m, Parameter(:esub_y, value=1.0))    
    endow  = add!(m, Parameter(:endow, value=1.0))
    Otax   = add!(m, Parameter(:Otax, value = 0.0))
    
    X = add!(m, Sector(:X))
    Y = add!(m, Sector(:Y))
    U = add!(m, Sector(:U))
    
    PX = add!(m, Commodity(:PX))
    PY = add!(m, Commodity(:PY))
    PU = add!(m, Commodity(:PU))
    PL = add!(m, Commodity(:PL))
    PK = add!(m, Commodity(:PK))
    
    RA = add!(m, Consumer(:RA, benchmark = 150.))
 
    @production(m, X, 0, :($esub_x*1.0), [Output(PX, 100., [MPSGE.Tax(:($Otax*1.0), RA)])], [Input(PL, 50.), Input(PK,50.)])
    @production(m, Y, 0, :($esub_y*1.0), [Output(PY, 50.)], [Input(PL, 20.), Input(PK,30.)])
    # @production(m, Y, 0, :($esub_y*1.0), [Output(PY, 50.,  [MPSGE.Tax(:($Otax*1.0), RA)])], [Input(PL, 20.), Input(PK,30.)])
    @production(m, U, 0, 1.0, [Output(PU, 150.)], [Input(PX, 100.), Input(PY,50.)])
   
    @demand(m, RA, 1., [Demand(PU, 150. )], [Endowment(PL, :(70. * $(endow))), Endowment(PK, 80)])
 
    gams_results = XLSX.readxlsx(joinpath(@__DIR__, "MPSGEresults.xlsx"))
    a_table = gams_results["TwoxTwowOTax"][:]  # Generated from TwoByTwo_Scalar_wTax-MPSGE.gms
    two_by_two_scalar_results = DenseAxisArray(a_table[2:end,2:end],a_table[2:end,1],a_table[1,2:end])
 
    solve!(m, cumulative_iteration_limit=0)

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
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PL†X")]) ≈ two_by_two_scalar_results["DXL.L","benchmark"]#    50.
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PL†Y")]) ≈ two_by_two_scalar_results["DYL.L","benchmark"]#    20.
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PK†X")]) ≈ two_by_two_scalar_results["DXK.L","benchmark"]#    50.
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PK†Y")]) ≈ two_by_two_scalar_results["DYK.L","benchmark"]#    30.
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX†U")]) ≈ two_by_two_scalar_results["DUX.L","benchmark"]#    100.
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PY†U")]) ≈ two_by_two_scalar_results["DUY.L","benchmark"]#    50.
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX‡X")]) ≈ two_by_two_scalar_results["SX.L","benchmark"]#    50.
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PY‡Y")]) ≈ two_by_two_scalar_results["SY.L","benchmark"]#    50.
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PU‡U")]) ≈ two_by_two_scalar_results["SU.L","benchmark"]#    50.
    
    #Counterfactual 1, increase labour endowment by 10%, default normalisation of price: fix RA income at initial prices
    set_value(endow, 1.1)
    set_fixed!(RA, true)
    solve!(m)

    @test value(m, :X) ≈ two_by_two_scalar_results["X.L","RA=157"]#    1.
    @test MPSGE.Complementarity.result_value(m._jump_model[:Y]) ≈ two_by_two_scalar_results["Y.L","RA=157"]#    1.
    @test MPSGE.Complementarity.result_value(m._jump_model[:U]) ≈ two_by_two_scalar_results["U.L","RA=157"]#    1.
    @test MPSGE.Complementarity.result_value(m._jump_model[:RA]) ≈ two_by_two_scalar_results["RA.L","RA=157"]#    150.
    @test MPSGE.Complementarity.result_value(m._jump_model[:PX]) ≈ two_by_two_scalar_results["PX.L","RA=157"]#    1.
    @test MPSGE.Complementarity.result_value(m._jump_model[:PY]) ≈ two_by_two_scalar_results["PY.L","RA=157"]#    1.
    @test MPSGE.Complementarity.result_value(m._jump_model[:PU]) ≈ two_by_two_scalar_results["PU.L","RA=157"]#    1.
    @test MPSGE.Complementarity.result_value(m._jump_model[:PL]) ≈ two_by_two_scalar_results["PL.L","RA=157"]#    1.
    @test MPSGE.Complementarity.result_value(m._jump_model[:PK]) ≈ two_by_two_scalar_results["PK.L","RA=157"]#    1.
# Implicit Variables
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PL†X")]) ≈ two_by_two_scalar_results["DXL.L","RA=157"]#    50.
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PL†Y")]) ≈ two_by_two_scalar_results["DYL.L","RA=157"]#    20.
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PK†X")]) ≈ two_by_two_scalar_results["DXK.L","RA=157"]#    50.
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PK†Y")]) ≈ two_by_two_scalar_results["DYK.L","RA=157"]#    30.
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX†U")]) ≈ two_by_two_scalar_results["DUX.L","RA=157"]#    100.
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PY†U")]) ≈ two_by_two_scalar_results["DUY.L","RA=157"]#    50.
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX‡X")]) ≈ two_by_two_scalar_results["SX.L","RA=157"]#    50.
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PY‡Y")]) ≈ two_by_two_scalar_results["SY.L","RA=157"]#    50.
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PU‡U")]) ≈ two_by_two_scalar_results["SU.L","RA=157"]#    50.
    
    #Counterfactual 2, fix price of x as numeraire, unfix RA
    set_fixed!(PX, true)
    set_fixed!(RA, false)
    solve!(m)
    
    @test value(m, :X) ≈ two_by_two_scalar_results["X.L","PX=1"]#    1.0488088481702906
    @test MPSGE.Complementarity.result_value(m._jump_model[:Y]) ≈ two_by_two_scalar_results["Y.L","PX=1"]#    1.038860118253863
    @test MPSGE.Complementarity.result_value(m._jump_model[:U]) ≈ two_by_two_scalar_results["U.L","PX=1"]#    1.0454820635787618
    @test MPSGE.Complementarity.result_value(m._jump_model[:RA]) ≈ two_by_two_scalar_results["RA.L","PX=1"]#  157.32132722551978
    @test MPSGE.Complementarity.result_value(m._jump_model[:PX]) ≈ two_by_two_scalar_results["PX.L","PX=1"]#    1.
    @test MPSGE.Complementarity.result_value(m._jump_model[:PY]) ≈ two_by_two_scalar_results["PY.L","PX=1"]#    1.0095765827768821
    @test MPSGE.Complementarity.result_value(m._jump_model[:PU]) ≈ two_by_two_scalar_results["PU.L","PX=1"]#   1.0031820580257127
    @test MPSGE.Complementarity.result_value(m._jump_model[:PL]) ≈ two_by_two_scalar_results["PL.L","PX=1"]#   0.953462589245595
    @test MPSGE.Complementarity.result_value(m._jump_model[:PK]) ≈ two_by_two_scalar_results["PK.L","PX=1"]#   1.0488088481701119
# Implicit Variables
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PL†X")]) ≈ two_by_two_scalar_results["DXL.L","PX=1"]#    52.44044240850651
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PL†Y")]) ≈ two_by_two_scalar_results["DYL.L","PX=1"]#    21.177057058435174
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PK†X")]) ≈ two_by_two_scalar_results["DXK.L","PX=1"]#    47.67312946228059
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PK†Y")]) ≈ two_by_two_scalar_results["DYK.L","PX=1"]#    28.8778050796855
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX†U")]) ≈ two_by_two_scalar_results["DUX.L","PX=1"]#    100.31820580257127
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PY†U")]) ≈ two_by_two_scalar_results["DUY.L","PX=1"]#    49.68330660297305
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX‡X")]) ≈ two_by_two_scalar_results["SX.L","PX=1"]#    50.
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PY‡Y")]) ≈ two_by_two_scalar_results["SY.L","PX=1"]#    50.
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PU‡U")]) ≈ two_by_two_scalar_results["SU.L","PX=1"]#    50.
    
    #Counterfactual #3 Use wages/labour price as numeraire
    set_fixed!(PX, false)
    set_fixed!(PL, true)
    solve!(m)
    
    @test value(m, :X) ≈ two_by_two_scalar_results["X.L","PL=1"]#    1.0488088481593985
    @test MPSGE.Complementarity.result_value(m._jump_model[:Y]) ≈ two_by_two_scalar_results["Y.L","PL=1"]#    1.0388601182505193
    @test MPSGE.Complementarity.result_value(m._jump_model[:U]) ≈ two_by_two_scalar_results["U.L","PL=1"]#    1.0454820635708377
    @test MPSGE.Complementarity.result_value(m._jump_model[:RA]) ≈ two_by_two_scalar_results["RA.L","PL=1"]#    164.9999999917842
    @test MPSGE.Complementarity.result_value(m._jump_model[:PX]) ≈ two_by_two_scalar_results["PX.L","PL=1"]#    1.0488088481386348
    @test MPSGE.Complementarity.result_value(m._jump_model[:PY]) ≈ two_by_two_scalar_results["PY.L","PL=1"]#    1.058852852879376
    @test MPSGE.Complementarity.result_value(m._jump_model[:PU]) ≈ two_by_two_scalar_results["PU.L","PL=1"]#    1.0521462187479675
    @test MPSGE.Complementarity.result_value(m._jump_model[:PL]) ≈ two_by_two_scalar_results["PL.L","PL=1"]#    1.
    @test MPSGE.Complementarity.result_value(m._jump_model[:PK]) ≈ two_by_two_scalar_results["PK.L","PL=1"]#    1.0999999998973022
# Implicit Variables
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PL†X")]) ≈ two_by_two_scalar_results["DXL.L","PL=1"]#    52.44044240605962
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PL†Y")]) ≈ two_by_two_scalar_results["DYL.L","PL=1"]#    21.177057057249414
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PK†X")]) ≈ two_by_two_scalar_results["DXK.L","PL=1"]#    47.67312946450504
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PK†Y")]) ≈ two_by_two_scalar_results["DYK.L","PL=1"]#    28.877805080763462
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX†U")]) ≈ two_by_two_scalar_results["DUX.L","PL=1"]#    100.31820580223697
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PY†U")]) ≈ two_by_two_scalar_results["DUY.L","PL=1"]#    49.68330660330415
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX‡X")]) ≈ two_by_two_scalar_results["SX.L","PL=1"]#    50.
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PY‡Y")]) ≈ two_by_two_scalar_results["SY.L","PL=1"]#    50.
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PU‡U")]) ≈ two_by_two_scalar_results["SU.L","PL=1"]#    50.
    
    set_value(Otax, 0.1)
    solve!(m)

    @test value(m, :X) ≈ two_by_two_scalar_results["X.L","Otax=.1"]#    1.0116855688658395
    @test MPSGE.Complementarity.result_value(m._jump_model[:Y]) ≈ two_by_two_scalar_results["Y.L","Otax=.1"]#    1.1123672179049628
    @test MPSGE.Complementarity.result_value(m._jump_model[:U]) ≈ two_by_two_scalar_results["U.L","Otax=.1"]#    1.0441905629409307
    @test MPSGE.Complementarity.result_value(m._jump_model[:RA]) ≈ two_by_two_scalar_results["RA.L","Otax=.1"]#    177.69230689285564
    @test MPSGE.Complementarity.result_value(m._jump_model[:PX]) ≈ two_by_two_scalar_results["PX.L","Otax=.1"]#    1.170932369505204
    @test MPSGE.Complementarity.result_value(m._jump_model[:PY]) ≈ two_by_two_scalar_results["PY.L","Otax=.1"]#    1.064949920418856
    @test MPSGE.Complementarity.result_value(m._jump_model[:PU]) ≈ two_by_two_scalar_results["PU.L","Otax=.1"]#    1.1344819828665367
    @test MPSGE.Complementarity.result_value(m._jump_model[:PL]) ≈ two_by_two_scalar_results["PL.L","Otax=.1"]#    1.
    @test MPSGE.Complementarity.result_value(m._jump_model[:PK]) ≈ two_by_two_scalar_results["PK.L","Otax=.1"]#    1.1105769136174084
# Implicit Variables
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PL†X")]) ≈ two_by_two_scalar_results["DXL.L","Otax=.1"]#    52.69195654028726
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PL†Y")]) ≈ two_by_two_scalar_results["DYL.L","Otax=.1"]#    21.298998374443727
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PK†X")]) ≈ two_by_two_scalar_results["DXK.L","Otax=.1"]#    47.44557166118035
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PK†Y")]) ≈ two_by_two_scalar_results["DYK.L","Otax=.1"]#    28.767478568955543
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX†U")]) ≈ two_by_two_scalar_results["DUX.L","Otax=.1"]#    96.88706302697432
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PY†U")]) ≈ two_by_two_scalar_results["DUY.L","Otax=.1"]#    53.26456958649977
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX‡X")]) ≈ two_by_two_scalar_results["SX.L","Otax=.1"]#    101.16855688658394
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PY‡Y")]) ≈ two_by_two_scalar_results["SY.L","Otax=.1"]#    50.
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PU‡U")]) ≈ two_by_two_scalar_results["SU.L","Otax=.1"]#    50.

    set_value(Otax, 0.2)
    solve!(m)

    @test value(m, :X) ≈ two_by_two_scalar_results["X.L","Otax=.2"]#    0.9688481110216813
    @test MPSGE.Complementarity.result_value(m._jump_model[:Y]) ≈ two_by_two_scalar_results["Y.L","Otax=.2"]#    1.197101452804781
    @test MPSGE.Complementarity.result_value(m._jump_model[:U]) ≈ two_by_two_scalar_results["U.L","Otax=.2"]#    1.039634741431309
    @test MPSGE.Complementarity.result_value(m._jump_model[:RA]) ≈ two_by_two_scalar_results["RA.L","Otax=.2"]#   192.49999801341977
    @test MPSGE.Complementarity.result_value(m._jump_model[:PX]) ≈ two_by_two_scalar_results["PX.L","Otax=.2"]#    1.3245970219534051
    @test MPSGE.Complementarity.result_value(m._jump_model[:PY]) ≈ two_by_two_scalar_results["PY.L","Otax=.2"]#    1.0720338858305598
    @test MPSGE.Complementarity.result_value(m._jump_model[:PU]) ≈ two_by_two_scalar_results["PU.L","Otax=.2"]#    1.2344078852090752
    @test MPSGE.Complementarity.result_value(m._jump_model[:PL]) ≈ two_by_two_scalar_results["PL.L","Otax=.2"]#    1.
    @test MPSGE.Complementarity.result_value(m._jump_model[:PK]) ≈ two_by_two_scalar_results["PK.L","Otax=.2"]#    1.122916644521622
# Implicit Variables
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PL†X")]) ≈ two_by_two_scalar_results["DXL.L","Otax=.2"]#    52.98388067425842
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PL†Y")]) ≈ two_by_two_scalar_results["DYL.L","Otax=.2"]#    21.44067763741017
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PK†X")]) ≈ two_by_two_scalar_results["DXK.L","Otax=.2"]#    47.184161827817846
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PK†Y")]) ≈ two_by_two_scalar_results["DYK.L","Otax=.2"]#    28.640608911640356
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX†U")]) ≈ two_by_two_scalar_results["DUX.L","Otax=.2"]#    93.19120190502586
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PY†U")]) ≈ two_by_two_scalar_results["DUY.L","Otax=.2"]#    57.57317476024549
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX‡X")]) ≈ two_by_two_scalar_results["SX.L","Otax=.2"]#    50.
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PY‡Y")]) ≈ two_by_two_scalar_results["SY.L","Otax=.2"]#    50.
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PU‡U")]) ≈ two_by_two_scalar_results["SU.L","Otax=.2"]#    50.

    set_value(Otax, 0.5)
    solve!(m)

    @test value(m, :X) ≈ two_by_two_scalar_results["X.L","Otax=.5"]#    1.
    @test MPSGE.Complementarity.result_value(m._jump_model[:Y]) ≈ two_by_two_scalar_results["Y.L","Otax=.5"]#    1.5521999426621624
    @test MPSGE.Complementarity.result_value(m._jump_model[:U]) ≈ two_by_two_scalar_results["U.L","Otax=.5"]#    0.9884720495748968
    @test MPSGE.Complementarity.result_value(m._jump_model[:RA]) ≈ two_by_two_scalar_results["RA.L","Otax=.5"]#    256.6666666666296
    @test MPSGE.Complementarity.result_value(m._jump_model[:PX]) ≈ two_by_two_scalar_results["PX.L","Otax=.5"]#    2.1692292538029863
    @test MPSGE.Complementarity.result_value(m._jump_model[:PY]) ≈ two_by_two_scalar_results["PY.L","Otax=.5"]#    1.102378027521483
    @test MPSGE.Complementarity.result_value(m._jump_model[:PU]) ≈ two_by_two_scalar_results["PU.L","Otax=.5"]#    1.731066762936565
    @test MPSGE.Complementarity.result_value(m._jump_model[:PL]) ≈ two_by_two_scalar_results["PL.L","Otax=.5"]#    1.
    @test MPSGE.Complementarity.result_value(m._jump_model[:PK]) ≈ two_by_two_scalar_results["PK.L","Otax=.5"]#    1.1763888888885616
# Implicit Variables
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PL†X")]) ≈ two_by_two_scalar_results["DXL.L","Otax=.5"]#    54.23073134507227
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PL†Y")]) ≈ two_by_two_scalar_results["DYL.L","Otax=.5"]#    22.04756055042873
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PK†X")]) ≈ two_by_two_scalar_results["DXK.L","Otax=.5"]#    46.09932298519823
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PK†Y")]) ≈ two_by_two_scalar_results["DYK.L","Otax=.5"]#    28.112591965135366
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX†U")]) ≈ two_by_two_scalar_results["DUX.L","Otax=.5"]#    79.80100581355073
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PY†U")]) ≈ two_by_two_scalar_results["DUY.L","Otax=.5"]#    78.5151154921232
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX‡X")]) ≈ two_by_two_scalar_results["SX.L","Otax=.5"]#    50.
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PY‡Y")]) ≈ two_by_two_scalar_results["SY.L","Otax=.5"]#    50.
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PU‡U")]) ≈ two_by_two_scalar_results["SU.L","Otax=.5"]#    50.

    set_value(Otax, 0.9)
    solve!(m)

    @test value(m, :X) ≈ two_by_two_scalar_results["X.L","Otax=.9"]#    1.
    @test MPSGE.Complementarity.result_value(m._jump_model[:Y]) ≈ two_by_two_scalar_results["Y.L","Otax=.9"]#    2.575333351676288
    @test MPSGE.Complementarity.result_value(m._jump_model[:U]) ≈ two_by_two_scalar_results["U.L","Otax=.9"]#    0.5659812410319296
    @test MPSGE.Complementarity.result_value(m._jump_model[:RA]) ≈ two_by_two_scalar_results["RA.L","Otax=.9"]#    461.9999999777376
    @test MPSGE.Complementarity.result_value(m._jump_model[:PX]) ≈ two_by_two_scalar_results["PX.L","Otax=.9"]#    11.608186765877146
    @test MPSGE.Complementarity.result_value(m._jump_model[:PY]) ≈ two_by_two_scalar_results["PY.L","Otax=.9"]#    1.195961679231847
    @test MPSGE.Complementarity.result_value(m._jump_model[:PU]) ≈ two_by_two_scalar_results["PU.L","Otax=.9"]#   5.441876473230442
    @test MPSGE.Complementarity.result_value(m._jump_model[:PL]) ≈ two_by_two_scalar_results["PL.L","Otax=.9"]#    1.
    @test MPSGE.Complementarity.result_value(m._jump_model[:PK]) ≈ two_by_two_scalar_results["PK.L","Otax=.9"]#    1.347499999874207
# Implicit Variables
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PL†X")]) ≈ two_by_two_scalar_results["DXL.L","Otax=.9"]#    58.040933828510354
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PL†Y")]) ≈ two_by_two_scalar_results["DYL.L","Otax=.9"]#    23.919233584290627
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PK†X")]) ≈ two_by_two_scalar_results["DXK.L","Otax=.9"]#    43.0730492274053
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PK†Y")]) ≈ two_by_two_scalar_results["DYK.L","Otax=.9"]#    26.62623404807817
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX†U")]) ≈ two_by_two_scalar_results["DUX.L","Otax=.9"]#    46.879642643468536
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PY†U")]) ≈ two_by_two_scalar_results["DUY.L","Otax=.9"]#    227.51048665392318
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX‡X")]) ≈ two_by_two_scalar_results["SX.L","Otax=.9"]#    50.
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PY‡Y")]) ≈ two_by_two_scalar_results["SY.L","Otax=.9"]#    50.
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PU‡U")]) ≈ two_by_two_scalar_results["SU.L","Otax=.9"]#    50.
      
    end