
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





macro final_demand(input_args...)
    error_fn = Containers.build_error_fn("final_demand", input_args, __source__)
    return parse_demand_netput(error_fn, input_args, ScalarFinalDemand, __FINAL_DEMAND_KWARGS__)
end

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