############################
## Initial Abstract Types ##
############################

abstract type AbstractMPSGEModel end

abstract type MPSGEVariable end

#abstract type MPSGEIndexedVariable <: MPSGEVariable end
abstract type MPSGEScalarVariable <: MPSGEVariable end

abstract type MPSGEIndexedVariable{T,N} <: AbstractArray{T,N} end

abstract type abstractMPSGEExpr end

abstract type Netput end



abstract type AbstractNest end;


####################
## Variable Types ##
####################

#Getters
base_name(V::MPSGEVariable) = V.name
name(V::MPSGEVariable) = ismissing(subindex(V)) ? V.name : Symbol(V.name,"_",join(subindex(V),"_"))
model(V::MPSGEVariable) = V.model
description(V::MPSGEVariable) = V.description


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

Base.:-(x::_MPSGEquantity) = MPSGEExpr(:-, [x])




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
    return X#value(X)
end


function _get_parameter_value(x::abstractMPSGEExpr)
    return NonlinearExpr(x.head, _get_parameter_value.(x.args)...)
end

function _get_parameter_value(x:: MPSGEScalarVariable)
    return x#get_variable(x)
end


####################
## Tree Structure ##
####################


commodity(C::Netput) = C.commodity
base_quantity(N::Netput) = _get_parameter_value(N.quantity)
reference_price(N::Netput) = _get_parameter_value(N.reference_price)
quantity(N::Netput) = base_quantity(N)*reference_price(N)
taxes(N::Netput) = N.taxes
name(N::Netput) = name(commodity(N))
parent(N::Netput) = N.parent
children(N::Netput) = []
function cost_function(N::Netput)
    C = commodity(N)
    sign = N.netput_sign
    rp = reference_price(N)
    return C*(1-sign*sum(tax(t) for t∈taxes(N);init = 0))/rp
end

struct Tax
    agent::Consumer
    tax::MPSGEquantity
end

tax_agent(T::Tax) = T.agent
tax(T::Tax) = _get_parameter_value(T.tax)


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
elasticity(N::ScalarNest) = _get_parameter_value(N.elasticity)
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

    function _IndexedNest(name::Symbol, elasticity::AbstractArray, index) 
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
    cost_function::MPSGEquantity
    netput_sign::Int
    function Node(data::ScalarNest; children = [], netput_sign::Int = 1)
        N = new(nothing, children, data, sum(cost_function(c) for c∈children; init=0), netput_sign) #Cost function wrong currently. Will fix
        for child in children 
            set_parent!(child, N)
        end
        return N
    end
end

quantity(N::Node) = base_quantity(N)
base_quantity(N::Node) = sum(quantity(c) for c∈children(N); init=0)#_get_parameter_value(N.quantity)
base_name(N::Node) = base_name(N.data)
name(N::Node) = name(N.data)
children(N::Node) = N.children
parents(N::Node) = N.parents
elasticity(N::Node) = elasticity(N.data)
raw_elasticity(N::Node) = N.elasticity
parent(N::Node) = N.parent

cost_function(N::Node) = N.cost_function
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
    
mutable struct Input <: Netput 
    commodity::ScalarCommodity
    quantity::MPSGEquantity
    reference_price::MPSGEquantity
    taxes::Vector{Tax}
    parents::Vector{Node}
    #cost_function::MPSGEquantity
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

mutable struct ScalarProduction
    sector::ScalarSector
    commodityNetputs::Vector{Netput}
    ordered_nests::Vector{ScalarNest}
    nest_dict::Dict{Symbol, Any}
    nested_compensated_demand::Dict
    compensated_demand::Dict
    taxes::Dict
    input::Symbol
    output::Symbol
    function ScalarProduction(sector::ScalarSector, nodes::Vector{Node}, netputs::Netput...)
        commodityNetputs = Vector{Netput}()#Dict{ScalarCommodity, Vector{Netput}}()
        ordered_nests = Vector{ScalarNest}()


        #Build the non-leaf portion of the tree
        nest_dict = Dict()
        for node in nodes
            nest_dict[node.name] = ScalarNest(node.name; parent = node.parent, elasticity = node.elasticity)
            if !ismissing(node.parent)
                add_child!(nest_dict[node.parent], nest_dict[node.name])
            end
            push!(ordered_nests, nest_dict[node.name])
        end

        Input = missing
        Output = missing

        #Build the leaves
        for netput in netputs
            if quantity(netput) == 0 #Pre prune, don't add if quantity starts at 0
                continue
            end
            push!(commodityNetputs, netput)
            add_child!(nest_dict[netput.parent], netput)
            
            #Determine the root of the input tree
            if ismissing(Input) && isa(netput, ScalarInput) 
                Input = parent(netput)
                while Input != parent(nest_dict[Input])#!ismissing(parent)
                    Input = parent(nest_dict[Input])
                end
            end
            
            #Determine the root of the output tree
            if ismissing(Output) && isa(netput, ScalarOutput)
                Output = parent(netput)
                while Output != parent(nest_dict[Output])#!ismissing(parent)
                    Output = parent(nest_dict[Output])
                end
            end

        end

        #It's possible there is no input/output tree. In this case set a default key value we can check for.
        if ismissing(Input) 
            Input = :missing
        end

        if ismissing(Output) 
            Output = :missing
        end

        P = new(sector, commodityNetputs, ordered_nests, nest_dict, Dict(), Dict(), Dict(), Input, Output)

        # Set all the input nests to be inputs. 
        if Input != :missing
            T = input(P)
            to_set = [T]
            while !isempty(to_set)
                T = popfirst!(to_set)
                T.input = true
                append!(to_set, [e for e∈children(T) if isa(e,ScalarNest)])
            end
        end
        
        return P

    end
end

const Production = ScalarProduction


sector(P::Production) = P.sector
input(P::Production) = P.nest_dict[P.input] 
output(P::Production) = P.nest_dict[P.output]
taxes(P::Production) = P.taxes
commodities(P::Production) = collect(keys(P.netput))
commodityNetputs(P::Production) = P.commodityNetputs

parent(P::Production, T::ScalarNest) = P.nest_dict[parent(T)]
parent(P::Production, T::Netput) = P.nest_dict[parent(T)]


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