__PARAMETER_KWARGS__ = [:description]


struct PreParameter
    model::MPSGE.AbstractMPSGEModel
    name::String
    value::Any
end

function build_parameter(
    error_fn::Function,
    args...;
    kwargs...
)
    error_fn("Invalid syntax for `@parameter` macro. Expected 3 arguments: model, name, value")
end

function build_parameter(
    error_fn::Function,
    model::MPSGE.AbstractMPSGEModel,
    base_name::String,
    index_vars::Vector{Any},
    pre_parameter::PreParameter,
    description::String;
    kwargs...
)

   # if length(kwargs) > 0

    P = ScalarParameter(
        model,
        pre_parameter.name,
        pre_parameter.value,
        description = description
    )
    return P
end

function build_parameter(
    error_fn::Function,
    model::MPSGE.AbstractMPSGEModel,
    base_name::String,
    index_vars::Vector{Any},
    variables::AbstractArray{<:PreParameter},
    description::String
)
    P = IndexedParameter(
        model,
        base_name,
        build_parameter.(error_fn, Ref(model), Ref(base_name), Ref(index_vars), variables, description),
        index_vars,
        description = description
    )
    return P
end


function parse_parameter_arguments(
        error_fn::Function, 
        input_args; 
        num_positional_args = 3, 
        valid_kwargs = __PARAMETER_KWARGS__
        )

    # Extract the model, name expression, value, and keyword arguments
    args, kwargs = Containers.parse_macro_arguments(
        error_fn, 
        input_args
        )

    if length(args) != num_positional_args
        error_fn("Invalid number of positional arguments. Expected " *
            "$num_positional_args, got $(length(args)). Recall the syntax for" *
            " the `@parameter` macro is `@parameter(model, expr, value, kwargs...)`\n\n")
    end

    non_valid_kwargs = filter(x -> !(x in valid_kwargs), keys(kwargs))
    if length(non_valid_kwargs) > 0
        error_fn("The following keyword arguments are not valid: \n\n" *
            "$(join(string.("* ", non_valid_kwargs), "\n"))\n\n " *
            " Valid keyword arguments for a parameter are: \n\n" *
            "$(join(string.("* ", valid_kwargs), "\n"))\n\n")
    end

    return args, kwargs

end


"""
    @parameter(model, expr, value, kwargs...)

Add a parameter to the `model` described by `expr` with initial value `value` and 
keyword arguments `kwargs...`.

## Required Arguments

- `model` is the MPSGE model
- `expr` an expression that describes the name and index of the parameter. See
    the examples below
- `value` The initial value of the parameter. 

## Keyword Arguments

- `description` A string describing the parameter.

## Examples

### Non-Indexed Parameters

```julia
using MPSGE

M = MPSGEModel()

initial_value = 10

@parameter(M, X, 1)
@parameter(M, Y, initial_value, description="A parameter")
```

### Indexed Parameters

```julia
using MPSGE

M = MPSGEModel()

R = 1:5
S = 1:3

one_dimension = Dict(r => 2*r for r in R)
two_dimension = Dict((r,s) => r+s for r in R, s in S)

@parameter(M, X[r=R], 1, description = "example") # Index `R` and value 1 with a description
@parameter(M, Y[R, S], 1) # Indices `R` and `S` and value 1.
@parameter(M, Z[r=R], one_dimension[r]) # Index `R` and values `one_dimension[r]`.
@parameter(M, W[r=R, s=S], two_dimension[r, s]) # Indices `R` and `S` and values `two_dimension[r, s]`.
```
"""
macro parameter(input_args...)
    # Create specific error message that points to a particular line in the code
    error_fn = Containers.build_error_fn("parameter", input_args, __source__)
    
    # Re-examine this line
    if length(input_args) >= 2 && Meta.isexpr(input_args[2], :block)
        error_fn("Invalid syntax. Did you mean to use `@parameters`?")
    end

    args, kwargs = parse_parameter_arguments(
        error_fn, 
        input_args; 
        num_positional_args = 3, 
        valid_kwargs = __PARAMETER_KWARGS__
    )


    # Extract the model
    model_sym = args[1]
    model = esc(model_sym)

    x = args[2]
    value = args[3]

    # Extract indices from the name expression
    name, index_vars, indices = Containers.parse_ref_sets(
        error_fn,
        x;
        invalid_index_variables = [model_sym]
        )

    
    description = get(kwargs, :description, "")
    
    #Build the name and base name
    name_expr = Containers.build_name_expr(name, index_vars, kwargs)
    base_name = string(name)

    # This is needed because the value might be an expression. By having this
    # the expression gets stored and evaluated later.
    build_code = JuMP.Containers.container_code(
        index_vars,
        indices,
        quote
            try
                PreParameter(
                    $model,
                    $name_expr,
                    $(esc(value))
                )
            catch e
                $error_fn("There is an issue with your inputs. Double check the " *
                    "syntax of your parameter.")
            end
        end,
        :DenseAxisArray
    )

    # The actual code that builds the parameter and adds it to the model. 
    code = quote
        $(esc(name))  = build_parameter(
            $error_fn,
            $model,
            $base_name,
            $index_vars,
            $build_code,
            $description
            )
        add!($model, $(esc(name)))
    end

    return code
end

"""
    @parameters(model, args...)

Adds multiple parameters to model at once, in the same fashion as the
[`@parameter`](@ref) macro.

The model must be the first argument, and multiple parameters can be added on
multiple lines wrapped in a `begin ... end` block.

The macro returns a tuple containing the parameters that were defined.

## Example

```julia
using MPSGE
model = MPSGEModel();

@parameters(model, begin
           x, 1
           y[i = 1:2], i, (description = "y parameter")
       end)
```

!!! note
    Keyword arguments must be contained within parentheses (refer to the example
    above).
"""
macro parameters(model, block)
    return _plural_macro_code(model, block, Symbol("@parameter"))
end