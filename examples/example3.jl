using MPSGE

m = Model()

i = [:x, :y]
f = [:l, :k]

@parameter(m, endow, 1.0)

Y = add!(m, Sector(:Y, indices=(i,)))
U = add!(m, Sector(:U))

PC = add!(m, Commodity(:PC, indices=(i,)))
PU = add!(m, Commodity(:PU))
PF = add!(m, Commodity(:PF, indices=(f,)))

RA = add!(m, Consumer(:RA, benchmark=150.))

@production(m, Y[:x], 1, PC[:x], 100, [Input(PF[:l], 50), Input(PF[:k], 50)])
@production(m, Y[:y], 1, PC[:y], 50, [Input(PF[:l], 20), Input(PF[:k], 30)])
@production(m, U, 1, PU, 150, [Input(PC[:x], 100), Input(PC[:y], 50)])

@demand(m, RA, PU, [Endowment(PF[:l], :(70 * $endow)), Endowment(PF[:k], 80.)])

solve!(m, cumulative_iteration_limit=0)

set_value(endow, 1.1)

solve!(m)

algebraic_version(m)