"""
    parse_ref_sets(error_fn::Function, expr::Expr)

Given an expression of the form `Y[r, :a, i=I]` extract four components:

- `name`: the name of the reference set, in this case `Y`.
- `index_vars`: a vector of index variables, in this case `[:i]`. In this case, only
   `i` is an index variable, while `r` and `:a` are not as they do not have and `=`.
- `indices`: an expression representing the Cartesian product of the index sets,
   in this example it's only `I`. 
- `all_indices`: a vector of all indices, in this case `[:r, :(:a), :i]`.

This is used in macros.
"""
function parse_ref_sets(error_fn::Function, expr::Expr; invalid_index_variables::Vector{Any} = Any[])
    @assert Meta.isexpr(expr, :ref) error_fn(
        "Invalid syntax for reference set $expr. Must have a name, " *
        "for example, `Y[i=I]`."
    )

    name = expr.args[1]
    index_vars, index_sets, all_indices, condition = _parse_ref_sets(error_fn, expr)

    repeated_index_variables = Set(index_vars) ∩ Set(invalid_index_variables)

    !isempty(repeated_index_variables) && error_fn(
        "Repeated index variable $repeated_index_variables in reference set $name. " *
        "Check your sector index variables, these cannot be repeated elsewhere in the macro."
    )


    indices = :(Containers.vectorized_product($(index_sets...)))

    return (name, index_vars, indices, all_indices)

end



function parse_ref_sets(error_fn::Function, expr; invalid_index_variables::Vector{Any} = Any[])
    # If the input is just a symbol, we return an empty set of index variables
    # and an empty set of indices.
    return (expr, Any[], :(Containers.vectorized_product()), Any[])
end



"""
    _parse_ref_sets(error_fn::Function, expr::Expr)

Called by [`parse_ref_sets`](@ref) to extract the index variables, index sets,
and all indices from an expression of the form `Y[r, :a, i=I]`. 

Performs checks to interpret the expressions.

Adapted from JuMP. 
"""
function _parse_ref_sets(error_fn::Function, expr::Expr)
    c = copy(expr)
    index_vars, index_sets, all_indices, condition = Any[], Any[], Any[], :()
    # `:(t[i, j; k])` is a `:ref`, while `:(t[i; j])` is a `:typed_vcat`. In
    # both cases `:t` is the first argument.
    if Meta.isexpr(c, :typed_vcat) || Meta.isexpr(c, :ref)
        name = popfirst!(c.args)
        if !(name isa Symbol)
            error_fn(
                "Unsupported syntax: the expression `$name` cannot be used " *
                "as a name.",
            )
        end
    end
    if Meta.isexpr(c, :vcat) || Meta.isexpr(c, :typed_vcat)
        # An expression like `t[i; k]` or `[i; k]`. The filtering condition is
        # the second argument.
        if length(c.args) > 2
            error_fn(
                "Unsupported syntax $c: There can be at most one filtering " *
                "condition, which is separated from the indices by a single " *
                "`;`.",
            )
        elseif length(c.args) == 2
            condition = pop!(c.args)
        end
        # If length(c.args) == 1, expr ends in a trailing `;`, but there is no
        # condition, so we don't hhave to do anything.
    elseif Meta.isexpr(c, :ref) || Meta.isexpr(c, :vect)
        # An expression like `t[i, j; k]` or `[i, j; k]`. The filtering
        # condition is a `:parameters` expression in the first argument.
        if Meta.isexpr(c.args[1], :parameters)
            parameters = popfirst!(c.args)
            if length(parameters.args) != 1
                error_fn(
                    "Unsupported syntax $c: There can be at most one " *
                    "filtering condition, which is separated from the " *
                    "indices by a single `;`.",
                )
            end
            condition = parameters.args[1]
        end
    end

    #return (index_vars, index_sets, c.args)

    for arg in c.args
        parse_mpsge_ref_sets(error_fn, index_vars, index_sets, all_indices, arg)
    end
    return index_vars, index_sets, all_indices, condition
end


"""
    parse_mpsge_ref_sets(error_fn::Function, index_vars, index_sets, all_indices, arg::Expr)

Builds the three vectors `index_vars`, `index_sets`, and `all_indices` from
an expression `arg` that is part of a reference set. 

Different input types are handled differently. 
"""
function parse_mpsge_ref_sets(error_fn::Function, index_vars, index_sets, all_indices, arg::Expr)
    if !Meta.isexpr(arg, :kw, 2)
        error_fn("Invalid syntax for index variable $arg. Must be of the form `i=I`.")
    end

    index_var, index_set = arg.args[1], esc(arg.args[2])

    push!(index_vars, index_var)
    push!(index_sets, index_set)
    push!(all_indices, esc(index_var))
    return 

end

# When the input has a single index, like Y[i]
function parse_mpsge_ref_sets(error_fn::Function, index_vars, index_sets, all_indices, arg)
    push!(all_indices, esc(arg))
end

# When there is an explicit symbol in the index set, like Y[:ppd]
#function parse_mpsge_ref_sets(error_fn::Function, index_vars, index_sets, all_indices, arg::QuoteNode)
#    push!(all_indices, esc(arg))
#end



"""
    build_name_expr(name::Union{Symbol,Nothing}, index_vars::Vector, kwargs::Dict{Symbol,Any})

Builds an expression that represents the name of a reference set, including
the index variables. 

Adapted from JuMP, however the JuMP version returns a `String` where as this returns
a usuable object, like a Sector.
"""
function build_name_expr(
    name::Union{Symbol,Nothing},
    index_vars::Vector,
    kwargs::Dict{Symbol,Any},
)
    base_name = esc(name)

    if isempty(index_vars) || base_name == ""
        return base_name
    end
    expr = Expr(:ref, base_name)
    for index in index_vars
        push!(expr.args, :($index))
    end
    return expr
end


function build_string_expr(
    name::Union{Symbol,Nothing},
    index_vars::Vector,
    kwargs::Dict{Symbol,Any},
)

    base_name = get(kwargs, :base_name, string(something(name, "")))
    if !(base_name isa String)
        base_name = esc(name)
    end

    if isempty(index_vars) || base_name == ""
        return base_name
    end
    expr = Expr(:call, :string, base_name, "[")
    for index in index_vars
        push!(expr.args, :(string($index)))
        push!(expr.args, ", ")
    end
    expr.args[end] = "]"  # Replace the last ", " with "]"
    return expr
end