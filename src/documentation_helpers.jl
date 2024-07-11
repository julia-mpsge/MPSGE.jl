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

- `index`: Explicity sets the index. For example, this `@$var_type(model, X, index = [I])` 
is equivalent to `@$var_type(model, X[I])`.
- `description`: Set a description on a variable. 
"""
end