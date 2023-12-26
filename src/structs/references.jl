abstract type MPSGERef end

struct ParameterRef <: MPSGERef
    model
    index::Int
    name::Symbol
    subindex::Any
    subindex_names::Any
end

struct SectorRef <: MPSGERef
    model
    name::Symbol
    subindex::Any
    subindex_names::Any
end

struct CommodityRef <: MPSGERef
    model
    name::Symbol
    subindex::Any
    subindex_names::Any
end

struct ConsumerRef <: MPSGERef
    model
    name::Symbol
    subindex::Any
    subindex_names::Any
end

struct AuxRef <: MPSGERef
    model
    name::Symbol
    subindex::Any
    subindex_names::Any
end

struct ImplicitvarRef <: MPSGERef
    model
    index::Int
    name::Symbol
    subindex::Any
    subindex_names::Any
end