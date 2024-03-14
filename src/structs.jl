############################
## Initial Abstract Types ##
############################

abstract type AbstractMPSGEModel end

abstract type MPSGEVariable end

#abstract type MPSGEIndexedVariable <: MPSGEVariable end
abstract type MPSGEScalarVariable <: MPSGEVariable end

abstract type MPSGEIndexedVariable{T,N} <: AbstractArray{T,N} end

abstract type abstractMPSGEExpr end

abstract type ScalarNetput end
abstract type IndexedNetput end

const Netput = Union{ScalarNetput,IndexedNetput}

abstract type AbstractNest end;


####################
## Variable Types ##
####################

#Getters
base_name(V::MPSGEVariable) = V.name
name(V::MPSGEVariable) = ismissing(subindex(V)) ? V.name : Symbol(V.name,"_",join(subindex(V),"_"))
model(V::MPSGEVariable) = V.model
description(V::MPSGEVariable) = V.description


Base.getindex(S::MPSGEIndexedVariable, index...) = S.subsectors[index...]

subindex(V::MPSGEVariable) = missing

subindex(V::MPSGEScalarVariable) = V.subindex

# Indexed Getters
name(V::MPSGEIndexedVariable) = V.name
model(V::MPSGEIndexedVariable) = V.model
description(V::MPSGEIndexedVariable) = V.description
subvariables(V::MPSGEIndexedVariable) = V.subsectors



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
        S = new(model,name,missing, description)
        
        return S
    end
    ScalarCommodity(model::AbstractMPSGEModel,name::Symbol,subindex; description = "") = new(model,name,subindex, description)
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
        return S
    end
end

const Consumer = Union{ScalarConsumer,IndexedConsumer}

mutable struct ScalarParameter <: MPSGEScalarVariable
    model::AbstractMPSGEModel
    name::Symbol
    subindex::Any
    value::Number
    description::String
    ScalarParameter(model::AbstractMPSGEModel,name::Symbol, value::Number; description = "") = new(model,name,missing, value, description)
    ScalarParameter(model::AbstractMPSGEModel,name::Symbol, value::Number,subindex; description = "") = new(model,name,subindex, value, description)
end


struct IndexedParameter{N} <: MPSGEIndexedVariable{ScalarParameter,N}
    model::AbstractMPSGEModel
    name::Symbol
    subsectors::DenseAxisArray{ScalarParameter,N}
    index::Any
    description::String
    function IndexedParameter(model::AbstractMPSGEModel,name::Symbol,index, value::Number; description = "") 
        temp_array = Array{ScalarParameter}(undef, length.(index)...)

        for i in CartesianIndices(temp_array)
            temp_array[i] = ScalarParameter(model, name, value, Tuple(index[j][v] for (j,v) in enumerate(Tuple(i))); description = description)
        end
        
        sr = JuMP.Containers.DenseAxisArray(temp_array, index...)
        S = new{length(index)}(model,name, sr, index, description)
        return S
    end

    function IndexedParameter(model::AbstractMPSGEModel,name::Symbol,index, value::AbstractArray; description = "") 
        temp_array = Array{ScalarParameter}(undef, length.(index)...)

        for i in CartesianIndices(temp_array)
            ind = Tuple(index[j][v] for (j,v) in enumerate(Tuple(i)))
            temp_array[i] = ScalarParameter(model, name, value[ind...], ind; description = description)
        end
        
        sr = JuMP.Containers.DenseAxisArray(temp_array, index...)
        S = new{length(index)}(model,name, sr, index, description)
        return S
    end
end

const Parameter = Union{ScalarParameter,IndexedParameter}

JuMP.value(P::ScalarParameter) = P.value

function set_value!(P::ScalarParameter, value::Number)
    P.value = value
    if !isnothing(jump_model(model(P)))
        fix(get_variable(P), value; force=true)
    end
    return value
end


set_value!(P::IndexedParameter, value::Number) = set_value!.(P.subsectors,value)
set_value!(P::IndexedParameter, value::AbstractArray) = set_value!.(P.subsectors,value)



struct ScalarAuxiliary <: MPSGEScalarVariable
    model::AbstractMPSGEModel
    name::Symbol
    subindex::Any
    description::String
    ScalarAuxiliary(model::AbstractMPSGEModel,name::Symbol; description = "") = new(model,name, missing, description)
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
        return S
    end
end

const Auxiliary = Union{ScalarAuxiliary,IndexedAuxiliary}


#######################
## MPSGE Expressions ##
#######################
struct MPSGEExpr <: abstractMPSGEExpr
    head::Symbol
    args::Vector{Union{Real,MPSGEScalarVariable,abstractMPSGEExpr}}
end

const MPSGEquantity = Union{Real,MPSGEScalarVariable,MPSGEExpr}
const _MPSGEquantity = Union{MPSGEScalarVariable,MPSGEExpr}

JuMP.value(x::abstractMPSGEExpr) = value(_get_parameter_value(x))


Base.:+(x::MPSGEquantity,y::_MPSGEquantity) = MPSGEExpr(:+, [x, y])
Base.:+(x::_MPSGEquantity,y::Real) = MPSGEExpr(:+, [x, y])

Base.:-(x::MPSGEquantity,y::_MPSGEquantity) = MPSGEExpr(:-, [x, y])
Base.:-(x::_MPSGEquantity,y::Real) = MPSGEExpr(:-, [x, y])

Base.:*(x::MPSGEquantity,y::_MPSGEquantity) = MPSGEExpr(:*, [x, y])
Base.:*(x::_MPSGEquantity,y::Real) = MPSGEExpr(:*, [x, y])

Base.:/(x::MPSGEquantity,y::_MPSGEquantity) = MPSGEExpr(:/, [x, y])
Base.:/(x::_MPSGEquantity,y::Real) = MPSGEExpr(:/, [x, y])

Base.:^(x::MPSGEquantity,y::_MPSGEquantity) = MPSGEExpr(:^, [x, y])
Base.:^(x::_MPSGEquantity,y::Real) = MPSGEExpr(:^, [x, y])

Base.:-(x::_MPSGEquantity) = MPSGE_MP.MPSGEExpr(:-, [x])


####################
## Tree Structure ##
####################

# Getters
"""
    _get_parameter_value

The purpose of this is to return either the variable or the value depending on 
if the model has been generated.
"""
_get_parameter_value(x) = x
function _get_parameter_value(X::ScalarParameter)
    if !isnothing(jump_model(model(X)))
        return get_variable(X)
    end
    return value(X)
end


function _get_parameter_value(x::abstractMPSGEExpr)
    return NonlinearExpr(x.head, _get_parameter_value.(x.args)...)
end

function _get_parameter_value(x:: MPSGEScalarVariable)
    return get_variable(x)
end



commodity(C::ScalarNetput) = C.commodity
base_quantity(N::ScalarNetput) = _get_parameter_value(N.quantity)
reference_price(N::ScalarNetput) = _get_parameter_value(N.reference_price)
quantity(N::ScalarNetput) = base_quantity(N)*reference_price(N)
taxes(N::ScalarNetput) = N.taxes
name(N::ScalarNetput) = name(commodity(N))
parent(N::ScalarNetput) = N.parent
children(N::ScalarNetput) = []

quantity(N::AbstractNest) = base_quantity(N)
base_quantity(N::AbstractNest) = sum(quantity(c) for c∈children(N); init=0)#_get_parameter_value(N.quantity)
name(N::AbstractNest) = N.name
children(N::AbstractNest) = N.children
parent(N::AbstractNest) = ismissing(N.parent) ? name(N) : N.parent
elasticity(N::AbstractNest) = _get_parameter_value(N.elasticity)
raw_elasticity(N::AbstractNest) = N.elasticity



# Small Setter - Deprecated? 
set_parent(child::AbstractNest,parent::AbstractNest) = (child.parent = parent)
set_parent(child::ScalarNetput,parent::AbstractNest) = (child.parent = parent)

struct Tax
    agent::Consumer
    tax::MPSGEquantity
end

tax_agent(T::Tax) = T.agent
tax(T::Tax) = _get_parameter_value(T.tax)

#isa(T.tax, Number) ? T.tax : get_variable(T.tax)


struct ScalarInput <: ScalarNetput
    commodity::ScalarCommodity
    quantity::MPSGEquantity
    reference_price::MPSGEquantity
    taxes::Vector{Tax}
    parent::Union{Symbol,Missing}
    ScalarInput(commodity::ScalarCommodity,
                quantity::MPSGEquantity;
                reference_price::MPSGEquantity=1,
                taxes = [],
                parent = :s
        ) = new(commodity,quantity,reference_price,taxes,parent)
end


struct ScalarOutput <: ScalarNetput
    commodity::ScalarCommodity
    quantity::MPSGEquantity
    reference_price::MPSGEquantity
    taxes::Vector{Tax}
    parent::Union{Symbol,Missing}
    ScalarOutput(commodity::ScalarCommodity,
                 quantity::MPSGEquantity;
                 reference_price::MPSGEquantity=1,
                 taxes = [],
                 parent = :t
        ) = new(commodity,quantity,reference_price,taxes,parent)
end


mutable struct ScalarNest <: AbstractNest
    name::Symbol
    elasticity::MPSGEquantity
    children::Vector{Union{ScalarNest,ScalarNetput}}
    parent::Union{Symbol,Missing}
    function ScalarNest(name::Symbol;parent::Union{Symbol,Missing} = missing, elasticity::MPSGEquantity=0,children = [])  
        N = new(name,elasticity,children, parent)
        for child in children
            set_parent(child,N)
        end
        return N
    end
end

function add_child!(N::ScalarNest, child)
    push!(N.children, child)
end

struct Node
    name::Symbol
    parent::Union{Symbol,Missing}
    elasticity::MPSGE_MP.MPSGEquantity
    Node(name::Symbol, elasticity; parent = missing) = new(name, parent, elasticity)
end


################
## Production ##
################

mutable struct ScalarProduction
    sector::ScalarSector
    netput::Dict{ScalarCommodity, Vector{MPSGE_MP.Netput}}
    nest_dict::Dict{Symbol, Any}
    nested_compensated_demand::Dict
    compensated_demand::Dict
    taxes::Dict
    function ScalarProduction(sector::ScalarSector, nodes::Vector{Node}, netputs::MPSGE_MP.ScalarNetput...)
        netput_dict = Dict{ScalarCommodity, Vector{MPSGE_MP.Netput}}()
        
        for netput in netputs
            if quantity(netput) == 0 #Pre prune, don't add if quantity starts at 0
                continue
            end
            C = commodity(netput)
            if !haskey(netput_dict, C)
                netput_dict[C] = []
            end
            push!(netput_dict[C], netput)
        end

        nest_dict = Dict()
        for node in nodes
            nest_dict[node.name] = ScalarNest(node.name; parent = node.parent, elasticity = node.elasticity)
            if !ismissing(node.parent)
                add_child!(nest_dict[node.parent], nest_dict[node.name])
            end
        end
        
        for (_, netputs) in netput_dict
            for netput ∈ netputs
                add_child!(nest_dict[netput.parent], netput)
            end
        end


        new(sector, netput_dict, nest_dict, Dict(), Dict(), Dict())
    end
end

const Production = ScalarProduction


sector(P::Production) = P.sector
input(P::Production) = P.nest_dict[:s] #Temporary
output(P::Production) = P.nest_dict[:t] #Temporary
taxes(P::Production) = P.taxes
commodities(P::Production) = collect(keys(P.netput))
commodity_netputs(P::Production) = collect(Iterators.flatten(values(P.netput)))
commodity(P::Production, C::Commodity) = P.netput[C]
netputs(P::Production) = P.netput

parent(P::Production, T::ScalarNest) = P.nest_dict[parent(T)]
parent(P::Production, T::ScalarNetput) = P.nest_dict[parent(T)]


########################
## Demands/Endowments ##
########################



struct ScalarDem
    commodity::ScalarCommodity
    quantity::MPSGEquantity
    reference_price::MPSGEquantity
    ScalarDem(commodity::ScalarCommodity, quantity::MPSGEquantity; reference_price::MPSGEquantity = 1) = new(commodity,quantity,reference_price)
end


struct ScalarEndowment
    commodity::ScalarCommodity
    quantity::MPSGEquantity
end

# Getters
commodity(C::ScalarDem) = C.commodity
base_quantity(D::ScalarDem) = _get_parameter_value(D.quantity)
quantity(D::ScalarDem) = base_quantity(D) * reference_price(D)
reference_price(D::ScalarDem) = _get_parameter_value(D.reference_price)
raw_quantity(D::ScalarDem) = value(D.quantity)*value(D.reference_price)

commodity(C::ScalarEndowment) = C.commodity
quantity(C::ScalarEndowment) = _get_parameter_value(C.quantity)

struct ScalarDemand
    consumer::ScalarConsumer
    elasticity::MPSGEquantity
    demands::Dict{Commodity,ScalarDem}
    endowments::Dict{Commodity,ScalarEndowment}
    function ScalarDemand(
        consumer::ScalarConsumer,
        demands::Vector{ScalarDem},
        endowments::Vector{ScalarEndowment};
        elasticity::MPSGEquantity = 1
        )

        new(consumer,
            elasticity,
            Dict(demand.commodity => demand for demand in demands), 
            Dict(endowment.commodity => endowment for endowment in endowments),
            )
    end
end

const Demand = ScalarDemand

consumer(D::Demand) = D.consumer
demands(D::Demand) = D.demands
endowments(D::Demand) = D.endowments
quantity(D::Demand) = sum(quantity(d) for (_,d)∈demands(D))
elasticity(D::Demand) = _get_parameter_value(D.elasticity)
raw_quantity(D::Demand) = sum(raw_quantity(d) for (_,d)∈demands(D))



struct ScalarAuxConstraint
    aux::ScalarAuxiliary
    constraint::MPSGEExpr
end

const AuxConstraint = ScalarAuxConstraint

auxiliary(C::AuxConstraint) = C.aux
constraint(C::AuxConstraint) = _get_parameter_value(C.constraint)

###########
## Model ##
###########


mutable struct MPSGEModel <:AbstractMPSGEModel
    object_dict::Dict{Symbol,Any} # Contains only MPSGEVariables?
    jump_model::Union{JuMP.Model,Nothing}
    productions::Dict{Sector,Production}
    demands::Dict{Consumer,Demand}
    commodities::Dict{Commodity,Vector{Sector}} #Generated on model build
    auxiliaries::Dict{Auxiliary, AuxConstraint}
    MPSGEModel() = new(Dict(),nothing,Dict(),Dict(),Dict(),Dict())
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