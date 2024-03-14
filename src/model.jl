

function add!(m::MPSGEModel,S::MPSGEScalarVariable)
    @assert !haskey(m.object_dict,name(S)) "Variable $(name(S)) already exists in model"
    m.object_dict[name(S)] = S
    #add_variable!(m,S)
end

function add!(m::MPSGEModel, S::MPSGEIndexedVariable)
    @assert !haskey(m.object_dict,name(S)) "Variable $(name(S)) already exists in model"
    m.object_dict[name(S)] = S
    #add_variable!(m,S)
end


function add_sector!(model::AbstractMPSGEModel, name::Symbol; index = nothing, description = "")
    S = index === nothing ? ScalarSector(model,name; description = description) : IndexedSector(model,name,index; description = description)
    add!(model,S)
    return S
end

function add_commodity!(model::AbstractMPSGEModel, name::Symbol; index = nothing, description = "")
    S = index === nothing ? ScalarCommodity(model,name; description = description) : IndexedCommodity(model,name,index; description = description)
    add!(model,S)
    return S
end

function add_consumer!(model::MPSGEModel, name::Symbol; index = nothing, description = "")
    S = index === nothing ? ScalarConsumer(model,name; description = description) : IndexedConsumer(model,name,index; description = description)
    add!(model,S)
    return S
end

function add_parameter!(model::MPSGEModel, name::Symbol, value::Number; index=nothing, description = "")
    S = index === nothing ? ScalarParameter(model,name, value; description = description) : IndexedParameter(model,name,index, value; description = description)
    add!(model,S)
    return S
end

function add_parameter!(model::MPSGEModel, name::Symbol, value::AbstractArray; index=nothing, description = "")
    @assert( !isnothing(index), "Parameter $name is being created with an array of values, but the index is nothing") 
    S = IndexedParameter(model,name,index, value; description = description)
    add!(model,S)
    return S
end

function add_auxiliary!(model::MPSGEModel, name::Symbol; index = nothing, description = "")
    S = index === nothing ? ScalarAuxiliary(model,name; description = description) : IndexedAuxiliary(model,name,index; description = description)
    add!(model,S)
    return S
end



function get_variable(S::MPSGEScalarVariable)
    jm = jump_model(S.model)
    if !isnothing(jm)
        var = jm[base_name(S)]    
        si = S.subindex
        if ismissing(si)
            return var
        else
            return var[si...]
        end
    end
    return S

end

function get_variable(S::MPSGEIndexedVariable)
    return get_variable.(S.subsectors)
end


#######################
## Production/Demand ##
#######################

function add_production!(model::AbstractMPSGEModel, S::ScalarSector, nodes::Vector{Node}, netputs::MPSGE_MP.ScalarNetput...)
    P = ScalarProduction(S,nodes, netputs...)
    model.productions[S] = P
    return P
end

function add_demand!(M::MPSGEModel,H::ScalarConsumer,demands::Vector{ScalarDem},endowments::Vector{ScalarEndowment};elasticity::Union{Real,ScalarParameter} = 1)
    P = ScalarDemand(H,demands,endowments; elasticity = elasticity)
    M.demands[H] = P
    return P
end


function add_aux_constraint!(model::AbstractMPSGEModel, A::ScalarAuxiliary, constraint::MPSGEExpr)
    P = ScalarAuxConstraint(A,constraint)
    model.auxiliaries[A] = P
    return P
end