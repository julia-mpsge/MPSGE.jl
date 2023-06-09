@testitem "TWOBYTWO (functional version , with non-1 prices in Inputs)" begin
    using XLSX, MPSGE.JuMP.Containers

gams_results = XLSX.readxlsx(joinpath(@__DIR__, "MPSGEresults.xlsx"))
a_table = gams_results["two_by_two_PriceinIntput"][:]  # Generated with TwoByTwo_wPriceE.gms
two_by_two_PriceinInput = DenseAxisArray(a_table[2:end,2:end],a_table[2:end,1],a_table[1,2:end])

using MPSGE

m = Model()
# Here parameter values are doubled and input data halved from MPSGE version       
endow  = add!(m, Parameter(:endow, value=1.))
esub_x = add!(m, Parameter(:esub_x, value=1.))
esub_y=add!(m, Parameter(:esub_y, value=1.))
esub_u=add!(m, Parameter(:esub_u, value=1.))
otax=add!(m, Parameter(:otax, value=0.))
itax=add!(m, Parameter(:itax, value=0.2))

X = add!(m, Sector(:X))
Y = add!(m, Sector(:Y))
U = add!(m, Sector(:U))

PX = add!(m, Commodity(:PX))
PY = add!(m, Commodity(:PY))
PU = add!(m, Commodity(:PU))
PL = add!(m, Commodity(:PL))
PK = add!(m, Commodity(:PK))

RA = add!(m, Consumer(:RA, benchmark=164.))

add!(m, Production(X, 0, :(1.0 * $esub_x), [Output(PX, 110, [Tax(:($otax*1.),RA)])], [Input(PL, 50, [Tax(:($itax*1.),RA)], 1.2), Input(PK, 50)]))
add!(m, Production(Y, 0, :(1.0 * $esub_y), [Output(PY, 54)], [Input(PL, 24,), Input(PK, 30)]))
add!(m, Production(U, 0, :(1.0 * $esub_u), [Output(PU, 164.)], [Input(PX, 110), Input(PY, 54)]))

add!(m, DemandFunction(RA, 1., [Demand(PU,164.)], [Endowment(PL, :(74. *$endow)), Endowment(PK, 80)]))

set_fixed!(PU,true)
solve!(m, cumulative_iteration_limit=0)


# benchmark
@test MPSGE.Complementarity.result_value(m._jump_model[:X]) ≈ two_by_two_PriceinInput["X","benchmark"]#  1
@test MPSGE.Complementarity.result_value(m._jump_model[:Y]) ≈ two_by_two_PriceinInput["Y","benchmark"]#  1
@test MPSGE.Complementarity.result_value(m._jump_model[:U]) ≈ two_by_two_PriceinInput["U","benchmark"]#  1
@test MPSGE.Complementarity.result_value(m._jump_model[:PX]) ≈ two_by_two_PriceinInput["PX","benchmark"]#  1
@test MPSGE.Complementarity.result_value(m._jump_model[:PY]) ≈ two_by_two_PriceinInput["PY","benchmark"]#  1
@test MPSGE.Complementarity.result_value(m._jump_model[:PU]) ≈ two_by_two_PriceinInput["PU","benchmark"]#  1
@test MPSGE.Complementarity.result_value(m._jump_model[:PL]) ≈ two_by_two_PriceinInput["PL","benchmark"]#  1
@test MPSGE.Complementarity.result_value(m._jump_model[:PK]) ≈ two_by_two_PriceinInput["PK","benchmark"]#  1
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX‡X")]) ≈ two_by_two_PriceinInput["SX","benchmark"]#  110
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PY‡Y")]) ≈ two_by_two_PriceinInput["SY","benchmark"]#  54
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PU‡U")]) ≈ two_by_two_PriceinInput["SU","benchmark"]#  164
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PL†X")]) ≈ two_by_two_PriceinInput["DXL","benchmark"]#  50
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PK†X")]) ≈ two_by_two_PriceinInput["DXK","benchmark"]#  50
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PL†Y")]) ≈ two_by_two_PriceinInput["DYL","benchmark"]#  24
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PK†Y")]) ≈ two_by_two_PriceinInput["DYK","benchmark"]#  30
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX†U")]) ≈ two_by_two_PriceinInput["DUX","benchmark"]#  110
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PY†U")]) ≈ two_by_two_PriceinInput["DUY","benchmark"]#  54
@test MPSGE.Complementarity.result_value(m._jump_model[:RA]) ≈ two_by_two_PriceinInput["RA","benchmark"]#  164
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PUρRA")]) ≈ two_by_two_PriceinInput["DU","benchmark"]#  164
# @test MPSGE.Complementarity.result_value(m._jump_model[:]) ≈ two_by_two_PriceinInput["CWI","benchmark"]#  1.09333333

set_value(endow,1.1)
solve!(m)

# RA=157
@test MPSGE.Complementarity.result_value(m._jump_model[:X]) ≈ two_by_two_PriceinInput["X","RA=157"]#  1.05336244
@test MPSGE.Complementarity.result_value(m._jump_model[:Y]) ≈ two_by_two_PriceinInput["Y","RA=157"]#  1.04327007
@test MPSGE.Complementarity.result_value(m._jump_model[:U]) ≈ two_by_two_PriceinInput["U","RA=157"]#  1.05002861
@test MPSGE.Complementarity.result_value(m._jump_model[:PX]) ≈ two_by_two_PriceinInput["PX","RA=157"]#  0.99683506
@test MPSGE.Complementarity.result_value(m._jump_model[:PY]) ≈ two_by_two_PriceinInput["PY","RA=157"]#  1.00647822
@test MPSGE.Complementarity.result_value(m._jump_model[:PU]) ≈ two_by_two_PriceinInput["PU","RA=157"]#  1
@test MPSGE.Complementarity.result_value(m._jump_model[:PL]) ≈ two_by_two_PriceinInput["PL","RA=157"]#  0.95457146
@test MPSGE.Complementarity.result_value(m._jump_model[:PK]) ≈ two_by_two_PriceinInput["PK","RA=157"]#  1.05002861
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX‡X")]) ≈ two_by_two_PriceinInput["SX","RA=157"]#  110
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PY‡Y")]) ≈ two_by_two_PriceinInput["SY","RA=157"]#  54
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PU‡U")]) ≈ two_by_two_PriceinInput["SU","RA=157"]#  164
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PL†X")]) ≈ two_by_two_PriceinInput["DXL","RA=157"]#  52.21374709
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PK†X")]) ≈ two_by_two_PriceinInput["DXK","RA=157"]#  47.46704281
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PL†Y")]) ≈ two_by_two_PriceinInput["DYL","RA=157"]#  25.30504873
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PK†Y")]) ≈ two_by_two_PriceinInput["DYK","RA=157"]#  28.75573719
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX†U")]) ≈ two_by_two_PriceinInput["DUX","RA=157"]#  110.3492
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PY†U")]) ≈ two_by_two_PriceinInput["DUY","RA=157"]#  53.65242762
@test MPSGE.Complementarity.result_value(m._jump_model[:RA]) ≈ two_by_two_PriceinInput["RA","RA=157"]#  172.2047
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PUρRA")]) ≈ two_by_two_PriceinInput["DU","RA=157"]#  172.2047
# @test MPSGE.Complementarity.result_value(m._jump_model[:]) ≈ two_by_two_PriceinInput["CWI","RA=157"]#  1.14803128

set_fixed!(PU,false)
set_fixed!(PX,true)
# # set_value(RA,172.2046917)
# # set_fixed!(RA, true)
solve!(m)

# PX=1
@test MPSGE.Complementarity.result_value(m._jump_model[:X]) ≈ two_by_two_PriceinInput["X","PX=1"]#  1.05336244
@test MPSGE.Complementarity.result_value(m._jump_model[:Y]) ≈ two_by_two_PriceinInput["Y","PX=1"]#  1.04327007
@test MPSGE.Complementarity.result_value(m._jump_model[:U]) ≈ two_by_two_PriceinInput["U","PX=1"]#  1.05002861
@test MPSGE.Complementarity.result_value(m._jump_model[:PX]) ≈ two_by_two_PriceinInput["PX","PX=1"]#  1
@test MPSGE.Complementarity.result_value(m._jump_model[:PY]) ≈ two_by_two_PriceinInput["PY","PX=1"]#  1.00967378
@test MPSGE.Complementarity.result_value(m._jump_model[:PU]) ≈ two_by_two_PriceinInput["PU","PX=1"]#  1.00317499
@test MPSGE.Complementarity.result_value(m._jump_model[:PL]) ≈ two_by_two_PriceinInput["PL","PX=1"]#  0.95760222
@test MPSGE.Complementarity.result_value(m._jump_model[:PK]) ≈ two_by_two_PriceinInput["PK","PX=1"]#  1.05336244
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX‡X")]) ≈ two_by_two_PriceinInput["SX","PX=1"]#  110
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PY‡Y")]) ≈ two_by_two_PriceinInput["SY","PX=1"]#  54
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PU‡U")]) ≈ two_by_two_PriceinInput["SU","PX=1"]#  164
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PL†X")]) ≈ two_by_two_PriceinInput["DXL","PX=1"]#  52.21374709
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PK†X")]) ≈ two_by_two_PriceinInput["DXK","PX=1"]#  47.46704281
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PL†Y")]) ≈ two_by_two_PriceinInput["DYL","PX=1"]#  25.30504873
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PK†Y")]) ≈ two_by_two_PriceinInput["DYK","PX=1"]#  28.75573719
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX†U")]) ≈ two_by_two_PriceinInput["DUX","PX=1"]#  110.3492
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PY†U")]) ≈ two_by_two_PriceinInput["DUY","PX=1"]#  53.65242762
@test MPSGE.Complementarity.result_value(m._jump_model[:RA]) ≈ two_by_two_PriceinInput["RA","PX=1"]#  172.7514
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PUρRA")]) ≈ two_by_two_PriceinInput["DU","PX=1"]#  172.2047
# @test MPSGE.Complementarity.result_value(m._jump_model[:]) ≈ two_by_two_PriceinInput["CWI","PX=1"]#  1.14803128

set_value(PL, 1.0)
set_fixed!(PX,false)
set_fixed!(PL,true)
solve!(m)
# PL=1
@test MPSGE.Complementarity.result_value(m._jump_model[:X]) ≈ two_by_two_PriceinInput["X","PL=1"]#  1.05336244
@test MPSGE.Complementarity.result_value(m._jump_model[:Y]) ≈ two_by_two_PriceinInput["Y","PL=1"]#  1.04327007
@test MPSGE.Complementarity.result_value(m._jump_model[:U]) ≈ two_by_two_PriceinInput["U","PL=1"]#  1.05002861
@test MPSGE.Complementarity.result_value(m._jump_model[:PX]) ≈ two_by_two_PriceinInput["PX","PL=1"]#  1.04427494
@test MPSGE.Complementarity.result_value(m._jump_model[:PY]) ≈ two_by_two_PriceinInput["PY","PL=1"]#  1.05437703
@test MPSGE.Complementarity.result_value(m._jump_model[:PU]) ≈ two_by_two_PriceinInput["PU","PL=1"]#  1.04759051
@test MPSGE.Complementarity.result_value(m._jump_model[:PL]) ≈ two_by_two_PriceinInput["PL","PL=1"]#  1
@test MPSGE.Complementarity.result_value(m._jump_model[:PK]) ≈ two_by_two_PriceinInput["PK","PL=1"]#  1.1
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX‡X")]) ≈ two_by_two_PriceinInput["SX","PL=1"]#  110
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PY‡Y")]) ≈ two_by_two_PriceinInput["SY","PL=1"]#  54
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PU‡U")]) ≈ two_by_two_PriceinInput["SU","PL=1"]#  164
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PL†X")]) ≈ two_by_two_PriceinInput["DXL","PL=1"]#  52.21374709
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PK†X")]) ≈ two_by_two_PriceinInput["DXK","PL=1"]#  47.46704281
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PL†Y")]) ≈ two_by_two_PriceinInput["DYL","PL=1"]#  25.30504873
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PK†Y")]) ≈ two_by_two_PriceinInput["DYK","PL=1"]#  28.75573719
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX†U")]) ≈ two_by_two_PriceinInput["DUX","PL=1"]#  110.3492
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PY†U")]) ≈ two_by_two_PriceinInput["DUY","PL=1"]#  53.65242762
@test MPSGE.Complementarity.result_value(m._jump_model[:RA]) ≈ two_by_two_PriceinInput["RA","PL=1"]#  180.4
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PUρRA")]) ≈ two_by_two_PriceinInput["DU","PL=1"]#  172.2047
# @test MPSGE.Complementarity.result_value(m._jump_model[:]) ≈ two_by_two_PriceinInput["CWI","PL=1"]#  1.14803128

set_value(itax, 0.1)
solve!(m)
# Itax=0.1
@test MPSGE.Complementarity.result_value(m._jump_model[:X]) ≈ two_by_two_PriceinInput["X","Itax=0.1"]#  1.06922305
@test MPSGE.Complementarity.result_value(m._jump_model[:Y]) ≈ two_by_two_PriceinInput["Y","Itax=0.1"]#  1.01599221
@test MPSGE.Complementarity.result_value(m._jump_model[:U]) ≈ two_by_two_PriceinInput["U","Itax=0.1"]#  1.05139479
@test MPSGE.Complementarity.result_value(m._jump_model[:PX]) ≈ two_by_two_PriceinInput["PX","Itax=0.1"]#  0.96924827
@test MPSGE.Complementarity.result_value(m._jump_model[:PY]) ≈ two_by_two_PriceinInput["PY","Itax=0.1"]#  1.02003006
@test MPSGE.Complementarity.result_value(m._jump_model[:PU]) ≈ two_by_two_PriceinInput["PU","Itax=0.1"]#  0.98568359
@test MPSGE.Complementarity.result_value(m._jump_model[:PL]) ≈ two_by_two_PriceinInput["PL","Itax=0.1"]#  1
@test MPSGE.Complementarity.result_value(m._jump_model[:PK]) ≈ two_by_two_PriceinInput["PK","Itax=0.1"]#  1.03634259
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX‡X")]) ≈ two_by_two_PriceinInput["SX","Itax=0.1"]#  110
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PY‡Y")]) ≈ two_by_two_PriceinInput["SY","Itax=0.1"]#  54
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PU‡U")]) ≈ two_by_two_PriceinInput["SU","Itax=0.1"]#  164
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PL†X")]) ≈ two_by_two_PriceinInput["DXL","Itax=0.1"]#  52.86808734
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PK†X")]) ≈ two_by_two_PriceinInput["DXK","Itax=0.1"]#  46.76292745
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PL†Y")]) ≈ two_by_two_PriceinInput["DYL","Itax=0.1"]#  24.48072144
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PK†Y")]) ≈ two_by_two_PriceinInput["DYK","Itax=0.1"]#  29.52778557
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX†U")]) ≈ two_by_two_PriceinInput["DUX","Itax=0.1"]#  111.8652
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PY†U")]) ≈ two_by_two_PriceinInput["DUY","Itax=0.1"]#  52.18171089
@test MPSGE.Complementarity.result_value(m._jump_model[:RA]) ≈ two_by_two_PriceinInput["RA","Itax=0.1"]#  169.9602
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PUρRA")]) ≈ two_by_two_PriceinInput["DU","Itax=0.1"]#  172.4287 
# @test MPSGE.Complementarity.result_value(m._jump_model[:]) ≈ two_by_two_PriceinInput["CWI","Itax=0.1"]#  1.14952497

set_value(otax, 0.1)
solve!(m)
# Otax=0.1
@test MPSGE.Complementarity.result_value(m._jump_model[:X]) ≈ two_by_two_PriceinInput["X","Otax=0.1"]#  1.03062531
@test MPSGE.Complementarity.result_value(m._jump_model[:Y]) ≈ two_by_two_PriceinInput["Y","Otax=0.1"]#  1.08731204
@test MPSGE.Complementarity.result_value(m._jump_model[:U]) ≈ two_by_two_PriceinInput["U","Otax=0.1"]#  1.04895633
@test MPSGE.Complementarity.result_value(m._jump_model[:PX]) ≈ two_by_two_PriceinInput["PX","Otax=0.1"]#  1.08058824
@test MPSGE.Complementarity.result_value(m._jump_model[:PY]) ≈ two_by_two_PriceinInput["PY","Otax=0.1"]#  1.02425205
@test MPSGE.Complementarity.result_value(m._jump_model[:PU]) ≈ two_by_two_PriceinInput["PU","Otax=0.1"]#  1.06170443
@test MPSGE.Complementarity.result_value(m._jump_model[:PL]) ≈ two_by_two_PriceinInput["PL","Otax=0.1"]#  1
@test MPSGE.Complementarity.result_value(m._jump_model[:PK]) ≈ two_by_two_PriceinInput["PK","Otax=0.1"]#  1.04407648
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX‡X")]) ≈ two_by_two_PriceinInput["SX","Otax=0.1"]#  110
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PY‡Y")]) ≈ two_by_two_PriceinInput["SY","Otax=0.1"]#  54
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PU‡U")]) ≈ two_by_two_PriceinInput["SU","Otax=0.1"]#  164
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PL†X")]) ≈ two_by_two_PriceinInput["DXL","Otax=0.1"]#  53.04705903
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PK†X")]) ≈ two_by_two_PriceinInput["DXK","Otax=0.1"]#  46.57366725
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PL†Y")]) ≈ two_by_two_PriceinInput["DYL","Otax=0.1"]#  24.58204917
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PK†Y")]) ≈ two_by_two_PriceinInput["DYK","Otax=0.1"]#  29.43037404
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX†U")]) ≈ two_by_two_PriceinInput["DUX","Otax=0.1"]#  108.0777
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PY†U")]) ≈ two_by_two_PriceinInput["DUY","Otax=0.1"]#  55.97454208
@test MPSGE.Complementarity.result_value(m._jump_model[:RA]) ≈ two_by_two_PriceinInput["RA","Otax=0.1"]#  182.6438
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PUρRA")]) ≈ two_by_two_PriceinInput["DU","Otax=0.1"]#  172.0288
# @test MPSGE.Complementarity.result_value(m._jump_model[:]) ≈ two_by_two_PriceinInput["CWI","Otax=0.1"]#  1.14685892

end

@testitem "TWOBYTWO (functional version , with non-1 prices in Ouput)" begin
    using XLSX, MPSGE.JuMP.Containers

gams_results = XLSX.readxlsx(joinpath(@__DIR__, "MPSGEresults.xlsx"))
a_table = gams_results["two_by_two_PriceinOutput"][:]  # Generated with TwoByTwo_wPriceeOutputs.gms
two_by_two_PriceinOutput = DenseAxisArray(a_table[2:end,2:end],a_table[2:end,1],a_table[1,2:end])

m = Model()
# Here parameter values are doubled and input data halved from MPSGE version       
endow  = add!(m, Parameter(:endow, value=1.))
esub_x = add!(m, Parameter(:esub_x, value=1.))
esub_y=add!(m, Parameter(:esub_y, value=1.))
esub_u=add!(m, Parameter(:esub_u, value=1.))
otax=add!(m, Parameter(:otax, value=0.2))
itax=add!(m, Parameter(:itax, value=0.))

X = add!(m, Sector(:X))
Y = add!(m, Sector(:Y))
U = add!(m, Sector(:U))

PX = add!(m, Commodity(:PX))
PY = add!(m, Commodity(:PY))
PU = add!(m, Commodity(:PU))
PL = add!(m, Commodity(:PL))
PK = add!(m, Commodity(:PK))

RA = add!(m, Consumer(:RA, benchmark=154.))

add!(m, Production(X, 0, :(1.0 * $esub_x), [Output(PX, 100, [Tax(:($otax*1.),RA)], 1.2)], [Input(PL, 30, [Tax(:($itax*1.),RA)]), Input(PK, 50)]))
add!(m, Production(Y, 0, :(1.0 * $esub_y), [Output(PY, 54)], [Input(PL, 24,), Input(PK, 30)]))
add!(m, Production(U, 0, :(1.0 * $esub_u), [Output(PU, 154.)], [Input(PX, 100), Input(PY, 54)]))

add!(m, DemandFunction(RA, 1., [Demand(PU,154.)], [Endowment(PL, :(54. *$endow)), Endowment(PK, 80)]))

set_fixed!(PU,true)
solve!(m, cumulative_iteration_limit=0)

# benchmark
@test MPSGE.Complementarity.result_value(m._jump_model[:X]) ≈ two_by_two_PriceinOutput["X","benchmark"]#  1
@test MPSGE.Complementarity.result_value(m._jump_model[:Y]) ≈ two_by_two_PriceinOutput["Y","benchmark"]#  1
@test MPSGE.Complementarity.result_value(m._jump_model[:U]) ≈ two_by_two_PriceinOutput["U","benchmark"]#  1
@test MPSGE.Complementarity.result_value(m._jump_model[:PX]) ≈ two_by_two_PriceinOutput["PX","benchmark"]#  1
@test MPSGE.Complementarity.result_value(m._jump_model[:PY]) ≈ two_by_two_PriceinOutput["PY","benchmark"]#  1
@test MPSGE.Complementarity.result_value(m._jump_model[:PU]) ≈ two_by_two_PriceinOutput["PU","benchmark"]#  1
@test MPSGE.Complementarity.result_value(m._jump_model[:PL]) ≈ two_by_two_PriceinOutput["PL","benchmark"]#  1
@test MPSGE.Complementarity.result_value(m._jump_model[:PK]) ≈ two_by_two_PriceinOutput["PK","benchmark"]#  1
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX‡X")]) ≈ two_by_two_PriceinOutput["SX","benchmark"]#  100
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PY‡Y")]) ≈ two_by_two_PriceinOutput["SY","benchmark"]#  54
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PU‡U")]) ≈ two_by_two_PriceinOutput["SU","benchmark"]#  154
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PL†X")]) ≈ two_by_two_PriceinOutput["DXL","benchmark"]#  30
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PK†X")]) ≈ two_by_two_PriceinOutput["DXK","benchmark"]#  50
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PL†Y")]) ≈ two_by_two_PriceinOutput["DYL","benchmark"]#  24
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PK†Y")]) ≈ two_by_two_PriceinOutput["DYK","benchmark"]#  30
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX†U")]) ≈ two_by_two_PriceinOutput["DUX","benchmark"]#  100
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PY†U")]) ≈ two_by_two_PriceinOutput["DUY","benchmark"]#  54
@test MPSGE.Complementarity.result_value(m._jump_model[:RA]) ≈ two_by_two_PriceinOutput["RA","benchmark"]#  154
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PUρRA")]) ≈ two_by_two_PriceinOutput["DU","benchmark"]#  154
# @test MPSGE.Complementarity.result_value(m._jump_model[:]) ≈ two_by_two_PriceinOutput["CWI","benchmark"]#  1.0266667

set_value(endow,1.1)
solve!(m)

# RA=157
@test MPSGE.Complementarity.result_value(m._jump_model[:X]) ≈ two_by_two_PriceinOutput["X","RA=157"]#  1.0363877
@test MPSGE.Complementarity.result_value(m._jump_model[:Y]) ≈ two_by_two_PriceinOutput["Y","RA=157"]#  1.0432701
@test MPSGE.Complementarity.result_value(m._jump_model[:U]) ≈ two_by_two_PriceinOutput["U","RA=157"]#  1.0387958
@test MPSGE.Complementarity.result_value(m._jump_model[:PX]) ≈ two_by_two_PriceinOutput["PX","RA=157"]#  1.0023236
@test MPSGE.Complementarity.result_value(m._jump_model[:PY]) ≈ two_by_two_PriceinOutput["PY","RA=157"]#  0.9957113
@test MPSGE.Complementarity.result_value(m._jump_model[:PU]) ≈ two_by_two_PriceinOutput["PU","RA=157"]#  1
@test MPSGE.Complementarity.result_value(m._jump_model[:PL]) ≈ two_by_two_PriceinOutput["PL","RA=157"]#  0.9443598
@test MPSGE.Complementarity.result_value(m._jump_model[:PK]) ≈ two_by_two_PriceinOutput["PK","RA=157"]#  1.0387958
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX‡X")]) ≈ two_by_two_PriceinOutput["SX","RA=157"]#  100
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PY‡Y")]) ≈ two_by_two_PriceinOutput["SY","RA=157"]#  54
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PU‡U")]) ≈ two_by_two_PriceinOutput["SU","RA=157"]#  154
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PL†X")]) ≈ two_by_two_PriceinOutput["DXL","RA=157"]#  31.8413654
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PK†X")]) ≈ two_by_two_PriceinOutput["DXK","RA=157"]#  48.2444931
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PL†Y")]) ≈ two_by_two_PriceinOutput["DYL","RA=157"]#  25.3050487
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PK†Y")]) ≈ two_by_two_PriceinOutput["DYK","RA=157"]#  28.7557372
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX†U")]) ≈ two_by_two_PriceinOutput["DUX","RA=157"]#  99.7681826
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PY†U")]) ≈ two_by_two_PriceinOutput["DUY","RA=157"]#  54.2325859
@test MPSGE.Complementarity.result_value(m._jump_model[:RA]) ≈ two_by_two_PriceinOutput["RA","RA=157"]#  159.9745571
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PUρRA")]) ≈ two_by_two_PriceinOutput["DU","RA=157"]#  159.9745571
# @test MPSGE.Complementarity.result_value(m._jump_model[:]) ≈ two_by_two_PriceinOutput["CWI","RA=157"]#  1.066497

set_fixed!(PU,false)
set_fixed!(PX,true)
solve!(m)

# PX=1
@test MPSGE.Complementarity.result_value(m._jump_model[:X]) ≈ two_by_two_PriceinOutput["X","PX=1"]#  1.0363877
@test MPSGE.Complementarity.result_value(m._jump_model[:Y]) ≈ two_by_two_PriceinOutput["Y","PX=1"]#  1.0432701
@test MPSGE.Complementarity.result_value(m._jump_model[:U]) ≈ two_by_two_PriceinOutput["U","PX=1"]#  1.0387958
@test MPSGE.Complementarity.result_value(m._jump_model[:PX]) ≈ two_by_two_PriceinOutput["PX","PX=1"]#  1
@test MPSGE.Complementarity.result_value(m._jump_model[:PY]) ≈ two_by_two_PriceinOutput["PY","PX=1"]#  0.9934031
@test MPSGE.Complementarity.result_value(m._jump_model[:PU]) ≈ two_by_two_PriceinOutput["PU","PX=1"]#  0.9976818
@test MPSGE.Complementarity.result_value(m._jump_model[:PL]) ≈ two_by_two_PriceinOutput["PL","PX=1"]#  0.9421707
@test MPSGE.Complementarity.result_value(m._jump_model[:PK]) ≈ two_by_two_PriceinOutput["PK","PX=1"]#  1.0363877
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX‡X")]) ≈ two_by_two_PriceinOutput["SX","PX=1"]#  100
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PY‡Y")]) ≈ two_by_two_PriceinOutput["SY","PX=1"]#  54
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PU‡U")]) ≈ two_by_two_PriceinOutput["SU","PX=1"]#  154
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PL†X")]) ≈ two_by_two_PriceinOutput["DXL","PX=1"]#  31.8413654
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PK†X")]) ≈ two_by_two_PriceinOutput["DXK","PX=1"]#  48.2444931
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PL†Y")]) ≈ two_by_two_PriceinOutput["DYL","PX=1"]#  25.3050487
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PK†Y")]) ≈ two_by_two_PriceinOutput["DYK","PX=1"]#  28.7557372
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX†U")]) ≈ two_by_two_PriceinOutput["DUX","PX=1"]#  99.7681826
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PY†U")]) ≈ two_by_two_PriceinOutput["DUY","PX=1"]#  54.2325859
@test MPSGE.Complementarity.result_value(m._jump_model[:RA]) ≈ two_by_two_PriceinOutput["RA","PX=1"]#  159.6037083
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PUρRA")]) ≈ two_by_two_PriceinOutput["DU","PX=1"]#  159.9745571
# @test MPSGE.Complementarity.result_value(m._jump_model[:]) ≈ two_by_two_PriceinOutput["CWI","PX=1"]#  1.066497

set_value(PL, 1.0)
set_fixed!(PX,false)
set_fixed!(PL,true)
solve!(m)
# PL=1
@test MPSGE.Complementarity.result_value(m._jump_model[:X]) ≈ two_by_two_PriceinOutput["X","PL=1"]#  1.0363877
@test MPSGE.Complementarity.result_value(m._jump_model[:Y]) ≈ two_by_two_PriceinOutput["Y","PL=1"]#  1.0432701
@test MPSGE.Complementarity.result_value(m._jump_model[:U]) ≈ two_by_two_PriceinOutput["U","PL=1"]#  1.0387958
@test MPSGE.Complementarity.result_value(m._jump_model[:PX]) ≈ two_by_two_PriceinOutput["PX","PL=1"]#  1.0613788
@test MPSGE.Complementarity.result_value(m._jump_model[:PY]) ≈ two_by_two_PriceinOutput["PY","PL=1"]#  1.054377
@test MPSGE.Complementarity.result_value(m._jump_model[:PU]) ≈ two_by_two_PriceinOutput["PU","PL=1"]#  1.0589184
@test MPSGE.Complementarity.result_value(m._jump_model[:PL]) ≈ two_by_two_PriceinOutput["PL","PL=1"]#  1
@test MPSGE.Complementarity.result_value(m._jump_model[:PK]) ≈ two_by_two_PriceinOutput["PK","PL=1"]#  1.1
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX‡X")]) ≈ two_by_two_PriceinOutput["SX","PL=1"]#  100
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PY‡Y")]) ≈ two_by_two_PriceinOutput["SY","PL=1"]#  54
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PU‡U")]) ≈ two_by_two_PriceinOutput["SU","PL=1"]#  154
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PL†X")]) ≈ two_by_two_PriceinOutput["DXL","PL=1"]#  31.8413654
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PK†X")]) ≈ two_by_two_PriceinOutput["DXK","PL=1"]#  48.2444931
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PL†Y")]) ≈ two_by_two_PriceinOutput["DYL","PL=1"]#  25.3050487
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PK†Y")]) ≈ two_by_two_PriceinOutput["DYK","PL=1"]#  28.7557372
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX†U")]) ≈ two_by_two_PriceinOutput["DUX","PL=1"]#  99.7681826
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PY†U")]) ≈ two_by_two_PriceinOutput["DUY","PL=1"]#  54.2325859
@test MPSGE.Complementarity.result_value(m._jump_model[:RA]) ≈ two_by_two_PriceinOutput["RA","PL=1"]#  169.3999999
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PUρRA")]) ≈ two_by_two_PriceinOutput["DU","PL=1"]#  159.9745571
# @test MPSGE.Complementarity.result_value(m._jump_model[:]) ≈ two_by_two_PriceinOutput["CWI","PL=1"]#  1.066497

set_value(itax, 0.1)
solve!(m)
# Itax=0.1
@test MPSGE.Complementarity.result_value(m._jump_model[:X]) ≈ two_by_two_PriceinOutput["X","Itax=0.1"]#  1.0196245
@test MPSGE.Complementarity.result_value(m._jump_model[:Y]) ≈ two_by_two_PriceinOutput["Y","Itax=0.1"]#  1.067579
@test MPSGE.Complementarity.result_value(m._jump_model[:U]) ≈ two_by_two_PriceinOutput["U","Itax=0.1"]#  1.0361894
@test MPSGE.Complementarity.result_value(m._jump_model[:PX]) ≈ two_by_two_PriceinOutput["PX","Itax=0.1"]#  1.1362131
@test MPSGE.Complementarity.result_value(m._jump_model[:PY]) ≈ two_by_two_PriceinOutput["PY","Itax=0.1"]#  1.0851756
@test MPSGE.Complementarity.result_value(m._jump_model[:PU]) ≈ two_by_two_PriceinOutput["PU","Itax=0.1"]#  1.1180492
@test MPSGE.Complementarity.result_value(m._jump_model[:PL]) ≈ two_by_two_PriceinOutput["PL","Itax=0.1"]#  1
@test MPSGE.Complementarity.result_value(m._jump_model[:PK]) ≈ two_by_two_PriceinOutput["PK","Itax=0.1"]#  1.1585106
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX‡X")]) ≈ two_by_two_PriceinOutput["SX","Itax=0.1"]#  100
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PY‡Y")]) ≈ two_by_two_PriceinOutput["SY","Itax=0.1"]#  54
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PU‡U")]) ≈ two_by_two_PriceinOutput["SU","Itax=0.1"]#  154
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PL†X")]) ≈ two_by_two_PriceinOutput["DXL","Itax=0.1"]#  30.9876286
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PK†X")]) ≈ two_by_two_PriceinOutput["DXK","Itax=0.1"]#  49.0376615
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PL†Y")]) ≈ two_by_two_PriceinOutput["DYL","Itax=0.1"]#  26.0442141
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PK†Y")]) ≈ two_by_two_PriceinOutput["DYK","Itax=0.1"]#  28.1009656
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX†U")]) ≈ two_by_two_PriceinOutput["DUX","Itax=0.1"]#  98.4013651
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PY†U")]) ≈ two_by_two_PriceinOutput["DUY","Itax=0.1"]#  55.6358391
@test MPSGE.Complementarity.result_value(m._jump_model[:RA]) ≈ two_by_two_PriceinOutput["RA","Itax=0.1"]#  178.4106383
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PUρRA")]) ≈ two_by_two_PriceinOutput["DU","Itax=0.1"]#  159.5731617
# @test MPSGE.Complementarity.result_value(m._jump_model[:]) ≈ two_by_two_PriceinOutput["CWI","Itax=0.1"]#  1.0638211

set_value(otax, 0.1)
solve!(m)
# Otax=0.1
@test MPSGE.Complementarity.result_value(m._jump_model[:X]) ≈ two_by_two_PriceinOutput["X","Otax=0.1"]#  1.0682942
@test MPSGE.Complementarity.result_value(m._jump_model[:Y]) ≈ two_by_two_PriceinOutput["Y","Otax=0.1"]#  0.9950053
@test MPSGE.Complementarity.result_value(m._jump_model[:U]) ≈ two_by_two_PriceinOutput["U","Otax=0.1"]#  1.0420005
@test MPSGE.Complementarity.result_value(m._jump_model[:PX]) ≈ two_by_two_PriceinOutput["PX","Otax=0.1"]#  1.01684
@test MPSGE.Complementarity.result_value(m._jump_model[:PY]) ≈ two_by_two_PriceinOutput["PY","Otax=0.1"]#  1.0917372
@test MPSGE.Complementarity.result_value(m._jump_model[:PU]) ≈ two_by_two_PriceinOutput["PU","Otax=0.1"]#  1.0424989
@test MPSGE.Complementarity.result_value(m._jump_model[:PL]) ≈ two_by_two_PriceinOutput["PL","Otax=0.1"]#  1
@test MPSGE.Complementarity.result_value(m._jump_model[:PK]) ≈ two_by_two_PriceinOutput["PK","Otax=0.1"]#  1.1711502
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX‡X")]) ≈ two_by_two_PriceinOutput["SX","Otax=0.1"]#  100
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PY‡Y")]) ≈ two_by_two_PriceinOutput["SY","Otax=0.1"]#  54
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PU‡U")]) ≈ two_by_two_PriceinOutput["SU","Otax=0.1"]#  154
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PL†X")]) ≈ two_by_two_PriceinOutput["DXL","Otax=0.1"]#  31.1984998
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PK†X")]) ≈ two_by_two_PriceinOutput["DXK","Otax=0.1"]#  48.838524
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PL†Y")]) ≈ two_by_two_PriceinOutput["DYL","Otax=0.1"]#  26.2016935
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PK†Y")]) ≈ two_by_two_PriceinOutput["DYK","Otax=0.1"]#  27.9657686
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX†U")]) ≈ two_by_two_PriceinOutput["DUX","Otax=0.1"]#  102.5233923
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PY†U")]) ≈ two_by_two_PriceinOutput["DUY","Otax=0.1"]#  51.5645494
@test MPSGE.Complementarity.result_value(m._jump_model[:RA]) ≈ two_by_two_PriceinOutput["RA","Otax=0.1"]#  167.2877805
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PUρRA")]) ≈ two_by_two_PriceinOutput["DU","Otax=0.1"]#  160.4680712
# @test MPSGE.Complementarity.result_value(m._jump_model[:]) ≈ two_by_two_PriceinOutput["CWI","Otax=0.1"]#  1.0697871

end

@testitem "TWOBYTWO (functional version , with non-1 prices in Demand)" begin
    using XLSX, MPSGE.JuMP.Containers

gams_results = XLSX.readxlsx(joinpath(@__DIR__, "MPSGEresults.xlsx"))
a_table = gams_results["two_by_two_PriceinDem"][:]  # Generated with TwoByTwo_wPriceeOutputs.gms
two_by_two_PriceinDemand = DenseAxisArray(a_table[2:end,2:end],a_table[2:end,1],a_table[1,2:end])

m = Model()
# Here parameter values are doubled and input data halved from MPSGE version       
endow  = add!(m, Parameter(:endow, value=1.))
esub_x = add!(m, Parameter(:esub_x, value=1.))
esub_y=add!(m, Parameter(:esub_y, value=1.))
esub_u=add!(m, Parameter(:esub_u, value=1.))
esub_ra=add!(m, Parameter(:esub_ra, value=1.))
pr_Ud=add!(m, Parameter(:pr_Ud, value=1.0))
otax=add!(m, Parameter(:otax, value=0.))
itax=add!(m, Parameter(:itax, value=0.))

X = add!(m, Sector(:X))
Y = add!(m, Sector(:Y))
U = add!(m, Sector(:U))

PX = add!(m, Commodity(:PX))
PY = add!(m, Commodity(:PY))
PU = add!(m, Commodity(:PU))
PL = add!(m, Commodity(:PL))#, benchmark=1.2))
PK = add!(m, Commodity(:PK))

RA = add!(m, Consumer(:RA, benchmark=134.))

add!(m, Production(X, 0, :(1.0 * $esub_x), [Output(PX, 80, [Tax(:($otax*1.),RA)])], [Input(PL, 30, [Tax(:($itax*1.),RA)]), Input(PK, 50)]))
# add!(m, Production(Y, 0, :(1.0 * $esub_y), [Output(PY, 54)], [Input(PL, 20), Input(PK, 30)]))
# add!(m, Production(Y, 0, :(1.0 * $esub_y), [Output(PY, 54)],                         [Input(PL, 20, [Tax(:($itax*1.),RA)], 1.2), Input(PK, 30)]))
add!(m, Production(Y, 0, :(1.0 * $esub_y), [Output(PY, 54)], [Input(PL, 24,), Input(PK, 30)]))
add!(m, Production(U, 0, :(1.0 * $esub_u), [Output(PU, 124.)], [Input(PX, 80), Input(PY, 44)]))

add!(m, DemandFunction(RA, :($esub_ra*1.), [Demand(PU,124., :($pr_Ud*1.)), Demand(PY,10, 1.0)], [Endowment(PL, :(54. *$endow)), Endowment(PK, 80)]))

set_fixed!(PU,true)
solve!(m, cumulative_iteration_limit=0)
# benchmark
@test MPSGE.Complementarity.result_value(m._jump_model[:X]) ≈ two_by_two_PriceinDemand["X","benchmark"]#  1
@test MPSGE.Complementarity.result_value(m._jump_model[:Y]) ≈ two_by_two_PriceinDemand["Y","benchmark"]#  1
@test MPSGE.Complementarity.result_value(m._jump_model[:U]) ≈ two_by_two_PriceinDemand["U","benchmark"]#  1
@test MPSGE.Complementarity.result_value(m._jump_model[:PX]) ≈ two_by_two_PriceinDemand["PX","benchmark"]#  1
@test MPSGE.Complementarity.result_value(m._jump_model[:PY]) ≈ two_by_two_PriceinDemand["PY","benchmark"]#  1
@test MPSGE.Complementarity.result_value(m._jump_model[:PU]) ≈ two_by_two_PriceinDemand["PU","benchmark"]#  1
@test MPSGE.Complementarity.result_value(m._jump_model[:PL]) ≈ two_by_two_PriceinDemand["PL","benchmark"]#  1
@test MPSGE.Complementarity.result_value(m._jump_model[:PK]) ≈ two_by_two_PriceinDemand["PK","benchmark"]#  1
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX‡X")]) ≈ two_by_two_PriceinDemand["SX","benchmark"]#  80
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PY‡Y")]) ≈ two_by_two_PriceinDemand["SY","benchmark"]#  54
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PU‡U")]) ≈ two_by_two_PriceinDemand["SU","benchmark"]#  124
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PL†X")]) ≈ two_by_two_PriceinDemand["DXL","benchmark"]#  30
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PK†X")]) ≈ two_by_two_PriceinDemand["DXK","benchmark"]#  50
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PL†Y")]) ≈ two_by_two_PriceinDemand["DYL","benchmark"]#  24
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PK†Y")]) ≈ two_by_two_PriceinDemand["DYK","benchmark"]#  30
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX†U")]) ≈ two_by_two_PriceinDemand["DUX","benchmark"]#  80
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PY†U")]) ≈ two_by_two_PriceinDemand["DUY","benchmark"]#  44
@test MPSGE.Complementarity.result_value(m._jump_model[:RA]) ≈ two_by_two_PriceinDemand["RA","benchmark"]#  134
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PUρRA")]) ≈ two_by_two_PriceinDemand["DU","benchmark"]#  124
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PYρRA")]) ≈ two_by_two_PriceinDemand["DY","benchmark"]#  10
# @test MPSGE.Complementarity.result_value(m._jump_model[:PYρRA]) ≈ two_by_two_PriceinDemand["DY","benchmark"]#  10

set_value(endow,1.1)
# # set_value(RA,172.2046917)
# # set_fixed!(RA, true)

# # algebraic_version(m)
solve!(m)

# RA=157
@test MPSGE.Complementarity.result_value(m._jump_model[:X]) ≈ two_by_two_PriceinDemand["X","RA=157"]#  1.0363877
@test MPSGE.Complementarity.result_value(m._jump_model[:Y]) ≈ two_by_two_PriceinDemand["Y","RA=157"]#  1.0432701
@test MPSGE.Complementarity.result_value(m._jump_model[:U]) ≈ two_by_two_PriceinDemand["U","RA=157"]#  1.0388246
@test MPSGE.Complementarity.result_value(m._jump_model[:PX]) ≈ two_by_two_PriceinDemand["PX","RA=157"]#  1.0023514
@test MPSGE.Complementarity.result_value(m._jump_model[:PY]) ≈ two_by_two_PriceinDemand["PY","RA=157"]#  0.9957389
@test MPSGE.Complementarity.result_value(m._jump_model[:PU]) ≈ two_by_two_PriceinDemand["PU","RA=157"]#  1
@test MPSGE.Complementarity.result_value(m._jump_model[:PL]) ≈ two_by_two_PriceinDemand["PL","RA=157"]#  0.944386
@test MPSGE.Complementarity.result_value(m._jump_model[:PK]) ≈ two_by_two_PriceinDemand["PK","RA=157"]#  1.0388246
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX‡X")]) ≈ two_by_two_PriceinDemand["SX","RA=157"]#  80
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PY‡Y")]) ≈ two_by_two_PriceinDemand["SY","RA=157"]#  54
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PU‡U")]) ≈ two_by_two_PriceinDemand["SU","RA=157"]#  124
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PL†X")]) ≈ two_by_two_PriceinDemand["DXL","RA=157"]#  31.8413654
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PK†X")]) ≈ two_by_two_PriceinDemand["DXK","RA=157"]#  48.2444931
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PL†Y")]) ≈ two_by_two_PriceinDemand["DYL","RA=157"]#  25.3050487
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PK†Y")]) ≈ two_by_two_PriceinDemand["DYK","RA=157"]#  28.7557372
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX†U")]) ≈ two_by_two_PriceinDemand["DUX","RA=157"]#  79.812333
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PY†U")]) ≈ two_by_two_PriceinDemand["DUY","RA=157"]#  44.1882892
@test MPSGE.Complementarity.result_value(m._jump_model[:RA]) ≈ two_by_two_PriceinDemand["RA","RA=157"]#  139.2025004
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PUρRA")]) ≈ two_by_two_PriceinDemand["DU","RA=157"]#  128.8142541
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PYρRA")]) ≈ two_by_two_PriceinDemand["DY","RA=157"]#  10.4327007
# @test MPSGE.Complementarity.result_value(m._jump_model[:PYρRA]) ≈ two_by_two_PriceinDemand["DY","RA=157"]#  10.4327007

# set_value(esub_ra, 0.6)
# # eRA=.5
# @test MPSGE.Complementarity.result_value(m._jump_model[:X]) ≈ two_by_two_PriceinDemand["X","eRA=.5"]#  1.036552
# @test MPSGE.Complementarity.result_value(m._jump_model[:Y]) ≈ two_by_two_PriceinDemand["Y","eRA=.5"]#  1.0430251
# @test MPSGE.Complementarity.result_value(m._jump_model[:U]) ≈ two_by_two_PriceinDemand["U","eRA=.5"]#  1.03899
# @test MPSGE.Complementarity.result_value(m._jump_model[:PX]) ≈ two_by_two_PriceinDemand["PX","eRA=.5"]#  1.002352
# @test MPSGE.Complementarity.result_value(m._jump_model[:PY]) ≈ two_by_two_PriceinDemand["PY","eRA=.5"]#  0.9957377
# @test MPSGE.Complementarity.result_value(m._jump_model[:PU]) ≈ two_by_two_PriceinDemand["PU","eRA=.5"]#  1
# @test MPSGE.Complementarity.result_value(m._jump_model[:PL]) ≈ two_by_two_PriceinDemand["PL","eRA=.5"]#  0.9443705
# @test MPSGE.Complementarity.result_value(m._jump_model[:PK]) ≈ two_by_two_PriceinDemand["PK","eRA=.5"]#  1.038836
# @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX‡X")]) ≈ two_by_two_PriceinDemand["SX","eRA=.5"]#  80
# @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PY‡Y")]) ≈ two_by_two_PriceinDemand["SY","eRA=.5"]#  54
# @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PU‡U")]) ≈ two_by_two_PriceinDemand["SU","eRA=.5"]#  124
# @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PL†X")]) ≈ two_by_two_PriceinDemand["DXL","eRA=.5"]#  31.8419115
# @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PK†X")]) ≈ two_by_two_PriceinDemand["DXK","eRA=.5"]#  48.2439966
# @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PL†Y")]) ≈ two_by_two_PriceinDemand["DYL","eRA=.5"]#  25.3054345
# @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PK†Y")]) ≈ two_by_two_PriceinDemand["DYK","eRA=.5"]#  28.7553865
# @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX†U")]) ≈ two_by_two_PriceinDemand["DUX","eRA=.5"]#  79.812279
# @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PY†U")]) ≈ two_by_two_PriceinDemand["DUY","eRA=.5"]#  44.1883435
# @test MPSGE.Complementarity.result_value(m._jump_model[:RA]) ≈ two_by_two_PriceinDemand["RA","eRA=.5"]#  139.2024876
# @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PUρRA")]) ≈ two_by_two_PriceinDemand["DU","eRA=.5"]#  128.8347541
# @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PYρRA")]) ≈ two_by_two_PriceinDemand["DY","eRA=.5"]#  10.4121129
# @test MPSGE.Complementarity.result_value(m._jump_model[:PYρRA]) ≈ two_by_two_PriceinDemand["DY","eRA=.5"]#  10.4121129

# set_value(pr_Ud, 2.)
# solve!(m)
# # pr_Ud=2
# @test MPSGE.Complementarity.result_value(m._jump_model[:X]) ≈ two_by_two_PriceinDemand["X","pr_Ud=2"]#  1.0595609
# @test MPSGE.Complementarity.result_value(m._jump_model[:Y]) ≈ two_by_two_PriceinDemand["Y","pr_Ud=2"]#  1.0087068
# @test MPSGE.Complementarity.result_value(m._jump_model[:U]) ≈ two_by_two_PriceinDemand["U","pr_Ud=2"]#  1.0621537
# @test MPSGE.Complementarity.result_value(m._jump_model[:PX]) ≈ two_by_two_PriceinDemand["PX","pr_Ud=2"]#  1.002447
# @test MPSGE.Complementarity.result_value(m._jump_model[:PY]) ≈ two_by_two_PriceinDemand["PY","pr_Ud=2"]#  0.9955662
# @test MPSGE.Complementarity.result_value(m._jump_model[:PU]) ≈ two_by_two_PriceinDemand["PU","pr_Ud=2"]#  1
# @test MPSGE.Complementarity.result_value(m._jump_model[:PL]) ≈ two_by_two_PriceinDemand["PL","pr_Ud=2"]#  0.9421925
# @test MPSGE.Complementarity.result_value(m._jump_model[:PK]) ≈ two_by_two_PriceinDemand["PK","pr_Ud=2"]#  1.0404339
# @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX‡X")]) ≈ two_by_two_PriceinDemand["SX","pr_Ud=2"]#  80
# @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PY‡Y")]) ≈ two_by_two_PriceinDemand["SY","pr_Ud=2"]#  54
# @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PU‡U")]) ≈ two_by_two_PriceinDemand["SU","pr_Ud=2"]#  124
# @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PL†X")]) ≈ two_by_two_PriceinDemand["DXL","pr_Ud=2"]#  31.9185419
# @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PK†X")]) ≈ two_by_two_PriceinDemand["DXK","pr_Ud=2"]#  48.1744684
# @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PL†Y")]) ≈ two_by_two_PriceinDemand["DYL","pr_Ud=2"]#  25.3595604
# @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PK†Y")]) ≈ two_by_two_PriceinDemand["DYK","pr_Ud=2"]#  28.706277
# @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX†U")]) ≈ two_by_two_PriceinDemand["DUX","pr_Ud=2"]#  79.8047156
# @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PY†U")]) ≈ two_by_two_PriceinDemand["DUY","pr_Ud=2"]#  44.1959582
# @test MPSGE.Complementarity.result_value(m._jump_model[:RA]) ≈ two_by_two_PriceinDemand["RA","pr_Ud=2"]#  139.2009488
# @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PUρRA")]) ≈ two_by_two_PriceinDemand["DU","pr_Ud=2"]#  131.7070569
# @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PYρRA")]) ≈ two_by_two_PriceinDemand["DY","pr_Ud=2"]#  7.5272667
# @test MPSGE.Complementarity.result_value(m._jump_model[:PYρRA]) ≈ two_by_two_PriceinDemand["DY","pr_Ud=2"]#  7.5272667

# set_value(esub_ra, .6)
# solve!(m)
# # prU2,eRA.6
# @test MPSGE.Complementarity.result_value(m._jump_model[:X]) ≈ two_by_two_PriceinDemand["X","prU2,eRA.6"]#  1.0633532
# @test MPSGE.Complementarity.result_value(m._jump_model[:Y]) ≈ two_by_two_PriceinDemand["Y","prU2,eRA.6"]#  1.0030496
# @test MPSGE.Complementarity.result_value(m._jump_model[:U]) ≈ two_by_two_PriceinDemand["U","prU2,eRA.6"]#  1.0659719
# @test MPSGE.Complementarity.result_value(m._jump_model[:PX]) ≈ two_by_two_PriceinDemand["PX","prU2,eRA.6"]#  1.0024627
# @test MPSGE.Complementarity.result_value(m._jump_model[:PY]) ≈ two_by_two_PriceinDemand["PY","prU2,eRA.6"]#  0.9955379
# @test MPSGE.Complementarity.result_value(m._jump_model[:PU]) ≈ two_by_two_PriceinDemand["PU","prU2,eRA.6"]#  1
# @test MPSGE.Complementarity.result_value(m._jump_model[:PL]) ≈ two_by_two_PriceinDemand["PL","prU2,eRA.6"]#  0.9418338
# @test MPSGE.Complementarity.result_value(m._jump_model[:PK]) ≈ two_by_two_PriceinDemand["PK","prU2,eRA.6"]#  1.0406977
# @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX‡X")]) ≈ two_by_two_PriceinDemand["SX","prU2,eRA.6"]#  80
# @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PY‡Y")]) ≈ two_by_two_PriceinDemand["SY","prU2,eRA.6"]#  54
# @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PU‡U")]) ≈ two_by_two_PriceinDemand["SU","prU2,eRA.6"]#  124
# @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PL†X")]) ≈ two_by_two_PriceinDemand["DXL","prU2,eRA.6"]#  31.9311957
# @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PK†X")]) ≈ two_by_two_PriceinDemand["DXK","prU2,eRA.6"]#  48.1630131
# @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PL†Y")]) ≈ two_by_two_PriceinDemand["DYL","prU2,eRA.6"]#  25.3684967
# @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PK†Y")]) ≈ two_by_two_PriceinDemand["DYK","prU2,eRA.6"]#  28.6981871
# @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX†U")]) ≈ two_by_two_PriceinDemand["DUX","prU2,eRA.6"]#  79.8034685
# @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PY†U")]) ≈ two_by_two_PriceinDemand["DUY","prU2,eRA.6"]#  44.1972139
# @test MPSGE.Complementarity.result_value(m._jump_model[:RA]) ≈ two_by_two_PriceinDemand["RA","prU2,eRA.6"]#  139.2007426
# @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PUρRA")]) ≈ two_by_two_PriceinDemand["DU","prU2,eRA.6"]#  132.18052
# @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PYρRA")]) ≈ two_by_two_PriceinDemand["DY","prU2,eRA.6"]#  7.0516882
# # @test MPSGE.Complementarity.result_value(m._jump_model[:PYρRA]) ≈ two_by_two_PriceinDemand["DY","prU2,eRA.6"]#  7.0516882

# set_value(pr_Ud, 2.)
# solve!(m)
# # prU.5,eRA~
# @test MPSGE.Complementarity.result_value(m._jump_model[:X]) ≈ two_by_two_PriceinDemand["X","prU.5,eRA~"]#  0.9983347
# @test MPSGE.Complementarity.result_value(m._jump_model[:Y]) ≈ two_by_two_PriceinDemand["Y","prU.5,eRA~"]#  1.1000067
# @test MPSGE.Complementarity.result_value(m._jump_model[:U]) ≈ two_by_two_PriceinDemand["U","prU.5,eRA~"]#  1.0005255
# @test MPSGE.Complementarity.result_value(m._jump_model[:PX]) ≈ two_by_two_PriceinDemand["PX","prU.5,eRA~"]#  1.0021944
# @test MPSGE.Complementarity.result_value(m._jump_model[:PY]) ≈ two_by_two_PriceinDemand["PY","prU.5,eRA~"]#  0.9960224
# @test MPSGE.Complementarity.result_value(m._jump_model[:PU]) ≈ two_by_two_PriceinDemand["PU","prU.5,eRA~"]#  1
# @test MPSGE.Complementarity.result_value(m._jump_model[:PL]) ≈ two_by_two_PriceinDemand["PL","prU.5,eRA~"]#  0.9479953
# @test MPSGE.Complementarity.result_value(m._jump_model[:PK]) ≈ two_by_two_PriceinDemand["PK","prU.5,eRA~"]#  1.0361902
# @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX‡X")]) ≈ two_by_two_PriceinDemand["SX","prU.5,eRA~"]#  80
# @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PY‡Y")]) ≈ two_by_two_PriceinDemand["SY","prU.5,eRA~"]#  54
# @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PU‡U")]) ≈ two_by_two_PriceinDemand["SU","prU.5,eRA~"]#  124
# @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PL†X")]) ≈ two_by_two_PriceinDemand["DXL","prU.5,eRA~"]#  31.7151726
# @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PK†X")]) ≈ two_by_two_PriceinDemand["DXK","prU.5,eRA~"]#  48.3595788
# @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PL†Y")]) ≈ two_by_two_PriceinDemand["DYL","prU.5,eRA~"]#  25.2158839
# @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PK†Y")]) ≈ two_by_two_PriceinDemand["DYK","prU.5,eRA~"]#  28.837054
# @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX†U")]) ≈ two_by_two_PriceinDemand["DUX","prU.5,eRA~"]#  79.8248298
# @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PY†U")]) ≈ two_by_two_PriceinDemand["DUY","prU.5,eRA~"]#  44.1757122
# @test MPSGE.Complementarity.result_value(m._jump_model[:RA]) ≈ two_by_two_PriceinDemand["RA","prU.5,eRA~"]#  139.2061339
# @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PUρRA")]) ≈ two_by_two_PriceinDemand["DU","prU.5,eRA~"]#  124.0651604
# @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PYρRA")]) ≈ two_by_two_PriceinDemand["DY","prU.5,eRA~"]#  15.2014384
# # @test MPSGE.Complementarity.result_value(m._jump_model[:PYρRA]) ≈ two_by_two_PriceinDemand["DY","prU.5,eRA~"]#  15.2014384

# set_value(itax, 0.1)
# solve!(m)

# set_value(otax, 0.1)
# solve!(m)
end