module MPSGE

import JuMP, Complementarity, MacroTools
import JuMP: value, set_value, Containers

export add!, Model, solve!, algebraic_version
export Sector, Commodity, Consumer, Production, DemandFunction, Endowment, Input, Output, Parameter, Demand
export value, set_value, set_fixed!
export @parameter, @sector, @commodity, @consumer, @production, @demand

include("model.jl")
include("macros.jl")
include("build.jl")
include("algebraic_wrapper.jl")

end
