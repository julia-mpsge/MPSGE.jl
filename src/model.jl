

"""
   Input(inputname::Symbol, value::Float64; taxes=taxes::Vector{Tax}, price=price::Union{Float64,Expr}=1.)
    The struct that stores all the elements of an Input.
### Options
        Taxes and price are optional, keyword must be used.

### Example
```julia-repl
julia> Input(:PL, 50, taxes=[Tax(1., RA)], price=1.2)
```
"""
mutable struct Input
    commodity::Any
    quantity::Union{Float64,Expr}
    taxes::Vector{Tax}
    price::Union{Float64,Expr}
    production_function::Any

    function Input(commodity, quantity::Union{Float64,Expr}; taxes::Vector{Tax}=Tax[], price::Union{Float64,Expr}=1.)
        return new(commodity, quantity, taxes, price, nothing)
    end
end

"""
   Output(outputname::Symbol, value::Float64; taxes=taxes::Vector{Tax}, price=price::Union{Float64,Expr}=1.)
    The struct that stores all the elements of an Input.
### Options
        Taxes and price are optional, keyword must be used.

### Example
```julia-repl
julia> Output(:PU, 50, taxes=[Tax(0.1, CONS)], price=.9)
```
"""
mutable struct Output
    commodity::CommodityRef
    quantity::Union{Float64,Expr}
    taxes::Vector{Tax}
    price::Union{Float64,Expr}
    production_function::Any

    function Output(commodity::CommodityRef, quantity::Union{Float64,Expr}; taxes::Vector{Tax}=Tax[], price::Union{Float64,Expr}=1.)
        return new(commodity, quantity, taxes, price, nothing)
    end
end

struct Production
    sector::SectorRef
    tr_elasticity::Union{Float64,Expr}
    elasticity::Union{Float64,Expr}
    outputs::Vector{Output}
    inputs::Vector{Input}

    function Production(sector::SectorRef, tr_elasticity::Union{Float64,Expr}, elasticity::Union{Float64,Expr}, outputs::Vector{Output}, inputs::Vector{Input})
        x = new(sector, tr_elasticity, elasticity, outputs, inputs)

        for output in outputs
            output.production_function = x
        end
        
        for input in inputs
            input.production_function = x
        end

        return x
    end
end

struct Nest
    name::Symbol
    elasticity::Union{Float64,Expr}
    benchmark::Union{Float64,Expr}
    inputs::Vector{Input}    
end

struct Endowment
    commodity::CommodityRef
    quantity::Union{Float64,Expr}
end

struct Implicitvar
    name::Symbol
    type::Any
end

mutable struct Demand
    commodity::Any
    quantity::Union{Float64,Expr}
    price::Union{Float64,Expr}
    demand_function::Any

    function Demand(commodity, quantity::Union{Float64,Expr}, price::Union{Float64,Expr}=1.)
        return new(commodity, quantity, price, nothing)
    end
end

struct DemandFunction
    consumer::ConsumerRef
    elasticity::Union{Float64,Expr}
    demands::Vector{Demand}
    endowments::Vector{Endowment}

    function DemandFunction(consumer::ConsumerRef, elasticity::Union{Float64,Expr}, demands::Vector{Demand}, endowments::Vector{Endowment})
        x = new(consumer, elasticity, demands, endowments)

        for demand in demands
            demand.demand_function = x
        end
        
        return x
    end
end

struct AuxConstraint
    aux::AuxRef
    equation
end

"""
   Model()
    The struct that stores all the elements of the model.

### Example
```julia-repl
julia> foo = Model()
```
"""
mutable struct Model
    _object_dict::Dict

    _parameters::Vector{Parameter}
    _sectors::Vector{Union{ScalarSector,IndexedSector}}
    _commodities::Vector{Union{ScalarCommodity,IndexedCommodity}}
    _consumers::Vector{Union{ScalarConsumer,IndexedConsumer}}
    _auxs::Vector{Union{ScalarAux,IndexedAux}}
    _implicitvars::Vector{Implicitvar}
    _implicitvarsDict::Dict{Symbol, ImplicitvarRef}

    _productions::Vector{Production}
    _demands::Vector{DemandFunction}
    _auxconstraints::Vector{AuxConstraint}

    _jump_model::Union{Nothing,JuMP.Model}
    _status

    _nlexpressions::Any

    function Model()
        return new(
            Dict(),
            Parameter[],
            Vector{Union{ScalarSector,IndexedSector}}(),
            Vector{Union{ScalarCommodity,IndexedCommodity}}(),
            Vector{Union{ScalarConsumer,IndexedConsumer}}(),
            Vector{Union{ScalarAux,IndexedAux}}(),
            Implicitvar[],
            Dict{Symbol, ImplicitvarRef}(),

            Production[],
            DemandFunction[],
            AuxConstraint[],
            nothing,
            nothing,
            (
                comp_demand=[],
                comp_supply=[],
                final_demand=[],
                zero_profit=[],
                market_clearance=[],
                income_balance=[],
                aux=[]
            )
        )
    end
end


function Base.getindex(m::Model,idx::Symbol)
    return m._object_dict[idx]
end

function get_name(mpsge_var::MPSGERef, include_subindex=false)
    if mpsge_var.subindex===nothing || include_subindex==false
        return mpsge_var.name
    else
        return Symbol("$(mpsge_var.name)[$(join(string.(mpsge_var.subindex_names), ", "))]") 
    end
end


function get_name(im::ImplicitvarRef, include_subindex=false)
    # if im.subindex===nothing || include_subindex===false
        return im.model._implicitvars[im.index].name
    # else
    #     return Symbol("$(im.model._implicitvars[im.index].name )[$(join(string.(im.subindex_names), ", "))]") 
    # end 
end

function get_full(s::SectorRef)
    return s.model._sectors[s.index]
end

function get_full(c::CommodityRef)
    return c.model._commodities[c.index]
end

function get_full(c::ConsumerRef)
    return c.model._consumers[c.index]
end

function get_full(a::AuxRef)
    return a.model._auxs[a.index]
end

function get_full(p::ParameterRef)
    return p.model._parameters[p.index]
end

function get_commodity_benchmark(c::CommodityRef)
    if c.subindex===nothing
        return get_full(c).benchmark
    else
        return get_full(c).benchmark[c.subindex]
    end
end

function get_consumer_benchmark(c::ConsumerRef)
    if c.subindex===nothing
        return get_full(c).benchmark
    else
        return get_full(c).benchmark[c.subindex]
    end
end

function get_consumer_total_endowment(jm, m, c::ScalarConsumer)
    endowments = []
    for d in m._demands
        if get_full(d.consumer) == c
            push!(endowments, 
                +(
                    (tojump(jm, en.quantity) * tojump(jm, en.commodity) for en in d.endowments)...
                )
            )
        end
    end

    total_end = +(0., get_tax_revenue_for_consumer(jm, m, c),  endowments...)

    return total_end
end

function get_consumer_total_endowment(jm, m, c::IndexedConsumer, i)
    endowments = []
    for d in m._demands
        c_for_d = get_full(d.consumer)
        
        if c_for_d == c && d.consumer.subindex_names == i
            push!(endowments, 
                +(
                    (tojump(jm, en.quantity) * tojump(jm, en.commodity) for en in d.endowments)...
                )
            )
        end
    end

    return +(0., endowments...)
end

function get_consumer_total_endowment_old(jm, m, c::ScalarConsumer)
    endowments = []
    for d in m._demands
        if get_full(d.consumer) == c
            push!(endowments, :(
                +($((:($(en.quantity) * 
                $(en.commodity)) for en in d.endowments)...))
            ))
        end
    end

    total_end = :(+(0., $(get_tax_revenue_for_consumer_old(jm, m, c)),  $(endowments...)))

    return total_end
end

function get_consumer_total_endowment_old(jm, m, c::IndexedConsumer, i)
    endowments = []
    for d in m._demands
        c_for_d = get_full(d.consumer)
        
        if c_for_d == c && d.consumer.subindex_names == i
            push!(endowments, :(
                +($((:($(en.quantity) * 
                $(en.commodity)) for en in d.endowments)...))
            ))
        end
    end

    return :(+(0., $(endowments...)))
end


# Outer constructors

function Input(commodity, quantity::Number; taxes::Vector{Tax}=Tax[], price::Union{Float64,Expr}=1.)
    return Input(commodity, convert(Float64, quantity), taxes=taxes, price=price)
end

function Output(commodity::CommodityRef, quantity::Number; taxes::Vector{Tax}=Tax[], price::Union{Float64,Expr}=1.)
    return Output(commodity, convert(Float64, quantity), taxes=taxes, price=price)
end

function Production(sector::SectorRef, tr_elasticity::Union{Number,Expr}, elasticity::Union{Number,Expr}, outputs::Vector{Output}, inputs::Vector{Input})

    if isa(tr_elasticity,Number)
        tr_elasticity = convert(Float64, tr_elasticity)
    end
    if isa(elasticity,Number)
        elasticity = convert(Float64, elasticity)
    end
    
    return Production(sector, tr_elasticity, elasticity, outputs, inputs)
end

function Endowment(commodity::CommodityRef, quantity::Number)
    return Endowment(commodity, convert(Float64, quantity))
end

function Demand(commodity, quantity::Number, price::Union{Float64,Expr}=1.)
    return Demand(commodity, convert(Float64, quantity), price)
end


function _add!(m::Model,s::MPSGEScalar,output_type,model_array)
    m._jump_model = nothing
    push!(model_array, s)

    s_ref = output_type(m, length(model_array), s.name,nothing, nothing)
    m._object_dict[s.name] = s

    return s_ref
end

function _add!(m::Model,s::MPSGEIndexed,output_type, model_array)
    m._jump_model = nothing
    push!(model_array, s)
    m._object_dict[s.name] = s

    temp_array = Array{output_type}(undef, length.(s.indices)...)

    for i in CartesianIndices(temp_array)
        temp_array[i] = output_type(m, length(model_array), s.name, i, Tuple(s.indices[j][v] for (j,v) in enumerate(Tuple(i))))
    end

    return JuMP.Containers.DenseAxisArray(temp_array, s.indices...)
end

"""
    add!(m,bar)
    Function that adds an element to the model with a name assignment
    m::Model is always the first Argument

    # Options
    Parameter::ScalarParameter, ::IndexedParameter
    Commodity::ScalarCommodity, ::IndexedCommodity
    Sector::ScalarSector,       ::IndexedSector
    Consumer::ScalarConsumer,   ::IndexedConsumer
    Aux::ScalarAux,             ::IndexedAux
### Example
```julia-repl
julia> S = add!(m, Sector())
```
    Production::Production
    Demand::DemandFunction
    AuxConstraint::AuxConstraint
### Example
```julia-repl
julia> add!(m, Production()) 
```
"""
function add!(m::Model, s::ScalarSector)
    _add!(m,s, SectorRef,m._sectors)
end

function add!(m::Model, s::IndexedSector)
    _add!(m,s,SectorRef,m._sectors)
end

function add!(m::Model, c::ScalarCommodity)
    _add!(m,c, CommodityRef, m._commodities)
end

function add!(m::Model, c::IndexedCommodity)
    _add!(m,c, CommodityRef, m._commodities)
end

function add!(m::Model, cn::ScalarConsumer)
    _add!(m,cn, ConsumerRef, m._consumers)
end

function add!(m::Model, cn::IndexedConsumer)
    _add!(m,cn, ConsumerRef, m._consumers)
end

function add!(m::Model, a::ScalarAux)
    _add!(m,a, AuxRef, m._auxs)
end

function add!(m::Model, a::IndexedAux)
    _add!(m,a, AuxRef, m._auxs)
end

function add!(m::Model, p::Production)
    m._jump_model = nothing

    for (i,v) in enumerate(p.inputs)        
        if v.commodity isa Nest
            sector_name = Symbol("$(get_name(p.sector))→$(v.commodity.name)")
            commodity_name = Symbol("P$(get_name(p.sector))→$(v.commodity.name)")
            sector_ref = add!(m, Sector(sector_name))
            commodity_ref = add!(m, Commodity(commodity_name))
            add!(m, Production(sector_ref, 0, v.commodity.elasticity, [Output(commodity_ref, v.commodity.benchmark)], v.commodity.inputs))

            new_input = Input(commodity_ref, v.quantity, taxes=v.taxes, price=v.price)
            new_input.production_function = v.production_function
            p.inputs[i] = new_input
        end
    end

    push!(m._productions, p)
    return m
end

function add!(m::Model, c::DemandFunction)
    m._jump_model = nothing

    for (i,v) in enumerate(c.demands)        
        if v.commodity isa Nest
            sector_name = Symbol("$(get_name(c.consumer))→$(v.commodity.name)")
            commodity_name = Symbol("P$(get_name(c.consumer))→$(v.commodity.name)")
            sector_ref = add!(m, Sector(sector_name))
            commodity_ref = add!(m, Commodity(commodity_name))
            add!(m, Production(sector_ref, 0, v.commodity.elasticity, [Output(commodity_ref, v.commodity.benchmark)], v.commodity.inputs))

            new_Input = Demand(commodity_ref, v.quantity)
            new_Input.demand_function = v.demand_function
            c.demands[i] = new_Input
        end
    end

    push!(m._demands, c)
    return m
end

function add!(m::Model, ac::AuxConstraint)
    m._jump_model = nothing
    push!(m._auxconstraints, ac)
    return m
end

function add!(m::Model, p::ScalarParameter)
    m._jump_model = nothing
    push!(m._parameters, p)
    return ParameterRef(m, length(m._parameters),p.name, nothing, nothing)
end

function add!(m::Model, p::IndexedParameter)
    m._jump_model = nothing
    push!(m._parameters, p)

    temp_array = Array{ParameterRef}(undef, length.(p.indices)...)

    for i in CartesianIndices(temp_array)
        temp_array[i] = ParameterRef(m, length(m._parameters),  p.name,i, Tuple(p.indices[j][v] for (j,v) in enumerate(Tuple(i))))
    end
    return JuMP.Containers.DenseAxisArray(temp_array, p.indices...)
end

function add!(m::Model, im::Implicitvar)
    m._jump_model = nothing
    push!(m._implicitvars, im)
    push!(m._implicitvarsDict,im.name=>ImplicitvarRef(m, length(m._implicitvars),im.name, nothing, nothing))
end


function JuMP.value(m::Model, name::Symbol)
    JuMP.value(m._jump_model[name])
end

"""
    solve!(m::Model; solver=solvername, keywords)
    Function to solve the model. Triggers the build if the model hasn't been built yet.
### Argumenents
    See @Complementarity.solveMCP() for full list of argument Options
### Example
```julia-repl
julia> solve!(m, cumulative_iteration_limit=0)
```
"""
function solve!(m::Model; kwargs...)
    if m._jump_model===nothing
        m._jump_model = build(m)
    end

    JuMP.set_optimizer(m._jump_model, PATHSolver.Optimizer)

    for (k,v) in kwargs
        JuMP.set_attribute(m._jump_model, string(k), v)
    end


    set_all_start_values(m)
    set_all_parameters(m)
    set_all_bounds(m)

    JuMP.optimize!(m._jump_model)

    if JuMP.termination_status(m._jump_model) != JuMP.LOCALLY_SOLVED
        m._status = JuMP.termination_status(m._jump_model)
    else
        m._status = :Solved
    end

    return m
end
"""
    set_value(P, value::Float64)
    Function that allows users to set a specific value for a variable, updating the benchmark field.
### Options
    Parameter::ScalarParameter, ::IndexedParameter
    Commodity::ScalarCommodity, ::IndexedCommodity
    Sector::ScalarSector,       ::IndexedSector
    Consumer::ScalarConsumer,   ::IndexedConsumer
    Aux::ScalarAux,             ::IndexedAux
### Example
```julia-repl
julia> set_value(var, 1.3)
```
"""
function JuMP.set_value(parameter::ParameterRef, new_value::Float64)
    p = parameter.model._parameters[parameter.index]
    if p isa ScalarParameter
        p.value = new_value
    else
        p.value[parameter.subindex] = new_value
    end
    return nothing
end

function get_value(parameter::ParameterRef)
    p = parameter.model._parameters[parameter.index]
    if p isa ScalarParameter
        return p.value
    else
        return p.value[parameter.subindex]
    end
end

function JuMP.set_value(consumer::ConsumerRef, new_value::Float64)
    c = consumer.model._consumers[consumer.index]
    if c isa ScalarConsumer
        c.benchmark = new_value
    else
        c.benchmark[consumer.subindex] = new_value
    end
    return nothing
end

function JuMP.set_value(sector::SectorRef, new_value::Float64)
    s = sector.model._sectors[sector.index]
    if s isa ScalarSector
        s.benchmark = new_value
    else
        s.benchmark[sector.subindex] = new_value
    end
    return nothing
end

function JuMP.set_value(aux::AuxRef, new_value::Float64)
    a = aux.model._auxs[aux.index]
    if a isa ScalarAux
        a.benchmark = new_value
    else
        a.benchmark[aux.subindex] = new_value
    end
    return nothing
end

function JuMP.set_value(commodity::CommodityRef, new_value::Float64)
    c = commodity.model._commodities[commodity.index]
    if c isa ScalarCommodity
        c.benchmark = new_value
    else
        c.benchmark[commodity.subindex] = new_value
    end
    return nothing

    # c.model._commodities[c.index].benchmark = new_value
end

"""
    set_fixed!(P, true::Boolean)
    Function that allows users to fix a value for a variable, the benchmark, the value from set_value, or the previous value.
### Options
    Parameter::ScalarParameter, ::IndexedParameter
    Commodity::ScalarCommodity, ::IndexedCommodity
    Sector::ScalarSector,       ::IndexedSector
    Consumer::ScalarConsumer,   ::IndexedConsumer
    Aux::ScalarAux,             ::IndexedAux
### Example
```julia-repl
julia> set_fixed!(var, false)
```
"""
function set_fixed!(commodity::CommodityRef, new_value::Bool)    
    c = commodity.model._commodities[commodity.index]
    if c isa ScalarCommodity
        c.fixed = new_value
    else
        c.fixed[commodity.subindex] = new_value
    end
    return nothing
end

function set_fixed!(consumer::ConsumerRef, new_value::Bool)    
    c = consumer.model._consumers[consumer.index]
    if c isa ScalarConsumer
        c.fixed = new_value
    else
        c.fixed[consumer.subindex] = new_value
    end
    return nothing
end

function set_fixed!(aux::AuxRef, new_value::Bool)    
    a = aux.model._auxs[aux.index]
    if a isa ScalarAux
        a.fixed = new_value
    else
        a.fixed[aux.subindex] = new_value
    end
    return nothing
end

function set_fixed!(sector::SectorRef, new_value::Bool)    
    s = sector.model._sectors[sector.index]
    if s isa ScalarSector
        s.fixed = new_value
    else
        s.fixed[sector.subindex] = new_value
    end
    return nothing
end

function get_nested_commodity(x::SectorRef, name::Symbol)
    for (i,v) in enumerate(x.model._commodities)
        if v.name == Symbol("P$(get_name(x))→$name")
            return CommodityRef(x.model, i, v.name, nothing, nothing)
        end
    end
end

function set_lower_bound(commodity::CommodityRef, l_bound::Float64)
    c = commodity.model._commodities[commodity.index]
    if c isa ScalarCommodity
        c.lower_bound = l_bound
    else
        c.lower_bound[commodity.subindex] = l_bound
    end
    return nothing

    # c.model._commodities[c.index].lower_bound = l_bound
end

function set_lower_bound(consumer::ConsumerRef, l_bound::Float64)
    cs = consumer.model._consumers[consumer.index]
    if cs isa ScalarConsumer
        cs.lower_bound = l_bound
    else
        cs.lower_bound[consumer.subindex] = l_bound
    end
    return nothing

    # cs.model._consumers[cs.index].lower_bound = l_bound
end

function set_lower_bound(aux::AuxRef, l_bound::Float64)
    a = aux.model._auxs[aux.index]
    if a isa ScalarAux
        a.lower_bound = l_bound
    else
        a.lower_bound[aux.subindex] = l_bound
    end
    return nothing

    # a.model._auxs[a.index].lower_bound = l_bound
end

function set_lower_bound(sector::SectorRef, l_bound::Float64)
    s = sector.model._sectors[sector.index]
    if s isa ScalarSector
        s.lower_bound = l_bound
    else
        s.lower_bound[sector.subindex] = l_bound
    end
    return nothing

    # s.model._sectors[s.index].lower_bound = l_bound
end

function set_upper_bound(commodity::CommodityRef, u_bound::Float64)
    c = commodity.model._commodities[commodity.index]
    if c isa ScalarCommodity
        c.upper_bound = u_bound
    else
        c.upper_bound[commodity.subindex] = u_bound
    end
    return nothing

    # c.model._commodities[c.index].upper_bound = u_bound
end

function set_upper_bound(consumer::ConsumerRef, u_bound::Float64)
    cs = consumer.model._consumers[consumer.index]
    if cs isa ScalarConsumer
        cs.upper_bound = u_bound
    else
        cs.upper_bound[consumer.subindex] = u_bound
    end
    return nothing

    # cs.model._consumers[cs.index].upper_bound = u_bound
end

function set_upper_bound(aux::AuxRef, u_bound::Float64)
    a = aux.model._auxs[aux.index]
    if a isa ScalarAux
        a.upper_bound = u_bound
    else
        a.upper_bound[aux.subindex] = u_bound
    end
    return nothing

    # a.model._auxs[a.index].upper_bound = u_bound
end

function set_upper_bound(sector::SectorRef, u_bound::Float64)
    s = sector.model._sectors[sector.index]
    if s isa ScalarSector
        s.upper_bound = u_bound
    else
        s.upper_bound[sector.subindex] = u_bound
    end
    return nothing

    # s.model._sectors[s.index].upper_bound = u_bound
end


