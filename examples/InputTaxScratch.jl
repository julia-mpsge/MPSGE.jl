using MPSGE

# A replication of the Two By Two Scalar, with an output Tax in counterfactual: TwoByTwo_Scalar_wTax_MPSGE.gms
m = Model()

esub_x = add!(m, Parameter(:esub_x, value=1.))    
esub_y = add!(m, Parameter(:esub_y, value=1.))    
endow  = add!(m, Parameter(:endow, value=1.0))
Otax   = add!(m, Parameter(:Otax, value = 0.0))
Itax   = add!(m, Parameter(:Itax, value = 0.0))


X = add!(m, Sector(:X))
Y = add!(m, Sector(:Y))
U = add!(m, Sector(:U))

PX = add!(m, Commodity(:PX))
PY = add!(m, Commodity(:PY))
PU = add!(m, Commodity(:PU))
PL = add!(m, Commodity(:PL))
PK = add!(m, Commodity(:PK))

RA = add!(m, Consumer(:RA, benchmark = 150.))
# RA = add!(m, Consumer(:RA, benchmark = 200.))

@production(m, X, 0, :($esub_x*1.0), [Output(PX, 100., [MPSGE.Tax(:($Otax*1.0), RA)])], [Input(PL, 50. , [MPSGE.Tax(:($Itax*1.0), RA)]), Input(PK,50. , [MPSGE.Tax(:($Itax*1.0), RA)])])
# @production(m, X, 0, :($esub_x*1.0), [Output(PX, 70., [MPSGE.Tax(:($Otax*1.0), RA)])], [Input(PL, 70. , [MPSGE.Tax(:($Itax*1.0), RA)])])
# @production(m, X, 2, :($esub_x*1.0), [Output(PX, 80., [MPSGE.Tax(:($Otax*1.0), RA)]), Output(PY, 20.)], [Input(PL, 40. , [MPSGE.Tax(:($Itax*1.0), RA)]), Input(PK,60. , [MPSGE.Tax(:($Itax*1.0), RA)])])
@production(m, Y, 0, :($esub_y*1.0), [Output(PY, 50.)], [Input(PL, 20.), Input(PK,30.)])
# @production(m, Y, 0, :($esub_y*1.0), [Output(PY, 80.)], [Input(PK, 80.)])
# @production(m, Y, 0, :($esub_y*1.0), [Output(PY, 80.), Output(PX, 20.)], [Input(PL, 60.), Input(PK,40.)])
# @production(m, Y, 0, :($esub_y*1.0), [Output(PY, 50.,  [MPSGE.Tax(:($Otax*1.0), RA)])], [Input(PL, 20.), Input(PK,30.)])
# @production(m, U, 0, 1.0, [Output(PU, 150.)], [Input(PX, 70.), Input(PY,80.)])
@production(m, U, 0, 1.0, [Output(PU, 150.)], [Input(PX, 100.), Input(PY,50.)])

@demand(m, RA, 1., [Demand(PU, 150. )], [Endowment(PL, :(70. * $(endow))), Endowment(PK, 80.)])
# @demand(m, RA, 1., [Demand(PU, 200. )], [Endowment(PL, 100), Endowment(PK, 100)])

solve!(m, cumulative_iteration_limit=0)

set_value(endow, 1.1)
# set_fixed!(RA, true)
# solve!(m)

# set_fixed!(PX, true)
# # set_fixed!(PU, true)

# set_fixed!(RA, false)
# solve!(m)

# set_fixed!(PX, false)
set_fixed!(PL, true)
# solve!(m)

# set_value(Otax, 0.1)
# set_value(Itax, 0.)
# solve!(m)

set_value(Otax, 0.)
set_value(Itax, 0.1)
solve!(m)


