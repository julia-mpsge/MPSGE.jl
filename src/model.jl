# These are weirdly named types exist so that we can forward
# type declare things here.

struct _ParameterRef{T}
    model::T
    index::Int
end

struct _SectorRef{T}
    model::T
    index::Int
end

struct _CommodityRef{T}
    model::T
    index::Int
end

struct _ConsumerRef{T}
    model::T
    index::Int
end

mutable struct Parameter
    name::Symbol
    value::Float64
end

struct Sector
    name::Symbol
    benchmark::Float64
    description::String

    function Sector(name::Symbol; description::AbstractString="", benchmark::Float64=1.)
        return new(name, benchmark, description)
    end
end

mutable struct Commodity
    name::Symbol
    benchmark::Float64
    description::String
    fixed::Bool

    function Commodity(name::Symbol; description::AbstractString="", benchmark::Float64=1., fixed=false)
        return new(name, benchmark, description, fixed)
    end
end

struct Consumer
    name::Symbol
    benchmark::Float64
    description::String

    function Consumer(name::Symbol; description::AbstractString="", benchmark::Float64=1.)
        return new(name, benchmark, description)
    end
end

struct Input
    commodity::Symbol
    quantity::Union{Float64,Expr}
end


struct Production
    sector::Symbol    
    elasticity::Union{Float64,Expr}
    output::Symbol
    output_quantity::Union{Float64,Expr}
    inputs::Vector{Input}
end



struct Endowment
    commodity::Symbol
    quantity::Union{Float64,Expr}
end


struct Demand
    consumer::Symbol
    commodity::Symbol
    endowments::Vector{Endowment}
end

mutable struct Model
    _parameters::Vector{Parameter}
    _sectors::Vector{Sector}
    _commodities::Vector{Commodity}
    _consumers::Vector{Consumer}

    _productions::Vector{Production}
    _demands::Vector{Demand}

    _jump_model::Union{Nothing,JuMP.Model}
    _jump_nlparameters::Dict{Symbol,JuMP.NonlinearParameter}
    _status

    function Model()
        return new(
            Parameter[],
            Sector[],
            Commodity[],
            Consumer[],
            Production[],
            Demand[],
            nothing,
            Dict{Symbol,JuMP.NonlinearParameter}(),
            nothing
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

# This is the second part of the forward type declaration
const ParameterRef = _ParameterRef{Model}
const SectorRef = _SectorRef{Model}
const CommodityRef = _CommodityRef{Model}
const ConsumerRef = _ConsumerRef{Model}

function get_name(sector::SectorRef)
    return sector.model._sectors[sector.index].name
end

function get_name(commodity::CommodityRef)
    return commodity.model._commodities[commodity.index].name
end

function get_name(consumer::ConsumerRef)
    return consumer.model._consumers[consumer.index].name
end

# Outer constructors

function Demand(consumer::ConsumerRef, commodity::CommodityRef, endowments::Vector{Endowment})
    return Demand(get_name(consumer), get_name(commodity), endowments)
end

function Production(sector::SectorRef, elasticity::Union{Number,Expr}, output::CommodityRef, output_quantity::Union{Number,Expr}, inputs::Vector{Input})
    return Production(get_name(sector), elasticity, get_name(output), output_quantity, inputs)
end

function Input(commodity::CommodityRef, quantity)
    return Input(get_name(commodity), quantity)
end

function Endowment(commodity::CommodityRef, quantity)
    return Endowment(get_name(commodity), quantity)
end

function Input(commodity::Symbol, quantity::Number)
    return Input(commodity, convert(Float64, quantity))
end

function Production(sector::Symbol, elasticity::Union{Number,Expr}, output::Symbol, output_quantity::Union{Number,Expr}, inputs::Vector{Input})

    if isa(elasticity,Number)
        elasticity = convert(Float64, elasticity)
    end

    if isa(output_quantity,Number)
        output_quantity = convert(Float64, output_quantity)
    end

    return Production(sector, elasticity, output, output_quantity, inputs)
end

function Endowment(commodity::Symbol, quantity::Number)
    return Endowment(commodity, convert(Float64, quantity))
end

function add!(m::Model, s::Sector)
    m._jump_model = nothing
    push!(m._sectors, s)
    return SectorRef(m, length(m._sectors))
end

function add!(m::Model, c::Commodity)
    m._jump_model = nothing
    push!(m._commodities, c)
    return CommodityRef(m, length(m._commodities))
end

function add!(m::Model, c::Consumer)
    m._jump_model = nothing
    push!(m._consumers, c)
    return ConsumerRef(m, length(m._consumers))
end

function add!(m::Model, p::Production)
    m._jump_model = nothing
    push!(m._productions, p)
    return m
end

function add!(m::Model, c::Demand)
    m._jump_model = nothing
    push!(m._demands, c)
    return m
end

function add!(m::Model, p::Parameter)
    m._jump_model = nothing
    push!(m._parameters, p)
    return ParameterRef(m, length(m._parameters))
end

function add_variable!(jm::JuMP.Model, name::Symbol, lower_bound::Union{Float64,Nothing}=nothing)
    if lower_bound===nothing
        jm[name] = JuMP.@variable(jm, base_name=string(name))
    else    
        jm[name] = JuMP.@variable(jm, base_name=string(name), lower_bound=lower_bound)
    end
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

function JuMP.set_value(p::ParameterRef, new_value::Float64)
    p.model._parameters[p.index].value = new_value
end

function set_fixed!(m::Model, commodity::Symbol, new_value::Bool)
    c = m._commodities[findfirst(i->i.name==commodity, m._commodities)]
    c.fixed = new_value
    return nothing
end