

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


function add_sector!(model::AbstractMPSGEModel, name::Symbol; index = nothing)
    S = index === nothing ? ScalarSector(model,name) : IndexedSector(model,name,index)
    add!(model,S)
    return S
end

function add_commodity!(model::AbstractMPSGEModel, name::Symbol; index = nothing)
    S = index === nothing ? ScalarCommodity(model,name) : IndexedCommodity(model,name,index)
    add!(model,S)
    return S
end

function add_consumer!(model::MPSGEModel, name::Symbol; index = nothing)
    S = index === nothing ? ScalarConsumer(model,name) : IndexedConsumer(model,name,index)
    add!(model,S)
    return S
end


function get_variable(S::MPSGEScalarVariable)
    jm = jump_model(S.model)
    var = jm[name(S)]    
    si = S.subindex
    if ismissing(si)
        return var
    else
        return var[si...]
    end

end

function get_variable(S::MPSGEIndexedVariable)
    return get_variable.(S.subsectors)
end


#######################
## Production/Demand ##
#######################

function add_production!(model::AbstractMPSGEModel, S::ScalarSector, input::ScalarNest, output::ScalarNest)
    P = ScalarProduction(S,input,output)
    model.productions[S] = P
    return P
end

function add_demand!(M::MPSGEModel,H::ScalarConsumer,demands::Vector{ScalarDem},endowments::Vector{ScalarEndowment})
    P = ScalarDemand(H,demands,endowments)
    M.demands[H] = P
    return P
end