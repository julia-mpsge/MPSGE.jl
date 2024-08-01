function variable_description(var_type::String)

return """
    @$var_type(model, expr, kwargs...)

Create a $var_type in the `model` described by the `expr` with keyword 
arguments `kwargs`.

**$var_type names**

`expr` must be one of the forms:

- A single symbol like `@$var_type(model, X)`
- A container like expression `@$var_type(model, X[I])`

**Keyword Arguments**

- `index`: Explicity sets the index. For example, this `@$var_type(model, X, index = [I])` is equivalent to `@$var_type(model, X[I])`.
- `description`: Set a description on a variable. 
"""
end

function variables_description(var_type::String)

return """
    @$var_type(model, args...)

Adds multiple $var_type to a model at once. 

The model must be the first argument, and multiple variables can be added on multiple lines by wrapping them in a `begin ... end` block. 

**Example**
```jldoctest
julia> M = MPSGEModel();

julia> I = [:a,:b];

julia> @$var_type(M, begin
            X[I]
            Y[I,I], (description = "This is an indexed variable")
            Z, (description = "Scalar variable")
        end);
```

!!! note
    Keywords must be contained in parentheses as in the example above. 
"""
end


function netput_documentation(var_type::String)
    return """
    @$var_type(commodity, quantity, nest, kwargs...)

This macro is soley used within a [`@production`](@ref) block to define the $(var_type)s for a sector. The `commodity`, `quantity` and `nest` arguments are required, where `nest` is an object created in the `@production` macro. 

**Keyword Arguments**

    - `taxes` associate a tax to the commodity. The syntax `taxes = [Tax(RA, .1), Tax(GOVT, .3)]` defines two taxes, one associated the consumer `RA` and another with `GOVT`. In this example the values are fixed, but they can also be parameters.
    - `reference_price=1` Set the reference price of a commodity.
    """
end