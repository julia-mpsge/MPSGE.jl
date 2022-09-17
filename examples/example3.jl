using MPSGE
using MPSGE.JuMP.Containers

# A replication of the Two By Two, with indexing, from https://www.gams.com/34/docs/UG_MPSGE_Intro.html#UG_MPSGE_Intro_Appendix_twobytwo1
m = Model()

goods = [:x, :y]
factors = [:l, :k]

factor = DenseAxisArray(Float64[50 50; 20 30], goods, factors)
supply = DenseAxisArray(Float64[100, 50], goods)

endow = add!(m, Parameter(:endow, indices=(factors,), value=1.0))

Y = add!(m, Sector(:Y, indices=(goods,)))
U = add!(m, Sector(:U))

PC = add!(m, Commodity(:PC, indices=(goods,)))
PU = add!(m, Commodity(:PU))
PF = add!(m, Commodity(:PF, indices=(factors,)))

RA = add!(m, Consumer(:RA, benchmark = 150.))

for i in goods
    @production(m, Y[i], 0, 1, [Output(PC[i], supply[i])], [Input(PF[:l], factor[i,:l]), Input(PF[:k], factor[i,:k])])
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
algebraic_version(m)


# A replication of the Two By Two, with an output Tax and indexing, from https://www.gams.com/34/docs/UG_MPSGE_Intro.html#UG_MPSGE_Intro_Appendix_twobytwo1
m = Model()

goods = [:x, :y]
factors = [:l, :k]

endow  = add!(m, Parameter(:endow,  indices=(factors,), value=1.0))
# outtax = add!(m, Parameter(:outtax, value = 0.2))
outtax2 = 0.2 # other options that work in the GAMS tax script at 0.0 and 0.6

factor = DenseAxisArray(Float64[50 50; 20 30], goods, factors)
# factor = DenseAxisArray(Float64[:(50 - 100 * $(outtax)) 50; 20 :(30-50*$(outtax))], goods, factors) # syntax doesn't work yet, plus not needed - this doesn't change

supply = DenseAxisArray(Float64[100*(1/(1-outtax2)), 50*(1/(1-outtax2))], goods)
# supply = DenseAxisArray(Float64[125, 62.5], goods)

Y = add!(m, Sector(:Y, indices=(goods,)))
U = add!(m, Sector(:U))

PC = add!(m, Commodity(:PC, indices=(goods,)))
PU = add!(m, Commodity(:PU))
PF = add!(m, Commodity(:PF, indices=(factors,)))

RA = add!(m, Consumer(:RA, benchmark = 150. *(1/(1-outtax2)) ))# * $(outtax))))
# RA = add!(m, Consumer(:RA, benchmark = 187.5))

for i in goods
    @production(m, Y[i], 0, 1, [Output(PC[i], supply[i], [MPSGE.Tax(outtax2, RA)])], [Input(PF[:l], factor[i,:l]), Input(PF[:k], factor[i,:k])])
end
# for i in goods
#     @production(m, Y[i], 0, 1, [Output(PC[i], supply[i], [MPSGE.Tax(0.2, RA)])], [Input(PF[:l], factor[i,:l]), Input(PF[:k], factor[i,:k])])
# end

# @production(m, [i in goods], Y[i], 1, PC[i], supply[i],  [Input(PF[f], factor[i,f]) for f in factors])

@production(m, U, 0, 1, [Output(PU, 150*(1/(1-outtax2)))], [Input(PC[:x], 100*(1/(1-outtax2))), Input(PC[:y], 50*(1/(1-outtax2)))])
# @production(m, U, 0, 1, [Output(PU, 187.5)], [Input(PC[:x], 125), Input(PC[:y], 62.5)])

@demand(m, RA, 1., [Demand(PU, (150. *(1/(1-outtax2))))], [Endowment(PF[:l], :(70 * $(endow[:l]))), Endowment(PF[:k], :(80 * $(endow[:k])))])
# @demand(m, RA, 1., [Demand(PU, 187.5)], [Endowment(PF[:l], :(70 * $(endow[:l]))), Endowment(PF[:k], :(80 * $(endow[:k])))])
# @demand(m, RA, 1., [Demand(PU, 150)], [Endowment(PF[:l], :((70-100*$(outtax)) * $(endow[:l]))), Endowment(PF[:k], :((80.0 -50*$(outtax)) * $(endow[:k])))])

set_fixed!(PC[:x], true) # Set sector x as the numeraire
solve!(m, cumulative_iteration_limit=0)
solve!(m)
algebraic_version(m)

#Counterfactual 1, increase labour endowment by 10%, default normalisation of price: fix RA income at initial prices
set_fixed!(PC[:x], false) # unfix, seems to be automatic with new numeraire in MPSGE
set_value(endow[:l], 1.1)
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
algebraic_version(m)