using MPSGE

m = Model()

@parameter(m, endow, 1.0)

@sector(m, X)
@sector(m, Y)
@sector(m, U)

@commodity(m, PX)
@commodity(m, PY)
@commodity(m, PU)
@commodity(m, PL)
@commodity(m, PK)

@consumer(m, RA, benchmark=150.)

@production(m, X, 1, [Output(PX, 100)], [Input(PL, 50), Input(PK, 50)])
@production(m, Y, 1, [Output(PY, 50)], [Input(PL, 20), Input(PK, 30)])
@production(m, U, 1, [Output(PU, 150)], [Input(PX, 100), Input(PY, 50)])

@demand(m, RA, PU, [Endowment(PL, :(70 * $endow)), Endowment(PK, 80.)])

solve!(m, cumulative_iteration_limit=0)

set_value(endow, 1.1)

solve!(m)

algebraic_version(m)