using MPSGE
using MPSGE.JuMP.Containers

m = Model()

goods = [:x, :y]
factors = [:l, :k]

factor = DenseAxisArray(Float64[50 50; 20 30], goods, factors)
supply = DenseAxisArray(Float64[100, 50], goods)

@parameter(m, endow, 1.0)

Y = add!(m, Sector(:Y, indices=(goods,)))
U = add!(m, Sector(:U))

# PX = add!(m, Commodity(:PX))
# PY = add!(m, Commodity(:PY))
PC = add!(m, Commodity(:PC, indices=(goods,)))
PU = add!(m, Commodity(:PU))
# PF = add!(m, Commodity(:PF, indices=(factors,)))
PL = add!(m,Commodity(:PL))
PK = add!(m,Commodity(:PK))


RA = add!(m, Consumer(:RA, benchmark=150.))

# for i in goods
#     @production(m, Y[i], 1, PC[i], supply[i], [Input(PL, factor[i,:l]), Input(PK, factor[i,:k])])
# end
@production(m, Y[:x], 1, PC[:x], supply[:x], [Input(PL, factor[:x,:l]), Input(PK, factor[:x,:k])])
@production(m, Y[:y], 1, PC[:y], supply[:y], [Input(PL, factor[:y,:l]), Input(PK, factor[:y,:k])])


# @production(m, [i in goods], Y[i], 1, PC[i], supply[i],  [Input(PF[f], factor[i,f]) for f in factors])

@production(m, U, 1, PU, 150, [Input(PC[:x], 100), Input(PC[:y], 50)])

@demand(m, RA, PU, [Endowment(PL, :(70 * $endow)), Endowment(PK, 80.)])

solve!(m, cumulative_iteration_limit=0)

set_value(endow, 1.1)

solve!(m)

algebraic_version(m)