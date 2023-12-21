abstract type MPSGEVariable end

abstract type MPSGEScalar <: MPSGEVariable end
abstract type MPSGEIndexed <: MPSGEVariable end

"""
    Parameter(:symbol; indices, value::Float64=1., string)
    Struct that holds the name, indices if IndexedParameter, value, and optional description of a parameter within the model.
### Options
    Parameter::ScalarParameter, IndexedParameter
### Example
```julia-repl
julia> P = add!(Parameter(model, :P, value=1., description="Elasticity"))
julia> sectors = [:s1, :s2]
julia> P = add!(Parameter(model, :P, indices=(,sectors), value=1., description="Elasticity parameters for X Sector "))
```
"""
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

    function IndexedParameter(name::Symbol, indices; value::Union{Array{Float64},Array{Int}}, description::AbstractString="")
            return new(name, indices, DenseAxisArray(Float64.(value), indices...), description)

    end
end

function Parameter(name; indices=nothing, kwargs...)
    return indices===nothing ? ScalarParameter(name; kwargs...) : IndexedParameter(name, indices; kwargs...)
end

#abstract type Sector end;

mutable struct ScalarSector <: MPSGEScalar
    name::Symbol
    benchmark::Float64
    lower_bound::Float64
    upper_bound::Float64
    description::String
    fixed::Bool

    function ScalarSector(name::Symbol; description::AbstractString="", lower_bound::Float64=0.0, upper_bound=10e100, benchmark::Float64=1., fixed=false)
        return new(name, benchmark, lower_bound, upper_bound, description, fixed)
    end
end

mutable struct IndexedSector <: MPSGEIndexed
    name::Symbol
    indices::Any
    benchmark::DenseAxisArray
    lower_bound::DenseAxisArray
    upper_bound::DenseAxisArray
    description::String
    fixed::DenseAxisArray

    function IndexedSector(name::Symbol, indices; benchmark::Float64=1., lower_bound::Float64=0.0, upper_bound::Float64=10e100, description::AbstractString="",  fixed=false)
        return new(name, indices, DenseAxisArray(fill(benchmark, length.(indices)...), indices...), DenseAxisArray(fill(lower_bound, length.(indices)...), indices...), DenseAxisArray(fill(upper_bound, length.(indices)...), indices...), description, DenseAxisArray(fill(fixed, length.(indices)...), indices...))
    end
end

"""
    Sector(:symbol; indices, value::Float64=1., string)
    Struct that holds the name, (indices if IndexedSector), value, and optional description of a sector within the model.
### Options
    Sector::ScalarSector, IndexedSector
### Example
```julia-repl
julia> S = add!(Sector(model, :S, value=1., description="Sector S"))
julia> sectors = [:s1, :s2]
julia> P = add!(Sector(model, :S, indices=(,sectors), value=1., description="S[:s1] and S[:s2] Sectors"))
```
"""
function Sector(name; indices=nothing, kwargs...)
    return indices===nothing ? ScalarSector(name; kwargs...) : IndexedSector(name, indices; kwargs...)
end

abstract type Commodity end;

mutable struct ScalarCommodity <: MPSGEScalar
    name::Symbol
    benchmark::Float64
    lower_bound::Float64
    upper_bound::Float64
    description::String
    fixed::Bool

    function ScalarCommodity(name::Symbol; description::AbstractString="", lower_bound::Float64=0.001, upper_bound::Float64=10e100, benchmark::Float64=1., fixed=false)
        return new(name, benchmark, lower_bound, upper_bound, description, fixed)
    end
end

mutable struct IndexedCommodity <: MPSGEIndexed
    name::Symbol
    indices::Any
    benchmark::DenseAxisArray
    lower_bound::DenseAxisArray
    upper_bound::DenseAxisArray
    description::String
    fixed::DenseAxisArray

    function IndexedCommodity(name::Symbol, indices; benchmark::Float64=1., lower_bound::Float64=0.001, upper_bound::Float64=10e100, description::AbstractString="", fixed=false)
        return new(name, indices, DenseAxisArray(fill(benchmark, length.(indices)...), indices...), DenseAxisArray(fill(lower_bound, length.(indices)...), indices...), DenseAxisArray(fill(upper_bound, length.(indices)...), indices...), description, DenseAxisArray(fill(fixed, length.(indices)...), indices...))
    end
end

function Commodity(name; indices=nothing, kwargs...)
    return indices===nothing ? ScalarCommodity(name; kwargs...) : IndexedCommodity(name, indices; kwargs...)
end

abstract type Consumer end;

mutable struct ScalarConsumer <: MPSGEScalar
    name::Symbol
    benchmark::Float64
    lower_bound::Float64
    upper_bound::Float64
    description::String
    fixed::Bool
    
    function ScalarConsumer(name::Symbol; description::AbstractString="", lower_bound::Float64=0.0, upper_bound::Float64=10e100, benchmark::Float64=1., fixed=false)
        return new(name, benchmark, lower_bound, upper_bound, description, fixed)
    end
end

mutable struct IndexedConsumer <: MPSGEIndexed
    name::Symbol
    indices::Any
    benchmark::DenseAxisArray
    lower_bound::DenseAxisArray
    upper_bound::DenseAxisArray
    description::String
    fixed::DenseAxisArray

    function IndexedConsumer(name::Symbol, indices; benchmark::Float64=1., lower_bound::Float64=0.0, upper_bound::Float64=10e100, description::AbstractString="", fixed=false)
        return new(name, indices, DenseAxisArray(fill(benchmark, length.(indices)...), indices...), DenseAxisArray(fill(lower_bound, length.(indices)...), indices...), DenseAxisArray(fill(upper_bound, length.(indices)...), indices...), description, DenseAxisArray(fill(fixed, length.(indices)...), indices...))
    end
end

function Consumer(name; indices=nothing, kwargs...)
    return indices===nothing ? ScalarConsumer(name; kwargs...) : IndexedConsumer(name, indices; kwargs...)
end

abstract type Aux end;

mutable struct ScalarAux <: MPSGEScalar
    name::Symbol
    benchmark::Float64
    lower_bound::Float64
    upper_bound::Float64
    description::String
    fixed::Bool

    function ScalarAux(name::Symbol; description::AbstractString="", lower_bound::Float64=0.0, upper_bound::Float64=10e100, benchmark::Float64=1., fixed=false)
        return new(name, benchmark, lower_bound, upper_bound, description, fixed)
    end
end

mutable struct IndexedAux <: MPSGEIndexed
    name::Symbol
    indices::Any
    benchmark::DenseAxisArray
    lower_bound::DenseAxisArray
    upper_bound::DenseAxisArray
    description::String
    fixed::DenseAxisArray

    function IndexedAux(name::Symbol, indices; benchmark::Float64=1., lower_bound::Float64=0.0, upper_bound::Float64=10e100, description::AbstractString="", fixed=false)
        return new(name, indices, DenseAxisArray(fill(benchmark, length.(indices)...), indices...), DenseAxisArray(fill(lower_bound, length.(indices)...), indices...), DenseAxisArray(fill(upper_bound, length.(indices)...), indices...), description, DenseAxisArray(fill(fixed, length.(indices)...), indices...))
    end
end

function Aux(name; indices=nothing, kwargs...)
    return indices===nothing ? ScalarAux(name; kwargs...) : IndexedAux(name, indices; kwargs...)
end

struct Tax
    rate::Union{Float64,Expr}
    agent::ConsumerRef
end