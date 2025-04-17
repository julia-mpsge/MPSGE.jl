#####################
## Pruning Helpers ##
#####################

function prune!(T::Netput)
    if quantity(T) != 0
        return T
    else
        return nothing
    end
end

function prune!(T::Node)
    if quantity(T) == 0
        return nothing
    end
    T.children = [e for e∈prune!.(children(T)) if !isnothing(e)]
    return T
end


#############################
## Building Cost Functions ##
#############################


function cobb_douglass(N::MPSGE.Node; virtual = :full, cf = cost_function)
    sign = MPSGE.netput_sign(N)
    return prod(cf(child; virtual = virtual)^(quantity(child)/quantity(N)) for child in MPSGE.children(N); init=1)
end

function CES(N::MPSGE.Node; virtual = :full,  cf = cost_function)
    sign = MPSGE.netput_sign(N)
    return sum(quantity(child)/quantity(N) * cf(child; virtual = virtual)^(1+sign*MPSGE.elasticity(N)) for child in MPSGE.children(N); init=0) ^ (1/(1+sign*MPSGE.elasticity(N)))
end


function build_cost_function(tree::MPSGE.Netput; virtual = :full)
    return cost_function(tree)
end

function build_cost_function(N::MPSGE.Node; virtual = :full)

    # If the cost function exists, return it
    if !isnothing(N.cost_function_virtual)
        return MPSGE.cost_function(N, virtual = :virtual)
    end

    cost_function = MPSGE.cost_function(N; virtual = :partial, cf = build_cost_function)

    if isnothing(N.cost_function_virtual)
        jm = MPSGE.jump_model(MPSGE.model(N))
        N.cost_function_virtual = @variable(jm, start = value(start_value, cost_function)) 
        N.cost_function = cost_function
        @constraint(jm, N.cost_function_virtual - cost_function ⟂ N.cost_function_virtual)
    end

    return N.cost_function_virtual
end


##########################
## The Production macro ##
##########################

struct PreProduction
    model
    sector
    nests
    netputs
end


macro production(input_args...)
    error_fn = Containers.build_error_fn("production", input_args, __source__)
    args,kwargs = Containers.parse_macro_arguments(
        error_fn, 
        input_args; 
        num_positional_args = 4,
        #valid_kwargs = [:description]
        )

    model = esc(args[1])
    sector = esc(args[2])
    #sector_name, index_vars, indices = Containers.parse_ref_sets(error_fn, args[2])

    #sector_name_expr = Containers.build_name_expr(sector_name, index_vars, kwargs)
    #sector_base_name = string(sector_name)
    
    nestings = args[3]
    nests = :(Any[])
    for nest in nestings.args
        a = MPSGE.build_nest_and_parent(nest, __source__)
        push!(nests.args, :($a))
    end

    netputs = :(Any[])
    for netput in args[4].args
        if !(netput isa LineNumberNode)#!Meta.isexpr(netput, :LineNumberNode)
            push!(netputs.args, :($(esc(netput))))
        end
    end

    P = :(build_production($error_fn, $sector, MPSGE.create_nodes($model, $nests), $(netputs)))

    return :(add_production!($model, $P))
end


function assign_netputs_to_node(N::MPSGE.NetputParent, nodes::Dict{Symbol, MPSGE.Node})
    netput = N.netput
    parent = N.parent
    node = nodes[parent]
    
    MPSGE.set_parent!(netput, node; add_child = true)
end

function flatten_netputs(netputs::Vector{Any})
    out = []
    for netput in netputs
        if netput isa MPSGE.NetputParent
            push!(out, netput)
        elseif netput isa AbstractArray{<:MPSGE.NetputParent}
            append!(out, vec(netput.data))
        end
    end
    return out
end

function build_production(error_fn::Function, sector, node_structure, all_netputs)

    nodes, root_nodes = node_structure
    netputs = flatten_netputs(all_netputs)
    
    assign_netputs_to_node.(netputs, Ref(nodes))

    (input_tree, output_tree) = MPSGE.netput_sign(root_nodes[1]) == -1 ? (root_nodes[1], root_nodes[2]) : (root_nodes[2], root_nodes[1])
    input_tree = MPSGE.prune!(input_tree)
    output_tree = MPSGE.prune!(output_tree)

    if xor(isnothing(input_tree), isnothing(output_tree))
        error_fn("Input and output trees must be both present or both absent for sector $sector")
    end

    if !isnothing(input_tree) && !isnothing(output_tree)
        build_cost_function(input_tree)
        build_cost_function(output_tree)   
    end
    
    netputs = filter(y -> base_quantity(y.netput) != 0, netputs)

    netputs_by_commodity = Dict{MPSGE.Commodity, Vector{MPSGE.Netput}}()
    netputs_by_consumer = Dict{MPSGE.Consumer, Vector{MPSGE.Netput}}()

    # To Do: Break into functions
    for netput_parent in netputs
        netput = netput_parent.netput
        commodity = MPSGE.commodity(netput)
        if !haskey(netputs_by_commodity, commodity)
            netputs_by_commodity[commodity] = Vector{MPSGE.Netput}()
        end
        push!(netputs_by_commodity[commodity], netput)

        for tax in MPSGE.taxes(netput)
            consumer = MPSGE.tax_agent(tax)
            if !haskey(netputs_by_consumer, consumer)
                netputs_by_consumer[consumer] = Vector{MPSGE.Netput}()
            end
            push!(netputs_by_consumer[consumer], netput)
        end
    end



    return Production(sector, netputs_by_commodity, input_tree, output_tree, netputs_by_consumer)
end


