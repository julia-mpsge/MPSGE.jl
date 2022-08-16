"""
    swap_our_param_with_jump_param(jm, expr)

This function takes an expression tree and replaces all instances of
`ParameterRef` with the corresponding `JuMP.NLParameter`.
"""
function swap_our_param_with_jump_param(jm, expr)
    return MacroTools.postwalk(expr) do x
        if x isa ParameterRef
            if x.subindex===nothing
                return jm[x.model._parameters[x.index].name]
            else
                return jm[x.model._parameters[x.index].name][x.subindex]
            end
        elseif x isa CommodityRef
            get_jump_variable_for_commodity(jm, x)
        else
            return x
        end
    end
end

"""
swap_our_param_with_val(expr)

This function takes an expression tree and replaces all instances of
`ParameterRef` with its value.
"""
function swap_our_param_with_val(expr)
    return MacroTools.postwalk(expr) do x
        if x isa ParameterRef
            if x.subindex===nothing
                return x.model._parameters[x.index].value
            else
                return x.model._parameters[x.index].value[x.subindex]
            end
        elseif x isa CommodityRef
            c = get_full(x)
            if c isa ScalarCommodity
                return c.benchmark
            else
                return c.benchmark[x.subindex]
            end
        else
            return x
        end
    end
end

function get_jump_variable_for_sector(jm, sector)
    if sector.subindex===nothing
        return jm[get_name(sector)]
    else
        return jm[get_name(sector)][sector.subindex]
    end
end

function get_jump_variable_for_commodity(jm, commodity::CommodityRef)
    if commodity.subindex===nothing
        return jm[get_name(commodity)]
    else
        return jm[get_name(commodity)][commodity.subindex]
    end
end

function get_jump_variable_for_commodity(jm, commodity::ScalarCommodity)
    return jm[get_name(commodity)]
end

function get_jump_variable_for_commodity(jm, commodity::IndexedCommodity)
    return jm[get_name(commodity)][commodity.subindex]
end

function get_jump_expression_for_commodity_producer_price(m::Model, jm, commodity::CommodityRef)
    jump_commodity = get_jump_variable_for_commodity(jm, commodity)

    taxes = []
    for pf in m._productions
        for output in pf.outputs
            if output.commodity == commodity
                for tax in output.taxes
                    push!(taxes, tax.rate)
                end
            end
        end
    end

    tax = :(+(0., $(taxes...)))

    return :($jump_commodity * (1. - $tax))
end

function get_jump_variable_for_consumer(jm, consumer::ConsumerRef)
    if consumer.subindex===nothing
        return jm[get_name(consumer)]
    else
        return jm[get_name(consumer)][consumer.subindex]
    end
end

function get_jump_variable_for_consumer(jm, consumer::ScalarConsumer)
    return jm[consumer.name]
end

function get_jump_variable_for_consumer(jm, consumer::IndexedConsumer)
    return jm[consumer.name][consumer.subindex]
end

function get_tax_revenue_for_consumer(jm, m, consumer::ScalarConsumer)
    taxes = []
    for pf in m._productions
        for output in pf.outputs
            for tax in output.taxes
                if get_full(tax.agent) == consumer
                    push!(taxes, :($(tax.rate) * $(output.quantity)))
                end
            end
        end
    end

    tax = :(+(0., $(taxes...)))

    return :($tax)
end

function get_tax_revenue_for_consumer(jm, m, consumer::ConsumerRef)
    c = get_full(consumer)
    
    return get_tax_revenue_for_consumer(jm, m, c)
end

function get_jump_variable_for_intermediate_supply(jm, output)
    return jm[get_comp_supply_name(output)]
end

function get_jump_variable_for_intermediate_demand(jm, input)
    return jm[get_comp_demand_name(input)]
end

function get_jump_variable_for_final_demand(jm, demand)
    return jm[get_final_demand_name(demand)]
end

function get_prod_func_name(x::Production)
    return Symbol("$(get_name(x.sector, true))")
end

function get_demand_func_name(x::DemandFunction)
    return Symbol("$(get_name(x.consumer, true))")
end

function get_comp_demand_name(i::Input)
    p = i.production_function::Production 
    return Symbol("$(get_name(i.commodity, true))†$(get_prod_func_name(p))")
end

function get_comp_supply_name(o::Output)
    p = o.production_function::Production
    return Symbol("$(get_name(o.commodity, true))‡$(get_prod_func_name(p))")
end

function get_final_demand_name(demand::Demand)
    demand_function = demand.demand_function::DemandFunction
    return Symbol("$(get_name(demand.commodity, true))ρ$(get_demand_func_name(demand_function))")
end