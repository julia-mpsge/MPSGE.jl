function variable_description(var_type::String)

return """
    @$var_type(model, expr, kwargs...)

Create a $var_type in the `model` described by the `expr` with keyword 
arguments `kwargs`.

*$var_type names*

`expr` must be one of the forms:

- A single symbol like `@$var_type(model, X)`
- A container like expression `@$var_type(model, X[I])`

*Keyword Arguments*

- `index`: Explicity sets the index. For example, this `@$var_type(model, X, index = [I])` is equivalent to `@$var_type(model, X[I])`.
- `description`: Set a description on a variable. 
"""
end

function variables_description(var_type::String)

return """
    @$var_type(model, args...)

Adds multiple $var_type to a model at once. 

The model must be the first argument, and multiple variables can be added on multiple lines by wrapping them in a `begin ... end` block. 

*Example*
```jldoctest
julia> M = MPSGEModel();

julia> I = [:a,:b];

julia> @$var_type(M, begin
            X[I]
            Y[I,I], (description = "This is an indexed variable")
            Z, (description = "Scalar variable")
        end)
```

!!! note
    Keywords must be contained in parentheses as in the example above. 
"""
end