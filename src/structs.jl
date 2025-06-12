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
base_name(V::MPSGEVariable) = Symbol(V.name)
name(V::MPSGEVariable) = Symbol(V.name) 
string_name(V::MPSGEVariable) = V.name
model(V::MPSGEVariable) = V.model
description(V::MPSGEVariable) = V.description




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
    name::String
    description::String
    function ScalarSector(model::AbstractMPSGEModel, name::String; description::String = "", start = 1, upper_bound = Inf, lower_bound = 0)  
        S = new(model, name, description)
        add_variable!(model, S; start = start, upper_bound = upper_bound, lower_bound = lower_bound)
        return S
    end
    ScalarSector(model::AbstractMPSGEModel, name::Symbol; description::String = "", start = 1, upper_bound=Inf, lower_bound = 0) = ScalarSector(model, string(name); description = description, start = start, upper_bound = upper_bound, lower_bound = lower_bound)
end

struct IndexedSector{N} <: MPSGEIndexedVariable{ScalarSector,N}
    model::AbstractMPSGEModel
    name::String
    subsectors::AbstractArray{<:ScalarSector,N}
    index::Any
    description::String
    IndexedSector(model::AbstractMPSGEModel, name::String, subsectors::AbstractArray{<:ScalarSector}, index, description) = new{length(axes(subsectors))}(model, name, subsectors, index, description)
    IndexedSector(model::AbstractMPSGEModel, name::String, subsectors::AbstractArray{<:ScalarSector}, index; description::String = "") = new{length(axes(subsectors))}(model, name, subsectors, index, description)
end

const Sector = Union{ScalarSector,IndexedSector}

struct ScalarCommodity <: MPSGEScalarVariable
    model::AbstractMPSGEModel
    name::String
    description::String
    function ScalarCommodity(model::AbstractMPSGEModel, name::String; description::String = "", start=1, upper_bound=Inf, lower_bound = 0)
        C = new(model, name, description)
        add_variable!(model, C; start = start, upper_bound = upper_bound, lower_bound = lower_bound)
        return C
    end
    ScalarCommodity(model::AbstractMPSGEModel, name::Symbol; description::String = "", start=1, upper_bound=Inf, lower_bound = 0  ) = ScalarCommodity(model, string(name); description = description, start=1, upper_bound=Inf, lower_bound = 0 )
end

struct IndexedCommodity{N} <: MPSGEIndexedVariable{ScalarCommodity,N}
    model::AbstractMPSGEModel
    name::String
    subsectors::AbstractArray{<:ScalarCommodity,N}
    index::Any
    description::String
    IndexedCommodity(model::AbstractMPSGEModel, name::String, subsectors::AbstractArray{<:ScalarCommodity}, index, description) = new{length(axes(subsectors))}(model, name, subsectors, index, description)
    IndexedCommodity(model::AbstractMPSGEModel, name::String, subsectors::AbstractArray{<:ScalarCommodity}, index; description::String = "") = new{length(axes(subsectors))}(model, name, subsectors, index, description)
end

const Commodity = Union{ScalarCommodity,IndexedCommodity}


struct ScalarConsumer <: MPSGEScalarVariable
    model::AbstractMPSGEModel
    name::String
    description::String

    function ScalarConsumer(model::AbstractMPSGEModel, name::String; description::String = "", start=1, upper_bound=Inf, lower_bound = 0)
        C = new(model, name, description)
        add_variable!(model, C; start = start, upper_bound = upper_bound, lower_bound = lower_bound)
        return C
    end
    ScalarConsumer(model::AbstractMPSGEModel, name::Symbol; description::String = "", start=1, upper_bound=Inf, lower_bound = 0) = ScalarConsumer(model, string(name); description = description, start=1, upper_bound=Inf, lower_bound = 0)
end

struct IndexedConsumer{N} <: MPSGEIndexedVariable{ScalarConsumer,N}
    model::AbstractMPSGEModel
    name::String
    subsectors::AbstractArray{ScalarConsumer,N}
    index::Any
    description::String
    IndexedConsumer(model::AbstractMPSGEModel, name::String, subsectors::AbstractArray{<:ScalarConsumer}, index; description::String = "")  = new{length(axes(subsectors))}(model, name, subsectors, index, description)
end

const Consumer = Union{ScalarConsumer,IndexedConsumer}

mutable struct ScalarParameter <: MPSGEScalarVariable
    model::AbstractMPSGEModel
    name::String
    value::Number
    description::String
    function ScalarParameter(
            model::MPSGE.AbstractMPSGEModel,
            name::String, 
            value::Number; 
            description::String = ""
            ) 
        P = new(model, name, value, description)
        add_variable!(model, P)
        fix(P, value)
        return P
    end
end


struct IndexedParameter{N} <: MPSGEIndexedVariable{ScalarParameter,N}
    model::AbstractMPSGEModel
    name::String
    subsectors::AbstractArray{<:ScalarParameter, N}#Containers.DenseAxisArray{ScalarParameter,N}
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
    name::String
    description::String

    function ScalarAuxiliary(model::AbstractMPSGEModel, name::String; description::String = "", start=0, upper_bound=Inf, lower_bound = -Inf)
        A = new(model, name, description)
        add_variable!(model, A; start = start, upper_bound = upper_bound, lower_bound = lower_bound)
        return A
    end

    ScalarAuxiliary(model::AbstractMPSGEModel, name::Symbol; description::String = "", start=0, upper_bound=Inf, lower_bound = -Inf) = ScalarAuxiliary(model, string(name); description = description, start = start, upper_bound = upper_bound, lower_bound = lower_bound)

end

struct IndexedAuxiliary{N} <: MPSGEIndexedVariable{ScalarAuxiliary,N}
    model::AbstractMPSGEModel
    name::String
    subsectors::AbstractArray{ScalarAuxiliary,N}
    index::Any
    description::String
    IndexedAuxiliary(model::AbstractMPSGEModel, name::String, subsectors::AbstractArray{<:ScalarAuxiliary}, index, description) = new{length(axes(subsectors))}(model, name, subsectors, index, description)
    IndexedAuxiliary(model::AbstractMPSGEModel, name::String, subsectors::AbstractArray{<:ScalarAuxiliary}, index; description::String = "") = new{length(axes(subsectors))}(model, name, subsectors, index, description)
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
    name::String
    base_name::String
    elasticity::MPSGEquantity
    function ScalarNest(name::String, base_name::String, elasticity::MPSGEquantity)
        new(name, base_name, elasticity)
    end
end


base_name(N::ScalarNest) = Symbol(N.base_name)
name(N::ScalarNest) = Symbol(N.name)
elasticity(N::ScalarNest) = N.elasticity

struct IndexedNest{N} <: AbstractArray{ScalarNest, N}
    name::String
    subsectors::DenseAxisArray{ScalarNest,N}
    index::Any
    function IndexedNest(name::String, subsectors::AbstractArray{<:ScalarNest}, index) 
        N = new{length(axes(subsectors))}(name, subsectors, index)
        return N
    end
end

const Nest = Union{ScalarNest, IndexedNest}


name(N::IndexedNest) = Symbol(N.name)
base_name(N::IndexedNest) = Symbol(N.name)
Base.getindex(V::IndexedNest, index...) = V.subsectors[index...]
Base.getindex(A::IndexedNest, idx::CartesianIndex) = A.subsectors[idx]

JuMP.index(N::IndexedNest) = N.index
Base.axes(N::IndexedNest) = axes(N.subsectors)
Base.size(N::IndexedNest) = size(N.subsectors)
Base.length(N::IndexedNest) = length(N.subsectors)
Base.broadcastable(N::IndexedNest) = N.subsectors



mutable struct Node
    model::AbstractMPSGEModel
    parent::Union{Node, Nothing}
    children::Vector{Union{Node,Netput}}
    data::ScalarNest
    cost_function_virtual::Union{Nothing,JuMP.VariableRef}
    cost_function::MPSGEquantity 
    netput_sign::Int
    function Node(model::AbstractMPSGEModel, data::ScalarNest; children = [], netput_sign::Int = 0)
        N = new(model, nothing, children, data, nothing, 0, netput_sign) #Cost function is set after trees are built
        for child in children 
            set_parent!(child, N)
        end
        return N
    end
end

model(N::Node) = N.model
quantity(N::Node) = base_quantity(N)
base_quantity(N::Node) = sum(quantity(c) for c∈children(N); init=0)
base_name(N::Node) = base_name(N.data)
name(N::Node) = name(N.data)
children(N::Node) = N.children
#
elasticity(N::Node) = elasticity(N.data)
parent(N::Node) = N.parent
netput_sign(N::Node) = N.netput_sign

set_sign(::Nothing, ::Int) = nothing

function set_sign(N::Node, new_sign::Int)
    if netput_sign(N) != 0 && new_sign != netput_sign(N)
        error("The nest $(name(N)) appears in both an input and output nest "*
              "This is not allowed, please check you model.")
    end

    if netput_sign(N) == new_sign
        return
    end

    N.netput_sign = new_sign
    set_sign(parent(N), new_sign)
    return 
end

function set_sign(N::Node, netput::Netput)
    set_sign(N, netput_sign(netput))
end


#cost_function(N::Node; virtual = false) = !virtual ? N.cost_function : N.cost_function_virtual

function cost_function(N::MPSGE.Netput; virtual = false)
    C = commodity(N)
    sign = MPSGE.netput_sign(N)
    rp = MPSGE.reference_price(N)
    return C*(1-sign*sum(MPSGE.tax(t) for t∈taxes(N);init = 0))/rp
end


function cost_function(N::MPSGE.Node; virtual = :full, cf = cost_function)

    @assert virtual in [:full, :virtual, :partial] "virtual must be one of :full, :virtual, or :partial"

    if virtual == :virtual
        return N.cost_function_virtual
    end

    virtual_adjust = if virtual == :partial
        :virtual
    else
        :full
    end

    sign = MPSGE.netput_sign(N)
    if !(isa(MPSGE.elasticity(N), Real))

        jm = jump_model(model(N))

        #This must be an explicit expression, otherwise it's evaluated now. 
        cost_function = @expression(jm, ifelse(
                    MPSGE.elasticity(N) * sign == -1,
                    cobb_douglass(N, virtual = virtual_adjust), 
                    CES(N, virtual = virtual_adjust)
                ))
    elseif MPSGE.elasticity(N)*sign == -1 #Cobb-Douglas is only on demand side with σ=1
        cost_function = cobb_douglass(N; virtual = virtual_adjust, cf = cf)
    else
        cost_function = CES(N; virtual = virtual_adjust, cf = cf)
    end

    return cost_function

end


function set_parent!(child::Node,   parent::Node; add_child=false) 
    child.parent = parent
    if add_child
        push!(parent.children, child)
    end
end

# Going to need to modify so child can be either scalar or indexed FUTURE
function set_parent!(child::Netput, parent::Node; add_child=false) 
    set_sign(parent, child)
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
        v = virtual ? :virtual : :full
        return sum(quantity.(N[nest]).*cost_function.(N[nest]; virtual = v))
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
    commodities::Dict{ScalarCommodity,Vector{ScalarSector}} # Generated when production is added
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

