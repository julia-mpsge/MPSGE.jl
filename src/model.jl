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
    xbenchmark::Union{Nothing,Float64}
    description::String
    fixed::Bool
    
    function ScalarConsumer(name::Symbol; description::AbstractString="", benchmark::Union{Nothing,Float64}=nothing, fixed=false)
        return new(name, benchmark, description, fixed)
    end
end

mutable struct IndexedConsumer <: Consumer
    name::Symbol
    indices::Any
    xbenchmark::DenseAxisArray
    description::String
    fixed::DenseAxisArray

    function IndexedConsumer(name::Symbol, indices; description::AbstractString="", benchmark::Union{Nothing,Float64}=nothing, fixed=false)
        return new(name, indices, DenseAxisArray(fill(benchmark, length.(indices)...), indices...), description, DenseAxisArray(fill(fixed, length.(indices)...), indices...))
    end
end

function Consumer(name; indices=nothing, kwargs...)
    return indices===nothing ? ScalarConsumer(name; kwargs...) : IndexedConsumer(name, indices; kwargs...)
end

mutable struct Input
    commodity::CommodityRef
    quantity::Union{Float64,Expr}
    production_function::Any

    function Input(commodity::CommodityRef, quantity::Union{Float64,Expr})
        return new(commodity, quantity, nothing)
    end
end

mutable struct Output
    commodity::CommodityRef
    quantity::Union{Float64,Expr}
    production_function::Any

    function Output(commodity::CommodityRef, quantity::Union{Float64,Expr})
        return new(commodity, quantity, nothing)
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

struct Endowment
    commodity::CommodityRef
    quantity::Union{Float64,Expr}
end

mutable struct Demand
    commodity::CommodityRef
    quantity::Union{Float64,Expr}
    demand_function::Any

    function Demand(commodity::CommodityRef, quantity::Union{Float64,Expr})
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

mutable struct Model
    _parameters::Vector{Parameter}
    _sectors::Vector{Sector}
    _commodities::Vector{Commodity}
    _consumers::Vector{Consumer}

    _productions::Vector{Production}
    _demands::Vector{DemandFunction}

    _jump_model::Union{Nothing,JuMP.Model}
    _status

    _nlexpressions::Vector{Any}

    function Model()
        return new(
            Parameter[],
            Sector[],
            Commodity[],
            Consumer[],
            Production[],
            DemandFunction[],
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
        return Symbol("$(sector.model._sectors[sector.index].name )[$(sector.subindex_names)]")
    end
end

function get_name(commodity::CommodityRef, include_subindex=false)
    if commodity.subindex===nothing || include_subindex==false
        return commodity.model._commodities[commodity.index].name
    else
        return Symbol("$(commodity.model._commodities[commodity.index].name )[$(commodity.subindex_names)]")
    end
end

function get_name(consumer::ConsumerRef, include_subindex=false)
    if consumer.subindex===nothing || include_subindex===false
        return consumer.model._consumers[consumer.index].name
    else
        return Symbol("$(consumer.model._consumers[consumer.index].name )[$(consumer.subindex_names)]") 
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

# Outer constructors

function Input(commodity::CommodityRef, quantity::Number)
    return Input(commodity, convert(Float64, quantity))
end

function Output(commodity::CommodityRef, quantity::Number)
    return Output(commodity, convert(Float64, quantity))
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

function Demand(commodity::CommodityRef, quantity::Number)
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
        # TODO Fix the [1] thing here to properly work with n-dimensional data
        temp_array[i] = SectorRef(m, length(m._sectors), i, string(s.indices[1][i]))
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
        # TODO Fix the [1] thing here to properly work with n-dimensional data
        temp_array[i] = CommodityRef(m, length(m._commodities), i, string(c.indices[1][i]))
    end
    return JuMP.Containers.DenseAxisArray(temp_array, c.indices...)
end

function add!(m::Model, cn::ScalarConsumer)
    m._jump_model = nothing
    push!(m._consumers, cn)
    return ConsumerRef(m, length(m._consumers), nothing, nothing)
end

function add!(m::Model, cn::IndexedConsumer)
    m._jump_model = nothing
    push!(m._consumers, cn)

    temp_array = Array{ConsumerRef}(undef, length.(cn.indices)...)

    for i in CartesianIndices(temp_array)
        # TODO Fix the [1] thing here to properly work with n-dimensional data
        temp_array[i] = ConsumerRef(m, length(m._consumers), i, string(cn.indices[1][i]))
    end
    return JuMP.Containers.DenseAxisArray(temp_array, cn.indices...)
end

function add!(m::Model, p::Production)
    m._jump_model = nothing
    push!(m._productions, p)
    return m
end

function add!(m::Model, c::DemandFunction)
    m._jump_model = nothing
    push!(m._demands, c)
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
        # TODO Fix the [1] thing here to properly work with n-dimensional data
        temp_array[i] = ParameterRef(m, length(m._parameters), i, string(p.indices[1][i]))
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

function set_fixed!(sector::SectorRef, new_value::Bool)    
    s = sector.model._sectors[sector.index]
    if s isa ScalarSector
        s.fixed = new_value
    else
        s.fixed[sector.subindex] = new_value
    end
    return nothing
end