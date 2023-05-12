struct ParameterRef
    model
    index::Int
    subindex::Any
    subindex_names::Any
end

struct SectorRef
    model
    index::Int
    subindex::Any
    subindex_names::Any
end

struct CommodityRef
    model
    index::Int
    subindex::Any
    subindex_names::Any
end

struct ConsumerRef
    model
    index::Int
    subindex::Any
    subindex_names::Any
end

struct AuxRef
    model
    index::Int
    subindex::Any
    Subindex_names::Any
end

abstract type Parameter end;

mutable struct ScalarParameter <: Parameter
    name::Symbol
    value::Float64
    description::String

    function ScalarParameter(name::Symbol; value::Float64=1., description::AbstractString="")
        return new(name, value, description)
    end
end

mutable struct IndexedParameter <: Parameter
    name::Symbol
    indices::Any
    value::DenseAxisArray
    description::String

    function IndexedParameter(name::Symbol, indices; value::Float64=1., description::AbstractString="")
        return new(name, indices, DenseAxisArray(fill(value, length.(indices)...), indices...), description)
    end
end

function Parameter(name; indices=nothing, kwargs...)
    return indices===nothing ? ScalarParameter(name; kwargs...) : IndexedParameter(name, indices; kwargs...)
end

abstract type Sector end;

mutable struct ScalarSector <: Sector
    name::Symbol
    benchmark::Float64
    description::String
    fixed::Bool

    function ScalarSector(name::Symbol; description::AbstractString="", benchmark::Float64=1., fixed=false)
        return new(name, benchmark, description, fixed)
    end
end

mutable struct IndexedSector <: Sector
    name::Symbol
    indices::Any
    benchmark::DenseAxisArray
    description::String
    fixed::DenseAxisArray

    function IndexedSector(name::Symbol, indices; description::AbstractString="", benchmark::Float64=1., fixed=false)
        return new(name, indices, DenseAxisArray(fill(benchmark, length.(indices)...), indices...), description, DenseAxisArray(fill(fixed, length.(indices)...), indices...))
    end
end

function Sector(name; indices=nothing, kwargs...)
    return indices===nothing ? ScalarSector(name; kwargs...) : IndexedSector(name, indices; kwargs...)
end

abstract type Commodity end;

mutable struct ScalarCommodity <: Commodity
    name::Symbol
    benchmark::Float64
    description::String
    fixed::Bool

    function ScalarCommodity(name::Symbol; description::AbstractString="", benchmark::Float64=1., fixed=false)
        return new(name, benchmark, description, fixed)
    end
end

mutable struct IndexedCommodity <: Commodity
    name::Symbol
    indices::Any
    benchmark::DenseAxisArray
    description::String
    fixed::DenseAxisArray

    function IndexedCommodity(name::Symbol, indices; description::AbstractString="", benchmark::Float64=1., fixed=false)
        return new(name, indices, DenseAxisArray(fill(benchmark, length.(indices)...), indices...), description, DenseAxisArray(fill(fixed, length.(indices)...), indices...))
    end
end

function Commodity(name; indices=nothing, kwargs...)
    return indices===nothing ? ScalarCommodity(name; kwargs...) : IndexedCommodity(name, indices; kwargs...)
end

abstract type Consumer end;

mutable struct ScalarConsumer <: Consumer
    name::Symbol
    benchmark::Float64
    description::String
    fixed::Bool
    
    function ScalarConsumer(name::Symbol; description::AbstractString="", benchmark::Float64=1., fixed=false)
        return new(name, benchmark, description, fixed)
    end
end

mutable struct IndexedConsumer <: Consumer
    name::Symbol
    indices::Any
    benchmark::DenseAxisArray
    description::String
    fixed::DenseAxisArray

    function IndexedConsumer(name::Symbol, indices; description::AbstractString="", benchmark::Float64=1., fixed=false)
        return new(name, indices, DenseAxisArray(fill(benchmark, length.(indices)...), indices...), description, DenseAxisArray(fill(fixed, length.(indices)...), indices...))
    end
end

function Consumer(name; indices=nothing, kwargs...)
    return indices===nothing ? ScalarConsumer(name; kwargs...) : IndexedConsumer(name, indices; kwargs...)
end

abstract type Aux end;

mutable struct ScalarAux <: Aux
    name::Symbol
    benchmark::Float64
    description::String
    fixed::Bool

    function ScalarAux(name::Symbol; description::AbstractString="", benchmark::Float64=1., fixed=false)
        return new(name, benchmark, description, fixed)
    end
end

mutable struct IndexedAux <: Aux
    name::Symbol
    indices::Any
    benchmark::DenseAxisArray
    description::String
    fixed::DenseAxisArray

    function IndexedAux(name::Symbol, indices; description::AbstractString="", benchmark::Float64=1., fixed=false)
        return new(name, indices, DenseAxisArray(fill(benchmark, length.(indices)...), indices...), description, DenseAxisArray(fill(fixed, length.(indices)...), indices...))
    end
end

function Aux(name; indices=nothing, kwargs...)
    return indices===nothing ? ScalarAux(name; kwargs...) : IndexedAux(name, indices; kwargs...)
end

struct Tax
    rate::Union{Float64,Expr}
    agent::ConsumerRef
end

mutable struct Input
    commodity::Any
    quantity::Union{Float64,Expr}
    taxes::Vector{Tax}
    price::Float64
    production_function::Any

    function Input(commodity, quantity::Union{Float64,Expr}, taxes::Vector{Tax}=Tax[], price::Float64=1.)
        return new(commodity, quantity, taxes, price, nothing)
    end
end

mutable struct Output
    commodity::CommodityRef
    quantity::Union{Float64,Expr}
    taxes::Vector{Tax}
    price::Float64
    production_function::Any

    function Output(commodity::CommodityRef, quantity::Union{Float64,Expr}, taxes::Vector{Tax}=Tax[], price::Float64=1.)
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

mutable struct Demand
    commodity::Any
    quantity::Union{Float64,Expr}
    demand_function::Any

    function Demand(commodity, quantity::Union{Float64,Expr})
        return new(commodity, quantity, nothing)
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

mutable struct Model
    _parameters::Vector{Parameter}
    _sectors::Vector{Sector}
    _commodities::Vector{Commodity}
    _consumers::Vector{Consumer}
    _auxs::Vector{Aux}

    _productions::Vector{Production}
    _demands::Vector{DemandFunction}
    _auxconstraints::Vector{AuxConstraint}

    _jump_model::Union{Nothing,JuMP.Model}
    _status

    _nlexpressions::Vector{Any}

    function Model()
        return new(
            Parameter[],
            Sector[],
            Commodity[],
            Consumer[],
            Aux[],
            Production[],
            DemandFunction[],
            AuxConstraint[],
            nothing,
            nothing,
            []
        )
    end
end


function Base.show(io::IO, m::Model)
    println(io, "MPSGE model with $(length(m._sectors)) sectors, $(length(m._commodities)) commodities and $(length(m._consumers)) consumers.")

    if length(m._sectors) > 0
        print(io, "  Sectors: ")
        print(io, join(["$(s.name) (bm=$(s.benchmark))" for s in m._sectors], ", "))
        println(io)
    end

    if length(m._commodities) > 0
        print(io, "  Commodities: ")
        print(io, join(["$(c.name) (bm=$(c.benchmark))" for c in m._commodities], ", "))
        println(io)
    end

    if length(m._consumers) > 0
        print(io, "  Consumers: ")
        print(io, join(["$(c.name) (bm=$(c.benchmark))" for c in m._consumers], ", "))
        println(io)
    end

    if length(m._auxs) > 0
        print(io, "  Auxs: ")
        print(io, join(["$(a.name) (bm=$(a.benchmark))" for a in m._auxs], ", "))
        println(io)
    end

    if m._jump_model!==nothing
        if m._status==:Solved
            println(io, "Solution:")

            for n in JuMP.all_variables(m._jump_model)
                println(io, "  $n:\t$(Complementarity.result_value(n))")
            end        
        else
            println(io, "Did not solve with error: $(m._status).")
        end
    end
end

function get_name(sector::SectorRef, include_subindex=false)
    if sector.subindex===nothing || include_subindex==false
        return sector.model._sectors[sector.index].name
    else
        return Symbol("$(sector.model._sectors[sector.index].name )[$(join(string.(sector.subindex_names), ", "))]") 
    end
end

function get_name(commodity::CommodityRef, include_subindex=false)
    if commodity.subindex===nothing || include_subindex==false
        return commodity.model._commodities[commodity.index].name
    else
        return Symbol("$(commodity.model._commodities[commodity.index].name )[$(join(string.(commodity.subindex_names), ", "))]") 
    end
end

function get_name(consumer::ConsumerRef, include_subindex=false)
    if consumer.subindex===nothing || include_subindex===false
        return consumer.model._consumers[consumer.index].name
    else
        return Symbol("$(consumer.model._consumers[consumer.index].name )[$(join(string.(consumer.subindex_names), ", "))]") 
    end 
end

function get_name(aux::AuxRef, include_subindex=false)
    if aux.subindex===nothing || include_subindex===false
        return aux.model._auxs[aux.index].name
    else
        return Symbol("$(aux.model._auxs[aux.index].name )[$(join(string.(aux.subindex_names), ", "))]") 
    end 
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

function get_consumer_total_endowment(jm, c::ConsumerRef)
    m = c.model

    endowments = []
    for d in m._demands
        if d.consumer == c
            push!(endowments, :(
                +($((:($(en.quantity) * 
                $(en.commodity)) for en in d.endowments)...))
            ))
        end
    end
    total_end = :(+(0., $(get_tax_revenue_for_consumer(jm, m, c)),  $(endowments...)))

    return total_end

end

function get_consumer_total_endowment(jm, m, c::ScalarConsumer)
    endowments = []
    for d in m._demands
        if get_full(d.consumer) == c
            push!(endowments, :(
                +($((:($(en.quantity) * 
                $(en.commodity)) for en in d.endowments)...))
            ))
        end
    end

    total_end = :(+(0., $(get_tax_revenue_for_consumer(jm, m, c)),  $(endowments...)))

    return total_end
end

function get_consumer_total_endowment(jm, m, c::IndexedConsumer, i)
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

function Input(commodity, quantity::Number, taxes::Vector{Tax}=Tax[], price::Float64=1.)
    return Input(commodity, convert(Float64, quantity), taxes, price)
end

function Output(commodity::CommodityRef, quantity::Number, taxes::Vector{Tax}=Tax[], price::Float64=1.)
    return Output(commodity, convert(Float64, quantity), taxes, price)
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

function Demand(commodity, quantity::Number)
    return Demand(commodity, convert(Float64, quantity))
end

function add!(m::Model, s::ScalarSector)
    m._jump_model = nothing
    push!(m._sectors, s)
    return SectorRef(m, length(m._sectors), nothing, nothing)
end

function add!(m::Model, s::IndexedSector)
    m._jump_model = nothing
    push!(m._sectors, s)

    temp_array = Array{SectorRef}(undef, length.(s.indices)...)

    for i in CartesianIndices(temp_array)
        temp_array[i] = SectorRef(m, length(m._sectors), i, Tuple(s.indices[j][v] for (j,v) in enumerate(Tuple(i))))
    end
    return JuMP.Containers.DenseAxisArray(temp_array, s.indices...)
end

function add!(m::Model, c::ScalarCommodity)
    m._jump_model = nothing
    push!(m._commodities, c)
    return CommodityRef(m, length(m._commodities), nothing, nothing)
end

function add!(m::Model, c::IndexedCommodity)
    m._jump_model = nothing
    push!(m._commodities, c)

    temp_array = Array{CommodityRef}(undef, length.(c.indices)...)

    for i in CartesianIndices(temp_array)
        temp_array[i] = CommodityRef(m, length(m._commodities), i, Tuple(c.indices[j][v] for (j,v) in enumerate(Tuple(i))))
    end
    return JuMP.Containers.DenseAxisArray(temp_array, c.indices...)
end

function add!(m::Model, cn::ScalarConsumer)
    m._jump_model = nothing
    push!(m._consumers, cn)
    cr = ConsumerRef(m, length(m._consumers), nothing, nothing)
    return cr
end

function add!(m::Model, cn::IndexedConsumer)
    m._jump_model = nothing
    push!(m._consumers, cn)

    temp_array = Array{ConsumerRef}(undef, length.(cn.indices)...)

    for i in CartesianIndices(temp_array)
        temp_array[i] = ConsumerRef(m, length(m._consumers), i, Tuple(cn.indices[j][v] for (j,v) in enumerate(Tuple(i))))
    end
    cr = JuMP.Containers.DenseAxisArray(temp_array, cn.indices...)
    return cr
end

function add!(m::Model, a::ScalarAux)
    m._jump_model = nothing
    push!(m._auxs, a)
    ar = AuxRef(m, length(m._auxs), nothing, nothing)
    return ar
end

function add!(m::Model, a::IndexedAux)
    m._jump_model = nothing
    push!(m._auxs, a)

    temp_array = Array{AuxRef}(undef, length.(a.indices)...)

    for i in CartesianIndices(temp_array)
        temp_array[i] = AuxRef(m, length(m._auxs), i, Tuple(a.indices[j][v] for (j,v) in enumerate(Tuple(i))))
    end
    ar = JuMP.Containers.DenseAxisArray(temp_array, a.indices...)
    return ar
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

            new_input = Input(commodity_ref, v.quantity, v.taxes, v.price)
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
    return ParameterRef(m, length(m._parameters), nothing, nothing)
end

function add!(m::Model, p::IndexedParameter)
    m._jump_model = nothing
    push!(m._parameters, p)

    temp_array = Array{ParameterRef}(undef, length.(p.indices)...)

    for i in CartesianIndices(temp_array)
        temp_array[i] = ParameterRef(m, length(m._parameters), i, Tuple(p.indices[j][v] for (j,v) in enumerate(Tuple(i))))
    end
    return JuMP.Containers.DenseAxisArray(temp_array, p.indices...)
end

function JuMP.value(m::Model, name::Symbol)
    Complementarity.result_value(m._jump_model[name])
end

function solve!(m::Model; solver::Symbol=:PATH, kwargs...)
    if m._jump_model===nothing
        m._jump_model = build(m)
    end

    set_all_start_values(m)
    set_all_parameters(m)
    set_all_bounds(m)

    m._status = Complementarity.solveMCP(m._jump_model; solver=solver, kwargs...)

    return m
end

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

    c.model._commodities[c.index].benchmark = new_value
end

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
            return CommodityRef(x.model, i, nothing, nothing)
        end
    end
end
