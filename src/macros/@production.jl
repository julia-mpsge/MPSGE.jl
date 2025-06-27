#####################
## Pruning Helpers ##
#####################

function prune!(T::Netput)
    if quantity(T) != 0 && base_quantity(T) != 0
        return T
    else
        return nothing
    end
end


function prune!(T::AbstractArray{<:Any})
    return prune!.(T)
end

function prune!(T::abstractDemandFlow)
    if quantity(T) != 0 && base_quantity(T) != 0
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


function cobb_douglass(N::Node; virtual = :full, cf = cost_function)
    sign = netput_sign(N)
    return prod(cf(child; virtual = virtual)^(quantity(child)/quantity(N)) for child in children(N); init=1)
end

function CES(N::Node; virtual = :full,  cf = cost_function)
    sign = netput_sign(N)
    return sum(quantity(child)/quantity(N) * cf(child; virtual = virtual)^(1+sign*elasticity(N)) for child in children(N); init=0) ^ (1/(1+sign*elasticity(N)))
end


function build_cost_function(tree::Netput; virtual = :full)
    return cost_function(tree)
end

function build_cost_function(N::Node; virtual = :full)

    # If the cost function exists, return it
    if !isnothing(N.cost_function_virtual)
        return MPSGE.cost_function(N, virtual = :virtual)
    end

    cost_function = MPSGE.cost_function(N; virtual = :partial, cf = MPSGE.build_cost_function)

    if isnothing(N.cost_function_virtual)
        jm = jump_model(model(N))
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

## sector

The `sector` can take the following forms:

- `X`, if `X` is a scalar sector.
- `X[i=I,j=J,...]` if the sector is indexed. Indexing
- `X[i=I, :j]` if `:j` is an element of the second index of `X`.
- `X[i=I, j]` if `j` is defined outside the production block, for example in a `for` loop.

For an indexed sector it is __required__ that an index is provided when iterating over an array. For example, 

```julia
julia> I = [:a,:b]

julia> @sector(M, X[i=I])

julia> @production(M, X[I], ...) # This is not allowed and will error.

julia> @production(M, X[i=I], ...) # This is required behavior.

julia>  for i in I
            @production(M, X[i], ...) # This is allowed.
        end
```


## nestings

This is where the nesting structure is defined and the associated elasticities. At minimum you must declare at least two nests and elasticities, one for the elasticity of substitution (`input`) and one for the elasticity of transformation (`output`), by convention these are denoted `s` and `t` respectively, although any identifier may be used. As a minimal example, `[s=1, t=0]` will set the `s` nest to have an elasticity of 1 and the `t` nest 0.

Additional nests must have a parent nest, which is defined by the `=>` operator. For example, if you want a nest below `s` called `va` with an elasticity of 2, this is created with `[s=1, t=0, va=>s=2]`. The `va` points at its parent nest `s` and the elasticity follows. Nestings can be arbitrarily deep, for example
```
[s=1, t=0, va=>s=2, dm=>s=1, d=>dm=2]
```
will have two nests, `va` and `dm`, below `s` and one below `dm`, namely `d`.

Non-root nests can also be indexed. For example, if `I=[:a,:b]`, we can created an indexed nest with `[s=1, t=0, va[i=I]=>s=2]`. This will create a nest `va` for each element of `I` with an elasticity of 2. 

Finally, elasticities can be either numbers, parameters, or a defined expression. For example, all of the following define nestings if the sectors and parameters are defined:

```julia
julia> V = Dict(:a => 1, :b => 2)

julia> I = [:a,:b]

julia> J = [:c, :d]

julia> @production(M, X, [s=1,t=0, va[i=I]=> s = V[i], ...)

julia> @production(M, X[i=I], [s = V[i], t=0, va=>s=V[i]], ...)

julia> @production(M, X[i=I], [s = 0, t=0, va[ii=I, j=J] => s = V[ii]],...)
```

## netputs

A netput is either an [`@input`](@ref) or an [`@output`](@ref). The netputs get wrapped in a `begin ... end` block and each netput must be on its own line. For examples creating netputs, see the netput documentation and the examples below.

Netputs can use indices initialized in the `sector`, but can not use them as a new index. For example, if we have `X[i=I]` in the production block, we can use
`@input(PX[i],...)` but not `@input(PX[i=I],...)`. The latter will error.

## Examples

We demonstrate three ways to define a production block. 

```julia
julia> M = MPSGEModel();

julia> I = [:a,:b]

julia> @parameters(M, begin
            elas[i=I,j=J], 4
            T[i=I], .1
        end)

julia> @sectors(M, begin
            X
            Y[i=I, j=J]
            Z[i=I]
        end);

julia> @commodities(M, begin
            PX
            PY
            PL[i=I]
            PK
        end);

julia> @consumer(M, RA);

julia> @production(M, X, [s=1,t=0], begin
            @output(PX, 10, t)
            @input(PL, 5, s)
            @input(PK, 5, s)
        end);

julia> @production(M, Y[i=I,j=J], [s=2, t=1, va[ii=I]=>s=elas[i,ii]], begin
            @output(PY, 15, t)
            @input(PX, 3, s)
            @input(PL[ii=I], 4, va[ii], taxes = [Tax(RA, .5)])
            @input(PK, 6, va[i])
        end);

julia> for i in I
            @production(M, Z[i], [s=1, t=0], begin
                @output(PK, 20, t)
                @input(PL[i], 2, s, taxes = [Tax(RA, T[i])])
            end)
        end
```
"""
macro production(input_args...)
    error_fn = Containers.build_error_fn("production", input_args, __source__)
    args,kwargs = Containers.parse_macro_arguments(
        error_fn, 
        input_args; 
        num_positional_args = 4,
        valid_kwargs = nothing
        )

    model = esc(args[1])

    sector, index_vars, indices, all_indices = parse_ref_sets(error_fn, args[2])
    sector_name_expr = build_name_expr(sector, all_indices, kwargs)
    
    nests = build_nest_expr(args[3], __source__, index_vars)
    netputs = build_netputs(args[4], index_vars)

    build_production_sectors = JuMP.Containers.container_code(
        index_vars,
        indices,
        quote
            PreProduction(
                $sector_name_expr,
                $nests,
                $netputs
            )
        end,
        :DenseAxisArray
    )
   
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
        create_nodes(model, nests), 
        netputs,
        index_vars
    )
end

function build_production(
        error_fn::Function,
        model,
        index_vars::Vector{Any},
        base_sector,
        pre_production::AbstractArray{<:PreProduction}
        )

    P =  build_production.(error_fn, Ref(model), Ref(index_vars), Ref(base_sector), pre_production)
    return IndexedProduction(base_sector, P, index_vars)
end


function ScalarProduction(
        error_fn::Function, 
        sector, 
        node_structure, 
        all_netputs,
        index_vars
        )

    nodes, root_nodes = node_structure

    netputs = build_netput.(error_fn, all_netputs, Ref(nodes), Ref(index_vars))

    # identify input and output trees - Should verify all signs are the same in the tree
    (input_tree, output_tree) = netput_sign(root_nodes[1]) == -1 ? (root_nodes[1], root_nodes[2]) : (root_nodes[2], root_nodes[1])

    input_tree = prune!(input_tree)
    output_tree = prune!(output_tree)
    netputs = filter(x -> !isnothing(x), prune!(netputs))

    if xor(isnothing(input_tree), isnothing(output_tree))
        error_fn("Input and output trees must be both present or both absent for sector $sector")
    end

    # Is the if statement necessary?
    if !isnothing(input_tree) && !isnothing(output_tree)
        build_cost_function(input_tree)
        build_cost_function(output_tree)   
    end
    
    netputs_by_commodity = Dict{Commodity, Vector{Netput}}()
    taxes_by_consumer = Dict{Consumer, Vector{Netput}}()

    for netput in netputs
        add_netputs_by_commodity!(netputs_by_commodity, netput)
        add_taxes_by_consumer!(taxes_by_consumer, netput)
    end
    
    return ScalarProduction(sector, netputs_by_commodity, input_tree, output_tree, taxes_by_consumer)
end



function add_netputs_by_commodity!(
        netputs_by_commodity::Dict{Commodity, Vector{Netput}},
        netput::Netput
        )

    C = commodity(netput)
    if !haskey(netputs_by_commodity, C)
        netputs_by_commodity[C] = Vector{Netput}()
    end
    push!(netputs_by_commodity[C], netput)

    return netputs_by_commodity
end

function add_netputs_by_commodity!(
        netputs_by_commodity::Dict{Commodity, Vector{Netput}},
        ::Nothing
        )  
    return netputs_by_commodity
end


function add_netputs_by_commodity!(
        netputs_by_commodity::Dict{Commodity, Vector{Netput}},
        netputs::AbstractArray{<:Any}
        )

    add_netputs_by_commodity!.(Ref(netputs_by_commodity), netputs)

    return netputs_by_commodity
end


function add_taxes_by_consumer!(
        taxes_by_consumer::Dict{Consumer, Vector{Netput}},
        netput::Netput
        )

    for tax in taxes(netput)
        consumer = tax_agent(tax)
        if !haskey(taxes_by_consumer, consumer)
            taxes_by_consumer[consumer] = Vector{Netput}()
        end
        if netput ∉ taxes_by_consumer[consumer]
            push!(taxes_by_consumer[consumer], netput)
        end
    end

    return taxes_by_consumer
end

function add_taxes_by_consumer!(
        taxes_by_consumer::Dict{Consumer, Vector{Netput}},
        ::Nothing
        )
    return taxes_by_consumer
end

function add_taxes_by_consumer!(
        taxes_by_consumer::Dict{Consumer, Vector{Netput}},
        netputs::AbstractArray{<:Any}
        )

    add_taxes_by_consumer!.(Ref(taxes_by_consumer), netputs)

    return taxes_by_consumer
end