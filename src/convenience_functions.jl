JuMP.value(X::MPSGEScalarVariable) = JuMP.value(get_variable(X)) #Issue if the model isn't defined

function JuMP.fix(X::MPSGEScalarVariable, value::Real) 
    M = model(X)
    JuMP.fix(get_variable(X), value; force=true)
    set_start_value(X, value)
end

function JuMP.unfix(X::MPSGEScalarVariable) 
    M = model(X)
    JuMP.unfix(get_variable(X))
    JuMP.set_lower_bound(get_variable(X),0)
end
JuMP.is_fixed(X::MPSGEScalarVariable) = JuMP.is_fixed(get_variable(X))

"""
    set_start_value(X::MPSGEScalarVariable, val::Real; update_internal_start_values::Bool = true)

Set the staring value of an MPSGE variable. This is an extension of the JuMP
function `set_start_value`.

Also updates the interval start values for all cost functions. This is 
necessary to ensure that the correct cost function values are returned
when querying cost functions or solving with `cumulative_iteration_limit=0`.

## Optional Arguments

- `update_internal_start_values::Bool`: Whether to update the internal start 
    values of the cost functions. Default is `true`. Setting this to `false` can 
    improve performance if setting a large number of start values, but may lead 
    to incorrect results when querying cost functions or solving with with 
    `cumulative_iteration_limit=0`. 
"""
function JuMP.set_start_value(X::MPSGEScalarVariable, val::Real; update_internal_start_values::Bool = true)  
    JuMP.set_start_value(get_variable(X), val)

    if update_internal_start_values
        update_internal_start_values!(X)
    end
end

function update_internal_start_values!(M::MPSGEModel)
    for S in production_sectors(M)
        update_internal_start_values!(S)
    end
end

function update_internal_start_values!(X::MPSGEScalarVariable)
    return 
end

function update_internal_start_values!(X::ScalarSector)
    P = production(X)
    update_internal_start_values!(P.input)
    update_internal_start_values!(P.output)
end

function update_internal_start_values!(C::ScalarCommodity)
    for S in sectors(C)
        update_internal_start_values!(S)
    end
end

function update_internal_start_values!(X::ScalarConsumer)
    return 
end


function update_internal_start_values!(A::ScalarAuxiliary)
    @warn "Changes in start values for auxiliary variables are not propagated " *
    "to the internal start values of the cost functions. This may lead to " *
    "incorrect results querying cost functions or solving with " * 
    "`cumulative_iteration_limit=0`. To manually update internal start values, " *
    "use `MPSGE.update_internal_start_values!(model)`. \n\n" * 
    "It is recommend to set the starting value when declaring an Auxiliary variable " * 
    "with `start = value` in the `@auxiliary` macro" maxlog=1

    return
end

function update_internal_start_values!(N::Node)
    update_internal_start_values!.(N.children)
    set_start_value(N.cost_function_virtual, value(start_value, N.cost_function))
end

function update_internal_start_values!(N::Netput)
    return 
end


JuMP.is_solved_and_feasible(M::MPSGEModel) = JuMP.is_solved_and_feasible(jump_model(M))






JuMP.start_value(H::MPSGEScalarVariable) = start_value(get_variable(H))

function JuMP.set_silent(M::MPSGEModel) 
    M.silent = true
    JuMP.set_silent(jump_model(M))
end

function JuMP.unset_silent(M::MPSGEModel) 
    M.silent = false
    JuMP.unset_silent(jump_model(M))
end

"""
    set_lower_bound(X::MPSGEScalarVariable, val::Real)

Set the lower bound of an MPSGE variable. This is an extension of the JuMP
function `set_lower_bound`.
"""
JuMP.set_lower_bound(X::MPSGEScalarVariable, val::Real) = JuMP.set_lower_bound(get_variable(X), val)

"""
    set_upper_bound(X::MPSGEScalarVariable, val::Real)

Set the upper bound of an MPSGE variable. This is an extension of the JuMP
function `set_upper_bound`.
"""
JuMP.set_upper_bound(X::MPSGEScalarVariable, val::Real) = JuMP.set_upper_bound(get_variable(X), val)
JuMP.lower_bound(X::MPSGEScalarVariable) = JuMP.lower_bound(get_variable(X))
JuMP.upper_bound(X::MPSGEScalarVariable) = JuMP.upper_bound(get_variable(X))


function JuMP.all_variables(M::MPSGEModel)

    X = [s for (_,s) in M.object_dict] |>
        x -> MPSGE.extract_scalars.(x) |>  
        x -> Iterators.flatten(x) |>
        x -> collect(x)

    return X

end

