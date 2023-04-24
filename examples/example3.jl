using MPSGE
using MPSGE.JuMP.Containers
# A replication of the Two By Two, with indexing, from https://www.gams.com/34/docs/UG_MPSGE_Intro.html#UG_MPSGE_Intro_Appendix_twobytwo1
m = Model()

goods = [:x, :y]
factors = [:l, :k]

factor = DenseAxisArray(Float64[50 50; 20 30], goods, factors)
supply = DenseAxisArray(Float64[100, 50], goods)
outtax = add!(m, Parameter(:outtax, indices=(goods,), value=0.))
intax  = add!(m, Parameter(:intax,  indices=(goods,), value=0.))
endow  = add!(m, Parameter(:endow,  indices=(factors,), value=1.0))

Y = add!(m, Sector(:Y, indices=(goods,)))
U = add!(m, Sector(:U))

PC = add!(m, Commodity(:PC, indices=(goods,)))
PU = add!(m, Commodity(:PU))
PF = add!(m, Commodity(:PF, indices=(factors,)))

RA = add!(m, Consumer(:RA, benchmark = 150.))

for i in goods
    @production(m, Y[i], 0, 1, [Output(PC[i], supply[i], [Tax(:(1 * $(outtax[i])), RA)])], [Input(PF[:l], factor[i,:l], [Tax(:(1 * $(intax[i])), RA)]), Input(PF[:k], factor[i,:k])])
end
# @production(m, [i in goods], Y[i], 1, PC[i], supply[i],  [Input(PF[f], factor[i,f]) for f in factors])

@production(m, U,0, 1, [Output(PU, 150)], [Input(PC[:x], 100), Input(PC[:y], 50)])

@demand(m, RA, 1., [Demand(PU, 150)], [Endowment(PF[:l], :(70 * $(endow[:l]))), Endowment(PF[:k], :(80. * $(endow[:k])))])

set_fixed!(PC[:x], true) # Set sector x as the numeraire
solve!(m, cumulative_iteration_limit=0)
solve!(m)
algebraic_version(m)

#Counterfactual 1, increase labour endowment by 10%, default normalisation of price: fix RA income at initial prices
set_fixed!(PC[:x], false) # unfix, seems to be automatic with new numeraire in MPSGE
set_value(endow[:l], 1.1.*get_value(endow[:l]))
# In the original indexed, endow[:l] = 1.1*endow[:l]
set_fixed!(RA, true)
solve!(m)

#Counterfactual 2, fix price of x as numeraire, unfix RA
set_fixed!(RA, false)
set_fixed!(PC[:x], true)
solve!(m)

#Counterfactual #3 Use wages/labour price as numeraire
set_fixed!(PC[:x], false)
set_fixed!(PF[:l], true)
solve!(m)

set_value(outtax[:x], 0.1)
solve!(m)

set_value(outtax[:x], 0.0)
set_value(intax[:x], 0.1)
solve!(m)
algebraic_version(m)
