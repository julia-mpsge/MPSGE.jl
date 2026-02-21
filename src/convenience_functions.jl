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
    set_start_value(X::MPSGEScalarVariable, val::Real)

Set the staring value of an MPSGE variable. This is an extension of the JuMP
function `set_start_value`.
"""
JuMP.set_start_value(X::MPSGEScalarVariable, val::Real) = JuMP.set_start_value(get_variable(X), val)
JuMP.start_value(H::MPSGEScalarVariable) = start_value(get_variable(H))

function JuMP.start_value(M::MPSGEModel)
    df = DataFrame(variables=Any[], start_values=Float64[])
        for i in values(M.object_dict)
        push!(df, [i value(i)])
        end
        df
end

start_values(M::MPSGEModel) = JuMP.start_value(M::MPSGEModel)

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

