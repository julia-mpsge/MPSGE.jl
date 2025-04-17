###########################
## Create JuMP Variables ##
###########################
function add_variable!(m::MPSGEModel, S::MPSGEScalarVariable; start = 1)
    jm = jump_model(m)
    jm[name(S)] = @variable(jm,base_name = string(name(S)),start=start, lower_bound = 0)
end

function add_variable!(m::MPSGEModel, S::MPSGEIndexedVariable; start = 1)

    jm = jump_model(m)
    index = S.index

    dim = length.(index)
    
    x = JuMP.@variable(jm, [1:prod(dim)], lower_bound=0, start = start)

    for (i, ind) in enumerate(Iterators.product(index...))
        new_index = join(ind,",")
        JuMP.set_name(x[i], "$(name(S))[$new_index]")
    end

    output = JuMP.Containers.DenseAxisArray(reshape(x, Tuple(dim)), index...)
    jm[name(S)] = output
    return output

end

function add_variable!(m::MPSGEModel, S::Auxiliary)
    add_variable!(m, S; start = 0)
end

#########################
### Add MPSGE Objects ###
#########################
function add!(m::MPSGEModel,S::MPSGEScalarVariable)
    @assert !haskey(m.object_dict,name(S)) "Variable $(name(S)) already exists in model"
    m.object_dict[name(S)] = S
    #add_variable!(m,S)
    return S
end

function add!(m::MPSGEModel, S::MPSGEIndexedVariable)
    @assert !haskey(m.object_dict,name(S)) "Variable $(name(S)) already exists in model"
    m.object_dict[name(S)] = S
    #add_variable!(m,S)
    return S
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

# Passing a number
function add_parameter!(model::MPSGEModel, name::Symbol, value::Number; index=nothing, description = "", error_fn = error)
    S = index === nothing ? ScalarParameter(model,name, value; description = description) : IndexedParameter(model,name,index, value; description = description)
    add!(model,S)
    return S
end

# Passing an array
function add_parameter!(model::MPSGEModel, name::Symbol, value::AbstractArray; index=nothing, description = "", error_fn = error)
    if isnothing(index)
        error_string = "Passing arrays as a value without passing an index is not allowed. Please pass an index to the parameter"
        error_fn == error ? error("Parameter Error: ", error_string) : error_fn(error_string)
    end
    #@assert( !isnothing(index), "Parameter $name is being created with an array of values, but the index is nothing") 
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

function get_variable(S)
    return S
end


#######################
## Production/Demand ##
#######################

function add_production!(model::MPSGEModel, P::Production)
    if !isnothing(input(P)) && !isnothing(output(P))
        model.productions[sector(P)] = P
        for (commodity, _) in netputs(P)
            push!(model.commodities[commodity], sector(P))
        end
        return P
    end
    return nothing
end

function add_demand!(M::MPSGEModel,H::ScalarConsumer,demand_flow::Vector{abstractDemandFlow};elasticity::Union{Real,ScalarParameter} = 1)
    P = ScalarDemand(H,demand_flow; elasticity = elasticity)
    M.demands[H] = P
    return P
end


function add_aux_constraint!(model::AbstractMPSGEModel, A::ScalarAuxiliary, constraint::Any)#MPSGEExpr)
    P = ScalarAuxConstraint(A,constraint)
    model.auxiliaries[A] = P
    return P
end