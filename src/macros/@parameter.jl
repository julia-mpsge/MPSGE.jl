_PARAMETER_KWARGS = [:description]


struct PreParameter
    model::MPSGE.AbstractMPSGEModel
    name::String
    value::Any
end

function build_parameter(
    error_fn::Function,
    model::MPSGE.AbstractMPSGEModel,
    base_name::String,
    index_vars::Vector{Any},
    pre_parameter::PreParameter,
    description::String
)
    P = ScalarParameter(
        model,
        pre_parameter.name,
        pre_parameter.value,
        description = description
    )

    v = add_variable!(model, P)
    fix(P, pre_parameter.value)
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


"""
    @parameter(model, expr, args..., kwargs...)

"""
macro parameter(input_args...)


    
    # Create specific error message that points to a particular line in the code
    error_fn = Containers.build_error_fn("new_parameter", input_args, __source__)
    
    args, kwargs = Containers.parse_macro_arguments(
        error, 
        input_args; 
        num_positional_args = 3,
        #valid_kwargs = [:description]
        )

    # Re-examine this line
    if length(args) >= 3 && Meta.isexpr(args[3], :block)
        error_fn("Invalid syntax. Did you mean to use `@variables`?")
    end

    # Extract the model
    model_sym = args[1]
    model = esc(model_sym)

    x = args[2]
    value = args[3]


    name, index_vars, indices = Containers.parse_ref_sets(
        error_fn,
        x;
        invalid_index_variables = [model_sym]
        )


    #info_kwargs  =
    #    [(k, JuMP._esc_non_constant(v)) for (k, v) in kwargs if k in _PARAMETER_KWARGS] 
    
    description = get(kwargs, :description, "")
    
    name_expr = Containers.build_name_expr(name, index_vars, kwargs)

    base_name = string(name)

    build_code = JuMP.Containers.container_code(
        index_vars,
        indices,
        quote
            PreParameter(
                $model,
                $name_expr,
                $(esc(value))
            )
        end,
        :DenseAxisArray
    )

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

macro parameters(model, block)
    return _plural_macro_code(model, block, Symbol("@parameter"))
end