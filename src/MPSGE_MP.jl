module MPSGE_MP

using JuMP, DataFrames, PATHSolver

import JuMP.Containers:DenseAxisArray

include("structs.jl")
include("show.jl")
include("model.jl")
include("production.jl")


include("macros.jl")
#include("prune.jl")

#include("build.jl")
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
        Node, Production,
        ScalarDem, ScalarEndowment, ScalarDemand,
        ScalarAuxConstraint

#Struct access
export  name, quantity, production, jump_model, sectors, commodities,
        consumers, taxes, sector, commodity, consumer, description,
        set_value!, value, auxiliaries, parameters#, cost_function


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
export  build!, compensated_demand_dictionary, compensated_demand, tau, 
        demand, endowment

#Reporting
export generate_report, solve!

#Convenience
export value, fix, unfix, set_start_value

end
