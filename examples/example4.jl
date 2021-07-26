using MPSGE
using MPSGE.JuMP.Containers

m = Model()

goods = [:g1, :g2]
factors = [:l, :k]
sectors = [:s1, :s2]

make0 = DenseAxisArray(Float64[6 2; 2 10], goods, sectors)
use0 = DenseAxisArray(Float64[4 2; 2 6], goods, sectors)
fd0 = DenseAxisArray(Float64[1 3; 1 1], factors, sectors)
c0 = DenseAxisArray(Float64[2, 4], goods)
e0 = DenseAxisArray(Float64[sum(fd0[f,:]) for f in factors], factors)

@parameter(m, endow, 1.0)

X = add!(m, Sector(:X, indices=(sectors,)))

P = add!(m, Commodity(:P, indices=(goods,)))
PF = add!(m, Commodity(:PF, indices=(factors,)))
Y = add!(m, Consumer(:Y, benchmark=sum(e0)))

for j in sectors
    @production(m, X[j], 1, [Output(P[i], make0[i,j]) for i in goods], [[Input(P[i], use0[i,j]) for i in goods]; [Input(PF[f], fd0[f,j]) for f in factors]])
end

@demand(m, Y, [Demand(P[i], c0[i]) for i in goods], [Endowment(PF[:k], e0[:k]), Endowment(PF[:l], :($endow * $(e0[:l])))])

solve!(m, cumulative_iteration_limit=0)
solve!(m)
set_value(endow, 1.1)
set_value(Y, 6.4)
set_fixed!(Y, true)

solve!(m)

algebraic_version(m)
