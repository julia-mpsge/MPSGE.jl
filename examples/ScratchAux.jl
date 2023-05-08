using MPSGE

m = Model()
# Here parameter values are doubled and input data halved from MPSGE version       
tx  = add!(m, Parameter(:tx, value=0.1))
ty  = add!(m, Parameter(:ty, value=0.))
tlx = add!(m, Parameter(:tlx, value=0.))
tkx = add!(m, Parameter(:tkx, value=0.))
uo  = add!(m, Parameter(:uo, value=0.2)) #Initial unemployment rate

X = add!(m, Sector(:X))
Y = add!(m, Sector(:Y))
W = add!(m, Sector(:W))

PX = add!(m, Commodity(:PX))
PY = add!(m, Commodity(:PY))
PW = add!(m, Commodity(:PW))
PL = add!(m, Commodity(:PL))
PK = add!(m, Commodity(:PK))

CONS = add!(m, Consumer(:CONS, benchmark=200.))

U = add!(m, Aux(:U, benchmark=0.2))
add!(m, Production(X, 0, 1.0, [Output(PX, 100, [Tax(:(1.0*$tx),CONS)])], [Input(PK, 50, [Tax(:($tkx*1.),CONS)]), Input(PL, 40)]))
add!(m, Production(Y, 0, 1.0, [Output(PY, 100, [Tax(:(1.0*$ty),CONS)])], [Input(PL, 60), Input(PK, 40)]))
add!(m, Production(W, 0, 1.0, [Output(PW, 200.)], [Input(PX, 100), Input(PY, 100)]))

add!(m, DemandFunction(CONS, 1., [Demand(PW,200.)], [Endowment(PL, 120.), Endowment(PL, :(-80/(1-$uo)*$U)), Endowment(PK, 90)]))
add!(m, AuxConstraint(U, :($PL==$PW)))

solve!(m, cumulative_iteration_limit=0)

set_value(U, .1)
set_value(CONS,210.)
set_fixed!(CONS,true)
solve!(m)

set_value(tkx, 0.25)
set_value(tx, 0.0)
set_fixed!(CONS,false)
set_fixed!(PX,true)
solve!(m)

set_value(ty, 0.5)
solve!(m)

set_value(tkx, 0.0)
solve!(m)
