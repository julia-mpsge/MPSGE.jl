@testitem "TWOBYTWOwTax (indexed)" begin
using XLSX, MPSGE.JuMP.Containers

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

gams_results = XLSX.readxlsx(joinpath(@__DIR__, "MPSGEresults.xlsx"))
a_table = gams_results["TwoxTwowTax"][:]  # Generated from TwoByTwo_Scalar_wTax-MPSGE.gms, Tax at 0.2
two_by_two_scalar_results = DenseAxisArray(a_table[2:end,2:end],a_table[2:end,1],a_table[1,2:end])

@test MPSGE.Complementarity.result_value(m._jump_model[:Y][:x]) ≈ two_by_two_scalar_results["Y.L","benchmark"] # 1.
@test MPSGE.Complementarity.result_value(m._jump_model[:Y][:y]) ≈ two_by_two_scalar_results["X.L","benchmark"] # 1.
@test MPSGE.Complementarity.result_value(m._jump_model[:U]) ≈ two_by_two_scalar_results["U.L","benchmark"] # 1.
@test MPSGE.Complementarity.result_value(m._jump_model[:RA]) ≈ two_by_two_scalar_results["RA.L","benchmark"] # 187.5
@test MPSGE.Complementarity.result_value(m._jump_model[:PC][:x]) ≈ two_by_two_scalar_results["PX.L","benchmark"] # 1.
@test MPSGE.Complementarity.result_value(m._jump_model[:PC][:y]) ≈ two_by_two_scalar_results["PY.L","benchmark"] # 1.
@test MPSGE.Complementarity.result_value(m._jump_model[:PU]) ≈ two_by_two_scalar_results["PU.L","benchmark"] # 1.
@test MPSGE.Complementarity.result_value(m._jump_model[:PF][:l]) ≈ two_by_two_scalar_results["PL.L","benchmark"] # 1.
@test MPSGE.Complementarity.result_value(m._jump_model[:PF][:k]) ≈ two_by_two_scalar_results["PK.L","benchmark"] # 1.
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PF[l]†Y[x]")]) ≈ two_by_two_scalar_results["DXL.L","benchmark"] # 50.
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PF[l]†Y[y]")]) ≈ two_by_two_scalar_results["DYL.L","benchmark"] # 20.
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PF[k]†Y[x]")]) ≈ two_by_two_scalar_results["DXL.L","benchmark"] # 50.
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PF[k]†Y[y]")]) ≈ two_by_two_scalar_results["DYK.L","benchmark"] # 30.
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PC[x]†U")]) ≈ two_by_two_scalar_results["DUX.L","benchmark"] # 125.
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PC[y]†U")]) ≈ two_by_two_scalar_results["DUY.L","benchmark"] # 62.5
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PC[x]‡Y[x]")]) ≈ two_by_two_scalar_results["SX.L","benchmark"] # 125.
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PC[y]‡Y[y]")]) ≈ two_by_two_scalar_results["SY.L","benchmark"] # 62.5
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PU‡U")]) ≈ two_by_two_scalar_results["DU.L","benchmark"] # 187.5
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PUρRA")]) ≈ two_by_two_scalar_results["SU.L","benchmark"] # 187.5

#Counterfactual 1, increase labour endowment by 10%, default normalisation of price: fix RA income at initial prices
set_fixed!(PC[:x], false) # unfix, seems to be automatic with new numeraire in MPSGE
set_value(endow[:l], 1.1)
# In the original indexed, endow[:l] = 1.1*endow[:l]
set_fixed!(RA, true)
solve!(m)

@test MPSGE.Complementarity.result_value(m._jump_model[:Y][:x]) ≈ two_by_two_scalar_results["Y.L","RA=157"] # 
@test MPSGE.Complementarity.result_value(m._jump_model[:Y][:y]) ≈ two_by_two_scalar_results["X.L","RA=157"] # 
@test MPSGE.Complementarity.result_value(m._jump_model[:U]) ≈ two_by_two_scalar_results["U.L","RA=157"] # 
@test MPSGE.Complementarity.result_value(m._jump_model[:RA]) ≈ two_by_two_scalar_results["RA.L","RA=157"] # 
@test MPSGE.Complementarity.result_value(m._jump_model[:PC][:x]) ≈ two_by_two_scalar_results["PX.L","RA=157"] # 
@test MPSGE.Complementarity.result_value(m._jump_model[:PC][:y]) ≈ two_by_two_scalar_results["PY.L","RA=157"] # 
@test MPSGE.Complementarity.result_value(m._jump_model[:PU]) ≈ two_by_two_scalar_results["PU.L","RA=157"] # 
@test MPSGE.Complementarity.result_value(m._jump_model[:PF][:l]) ≈ two_by_two_scalar_results["PL.L","RA=157"] # 
@test MPSGE.Complementarity.result_value(m._jump_model[:PF][:k]) ≈ two_by_two_scalar_results["PK.L","RA=157"] # 
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PF[l]†Y[x]")]) ≈ two_by_two_scalar_results["DXL.L","RA=157"] # 
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PF[l]†Y[y]")]) ≈ two_by_two_scalar_results["DYL.L","RA=157"] # 
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PF[k]†Y[x]")]) ≈ two_by_two_scalar_results["DXL.L","RA=157"] # 
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PF[k]†Y[y]")]) ≈ two_by_two_scalar_results["DYK.L","RA=157"] # 
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PC[x]†U")]) ≈ two_by_two_scalar_results["DUX.L","RA=157"] # 
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PC[y]†U")]) ≈ two_by_two_scalar_results["DUY.L","RA=157"] # 
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PC[x]‡Y[x]")]) ≈ two_by_two_scalar_results["SX.L","RA=157"] # 
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PC[y]‡Y[y]")]) ≈ two_by_two_scalar_results["SY.L","RA=157"] # 
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PU‡U")]) ≈ two_by_two_scalar_results["DU.L","RA=157"] # 
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PUρRA")]) ≈ two_by_two_scalar_results["SU.L","RA=157"] # 

#Counterfactual 2, fix price of x as numeraire, unfix RA
set_fixed!(RA, false)
set_fixed!(PC[:x], true)
solve!(m)

@test MPSGE.Complementarity.result_value(m._jump_model[:Y][:x]) ≈ two_by_two_scalar_results["Y.L","PX=1"] # 
@test MPSGE.Complementarity.result_value(m._jump_model[:Y][:y]) ≈ two_by_two_scalar_results["X.L","PX=1"] # 
@test MPSGE.Complementarity.result_value(m._jump_model[:U]) ≈ two_by_two_scalar_results["U.L","PX=1"] # 
@test MPSGE.Complementarity.result_value(m._jump_model[:RA]) ≈ two_by_two_scalar_results["RA.L","PX=1"] # 
@test MPSGE.Complementarity.result_value(m._jump_model[:PC][:x]) ≈ two_by_two_scalar_results["PX.L","PX=1"] # 
@test MPSGE.Complementarity.result_value(m._jump_model[:PC][:y]) ≈ two_by_two_scalar_results["PY.L","PX=1"] # 
@test MPSGE.Complementarity.result_value(m._jump_model[:PU]) ≈ two_by_two_scalar_results["PU.L","PX=1"] # 
@test MPSGE.Complementarity.result_value(m._jump_model[:PF][:l]) ≈ two_by_two_scalar_results["PL.L","PX=1"] # 
@test MPSGE.Complementarity.result_value(m._jump_model[:PF][:k]) ≈ two_by_two_scalar_results["PK.L","PX=1"] # 
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PF[l]†Y[x]")]) ≈ two_by_two_scalar_results["DXL.L","PX=1"] # 
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PF[l]†Y[y]")]) ≈ two_by_two_scalar_results["DYL.L","PX=1"] # 
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PF[k]†Y[x]")]) ≈ two_by_two_scalar_results["DXL.L","PX=1"] # 
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PF[k]†Y[y]")]) ≈ two_by_two_scalar_results["DYK.L","PX=1"] # 
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PC[x]†U")]) ≈ two_by_two_scalar_results["DUX.L","PX=1"] # 
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PC[y]†U")]) ≈ two_by_two_scalar_results["DUY.L","PX=1"] # 
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PC[x]‡Y[x]")]) ≈ two_by_two_scalar_results["SX.L","PX=1"] # 
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PC[y]‡Y[y]")]) ≈ two_by_two_scalar_results["SY.L","PX=1"] # 
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PU‡U")]) ≈ two_by_two_scalar_results["DU.L","PX=1"] # 
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PUρRA")]) ≈ two_by_two_scalar_results["SU.L","PX=1"] # 

#Counterfactual #3 Use wages/labour price as numeraire
set_fixed!(PC[:x], false)
set_fixed!(PF[:l], true)
solve!(m)

@test MPSGE.Complementarity.result_value(m._jump_model[:Y][:x]) ≈ two_by_two_scalar_results["Y.L","PL=1"] # 
@test MPSGE.Complementarity.result_value(m._jump_model[:Y][:y]) ≈ two_by_two_scalar_results["X.L","PL=1"] # 
@test MPSGE.Complementarity.result_value(m._jump_model[:U]) ≈ two_by_two_scalar_results["U.L","PL=1"] # 
@test MPSGE.Complementarity.result_value(m._jump_model[:RA]) ≈ two_by_two_scalar_results["RA.L","PL=1"] # 
@test MPSGE.Complementarity.result_value(m._jump_model[:PC][:x]) ≈ two_by_two_scalar_results["PX.L","PL=1"] # 
@test MPSGE.Complementarity.result_value(m._jump_model[:PC][:y]) ≈ two_by_two_scalar_results["PY.L","PL=1"] # 
@test MPSGE.Complementarity.result_value(m._jump_model[:PU]) ≈ two_by_two_scalar_results["PU.L","PL=1"] # 
@test MPSGE.Complementarity.result_value(m._jump_model[:PF][:l]) ≈ two_by_two_scalar_results["PL.L","PL=1"] # 
@test MPSGE.Complementarity.result_value(m._jump_model[:PF][:k]) ≈ two_by_two_scalar_results["PK.L","PL=1"] # 
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PF[l]†Y[x]")]) ≈ two_by_two_scalar_results["DXL.L","PL=1"] # 
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PF[l]†Y[y]")]) ≈ two_by_two_scalar_results["DYL.L","PL=1"] # 
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PF[k]†Y[x]")]) ≈ two_by_two_scalar_results["DXL.L","PL=1"] # 
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PF[k]†Y[y]")]) ≈ two_by_two_scalar_results["DYK.L","PL=1"] # 
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PC[x]†U")]) ≈ two_by_two_scalar_results["DUX.L","PL=1"] # 
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PC[y]†U")]) ≈ two_by_two_scalar_results["DUY.L","PL=1"] # 
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PC[x]‡Y[x]")]) ≈ two_by_two_scalar_results["SX.L","PL=1"] # 
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PC[y]‡Y[y]")]) ≈ two_by_two_scalar_results["SY.L","PL=1"] # 
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PU‡U")]) ≈ two_by_two_scalar_results["DU.L","PL=1"] # 
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PUρRA")]) ≈ two_by_two_scalar_results["SU.L","PL=1"] # 

algebraic_version(m)

end