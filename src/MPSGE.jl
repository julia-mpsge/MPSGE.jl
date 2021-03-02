module MPSGE

import JuMP, Complementarity, MacroTools
import JuMP: value, set_value

export add!, Model, solve!, algebraic_version
export Sector, Commodity, Consumer, Production, Demand, Endowment, Input, Parameter
export value, set_value, set_fixed!

include("model.jl")
include("build.jl")
include("algebraic_wrapper.jl")

end
