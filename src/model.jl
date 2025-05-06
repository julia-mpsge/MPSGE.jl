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
    add_variable!(m,S)
    return S
end

function add!(m::MPSGEModel, S::MPSGEIndexedVariable)
    @assert !haskey(m.object_dict,name(S)) "Variable $(name(S)) already exists in model"
    m.object_dict[name(S)] = S
    add_variable!.(Ref(m),S)
    return S
end


function add!(m::MPSGEModel,S::ScalarParameter)
    @assert !haskey(m.object_dict,name(S)) "Variable $(name(S)) already exists in model"
    m.object_dict[name(S)] = S
    add_variable!(m,S)
    fix(S, value(S))
    return S
end

function add!(m::MPSGEModel, S::IndexedParameter)
    @assert !haskey(m.object_dict,name(S)) "Variable $(name(S)) already exists in model"
    m.object_dict[name(S)] = S
    add_variable!.(Ref(m),S)
    fix.(S, value.(S))
    return S
end


function get_variable(S::MPSGEScalarVariable)

    jm = jump_model(S.model)
    return jm[name(S)]
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