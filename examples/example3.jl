using MPSGE

m = Model()

sectors = [:x, :y]

@parameter(m, endow, 1.0)

S = add!(m, Sector(:S, indices=(sectors,)))
@sector(m, U)

@commodity(m, PX)
@commodity(m, PY)
@commodity(m, PU)
@commodity(m, PL)
@commodity(m, PK)

@consumer(m, RA, benchmark=150.)

@production(m, S[:x], 1, PX, 100, [Input(PL, 50), Input(PK, 50)])
@production(m, S[:y], 1, PY, 50, [Input(PL, 20), Input(PK, 30)])
@production(m, U, 1, PU, 150, [Input(PX, 100), Input(PY, 50)])

@demand(m, RA, PU, [Endowment(PL, :(70 * $endow)), Endowment(PK, 80.)])

solve!(m, cumulative_iteration_limit=0)

set_value(endow, 1.1)

solve!(m)

algebraic_version(m)