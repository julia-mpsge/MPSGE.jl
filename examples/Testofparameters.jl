using MPSGE
m = Model()

@parameter(m, endow, 1.0)
@parameter(m, diff, 0.0)

@sector(m, X)
@sector(m, Y)
@sector(m, U)

@commodity(m, PX)
@commodity(m, PY)
@commodity(m, PU)
@commodity(m, PL)
@commodity(m, PK)

@consumer(m, RA, benchmark = 150.)

@production(m, X, 0, 1, [Output(PX, :(100+$diff))], [Input(PL, 50), Input(PK, 50)])
@production(m, Y, 0, 1, [Output(PY, 50)], [Input(PL, 20), Input(PK, 30)])
@production(m, U, 0, 1, [Output(PU, 150)], [Input(PX, 100), Input(PY, 50)])

@demand(m, RA, 1.0, [Demand(PU, 150)], [Endowment(PL, :(70 * $endow)), Endowment(PK, 80.)])
solve!(m, cumulative_iteration_limit=0)

algebraic_version(m)

set_value(diff, 10.)
# set_value(RA, 165.)
set_value(endow, 1.1)
set_fixed!(RA, true)
solve!(m)


set_fixed!(RA, false)
set_fixed!(PX, true)
solve!(m)

# set_fixed!(PX, false)
# set_fixed!(PL, true)
# solve!(m)
