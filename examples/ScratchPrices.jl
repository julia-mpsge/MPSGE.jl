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
PL = add!(m, Commodity(:PL, benchmark=1.2))
PK = add!(m, Commodity(:PK))

RA = add!(m, Consumer(:RA, benchmark=150.))

# add!(m, Production(X, 0, :(1.0 * $esub_x), [Output(PX, 110)], [Input(PL, 50), Input(PK, 50)]))
add!(m, Production(X, 0, :(1.0 * $esub_x), [Output(PX, 110)], [Input(PL, 50, [Tax(:($itax*1.),RA)]), Input(PK, 50)]))
# add!(m, Production(Y, 0, :(1.0 * $esub_y), [Output(PY, 54)], [Input(PL, 20), Input(PK, 30)]))
add!(m, Production(Y, 0, :(1.0 * $esub_y), [Output(PY, 54)], [Input(PL, 20, [Tax(:($itax*1.),RA)]), Input(PK, 30)]))
add!(m, Production(U, 0, :(1.0 * $esub_u), [Output(PU, 164.)], [Input(PX, 110), Input(PY, 54)]))

add!(m, DemandFunction(RA, 1., [Demand(PU,150.)], [Endowment(PL, :(70. *$endow)), Endowment(PK, 80)]))

set_fixed!(PU,true)
solve!(m, cumulative_iteration_limit=0)

solve!(m)

set_value(endow,1.1)

solve!(m)