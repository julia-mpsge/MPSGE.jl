abstract type MPSGERef end

struct ParameterRef <: MPSGERef
    model
    index::Int
    subindex::Any
    subindex_names::Any
end

struct SectorRef <: MPSGERef
    model
    index::Int
    subindex::Any
    subindex_names::Any
end

struct CommodityRef <: MPSGERef
    model
    index::Int
    subindex::Any
    subindex_names::Any
end

struct ConsumerRef <: MPSGERef
    model
    index::Int
    subindex::Any
    subindex_names::Any
end

struct AuxRef <: MPSGERef
    model
    index::Int
    subindex::Any
    subindex_names::Any
end

struct ImplicitvarRef <: MPSGERef
    model
    index::Int
    subindex::Any
    subindex_names::Any
end