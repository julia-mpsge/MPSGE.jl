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
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PUρRA")]) ≈ two_by_two_scalar_results["CWI.L","benchmark"] # 100.3182058

    
    #Counterfactual 1, increase labour endowment by 10%, default normalisation of price: fix RA income at initial prices
set_value(endow, 1.1)
set_fixed!(RA, true)
solve!(m)

    @test value(m, :X)                                          ≈ two_by_two_scalar_results["X.L","RA=157"]#    1.
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
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PUρRA")]) ≈ two_by_two_scalar_results["CWI.L","RA=157"] # 156.8223095


    #Counterfactual 2, fix price of x as numeraire, unfix RA
set_fixed!(PX, true)
set_fixed!(RA, false)
solve!(m)
    
    @test value(m, :X)                                          ≈ two_by_two_scalar_results["X.L","PX=1"]#    1.0488088481702906
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
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PUρRA")]) ≈ two_by_two_scalar_results["CWI.L","PX=1"] # 156.8223095

#Counterfactual #3 Use wages/labour price as numeraire
set_fixed!(PX, false)
set_fixed!(PL, true)
solve!(m)
    
    @test value(m, :X)                                          ≈ two_by_two_scalar_results["X.L","PL=1"]#    1.0488088481593985
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
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PUρRA")]) ≈ two_by_two_scalar_results["CWI.L","PL=1"] # 156.8223095

set_value(Otax, 0.1)
solve!(m)

    @test value(m, :X)                                          ≈ two_by_two_scalar_results["X.L","Otax=.1"]#    1.0116855688658395
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
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PUρRA")]) ≈ two_by_two_scalar_results["CWI.L","Otax=.1"] # 156.6285843

set_value(Otax, 0.2)
solve!(m)

    @test value(m, :X)                                          ≈ two_by_two_scalar_results["X.L","Otax=.2"]#    0.9688481110216813
    @test MPSGE.Complementarity.result_value(m._jump_model[:Y]) ≈ two_by_two_scalar_results["Y.L","Otax=.2"]#    1.197101452804781
    @test MPSGE.Complementarity.result_value(m._jump_model[:U]) ≈ two_by_two_scalar_results["U.L","Otax=.2"]#    1.039634741431309
    @test MPSGE.Complementarity.result_value(m._jump_model[:RA]) ≈ two_by_two_scalar_results["RA.L","Otax=.2"]#   192.49999801341977
    @test MPSGE.Complementarity.result_value(m._jump_model[:PX]) ≈ two_by_two_scalar_results["PX.L","Otax=.2"]#    1.3245970219534051
    @test MPSGE.Complementarity.result_value(m._jump_model[:PY]) ≈ two_by_two_scalar_results["PY.L","Otax=.2"]#    1.0720338858305598
    @test MPSGE.Complementarity.result_value(m._jump_model[:PU]) ≈ two_by_two_scalar_results["PU.L","Otax=.2"]#    1.2344078852090752
    @test MPSGE.Complementarity.result_value(m._jump_model[:PL]) ≈ two_by_two_scalar_results["PL.L","Otax=.2"]#    1.
    @test MPSGE.Complementarity.result_value(m._jump_model[:PK]) ≈ two_by_two_scalar_results["PK.L","Otax=.2"] atol=1.0e-7#    1.122916644521622
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
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PUρRA")]) ≈ two_by_two_scalar_results["CWI.L","Otax=.2"] # 155.9452109

set_value(Otax, 0.5)
solve!(m)

    @test value(m, :X)                                          ≈ two_by_two_scalar_results["X.L","Otax=.5"]#    0.7888106357533915
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
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PUρRA")]) ≈ two_by_two_scalar_results["CWI.L","Otax=.5"] # 148.2708074

set_value(Otax, 0.9)
solve!(m)

    @test value(m, :X)                                          ≈ two_by_two_scalar_results["X.L","Otax=.9"]#    0.2653299831628428
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
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PUρRA")]) ≈ two_by_two_scalar_results["CWI.L","Otax=.9"] # 84.89718615
  
end

@testitem "TWOBYTWOwOTax_IndCons" begin
    using XLSX, MPSGE.JuMP.Containers
    
    # A replication of the Two By Two, with an output Tax in one consumer counterfactual: TwoByTwo_wTax_IndexRA.gms
    m = Model()
    
    consumers = [:a, :b]
    consumption = DenseAxisArray(Float64[75, 75], consumers)

    esub_x = add!(m, Parameter(:esub_x, value=1.0))    
    esub_y = add!(m, Parameter(:esub_y, value=1.0))    
    endow  = add!(m, Parameter(:endow, value=1.0))
    Otaxa   = add!(m, Parameter(:Otaxa, value = 0.0))
    Otaxb   = add!(m, Parameter(:Otaxb, value = 0.0))
    
    X = add!(m, Sector(:X))
    Y = add!(m, Sector(:Y))
    U = add!(m, Sector(:U))
    
    PX = add!(m, Commodity(:PX))
    PY = add!(m, Commodity(:PY))
    PU = add!(m, Commodity(:PU))
    PL = add!(m, Commodity(:PL))
    PK = add!(m, Commodity(:PK))
    
    RA = add!(m, Consumer(:RA, indices=(consumers,), benchmark=75.))#(consumption)))
 
    @production(m, X, 0, :($esub_x*1.0), [Output(PX, 100., [MPSGE.Tax(:($Otaxa*1.0), RA[:a])])], [Input(PL, 50.), Input(PK,50.)])
    @production(m, Y, 0, :($esub_y*1.0), [Output(PY, 50.,  [MPSGE.Tax(:($Otaxb*1.0), RA[:b])])], [Input(PL, 20.), Input(PK,30.)])
    @production(m, U, 0, 1.0, [Output(PU, 150.)], [Input(PX, 100.), Input(PY,50.)])

    for r in consumers
        @demand(m, RA[r], 1., [Demand(PU, 75. )], [Endowment(PL, :(35. * $(endow))), Endowment(PK, 40)])
    end

 
    gams_results = XLSX.readxlsx(joinpath(@__DIR__, "MPSGEresults.xlsx"))
    a_table = gams_results["TwoxTwowOTax_IndCon"][:]  # Generated from TwoByTwo_wTax_IndexRA.gms
    two_by_two_scalar_results = DenseAxisArray(a_table[2:end,2:end],a_table[2:end,1],a_table[1,2:end])
 
    solve!(m, cumulative_iteration_limit=0)

    @test value(m, :X) ≈ two_by_two_scalar_results["X.L","benchmark"]#    1.
    @test MPSGE.Complementarity.result_value(m._jump_model[:Y]) ≈ two_by_two_scalar_results["Y.L","benchmark"]#    1.
    @test MPSGE.Complementarity.result_value(m._jump_model[:U]) ≈ two_by_two_scalar_results["U.L","benchmark"]#    1.
    @test MPSGE.Complementarity.result_value(m._jump_model[:RA][:a]) ≈ two_by_two_scalar_results["RAA.L","benchmark"]#    75.
    @test MPSGE.Complementarity.result_value(m._jump_model[:RA][:b]) ≈ two_by_two_scalar_results["RAB.L","benchmark"]#    75.
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
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PUρRA[a]")]) ≈ two_by_two_scalar_results["DURAA.L","benchmark"] # 75.
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PUρRA[b]")]) ≈ two_by_two_scalar_results["DURAA.L","benchmark"] # 75.

    #Counterfactual 1, increase labour endowment by 10%, default normalisation of price: fix RA income at initial prices
    set_value(endow, 1.1)
    set_fixed!(RA[:a], true)
    set_fixed!(RA[:b], true)
    solve!(m)

    @test value(m, :X)                                          ≈ two_by_two_scalar_results["X.L","RA=157"]#    1.04880885
    @test MPSGE.Complementarity.result_value(m._jump_model[:Y]) ≈ two_by_two_scalar_results["Y.L","RA=157"]#    1.03886012
    @test MPSGE.Complementarity.result_value(m._jump_model[:U]) ≈ two_by_two_scalar_results["U.L","RA=157"]#  1.04548206
    @test MPSGE.Complementarity.result_value(m._jump_model[:RA][:a]) ≈ two_by_two_scalar_results["RAA.L","RA=157"]#   78.50000000
    @test MPSGE.Complementarity.result_value(m._jump_model[:RA][:b]) ≈ two_by_two_scalar_results["RAB.L","RA=157"]#    78.49999994
    @test MPSGE.Complementarity.result_value(m._jump_model[:PX]) ≈ two_by_two_scalar_results["PX.L","RA=157"]#   0.99795751
    @test MPSGE.Complementarity.result_value(m._jump_model[:PY]) ≈ two_by_two_scalar_results["PY.L","RA=157"]#    1.00751453
    @test MPSGE.Complementarity.result_value(m._jump_model[:PU]) ≈ two_by_two_scalar_results["PU.L","RA=157"]#    1.00113307
    @test MPSGE.Complementarity.result_value(m._jump_model[:PL]) ≈ two_by_two_scalar_results["PL.L","RA=157"]#    0.95151515
    @test MPSGE.Complementarity.result_value(m._jump_model[:PK]) ≈ two_by_two_scalar_results["PK.L","RA=157"]#  1.04666667
# Implicit Variables
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PL†X")]) ≈ two_by_two_scalar_results["DXL.L","RA=157"]#    52.44044243
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PL†Y")]) ≈ two_by_two_scalar_results["DYL.L","RA=157"]#    21.1770570
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PK†X")]) ≈ two_by_two_scalar_results["DXK.L","RA=157"]#    47.67312946200557
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PK†Y")]) ≈ two_by_two_scalar_results["DYK.L","RA=157"]#    28.877805080093896
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX†U")]) ≈ two_by_two_scalar_results["DUX.L","RA=157"]#    100.31820580267068
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PY†U")]) ≈ two_by_two_scalar_results["DUY.L","RA=157"]#    49.683306602880336
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX‡X")]) ≈ two_by_two_scalar_results["SX.L","RA=157"]#    100.
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PY‡Y")]) ≈ two_by_two_scalar_results["SY.L","RA=157"]#    50.
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PU‡U")]) ≈ two_by_two_scalar_results["SU.L","RA=157"]#    150.
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PUρRA[a]")]) ≈ two_by_two_scalar_results["DURAA.L","RA=157"] # 78.41115476890819
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PUρRA[b]")]) ≈ two_by_two_scalar_results["DURAB.L","RA=157"] # 78.41115476890819

    #Counterfactual 2, fix price of x as numeraire, unfix RA
    set_fixed!(PX, true)
    set_fixed!(RA[:a], false)
    set_fixed!(RA[:b], false)
    solve!(m)
    
    @test value(m, :X)                                          ≈ two_by_two_scalar_results["X.L","PX=1"]#    1.0488088485
    @test MPSGE.Complementarity.result_value(m._jump_model[:Y]) ≈ two_by_two_scalar_results["Y.L","PX=1"]#    1.03886012
    @test MPSGE.Complementarity.result_value(m._jump_model[:U]) ≈ two_by_two_scalar_results["U.L","PX=1"]#    1.04548206
    @test MPSGE.Complementarity.result_value(m._jump_model[:RA][:a]) ≈ two_by_two_scalar_results["RAA.L","PX=1"]#  78.66066361
    @test MPSGE.Complementarity.result_value(m._jump_model[:RA][:b]) ≈ two_by_two_scalar_results["RAB.L","PX=1"]#  78.66066361
    @test MPSGE.Complementarity.result_value(m._jump_model[:PX]) ≈ two_by_two_scalar_results["PX.L","PX=1"]#    1.
    @test MPSGE.Complementarity.result_value(m._jump_model[:PY]) ≈ two_by_two_scalar_results["PY.L","PX=1"]#    1.00957658
    @test MPSGE.Complementarity.result_value(m._jump_model[:PU]) ≈ two_by_two_scalar_results["PU.L","PX=1"]#   1.00318206
    @test MPSGE.Complementarity.result_value(m._jump_model[:PL]) ≈ two_by_two_scalar_results["PL.L","PX=1"]#   0.95346259
    @test MPSGE.Complementarity.result_value(m._jump_model[:PK]) ≈ two_by_two_scalar_results["PK.L","PX=1"]#   1.04880885
# Implicit Variables
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PL†X")]) ≈ two_by_two_scalar_results["DXL.L","PX=1"]#    52.44044241
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PL†Y")]) ≈ two_by_two_scalar_results["DYL.L","PX=1"]#    21.17705706
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PK†X")]) ≈ two_by_two_scalar_results["DXK.L","PX=1"]#    47.67312946
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PK†Y")]) ≈ two_by_two_scalar_results["DYK.L","PX=1"]#    28.87780508
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX†U")]) ≈ two_by_two_scalar_results["DUX.L","PX=1"]#    100.3182
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PY†U")]) ≈ two_by_two_scalar_results["DUY.L","PX=1"]#    49.68330660
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX‡X")]) ≈ two_by_two_scalar_results["SX.L","PX=1"]#    100.
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PY‡Y")]) ≈ two_by_two_scalar_results["SY.L","PX=1"]#    50.
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PU‡U")]) ≈ two_by_two_scalar_results["SU.L","PX=1"]#    150.
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PUρRA[a]")]) ≈ two_by_two_scalar_results["DURAA.L","PX=1"] # 78.41115477
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PUρRA[b]")]) ≈ two_by_two_scalar_results["DURAB.L","PX=1"] # 78.41115477

#Counterfactual #3 Use wages/labour price as numeraire
set_fixed!(PX, false)
set_fixed!(PL, true)
solve!(m)

    @test value(m, :X)                                          ≈ two_by_two_scalar_results["X.L","PL=1"]	#	1.04880885
    @test MPSGE.Complementarity.result_value(m._jump_model[:Y]) ≈ two_by_two_scalar_results["Y.L","PL=1"]	#	1.03886012
    @test MPSGE.Complementarity.result_value(m._jump_model[:U]) ≈ two_by_two_scalar_results["U.L","PL=1"]	#	1.04548206
    @test MPSGE.Complementarity.result_value(m._jump_model[:RA][:a]) ≈ two_by_two_scalar_results["RAA.L","PL=1"]	#	82.5
    @test MPSGE.Complementarity.result_value(m._jump_model[:RA][:b]) ≈ two_by_two_scalar_results["RAB.L","PL=1"]	#	82.5
    @test MPSGE.Complementarity.result_value(m._jump_model[:PX]) ≈ two_by_two_scalar_results["PX.L","PL=1"]	#	1.04880885
    @test MPSGE.Complementarity.result_value(m._jump_model[:PY]) ≈ two_by_two_scalar_results["PY.L","PL=1"]	#	1.05885285
    @test MPSGE.Complementarity.result_value(m._jump_model[:PU]) ≈ two_by_two_scalar_results["PU.L","PL=1"]	#	1.05214622
    @test MPSGE.Complementarity.result_value(m._jump_model[:PL]) ≈ two_by_two_scalar_results["PL.L","PL=1"]	#	1
    @test MPSGE.Complementarity.result_value(m._jump_model[:PK]) ≈ two_by_two_scalar_results["PK.L","PL=1"]	#	1.1
	#	 Implicit Variables
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PL†X")]) ≈ two_by_two_scalar_results["DXL.L","PL=1"]	#	52.44044241
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PL†Y")]) ≈ two_by_two_scalar_results["DYL.L","PL=1"]	#	47.67312946
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PK†X")]) ≈ two_by_two_scalar_results["DXK.L","PL=1"]	#	21.17705706
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PK†Y")]) ≈ two_by_two_scalar_results["DYK.L","PL=1"]	#	28.87780508
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX†U")]) ≈ two_by_two_scalar_results["DUX.L","PL=1"]	#	100.3182
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PY†U")]) ≈ two_by_two_scalar_results["DUY.L","PL=1"]	#	49.6833066
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX‡X")]) ≈ two_by_two_scalar_results["SX.L","PL=1"]	#	100
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PY‡Y")]) ≈ two_by_two_scalar_results["SY.L","PL=1"]	#	50
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PU‡U")]) ≈ two_by_two_scalar_results["SU.L","PL=1"]	#	150
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PUρRA[a]")]) ≈ two_by_two_scalar_results["DURAA.L","PL=1"] 	#	78.41115477
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PUρRA[b]")]) ≈ two_by_two_scalar_results["DURAB.L","PL=1"] 	#	78.41115477

set_value(Otaxa, 0.1)		
solve!(m)		

    @test value(m, :X)                                          ≈ two_by_two_scalar_results["X.L","Otaxa=.1"]	#	1.01168557
    @test MPSGE.Complementarity.result_value(m._jump_model[:Y]) ≈ two_by_two_scalar_results["Y.L","Otaxa=.1"]	#	1.11236722
    @test MPSGE.Complementarity.result_value(m._jump_model[:U]) ≈ two_by_two_scalar_results["U.L","Otaxa=.1"]	#	1.04419056
    @test MPSGE.Complementarity.result_value(m._jump_model[:RA][:a]) ≈ two_by_two_scalar_results["RAA.L","Otaxa=.1"]	#	94.76923035
    @test MPSGE.Complementarity.result_value(m._jump_model[:RA][:b]) ≈ two_by_two_scalar_results["RAB.L","Otaxa=.1"]	#	82.92307654
    @test MPSGE.Complementarity.result_value(m._jump_model[:PX]) ≈ two_by_two_scalar_results["PX.L","Otaxa=.1"]	#	1.17093237
    @test MPSGE.Complementarity.result_value(m._jump_model[:PY]) ≈ two_by_two_scalar_results["PY.L","Otaxa=.1"]	#	1.06494992
    @test MPSGE.Complementarity.result_value(m._jump_model[:PU]) ≈ two_by_two_scalar_results["PU.L","Otaxa=.1"]	#	1.13448198
    @test MPSGE.Complementarity.result_value(m._jump_model[:PL]) ≈ two_by_two_scalar_results["PL.L","Otaxa=.1"]	#	1
    @test MPSGE.Complementarity.result_value(m._jump_model[:PK]) ≈ two_by_two_scalar_results["PK.L","Otaxa=.1"]	#	1.11057691
	#	 Implicit Variables
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PL†X")]) ≈ two_by_two_scalar_results["DXL.L","Otaxa=.1"]	#	52.69195654
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PL†Y")]) ≈ two_by_two_scalar_results["DYL.L","Otaxa=.1"]	#	47.44557166
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PK†X")]) ≈ two_by_two_scalar_results["DXK.L","Otaxa=.1"]	#	21.29899837
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PK†Y")]) ≈ two_by_two_scalar_results["DYK.L","Otaxa=.1"]	#	28.76747857
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX†U")]) ≈ two_by_two_scalar_results["DUX.L","Otaxa=.1"]	#	96.88706303
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PY†U")]) ≈ two_by_two_scalar_results["DUY.L","Otaxa=.1"]	#	53.26456959
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX‡X")]) ≈ two_by_two_scalar_results["SX.L","Otaxa=.1"]	#	100
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PY‡Y")]) ≈ two_by_two_scalar_results["SY.L","Otaxa=.1"]	#	50
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PU‡U")]) ≈ two_by_two_scalar_results["SU.L","Otaxa=.1"]	#	150
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PUρRA[a]")]) ≈ two_by_two_scalar_results["DURAA.L","Otaxa=.1"] 	#	83.53524497
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PUρRA[b]")]) ≈ two_by_two_scalar_results["DURAB.L","Otaxa=.1"] 	#	73.09333934
		
set_value(Otaxa, 0.2)		
solve!(m)		
		
    @test value(m, :X)                                          ≈ two_by_two_scalar_results["X.L","Otaxa=.2"]	#	0.96884811
    @test MPSGE.Complementarity.result_value(m._jump_model[:Y]) ≈ two_by_two_scalar_results["Y.L","Otaxa=.2"]	#	1.19710145
    @test MPSGE.Complementarity.result_value(m._jump_model[:U]) ≈ two_by_two_scalar_results["U.L","Otaxa=.2"]	#	1.03963474
    @test MPSGE.Complementarity.result_value(m._jump_model[:RA][:a]) ≈ two_by_two_scalar_results["RAA.L","Otaxa=.2"]	#	109.0833
    @test MPSGE.Complementarity.result_value(m._jump_model[:RA][:b]) ≈ two_by_two_scalar_results["RAB.L","Otaxa=.2"]	#	83.41666578
    @test MPSGE.Complementarity.result_value(m._jump_model[:PX]) ≈ two_by_two_scalar_results["PX.L","Otaxa=.2"]	#	1.32459702
    @test MPSGE.Complementarity.result_value(m._jump_model[:PY]) ≈ two_by_two_scalar_results["PY.L","Otaxa=.2"]	#	1.07203389
    @test MPSGE.Complementarity.result_value(m._jump_model[:PU]) ≈ two_by_two_scalar_results["PU.L","Otaxa=.2"]	#	1.23440789
    @test MPSGE.Complementarity.result_value(m._jump_model[:PL]) ≈ two_by_two_scalar_results["PL.L","Otaxa=.2"]	#	1
    @test MPSGE.Complementarity.result_value(m._jump_model[:PK]) ≈ two_by_two_scalar_results["PK.L","Otaxa=.2"] atol=1.0e-7	#	1.12291664
	#	 Implicit Variables
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PL†X")]) ≈ two_by_two_scalar_results["DXL.L","Otaxa=.2"]	#	52.98388067
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PL†Y")]) ≈ two_by_two_scalar_results["DYL.L","Otaxa=.2"]	#	47.18416183
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PK†X")]) ≈ two_by_two_scalar_results["DXK.L","Otaxa=.2"]	#	21.44067764
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PK†Y")]) ≈ two_by_two_scalar_results["DYK.L","Otaxa=.2"]	#	28.64060891
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX†U")]) ≈ two_by_two_scalar_results["DUX.L","Otaxa=.2"]	#	93.19120191
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PY†U")]) ≈ two_by_two_scalar_results["DUY.L","Otaxa=.2"]	#	57.57317476
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX‡X")]) ≈ two_by_two_scalar_results["SX.L","Otaxa=.2"]	#	100
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PY‡Y")]) ≈ two_by_two_scalar_results["SY.L","Otaxa=.2"]	#	50
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PU‡U")]) ≈ two_by_two_scalar_results["SU.L","Otaxa=.2"]	#	150
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PUρRA[a]")]) ≈ two_by_two_scalar_results["DURAA.L","Otaxa=.2"] 	#	88.36895287
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PUρRA[b]")]) ≈ two_by_two_scalar_results["DURAB.L","Otaxa=.2"] 	#	67.57625804
		
set_value(Otaxa, 0.5)		
solve!(m)		
		
    @test value(m, :X)                                          ≈ two_by_two_scalar_results["X.L","Otaxa=.5"]	#	0.78881064
    @test MPSGE.Complementarity.result_value(m._jump_model[:Y]) ≈ two_by_two_scalar_results["Y.L","Otaxa=.5"]	#	1.55219994
    @test MPSGE.Complementarity.result_value(m._jump_model[:U]) ≈ two_by_two_scalar_results["U.L","Otaxa=.5"]	#	0.98847205
    @test MPSGE.Complementarity.result_value(m._jump_model[:RA][:a]) ≈ two_by_two_scalar_results["RAA.L","Otaxa=.5"]	#	171.1111
    @test MPSGE.Complementarity.result_value(m._jump_model[:RA][:b]) ≈ two_by_two_scalar_results["RAB.L","Otaxa=.5"]	#	85.55555556
    @test MPSGE.Complementarity.result_value(m._jump_model[:PX]) ≈ two_by_two_scalar_results["PX.L","Otaxa=.5"]	#	2.16922925
    @test MPSGE.Complementarity.result_value(m._jump_model[:PY]) ≈ two_by_two_scalar_results["PY.L","Otaxa=.5"]	#	1.10237803
    @test MPSGE.Complementarity.result_value(m._jump_model[:PU]) ≈ two_by_two_scalar_results["PU.L","Otaxa=.5"]	#	1.73106676
    @test MPSGE.Complementarity.result_value(m._jump_model[:PL]) ≈ two_by_two_scalar_results["PL.L","Otaxa=.5"]	#	1
    @test MPSGE.Complementarity.result_value(m._jump_model[:PK]) ≈ two_by_two_scalar_results["PK.L","Otaxa=.5"]	#	1.17638889
	#	 Implicit Variables
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PL†X")]) ≈ two_by_two_scalar_results["DXL.L","Otaxa=.5"]	#	54.23073135
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PL†Y")]) ≈ two_by_two_scalar_results["DYL.L","Otaxa=.5"]	#	46.09932299
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PK†X")]) ≈ two_by_two_scalar_results["DXK.L","Otaxa=.5"]	#	22.04756055
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PK†Y")]) ≈ two_by_two_scalar_results["DYK.L","Otaxa=.5"]	#	28.11259197
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX†U")]) ≈ two_by_two_scalar_results["DUX.L","Otaxa=.5"]	#	79.80100581
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PY†U")]) ≈ two_by_two_scalar_results["DUY.L","Otaxa=.5"]	#	78.51511549
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX‡X")]) ≈ two_by_two_scalar_results["SX.L","Otaxa=.5"]	#	100
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PY‡Y")]) ≈ two_by_two_scalar_results["SY.L","Otaxa=.5"]	#	50
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PU‡U")]) ≈ two_by_two_scalar_results["SU.L","Otaxa=.5"]	#	150
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PUρRA[a]")]) ≈ two_by_two_scalar_results["DURAA.L","Otaxa=.5"] 	#	98.84720496
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PUρRA[b]")]) ≈ two_by_two_scalar_results["DURAB.L","Otaxa=.5"] 	#	49.42360248
		
set_value(Otaxa, 0.9)		
solve!(m)		
		
    @test value(m, :X)                                          ≈ two_by_two_scalar_results["X.L","Otaxa=.9"]	#	0.26532998
    @test MPSGE.Complementarity.result_value(m._jump_model[:Y]) ≈ two_by_two_scalar_results["Y.L","Otaxa=.9"]	#	2.57533335
    @test MPSGE.Complementarity.result_value(m._jump_model[:U]) ≈ two_by_two_scalar_results["U.L","Otaxa=.9"]	#	0.56598124
    @test MPSGE.Complementarity.result_value(m._jump_model[:RA][:a]) ≈ two_by_two_scalar_results["RAA.L","Otaxa=.9"]	#	369.6
    @test MPSGE.Complementarity.result_value(m._jump_model[:RA][:b]) ≈ two_by_two_scalar_results["RAB.L","Otaxa=.9"]	#	92.39999999
    @test MPSGE.Complementarity.result_value(m._jump_model[:PX]) ≈ two_by_two_scalar_results["PX.L","Otaxa=.9"]	#	11.60818677
    @test MPSGE.Complementarity.result_value(m._jump_model[:PY]) ≈ two_by_two_scalar_results["PY.L","Otaxa=.9"]	#	1.19596168
    @test MPSGE.Complementarity.result_value(m._jump_model[:PU]) ≈ two_by_two_scalar_results["PU.L","Otaxa=.9"]	#	5.44187647
    @test MPSGE.Complementarity.result_value(m._jump_model[:PL]) ≈ two_by_two_scalar_results["PL.L","Otaxa=.9"]	#	1
    @test MPSGE.Complementarity.result_value(m._jump_model[:PK]) ≈ two_by_two_scalar_results["PK.L","Otaxa=.9"]	#	1.3475
	#	 Implicit Variables
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PL†X")]) ≈ two_by_two_scalar_results["DXL.L","Otaxa=.9"]	#	58.04093383
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PL†Y")]) ≈ two_by_two_scalar_results["DYL.L","Otaxa=.9"]	#	43.07304923
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PK†X")]) ≈ two_by_two_scalar_results["DXK.L","Otaxa=.9"]	#	23.91923358
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PK†Y")]) ≈ two_by_two_scalar_results["DYK.L","Otaxa=.9"]	#	26.62623405
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX†U")]) ≈ two_by_two_scalar_results["DUX.L","Otaxa=.9"]	#	46.87964264
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PY†U")]) ≈ two_by_two_scalar_results["DUY.L","Otaxa=.9"]	#	227.5105
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX‡X")]) ≈ two_by_two_scalar_results["SX.L","Otaxa=.9"]	#	100
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PY‡Y")]) ≈ two_by_two_scalar_results["SY.L","Otaxa=.9"]	#	50
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PU‡U")]) ≈ two_by_two_scalar_results["SU.L","Otaxa=.9"]	#	150
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PUρRA[a]")]) ≈ two_by_two_scalar_results["DURAA.L","Otaxa=.9"] 	#	67.91774892
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PUρRA[b]")]) ≈ two_by_two_scalar_results["DURAB.L","Otaxa=.9"] 	#	16.97943723
   		
set_value(Otaxa, 0.1)		
set_value(Otaxb, 0.1)		
solve!(m)		
		
    @test value(m, :X)                                          ≈ two_by_two_scalar_results["X.L","Otax=.1"]	#	1.04880885
    @test MPSGE.Complementarity.result_value(m._jump_model[:Y]) ≈ two_by_two_scalar_results["Y.L","Otax=.1"]	#	1.03886012
    @test MPSGE.Complementarity.result_value(m._jump_model[:U]) ≈ two_by_two_scalar_results["U.L","Otax=.1"]	#	1.04548206
    @test MPSGE.Complementarity.result_value(m._jump_model[:RA][:a]) ≈ two_by_two_scalar_results["RAA.L","Otax=.1"]	#	94.72222205
    @test MPSGE.Complementarity.result_value(m._jump_model[:RA][:b]) ≈ two_by_two_scalar_results["RAB.L","Otax=.1"]	#	88.61111095
    @test MPSGE.Complementarity.result_value(m._jump_model[:PX]) ≈ two_by_two_scalar_results["PX.L","Otax=.1"]	#	1.16534316
    @test MPSGE.Complementarity.result_value(m._jump_model[:PY]) ≈ two_by_two_scalar_results["PY.L","Otax=.1"]	#	1.17650317
    @test MPSGE.Complementarity.result_value(m._jump_model[:PU]) ≈ two_by_two_scalar_results["PU.L","Otax=.1"]	#	1.16905135
    @test MPSGE.Complementarity.result_value(m._jump_model[:PL]) ≈ two_by_two_scalar_results["PL.L","Otax=.1"]	#	1
    @test MPSGE.Complementarity.result_value(m._jump_model[:PK]) ≈ two_by_two_scalar_results["PK.L","Otax=.1"]	#	1.1
	#	 Implicit Variables
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PL†X")]) ≈ two_by_two_scalar_results["DXL.L","Otax=.1"]	#	52.44044232
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PL†Y")]) ≈ two_by_two_scalar_results["DYL.L","Otax=.1"]	#	47.67312955
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PK†X")]) ≈ two_by_two_scalar_results["DXK.L","Otax=.1"]	#	21.17705701
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PK†Y")]) ≈ two_by_two_scalar_results["DYK.L","Otax=.1"]	#	28.87780512
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX†U")]) ≈ two_by_two_scalar_results["DUX.L","Otax=.1"]	#	100.3182
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PY†U")]) ≈ two_by_two_scalar_results["DUY.L","Otax=.1"]	#	49.68330662
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX‡X")]) ≈ two_by_two_scalar_results["SX.L","Otax=.1"]	#	100
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PY‡Y")]) ≈ two_by_two_scalar_results["SY.L","Otax=.1"]	#	50
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PU‡U")]) ≈ two_by_two_scalar_results["SU.L","Otax=.1"]	#	150
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PUρRA[a]")]) ≈ two_by_two_scalar_results["DURAA.L","Otax=.1"] 	#	81.02485989
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PUρRA[b]")]) ≈ two_by_two_scalar_results["DURAB.L","Otax=.1"] 	#	75.79744957
		
set_value(Otaxa, 0.2)		
set_value(Otaxb, 0.2)		
solve!(m)		
		
    @test value(m, :X)                                          ≈ two_by_two_scalar_results["X.L","Otax=.2"]	#	1.04880885
    @test MPSGE.Complementarity.result_value(m._jump_model[:Y]) ≈ two_by_two_scalar_results["Y.L","Otax=.2"]	#	1.03886012
    @test MPSGE.Complementarity.result_value(m._jump_model[:U]) ≈ two_by_two_scalar_results["U.L","Otax=.2"]	#	1.04548206
    @test MPSGE.Complementarity.result_value(m._jump_model[:RA][:a]) ≈ two_by_two_scalar_results["RAA.L","Otax=.2"]	#	110
    @test MPSGE.Complementarity.result_value(m._jump_model[:RA][:b]) ≈ two_by_two_scalar_results["RAB.L","Otax=.2"]	#	96.25
    @test MPSGE.Complementarity.result_value(m._jump_model[:PX]) ≈ two_by_two_scalar_results["PX.L","Otax=.2"]	#	1.31101106
    @test MPSGE.Complementarity.result_value(m._jump_model[:PY]) ≈ two_by_two_scalar_results["PY.L","Otax=.2"]	#	1.32356607
    @test MPSGE.Complementarity.result_value(m._jump_model[:PU]) ≈ two_by_two_scalar_results["PU.L","Otax=.2"]	#	1.31518277
    @test MPSGE.Complementarity.result_value(m._jump_model[:PL]) ≈ two_by_two_scalar_results["PL.L","Otax=.2"]	#	1
    @test MPSGE.Complementarity.result_value(m._jump_model[:PK]) ≈ two_by_two_scalar_results["PK.L","Otax=.2"] atol=1.0e-7	#	1.1
	#	 Implicit Variables
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PL†X")]) ≈ two_by_two_scalar_results["DXL.L","Otax=.2"]	#	52.44044241
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PL†Y")]) ≈ two_by_two_scalar_results["DYL.L","Otax=.2"]	#	47.67312946
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PK†X")]) ≈ two_by_two_scalar_results["DXK.L","Otax=.2"]	#	21.17705706
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PK†Y")]) ≈ two_by_two_scalar_results["DYK.L","Otax=.2"]	#	28.87780508
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX†U")]) ≈ two_by_two_scalar_results["DUX.L","Otax=.2"]	#	100.3182
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PY†U")]) ≈ two_by_two_scalar_results["DUY.L","Otax=.2"]	#	49.6833066
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX‡X")]) ≈ two_by_two_scalar_results["SX.L","Otax=.2"]	#	100
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PY‡Y")]) ≈ two_by_two_scalar_results["SY.L","Otax=.2"]	#	50
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PU‡U")]) ≈ two_by_two_scalar_results["SU.L","Otax=.2"]	#	150
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PUρRA[a]")]) ≈ two_by_two_scalar_results["DURAA.L","Otax=.2"] 	#	83.63856509
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PUρRA[b]")]) ≈ two_by_two_scalar_results["DURAB.L","Otax=.2"] 	#	73.18374445
		
set_value(Otaxa, 0.5)		
set_value(Otaxb, 0.5)		
solve!(m)		
		
    @test value(m, :X)                                          ≈ two_by_two_scalar_results["X.L","Otax=.5"]	#	1.04880885
    @test MPSGE.Complementarity.result_value(m._jump_model[:Y]) ≈ two_by_two_scalar_results["Y.L","Otax=.5"]	#	1.03886012
    @test MPSGE.Complementarity.result_value(m._jump_model[:U]) ≈ two_by_two_scalar_results["U.L","Otax=.5"]	#	1.04548206
    @test MPSGE.Complementarity.result_value(m._jump_model[:RA][:a]) ≈ two_by_two_scalar_results["RAA.L","Otax=.5"]	#	192.5
    @test MPSGE.Complementarity.result_value(m._jump_model[:RA][:b]) ≈ two_by_two_scalar_results["RAB.L","Otax=.5"]	#	137.5
    @test MPSGE.Complementarity.result_value(m._jump_model[:PX]) ≈ two_by_two_scalar_results["PX.L","Otax=.5"]	#	2.0976177
    @test MPSGE.Complementarity.result_value(m._jump_model[:PY]) ≈ two_by_two_scalar_results["PY.L","Otax=.5"]	#	2.11770571
    @test MPSGE.Complementarity.result_value(m._jump_model[:PU]) ≈ two_by_two_scalar_results["PU.L","Otax=.5"]	#	2.10429244
    @test MPSGE.Complementarity.result_value(m._jump_model[:PL]) ≈ two_by_two_scalar_results["PL.L","Otax=.5"]	#	1
    @test MPSGE.Complementarity.result_value(m._jump_model[:PK]) ≈ two_by_two_scalar_results["PK.L","Otax=.5"]	#	1.1
	#	 Implicit Variables
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PL†X")]) ≈ two_by_two_scalar_results["DXL.L","Otax=.5"]	#	52.4404424
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PL†Y")]) ≈ two_by_two_scalar_results["DYL.L","Otax=.5"]	#	47.67312947
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PK†X")]) ≈ two_by_two_scalar_results["DXK.L","Otax=.5"]	#	21.17705706
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PK†Y")]) ≈ two_by_two_scalar_results["DYK.L","Otax=.5"]	#	28.87780508
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX†U")]) ≈ two_by_two_scalar_results["DUX.L","Otax=.5"]	#	100.3182
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PY†U")]) ≈ two_by_two_scalar_results["DUY.L","Otax=.5"]	#	49.6833066
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX‡X")]) ≈ two_by_two_scalar_results["SX.L","Otax=.5"]	#	100
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PY‡Y")]) ≈ two_by_two_scalar_results["SY.L","Otax=.5"]	#	50
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PU‡U")]) ≈ two_by_two_scalar_results["SU.L","Otax=.5"]	#	150
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PUρRA[a]")]) ≈ two_by_two_scalar_results["DURAA.L","Otax=.5"] 	#	91.47968056
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PUρRA[b]")]) ≈ two_by_two_scalar_results["DURAB.L","Otax=.5"] 	#	65.34262897
		
set_value(Otaxa, 0.9)		
set_value(Otaxb, 0.9)		
solve!(m)		
		
    @test value(m, :X)                                          ≈ two_by_two_scalar_results["X.L","Otax=.9"]	#	1.04880885
    @test MPSGE.Complementarity.result_value(m._jump_model[:Y]) ≈ two_by_two_scalar_results["Y.L","Otax=.9"]	#	1.03886012
    @test MPSGE.Complementarity.result_value(m._jump_model[:U]) ≈ two_by_two_scalar_results["U.L","Otax=.9"]	#	1.04548206
    @test MPSGE.Complementarity.result_value(m._jump_model[:RA][:a]) ≈ two_by_two_scalar_results["RAA.L","Otax=.9"]	#	1072.5
    @test MPSGE.Complementarity.result_value(m._jump_model[:RA][:b]) ≈ two_by_two_scalar_results["RAB.L","Otax=.9"]	#	577.5
    @test MPSGE.Complementarity.result_value(m._jump_model[:PX]) ≈ two_by_two_scalar_results["PX.L","Otax=.9"]	#	10.48808848
    @test MPSGE.Complementarity.result_value(m._jump_model[:PY]) ≈ two_by_two_scalar_results["PY.L","Otax=.9"]	#	10.58852853
    @test MPSGE.Complementarity.result_value(m._jump_model[:PU]) ≈ two_by_two_scalar_results["PU.L","Otax=.9"]	#	10.52146219
    @test MPSGE.Complementarity.result_value(m._jump_model[:PL]) ≈ two_by_two_scalar_results["PL.L","Otax=.9"]	#	1
    @test MPSGE.Complementarity.result_value(m._jump_model[:PK]) ≈ two_by_two_scalar_results["PK.L","Otax=.9"]	#	1.1
	#	 Implicit Variables
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PL†X")]) ≈ two_by_two_scalar_results["DXL.L","Otax=.9"]	#	52.44044241
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PL†Y")]) ≈ two_by_two_scalar_results["DYL.L","Otax=.9"]	#	47.67312946
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PK†X")]) ≈ two_by_two_scalar_results["DXK.L","Otax=.9"]	#	21.17705706
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PK†Y")]) ≈ two_by_two_scalar_results["DYK.L","Otax=.9"]	#	28.87780508
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX†U")]) ≈ two_by_two_scalar_results["DUX.L","Otax=.9"]	#	100.3182
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PY†U")]) ≈ two_by_two_scalar_results["DUY.L","Otax=.9"]	#	49.6833066
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX‡X")]) ≈ two_by_two_scalar_results["SX.L","Otax=.9"]	#	100
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PY‡Y")]) ≈ two_by_two_scalar_results["SY.L","Otax=.9"]	#	50
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PU‡U")]) ≈ two_by_two_scalar_results["SU.L","Otax=.9"]	#	150
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PUρRA[a]")]) ≈ two_by_two_scalar_results["DURAA.L","Otax=.9"] 	#	101.9345
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PUρRA[b]")]) ≈ two_by_two_scalar_results["DURAB.L","Otax=.9"] 	#	54.88780834
  		
end		

@TestItem "TwobyTwo_Scalar_wIntax" begin
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

# gams_results = XLSX.readxlsx(joinpath(@__DIR__, "MPSGEresults.xlsx"))
# a_table = gams_results["TwoxTwowITax"][:]  # Generated from TwoByTwo_Scalar_wTax-MPSGE.gms
# two_by_two_scalar_results = DenseAxisArray(a_table[2:end,2:end],a_table[2:end,1],a_table[1,2:end])

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
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PUρRA")]) ≈ two_by_two_scalar_results["CWI.L","benchmark"] # 100.3182058

    
    #Counterfactual 1, increase labour endowment by 10%, default normalisation of price: fix RA income at initial prices
set_value(endow, 1.1)
set_fixed!(RA, true)
solve!(m)

    @test value(m, :X)                                          ≈ two_by_two_scalar_results["X.L","RA=157"]#    1.
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
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PUρRA")]) ≈ two_by_two_scalar_results["CWI.L","RA=157"] # 156.8223095


    #Counterfactual 2, fix price of x as numeraire, unfix RA
set_fixed!(PX, true)
set_fixed!(RA, false)
solve!(m)
    
    @test value(m, :X)                                          ≈ two_by_two_scalar_results["X.L","PX=1"]#    1.0488088481702906
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
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PUρRA")]) ≈ two_by_two_scalar_results["CWI.L","PX=1"] # 156.8223095

#Counterfactual #3 Use wages/labour price as numeraire
set_fixed!(PX, false)
set_fixed!(PL, true)
solve!(m)
    
    @test value(m, :X)                                          ≈ two_by_two_scalar_results["X.L","PL=1"]#    1.0488088481593985
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
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PUρRA")]) ≈ two_by_two_scalar_results["CWI.L","PL=1"] # 156.8223095

set_value(Otax, 0.1)
solve!(m)

    @test value(m, :X)                                          ≈ two_by_two_scalar_results["X.L","Otax=.1"]#    1.0116855688658395
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
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PUρRA")]) ≈ two_by_two_scalar_results["CWI.L","Otax=.1"] # 156.6285843

set_value(Otax, 0.0)
set_value(Itax, 0.1)
solve!(m)

    @test value(m, :X)                                          ≈ 1.03413947  #two_by_two_scalar_results["X.L","Otax=.2"]# 
    @test MPSGE.Complementarity.result_value(m._jump_model[:Y]) ≈ 1.06713746  #two_by_two_scalar_results["Y.L","Otax=.2"]# 
    @test MPSGE.Complementarity.result_value(m._jump_model[:U]) ≈ 1.04502384  #two_by_two_scalar_results["U.L","Otax=.2"]# 
    @test MPSGE.Complementarity.result_value(m._jump_model[:RA]) ≈ 176.4583 #two_by_two_scalar_results["RA.L","Otax=.2"]# 
    @test MPSGE.Complementarity.result_value(m._jump_model[:PX]) ≈ 1.13755342 #two_by_two_scalar_results["PX.L","Otax=.2"]# 
    @test MPSGE.Complementarity.result_value(m._jump_model[:PY]) ≈ 1.10237803 #two_by_two_scalar_results["PY.L","Otax=.2"]# 
    @test MPSGE.Complementarity.result_value(m._jump_model[:PU]) ≈ 1.12570531 #two_by_two_scalar_results["PU.L","Otax=.2"]# 
    @test MPSGE.Complementarity.result_value(m._jump_model[:PL]) ≈ 1.00000000 #two_by_two_scalar_results["PL.L","Otax=.2"]# 
    @test MPSGE.Complementarity.result_value(m._jump_model[:PK]) ≈ 1.17638889 #two_by_two_scalar_results["PK.L","Otax=.2"]# 
# Implicit Variables
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PL†X")]) ≈ 51.70697347  #two_by_two_scalar_results["DXL.L","Otax=.2"]# 
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PL†Y")]) ≈ 22.04756052  #two_by_two_scalar_results["DYL.L","Otax=.2"]# 
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PK†X")]) ≈ 48.34937789  #two_by_two_scalar_results["DXK.L","Otax=.2"]# 
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PK†Y")]) ≈ 28.11259199  #two_by_two_scalar_results["DYK.L","Otax=.2"]# 
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX†U")]) ≈ 98.95845729  #two_by_two_scalar_results["DUX.L","Otax=.2"]# 
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PY†U")]) ≈ 51.05804384  #two_by_two_scalar_results["DUY.L","Otax=.2"]# 
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX‡X")]) ≈ 100.000  #two_by_two_scalar_results["SX.L","Otax=.2"]# 
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PY‡Y")]) ≈ 50.0000  #two_by_two_scalar_results["SY.L","Otax=.2"]# 
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PU‡U")]) ≈ 150.0000  #two_by_two_scalar_results["SU.L","Otax=.2"]# 
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PUρRA")]) ≈ 156.7536 #two_by_two_scalar_results["CWI.L","Otax=.2"]# 
     
    
end