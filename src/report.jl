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
    generate_report(variables::Union{MPSGEIndexedVariable, MPSGEScalarVariable}...)

Returns a dataframe with three columns:

    - `var`: The variable
    - `value`: The value of the variable
    - `margin`: The value of the constraint for the variable

The product of the value and the margin should be zero, if not the model has a 
specification error.

## Arguments

There are two methods for this function:

    1. `M::MPSGEModel`: This will report on all sectors, commodities, consumers, and auxiliaries in the model.  
    2. `variables::Union{MPSGEIndexedVariable, MPSGEScalarVariable}...`: This will report on the specified variables.

## Example

Let `M` be an MPSGEModel with sectors `X` and `EX`. The following code will report
on all variables in the model:

```julia
generate_report(M)
```

The following code will report only on the variables `X` and `EX`:

```julia
generate_report(X, EX)
```
"""
function generate_report(M::MPSGEModel)
    out = []

    vars_to_report = [
        production_sectors(M);
        commodities(M);
        consumers(M); 
        auxiliaries(M)
    ]

    for T in vars_to_report
        push!(out, (var = T, value = value(T), margin = value(constraint(T))))
    end

    return DataFrame(out)

end

function generate_report(variable::MPSGEIndexedVariable)
    vars_to_report = extract_scalars(variable) |> vec

    return DataFrame(
        OrderedDict(
            :var => vars_to_report,
            :value => value.(vars_to_report),
            :margin => value.(constraint.(vars_to_report))
        ))
end

function generate_report(variable::MPSGEScalarVariable)
    return DataFrame(var = variable, value = value(variable), margin = value(constraint(variable)))
end

function generate_report(variables::Union{MPSGEIndexedVariable, MPSGEScalarVariable}...)
    out = []

    for variable in variables
        push!(out, generate_report(variable))
    end

    return vcat(out...)
end











