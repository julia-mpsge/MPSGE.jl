function constraint(P::ScalarParameter)
    return 0
end

function constraint(X::ScalarSector)
    return zero_profit(X)
end

function constraint(C::ScalarCommodity)
    return market_clearance(C)
end

function constraint(H::ScalarConsumer)
    return income_balance(H)
end

function constraint(A::ScalarAuxiliary)
    D = MPSGE.aux_constraints(M)
    return MPSGE.constraint(D[A])
end


"""
    generate_report(M::MPSGEModel)

Returns a dataframe with three columns:

    - `var`: The name of the variable
    - `value`: The value of the variable
    - `margin`: The value of the constraint for the variable

The product of the value and the marge should be zero, if not the model has a 
specification error.

This function is useful for debugging models that fail a calibrated benchmark. 
If the model fails the benchmark, look for non-zero margins in this report, as 
they will reveal the error.
"""
function generate_report(M::MPSGEModel)

    out = []

    for T in [v for v in MPSGE.all_variables(M) if !isa(v, ScalarParameter)]
        push!(out, (var = name(T), value = value(T), margin = value(constraint(T))))
    end

    return DataFrame(out)

end





"""
    variable_index(X::MPSGE.MPSGEScalarVariable, ind::Int)

This is necessary as scalar variables do not store their index. 
"""
function variable_index(X::MPSGE.MPSGEScalarVariable, ind::Int)
    return name(X) |>
        x -> string(x) |>
        x -> split(x, "[")[2] |>
        x -> strip(x, ']') |>
        x -> split(x, ",") |>
        x -> string(x[ind])
end

"""
    
"""
function report(X::MPSGE.MPSGEIndexedVariable)
    index_names = MPSGE.index_names(X)
    variables = reduce(vcat, MPSGE.subvariables(X))

    return DataFrame(OrderedDict(
        :var => name(X),
        [ind => variable_index.(variables, i) for (i, ind) in enumerate(index_names)]...,
        :value => value.(variables),
        :margin => value.(constraint.(variables))
    ))

end


function report(X::MPSGE.MPSGEScalarVariable)
    return DataFrame(var = name(X), value = value(X), margin = value(constraint(X)))
end



















