using MPSGE

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

# add!(m, Production(X, 0, :(1.0 * $esub_x), [Output(PX, 110)], [Input(PL, 50), Input(PK, 50)]))
add!(m, Production(X, 0, :(1.0 * $esub_x), [Output(PX, 80, [Tax(:($otax*1.),RA)])], [Input(PL, 30, [Tax(:($itax*1.),RA)]), Input(PK, 50)]))
# add!(m, Production(Y, 0, :(1.0 * $esub_y), [Output(PY, 54)], [Input(PL, 20), Input(PK, 30)]))
# add!(m, Production(Y, 0, :(1.0 * $esub_y), [Output(PY, 54)],                         [Input(PL, 20, [Tax(:($itax*1.),RA)], 1.2), Input(PK, 30)]))
add!(m, Production(Y, 0, :(1.0 * $esub_y), [Output(PY, 54)], [Input(PL, 24,), Input(PK, 30)]))
add!(m, Production(U, 0, :(1.0 * $esub_u), [Output(PU, 124.)], [Input(PX, 80), Input(PY, 44)]))

add!(m, DemandFunction(RA, :($esub_ra*1.), [Demand(PU,124., :($pr_Ud*1.)), Demand(PY,10, 1.0)], [Endowment(PL, :(54. *$endow)), Endowment(PK, 80)]))
# :($esub_ra*1.)
set_fixed!(PU,true)
# solve!(m, cumulative_iteration_limit=0)

# set_value(RA, 164.)
# set_fixed!(RA,true)
# solve!(m)

set_value(endow,1.1)
# # set_value(RA,172.2046917)
# # set_fixed!(RA, true)

# # algebraic_version(m)
# solve!(m)

# set_fixed!(PU,false)
# set_fixed!(PX,true)
# # # set_value(RA,172.2046917)
# # # set_fixed!(RA, true)
set_value(esub_ra, .6) 
# solve!(m)

# set_value(PL, 1.0)
# set_fixed!(PX,false)
# set_fixed!(PL,true)
# # # set_value(RA,172.2046917)
# # # set_fixed!(RA, true)
set_value(pr_Ud, 3.)
solve!(m)

# set_value(itax, 0.1)
# solve!(m)

# set_value(otax, 0.1)
# solve!(m)

# algebraic_version(m)
# solve!(m)


