
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

"""
    _strip_nest_elasticity(nest)

Strips the elasticity from a nest expression. Handles either,

- `s = σ`, root nodes
- `va => s = σ`, child nodes
"""
function _strip_nest_elasticity(nest)
    value = nest.args[2]
    if Meta.isexpr(value, :block)
        value = value.args[2]
    end
    return value
end

"""
    _strip_nest_name(nest)

Strips the name and parent from a nest expression. Handles either,

- `s = σ`, root nodes (child is `s`, parent is `missing`)
- `va => s = σ`, child nodes (child is `va`, parent is `s`)
"""
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
        error("Invalid syntax for nesting `$nest`. Required to have an `=` in "*
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


function build_nest_expr(input_nest_expr, source, disallowed_index_variables)
    nests = :(Any[])
    for nest in input_nest_expr.args
        a = MPSGE.build_nest_and_parent(nest, source, disallowed_index_variables)
        push!(nests.args, :($a))
    end
    return nests
end



"""
    build_nest_and_parent(nest_arg::Expr, source)

Return an expression that evaluates to 

    ((Nest, nest base name), (Parent, parent base name))
"""
function build_nest_and_parent(nest_arg::Any, source, disallowed_index_variables)
    error_fn = Containers.build_error_fn("nest", (nest_arg,), source)

    x, elasticity, parent = MPSGE._parse_nest(nest_arg)
    name, index_vars, indices, all_indices = parse_ref_sets(
        error_fn,
        x;
        invalid_index_variables = disallowed_index_variables
        )


    nest_code = MPSGE.nest_container(
        error_fn,
        name,
        index_vars,
        indices,
        elasticity
    )

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
            try
                MPSGE.PreNest(
                    $name_expr,
                    $(esc(elasticity))
                )
            catch e
                $error_fn("Error in nest macro: $(e)")
            end
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


function nest_to_node(model::MPSGEModel, nest::ScalarNest)
    return MPSGE.Node(model, nest)
end

function nest_to_node(model::MPSGEModel, nest::IndexedNest)
    return MPSGE.Node.(Ref(model), nest)
end

function build_node_dict!(nodes::Dict{Symbol, MPSGE.Node}, node::MPSGE.Node)
    node_name = MPSGE.name(node)
    if haskey(nodes, node_name)
        error("Duplicate node name: $(node.name)")
    end

    nodes[node_name] = node
end

function build_node_dict!(nodes::Dict{Symbol, MPSGE.Node}, node::AbstractArray{<:MPSGE.Node})
    build_node_dict!.(Ref(nodes), node)
end

function is_root_nest(gen_nest::MPSGE.GeneratedNest)
    return ismissing(gen_nest.parent)
end

function is_root_nest(gen_nest)
    return false
end

function create_parent_child_dict!(parent_child::Dict{Symbol, Vector{Symbol}}, nest::MPSGE.ScalarNest, parent)
    parent_name = Symbol(parent)
    if !haskey(parent_child, parent_name)
        parent_child[parent_name] = Vector{Symbol}()
    end
    push!(parent_child[parent_name], MPSGE.name(nest))
end

function create_parent_child_dict!(parent_child::Dict{Symbol, Vector{Symbol}}, nest::MPSGE.IndexedNest, parent)
    create_parent_child_dict!.(Ref(parent_child), nest, parent)
end

function create_parent_child_dict!(parent_child::Dict{Symbol, Vector{Symbol}}, node::MPSGE.GeneratedNest)
    create_parent_child_dict!(parent_child, node.nest, node.parent)
end





""" 
    create_nodes(generated_nodes::Vector{Any})

Given a vector of generated nodes, create the nodes and two required trees.

## Returns

    (nodes::Dict{Symbol, MPSGE.Node}, root_nodes::Vector{MPSGE.Node})
"""
function create_nodes(model::MPSGEModel, generated_nodes::Vector{Any})
    nodes = Dict{Symbol, MPSGE.Node}()
    parent_child = Dict{Symbol, Vector{Symbol}}()
    root_nodes = []

    for nest in generated_nodes
        node = nest_to_node(model, nest.nest)
        build_node_dict!(nodes, node)

        if is_root_nest(nest)
            push!(root_nodes, node)
        else
            create_parent_child_dict!(parent_child, nest)
        end
    end

    if length(root_nodes) != 2
        error("The nesting structure must have exactly 2 top-level nests, input "*
            "and output. We found $(length(root_nodes)) top-level nests. We found "*
            "the following\n\n$(join(string.("* ", root_nodes), ""))\n")
    end

    for (parent, children) in parent_child
        parent_node = nodes[parent]
        for child in children
            child_node = nodes[child]
            if parent_node == child_node
                error("A node cannot be its own parent. The node $(parent_node) is "*
                    "its own parent.")
            end
            MPSGE.set_parent!(child_node, parent_node; add_child = true)
        end
    end

    return (nodes, root_nodes)
end