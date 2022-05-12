using MPSGE
# A replication of Model M1_2S: Closed 2X2 Economy with Intermediate Inputs and *Nesting* from https://www.gamsworld.org/mpsge/debreu/markusen/m1.htm#M1_2S
m = Model()

@sector(m, X)
@sector(m, Y)
@sector(m, W)

@commodity(m, PX)
@commodity(m, PY)
@commodity(m, PW)
@commodity(m, PL)
@commodity(m, PK)

@consumer(m, CONS, benchmark=200.)

# Elasticity of substituion for X: VA (L and K) vs Y -> 0.5, L vs K -> Cobb-Douglas (=1?)
@production(m, X, 1, [Output(PX, 120)], [Input(PY,20),[Input(PL, 40), Input(PK, 60)]])
# Elasticity of substitution for Y: VA (L and K) vs Y -> 0.75, L vs K -> (=1?)
@production(m, Y, 1, [Output(PY, 120)], [Input(PY, 20),[Input(PL, 60), Input(PK, 40)]])
@production(m, W, 1, [Output(PW, 200)], [Input(PX, 100), Input(PY, 100)])

@demand(m, CONS, [Demand(PW, 200)], [Endowment(PL, 100), Endowment(PK, 100)])

solve!(m, cumulative_iteration_limit=0)
solve!(m)

set_fixed!(PL, true)
solve!(m)

algebraic_version(m)