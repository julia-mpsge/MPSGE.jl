# MPSGE Variables

Variables are created in MPSGE using the eponymous macros. Each macro has two versions: a singular version (e.g. [`@sector`](@ref)) for creating a single variable, and a plural version (e.g. [`@sectors`](@ref)) for creating multiple variables at once. 

Variables can either be scalars (no index) or indexed (with one or more indices). This is handled automatically by the macros based on the input provided. For example, let's create a scalar sector and indexed sector simultaneously using the [`@sectors`](@ref) macro:

```julia
@sectors(model, begin
    Scalar
    Indexed[i=I]
end)
```

In this small example, we create two sectors: `Scalar`, which is a scalar variable, and `Indexed`, which is indexed over the set `I`. The macro automatically detects that `Indexed` has an index and creates it accordingly. We will explore the difference between scalar and indexed variables in more detail later.

With this basic understanding, let's dive into the different types of variables available in MPSGE and their keyword arguments.


## Variable Types

There are five types of variables in MPSGE:

- Parameters - [`@parameter`](@ref) / [`@parameters`](@ref)
- Sectors - [`@sector`](@ref) / [`@sectors`](@ref)
- Commodities - [`@commodity`](@ref) / [`@commodities`](@ref)
- Consumers - [`@consumer`](@ref) / [`@consumers`](@ref)
- Auxiliary Variables - [`@auxiliary`](@ref) / [`@auxiliaries`](@ref)

With the exception of parameters, these variables are constructed identically using their respective macros. Each variable type has its own set of keyword arguments that can be used to customize its behavior. 

Keyword arguments are optional and can be provided in any order. They are specified as `keyword = value` pairs after the required arguments. The keywords available for non-parameter variables are:

- `description::String = ""`: A description of the variable.
- `start::Real = 1.0`: The starting value for the variable in the solver. Auxiliary variables default to a starting value of `0.0`.
- `lower_bound::Real = 0`: The lower bound for the variable.
- `upper_bound::Real = Inf`: The upper bound for the variable. 




Parameters represent fixed values in the model, such as technology coefficients or policy parameters. Unlike other variables, you must provide a value when constructing a parameter. Model parameters are saved into the model as variables with names so that certain values can be updated without re-defining the whole model. Parameters are commonly used to run counterfactual simulations, where updating their value will alter the solution, but can be used in other ways.

```julia
@parameter(model, parameter, value)
```

Here, `value` is the fixed value assigned to the parameter. The only keyword argument available for parameters is `description::String = ""`, which allows you to provide a description of the parameter.


## Scalar Variables

Scalar variables are the primary objects that go into models, in other words when building a model all the variables will be scalars. 

A scalar variable stores three pieces of information:

- The model it belongs to
- The variable name (will have an index if it is part of an indexed variable)
- A description of the variable
- Parameters also store their fixed value

On construction, a scalar variable creates a JuMP variable in the underlying JuMP model with the same name. Most MPSGE operations on variables are wrappers around JuMP operations. For example, adding two MPSGE scalar variables together results in a JuMP expression with JuMP variables. This is largely transparent to the user, because the JuMP variable has the same name as the MPSGE variable. If there is an operation that is not supported by MPSGE, you can always access the underlying JuMP variable using the `get_variable` function.


## Indexed Variables

Indexed variables are collections of scalar variables that are indexed over one or more sets. Each element in the indexed variable is a scalar variable, and can be accessed using its indices. For example, if we construct an indexed sector variable:

```julia
@sectors(model, Y[i=I, j=J])
```

This creates a collection of sector variables `Y[i,j]` for each combination of indices `i` in set `I` and `j` in set `J`. Each `Y[i,j]` is a scalar variable that can be used in the same way as any other scalar variable.

The advantage of an MPSGE indexed variable over an array of scalar variables is that indexed variables are designed to print nicely in model descriptions. When printing an indexed variable, MPSGE will show the variable name along with its indices, making it easier to understand the structure of the model. For example, printing the indexed sector variable `Y` will display `Y[i,j]`, giving the user a clear indication of the variable's indexing. We display the index `i`, rather than the array `I` because `I` doesn't need to be a symbolic set; it could be any iterable collection. For example, how would the following display:

```julia
@sectors(model, begin
    Z[i = 1:10]
    W[i = filter(x -> x % 2 == 0, 1:10)]
end)
```

Indexed variables store the following pieces of information:

- The model it belongs to
- The variable name (with no indices)
- An array of scalar variables
- The indices used to create the variable
- A description of the variable

When an indexed variable is first created, it constructs all the scalar variables. Each scalar variable has the name `variable_name[index1,index2,...]`, where `index1`, `index2`, etc. are the specific indices for that scalar variable. For example, the scalar variable `Y[1,:a]` would be created with the name `Symbol("Y[1,a]")`, or the symbolic representation of the variable name.


## Variable Functions

Most JuMP functions have been extended to work with MPSGE scalar variables. Several examples:

- `value`
- `fix`
- `unfix`
- `is_fixed`
- `set_start_value`
- `start_value`
- `lower_bound`
- `upper_bound`
- `set_lower_bound`
- `set_upper_bound`
- `all_variables`

This list may not be exhaustive, so if you find a JuMP function that does not work with MPSGE variables, please open an issue on the GitHub repository. Additionally, these functions are missing documentation, we plan to work on this in the future. We also welcome contributions from the community!