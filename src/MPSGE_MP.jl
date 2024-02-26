module MPSGE_MP

using JuMP, DataFrames, PATHSolver

include("structs.jl")
include("show.jl")
include("model.jl")

include("macros.jl")
include("prune.jl")

include("build.jl")
include("report.jl")

#Structs
export  MPSGEModel, 
        ScalarSector,    IndexedSector,    Sector, 
        ScalarCommodity, IndexedCommodity, Commodity, 
        ScalarConsumer,  IndexedConsumer,  Consumer, 
        Tax, ScalarInput, ScalarOutput,
        ScalarNest, ScalarProduction,
        ScalarDem, ScalarEndowment, ScalarDemand

#Struct access
export  name, quantity, production, jump_model, sectors, commodities,
        consumers, taxes, sector, commodity, consumer


#Model
export  add_variable!, add!, add_sector!, add_commodity!, add_consumer!,
        get_variable, add_production!, add_demand!

#Macros
export  @sector, @sectors, @commodity, @commodities, @consumer,
        @consumers, @production

#Building
export  build!, compensated_demand_dictionary, compensated_demand, tau, 
        demand, endowment

#Reporting
export generate_report, solve!

end
