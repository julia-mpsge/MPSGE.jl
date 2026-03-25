__MPSGEVARIABLE_KWARGS__ = [:description, :start, :lower_bound, :upper_bound]
__MPSGEVARIABLE_KWARGS_DEFAULT__ = Dict(
        :description => "",
        :start => 1.0,
        :lower_bound => 0,
        :upper_bound => Inf
        )

__MPSGEAUXILIARY_DEFAULTS__ = Dict(
    :description => "",
    :start => 0.0,
    :lower_bound => -Inf,
    :upper_bound => Inf
)


struct PreVariable
    name
    description
    start
    lower_bound
    upper_bound
    PreVariable(
        name; 
        description = __MPSGEVARIABLE_KWARGS_DEFAULT__[:description],
        start = __MPSGEVARIABLE_KWARGS_DEFAULT__[:start],
        lower_bound = __MPSGEVARIABLE_KWARGS_DEFAULT__[:lower_bound],
        upper_bound = __MPSGEVARIABLE_KWARGS_DEFAULT__[:upper_bound]
        ) = new(name, description, start, lower_bound, upper_bound)
end

function parse_variable_arguments(
    error_fn::Function, 
    input_args; 
    num_positional_args = 2, 
    valid_kwargs = __MPSGEVARIABLE_KWARGS__
    )

    # Extract the model, name expression, value, and keyword arguments
    args, kwargs = Containers.parse_macro_arguments(
        error_fn, 
        input_args
        )

    if length(args) != num_positional_args
        error_fn("Invalid number of positional arguments. Expected " *
            "$num_positional_args, got $(length(args)). Recall the syntax for" *
            " the variable macros is `@variable_type(model, name[index], kwargs...)`\n\n")
    end

    non_valid_kwargs = filter(x -> !(x in valid_kwargs), keys(kwargs))
    if length(non_valid_kwargs) > 0
        error_fn("The following keyword arguments are not valid: \n\n" *
            "$(join(string.("* ", non_valid_kwargs), "\n"))\n\n " *
            " Valid keyword arguments for a variable are: \n\n" *
            "$(join(string.("* ", valid_kwargs), "\n"))\n\n")
    end

    return args, kwargs

end


function build_MPSGEvariable(
    error_fn::Function,
    args...;
    kwargs...
)
    error_fn("Invalid syntax for a variable macro. Expected 2 arguments: model, name")
end

function build_MPSGEvariable(
    error_fn::Function,
    model::MPSGE.AbstractMPSGEModel,
    base_name::String,
    index_vars::Vector{Any},
    pre_parameter::PreVariable,
    description::String,
    scalar_type,
    indexed_type
    ;
    kwargs...
)
    P = scalar_type(
        model,
        pre_parameter.name;
        description = pre_parameter.description,
        start = pre_parameter.start,
        lower_bound = pre_parameter.lower_bound,
        upper_bound = pre_parameter.upper_bound
    )
    return P
end

function build_MPSGEvariable(
    error_fn::Function,
    model::MPSGE.AbstractMPSGEModel,
    base_name::String,
    index_vars::Vector{Any},
    variables::AbstractArray{<:PreVariable},
    description::String,
    scalar_type,
    indexed_type

)
    P = indexed_type(
        model,
        base_name,
        build_MPSGEvariable.(error_fn, Ref(model), Ref(base_name), Ref(index_vars), variables, description, scalar_type, indexed_type),
        index_vars;
        description = description
    )
    return P
end

function parse_MPSGEvariable(
    error_fn::Function,
    input_args,
    scalar_type,
    indexed_type;
    extra_code::Function = ((model, name) -> nothing),
    kwargs = __MPSGEVARIABLE_KWARGS__,
    default_values = __MPSGEVARIABLE_KWARGS_DEFAULT__
)
    args, kwargs = parse_variable_arguments(
        error_fn, 
        input_args; 
        num_positional_args = 2, 
        valid_kwargs =  kwargs
    )

    # Extract the model
    model_sym = args[1]
    model = esc(model_sym)

    # Extract indices from the name expression
    x = args[2]
    name, index_vars, indices = Containers.parse_ref_sets(
        error_fn,
        x;
        invalid_index_variables = [model_sym]
        )

    description = get(kwargs, :description, "")
    start = get(kwargs, :start, default_values[:start])
    lower_bound = get(kwargs, :lower_bound, default_values[:lower_bound])
    upper_bound = get(kwargs, :upper_bound, default_values[:upper_bound])

    #Build the name and base name
    name_expr = Containers.build_name_expr(name, index_vars, kwargs)
    base_name = string(name)
    
    build_code = JuMP.Containers.container_code(
        index_vars,
        indices,
        quote
            try
                PreVariable(
                    $name_expr;
                    description = $description,
                    start = $(esc(start)),
                    lower_bound = $(esc(lower_bound)),
                    upper_bound = $(esc(upper_bound))
                )
            catch e
                $error_fn("There is an issue with your inputs. Double check the " *
                    "syntax of your variable.")
            end
        end,
        :DenseAxisArray
    )

    code = quote
        $(esc(name))  = build_MPSGEvariable(
            $error_fn,
            $model,
            $base_name,
            $index_vars,
            $build_code,
            $description,
            $scalar_type,
            $indexed_type
            )
        add!($model, $(esc(name)))
        $extra_code($model, $(esc(name)))
    end

    return code
end

"""
    @sector(model, S, kwargs...)
    @sector(model, S[I], kwargs...)
    @sector(model, S[i=I], kwargs...)

Create a sector in the `model` with name `S`, index `I`, and index name `i` with
arguments `kwargs`.

## Arguments

- `model`: An instance of `MPSGEModel`.
- The sector `S` can be instantiated in a several ways. 
  1. `S` creates a scalar sector
  2. If `I` is a defined array, then `S[I]` creates an indexed sector with 
    indices given by `I`.
  3. If `I` is a defined array, then `S[i=I]`creates an indexed sector with 
    indices given by `I` and variable index named `i`. 

If you want to create an index sector it is highly recommended to use the syntax 
from (3) with better name for `i`, For example `S[goods=I]`, this will set the 
index name to `goods` which will be displayed when printing the model. For example
creating a variable using
```julia
@sector(M, S[goods=I], description = "Sector with indexed variables")
```
will allow the sector to be printed as
```
S[goods] -- Sector with indexed variables
```

Additionally, multi-indexed sectors can be created by using the syntax 
`S[regions = R, goods = G]`. 


## Optional Arguments

- `description`: Set a description on a variable. 
- `start`: Set the starting value of the variable Default 1.0
- `lower_bound`: Set the lower bound of the variable. Default 0.
- `upper_bound`: Set the upper bound of the variable. Default `Inf`.
## Examples

```julia
using MPSGE

R = Symbol.(:r, 1:5)
G = Symbol.(:g, 1:5)
M = MPSGEModel()

@sector(M, S[region=R, goods=G], description="Sector with indexed variables", start = 1.5)
```
"""
macro sector(input_args...)
    # Create specific error message that points to a particular line in the code
    error_fn = Containers.build_error_fn("sector", input_args, __source__)
    
    if length(input_args) >= 2 && Meta.isexpr(input_args[2], :block)
        error_fn("Invalid syntax. Did you mean to use `@sectors`?")
    end

    parse_MPSGEvariable(
        error_fn,
        input_args,
        ScalarSector,
        IndexedSector
    )
end

"""
    @sectors(model, args...)

Adds multiple [`@sector`](@ref) to a model. 

The model must be the first argument, and multiple sectors can be added in a 
`begin ... end` block, one sector per line. 

**Example**
```julia
julia> M = MPSGEModel()

julia> I = [:a,:b]

julia> @sectors(M, begin
            X[i=I]
            Y[i=I,j=I], (description = "This is an indexed variable")
            Z, (description = "Scalar variable")
        end)
```

!!! note
    Keywords must be contained in parentheses as in the example above. 
"""
macro sectors(model, block)
    return _plural_macro_code(model, block, Symbol("@sector"))
end

function add_commodity_to_model(M::MPSGEModel, C::ScalarCommodity)
    M.commodities[C] = []
end

function add_commodity_to_model(M::MPSGEModel, C::IndexedCommodity)
    add_commodity_to_model.(Ref(M), C)
end

"""
    @commodity(model, C, kwargs...)
    @commodity(model, C[I], kwargs...)
    @commodity(model, C[i=I], kwargs...)

Create a commodity in the `model` with name `C`, index `I`, and index name `i` with
arguments `kwargs`.

## Arguments

- `model`: An instance of `MPSGEModel`.
- The commodity `C` can be instantiated in a several ways. 
  1. `C` creates a scalar commodity
  2. If `I` is a defined array, then `C[I]` creates an indexed commodity with 
    indices given by `I`.
  3. If `I` is a defined array, then `C[i=I]`creates an indexed commodity with 
    indices given by `I` and variable index named `i`. 

If you want to create an index commodity it is highly recommended to use the syntax 
from (3) with better name for `i`, For example `C[goods=I]`, this will get the 
index name to `goods` which will be displayed when printing the model. For example
creating a variable using
```julia
@commodity(M, C[goods=I], description = "Commodity with indexed variables")
```
will allow the commodity to be printed as
```
C[goods] -- Commodity with indexed variables
```

Additionally, multi-indexed commoditys can be created by using the syntax 
`C[regions = R, goods = G]`. 


## Optional Arguments

- `description`: Set a description on a variable. 
- `start`: Set the starting value of the variable Default 1.0
- `lower_bound`: Set the lower bound of the variable. Default 0.
- `upper_bound`: Set the upper bound of the variable. Default `Inf`.

## Examples

```julia
using MPSGE

R = Symbol.(:r, 1:5)
G = Symbol.(:g, 1:5)
M = MPSGEModel()

@commodity(M, C[region=R, goods=G], description="Commodity with indexed variables")
```
"""
macro commodity(input_args...)
    # Create specific error message that points to a particular line in the code
    error_fn = Containers.build_error_fn("commodity", input_args, __source__)
    
    if length(input_args) >= 2 && Meta.isexpr(input_args[2], :block)
        error_fn("Invalid syntax. Did you mean to use `@commodities`?")
    end

    parse_MPSGEvariable(
        error_fn,
        input_args,
        ScalarCommodity,
        IndexedCommodity;
        extra_code = add_commodity_to_model
    )
end


"""
    @commodities(model, args...)

Adds multiple [`@commodity`](@ref) to a model. 

The model must be the first argument, and multiple commodities can be added in a 
`begin ... end` block, one commodity per line. 

**Example**
```julia
julia> M = MPSGEModel()

julia> I = [:a,:b]

julia> @commodities(M, begin
            X[i=I]
            Y[i=I,j=I], (description = "This is an indexed variable")
            Z, (description = "Scalar variable")
        end)
```

!!! note
    Keywords must be contained in parentheses as in the example above. 
"""
macro commodities(model, block)
    return _plural_macro_code(model, block, Symbol("@commodity"))
end


"""
    @consumer(model, H, kwargs...)
    @consumer(model, H[I], kwargs...)
    @consumer(model, H[i=I], kwargs...)

Create a consumer in the `model` with name `H`, index `I`, and index name `i` with
arguments `kwargs`.

## Arguments

- `model`: An instance of `MPSGEModel`.
- The consumer `H` can be instantiated in a several ways. 
  1. `H` creates a scalar consumer
  2. If `I` is a defined array, then `H[I]` creates an indexed consumer with 
    indices given by `I`.
  3. If `I` is a defined array, then `H[i=I]`creates an indexed consumer with 
    indices given by `I` and variable index named `i`. 

If you want to create an index consumer it is highly recommended to use the syntax 
from (3) with better name for `i`, For example `H[goods=I]`, this will get the 
index name to `goods` which will be displayed when printing the model. For example
creating a variable using
```julia
@consumer(M, H[goods=I], description = "Consumer with indexed variables")
```
will allow the consumer to be printed as
```
H[goods] -- Consumer with indexed variables
```

Additionally, multi-indexed consumers can be created by using the syntax 
`H[regions = R, goods = G]`. 


## Optional Arguments

- `description`: Set a description on a variable. 
- `start`: Set the starting value of the variable Default 1.0
- `lower_bound`: Set the lower bound of the variable. Default 0.
- `upper_bound`: Set the upper bound of the variable. Default `Inf`.

## Examples

```julia
using MPSGE

R = Symbol.(:r, 1:5)
G = Symbol.(:g, 1:5)
M = MPSGEModel()

@consumer(M, H[region=R, goods=G], description="Consumer with indexed variables")
```
"""
macro consumer(input_args...)
    # Create specific error message that points to a particular line in the code
    error_fn = Containers.build_error_fn("consumer", input_args, __source__)
    
    if length(input_args) >= 2 && Meta.isexpr(input_args[2], :block)
        error_fn("Invalid syntax. Did you mean to use `@consumers`?")
    end

    parse_MPSGEvariable(
        error_fn,
        input_args,
        ScalarConsumer,
        IndexedConsumer
    )
end

"""
    @consumers(model, args...)

Adds multiple [`@consumer`](@ref) to a model. 

The model must be the first argument, and multiple consumers can be added in a 
`begin ... end` block, one consumer per line. 

**Example**
```julia
julia> M = MPSGEModel()

julia> I = [:a,:b]

julia> @consumers(M, begin
            X[i=I]
            Y[i=I,j=I], (description = "This is an indexed variable")
            Z, (description = "Scalar variable")
        end)
```

!!! note
    Keywords must be contained in parentheses as in the example above. 
"""
macro consumers(model, block)
    return _plural_macro_code(model, block, Symbol("@consumer"))
end

"""
    @auxiliary(model, X, kwargs...)
    @auxiliary(model, X[I], kwargs...)
    @auxiliary(model, X[i=I], kwargs...)

Create a auxiliary in the `model` with name `X`, index `I`, and index name `i` with
arguments `kwargs`.

## Arguments

- `model`: An instance of `MPSGEModel`.
- The auxiliary `X` can be instantiated in a several ways. 
  1. `X` creates a scalar auxiliary
  2. If `I` is a defined array, then `X[I]` creates an indexed auxiliary with 
    indices given by `I`.
  3. If `I` is a defined array, then `X[i=I]`creates an indexed auxiliary with 
    indices given by `I` and variable index named `i`. 

If you want to create an index auxiliary it is highly recommended to use the syntax 
from (3) with better name for `i`, For example `X[goods=I]`, this will get the 
index name to `goods` which will be displayed when printing the model. For example
creating a variable using
```julia
@auxiliary(M, X[goods=I], description = "Auxiliary with indexed variables")
```
will allow the auxiliary to be printed as
```
X[goods] -- Auxiliary with indexed variables
```

Additionally, multi-indexed auxiliaries can be created by using the syntax 
`X[regions = R, goods = G]`. 


## Optional Arguments

- `description`: Set a description on a variable. 
- `start`: Set the starting value of the variable Default 0.0
- `lower_bound`: Set the lower bound of the variable. Default `-Inf`.
- `upper_bound`: Set the upper bound of the variable. Default `Inf`.

## Examples

```julia
using MPSGE

R = Symbol.(:r, 1:5)
G = Symbol.(:g, 1:5)
M = MPSGEModel()

@auxiliary(M, X[region=R, goods=G], description="Auxiliary with indexed variables")
```

!!! note
    By default auxiliary variables start at 0 with no lower or upper bounds. These
    can be set after variable creating using [`set_start_value`](@ref), 
    [`set_lower_bound`](@ref), and [`set_upper_bound`](@ref).
"""
macro auxiliary(input_args...)
    # Create specific error message that points to a particular line in the code
    error_fn = Containers.build_error_fn("auxiliary", input_args, __source__)
    
    if length(input_args) >= 2 && Meta.isexpr(input_args[2], :block)
        error_fn("Invalid syntax. Did you mean to use `@auxiliaries`?")
    end

    parse_MPSGEvariable(
        error_fn,
        input_args,
        ScalarAuxiliary,
        IndexedAuxiliary;
        default_values = __MPSGEAUXILIARY_DEFAULTS__,
    )
end


"""
    @auxiliaries(model, args...)

Adds multiple [`@auxiliary`](@ref) to a model. 

The model must be the first argument, and multiple auxiliaries can be added in a 
`begin ... end` block, one auxiliary per line. 

**Example**
```julia
julia> M = MPSGEModel()

julia> I = [:a,:b]

julia> @auxiliaries(M, begin
            X[i=I]
            Y[i=I,j=I], (description = "This is an indexed variable")
            Z, (description = "Scalar variable")
        end)
```

!!! note
    Keywords must be contained in parentheses as in the example above. 
"""
macro auxiliaries(model, block)
    return _plural_macro_code(model, block, Symbol("@auxiliary"))
end