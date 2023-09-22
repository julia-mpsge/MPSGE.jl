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

add!(m, Production(X, 0, :(1.0 * $esub_x), [Output(PX, 110)], [Input(PL, 50, taxes=[Tax(:($itax*1.),RA)],price=1.2), Input(PK, 50)]))
# add!(m, Production(X, 0, :(1.0 * $esub_x), [Output(PX, 110, taxes=[Tax(0.,RA)])], [Input(PL, 50, taxes=[Tax(:($itax*1.),RA)],price=1.2), Input(PK, 50)]))
# add!(m, Production(X, 0, :(1.0 * $esub_x), [Output(PX, 110, taxes=[Tax(:($otax*1.),RA)])], [Input(PL, 50, taxes=[Tax(:($itax*1.),RA)], price=1.2), Input(PK, 50)]))
add!(m, Production(Y, 0, :(1.0 * $esub_y), [Output(PY, 54)], [Input(PL, 24,), Input(PK, 30)]))
add!(m, Production(U, 0, :(1.0 * $esub_u), [Output(PU, 164.)], [Input(PX, 110), Input(PY, 54)]))

# add!(m, DemandFunction(RA, 1., [Demand(PU,154.)], [Endowment(PL, 74.), Endowment(PK, 80)]))
add!(m, DemandFunction(RA, 1., [Demand(PU,164.)], [Endowment(PL, :(74. *$endow)), Endowment(PK, 80)]))

set_value(endow, 1.1)
set_fixed!(PL,true)
solve!(m)

set_value(itax, 0.1)
solve!(m)
# A replication of the MPSGE Two by Two Scalar , from https://www.gams.com/34/docs/UG_MPSGE_Intro.html#UG_MPSGE_Intro_Appendix_twobytwo1
# m = Model()

# endow = add!(m, Parameter(:endow, value=1.0))
# @parameter(m, sub_elas_x, 1.5, description="Substituion Elasticity for Sector X")
# @parameter(m, sub_elas_y, 2.)
# @parameter(m, sub_elas_u, 0.5)
# @parameter(m, transf_elas_x, 0.)
# @parameter(m, transf_elas_y, 0.)
# # transf_elas_x = 0
# # transf_elas_y = 0
# # sub_elas_x = 1
# # sub_elas_y = 1
# @sector(m, X)
# Y = add!(m, Sector(:Y))
# @sector(m, U)

# @commodity(m, PX)
# @commodity(m, PY)
# @commodity(m, PU)
# @commodity(m, PL)
# @commodity(m, PK)

# @consumer(m, RA, benchmark = 150.)

# @production(m, X, :($transf_elas_x*1.), :($sub_elas_x*1.), [Output(PX, 100)], [Input(PL, 50),  Input(PK, 50)])
# @production(m, Y, :($transf_elas_y*1.), :($sub_elas_y*1.), [Output(PY, 50)],  [Input(PL, 20),  Input(PK, 30)])
# @production(m, U, 0,                    :($sub_elas_u*1.), [Output(PU, 150)], [Input(PX, 100), Input(PY, 50)])

# @demand(m, RA, 1., [Demand(PU, 150)], [Endowment(PL, :(70 * $endow)), Endowment(PK, 80.)])

# solve!(m)
# solve!(m, cumulative_iteration_limit=0)
# algebraic_version(m)

# set_value(endow, 1.1)
# set_fixed!(RA, true)
# solve!(m)

# set_fixed!(PX, true)
# set_fixed!(RA, false)
# solve!(m)

# set_fixed!(PX, false)
# set_fixed!(PL, true)
# solve!(m)

# # Re-running with non-1 elasticities of substitution, non-Cobb-Douglas forms for production in the cost function
# set_value(sub_elas_x, 0.5)
# set_value(sub_elas_y, 0.6)
# set_fixed!(RA, true)
# solve!(m)

# set_fixed!(PX, true)
# set_fixed!(RA, false)
# solve!(m)

# set_fixed!(PX, false)
# set_fixed!(PL, true)
# solve!(m)

# # A model with joint porduction and non-0 elasticities of transformation
# m = Model()

# @parameter(m, diff, 0.0)
# @parameter(m, sub_elas_a, 1.)
# @parameter(m, sub_elas_b, 1.)
# @parameter(m, sub_elas_w, 1.)
# @parameter(m, t_elas_a, 0.0)
# @parameter(m, t_elas_b, 0.0)


# @sector(m, A)
# @sector(m, B)
# @sector(m, W)

# @commodity(m, PX)
# @commodity(m, PY)
# @commodity(m, PW)
# @commodity(m, PL)
# @commodity(m, PK)

# @consumer(m, CONS, benchmark=200.0)

# @production(m, A, :($t_elas_a*1.), :($sub_elas_a*1.), [Output(PX, 80),          Output(PY, 20)], [Input(PL, 40),             Input(PK, 60)])
# @production(m, B, :($t_elas_b*1.), :($sub_elas_b*1.), [Output(PX, :(20+$diff)), Output(PY, 80)], [Input(PL, 60),             Input(PK, 40)])
# @production(m, W, 0,               :($sub_elas_w*1.), [Output(PW, 200.0)],                       [Input(PX, :(100.0+$diff)), Input(PY, 100.0)])

# @demand(m, CONS, 1., [Demand(PW, 200.)], [Endowment(PL, 100.0), Endowment(PK, 100.0)])

# solve!(m, cumulative_iteration_limit=0)
# algebraic_version(m)

# set_value(diff, 10.0)
# set_value(CONS, 200.0)
# set_fixed!(CONS, true)
# solve!(m)

# set_value(PW, 1.0)
# set_fixed!(PW, true)
# # set_fixed!(CONS, false)
# solve!(m)

# set_value(t_elas_a, 2.0)
# set_value(t_elas_b, 1.5)
# solve!(m)

# set_value(t_elas_a, 3.0)
# set_value(t_elas_b, 1.0)
# solve!(m)

# set_value(t_elas_a, 1.0)
# solve!(m)

# # Re-set with Leontief/Complement Substitution Elasticities
# set_value(diff, 0.0)
# set_value(sub_elas_a, 0.0)
# set_value(sub_elas_b, 0.)
# set_value(sub_elas_w, 0.)
# set_value(t_elas_a, 0.0)
# set_value(t_elas_b, 0.0)
# solve!(m, cumulative_iteration_limit=0)

# set_value(diff, 10.0)
# set_fixed!(PW, true)
# set_fixed!(CONS, true)
# solve!(m)

# set_value(t_elas_a, 2.0)
# set_value(t_elas_b, 1.5)
# solve!(m)

# set_value(t_elas_a, 3.0)
# set_value(t_elas_b, 1.0)
# solve!(m)

# set_value(t_elas_a, 1.0)
# set_value(t_elas_b, 1.0)
# solve!(m)

# # Re-set with CES Substitution Elasticities
# set_value(diff, 0.0)
# set_value(sub_elas_a, 1.5)
# set_value(sub_elas_b, 2.)
# set_value(sub_elas_w, .5)
# set_value(t_elas_a, 0.0)
# set_value(t_elas_b, 0.0)
# solve!(m, cumulative_iteration_limit=0)

# set_value(diff, 10.0)
# set_fixed!(PW, false)
# set_fixed!(CONS, true)
# solve!(m)

# set_value(t_elas_a, 2.0)
# set_value(t_elas_b, 1.5)
# solve!(m)

# set_value(t_elas_a, 3.0)
# set_value(t_elas_b, 1.0)
# solve!(m)

# set_value(t_elas_a, 1.0)
# set_value(t_elas_b, 1.0)
# solve!(m)

