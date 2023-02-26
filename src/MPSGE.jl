module MPSGE

import JuMP, Complementarity, MacroTools
import JuMP: value, set_value, Containers
import JuMP.Containers: DenseAxisArray

export add!, Model, solve!, algebraic_version
export Sector, Commodity, Consumer, Aux, Production, DemandFunction, AuxConstraint, Endowment, Input, Output, Parameter, Demand
export value, set_value, get_value, set_fixed!
export @parameter, @sector, @commodity, @consumer, @production, @demand

include("model.jl")
include("macros.jl")
include("build/build_helpers.jl")
include("build/build_variables.jl")
include("build/build_implicitconstraints.jl")
include("build/build_zeroprofit.jl")
include("build/build_marketclearance.jl")
include("build/build_incomebalance.jl")
include("build/build_auxconstraints.jl")
include("build/build_startvalues_bounds.jl")
include("build/build.jl")
include("algebraic_wrapper.jl")

end
