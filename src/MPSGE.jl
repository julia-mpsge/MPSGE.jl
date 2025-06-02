module MPSGE

using JuMP, DataFrames, PATHSolver

import JuMP.Containers:DenseAxisArray

import OrderedCollections:OrderedDict

include("structs.jl")
include("arithmetic.jl")
include("show.jl")
include("model.jl")


include("macros.jl")
include("macros/@parameter.jl")
include("macros/nests.jl")
include("macros/@netput.jl")
include("macros/@production.jl")
include("macros/@MPSGEvariable.jl")

include("build.jl")
include("report.jl")

include("convenience_functions.jl")

#Structs
export  MPSGEModel, 
        ScalarSector,    IndexedSector,    Sector, 
        ScalarCommodity, IndexedCommodity, Commodity, 
        ScalarConsumer,  IndexedConsumer,  Consumer, 
        ScalarParameter, IndexedParameter, Parameter,
        ScalarAuxiliary, IndexedAuxiliary, Auxiliary,
        ScalarNest,      IndexedNest,      Nest,
        Tax, Input, Output,
        Production,
        ScalarFinalDemand, ScalarEndowment, ScalarDemand,
        ScalarAuxConstraint

#Struct access
export  name, quantity, production, jump_model, sectors, commodities,
        consumers, taxes, sector, commodity, consumer, description,
        set_value!, value, auxiliaries, parameters

#Production
export cost_function, revenue_function, input, output

#Model
export  add_variable!, add!, add_sector!, add_commodity!, add_consumer!,
        get_variable, add_production!, add_demand!, add_parameter!,
        add_auxiliary!, add_aux_constraint!

#Macros
export  @sector,    @sectors, 
        @commodity, @commodities, 
        @consumer,  @consumers,  
        @parameter, @parameters,
        @auxiliary, @auxiliaries,
        @production, @demand,
        @aux_constraint,
        @output, @input,
        @final_demand, @endowment

#Building
export  compensated_demand, tau, demand, endowment,
        zero_profit, market_clearance, income_balance

#Reporting
export generate_report, solve!

#Convenience
export  value, fix, unfix, is_fixed, 
        set_start_value, start_value, 
        set_silent, unset_silent, set_lower_bound, set_upper_bound,
        lower_bound, upper_bound

end
