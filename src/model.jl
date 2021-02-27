struct Sector
    name::Symbol
    benchmark::Float64
    description::String

    function Sector(name::Symbol; description::AbstractString="", benchmark::Float64=1.)
        return new(name, benchmark, description)
    end
end

struct Commodity
    name::Symbol
    benchmark::Float64
    description::String

    function Commodity(name::Symbol; description::AbstractString="", benchmark::Float64=1.)
        return new(name, benchmark, description)
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
    quantity::Float64
end

struct Production
    sector::Symbol    
    elasticity::Float64
    output::Symbol
    output_quantity::Float64
    inputs::Vector{Input}
end

struct Endowment
    commodity::Symbol
    quantity::Float64
end

struct Demand
    consumer::Symbol
    commodity::Symbol
    endowments::Vector{Endowment}
end

mutable struct Model
    _sectors::Vector{Sector}
    _commodities::Vector{Commodity}
    _consumsers::Vector{Consumer}

    _productions::Vector{Production}
    _demands::Vector{Demand}

    _jump_model::Union{Nothing,JuMP.Model}
    _status

    function Model()
        return new(
            Sector[],
            Commodity[],
            Consumer[],
            Production[],
            Demand[],
            nothing,
            nothing
        )
    end
end

function Base.show(io::IO, m::Model)
    println(io, "MPSGE model with $(length(m._sectors)) sectors, $(length(m._commodities)) commodities and $(length(m._consumsers)) consumers.")

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

    if length(m._consumsers) > 0
        print(io, "  Consumers: ")
        print(io, join(["$(c.name) (bm=$(c.benchmark))" for c in m._consumsers], ", "))
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

function add!(m::Model, s::Sector)
    m._jump_model = nothing
    push!(m._sectors, s)
    return m
end

function add!(m::Model, c::Commodity)
    m._jump_model = nothing
    push!(m._commodities, c)
    return m
end

function add!(m::Model, c::Consumer)
    m._jump_model = nothing
    push!(m._consumsers, c)
    return m
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
    m._jump_model = build(m)

    m._status = Complementarity.solveMCP(m._jump_model; solver=solver, kwargs...)

    return m
end