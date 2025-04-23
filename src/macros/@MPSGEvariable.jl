
function parse_variable_arguments(
    error_fn::Function, 
    input_args; 
    num_positional_args = 2, 
    valid_kwargs = [:description]
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


struct PreVariable
    name
end

function build_MPSGEvariable(
    error_fn::Function,
    args...;
    kwargs...
)
    error_fn("Invalid syntax for `@parameter` macro. Expected 3 arguments: model, name, value")
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

   # if length(kwargs) > 0

    P = scalar_type(
        model,
        pre_parameter.name,
        description
    )

    add_variable!(model, P)
    #fix(P, pre_parameter.value)
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
        index_vars,
        description
    )
    return P
end

function parse_MPSGEvariable(
    error_fn::Function,
    input_args,
    scalar_type,
    indexed_type;
    extra_code::Function = ((model, name) -> nothing)
)
    args, kwargs = parse_variable_arguments(
        error_fn, 
        input_args; 
        num_positional_args = 2, 
        valid_kwargs = [:description]
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

    #Build the name and base name
    name_expr = Containers.build_name_expr(name, index_vars, kwargs)
    base_name = string(name)
    
    build_code = JuMP.Containers.container_code(
        index_vars,
        indices,
        quote
            try
                PreVariable(
                    $name_expr,
                )
            catch e
                $error_fn("There is an issue with your inputs. Double check the " *
                    "syntax of your parameter.")
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


macro sector(input_args...)
    # Create specific error message that points to a particular line in the code
    error_fn = Containers.build_error_fn("parameter", input_args, __source__)
    
    if length(input_args) >= 2 && Meta.isexpr(input_args[2], :block)
        error_fn("Invalid syntax. Did you mean to use `@parameters`?")
    end

    parse_MPSGEvariable(
        error_fn,
        input_args,
        ScalarSector,
        IndexedSector
    )
end

macro sectors(model, block)
    return _plural_macro_code(model, block, Symbol("@sector"))
end

function add_commodity_to_model(M::MPSGEModel, C::ScalarCommodity)
    M.commodities[C] = []
end

function add_commodity_to_model(M::MPSGEModel, C::IndexedCommodity)
    add_commodity_to_model.(Ref(M), C)
end

macro commodity(input_args...)
    # Create specific error message that points to a particular line in the code
    error_fn = Containers.build_error_fn("parameter", input_args, __source__)
    
    if length(input_args) >= 2 && Meta.isexpr(input_args[2], :block)
        error_fn("Invalid syntax. Did you mean to use `@parameters`?")
    end

    parse_MPSGEvariable(
        error_fn,
        input_args,
        ScalarCommodity,
        IndexedCommodity;
        extra_code = add_commodity_to_model
    )
end

macro commodities(model, block)
    return _plural_macro_code(model, block, Symbol("@commodity"))
end

macro consumer(input_args...)
    # Create specific error message that points to a particular line in the code
    error_fn = Containers.build_error_fn("parameter", input_args, __source__)
    
    if length(input_args) >= 2 && Meta.isexpr(input_args[2], :block)
        error_fn("Invalid syntax. Did you mean to use `@parameters`?")
    end

    parse_MPSGEvariable(
        error_fn,
        input_args,
        ScalarConsumer,
        IndexedConsumer
    )
end

macro consumers(model, block)
    return _plural_macro_code(model, block, Symbol("@consumer"))
end


macro auxiliary(input_args...)
    # Create specific error message that points to a particular line in the code
    error_fn = Containers.build_error_fn("parameter", input_args, __source__)
    
    if length(input_args) >= 2 && Meta.isexpr(input_args[2], :block)
        error_fn("Invalid syntax. Did you mean to use `@parameters`?")
    end

    parse_MPSGEvariable(
        error_fn,
        input_args,
        ScalarAuxiliary,
        IndexedAuxiliary
    )
end

macro auxiliaries(model, block)
    return _plural_macro_code(model, block, Symbol("@auxiliary"))
end