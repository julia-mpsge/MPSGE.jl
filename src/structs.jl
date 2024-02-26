############################
## Initial Abstract Types ##
############################

abstract type AbstractMPSGEModel end

abstract type MPSGEVariable end

abstract type MPSGEIndexedVariable <: MPSGEVariable end
abstract type MPSGEScalarVariable <: MPSGEVariable end

abstract type ScalarNetput end
abstract type IndexedNetput end

const Netput = Union{ScalarNetput,IndexedNetput}

abstract type AbstractNest end;


####################
## Variable Types ##
####################

#Getters
name(V::MPSGEVariable) = V.name
model(V::MPSGEVariable) = V.model

Base.getindex(S::MPSGEIndexedVariable, index...) = S.subsectors[index...]

subindex(V::MPSGEScalarVariable) = V.subindex




struct ScalarSector <: MPSGEScalarVariable
    model::AbstractMPSGEModel
    name::Symbol
    subindex::Any
    function ScalarSector(model::AbstractMPSGEModel,name::Symbol) 
        S = new(model,name,missing)
        return S
    end
    ScalarSector(model::AbstractMPSGEModel,name::Symbol,subindex) = new(model,name,subindex)
end

struct IndexedSector <: MPSGEIndexedVariable
    model::AbstractMPSGEModel
    name::Symbol
    subsectors::Any
    index::Any
    function IndexedSector(model::AbstractMPSGEModel,name::Symbol,index) 
        temp_array = Array{ScalarSector}(undef, length.(index)...)

        for i in CartesianIndices(temp_array)
            temp_array[i] = ScalarSector(model, name, Tuple(index[j][v] for (j,v) in enumerate(Tuple(i))))
        end
        
        sr = JuMP.Containers.DenseAxisArray(temp_array, index...)
        S = new(model,name, sr, index)
        return S
    end
end

const Sector = Union{ScalarSector,IndexedSector}

struct ScalarCommodity <: MPSGEScalarVariable
    model::AbstractMPSGEModel
    name::Symbol
    subindex::Any
    function ScalarCommodity(model::AbstractMPSGEModel,name::Symbol) 
        S = new(model,name,missing)
        
        return S
    end
    ScalarCommodity(model::AbstractMPSGEModel,name::Symbol,subindex) = new(model,name,subindex)
end

struct IndexedCommodity <: MPSGEIndexedVariable
    model::AbstractMPSGEModel
    name::Symbol
    subsectors::Any
    index::Any
    function IndexedCommodity(model::AbstractMPSGEModel,name::Symbol,index) 
        temp_array = Array{ScalarCommodity}(undef, length.(index)...)

        for i in CartesianIndices(temp_array)
            temp_array[i] = ScalarCommodity(model, name, Tuple(index[j][v] for (j,v) in enumerate(Tuple(i))))
        end
        
        sr = JuMP.Containers.DenseAxisArray(temp_array, index...)
        S = new(model,name, sr, index)
        return S
    end
end

const Commodity = Union{ScalarCommodity,IndexedCommodity}


struct ScalarConsumer <: MPSGEScalarVariable
    model::AbstractMPSGEModel
    name::Symbol
    subindex::Any
    function ScalarConsumer(model::AbstractMPSGEModel,name::Symbol) 
        S = new(model,name,missing)
        
        return S
    end
    ScalarConsumer(model::AbstractMPSGEModel,name::Symbol,subindex) = new(model,name,subindex)
end

struct IndexedConsumer <: MPSGEIndexedVariable
    model::AbstractMPSGEModel
    name::Symbol
    subsectors::Any
    index::Any
    function IndexedConsumer(model::AbstractMPSGEModel,name::Symbol,index) 
        temp_array = Array{ScalarConsumer}(undef, length.(index)...)

        for i in CartesianIndices(temp_array)
            temp_array[i] = ScalarConsumer(model, name, Tuple(index[j][v] for (j,v) in enumerate(Tuple(i))))
        end
        
        sr = JuMP.Containers.DenseAxisArray(temp_array, index...)
        S = new(model,name, sr, index)
        return S
    end
end

const Consumer = Union{ScalarConsumer,IndexedConsumer}


####################
## Tree Structure ##
####################

# Getters
commodity(C::ScalarNetput) = C.commodity
base_quantity(N::ScalarNetput) = N.quantity
reference_price(N::ScalarNetput) = N.reference_price
quantity(N::ScalarNetput) = base_quantity(N)*reference_price(N)
taxes(N::ScalarNetput) = N.taxes
name(N::ScalarNetput) = name(commodity(N))
parent(N::ScalarNetput) = N.parent
children(N::ScalarNetput) = []

quantity(N::AbstractNest) = N.quantity
base_quantity(N::AbstractNest) = N.quantity
name(N::AbstractNest) = N.name
children(N::AbstractNest) = N.children
parent(N::AbstractNest) = ismissing(N.parent) ? N : N.parent
elasticity(N::AbstractNest) = N.elasticity


# Small Setter
set_parent(child::AbstractNest,parent::AbstractNest) = (child.parent = parent)
set_parent(child::ScalarNetput,parent::AbstractNest) = (child.parent = parent)

struct Tax
    agent::Consumer
    tax::Float64
end

tax_agent(T::Tax) = T.agent
tax(T::Tax) = T.tax

mutable struct ScalarInput <: ScalarNetput
    commodity::ScalarCommodity
    quantity::Float64
    reference_price::Float64
    taxes::Vector{Tax}
    parent::Union{AbstractNest,Missing}
    ScalarInput(commodity::ScalarCommodity,
                         quantity::Real;
                         reference_price=1,
                         taxes = []
        ) = new(commodity,quantity,reference_price,taxes,missing)
end


mutable struct ScalarOutput <: ScalarNetput
    commodity::ScalarCommodity
    quantity::Float64
    reference_price::Float64
    taxes::Vector{Tax}
    parent::Union{AbstractNest,Missing}
    ScalarOutput(commodity::ScalarCommodity,
                 quantity::Real;
                 reference_price=1,
                 taxes = []
        ) = new(commodity,quantity,reference_price,taxes,missing)
end


mutable struct ScalarNest <: AbstractNest
    name::Symbol
    elasticity::Float64
    quantity::Float64
    children::Vector{Union{ScalarNest,ScalarNetput}}
    parent::Union{ScalarNest,Missing}
    function ScalarNest(name::Symbol;elasticity::Real=0,children = [])  
        N = new(name,elasticity,sum(quantity(c) for c∈children; init=0),children, missing)
        for child in children
            set_parent(child,N)
        end
        return N
    end
end


################
## Production ##
################

mutable struct ScalarProduction
    sector::ScalarSector
    output::Union{Nothing,ScalarNest}
    input::Union{Nothing,ScalarNest}
    nested_compensated_demand::Dict
    compensated_demand::Dict
    taxes::Dict
    ScalarProduction(sector::ScalarSector,output::ScalarNest,input::ScalarNest) = new(sector,output,input, Dict(),Dict(),Dict())
end

const Production = ScalarProduction


sector(P::Production) = P.sector
output(P::Production) = P.output
input(P::Production) = P.input
taxes(P::Production) = P.taxes



########################
## Demands/Endowments ##
########################



struct ScalarDem
    commodity::ScalarCommodity
    quantity::Float64
end


struct ScalarEndowment
    commodity::ScalarCommodity
    quantity::Float64
end

# Getters
commodity(C::ScalarDem) = C.commodity
quantity(C::ScalarDem) = C.quantity

commodity(C::ScalarEndowment) = C.commodity
quantity(C::ScalarEndowment) = C.quantity

struct ScalarDemand
    consumer::ScalarConsumer
    demands::Dict{Commodity,ScalarDem}
    endowments::Dict{Commodity,ScalarEndowment}
    quantity::Float64
    function ScalarDemand(consumer::ScalarConsumer,demands::Vector{ScalarDem},endowments::Vector{ScalarEndowment})
        #var = get_variable(consumer)
        quantity=  sum(d.quantity for d∈demands)
        #set_start_value(var, quantity)
        new(consumer,
            Dict(demand.commodity => demand for demand in demands), 
            Dict(endowment.commodity => endowment for endowment in endowments),
            quantity
            )
    end
end

const Demand = ScalarDemand

consumer(D::Demand) = D.consumer
demands(D::Demand) = D.demands
endowments(D::Demand) = D.endowments
quantity(D::Demand) = D.quantity


###########
## Model ##
###########


mutable struct MPSGEModel <:AbstractMPSGEModel
    object_dict::Dict{Symbol,Any} # Contains only MPSGEVariables?
    jump_model::JuMP.Model
    productions::Dict{Sector,Production}
    demands::Dict{Consumer,Demand}
    commodities::Dict{Commodity,Vector{Sector}} #Generated on model build
    MPSGEModel() = new(Dict(),JuMP.Model(PATHSolver.Optimizer),Dict(),Dict(),Dict())
end

#Getters
object_dict(M::MPSGEModel) = M.object_dict
jump_model(M::MPSGEModel) = M.jump_model
productions(M::MPSGEModel) = M.productions
demands(M::MPSGEModel) = M.demands
Base.getindex(M::MPSGEModel,key::Symbol) = M.object_dict[key]


########################
## Collection Getters ##
########################

"""
    extract_scalars

Takes a variable and extracts it the sub-variables. 
"""
extract_scalars(S::MPSGEScalarVariable) = [S]
extract_scalars(S::MPSGEIndexedVariable) = S.subsectors.data


## Variables 

raw_sectors(m::MPSGEModel) = [s for (_,s) in m.object_dict if isa(s,Sector)]
raw_commodities(m::MPSGEModel) = [s for (_,s) in m.object_dict if isa(s,Commodity)]
raw_consumers(m::MPSGEModel) = [s for (_,s) in m.object_dict if isa(s,Consumer)]


"""
    sectors(m::MPSGEModel)

Return all sectors in a model
"""
function sectors(m::MPSGEModel)
    X = raw_sectors(m) |>
        x -> extract_scalars.(x) |>  
        x -> Iterators.flatten(x) |>
        x -> collect(x)
    return X
end


"""
    production_sectors(m::MPSGEModel)

Return all sectors that have a corresponding production block. 
These are coming from a dictionary, so order is not guaranteed.

This is primarily used when generating constraints.
"""
function production_sectors(m::MPSGEModel)
    return collect(keys(m.productions))
end

"""
    sectors(C::Commodity)

Return only the sectors that have the input commodity in their production
block. 

This is an optimization in building the model as the structure is very sparse 
iterating over all sectors is expensive.
"""
function sectors(C::Commodity)
    return C.model.commodities[C]  #stupid
end


function commodities(m::MPSGEModel)
    X = raw_commodities(m) |>
        x -> extract_scalars.(x) |>  
        x -> Iterators.flatten(x) |>
        x -> collect(x)
    return X
end

function commodities(S::Sector)
    return collect(keys(compensated_demand_dictionary(S)))
end


function consumers(m::MPSGEModel)
    X = raw_consumers(m) |>
        x -> extract_scalars.(x) |>
        x -> Iterators.flatten(x) |>
        x -> collect(x)
    return X
end

## Production
function production(S::ScalarSector)
    M = model(S)
    return M.productions[S]
end

function taxes(S::ScalarSector)
    P = production(S)
    return taxes(P)
end

function taxes(S::ScalarSector, H::ScalarConsumer)
    P = production(S)
    return get(taxes(P), H, Dict())
end