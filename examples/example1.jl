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

add!(m, Production(X, 1, PX, 100, [Input(PL, 50), Input(PK, 50)]))
add!(m, Production(Y, 1, PY, 50, [Input(PL, 20), Input(PK, 30)]))
add!(m, Production(U, 1, PU, 150, [Input(PX, 100), Input(PY, 50)]))

add!(m, Demand(RA, PU, [Endowment(PL, :(70 * $endow)), Endowment(PK, 80.)]))

solve!(m, cumulative_iteration_limit=0)

set_value(endow, 1.1)

solve!(m)

algebraic_version(m)