using MPSGE

# m = Model()
# # A set up to test R: the rationing instrument, the Auxiliary Variable in Demand blocks (applied to Endowments)       
# tx  = add!(m, Parameter(:tx, value=0.1))
# ty  = add!(m, Parameter(:ty, value=0.))
# tlx = add!(m, Parameter(:tlx, value=0.))
# tkx = add!(m, Parameter(:tkx, value=0.))
# uo  = add!(m, Parameter(:uo, value=0.2)) #Initial unemployment rate

# X = add!(m, Sector(:X))
# Y = add!(m, Sector(:Y))
# W = add!(m, Sector(:W))

# PX = add!(m, Commodity(:PX))
# PY = add!(m, Commodity(:PY))
# PW = add!(m, Commodity(:PW))
# PL = add!(m, Commodity(:PL))
# PK = add!(m, Commodity(:PK))

# CONS = add!(m, Consumer(:CONS, benchmark=200.))

# U = add!(m, Aux(:U, benchmark=0.2))
# add!(m, Production(X, 0, 1.0, [Output(PX, 100, [Tax(:(1.0*$tx),CONS)])], [Input(PK, 50, [Tax(:($tkx*1.),CONS)]), Input(PL, 40)]))
# add!(m, Production(Y, 0, 1.0, [Output(PY, 100, [Tax(:(1.0*$ty),CONS)])], [Input(PL, 60), Input(PK, 40)]))
# add!(m, Production(W, 0, 1.0, [Output(PW, 200.)], [Input(PX, 100), Input(PY, 100)]))

# add!(m, DemandFunction(CONS, 1., [Demand(PW,200.)], [Endowment(PL, 120.), Endowment(PL, :(-80/(1-$uo)*$U)), Endowment(PK, 90)]))
# add!(m, AuxConstraint(U, :($PL==$PW)))

# solve!(m, cumulative_iteration_limit=0)

# set_value(U, .1)
# set_value(CONS,210.)
# set_fixed!(CONS,true)
# solve!(m)

# set_value(tkx, 0.25)
# set_value(tx, 0.0)
# set_fixed!(CONS,false)
# set_fixed!(PX,true)
# solve!(m)

# set_value(ty, 0.5)
# solve!(m)

# set_value(tkx, 0.0)
# solve!(m)


# m = Model()
# # A set up to test N: Endogenous taxes (and M: the multiplier), the Auxiliary Variable in Production blocks (applied to Inputs or Outputs)       
# txl = add!(m,Parameter(:txl, value=0.2))
# txk = add!(m,Parameter(:txk, value=0.2))

# X = add!(m, Sector(:X))
# Y = add!(m, Sector(:Y))
# W = add!(m, Sector(:W))
# TL = add!(m, Sector(:TL))
# TK = add!(m, Sector(:TK))

# PX = add!(m, Commodity(:PX))
# PY = add!(m, Commodity(:PY))
# PW = add!(m, Commodity(:PW))
# PL = add!(m, Commodity(:PL))
# PK = add!(m, Commodity(:PK))
# PKS = add!(m, Commodity(:PKS))
# PLS = add!(m, Commodity(:PLS))

# CONS = add!(m, Consumer(:CONS, benchmark=340.))

# TAU = add!(m, Aux(:TAU, benchmark=1.0))

# add!(m, Production(X, 0, 1.0, [Output(PX, 120.)], [Input(PLS, 48), Input(PKS, 72)]))
# add!(m, Production(Y, 0, 1.0, [Output(PY, 120.)], [Input(PLS, 72), Input(PKS, 48)]))
# add!(m, Production(W, 0, 0.7, [Output(PW, 340.)], [Input(Nest(:AW,1.0,240.,[Input(PX, 120), Input(PY, 120)]),240.), Input(PL,100.)]))

# # add!(m, Production(TL, 0., 1.0, [Output(PLS, 120.)], [Input(PL, 120.)]))
# # add!(m, Production(TK, 0., 1.0, [Output(PKS, 120.)], [Input(PK, 120.)]))
# add!(m, Production(TL, 0., 1.0, [Output(PLS, 120.)], [Input(PL, 100., [Tax(:(1.0*$txl*$TAU),CONS)])])) #If fails, scalar*$TAU works
# add!(m, Production(TK, 0., 1.0, [Output(PKS, 120.)], [Input(PK, 100., [Tax(:(1.0*$txk*$TAU),CONS)])]))

# add!(m, DemandFunction(CONS, 1., [Demand(PW,340.)], [Endowment(PL, 200.), Endowment(PK, 100)]))
# add!(m, AuxConstraint(TAU, :($W*$PW*340 - $PL * 200 - $PK * 100  == 40 * ($PX + $PY)/2)))

# set_fixed!(CONS, true)
# solve!(m, cumulative_iteration_limit=0)
# solve!(m)
# # algebraic_version(m)

# set_value(txl, 0.15)
# set_value(txk, 0.25)
# solve!(m)

# set_value(CONS,339.5832292)
# set_value(txl, 0.1)
# set_value(txk, 0.3)
# solve!(m)

# set_value(CONS,338.7151989)
# set_value(txl, 0.05)
# set_value(txk, 0.35)
# solve!(m)

# set_value(CONS,337.2894147)
# set_value(txl, 0.)
# set_value(txk, 0.4)
# solve!(m)

# set_value(CONS,335.0362347)
# set_value(txl, -0.05)
# set_value(txk, 0.45)
# solve!(m)


m = Model()
# A set up to test N: Endogenous taxes (and M: the multiplier), the Auxiliary Variable in Production blocks (applied to Outputs)       

sigma = add!(m,Parameter(:sigma, value=9.0))

X = add!(m, Sector(:X))
Y = add!(m, Sector(:Y))
W = add!(m, Sector(:W))

PX = add!(m, Commodity(:PX))
PY = add!(m, Commodity(:PY))
PW = add!(m, Commodity(:PW))
PL = add!(m, Commodity(:PL))
PK = add!(m, Commodity(:PK))

CONS = add!(m, Consumer(:CONS, benchmark=180.))

SHAREX = add!(m, Aux(:SHAREX, benchmark=0.5))
MARKUP = add!(m, Aux(:MARKUP, benchmark=0.2))

add!(m, Production(X, 0, 1.0, [Output(PX, 80., [Tax(:(1.0*$MARKUP), CONS)])], [Input(PL, 14), Input(PK, 50)]))
add!(m, Production(Y, 0, 1.0, [Output(PY, 100.)],                             [Input(PL, 60), Input(PK, 40)]))
add!(m, Production(W, 0, 9.0, [Output(PW, 180.)], [Input(PX,80), Input(PY,100.)]))

add!(m, DemandFunction(CONS, 1., [Demand(PW,180.)], [Endowment(PL, 74.), Endowment(PK, 90)]))
add!(m, AuxConstraint(SHAREX, :($SHAREX == 100*$PX*$X / (100*$PX*$X + 100*$PY*$Y))))
add!(m, AuxConstraint(MARKUP, :($MARKUP == 1 / ($sigma - ($sigma-1) * $SHAREX))))

set_fixed!(CONS, true)
solve!(m, cumulative_iteration_limit=0)

set_value(CONS,164.)
# set_fixed!(CONS, true)
set_value(MARKUP, 0.)
set_fixed!(MARKUP, true)
set_value(SHAREX, 0.5)
solve!(m)