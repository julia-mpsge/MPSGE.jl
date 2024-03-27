####################################
## Production Constructor Helpers ##
####################################

function create_node!(node_dict, child::ScalarNest, parent::ScalarNest)
    if !haskey(node_dict, child)
        node_dict[child] = []
    end
    for node ∈ node_dict[parent]
        N = Node(child)
        set_parent!(N, node; add_child=true)
        push!(node_dict[child], N)
    end
end

function create_node!(node_dict, child::IndexedNest, parent::ScalarNest)
    create_node!.(Ref(node_dict), child, Ref(parent))
end

function create_node!(node_dict, child::Nest, parent::IndexedNest)
    for p∈parent
        create_node!.(Ref(node_dict), child, Ref(p))
    end
end

function _add_netput!(netput_dict, node_dict, child::Netput, parent::ScalarNest)
    for node ∈ node_dict[parent]
        set_parent!(child, node; add_child = true) 

        #Check netput signs match up the tree
        c, p = child, node
        while !isnothing(p)
            if c.netput_sign != p.netput_sign
                p.netput_sign = c.netput_sign
                c,p = p, MPSGE_MP.parent(p)
            else
                p = nothing
            end
        end
    end
    if child ∉ netput_dict[commodity(child)]
        push!(netput_dict[commodity(child)], child)
    end
end

function _add_netput!(netput_dict, node_dict, child::Netput, parent::IndexedNest)
    _add_netput!.(Ref(netput_dict), Ref(node_dict), Ref(child), parent)
end

############################
## Production Constructor ##
############################

function Production(
    sector::ScalarSector, 
    all_nests::Vector{Any}, 
    top_nests::Vector{Symbol},
    nest_connections::Vector{Tuple{Symbol,Symbol}},
    netputs::Vector{Tuple{Netput, Symbol}}
    )

    # Error Checking
    # 1. |top_nests| == 2
    # 2. 


    # Create a dictionary with all the nests/nest names
    nest_dict = Dict()
    for nest∈all_nests
        nest_dict[name(nest)] = nest
        if isa(nest, IndexedNest)
            for n∈nest
                nest_dict[name(n)] = n #stupid
            end
        end
    end

    # Build the non-leaf portion of the tree
    node_dict = Dict()
    for nest∈top_nests
        child = nest_dict[nest]
        node_dict[child] = [Node(child)]
    end

    for (child_nest,parent_nest)∈nest_connections
        child = nest_dict[child_nest]
        parent = nest_dict[parent_nest]

        create_node!(node_dict, child, parent)
    end


    netput_dict = Dict()
    for (child,parent_nest)∈netputs

        # Prune, this will only give zero if the base quantity is 0 
        if base_quantity(child) == 0
            continue
        end

        #Assume scalar input, for now
        if !haskey(netput_dict, commodity(child))
            netput_dict[commodity(child)] = []
        end
        parent = nest_dict[parent_nest]
        _add_netput!(netput_dict, node_dict, child, parent)
    end

    # Ugly and not necessary for computations. But useful for printing. 
    input_ind =  node_dict[nest_dict[top_nests[1]]][1].netput_sign == -1 ? 1 : 2
    output_ind = 3 - input_ind

    input = node_dict[nest_dict[top_nests[input_ind]]][1]
    output = node_dict[nest_dict[top_nests[output_ind]]][1]

    #Prune nodes that have no children. Is this necessary? YES
    input = prune!(input)
    output = prune!(output)

    @assert !isnothing(input) && !isnothing(output) "Production block for $(sector) has a 0 quantity in either output or input, but not both."

    return Production(sector, netput_dict, Dict(), input, output)
end

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
#remove_child!(parent::Node, child::Node)


#remove_parent!(child::Node, parent::Node)