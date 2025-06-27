
# Final Demands/Endowments

__FINAL_DEMAND_KWARGS__ = [:reference_price]
__ENDOWMENT_KWARGS__ = Symbol[]


struct PreDemandNetput
    commodity::Any
    quantity::Any
    netput_type::Any
    index_vars::Vector{Any}
    reference_price::Any
end


function parse_demand_netput(error_fn::Function, netput_arg::Any, netput_fn::DataType, valid_kwargs::Vector{Symbol})

    args, kwargs = MPSGE.parse_netput_macro_arguments(
        error_fn,
        netput_arg,
        netput_fn;
        num_positional_args = 2,
        valid_kwargs = valid_kwargs
    )

    commodity = args[1]
    quantity = args[2]
    reference_price = get(kwargs, :reference_price, 1.0)    

    x, index_vars, indices, all_indices = MPSGE.parse_ref_sets(error_fn, commodity)
    commodity_name_expr = MPSGE.build_name_expr(x, all_indices, kwargs)


    build_code = JuMP.Containers.container_code(
        index_vars,
        indices,
        quote
            PreDemandNetput(
                $commodity_name_expr,
                $(esc(quantity)),
                $(esc(netput_fn)),
                $index_vars,
                $(esc(reference_price))
            )
        end,
        :DenseAxisArray
    )

    return build_code
end




"""
    @final_demand(commodity, quantity, nest, kwargs...)

This macro is soley used within a [`@demand`](@ref) block to define the final demands 
for a consumer. 

## Required Arguments

- `commodity` - A commodity. This can either be a scalar `C` or indexed `C[i=R]`. 
- `quantity` - Either a number or expression. 

## Keyword Arguments

- `reference_price=1` Set the reference price of a commodity.

## Examples

```julia
@final_demand(C, 1)
@final_demand(C[i=R], 1)
@final_demand(C[i=R], quantity[i])
@final_demand(C[i=R], quantity[i], reference_price = price[i])
```
"""
macro final_demand(input_args...)
    error_fn = Containers.build_error_fn("final_demand", input_args, __source__)
    return parse_demand_netput(error_fn, input_args, ScalarFinalDemand, __FINAL_DEMAND_KWARGS__)
end

"""
    @endowment(commodity, quantity, nest, kwargs...)

This macro is soley used within a [`@demand`](@ref) block to define the endowments 
for a consumer. 

## Required Arguments

- `commodity` - A commodity. This can either be a scalar `C` or indexed `C[i=R]`. 
- `quantity` - Either a number or expression. 

## Examples

```julia
@endowment(C, 1)
@endowment(C[i=R], 1)
@endowment(C[i=R], quantity[i])
```
"""
macro endowment(input_args...)
    error_fn = Containers.build_error_fn("endowment", input_args, __source__)
    return parse_demand_netput(error_fn, input_args, ScalarEndowment, __ENDOWMENT_KWARGS__)
end





function build_demand_netput(error_fn::Function, netput::PreDemandNetput, sector_index_vars)
    commodity = netput.commodity
    quantity = netput.quantity
    netput_fn = netput.netput_type
    index_vars = netput.index_vars
    reference_price = netput.reference_price

    common_index_vars = intersect(index_vars, sector_index_vars)
    if !isempty(common_index_vars)
        error_fn("The netput $commodity has index variables $common_index_vars " * 
            "that are already used in the sector. " *
            "This is not allowed, as it create ambiguity in the model.\n")
    end

    
    N = netput_fn(commodity, quantity; reference_price = reference_price) 

    

    return N

end


function build_demand_netput(error_fn::Function, netput::AbstractArray{<:PreDemandNetput}, sector_index_vars)
    build_demand_netput.(error_fn, netput, Ref(sector_index_vars))
end



# Demand

__DEMAND_KWARGS__ = [:elasticity]

struct PreDemand
    consumer
    netputs
    elasticity
end


"""
    @demand(model, comsumer, demand_netputs; elasticity = 1)

Define a demand for a `consumer` in the `model` with given `demand_netputs` where 
the `final_demands` have an elasticity of substitution `elasticity`.

## consumer

The `consumer` can take the following forms:

- `X`, if `X` is a scalar consumer.
- `X[i=I,j=J,...]` if the consumer is indexed. Indexing
- `X[i=I, :j]` if `:j` is an element of the second index of `X`.
- `X[i=I, j]` if `j` is defined outside the demand block, for example in a `for` loop.

For an indexed consumer it is __required__ that an index is provided when iterating over an array. For example, 

```julia
julia> I = [:a,:b]

julia> @consumer(M, X[i=I])

julia> demand(M, X[I], ...) # This is not allowed and will error.

julia> demand(M, X[i=I], ...) # This is required behavior.

julia>  for i in I
            demand(M, X[i], ...) # This is allowed.
        end
```

## demand_netputs

A demand netput is either a [`@final_demand`](@ref) or an [`@endowment`](@ref). The netputs get wrapped in a `begin ... end` block and each netput must be on its own line. For examples creating netputs, see the netput documentation and the examples below.

Netputs can use indices initialized in the `consumer`, but can not use them as a new index. For example, if we have `X[i=I]` in the demand block, we can use
`@final_demand(PX[i],...)` but not `@final_demand(PX[i=I],...)`. The latter will error.

## Examples

We demonstrate three ways to define a demand block. 

```julia
julia> M = MPSGEModel();

julia> I = [:a,:b]

julia> @parameters(M, begin
            elas[i=I,j=J], 4
            T[i=I], .1
        end)

julia> @commodities(M, begin
            PX
            PY
            PL[i=I]
            PK
        end);

julia> @consumers(M, begin
            X
            Y[i=I, j=J]
            Z[i=I]
        end);

julia> @demand(M, X, begin
            @final_demand(PX, 10, t)
            @endowment(PL, 5, s)
            @endowment(PK, 5, s)
        end);

julia> @demand(M, Y[i=I,j=J], [s=2, t=1, begin
            @final_demand(PY, 15, t, reference_price = 2)
            @endowment(PX, 3, s)
            @endowment(PL[ii=I], 4, va[ii])
            @endowment(PK, 6, va[i])
        end, elasticity = 2);

julia> for i in I
            @demand(M, Z[i], begin
                @final_demand(PK, 20, t)
                @endowment(PL[i], 2, s)
            end)
        end
```
"""
macro demand(input_args...)
    error_fn = Containers.build_error_fn("production", input_args, __source__)
    args,kwargs = Containers.parse_macro_arguments(
        error_fn, 
        input_args; 
        num_positional_args = 3,
        valid_kwargs = __DEMAND_KWARGS__
        )

    model = esc(args[1])
    elasticty = get(kwargs, :elasticity, 1.0)

    consumer, index_vars, indices, all_indices = parse_ref_sets(error_fn, args[2])
    consumer_name_expr = build_name_expr(consumer, all_indices, kwargs)
    
    demand_netputs = build_netputs(args[3], index_vars)



    build_demand = JuMP.Containers.container_code(
        index_vars,
        indices,
        quote
            PreDemand(
                $consumer_name_expr,
                $demand_netputs,
                $(esc(elasticty))
            )
        end,
        :DenseAxisArray
    )

    demand_code = quote
        D = build_demand(
            $error_fn,
            $model,
            $index_vars,
            $(esc(consumer)),
            $build_demand
        )
       add_demand!($model, D)
    end
   
    return demand_code
end



function build_demand(
    error_fn::Function,
    model,
    index_vars,
    base_consumer,
    pre_demand
)


    return ScalarDemand(
        error_fn,
        model,
        pre_demand.consumer,
        pre_demand.netputs,
        pre_demand.elasticity,
        index_vars
    )
end


function build_demand(
        error_fn::Function,
        model,
        index_vars::Vector{Any},
        base_consumer,
        pre_demand::AbstractArray{<:PreDemand}
        )

    P =  build_demand.(error_fn, Ref(model), Ref(index_vars), Ref(base_consumer), pre_demand)
    return IndexedDemand(base_consumer, P, index_vars)
end


function ScalarDemand(
    error_fn::Function,
    model,
    consumer,
    all_netputs,
    elasticity,
    index_vars
)

    demand_netputs = build_demand_netput.(error_fn, all_netputs, Ref(index_vars))
    demand_netputs = filter(x -> !isnothing(x), prune!(demand_netputs))

    netputs_by_commodity = Dict{Commodity, Vector{abstractDemandFlow}}()
    for netput in demand_netputs
        add_netputs_by_commodity!(netputs_by_commodity, netput)
    end


    return ScalarDemand(consumer, netputs_by_commodity; elasticity = elasticity)

end


function add_netputs_by_commodity!(
        netputs_by_commodity::Dict{Commodity, Vector{abstractDemandFlow}},
        netput::abstractDemandFlow
        )

    C = commodity(netput)
    if !haskey(netputs_by_commodity, C)
        netputs_by_commodity[C] = Vector{Netput}()
    end
    push!(netputs_by_commodity[C], netput)

    return netputs_by_commodity
end

function add_netputs_by_commodity!(
        netputs_by_commodity::Dict{Commodity, Vector{abstractDemandFlow}},
        netputs::AbstractArray{<:Any}
        )

    add_netputs_by_commodity!.(Ref(netputs_by_commodity), netputs)

    return netputs_by_commodity
end

function add_netputs_by_commodity!(
        netputs_by_commodity::Dict{Commodity, Vector{abstractDemandFlow}},
        ::Nothing
        )  
    return netputs_by_commodity
end