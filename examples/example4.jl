using MPSGE
using MPSGE.JuMP.Containers
#A replication of the JPMGE from https://www.gams.com/34/docs/UG_MPSGE_Intro.html#UG_MPSGE_Intro_Appendix_jpmge
m = Model()

goods = [:g1, :g2]
factors = [:l, :k]
sectors = [:s1, :s2]

make0 = DenseAxisArray(Float64[6 2; 2 10], goods, sectors)
use0 = DenseAxisArray(Float64[4 2; 2 6], goods, sectors)
fd0 = DenseAxisArray(Float64[1 3; 1 1], factors, sectors)
c0 = DenseAxisArray(Float64[2, 4], goods)
e0 = DenseAxisArray(Float64[sum(fd0[f,:]) for f in factors], factors)

endow = add!(m, Parameter(:endow, indices=(factors,), value=1.0))

X = add!(m, Sector(:X, indices=(sectors,)))

P = add!(m, Commodity(:P, indices=(goods,)))
PF = add!(m, Commodity(:PF, indices=(factors,)))
Y = add!(m, Consumer(:Y, benchmark=sum(e0)))

for j in sectors
    @production(m, X[j], 0, 1, [Output(P[i], make0[i,j]) for i in goods], [[Input(P[i], use0[i,j]) for i in goods]; [Input(PF[f], fd0[f,j]) for f in factors]])
end

@demand(m, Y, [Demand(P[i], c0[i]) for i in goods], [Endowment(PF[:k], :($(endow[:k]) * $(e0[:k]))), Endowment(PF[:l], :($(endow[:l]) * $(e0[:l])))])

solve!(m, cumulative_iteration_limit=0)
solve!(m)
algebraic_version(m)
#Counterfactual 1: 10% increase in labor endowment. Fix the income level at the default level, i.e. the income level corresponding to the counterfactual endowment at benchmark price
set_value(endow[:l], 1.1)
fd1 = fd0 .* convert(Vector, get_value.(endow))
set_value(Y, sum(DenseAxisArray(Float64[sum(fd1[f,:]) for f in factors], factors)))
set_fixed!(Y, true)

solve!(m)

#Counterfactual 2: Fix a numeraire price index and recalculate:
set_fixed!(Y,false)
set_fixed!(P[:g1], true)
solve!(m)

#Counterfactual 3: Recalculate with a different numeraire. "Unfix" the price of X and fix the wage rate:
set_fixed!(P[:g1], false)
set_fixed!(PF[:l], true)
solve!(m)

algebraic_version(m)