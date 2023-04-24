@testitem "TWOBYTWOwTax" begin
using XLSX, MPSGE.JuMP.Containers

# A replication of the Two By Two Scalar, with an output Tax in counterfactual: TwoByTwo_Scalar_wTax_MPSGE.gms
m = Model()

esub_x = add!(m, Parameter(:esub_x, value=1.0))    
esub_y = add!(m, Parameter(:esub_y, value=1.0))    
endow  = add!(m, Parameter(:endow, value=1.0))
otax   = add!(m, Parameter(:otax, value = 0.0))

X = add!(m, Sector(:X))
Y = add!(m, Sector(:Y))
U = add!(m, Sector(:U))

PX = add!(m, Commodity(:PX))
PY = add!(m, Commodity(:PY))
PU = add!(m, Commodity(:PU))
PL = add!(m, Commodity(:PL))
PK = add!(m, Commodity(:PK))

RA = add!(m, Consumer(:RA, benchmark = 150.))

@production(m, X, 0, :($esub_x*1.0), [Output(PX, 100., [Tax(:($otax*1.0), RA)])], [Input(PL, 50.), Input(PK,50.)])
@production(m, Y, 0, :($esub_y*1.0), [Output(PY, 50.)], [Input(PL, 20.), Input(PK,30.)])
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
set_value(RA, 157.)
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

set_value(otax, 0.1)
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

set_value(otax, 0.2)
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

set_value(otax, 0.5)
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

set_value(otax, 0.9)
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
    otaxa   = add!(m, Parameter(:otaxa, value = 0.0))
    otaxb   = add!(m, Parameter(:otaxb, value = 0.0))
    
    X = add!(m, Sector(:X))
    Y = add!(m, Sector(:Y))
    U = add!(m, Sector(:U))
    
    PX = add!(m, Commodity(:PX))
    PY = add!(m, Commodity(:PY))
    PU = add!(m, Commodity(:PU))
    PL = add!(m, Commodity(:PL))
    PK = add!(m, Commodity(:PK))
    
    RA = add!(m, Consumer(:RA, indices=(consumers,), benchmark=75.))#(consumption)))
 
    @production(m, X, 0, :($esub_x*1.0), [Output(PX, 100., [Tax(:($otaxa*1.0), RA[:a])])], [Input(PL, 50.), Input(PK,50.)])
    @production(m, Y, 0, :($esub_y*1.0), [Output(PY, 50.,  [Tax(:($otaxb*1.0), RA[:b])])], [Input(PL, 20.), Input(PK,30.)])
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
    set_value(RA[:a], 78.5)
    set_value(RA[:b], 78.5)
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

set_value(otaxa, 0.1)		
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
		
set_value(otaxa, 0.2)		
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
		
set_value(otaxa, 0.5)		
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
		
set_value(otaxa, 0.9)		
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
   		
set_value(otaxa, 0.1)		
set_value(otaxb, 0.1)		
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
		
set_value(otaxa, 0.2)		
set_value(otaxb, 0.2)		
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
		
set_value(otaxa, 0.5)		
set_value(otaxb, 0.5)		
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
		
set_value(otaxa, 0.9)		
set_value(otaxb, 0.9)		
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

@testitem "TWObyTWOwOutTax_tr_elas" begin
    using XLSX, MPSGE.JuMP.Containers
    
    # A replication of the Two By Two Scalar, with an output Tax and non-0 transformation elasticities in counterfactual: TwobyTwo_OutTax1-2Sectors.gms
    m = Model()
    
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
    
    @consumer(m, CONS, benchmark=200.0)
    
    @production(m, A, :($t_elas_a*1.), :($sub_elas_a*1.), [Output(PX, 80, [Tax(:($otax1*1.0), CONS)]), Output(PY, 20, [Tax(:($otax2*1.0), CONS)])], [Input(PL, 40, [Tax(:($itax*1.0), CONS)]), Input(PK, 60, [Tax(:($itax*1.0), CONS)])])
    @production(m, B, :($t_elas_b*1.), :($sub_elas_b*1.), [Output(PX, 20, [Tax(:($otax3*1.0), CONS)]), Output(PY, 80, [Tax(:($otax4*1.0), CONS)])], [Input(PL, 60), Input(PK, 40)])
    @production(m, W, 0, :($sub_elas_w*1.), [Output(PW, 200.0)],[Input(PX, 100.0), Input(PY, 100.0)])
    
    @demand(m, CONS, 1., [Demand(PW, 200.)], [Endowment(PL, 100.0), Endowment(PK, 100.0)])
    
    solve!(m, cumulative_iteration_limit=0)

    gams_results = XLSX.readxlsx(joinpath(@__DIR__, "MPSGEresults.xlsx"))
    a_table = gams_results["TwoxTwoOutTax_1-2"][:]  # Generated from TwoxTwoOutTax_1-2.gms
    two_by_two_scalar_results = DenseAxisArray(a_table[2:end,2:end],a_table[2:end,1],a_table[1,2:end])

    @test MPSGE.Complementarity.result_value(m._jump_model[:A]) ≈ two_by_two_scalar_results["A.L","benchmark"]#  1
    @test MPSGE.Complementarity.result_value(m._jump_model[:B]) ≈ two_by_two_scalar_results["B.L","benchmark"]#  1
    @test MPSGE.Complementarity.result_value(m._jump_model[:W]) ≈ two_by_two_scalar_results["W.L","benchmark"]#  1
    @test MPSGE.Complementarity.result_value(m._jump_model[:PX]) ≈ two_by_two_scalar_results["PX.L","benchmark"]#  1
    @test MPSGE.Complementarity.result_value(m._jump_model[:PY]) ≈ two_by_two_scalar_results["PY.L","benchmark"]#  1
    @test MPSGE.Complementarity.result_value(m._jump_model[:PW]) ≈ two_by_two_scalar_results["PW.L","benchmark"]#  1
    @test MPSGE.Complementarity.result_value(m._jump_model[:PL]) ≈ two_by_two_scalar_results["PL.L","benchmark"]#  1
    @test MPSGE.Complementarity.result_value(m._jump_model[:PK]) ≈ two_by_two_scalar_results["PK.L","benchmark"]#  1
    @test MPSGE.Complementarity.result_value(m._jump_model[:CONS]) ≈ two_by_two_scalar_results["CONS.L","benchmark"]#  200
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX‡A")]) ≈ two_by_two_scalar_results["SAX.L","benchmark"]#  80
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PY‡A")]) ≈ two_by_two_scalar_results["SAY.L","benchmark"]#  20
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX‡B")]) ≈ two_by_two_scalar_results["SBX.L","benchmark"]#  20
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PY‡B")]) ≈ two_by_two_scalar_results["SBY.L","benchmark"]#  80
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PL†A")]) ≈ two_by_two_scalar_results["DAL.L","benchmark"]#  40
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PK†A")]) ≈ two_by_two_scalar_results["DAK.L","benchmark"]#  60
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PL†B")]) ≈ two_by_two_scalar_results["DBL.L","benchmark"]#  60
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PK†B")]) ≈ two_by_two_scalar_results["DBK.L","benchmark"]#  40
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PW‡W")]) ≈ two_by_two_scalar_results["SW.L","benchmark"]#  200
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX†W")]) ≈ two_by_two_scalar_results["DWX.L","benchmark"]#  100
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PY†W")]) ≈ two_by_two_scalar_results["DWY.L","benchmark"]#  100
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PWρCONS")]) ≈ two_by_two_scalar_results["DW.L","benchmark"]#  200
    # CWI ")]) ≈ two_by_two_scalar_results["CWI.L","benchmark"]#  1
        
set_value(otax1, 0.1)
set_fixed!(CONS, true)
set_fixed!(PW, true)
solve!(m)

    @test MPSGE.Complementarity.result_value(m._jump_model[:A]) ≈ two_by_two_scalar_results["A.L","OUTTAX=0.1"]#  1
    @test MPSGE.Complementarity.result_value(m._jump_model[:B]) ≈ two_by_two_scalar_results["B.L","OUTTAX=0.1"]#  1
    @test MPSGE.Complementarity.result_value(m._jump_model[:W]) ≈ two_by_two_scalar_results["W.L","OUTTAX=0.1"]#  1
    @test MPSGE.Complementarity.result_value(m._jump_model[:PX]) ≈ two_by_two_scalar_results["PX.L","OUTTAX=0.1"]#  1.06382979
    @test MPSGE.Complementarity.result_value(m._jump_model[:PY]) ≈ two_by_two_scalar_results["PY.L","OUTTAX=0.1"]#  0.93617021
    @test MPSGE.Complementarity.result_value(m._jump_model[:PW]) ≈ two_by_two_scalar_results["PW.L","OUTTAX=0.1"]#  1
    @test MPSGE.Complementarity.result_value(m._jump_model[:PL]) ≈ two_by_two_scalar_results["PL.L","OUTTAX=0.1"]#  0.9787234
    @test MPSGE.Complementarity.result_value(m._jump_model[:PK]) ≈ two_by_two_scalar_results["PK.L","OUTTAX=0.1"]#  0.93617021
    @test MPSGE.Complementarity.result_value(m._jump_model[:CONS]) ≈ two_by_two_scalar_results["CONS.L","OUTTAX=0.1"]#  200
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX‡A")]) ≈ two_by_two_scalar_results["SAX.L","OUTTAX=0.1"]#  80
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PY‡A")]) ≈ two_by_two_scalar_results["SAY.L","OUTTAX=0.1"]#  20
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX‡B")]) ≈ two_by_two_scalar_results["SBX.L","OUTTAX=0.1"]#  20
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PY‡B")]) ≈ two_by_two_scalar_results["SBY.L","OUTTAX=0.1"]#  80
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PL†A")]) ≈ two_by_two_scalar_results["DAL.L","OUTTAX=0.1"]#  40
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PK†A")]) ≈ two_by_two_scalar_results["DAK.L","OUTTAX=0.1"]#  60
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PL†B")]) ≈ two_by_two_scalar_results["DBL.L","OUTTAX=0.1"]#  60
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PK†B")]) ≈ two_by_two_scalar_results["DBK.L","OUTTAX=0.1"]#  40
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PW‡W")]) ≈ two_by_two_scalar_results["SW.L","OUTTAX=0.1"]#  200
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX†W")]) ≈ two_by_two_scalar_results["DWX.L","OUTTAX=0.1"]#  100
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PY†W")]) ≈ two_by_two_scalar_results["DWY.L","OUTTAX=0.1"]#  100
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PWρCONS")]) ≈ two_by_two_scalar_results["DW.L","OUTTAX=0.1"]#  200
    # CWI ")]) ≈ two_by_two_scalar_results["CWI.L","OUTTAX=0.1"]#  1
    
    
set_fixed!(PW, false)
set_value(sub_elas_a, 1.0)
set_value(sub_elas_b, 1.)
set_value(sub_elas_w, 1.)
solve!(m)
    
    @test MPSGE.Complementarity.result_value(m._jump_model[:A]) ≈ two_by_two_scalar_results["A.L","SUBes=1"]#  0.89337249
    @test MPSGE.Complementarity.result_value(m._jump_model[:B]) ≈ two_by_two_scalar_results["B.L","SUBes=1"]#  1.1061559
    @test MPSGE.Complementarity.result_value(m._jump_model[:W]) ≈ two_by_two_scalar_results["W.L","SUBes=1"]#  0.99772418
    @test MPSGE.Complementarity.result_value(m._jump_model[:PX]) ≈ two_by_two_scalar_results["PX.L","SUBes=1"]#  1.06845692
    @test MPSGE.Complementarity.result_value(m._jump_model[:PY]) ≈ two_by_two_scalar_results["PY.L","SUBes=1"]#  0.94020378
    @test MPSGE.Complementarity.result_value(m._jump_model[:PW]) ≈ two_by_two_scalar_results["PW.L","SUBes=1"]#  1.00228101
    @test MPSGE.Complementarity.result_value(m._jump_model[:PL]) ≈ two_by_two_scalar_results["PL.L","SUBes=1"]#  0.98313215
    @test MPSGE.Complementarity.result_value(m._jump_model[:PK]) ≈ two_by_two_scalar_results["PK.L","SUBes=1"]#  0.94050545
    @test MPSGE.Complementarity.result_value(m._jump_model[:CONS]) ≈ two_by_two_scalar_results["CONS.L","SUBes=1"]#  200
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX‡A")]) ≈ two_by_two_scalar_results["SAX.L","SUBes=1"]#  80
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PY‡A")]) ≈ two_by_two_scalar_results["SAY.L","SUBes=1"]#  20
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX‡B")]) ≈ two_by_two_scalar_results["SBX.L","SUBes=1"]#  20
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PY‡B")]) ≈ two_by_two_scalar_results["SBY.L","SUBes=1"]#  80
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PL†A")]) ≈ two_by_two_scalar_results["DAL.L","SUBes=1"]#  38.95019557
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PK†A")]) ≈ two_by_two_scalar_results["DAK.L","SUBes=1"]#  61.07331347
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PL†B")]) ≈ two_by_two_scalar_results["DBL.L","SUBes=1"]#  58.94554913
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PK†B")]) ≈ two_by_two_scalar_results["DBK.L","SUBes=1"]#  41.07809926
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PW‡W")]) ≈ two_by_two_scalar_results["SW.L","SUBes=1"]#  200
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX†W")]) ≈ two_by_two_scalar_results["DWX.L","SUBes=1"]#  93.8064041
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PY†W")]) ≈ two_by_two_scalar_results["DWY.L","SUBes=1"]#  106.6025
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PWρCONS")]) ≈ two_by_two_scalar_results["DW.L","SUBes=1"]#  199.5448
    # CWI ")]) ≈ two_by_two_scalar_results["CWI.L","SUBes=1"]#  0.99772418
        
set_fixed!(PW, true)
set_fixed!(CONS, false)
solve!(m)
    
    @test MPSGE.Complementarity.result_value(m._jump_model[:A]) ≈ two_by_two_scalar_results["A.L","PW.FX=1"]#  0.89337249
    @test MPSGE.Complementarity.result_value(m._jump_model[:B]) ≈ two_by_two_scalar_results["B.L","PW.FX=1"]#  1.1061559
    @test MPSGE.Complementarity.result_value(m._jump_model[:W]) ≈ two_by_two_scalar_results["W.L","PW.FX=1"]#  0.99772418
    @test MPSGE.Complementarity.result_value(m._jump_model[:PX]) ≈ two_by_two_scalar_results["PX.L","PW.FX=1"]#  1.0660253
    @test MPSGE.Complementarity.result_value(m._jump_model[:PY]) ≈ two_by_two_scalar_results["PY.L","PW.FX=1"]#  0.93806404
    @test MPSGE.Complementarity.result_value(m._jump_model[:PW]) ≈ two_by_two_scalar_results["PW.L","PW.FX=1"]#  1
    @test MPSGE.Complementarity.result_value(m._jump_model[:PL]) ≈ two_by_two_scalar_results["PL.L","PW.FX=1"]#  0.98089471
    @test MPSGE.Complementarity.result_value(m._jump_model[:PK]) ≈ two_by_two_scalar_results["PK.L","PW.FX=1"]#  0.93836503
    @test MPSGE.Complementarity.result_value(m._jump_model[:CONS]) ≈ two_by_two_scalar_results["CONS.L","PW.FX=1"]#  199.5448
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX‡A")]) ≈ two_by_two_scalar_results["SAX.L","PW.FX=1"]#  80
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PY‡A")]) ≈ two_by_two_scalar_results["SAY.L","PW.FX=1"]#  20
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX‡B")]) ≈ two_by_two_scalar_results["SBX.L","PW.FX=1"]#  20
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PY‡B")]) ≈ two_by_two_scalar_results["SBY.L","PW.FX=1"]#  80
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PL†A")]) ≈ two_by_two_scalar_results["DAL.L","PW.FX=1"]#  38.95019557
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PK†A")]) ≈ two_by_two_scalar_results["DAK.L","PW.FX=1"]#  61.07331347
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PL†B")]) ≈ two_by_two_scalar_results["DBL.L","PW.FX=1"]#  58.94554913
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PK†B")]) ≈ two_by_two_scalar_results["DBK.L","PW.FX=1"]#  41.07809926
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PW‡W")]) ≈ two_by_two_scalar_results["SW.L","PW.FX=1"]#  200
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX†W")]) ≈ two_by_two_scalar_results["DWX.L","PW.FX=1"]#  93.8064041
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PY†W")]) ≈ two_by_two_scalar_results["DWY.L","PW.FX=1"]#  106.6025
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PWρCONS")]) ≈ two_by_two_scalar_results["DW.L","PW.FX=1"]#  199.5448
    # CWI ")]) ≈ two_by_two_scalar_results["CWI.L","PW.FX=1"]#  0.99772418

set_value(otax1, 0.2)
solve!(m)
    
    @test MPSGE.Complementarity.result_value(m._jump_model[:A]) ≈ two_by_two_scalar_results["A.L","OUTTAX=0.2"]#  0.77047179
    @test MPSGE.Complementarity.result_value(m._jump_model[:B]) ≈ two_by_two_scalar_results["B.L","OUTTAX=0.2"]#  1.22735428
    @test MPSGE.Complementarity.result_value(m._jump_model[:W]) ≈ two_by_two_scalar_results["W.L","OUTTAX=0.2"]#  0.98946476
    @test MPSGE.Complementarity.result_value(m._jump_model[:PX]) ≈ two_by_two_scalar_results["PX.L","OUTTAX=0.2"]#  1.14807301
    @test MPSGE.Complementarity.result_value(m._jump_model[:PY]) ≈ two_by_two_scalar_results["PY.L","OUTTAX=0.2"]#  0.87102475
    @test MPSGE.Complementarity.result_value(m._jump_model[:PW]) ≈ two_by_two_scalar_results["PW.L","OUTTAX=0.2"]#  1
    @test MPSGE.Complementarity.result_value(m._jump_model[:PL]) ≈ two_by_two_scalar_results["PL.L","OUTTAX=0.2"]#  0.96237275
    @test MPSGE.Complementarity.result_value(m._jump_model[:PK]) ≈ two_by_two_scalar_results["PK.L","OUTTAX=0.2"]#  0.87502751
    @test MPSGE.Complementarity.result_value(m._jump_model[:CONS]) ≈ two_by_two_scalar_results["CONS.L","OUTTAX=0.2"]#  197.893
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX‡A")]) ≈ two_by_two_scalar_results["SAX.L","OUTTAX=0.2"]#  80
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PY‡A")]) ≈ two_by_two_scalar_results["SAY.L","OUTTAX=0.2"]#  20
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX‡B")]) ≈ two_by_two_scalar_results["SBX.L","OUTTAX=0.2"]#  20
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PY‡B")]) ≈ two_by_two_scalar_results["SBY.L","OUTTAX=0.2"]#  80
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PL†A")]) ≈ two_by_two_scalar_results["DAL.L","OUTTAX=0.2"]#  37.78044124
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PK†A")]) ≈ two_by_two_scalar_results["DAK.L","OUTTAX=0.2"]#  62.32752679
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PL†B")]) ≈ two_by_two_scalar_results["DBL.L","OUTTAX=0.2"]#  57.75939116
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PK†B")]) ≈ two_by_two_scalar_results["DBK.L","OUTTAX=0.2"]#  42.34995536
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PW‡W")]) ≈ two_by_two_scalar_results["SW.L","OUTTAX=0.2"]#  200
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX†W")]) ≈ two_by_two_scalar_results["DWX.L","OUTTAX=0.2"]#  87.10247453
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PY†W")]) ≈ two_by_two_scalar_results["DWY.L","OUTTAX=0.2"]#  114.8073
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PWρCONS")]) ≈ two_by_two_scalar_results["DW.L","OUTTAX=0.2"]#  197.893
    # CWI ")]) ≈ two_by_two_scalar_results["CWI.L","OUTTAX=0.2"]#  0.98946476

set_value(t_elas_a, 3.0)
set_value(t_elas_b, 1.0)
solve!(m)

    @test MPSGE.Complementarity.result_value(m._jump_model[:A]) ≈ two_by_two_scalar_results["A.L","TrA=3B=1"]#  0.64533631
    @test MPSGE.Complementarity.result_value(m._jump_model[:B]) ≈ two_by_two_scalar_results["B.L","TrA=3B=1"]#  1.34950119
    @test MPSGE.Complementarity.result_value(m._jump_model[:W]) ≈ two_by_two_scalar_results["W.L","TrA=3B=1"]#  0.9838439
    @test MPSGE.Complementarity.result_value(m._jump_model[:PX]) ≈ two_by_two_scalar_results["PX.L","TrA=3B=1"]#  1.14393203
    @test MPSGE.Complementarity.result_value(m._jump_model[:PY]) ≈ two_by_two_scalar_results["PY.L","TrA=3B=1"]#  0.87417782
    @test MPSGE.Complementarity.result_value(m._jump_model[:PW]) ≈ two_by_two_scalar_results["PW.L","TrA=3B=1"]#  1
    @test MPSGE.Complementarity.result_value(m._jump_model[:PL]) ≈ two_by_two_scalar_results["PL.L","TrA=3B=1"]#  0.99079613
    @test MPSGE.Complementarity.result_value(m._jump_model[:PK]) ≈ two_by_two_scalar_results["PK.L","TrA=3B=1"]#  0.85572088
    @test MPSGE.Complementarity.result_value(m._jump_model[:CONS]) ≈ two_by_two_scalar_results["CONS.L","TrA=3B=1"]#  196.7688
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX‡A")]) ≈ two_by_two_scalar_results["SAX.L","TrA=3B=1"]#  82.06946612
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PY‡A")]) ≈ two_by_two_scalar_results["SAY.L","TrA=3B=1"]#  17.88341039
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX‡B")]) ≈ two_by_two_scalar_results["SBX.L","TrA=3B=1"]#  24.48537622
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PY‡B")]) ≈ two_by_two_scalar_results["SBY.L","TrA=3B=1"]#  74.84561046
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PL†A")]) ≈ two_by_two_scalar_results["DAL.L","TrA=3B=1"]#  36.63267965
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PK†A")]) ≈ two_by_two_scalar_results["DAK.L","TrA=3B=1"]#  63.62270345
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PL†B")]) ≈ two_by_two_scalar_results["DBL.L","TrA=3B=1"]#  56.5835748
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PK†B")]) ≈ two_by_two_scalar_results["DBK.L","TrA=3B=1"]#  43.67684852
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PW‡W")]) ≈ two_by_two_scalar_results["SW.L","TrA=3B=1"]#  200
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX†W")]) ≈ two_by_two_scalar_results["DWX.L","TrA=3B=1"]#  87.41778159
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PY†W")]) ≈ two_by_two_scalar_results["DWY.L","TrA=3B=1"]#  114.3932
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PWρCONS")]) ≈ two_by_two_scalar_results["DW.L","TrA=3B=1"]#  196.7688
    # CWI ")]) ≈ two_by_two_scalar_results["CWI.L","TrA=3B=1"]#  0.9838439

set_value(t_elas_a, 1.0)
set_value(t_elas_b, 1.0)
solve!(m)

    @test MPSGE.Complementarity.result_value(m._jump_model[:A]) ≈ two_by_two_scalar_results["A.L","TrA/B=1"]#  0.65743472
    @test MPSGE.Complementarity.result_value(m._jump_model[:B]) ≈ two_by_two_scalar_results["B.L","TrA/B=1"]#  1.33774645
    @test MPSGE.Complementarity.result_value(m._jump_model[:W]) ≈ two_by_two_scalar_results["W.L","TrA/B=1"]#  0.98388691
    @test MPSGE.Complementarity.result_value(m._jump_model[:PX]) ≈ two_by_two_scalar_results["PX.L","TrA/B=1"]#  1.14538803
    @test MPSGE.Complementarity.result_value(m._jump_model[:PY]) ≈ two_by_two_scalar_results["PY.L","TrA/B=1"]#  0.87306657
    @test MPSGE.Complementarity.result_value(m._jump_model[:PW]) ≈ two_by_two_scalar_results["PW.L","TrA/B=1"]#  1
    @test MPSGE.Complementarity.result_value(m._jump_model[:PL]) ≈ two_by_two_scalar_results["PL.L","TrA/B=1"]#  0.98833168
    @test MPSGE.Complementarity.result_value(m._jump_model[:PK]) ≈ two_by_two_scalar_results["PK.L","TrA/B=1"]#  0.85783333
    @test MPSGE.Complementarity.result_value(m._jump_model[:CONS]) ≈ two_by_two_scalar_results["CONS.L","TrA/B=1"]#  196.7774
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX‡A")]) ≈ two_by_two_scalar_results["SAX.L","TrA/B=1"]#  80.74762872
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PY‡A")]) ≈ two_by_two_scalar_results["SAY.L","TrA/B=1"]#  19.23421727
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX‡B")]) ≈ two_by_two_scalar_results["SBX.L","TrA/B=1"]#  24.52899978
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PY‡B")]) ≈ two_by_two_scalar_results["SBY.L","TrA/B=1"]#  74.78845284
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PL†A")]) ≈ two_by_two_scalar_results["DAL.L","TrA/B=1"]#  36.74177319
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PK†A")]) ≈ two_by_two_scalar_results["DAK.L","TrA/B=1"]#  63.49670218
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PL†B")]) ≈ two_by_two_scalar_results["DBL.L","TrA/B=1"]#  56.69585784
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PK†B")]) ≈ two_by_two_scalar_results["DBK.L","TrA/B=1"]#  43.54716338
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PW‡W")]) ≈ two_by_two_scalar_results["SW.L","TrA/B=1"]#  200
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX†W")]) ≈ two_by_two_scalar_results["DWX.L","TrA/B=1"]#  87.30665698
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PY†W")]) ≈ two_by_two_scalar_results["DWY.L","TrA/B=1"]#  114.5388
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PWρCONS")]) ≈ two_by_two_scalar_results["DW.L","TrA/B=1"]#  196.7774
    # CWI ")]) ≈ two_by_two_scalar_results["CWI.L","TrA/B=1"]#  0.98388691

set_value(t_elas_a, 2.0)
set_value(t_elas_b, 1.5)
solve!(m)

    @test MPSGE.Complementarity.result_value(m._jump_model[:A]) ≈ two_by_two_scalar_results["A.L","S1Tr2,1.5"]#  0.59043553
    @test MPSGE.Complementarity.result_value(m._jump_model[:B]) ≈ two_by_two_scalar_results["B.L","S1Tr2,1.5"]#  1.40269647
    @test MPSGE.Complementarity.result_value(m._jump_model[:W]) ≈ two_by_two_scalar_results["W.L","S1Tr2,1.5"]#  0.98045634
    @test MPSGE.Complementarity.result_value(m._jump_model[:PX]) ≈ two_by_two_scalar_results["PX.L","S1Tr2,1.5"]#  1.14305464
    @test MPSGE.Complementarity.result_value(m._jump_model[:PY]) ≈ two_by_two_scalar_results["PY.L","S1Tr2,1.5"]#  0.87484882
    @test MPSGE.Complementarity.result_value(m._jump_model[:PW]) ≈ two_by_two_scalar_results["PW.L","S1Tr2,1.5"]#  1
    @test MPSGE.Complementarity.result_value(m._jump_model[:PL]) ≈ two_by_two_scalar_results["PL.L","S1Tr2,1.5"]#  1.0035789
    @test MPSGE.Complementarity.result_value(m._jump_model[:PK]) ≈ two_by_two_scalar_results["PK.L","S1Tr2,1.5"]#  0.84752137
    @test MPSGE.Complementarity.result_value(m._jump_model[:CONS]) ≈ two_by_two_scalar_results["CONS.L","S1Tr2,1.5"]#  196.0913
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX‡A")]) ≈ two_by_two_scalar_results["SAX.L","S1Tr2,1.5"]#  81.35456661
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PY‡A")]) ≈ two_by_two_scalar_results["SAY.L","S1Tr2,1.5"]#  18.61547012
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX‡B")]) ≈ two_by_two_scalar_results["SBX.L","S1Tr2,1.5"]#  26.90566422
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PY‡B")]) ≈ two_by_two_scalar_results["SBY.L","S1Tr2,1.5"]#  72.06140704
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PL†A")]) ≈ two_by_two_scalar_results["DAL.L","S1Tr2,1.5"]#  36.14260684
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PK†A")]) ≈ two_by_two_scalar_results["DAK.L","S1Tr2,1.5"]#  64.19653617
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PL†B")]) ≈ two_by_two_scalar_results["DBL.L","S1Tr2,1.5"]#  56.07779197
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PK†B")]) ≈ two_by_two_scalar_results["DBK.L","S1Tr2,1.5"]#  44.26908128
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PW‡W")]) ≈ two_by_two_scalar_results["SW.L","S1Tr2,1.5"]#  200
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX†W")]) ≈ two_by_two_scalar_results["DWX.L","S1Tr2,1.5"]#  87.48488182
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PY†W")]) ≈ two_by_two_scalar_results["DWY.L","S1Tr2,1.5"]#  114.3055
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PWρCONS")]) ≈ two_by_two_scalar_results["DW.L","S1Tr2,1.5"]#  196.0913
    # CWI ")]) ≈ two_by_two_scalar_results["CWI.L","S1Tr2,1.5"]#  0.98045634

set_value(sub_elas_a, 0.)
set_value(sub_elas_b, 0.)
set_value(sub_elas_w, 0.)
set_value(t_elas_a, 3.0)
set_value(t_elas_b, 1.0)
solve!(m)
     
    @test MPSGE.Complementarity.result_value(m._jump_model[:A]) ≈ two_by_two_scalar_results["A.L","S0Tr=3,1"]#  1
    @test MPSGE.Complementarity.result_value(m._jump_model[:B]) ≈ two_by_two_scalar_results["B.L","S0Tr=3,1"]#  1
    @test MPSGE.Complementarity.result_value(m._jump_model[:W]) ≈ two_by_two_scalar_results["W.L","S0Tr=3,1"]#  0.99836642
    @test MPSGE.Complementarity.result_value(m._jump_model[:PX]) ≈ two_by_two_scalar_results["PX.L","S0Tr=3,1"]#  1.08317338
    @test MPSGE.Complementarity.result_value(m._jump_model[:PY]) ≈ two_by_two_scalar_results["PY.L","S0Tr=3,1"]#  0.91682662
    @test MPSGE.Complementarity.result_value(m._jump_model[:PW]) ≈ two_by_two_scalar_results["PW.L","S0Tr=3,1"]#  1
    @test MPSGE.Complementarity.result_value(m._jump_model[:PL]) ≈ two_by_two_scalar_results["PL.L","S0Tr=3,1"]#  1.10266152
    @test MPSGE.Complementarity.result_value(m._jump_model[:PK]) ≈ two_by_two_scalar_results["PK.L","S0Tr=3,1"]#  0.72706546
    @test MPSGE.Complementarity.result_value(m._jump_model[:CONS]) ≈ two_by_two_scalar_results["CONS.L","S0Tr=3,1"]#  199.6733
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX‡A")]) ≈ two_by_two_scalar_results["SAX.L","S0Tr=3,1"]#  77.09100751
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PY‡A")]) ≈ two_by_two_scalar_results["SAY.L","S0Tr=3,1"]#  22.82661349
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX‡B")]) ≈ two_by_two_scalar_results["SBX.L","S0Tr=3,1"]#  22.74563436
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PY‡B")]) ≈ two_by_two_scalar_results["SBY.L","S0Tr=3,1"]#  77.01002838
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PL†A")]) ≈ two_by_two_scalar_results["DAL.L","S0Tr=3,1"]#  40
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PK†A")]) ≈ two_by_two_scalar_results["DAK.L","S0Tr=3,1"]#  60
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PL†B")]) ≈ two_by_two_scalar_results["DBL.L","S0Tr=3,1"]#  60
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PK†B")]) ≈ two_by_two_scalar_results["DBK.L","S0Tr=3,1"]#  40
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PW‡W")]) ≈ two_by_two_scalar_results["SW.L","S0Tr=3,1"]#  200
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX†W")]) ≈ two_by_two_scalar_results["DWX.L","S0Tr=3,1"]#  100
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PY†W")]) ≈ two_by_two_scalar_results["DWY.L","S0Tr=3,1"]#  100
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PWρCONS")]) ≈ two_by_two_scalar_results["DW.L","S0Tr=3,1"]#  199.6733
    # CWI ")]) ≈ two_by_two_scalar_results["CWI.L","S0Tr=3,1"]#  0.99836642

set_value(t_elas_a, 1.0)
set_value(t_elas_b, 1.0)
solve!(m)
    
    @test MPSGE.Complementarity.result_value(m._jump_model[:A]) ≈ two_by_two_scalar_results["A.L","Sub=0Tr=1"]#  1
    @test MPSGE.Complementarity.result_value(m._jump_model[:B]) ≈ two_by_two_scalar_results["B.L","Sub=0Tr=1"]#  1
    @test MPSGE.Complementarity.result_value(m._jump_model[:W]) ≈ two_by_two_scalar_results["W.L","Sub=0Tr=1"]#  0.99893795
    @test MPSGE.Complementarity.result_value(m._jump_model[:PX]) ≈ two_by_two_scalar_results["PX.L","Sub=0Tr=1"]#  1.05572809
    @test MPSGE.Complementarity.result_value(m._jump_model[:PY]) ≈ two_by_two_scalar_results["PY.L","Sub=0Tr=1"]#  0.94427191
    @test MPSGE.Complementarity.result_value(m._jump_model[:PW]) ≈ two_by_two_scalar_results["PW.L","Sub=0Tr=1"]#  1
    @test MPSGE.Complementarity.result_value(m._jump_model[:PL]) ≈ two_by_two_scalar_results["PL.L","Sub=0Tr=1"]#  1.17189333
    @test MPSGE.Complementarity.result_value(m._jump_model[:PK]) ≈ two_by_two_scalar_results["PK.L","Sub=0Tr=1"]#  0.66113695
    @test MPSGE.Complementarity.result_value(m._jump_model[:CONS]) ≈ two_by_two_scalar_results["CONS.L","Sub=0Tr=1"]#  199.7876
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX‡A")]) ≈ two_by_two_scalar_results["SAX.L","Sub=0Tr=1"]#  78.07200584
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PY‡A")]) ≈ two_by_two_scalar_results["SAY.L","Sub=0Tr=1"]#  21.82178902
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX‡B")]) ≈ two_by_two_scalar_results["SBX.L","Sub=0Tr=1"]#  21.82178903
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PY‡B")]) ≈ two_by_two_scalar_results["SBY.L","Sub=0Tr=1"]#  78.07200583
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PL†A")]) ≈ two_by_two_scalar_results["DAL.L","Sub=0Tr=1"]#  40
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PK†A")]) ≈ two_by_two_scalar_results["DAK.L","Sub=0Tr=1"]#  60
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PL†B")]) ≈ two_by_two_scalar_results["DBL.L","Sub=0Tr=1"]#  60
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PK†B")]) ≈ two_by_two_scalar_results["DBK.L","Sub=0Tr=1"]#  40
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PW‡W")]) ≈ two_by_two_scalar_results["SW.L","Sub=0Tr=1"]#  200
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX†W")]) ≈ two_by_two_scalar_results["DWX.L","Sub=0Tr=1"]#  100
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PY†W")]) ≈ two_by_two_scalar_results["DWY.L","Sub=0Tr=1"]#  100
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PWρCONS")]) ≈ two_by_two_scalar_results["DW.L","Sub=0Tr=1"]#  199.7876
    # CWI ")]) ≈ two_by_two_scalar_results["CWI.L","Sub=0Tr=1"]#  0.99893795


set_value(sub_elas_a, 1.5)
set_value(sub_elas_b, 2.)
set_value(sub_elas_w, 0.5)
set_value(t_elas_a, 0.0)
set_value(t_elas_b, 0.0)
solve!(m)

    @test MPSGE.Complementarity.result_value(m._jump_model[:A]) ≈ two_by_two_scalar_results["A.L","1.52,.5T0"]#  0.87514262
    @test MPSGE.Complementarity.result_value(m._jump_model[:B]) ≈ two_by_two_scalar_results["B.L","1.52,.5T0"]#  1.12449411
    @test MPSGE.Complementarity.result_value(m._jump_model[:W]) ≈ two_by_two_scalar_results["W.L","1.52,.5T0"]#  0.99422149
    @test MPSGE.Complementarity.result_value(m._jump_model[:PX]) ≈ two_by_two_scalar_results["PX.L","1.52,.5T0"]#  1.15523596
    @test MPSGE.Complementarity.result_value(m._jump_model[:PY]) ≈ two_by_two_scalar_results["PY.L","1.52,.5T0"]#  0.85595982
    @test MPSGE.Complementarity.result_value(m._jump_model[:PW]) ≈ two_by_two_scalar_results["PW.L","1.52,.5T0"]#  1
    @test MPSGE.Complementarity.result_value(m._jump_model[:PL]) ≈ two_by_two_scalar_results["PL.L","1.52,.5T0"]#  0.92664016
    @test MPSGE.Complementarity.result_value(m._jump_model[:PK]) ≈ two_by_two_scalar_results["PK.L","1.52,.5T0"]#  0.90004343
    @test MPSGE.Complementarity.result_value(m._jump_model[:CONS]) ≈ two_by_two_scalar_results["CONS.L","1.52,.5T0"]#  198.8443
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX‡A")]) ≈ two_by_two_scalar_results["SAX.L","1.52,.5T0"]#  80
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PY‡A")]) ≈ two_by_two_scalar_results["SAY.L","1.52,.5T0"]#  20
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX‡B")]) ≈ two_by_two_scalar_results["SBX.L","1.52,.5T0"]#  20
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PY‡B")]) ≈ two_by_two_scalar_results["SBY.L","1.52,.5T0"]#  80
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PL†A")]) ≈ two_by_two_scalar_results["DAL.L","1.52,.5T0"]#  38.9622461
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PK†A")]) ≈ two_by_two_scalar_results["DAK.L","1.52,.5T0"]#  61.0529602
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PL†B")]) ≈ two_by_two_scalar_results["DBL.L","1.52,.5T0"]#  58.60633444
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PK†B")]) ≈ two_by_two_scalar_results["DBK.L","1.52,.5T0"]#  41.41413634
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PW‡W")]) ≈ two_by_two_scalar_results["SW.L","1.52,.5T0"]#  200
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX†W")]) ≈ two_by_two_scalar_results["DWX.L","1.52,.5T0"]#  93.03891791
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PY†W")]) ≈ two_by_two_scalar_results["DWY.L","1.52,.5T0"]#  108.087
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PWρCONS")]) ≈ two_by_two_scalar_results["DW.L","1.52,.5T0"]#  198.8443
    # CWI ")]) ≈ two_by_two_scalar_results["CWI.L","1.52,.5T0"]#  0.99422149
    
       
set_value(t_elas_a, 2.0)
set_value(t_elas_b, 1.5)
solve!(m)
        
    @test MPSGE.Complementarity.result_value(m._jump_model[:A]) ≈ two_by_two_scalar_results["A.L","S..T2,1.5"]#  0.65301554
    @test MPSGE.Complementarity.result_value(m._jump_model[:B]) ≈ two_by_two_scalar_results["B.L","S..T2,1.5"]#  1.34428248
    @test MPSGE.Complementarity.result_value(m._jump_model[:W]) ≈ two_by_two_scalar_results["W.L","S..T2,1.5"]#  0.98334631
    @test MPSGE.Complementarity.result_value(m._jump_model[:PX]) ≈ two_by_two_scalar_results["PX.L","S..T2,1.5"]#  1.15814902
    @test MPSGE.Complementarity.result_value(m._jump_model[:PY]) ≈ two_by_two_scalar_results["PY.L","S..T2,1.5"]#  0.85345573
    @test MPSGE.Complementarity.result_value(m._jump_model[:PW]) ≈ two_by_two_scalar_results["PW.L","S..T2,1.5"]#  1
    @test MPSGE.Complementarity.result_value(m._jump_model[:PL]) ≈ two_by_two_scalar_results["PL.L","S..T2,1.5"]#  0.95693303
    @test MPSGE.Complementarity.result_value(m._jump_model[:PK]) ≈ two_by_two_scalar_results["PK.L","S..T2,1.5"]#  0.88509599
    @test MPSGE.Complementarity.result_value(m._jump_model[:CONS]) ≈ two_by_two_scalar_results["CONS.L","S..T2,1.5"]#  196.6693
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX‡A")]) ≈ two_by_two_scalar_results["SAX.L","S..T2,1.5"]#  82.41792731
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PY‡A")]) ≈ two_by_two_scalar_results["SAY.L","S..T2,1.5"]#  17.48295499
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX‡B")]) ≈ two_by_two_scalar_results["SBX.L","S..T2,1.5"]#  27.93620902
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PY‡B")]) ≈ two_by_two_scalar_results["SBY.L","S..T2,1.5"]#  70.6890752
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PL†A")]) ≈ two_by_two_scalar_results["DAL.L","S..T2,1.5"]#  37.26666598
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PK†A")]) ≈ two_by_two_scalar_results["DAK.L","S..T2,1.5"]#  62.84179114
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PL†B")]) ≈ two_by_two_scalar_results["DBL.L","S..T2,1.5"]#  56.28600301
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PK†B")]) ≈ two_by_two_scalar_results["DBK.L","S..T2,1.5"]#  43.86230905
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PW‡W")]) ≈ two_by_two_scalar_results["SW.L","S..T2,1.5"]#  200
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX†W")]) ≈ two_by_two_scalar_results["DWX.L","S..T2,1.5"]#  92.92183527
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PY†W")]) ≈ two_by_two_scalar_results["DWY.L","S..T2,1.5"]#  108.2454
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PWρCONS")]) ≈ two_by_two_scalar_results["DW.L","S..T2,1.5"]#  196.6693
    # CWI ")]) ≈ two_by_two_scalar_results["CWI.L","S..T2,1.5"]#  0.98334631

set_value(t_elas_a, 3.0)
set_value(t_elas_b, 1.0)
solve!(m)

    @test MPSGE.Complementarity.result_value(m._jump_model[:A]) ≈ two_by_two_scalar_results["A.L","S...T3,1"]#  0.717787
    @test MPSGE.Complementarity.result_value(m._jump_model[:B]) ≈ two_by_two_scalar_results["B.L","S...T3,1"]#  1.28040608
    @test MPSGE.Complementarity.result_value(m._jump_model[:W]) ≈ two_by_two_scalar_results["W.L","S...T3,1"]#  0.98762504
    @test MPSGE.Complementarity.result_value(m._jump_model[:PX]) ≈ two_by_two_scalar_results["PX.L","S...T3,1"]#  1.15559805
    @test MPSGE.Complementarity.result_value(m._jump_model[:PY]) ≈ two_by_two_scalar_results["PY.L","S...T3,1"]#  0.85564819
    @test MPSGE.Complementarity.result_value(m._jump_model[:PW]) ≈ two_by_two_scalar_results["PW.L","S...T3,1"]#  1
    @test MPSGE.Complementarity.result_value(m._jump_model[:PL]) ≈ two_by_two_scalar_results["PL.L","S...T3,1"]#  0.94793634
    @test MPSGE.Complementarity.result_value(m._jump_model[:PK]) ≈ two_by_two_scalar_results["PK.L","S...T3,1"]#  0.88903973
    @test MPSGE.Complementarity.result_value(m._jump_model[:CONS]) ≈ two_by_two_scalar_results["CONS.L","S...T3,1"]#  197.525
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX‡A")]) ≈ two_by_two_scalar_results["SAX.L","S...T3,1"]#  83.35049624
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PY‡A")]) ≈ two_by_two_scalar_results["SAY.L","S...T3,1"]#  16.52127468
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX‡B")]) ≈ two_by_two_scalar_results["SBX.L","S...T3,1"]#  25.0274236
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PY‡B")]) ≈ two_by_two_scalar_results["SBY.L","S...T3,1"]#  74.12497738
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PL†A")]) ≈ two_by_two_scalar_results["DAL.L","S...T3,1"]#  37.7422087
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PK†A")]) ≈ two_by_two_scalar_results["DAK.L","S...T3,1"]#  62.33121254
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PL†B")]) ≈ two_by_two_scalar_results["DBL.L","S...T3,1"]#  56.94219551
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PK†B")]) ≈ two_by_two_scalar_results["DBK.L","S...T3,1"]#  43.15776592
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PW‡W")]) ≈ two_by_two_scalar_results["SW.L","S...T3,1"]#  200
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX†W")]) ≈ two_by_two_scalar_results["DWX.L","S...T3,1"]#  93.02434064
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PY†W")]) ≈ two_by_two_scalar_results["DWY.L","S...T3,1"]#  108.1066
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PWρCONS")]) ≈ two_by_two_scalar_results["DW.L","S...T3,1"]#  197.525
    # CWI ")]) ≈ two_by_two_scalar_results["CWI.L","S...T3,1"]#  0.98762504

set_value(t_elas_a, 1.0)
set_value(t_elas_b, 1.0)
solve!(m)

    @test MPSGE.Complementarity.result_value(m._jump_model[:A]) ≈ two_by_two_scalar_results["A.L","S...T1"]#  0.74236189
    @test MPSGE.Complementarity.result_value(m._jump_model[:B]) ≈ two_by_two_scalar_results["B.L","S...T1"]#  1.25612592
    @test MPSGE.Complementarity.result_value(m._jump_model[:W]) ≈ two_by_two_scalar_results["W.L","S...T1"]#  0.98786685
    @test MPSGE.Complementarity.result_value(m._jump_model[:PX]) ≈ two_by_two_scalar_results["PX.L","S...T1"]#  1.15758898
    @test MPSGE.Complementarity.result_value(m._jump_model[:PY]) ≈ two_by_two_scalar_results["PY.L","S...T1"]#  0.85393661
    @test MPSGE.Complementarity.result_value(m._jump_model[:PW]) ≈ two_by_two_scalar_results["PW.L","S...T1"]#  1
    @test MPSGE.Complementarity.result_value(m._jump_model[:PL]) ≈ two_by_two_scalar_results["PL.L","S...T1"]#  0.94504732
    @test MPSGE.Complementarity.result_value(m._jump_model[:PK]) ≈ two_by_two_scalar_results["PK.L","S...T1"]#  0.8910844
    @test MPSGE.Complementarity.result_value(m._jump_model[:CONS]) ≈ two_by_two_scalar_results["CONS.L","S...T1"]#  197.5734
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX‡A")]) ≈ two_by_two_scalar_results["SAX.L","S...T1"]#  81.22533941
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PY‡A")]) ≈ two_by_two_scalar_results["SAY.L","S...T1"]#  18.72461106
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX‡B")]) ≈ two_by_two_scalar_results["SBX.L","S...T1"]#  25.09143825
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PY‡B")]) ≈ two_by_two_scalar_results["SBY.L","S...T1"]#  74.03836104
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PL†A")]) ≈ two_by_two_scalar_results["DAL.L","S...T1"]#  37.92659869
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PK†A")]) ≈ two_by_two_scalar_results["DAK.L","S...T1"]#  62.13513247
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PL†B")]) ≈ two_by_two_scalar_results["DBL.L","S...T1"]#  57.19549083
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PK†B")]) ≈ two_by_two_scalar_results["DBK.L","S...T1"]#  42.8884117
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PW‡W")]) ≈ two_by_two_scalar_results["SW.L","S...T1"]#  200
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX†W")]) ≈ two_by_two_scalar_results["DWX.L","S...T1"]#  92.94430997
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PY†W")]) ≈ two_by_two_scalar_results["DWY.L","S...T1"]#  108.2149
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PWρCONS")]) ≈ two_by_two_scalar_results["DW.L","S...T1"]#  197.5734
    # CWI ")]) ≈ two_by_two_scalar_results["CWI.L","S...T1,1"]#  0.98786685

set_value(otax2, 0.1)
solve!(m)

    @test MPSGE.Complementarity.result_value(m._jump_model[:A]) ≈ two_by_two_scalar_results["A.L","S.T1,O2=.1"]#  0.69377214
    @test MPSGE.Complementarity.result_value(m._jump_model[:B]) ≈ two_by_two_scalar_results["B.L","S.T1,O2=.1"]#  1.30410892
    @test MPSGE.Complementarity.result_value(m._jump_model[:W]) ≈ two_by_two_scalar_results["W.L","S.T1,O2=.1"]#  0.98418612
    @test MPSGE.Complementarity.result_value(m._jump_model[:PX]) ≈ two_by_two_scalar_results["PX.L","S.T1,O2=.1"]#  1.17251766
    @test MPSGE.Complementarity.result_value(m._jump_model[:PY]) ≈ two_by_two_scalar_results["PY.L","S.T1,O2=.1"]#  0.84120348
    @test MPSGE.Complementarity.result_value(m._jump_model[:PW]) ≈ two_by_two_scalar_results["PW.L","S.T1,O2=.1"]#  1
    @test MPSGE.Complementarity.result_value(m._jump_model[:PL]) ≈ two_by_two_scalar_results["PL.L","S.T1,O2=.1"]#  0.94342778
    @test MPSGE.Complementarity.result_value(m._jump_model[:PK]) ≈ two_by_two_scalar_results["PK.L","S.T1,O2=.1"]#  0.88023493
    @test MPSGE.Complementarity.result_value(m._jump_model[:CONS]) ≈ two_by_two_scalar_results["CONS.L","S.T1,O2=.1"]#  196.8372
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX‡A")]) ≈ two_by_two_scalar_results["SAX.L","S.T1,O2=.1"]#  82.94337454
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PY‡A")]) ≈ two_by_two_scalar_results["SAY.L","S.T1,O2=.1"]#  16.73616309
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX‡B")]) ≈ two_by_two_scalar_results["SBX.L","S.T1,O2=.1"]#  25.57033231
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PY‡B")]) ≈ two_by_two_scalar_results["SBY.L","S.T1,O2=.1"]#  73.38005467
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PL†A")]) ≈ two_by_two_scalar_results["DAL.L","S.T1,O2=.1"]#  37.56414425
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PK†A")]) ≈ two_by_two_scalar_results["DAK.L","S.T1,O2=.1"]#  62.52156613
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PL†B")]) ≈ two_by_two_scalar_results["DBL.L","S.T1,O2=.1"]#  56.6969846
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PK†B")]) ≈ two_by_two_scalar_results["DBK.L","S.T1,O2=.1"]#  43.41990034
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PW‡W")]) ≈ two_by_two_scalar_results["SW.L","S.T1,O2=.1"]#  200
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX†W")]) ≈ two_by_two_scalar_results["DWX.L","S.T1,O2=.1"]#  92.3507239
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PY†W")]) ≈ two_by_two_scalar_results["DWY.L","S.T1,O2=.1"]#  109.0309
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PWρCONS")]) ≈ two_by_two_scalar_results["DW.L","S.T1,O2=.1"]#  196.8372
    # CWI ")]) ≈ two_by_two_scalar_results["CWI.L","S.T1,O2=.1"]#  0.98418612

set_value(otax2, 0.)
set_value(otax3, 0.1)
solve!(m)

    @test MPSGE.Complementarity.result_value(m._jump_model[:A]) ≈ two_by_two_scalar_results["A.L","S.T1,O3=.1"]#  0.8361865
    @test MPSGE.Complementarity.result_value(m._jump_model[:B]) ≈ two_by_two_scalar_results["B.L","S.T1,O3=.1"]#  1.16319234
    @test MPSGE.Complementarity.result_value(m._jump_model[:W]) ≈ two_by_two_scalar_results["W.L","S.T1,O3=.1"]#  0.99442372
    @test MPSGE.Complementarity.result_value(m._jump_model[:PX]) ≈ two_by_two_scalar_results["PX.L","S.T1,O3=.1"]#  1.13192563
    @test MPSGE.Complementarity.result_value(m._jump_model[:PY]) ≈ two_by_two_scalar_results["PY.L","S.T1,O3=.1"]#  0.87624589
    @test MPSGE.Complementarity.result_value(m._jump_model[:PW]) ≈ two_by_two_scalar_results["PW.L","S.T1,O3=.1"]#  1
    @test MPSGE.Complementarity.result_value(m._jump_model[:PL]) ≈ two_by_two_scalar_results["PL.L","S.T1,O3=.1"]#  0.92056787
    @test MPSGE.Complementarity.result_value(m._jump_model[:PK]) ≈ two_by_two_scalar_results["PK.L","S.T1,O3=.1"]#  0.88627413
    @test MPSGE.Complementarity.result_value(m._jump_model[:CONS]) ≈ two_by_two_scalar_results["CONS.L","S.T1,O3=.1"]#  198.8847
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX‡A")]) ≈ two_by_two_scalar_results["SAX.L","S.T1,O3=.1"]#  80.51414876
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PY‡A")]) ≈ two_by_two_scalar_results["SAY.L","S.T1,O3=.1"]#  19.47737052
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX‡B")]) ≈ two_by_two_scalar_results["SBX.L","S.T1,O3=.1"]#  22.47527322
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PY‡B")]) ≈ two_by_two_scalar_results["SBY.L","S.T1,O3=.1"]#  77.32689296
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PL†A")]) ≈ two_by_two_scalar_results["DAL.L","S.T1,O3=.1"]#  38.65135847
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PK†A")]) ≈ two_by_two_scalar_results["DAK.L","S.T1,O3=.1"]#  61.37445248
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PL†B")]) ≈ two_by_two_scalar_results["DBL.L","S.T1,O3=.1"]#  58.18492236
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PK†B")]) ≈ two_by_two_scalar_results["DBK.L","S.T1,O3=.1"]#  41.84992453
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PW‡W")]) ≈ two_by_two_scalar_results["SW.L","S.T1,O3=.1"]#  200
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX†W")]) ≈ two_by_two_scalar_results["DWX.L","S.T1,O3=.1"]#  93.99203514
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PY†W")]) ≈ two_by_two_scalar_results["DWY.L","S.T1,O3=.1"]#  106.8285
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PWρCONS")]) ≈ two_by_two_scalar_results["DW.L","S.T1,O3=.1"]#  198.8847
    # CWI ")]) ≈ two_by_two_scalar_results["CWI.L","S.T1,O3=.1"]#  0.99442372

set_value(otax3, 0.)
set_value(otax4, 0.1)
solve!(m)

    @test MPSGE.Complementarity.result_value(m._jump_model[:A]) ≈ two_by_two_scalar_results["A.L","S.T1,O4=.1"]#  0.85040405
    @test MPSGE.Complementarity.result_value(m._jump_model[:B]) ≈ two_by_two_scalar_results["B.L","S.T1,O4=.1"]#  1.14907667
    @test MPSGE.Complementarity.result_value(m._jump_model[:W]) ≈ two_by_two_scalar_results["W.L","S.T1,O4=.1"]#  0.99396862
    @test MPSGE.Complementarity.result_value(m._jump_model[:PX]) ≈ two_by_two_scalar_results["PX.L","S.T1,O4=.1"]#  1.08496248
    @test MPSGE.Complementarity.result_value(m._jump_model[:PY]) ≈ two_by_two_scalar_results["PY.L","S.T1,O4=.1"]#  0.91850119
    @test MPSGE.Complementarity.result_value(m._jump_model[:PW]) ≈ two_by_two_scalar_results["PW.L","S.T1,O4=.1"]#  1
    @test MPSGE.Complementarity.result_value(m._jump_model[:PL]) ≈ two_by_two_scalar_results["PL.L","S.T1,O4=.1"]#  0.89687906
    @test MPSGE.Complementarity.result_value(m._jump_model[:PK]) ≈ two_by_two_scalar_results["PK.L","S.T1,O4=.1"]#  0.86624727
    @test MPSGE.Complementarity.result_value(m._jump_model[:CONS]) ≈ two_by_two_scalar_results["CONS.L","S.T1,O4=.1"]#  198.7937
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX‡A")]) ≈ two_by_two_scalar_results["SAX.L","S.T1,O4=.1"]#  79.05829527
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PY‡A")]) ≈ two_by_two_scalar_results["SAY.L","S.T1,O4=.1"]#  20.91522142
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX‡B")]) ≈ two_by_two_scalar_results["SBX.L","S.T1,O4=.1"]#  24.53639262
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PY‡B")]) ≈ two_by_two_scalar_results["SBY.L","S.T1,O4=.1"]#  74.77875199
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PL†A")]) ≈ two_by_two_scalar_results["DAL.L","S.T1,O4=.1"]#  38.76412959
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PK†A")]) ≈ two_by_two_scalar_results["DAK.L","S.T1,O4=.1"]#  61.25750586
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PL†B")]) ≈ two_by_two_scalar_results["DBL.L","S.T1,O4=.1"]#  58.3379934
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PK†B")]) ≈ two_by_two_scalar_results["DBK.L","S.T1,O4=.1"]#  41.69118576
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PW‡W")]) ≈ two_by_two_scalar_results["SW.L","S.T1,O4=.1"]#  200
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX†W")]) ≈ two_by_two_scalar_results["DWX.L","S.T1,O4=.1"]#  96.0047319
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PY†W")]) ≈ two_by_two_scalar_results["DWY.L","S.T1,O4=.1"]#  104.3422
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PWρCONS")]) ≈ two_by_two_scalar_results["DW.L","S.T1,O4=.1"]#  198.7937
    # CWI ")]) ≈ two_by_two_scalar_results["CWI.L","S.T1,O4=.1"]#  0.99396862


set_value(itax, 0.1)
solve!(m)    
    
    @test MPSGE.Complementarity.result_value(m._jump_model[:A]) ≈ two_by_two_scalar_results["A.L","O4,I=0.1"]#  0.63672356
    @test MPSGE.Complementarity.result_value(m._jump_model[:B]) ≈ two_by_two_scalar_results["B.L","O4,I=0.1"]#  1.36032283
    @test MPSGE.Complementarity.result_value(m._jump_model[:W]) ≈ two_by_two_scalar_results["W.L","O4,I=0.1"]#  0.97648969
    @test MPSGE.Complementarity.result_value(m._jump_model[:PX]) ≈ two_by_two_scalar_results["PX.L","O4,I=0.1"]#  1.18245598
    @test MPSGE.Complementarity.result_value(m._jump_model[:PY]) ≈ two_by_two_scalar_results["PY.L","O4,I=0.1"]#  0.83282431
    @test MPSGE.Complementarity.result_value(m._jump_model[:PW]) ≈ two_by_two_scalar_results["PW.L","O4,I=0.1"]#  1
    @test MPSGE.Complementarity.result_value(m._jump_model[:PL]) ≈ two_by_two_scalar_results["PL.L","O4,I=0.1"]#  0.88286437
    @test MPSGE.Complementarity.result_value(m._jump_model[:PK]) ≈ two_by_two_scalar_results["PK.L","O4,I=0.1"]#  0.81377744
    @test MPSGE.Complementarity.result_value(m._jump_model[:CONS]) ≈ two_by_two_scalar_results["CONS.L","O4,I=0.1"]#  195.2979
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX‡A")]) ≈ two_by_two_scalar_results["SAX.L","O4,I=0.1"]#  81.8622781
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PY‡A")]) ≈ two_by_two_scalar_results["SAY.L","O4,I=0.1"]#  18.01782051
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX‡B")]) ≈ two_by_two_scalar_results["SBX.L","O4,I=0.1"]#  27.69645309
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PY‡B")]) ≈ two_by_two_scalar_results["SBY.L","O4,I=0.1"]#  70.22553628
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PL†A")]) ≈ two_by_two_scalar_results["DAL.L","O4,I=0.1"]#  37.1493891
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PK†A")]) ≈ two_by_two_scalar_results["DAK.L","O4,I=0.1"]#  62.96880528
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PL†B")]) ≈ two_by_two_scalar_results["DBL.L","O4,I=0.1"]#  56.12352231
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PK†B")]) ≈ two_by_two_scalar_results["DBK.L","O4,I=0.1"]#  44.03828026
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PW‡W")]) ≈ two_by_two_scalar_results["SW.L","O4,I=0.1"]#  200
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX†W")]) ≈ two_by_two_scalar_results["DWX.L","O4,I=0.1"]#  91.96180957
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PY†W")]) ≈ two_by_two_scalar_results["DWY.L","O4,I=0.1"]#  109.578
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PWρCONS")]) ≈ two_by_two_scalar_results["DW.L","O4,I=0.1"]#  195.2979
    # CWI ")]) ≈ two_by_two_scalar_results["CWI.L","O4,I=0.1"]#  0.97648969


set_value(otax4, 0.0)
solve!(m)    

    @test MPSGE.Complementarity.result_value(m._jump_model[:A]) ≈ two_by_two_scalar_results["A.L","ITAX=0.1"]#  0.54435839
    @test MPSGE.Complementarity.result_value(m._jump_model[:B]) ≈ two_by_two_scalar_results["B.L","ITAX=0.1"]#  1.45106586
    @test MPSGE.Complementarity.result_value(m._jump_model[:W]) ≈ two_by_two_scalar_results["W.L","ITAX=0.1"]#  0.96551295
    @test MPSGE.Complementarity.result_value(m._jump_model[:PX]) ≈ two_by_two_scalar_results["PX.L","ITAX=0.1"]#  1.25371686
    @test MPSGE.Complementarity.result_value(m._jump_model[:PY]) ≈ two_by_two_scalar_results["PY.L","ITAX=0.1"]#  0.77493692
    @test MPSGE.Complementarity.result_value(m._jump_model[:PW]) ≈ two_by_two_scalar_results["PW.L","ITAX=0.1"]#  1
    @test MPSGE.Complementarity.result_value(m._jump_model[:PL]) ≈ two_by_two_scalar_results["PL.L","ITAX=0.1"]#  0.92927845
    @test MPSGE.Complementarity.result_value(m._jump_model[:PK]) ≈ two_by_two_scalar_results["PK.L","ITAX=0.1"]#  0.84027402
    @test MPSGE.Complementarity.result_value(m._jump_model[:CONS]) ≈ two_by_two_scalar_results["CONS.L","ITAX=0.1"]#  193.1026
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX‡A")]) ≈ two_by_two_scalar_results["SAX.L","ITAX=0.1"]#  83.43323254
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PY‡A")]) ≈ two_by_two_scalar_results["SAY.L","ITAX=0.1"]#  16.11595257
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX‡B")]) ≈ two_by_two_scalar_results["SBX.L","ITAX=0.1"]#  28.12581929
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PY‡B")]) ≈ two_by_two_scalar_results["SBY.L","ITAX=0.1"]#  69.53957979
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PL†A")]) ≈ two_by_two_scalar_results["DAL.L","ITAX=0.1"]#  36.5016685
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PK†A")]) ≈ two_by_two_scalar_results["DAK.L","ITAX=0.1"]#  63.6782873
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PL†B")]) ≈ two_by_two_scalar_results["DBL.L","ITAX=0.1"]#  55.22148407
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PK†B")]) ≈ two_by_two_scalar_results["DBK.L","ITAX=0.1"]#  45.02634343
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PW‡W")]) ≈ two_by_two_scalar_results["SW.L","ITAX=0.1"]#  200
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX†W")]) ≈ two_by_two_scalar_results["DWX.L","ITAX=0.1"]#  89.31003664
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PY†W")]) ≈ two_by_two_scalar_results["DWY.L","ITAX=0.1"]#  113.597
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PWρCONS")]) ≈ two_by_two_scalar_results["DW.L","ITAX=0.1"]#  193.1026
    # CWI ")]) ≈ two_by_two_scalar_results["CWI.L","ITAX=0.1"]#  0.96551295

set_value(otax2, 0.3 )
set_value(itax, 0.2 )
solve!(m)    
    
    @test MPSGE.Complementarity.result_value(m._jump_model[:A]) ≈ two_by_two_scalar_results["A.L","O2=.3,I=.2"]#  0.26298582
    @test MPSGE.Complementarity.result_value(m._jump_model[:B]) ≈ two_by_two_scalar_results["B.L","O2=.3,I=.2"]#  1.72557704
    @test MPSGE.Complementarity.result_value(m._jump_model[:W]) ≈ two_by_two_scalar_results["W.L","O2=.3,I=.2"]#  0.91527149
    @test MPSGE.Complementarity.result_value(m._jump_model[:PX]) ≈ two_by_two_scalar_results["PX.L","O2=.3,I=.2"]#  1.37998382
    @test MPSGE.Complementarity.result_value(m._jump_model[:PY]) ≈ two_by_two_scalar_results["PY.L","O2=.3,I=.2"]#  0.68107531
    @test MPSGE.Complementarity.result_value(m._jump_model[:PW]) ≈ two_by_two_scalar_results["PW.L","O2=.3,I=.2"]#  1
    @test MPSGE.Complementarity.result_value(m._jump_model[:PL]) ≈ two_by_two_scalar_results["PL.L","O2=.3,I=.2"]#  0.92558632
    @test MPSGE.Complementarity.result_value(m._jump_model[:PK]) ≈ two_by_two_scalar_results["PK.L","O2=.3,I=.2"]#  0.79214911
    @test MPSGE.Complementarity.result_value(m._jump_model[:CONS]) ≈ two_by_two_scalar_results["CONS.L","O2=.3,I=.2"]#  183.0543
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX‡A")]) ≈ two_by_two_scalar_results["SAX.L","O2=.3,I=.2"]#  87.42786978
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PY‡A")]) ≈ two_by_two_scalar_results["SAY.L","O2=.3,I=.2"]#  9.43885039
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX‡B")]) ≈ two_by_two_scalar_results["SBX.L","O2=.3,I=.2"]#  31.82775909
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PY‡B")]) ≈ two_by_two_scalar_results["SBY.L","O2=.3,I=.2"]#  62.83291339
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PL†A")]) ≈ two_by_two_scalar_results["DAL.L","O2=.3,I=.2"]#  34.6951557
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PK†A")]) ≈ two_by_two_scalar_results["DAK.L","O2=.3,I=.2"]#  65.73173321
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PL†B")]) ≈ two_by_two_scalar_results["DBL.L","O2=.3,I=.2"]#  52.66392871
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PK†B")]) ≈ two_by_two_scalar_results["DBK.L","O2=.3,I=.2"]#  47.93381262
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PW‡W")]) ≈ two_by_two_scalar_results["SW.L","O2=.3,I=.2"]#  200
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX†W")]) ≈ two_by_two_scalar_results["DWX.L","O2=.3,I=.2"]#  85.12615199
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PY†W")]) ≈ two_by_two_scalar_results["DWY.L","O2=.3,I=.2"]#  121.172
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PWρCONS")]) ≈ two_by_two_scalar_results["DW.L","O2=.3,I=.2"]#  183.0543
    # CWI ")]) ≈ two_by_two_scalar_results["CWI.L","O2=.3,I=.2"]#  0.91527149
    
    set_value(itax, 1.0)
    solve!(m)

    @test MPSGE.Complementarity.result_value(m._jump_model[:A]) ≈ 0 #two_by_two_scalar_results["A.L","ITAX=100%"]#  NULL
    @test MPSGE.Complementarity.result_value(m._jump_model[:B]) ≈ two_by_two_scalar_results["B.L","ITAX=100%"]#  1.9797959
    @test MPSGE.Complementarity.result_value(m._jump_model[:W]) ≈ two_by_two_scalar_results["W.L","ITAX=100%"]#  0.85094166
    @test MPSGE.Complementarity.result_value(m._jump_model[:PX]) ≈ two_by_two_scalar_results["PX.L","ITAX=100%"]#  1.50558687
    @test MPSGE.Complementarity.result_value(m._jump_model[:PY]) ≈ two_by_two_scalar_results["PY.L","ITAX=100%"]#  0.59749254
    @test MPSGE.Complementarity.result_value(m._jump_model[:PW]) ≈ two_by_two_scalar_results["PW.L","ITAX=100%"]#  1
    @test MPSGE.Complementarity.result_value(m._jump_model[:PL]) ≈ two_by_two_scalar_results["PL.L","ITAX=100%"]#  0.93690422
    @test MPSGE.Complementarity.result_value(m._jump_model[:PK]) ≈ two_by_two_scalar_results["PK.L","ITAX=100%"]#  0.76497909
    @test MPSGE.Complementarity.result_value(m._jump_model[:CONS]) ≈ two_by_two_scalar_results["CONS.L","ITAX=100%"]#  170.1883
    # @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX‡A")]) ≈ 0 # two_by_two_scalar_results["SAX.L","ITAX=100%"]# UNDF in GAMS, but has a value in Julia
    # @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PY‡A")]) ≈ 0 # two_by_two_scalar_results["SAY.L","ITAX=100%"]# UNDF in GAMS, but has a value in Julia
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX‡B")]) ≈ two_by_two_scalar_results["SBX.L","ITAX=100%"]#  35.0288964
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PY‡B")]) ≈ two_by_two_scalar_results["SBY.L","ITAX=100%"]#  55.60490686
    # @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PL†A")]) ≈ 0 # two_by_two_scalar_results["DAL.L","ITAX=100%"]# UNDF in GAMS, but has a value in Julia
    # @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PK†A")]) ≈ 0 # two_by_two_scalar_results["DAK.L","ITAX=100%"]#  UNDF in GAMS, but has a value in Julia
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PL†B")]) ≈ two_by_two_scalar_results["DBL.L","ITAX=100%"]#  50.51025716
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PK†B")]) ≈ two_by_two_scalar_results["DBK.L","ITAX=100%"]#  50.51025729
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PW‡W")]) ≈ two_by_two_scalar_results["SW.L","ITAX=100%"]#  200
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX†W")]) ≈ two_by_two_scalar_results["DWX.L","ITAX=100%"]#  81.49802621
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PY†W")]) ≈ two_by_two_scalar_results["DWY.L","ITAX=100%"]#  129.3701
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PWρCONS")]) ≈ two_by_two_scalar_results["DW.L","ITAX=100%"]#  170.1883
    # CWI ")]) ≈ two_by_two_scalar_results["CWI.L","ITAX=100%"]#  0.85094165
    end