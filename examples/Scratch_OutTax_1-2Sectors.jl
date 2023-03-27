using MPSGE

m = Model()

@parameter(m, diff, 0.0)
@parameter(m, sub_elas_a, 0.)
@parameter(m, sub_elas_b, 0.)
@parameter(m, sub_elas_w, 0.)
@parameter(m, t_elas_a, 0.0)
@parameter(m, t_elas_b, 0.0)
@parameter(m, Otax1, 0.0)
@parameter(m, Otax2, 0.0)
@parameter(m, Otax3, 0.0)
@parameter(m, Otax4, 0.0)
@parameter(m, TA, 0.0)


@sector(m, A)
@sector(m, B)
@sector(m, W)

@commodity(m, PX)
@commodity(m, PY)
@commodity(m, PW)
@commodity(m, PL)
@commodity(m, PK)

@consumer(m, CONS, benchmark=200.0)

# @production(m, A, 0, 1, [Output(PX, 80),          Output(PY, 20)], [Input(PL, 40), Input(PK, 60)])
@production(m, A, :($t_elas_a*1.), :($sub_elas_a*1.), [Output(PX, 80, [MPSGE.Tax(:($Otax1*1.0), CONS)]), Output(PY, 20, [MPSGE.Tax(:($Otax2*1.0), CONS)])], [Input(PL, 40), Input(PK, 60)])
# @production(m, B, 0, 1, [Output(PX, 20), Output(PY, 80)], [Input(PL, 60), Input(PK, 40)])
# @production(m, B, :($t_elas_b*1.), 1, [Output(PX, 20), Output(PY, 80)], [Input(PL, 60), Input(PK, 40)])
@production(m, B, :($t_elas_b*1.), :($sub_elas_b*1.), [Output(PX, 20, [MPSGE.Tax(:($Otax3*1.0), CONS)]), Output(PY, 80, [MPSGE.Tax(:($Otax4*1.0), CONS)])], [Input(PL, 60), Input(PK, 40)])
@production(m, W, 0, :($sub_elas_w*1.), [Output(PW, 200.0)],[Input(PX, 100.0), Input(PY, 100.0)])
# @production(m, W, 0, 1, [Output(PW, 200.0)], [Input(PX, 100.0), Input(PY, 100.0)])
# @production(m, W, 0.,1, [Output(PW, :(200.0+$diff))], [Input(PX, :(100.0+$diff)), Input(PY, 100.0)])

@demand(m, CONS, 1., [Demand(PW, 200.)], [Endowment(PL, 100.0), Endowment(PK, 100.0)])

# solve!(m, cumulative_iteration_limit=0)
# algebraic_version(m)

set_value(Otax1, 0.1)
# # set_value(Otax3, 0.1)
# set_value(CONS, 200.0)
set_fixed!(CONS, true)
set_fixed!(PW, true)
solve!(m)

# set_fixed!(CONS, true)
set_fixed!(PW, false)
set_value(sub_elas_a, 1.0)
set_value(sub_elas_b, 1.)
set_value(sub_elas_w, 1.)
solve!(m)


set_fixed!(PW, true)
set_fixed!(CONS, false)
solve!(m)

set_value(Otax1, 0.2)
solve!(m)

set_value(t_elas_a, 3.0)
set_value(t_elas_b, 1.0)
solve!(m)

set_value(t_elas_a, 1.0)
set_value(t_elas_b, 1.0)
solve!(m)

set_value(sub_elas_a, 0.)
set_value(sub_elas_b, 0.)
set_value(sub_elas_w, 0.)
set_value(t_elas_a, 1.0)
set_value(t_elas_b, 1.0)
solve!(m)

set_value(sub_elas_a, 1.5)
set_value(sub_elas_b, 2.)
set_value(sub_elas_w, 0.5)
set_value(t_elas_a, 0.0)
set_value(t_elas_b, 0.0)
solve!(m)

set_value(t_elas_a, 2.0)
set_value(t_elas_b, 1.5)
solve!(m)

set_value(t_elas_a, 3.0)
set_value(t_elas_b, 1.0)
solve!(m)

set_value(t_elas_a, 1.0)
set_value(t_elas_b, 1.0)
solve!(m)


