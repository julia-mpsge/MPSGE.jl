module MPSGE


import JuMP, MacroTools, PATHSolver, PrettyTables, CSV, DataFrames
import JuMP: value, set_value, Containers, set_lower_bound, set_upper_bound, @constraint, @expression, MOI
import DataFrames: DataFrame
import CSV: File

import JuMP.Containers: DenseAxisArray

export add!, Model, solve!, algebraic_version, algebraic_version_main, constraint_values
export Sector, Commodity, Consumer, Aux, Production, DemandFunction, AuxConstraint, Endowment, Input, Output, Parameter, Demand, Tax, Nest
export value, set_value, get_value, set_fixed!, get_nested_commodity, set_lower_bound, set_upper_bound
export @parameter, @sector, @commodity, @consumer, @production, @demand
export var_report, PATH_var, generate_name

include("model.jl")
include("macros.jl")
include("build/build_helpers.jl")
include("build/build_variables.jl")
include("build/build_implicitexpressions.jl")
include("build/build_zeroprofit.jl")
include("build/build_marketclearance.jl")
include("build/build_incomebalance.jl")
include("build/build_auxconstraints.jl")
include("build/build_startvalues_bounds.jl")
include("build/build.jl")
include("algebraic_wrapper.jl")
include("show.jl")

end
