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
    sector
    nests
    netputs
end




"""
    @production(model, sector, nestings, netputs)

Define a production for the `sector` in the `model` with given `nestings` and `netputs`. 

**sector**

This is any `ScalarSector` in the model. 

**nestings**

This is where the nesting structure is defined and the associated elasticities. At minimum you must declare at least two nests and elasticities, one for the elasticity of substitution (`input`) and one for the elasticity of transformation (`output`), by convention these are denoted `s` and `t` respectively, although any identifier may be used. 

As a minimal example, `[s=1, t=0]` will set the `s` nest to have an elasticity of 1 and the `t` nest 0. Suppose you want a nest below `s` called `va` with an elasticity of 2, this is created with `[s=1, t=0, va=>s=2]`. The `va` points at its parent nest `s` and the elasticity follows. Nestings can be aribrarily deep, for example 
```
[s=1, t=0, va=>s=2, dm=>s=1, d=>dm=2]
```
will have two nests below `s` and one below `dm`. 

**netputs**

A netput is either an [`@input`](@ref) or an [`@output`](@ref). The netputs get wrapped in a `begin ... end` block and each netput must be on its own line.

**Examples**

In the below example we define the production blocks for two sectors `X` and `Y`. This is a non-function example solely created to show syntax. The `X` sector only has the two require elasticities where as `Y` has a more interesting nesting structure. A tax is included in the `Y` production block. 

```julia
julia> M = MPSGEModel();

julia> @sectors(M, begin
            X
            Y
        end);

julia> @commodities(M, begin
            PX
            PY
            PL
            PK
        end);

julia> @consumer(M, RA);

julia> @production(M, X, [s=1,t=0], begin
            @output(PX, 10, t)
            @input(PL, 5, s)
            @input(PK, 5, s)
        end);

julia> @production(M, Y, [s=2, t=1, va=>s=1], begin
            @output(PY, 15, t)
            @input(PX, 3, s)
            @input(PL, 4, va, taxes = [Tax(RA, .5)])
            @input(PK, 6, va)
        end);
```

For examples using indexed sectors and commodities we recommend looking at the WiNDC national model. This will be linked when the appropriate write-up is ready.

"""
macro production(input_args...)
    error_fn = Containers.build_error_fn("production", input_args, __source__)
    args,kwargs = Containers.parse_macro_arguments(
        error_fn, 
        input_args; 
        num_positional_args = 4,
        #valid_kwargs = [:description]
        )

    model = esc(args[1])

    sector, index_vars, indices, all_indices = parse_ref_sets(error_fn, args[2])
    sector_name_expr = build_name_expr(sector, all_indices, kwargs)
    
    nests = build_nest_expr(args[3], __source__)

    # Extract netputs
    netputs = :(Any[])
    for netput in args[4].args
        if !Meta.isexpr(netput, :LineNumberNode)
            push!(netputs.args, :($(esc(netput))))
        end
    end

    build_production_sectors = JuMP.Containers.container_code(
        index_vars,
        indices,
        quote
            try
                PreProduction(
                    $sector_name_expr,
                    $nests,
                    $netputs
                )
            catch e
                $error_fn("Error in nest macro: $(e)")
            end
        end,
        :DenseAxisArray
    )

   # return sector_name_expr

    production_code = quote
        P = build_production(
            $error_fn,
            $model,
            $index_vars,
            $(esc(sector)),
            $build_production_sectors
        )
        add_production!($model, P)
    end

    return production_code
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


function build_production(
        error_fn::Function,
        model,
        index_vars::Vector{Any},
        base_sector,
        pre_preduction::PreProduction
        )

    sector = pre_preduction.sector
    nests = pre_preduction.nests
    netputs = pre_preduction.netputs

    return ScalarProduction(
        error_fn, 
        sector, 
        MPSGE.create_nodes(model, nests), 
        netputs
    )

    return sector

end

# Currently returns a dense axis array of scalar productions
function build_production(
        error_fn::Function,
        model,
        index_vars::Vector{Any},
        base_sector,
        pre_production::AbstractArray{<:PreProduction}
        )

    P =  build_production.(error_fn, Ref(model), Ref(index_vars), Ref(base_sector), pre_production)
    #return P
    return IndexedProduction(base_sector, P, index_vars)

    #return build_production.(error_fn, Ref(model), Ref(index_vars), Ref(base_sector), pre_production)
end


function ScalarProduction(
        error_fn::Function, 
        sector, 
        node_structure, 
        all_netputs
        )

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
            if netput ∉ netputs_by_consumer[consumer]
                push!(netputs_by_consumer[consumer], netput)
            end
            #push!(netputs_by_consumer[consumer], netput)
        end
    end



    return ScalarProduction(sector, netputs_by_commodity, input_tree, output_tree, netputs_by_consumer)
end





