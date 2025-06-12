###########################
## Create JuMP Variables ##
###########################
function add_variable!(m::MPSGEModel, S::MPSGEScalarVariable; start = 1, lower_bound = 0, upper_bound = Inf)
    jm = jump_model(m)
    jm[name(S)] = @variable(jm,base_name = string(name(S)),start=start, lower_bound = lower_bound, upper_bound = upper_bound)
end


#########################
### Add MPSGE Objects ###
#########################
function add!(m::MPSGEModel,S::MPSGEScalarVariable)
    @assert !haskey(m.object_dict,name(S)) "Variable $(name(S)) already exists in model"
    m.object_dict[name(S)] = S
    return S
end

function add!(m::MPSGEModel, S::MPSGEIndexedVariable)
    @assert !haskey(m.object_dict,name(S)) "Variable $(name(S)) already exists in model"
    m.object_dict[name(S)] = S
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

function add_production!(model::MPSGEModel, P::ScalarProduction)
    model.productions[name(sector(P))] = P
    return P
end

function add_production!(model::MPSGEModel, P::IndexedProduction)
    model.productions[name(sector(P))] = P
    return P
end

function add_production!(::MPSGEModel, ::Nothing)
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