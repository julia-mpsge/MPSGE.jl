using MPSGE, MPSGE.JuMP.Containers
    
m = Model()
goods = [:x, :y]
factors = [:l, :k]
consumers = [:ra]
factor = DenseAxisArray(Float64[50 50; 20 30], goods, factors)
supply = DenseAxisArray(Float64[100, 50], goods)
endow = add!(m, Parameter(:endow, indices=(factors,), value=1.0)) 
outax = add!(m, Parameter(:outax, indices=(goods,), value=0.))
intax = add!(m, Parameter(:intax, indices=(goods,), value=0.))

Y = add!(m, Sector(:Y, indices=(goods,)))
U = add!(m, Sector(:U))
PC = add!(m, Commodity(:PC, indices=(goods,)))
PU = add!(m, Commodity(:PU))
PF = add!(m, Commodity(:PF, indices=(factors,)))
C = add!(m, Consumer(:C, indices=(consumers,), benchmark=150.))

for i in goods
    @production(m, Y[i], 0, 1, [Output(PC[i], supply[i], [Tax(:(1 * $(outax[i])), C[:ra])])], [Input(PF[:l], factor[i,:l], [Tax(:(1 * $(intax[i])), C[:ra])]), Input(PF[:k], factor[i,:k])])
end
@production(m, U, 0, 1, [Output(PU, 150)], [Input(PC[:x], 100), Input(PC[:y], 50)])
@demand(m, C[:ra], 1., [Demand(PU, 150)], [Endowment(PF[:l], :(70 * $(endow[:l]))), Endowment(PF[:k], :(80. * $(endow[:k])))])
add!(m, DemandFunction(C[:ra], 1., [Demand(PU, 150)], [Endowment(PF[:l], :(70 * $(endow[:l]))), Endowment(PF[:k], :(80. * $(endow[:k])))]))

solve!(m, cumulative_iteration_limit=0)
