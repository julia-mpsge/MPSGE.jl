
struct PreNest
    name::String
    elasticity::Any
end

struct NestParent
    name::Any
end


struct GeneratedNest
    nest::Union{Nest, AbstractArray{<:Nest}}
    parent::Union{Missing, String, AbstractArray{String}}
end


function _strip_nest_elasticity(nest)
    value = nest.args[2]
    if Meta.isexpr(value, :block)
        value = value.args[2]
    end
    return value
end

function _strip_nest_name(nest)
    parent = missing
    name = nest.args[1]
    if Meta.isexpr(name, :call)
        parent = name.args[3]
        name = name.args[2]
    end
    return parent, name
end

function _parse_nest(nest)
    if !Meta.isexpr(nest, :(=))
        error("Invalid syntax for nesting $nest. Required to have an = in "*
        "statement. `s = 0` or `va => s = 0`."
        )
    end
    value = _strip_nest_elasticity(nest)
    parent, name = _strip_nest_name(nest)
    
    return name, value, parent
end

function build_nest(
    error_fn::Function,
    base_name::String,
    index_vars::Vector{Any},
    pre_nest::PreNest,
)
    N = MPSGE.ScalarNest(
        pre_nest.name,
        base_name,
        pre_nest.elasticity,
    )

    return N

end


function build_nest(
    error_fn::Function,
    base_name::String,
    index_vars::Vector{Any},
    pre_nests::AbstractArray{<:PreNest},
)
    # Create the nest object
    N = MPSGE.IndexedNest(
        base_name,
        MPSGE.build_nest.(error_fn, Ref(base_name), Ref(index_vars), pre_nests),
        index_vars
    )
    return N
end


function build_nest_structure(
    error_fn::Function,
    parent::NestParent
)
    return parent.name
end

function build_nest_structure(
    error_fn::Function,
    parent::AbstractArray{<:NestParent}
)
    return MPSGE.build_nest_structure.(error_fn, parent)
end

function parse_nest_parent(
    error_fn::Function,
    expr::Symbol
)
    return (expr, Any[])
end

function parse_nest_parent(
    error_fn::Function,
    expr::Expr
)
    if !Meta.isexpr(expr, :ref)
        error_fn("Invalid syntax for nesting $expr. Must be of the form "*
            "`nest_name[indices]`."
        )
    end
    name = expr.args[1]
    index_vars = expr.args[2:end]

    return (name, index_vars)
end

"""
    build_nest_and_parent(nest_arg::Expr, source)

Return an expression that evaluates to 

    ((Nest, nest base name), (Parent, parent base name))
"""
function build_nest_and_parent(nest_arg::Any, source)
    error_fn = Containers.build_error_fn("nest", (nest_arg,), source)


    if !Meta.isexpr(nest_arg, :(=))
        error_fn("Invalid syntax for nesting $nest_arg. Required to have an = in "*
        "statement. `s = 0` or `va => s = 0`."
        )
    end

    x, elasticity, parent = MPSGE._parse_nest(nest_arg)
    name, index_vars, indices = Containers.parse_ref_sets(
        error,
        x;
        #invalid_index_variables = [model_sym]
        )


    nest_code = MPSGE.nest_container(
        error_fn,
        name,
        index_vars,
        indices,
        elasticity
    )

    #return nest_code

    parent_code = if !ismissing(parent) 
        parent_code = MPSGE.parent_container(
            error_fn,
            parent,
            index_vars,
            indices
        )
    else
        missing
    end

    return :(MPSGE.GeneratedNest(
                $nest_code, 
                $parent_code,  
    ))
end

function nest_container(
        error_fn::Function,
        name::Symbol,
        index_vars,
        indices,
        elasticity
    )

    name_expr = Containers.build_name_expr(name, index_vars, Dict{Symbol, Any}())
    base_name = string(name)

    build_nests = JuMP.Containers.container_code(
        index_vars,
        indices,
        quote
            MPSGE.PreNest(
                $name_expr,
                $(esc(elasticity))
            )
        end,
        :DenseAxisArray
    )
    return :(MPSGE.build_nest($error_fn, $base_name, $index_vars, $build_nests))
end

function parent_container(
    error_fn::Function,
    parent,
    index_vars,
    indices
)

    parent_name, parent_index_vars = MPSGE.parse_nest_parent(error_fn, parent)
    parent_expr = Containers.build_name_expr(parent_name, parent_index_vars, Dict{Symbol, Any}())
    
    build_parents = JuMP.Containers.container_code(
        index_vars,
        indices,
        quote
            MPSGE.NestParent(
                $parent_expr
            )
        end,
        :DenseAxisArray
    )
    
    return :(MPSGE.build_nest_structure($error_fn, $build_parents))
end
