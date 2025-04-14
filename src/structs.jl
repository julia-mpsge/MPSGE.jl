############################
## Initial Abstract Types ##
############################

abstract type AbstractMPSGEModel end

abstract type MPSGEVariable end

#abstract type MPSGEIndexedVariable <: MPSGEVariable end
abstract type MPSGEScalarVariable <: MPSGEVariable end

# Valid types for fields that are quantities
const MPSGEquantity = Union{Real,MPSGEScalarVariable, JuMP.VariableRef, JuMP.AffExpr, JuMP.QuadExpr, JuMP.NonlinearExpr}

abstract type MPSGEIndexedVariable{T,N} <: AbstractArray{T,N} end

abstract type abstractMPSGEExpr end

abstract type Netput end



abstract type AbstractNest end;


####################
## Variable Types ##
####################

#Getters
base_name(V::MPSGEVariable) = V.name
name(V::MPSGEVariable) = ismissing(subindex(V)) ? Symbol(V.name) : Symbol(V.name,"_",join(subindex(V),"_"))
string_name(V::MPSGEVariable) = name(V)
model(V::MPSGEVariable) = V.model
description(V::MPSGEVariable) = V.description


subindex(V::MPSGEVariable) = missing
subindex(V::MPSGEScalarVariable) = V.subindex

# Indexed Getters
name(V::MPSGEIndexedVariable) = Symbol(V.name)
model(V::MPSGEIndexedVariable) = V.model
description(V::MPSGEIndexedVariable) = V.description
subvariables(V::MPSGEIndexedVariable) = V.subsectors
index_names(V::MPSGEIndexedVariable) = V.index


# Abstract array interface
Base.getindex(V::MPSGEIndexedVariable, index...) = V.subsectors[index...]
Base.getindex(A::MPSGEIndexedVariable, idx::CartesianIndex) = A.subsectors[idx]

Base.axes(A::MPSGEIndexedVariable) = axes(subvariables(A))
Base.CartesianIndices(A::MPSGEIndexedVariable) = CartesianIndices(subvariables(A))
Base.size(V::MPSGEIndexedVariable) = size(subvariables(V))
Base.length(V::MPSGEIndexedVariable) = length(subvariables(V))
Broadcast.broadcastable(V::MPSGEIndexedVariable) = subvariables(V)

struct ScalarSector <: MPSGEScalarVariable
    model::AbstractMPSGEModel
    name::Symbol
    subindex::Any
    description::String
    function ScalarSector(model::AbstractMPSGEModel,name::Symbol; description ="") 
        S = new(model,name,missing, description)
        add_variable!(model, S)
        return S
    end
    ScalarSector(model::AbstractMPSGEModel,name::Symbol,subindex; description = "") = new(model,name,subindex,description)
end

struct IndexedSector{N} <: MPSGEIndexedVariable{ScalarSector,N}
    model::AbstractMPSGEModel
    name::Symbol
    subsectors::DenseAxisArray{ScalarSector,N}
    index::Any
    description::String
    function IndexedSector(model::AbstractMPSGEModel,name::Symbol,index; description = "") 
        temp_array = Array{ScalarSector}(undef, length.(index)...)

        for i in CartesianIndices(temp_array)
            temp_array[i] = ScalarSector(model, name, Tuple(index[j][v] for (j,v) in enumerate(Tuple(i))); description = description)
        end
        
        sr = JuMP.Containers.DenseAxisArray(temp_array, index...)
        S = new{length(index)}(model,name, sr, index, description)
        add_variable!(model, S)
        return S
    end
end

const Sector = Union{ScalarSector,IndexedSector}

struct ScalarCommodity <: MPSGEScalarVariable
    model::AbstractMPSGEModel
    name::Symbol
    subindex::Any
    description::String
    function ScalarCommodity(model::AbstractMPSGEModel,name::Symbol; description = "") 
        C = new(model,name,missing, description)
        model.commodities[C] = []
        add_variable!(model, C)
        return C
    end
    function ScalarCommodity(model::AbstractMPSGEModel,name::Symbol,subindex; description = "") 
        C = new(model,name,subindex, description)
        model.commodities[C] = []
        return C
    end
end

struct IndexedCommodity{N} <: MPSGEIndexedVariable{ScalarCommodity,N}
    model::AbstractMPSGEModel
    name::Symbol
    subsectors::DenseAxisArray{ScalarCommodity,N}
    index::Any
    description::String
    function IndexedCommodity(model::AbstractMPSGEModel,name::Symbol,index; description = "") 
        temp_array = Array{ScalarCommodity}(undef, length.(index)...)

        for i in CartesianIndices(temp_array)
            temp_array[i] = ScalarCommodity(model, name, Tuple(index[j][v] for (j,v) in enumerate(Tuple(i))); description = description)
        end
        
        sr = JuMP.Containers.DenseAxisArray(temp_array, index...)
        S = new{length(index)}(model,name, sr, index, description)
        add_variable!(model, S)
        return S
    end
end

const Commodity = Union{ScalarCommodity,IndexedCommodity}


struct ScalarConsumer <: MPSGEScalarVariable
    model::AbstractMPSGEModel
    name::Symbol
    subindex::Any
    description::String
    function ScalarConsumer(model::AbstractMPSGEModel,name::Symbol; description = "") 
        S = new(model,name,missing, description)
        add_variable!(model, S)
        return S
    end
    ScalarConsumer(model::AbstractMPSGEModel,name::Symbol,subindex; description = "") = new(model,name,subindex, description)
end

struct IndexedConsumer{N} <: MPSGEIndexedVariable{ScalarConsumer,N}
    model::AbstractMPSGEModel
    name::Symbol
    subsectors::DenseAxisArray{ScalarConsumer,N}
    index::Any
    description::String
    function IndexedConsumer(model::AbstractMPSGEModel,name::Symbol,index; description = "") 
        temp_array = Array{ScalarConsumer}(undef, length.(index)...)

        for i in CartesianIndices(temp_array)
            temp_array[i] = ScalarConsumer(model, name, Tuple(index[j][v] for (j,v) in enumerate(Tuple(i))); description = description)
        end
        
        sr = JuMP.Containers.DenseAxisArray(temp_array, index...)
        S = new{length(index)}(model,name, sr, index, description)
        add_variable!(model, S)
        return S
    end
end

const Consumer = Union{ScalarConsumer,IndexedConsumer}

mutable struct ScalarParameter <: MPSGEScalarVariable
    model::AbstractMPSGEModel
    name::String
    value::Number
    description::String
    subindex::Missing
    function ScalarParameter(
            model::MPSGE.AbstractMPSGEModel,
            name::String, 
            value::Number; 
            description::String = ""
            ) 
        return new(model, name, value, description, missing)
    end
end


struct IndexedParameter{N} <: MPSGEIndexedVariable{ScalarParameter,N}
    model::AbstractMPSGEModel
    name::String
    subsectors::AbstractArray{<:ScalarParameter}#Containers.DenseAxisArray{ScalarParameter,N}
    index::Any
    description::String
    function IndexedParameter(
            model::AbstractMPSGEModel, 
            name::String, 
            subsectors::AbstractArray{<:ScalarParameter}, 
            index; 
            description = ""
            ) 
        return new{length(axes(subsectors))}(model, name, subsectors, index, description)
    end
end

const Parameter = Union{ScalarParameter,IndexedParameter}

JuMP.value(P::ScalarParameter) = P.value
JuMP.value(F::Function, P::ScalarParameter) = P.value

function set_value!(P::ScalarParameter, value::Number)
    P.value = value
    fix(get_variable(P), value; force=true)
    set_start_value(get_variable(P), value)
    return value
end


set_value!(P::IndexedParameter, value::Number) = set_value!.(P.subsectors,value)
set_value!(P::IndexedParameter, value::AbstractArray) = set_value!.(P.subsectors,value)



struct ScalarAuxiliary <: MPSGEScalarVariable
    model::AbstractMPSGEModel
    name::Symbol
    subindex::Any
    description::String
    function ScalarAuxiliary(model::AbstractMPSGEModel,name::Symbol; description = "")  
        S = new(model,name, missing, description)
        add_variable!(model, S)
        return S
    end
    ScalarAuxiliary(model::AbstractMPSGEModel,name::Symbol,subindex; description = "") = new(model,name,subindex, description)
end

struct IndexedAuxiliary{N} <: MPSGEIndexedVariable{ScalarAuxiliary,N}
    model::AbstractMPSGEModel
    name::Symbol
    subsectors::DenseAxisArray{ScalarAuxiliary,N}
    index::Any
    description::String
    function IndexedAuxiliary(model::AbstractMPSGEModel,name::Symbol,index; description = "") 
        temp_array = Array{ScalarAuxiliary}(undef, length.(index)...)

        for i in CartesianIndices(temp_array)
            temp_array[i] = ScalarAuxiliary(model, name, Tuple(index[j][v] for (j,v) in enumerate(Tuple(i))); description = description)
        end
        
        sr = JuMP.Containers.DenseAxisArray(temp_array, index...)
        S = new{length(index)}(model,name, sr, index, description)
        add_variable!(model, S)
        return S
    end
end

const Auxiliary = Union{ScalarAuxiliary,IndexedAuxiliary}


####################
## Tree Structure ##
####################

struct Tax
    agent::Consumer
    tax::MPSGEquantity
end

tax_agent(T::Tax) = T.agent
tax(T::Tax) = T.tax


struct ScalarNest
    name::Symbol
    subindex::Any
    elasticity::MPSGEquantity
    function ScalarNest(name::Symbol, elasticity::MPSGEquantity; subindex = missing)
        new(name, subindex, elasticity)
    end
end


base_name(N::ScalarNest) = N.name
name(N::ScalarNest) = ismissing(subindex(N)) ? N.name : Symbol(N.name,"_",join(subindex(N),"_"))
elasticity(N::ScalarNest) = N.elasticity
subindex(N::ScalarNest) = N.subindex

struct IndexedNest{N} <: AbstractArray{ScalarNest, N}
    name::Symbol
    subsectors::DenseAxisArray{ScalarNest,N}
    index::Any
    function IndexedNest(name::Symbol, elasticity::MPSGEquantity, index)
        temp_array = Array{ScalarNest}(undef, length.(index)...)
        for i in CartesianIndices(temp_array)
            temp_array[i] = ScalarNest(name, elasticity; subindex = Tuple(index[j][v] for (j,v) in enumerate(Tuple(i))))
        end
        sr = JuMP.Containers.DenseAxisArray(temp_array, index...)
        S = new{length(index)}(name, sr, index)
        return S  
    end

    function IndexedNest(name::Symbol, elasticity::AbstractArray, index) 
        temp_array = Array{ScalarNest}(undef, length.(index)...)
        for i in CartesianIndices(temp_array)
            ind = Tuple(index[j][v] for (j,v) in enumerate(Tuple(i)))
            temp_array[i] = ScalarNest(name, elasticity[ind...]; subindex = ind)
        end
        sr = JuMP.Containers.DenseAxisArray(temp_array, index...)
        S = new{length(index)}(name, sr, index)
        return S
    end
end

const Nest = Union{ScalarNest, IndexedNest}


name(N::IndexedNest) = N.name

Base.getindex(V::IndexedNest, index...) = V.subsectors[index...]
Base.getindex(A::IndexedNest, idx::CartesianIndex) = A.subsectors[idx]

Base.axes(N::IndexedNest) = axes(N.subsectors)
Base.size(N::IndexedNest) = size(N.subsectors)
Base.length(N::IndexedNest) = length(N.subsectors)
Base.broadcastable(N::IndexedNest) = N.subsectors



mutable struct Node
    parent::Union{Node, Nothing}
    children::Vector{Union{Node,Netput}}
    data::ScalarNest
    cost_function_virtual::Union{Nothing,JuMP.VariableRef}
    cost_function::MPSGEquantity 
    netput_sign::Int
    function Node(data::ScalarNest; children = [], netput_sign::Int = 1)
        N = new(nothing, children, data, nothing, 0, netput_sign) #Cost function is set after trees are built
        for child in children 
            set_parent!(child, N)
        end
        return N
    end
end

quantity(N::Node) = base_quantity(N)
base_quantity(N::Node) = sum(quantity(c) for c∈children(N); init=0)
base_name(N::Node) = base_name(N.data)
name(N::Node) = name(N.data)
children(N::Node) = N.children
#
elasticity(N::Node) = elasticity(N.data)
parent(N::Node) = N.parent



cost_function(N::Node; virtual = false) = !virtual ? N.cost_function : N.cost_function_virtual
#name(N::Node) = N.data.name
#elasticity(N::Node) = N.data.elasticity



function set_parent!(child::Node,   parent::Node; add_child=false) 
    child.parent = parent
    if add_child
        push!(parent.children, child)
    end
end

# Going to need to modify so child can be either scalar or indexed FUTURE
function set_parent!(child::Netput, parent::Node; add_child=false) 
    push!(child.parents, parent)
    if add_child
        push!(parent.children, child)
    end
end


## Netputs

commodity(C::Netput) = C.commodity
base_quantity(N::Netput) = N.quantity
reference_price(N::Netput) = N.reference_price
quantity(N::Netput) = base_quantity(N)*reference_price(N)
taxes(N::Netput) = N.taxes
name(N::Netput) = name(commodity(N))
#parent(N::Netput) = N.parent
children(N::Netput) = []
parent(N::Netput) = N.parents
netput_sign(N::Netput) = N.netput_sign
    
mutable struct Input <: Netput 
    commodity::ScalarCommodity
    quantity::MPSGEquantity
    reference_price::MPSGEquantity
    taxes::Vector{Tax}
    parents::Vector{Node}
    netput_sign::Int
    Input( commodity::ScalarCommodity,
            quantity::MPSGEquantity;
            reference_price::MPSGEquantity=1,
            taxes = [],
    ) = new(commodity, quantity, reference_price, taxes, [], -1)
end

mutable struct Output <: Netput 
    commodity::ScalarCommodity
    quantity::MPSGEquantity
    reference_price::MPSGEquantity
    taxes::Vector{Tax}
    parents::Vector{Node}
    #cost_function::MPSGEquantity
    netput_sign::Int
    Output(commodity::ScalarCommodity,
            quantity::MPSGEquantity;
            reference_price::MPSGEquantity=1,
            taxes = [],
    ) = new(commodity, quantity, reference_price, taxes, [], 1)
end


################
## Production ##
################
struct Production
    sector::ScalarSector
    netputs::Dict{Commodity, Vector{Netput}}
    input::Union{Node, Nothing}
    output::Union{Node, Nothing}
    taxes::Dict{Consumer, Vector{Netput}}
end

sector(P::Production) = P.sector
input(P::Production) = P.input
output(P::Production) = P.output
commodities(P::Production) = collect(keys(P.netputs))
netputs(P::Production) = P.netputs
netputs(S::ScalarSector, C::ScalarCommodity) = !ismissing(production(S)) ? get(netputs(production(S)), C, []) : []
function taxes(S::ScalarSector,H::ScalarConsumer)
    P = production(S)
    if !haskey(P.taxes, H)
        return []
    end
    return P.taxes[H]
end



function find_nodes(P; search = :all)
    out = Dict()
    nodes_to_search = []
    if search == :all
        nodes_to_search = Vector{Any}([P.input, P.output])
    elseif search == :input
        nodes_to_search = Vector{Any}([input(P)])
    elseif search == :output
        nodes_to_search = Vector{Any}([output(P)])
    end
    while !isempty(nodes_to_search)
        n = popfirst!(nodes_to_search)
        if !haskey(out, name(n))
            out[name(n)] = []
        end
        push!(out[name(n)], n)
        if isa(n, MPSGE.Node)
            push!(nodes_to_search, MPSGE.children(n)...)
        end
    end
    return out
end


function cost_function(P::Production, nest::Symbol; virtual = false, search = :all)
    N = find_nodes(P; search = search)
    if haskey(N, nest)
        return sum(quantity.(N[nest]).*cost_function.(N[nest]; virtual = virtual))
    end
    return 0
end


"""
    cost_function(S::ScalarSector; virtual = false)
    cost_function(S::ScalarSector, nest::Symbol; virtual = false)
    
Return a vector of cost functions for the given sector and nest. If `nest` is 
not provided return the cost function for input tree. 

`nest` is the symbol representing the nest. This can also be the name of a 
commodity. 

If `virtual` is true, return the virtual cost functions.
"""
cost_function(P::Production; virtual=false) = cost_function(P, name(input(P)), virtual=virtual)
cost_function(S::ScalarSector, nest::Symbol; virtual = false) = cost_function(production(S), nest, virtual=virtual, search = :input)
cost_function(S::ScalarSector; virtual = false) = cost_function(production(S), virtual=virtual)



"""
    revenue_function(S::ScalarSector; virtual = false)    
    revenue_function(S::ScalarSector, nest::Symbol; virtual = false)
    
Return a vector of revenue functions for the given sector and nest. If `nest` is 
not provided return the revenue function for input tree. 

`nest` is the symbol representing the nest. This can also be the name of a 
commodity. 

If `virtual` is true, return the virtual revenue functions.

"""
revenue_function(P::Production; virtual = false) = cost_function(P, name(output(P)), virtual = virtual, search = :output)
revenue_function(S::ScalarSector, nest::Symbol; virtual = false) = cost_function(production(S), nest, virtual = virtual, search = :output)
revenue_function(S::ScalarSector; virtual = false) = revenue_function(production(S); virtual = virtual)

########################
## Demands/Endowments ##
########################

abstract type abstractDemandFlow end;

struct ScalarFinalDemand <: abstractDemandFlow #FinalDemand
    commodity::ScalarCommodity
    quantity::MPSGEquantity
    reference_price::MPSGEquantity
    ScalarFinalDemand(commodity::ScalarCommodity, quantity::MPSGEquantity; reference_price::MPSGEquantity = 1) = new(commodity,quantity,reference_price)
end


struct ScalarEndowment <: abstractDemandFlow
    commodity::ScalarCommodity
    quantity::MPSGEquantity
end

# Getters
commodity(C::ScalarFinalDemand) = C.commodity
base_quantity(D::ScalarFinalDemand) = D.quantity
quantity(D::ScalarFinalDemand) = base_quantity(D) * reference_price(D)
reference_price(D::ScalarFinalDemand) = D.reference_price
raw_quantity(F::Function, D::ScalarFinalDemand) = value(F, D.quantity)*value(F,D.reference_price)
raw_quantity(D::ScalarFinalDemand) = value(D.quantity)*value(D.reference_price)

commodity(C::ScalarEndowment) = C.commodity
quantity(C::ScalarEndowment) = C.quantity
raw_quantity(F::Function, C::ScalarEndowment) = value(F, C.quantity)


raw_quantity(C::ScalarEndowment) = value(C.quantity)

struct ScalarDemand
    consumer::ScalarConsumer
    elasticity::MPSGEquantity
    demand_flow::Dict{Commodity, Vector{abstractDemandFlow}}
    function ScalarDemand(
        consumer::ScalarConsumer,
        demand_flow::Vector{abstractDemandFlow};
        elasticity::MPSGEquantity = 1
        )

        M = model(consumer)

        _demand_flow = Dict{Commodity, Vector{abstractDemandFlow}}()
        for demand in demand_flow
            if quantity(demand) == 0
                continue
            end
            if haskey(_demand_flow, demand.commodity)
                push!(_demand_flow[demand.commodity], demand)
            else
                _demand_flow[demand.commodity] = [demand]
            end

            if isa(demand, ScalarEndowment)
                if !(haskey(M.endowments, demand.commodity))
                    M.endowments[demand.commodity] = []
                end
                if consumer ∉ M.endowments[demand.commodity]
                    push!(M.endowments[demand.commodity], consumer)
                end
            end

            if isa(demand, ScalarFinalDemand)
                if !(haskey(M.final_demands, demand.commodity))
                    M.final_demands[demand.commodity] = [consumer]
                else
                    push!(M.final_demands[demand.commodity], consumer)
                end
            end

        end

        D = new(consumer,
            elasticity,
            _demand_flow
            )

        set_start_value(consumer, raw_quantity(start_value,D))

        return D
    end
end

const Demand = ScalarDemand

consumer(D::Demand) = D.consumer
final_demands(D::Demand) = Dict(C => [d for d in DF if isa(d,ScalarFinalDemand)] for (C,DF) in D.demand_flow)
endowments(D::Demand) = Dict(C => [e for e in E if isa(e,ScalarEndowment)] for (C,E) in D.demand_flow)#D.endowments
quantity(D::Demand) = sum(sum(quantity.(d);init=0) for (_,d)∈final_demands(D);init=0)
elasticity(D::Demand) = D.elasticity
raw_quantity(F::Function, D::Demand) = sum(sum(raw_quantity.(F,d);init=0) for (_,d)∈final_demands(D); init=0)
raw_quantity(D::Demand) = sum(sum(raw_quantity.(d);init=0) for (_,d)∈final_demands(D); init=0)



struct ScalarAuxConstraint
    aux::ScalarAuxiliary
    constraint::Any#MPSGEExpr
end

const AuxConstraint = ScalarAuxConstraint

auxiliary(C::AuxConstraint) = C.aux
constraint(C::AuxConstraint) = C.constraint

###########
## Model ##
###########


mutable struct MPSGEModel <:AbstractMPSGEModel
    object_dict::Dict{Symbol,Any} # Contains only MPSGEVariables?
    jump_model::Union{JuMP.Model,Nothing}
    productions::Dict{ScalarSector,Production} # all scalars
    demands::Dict{ScalarConsumer,Demand}
    commodities::Dict{ScalarCommodity,Vector{ScalarSector}} #Generated on model build
    endowments::Dict{ScalarCommodity, Vector{ScalarConsumer}}
    final_demands::Dict{ScalarCommodity, Vector{ScalarConsumer}}
    auxiliaries::Dict{ScalarAuxiliary, AuxConstraint}
    silent::Bool
    MPSGEModel() = new(Dict(),direct_model(PATHSolver.Optimizer()),Dict(),Dict(),Dict(),Dict(),Dict(),Dict(),false)
end

#Getters
object_dict(M::MPSGEModel) = M.object_dict
jump_model(M::MPSGEModel) = M.jump_model
productions(M::MPSGEModel) = M.productions
demands(M::MPSGEModel) = M.demands
aux_constraints(M::MPSGEModel) = M.auxiliaries
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
raw_parameters(m::MPSGEModel) = [s for (_,s) in m.object_dict if isa(s,Parameter)]
raw_auxiliaries(m::MPSGEModel) = [s for (_,s) in m.object_dict if isa(s,Auxiliary)]

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

function endowments(C::Commodity)
    if !haskey(C.model.endowments, C)
        return []
    end
    return C.model.endowments[C]
end

function final_demands(C::Commodity)
    if !haskey(C.model.final_demands, C)
        return []
    end
    return C.model.final_demands[C]
end


function commodities(m::MPSGEModel)
    X = raw_commodities(m) |>
        x -> extract_scalars.(x) |>  
        x -> Iterators.flatten(x) |>
        x -> collect(x)
    return X
end

function commodities(S::ScalarSector) 
    P = production(S)
    return collect(keys(P.netputs))
    #return collect(keys(compensated_demand_dictionary(S)))
end


function consumers(m::MPSGEModel)
    X = raw_consumers(m) |>
        x -> extract_scalars.(x) |>
        x -> Iterators.flatten(x) |>
        x -> collect(x)
    return X
end

function parameters(m::MPSGEModel)
    X = raw_parameters(m) |>
        x -> extract_scalars.(x) |>
        x -> Iterators.flatten(x) |>
        x -> collect(x)
    return X
end


function auxiliaries(m::MPSGEModel)
    X = raw_auxiliaries(m) |>
        x -> extract_scalars.(x) |>
        x -> Iterators.flatten(x) |>
        x -> collect(x)
    return X
end


## Production
function production(S::ScalarSector) #Key errors are possible
    M = model(S)
    if haskey(M.productions, S)
        return M.productions[S]
    end
    return missing
end

