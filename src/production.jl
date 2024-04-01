####################################
## Production Constructor Helpers ##
####################################

function create_node!(node_dict, child::ScalarNest, parent::ScalarNest)
    if !haskey(node_dict, child)
        node_dict[child] = Node[]
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
    all_nests::Vector{Nest}, 
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
    node_dict = OrderedDict{Nest,Vector{Node}}()
    for nest∈top_nests
        child = nest_dict[nest]
        node_dict[child] = [Node(child)]
    end

    for (child_nest,parent_nest)∈nest_connections
        child = nest_dict[child_nest]
        parent = nest_dict[parent_nest]

        create_node!(node_dict, child, parent)
    end


    netput_dict = Dict{ScalarCommodity,Vector{Netput}}()
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

    # Initialize cost functions - Should check if things are nothing
    for nest∈reverse(collect(keys(node_dict)))
        for node∈node_dict[nest]
            build_cost_function!(node, sector)
        end
    end

    # Build compensated demands
    compensated_demands = Dict{Netput, Vector{MPSGEquantity}}()
    for (_, netput_vector)∈netput_dict
        for netput∈netput_vector
            compensated_demands[netput] = build_compensated_demand.(Ref(netput),netput.parents)
        end
    end

    #Store sectors by commodity
    M = model(sector) 
    for (C,_)∈netput_dict
        push!(M.commodities[C], sector)
    end

    return Production(sector, netput_dict, compensated_demands, input, output)
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

####################
## Cost Functions ##
####################

function cost_function(N::Netput)
    C = commodity(N)
    sign = N.netput_sign
    rp = reference_price(N)
    return C*(1-sign*sum(tax(t) for t∈taxes(N);init = 0))/rp
end

build_cost_function!(N::Netput, S::ScalarSector) = nothing

# ScalarSector is a required input so that we can pull the jump model and
# create an ifelse 
function build_cost_function!(N::Node, S::ScalarSector)
    
    sign = N.netput_sign
    if !(isa(elasticity(N), Real))

        jm = jump_model(model(S))

        #This must be an explicit expression, otherwise it's evaluated now. 
        N.cost_function = @expression(jm, ifelse(
                    elasticity(N) * sign == -1,
                    cobb_douglass(N), 
                    CES(N)
                ))
    elseif elasticity(N)*sign == -1 #Cobb-Douglas is only on demand side with σ=1
        N.cost_function = cobb_douglass(N)
    else
        N.cost_function = CES(N)
    end
end

function cobb_douglass(N::Node)#P::ScalarProduction, T::ScalarNest, sign)
    sign = N.netput_sign
    return prod(cost_function(child)^(quantity(child)/quantity(N)) for child in children(N); init=1)
end

function CES(N::Node)#P::ScalarProduction, T::ScalarNest, sign::Int)
    sign = N.netput_sign
    return sum(quantity(child)/quantity(N) * cost_function(child)^(1+sign*elasticity(N)) for child in children(N); init=0) ^ (1/(1+sign*elasticity(N)))
end

function build_compensated_demand(base_netput::Netput, parent_node::Node)
    child, parent = base_netput, parent_node
    sign = child.netput_sign
    compensated_demand = -sign * MPSGE_MP.base_quantity(child)
    while !isnothing(parent)
        if elasticity(parent)!=0
            compensated_demand *= (cost_function(parent)/cost_function(child)) ^ (-sign*elasticity(parent))
        end
        child,parent = parent, parent.parent
    end
    return compensated_demand
end