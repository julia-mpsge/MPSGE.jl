"""
    swap_our_param_with_jump_param(expr)

This function takes an expression tree and replaces all instances of
`ParameterRef` with the corresponding `JuMP.NLParameter`.
"""
function swap_our_param_with_jump_param(expr)
    return MacroTools.postwalk(expr) do x
        if x isa ParameterRef
            return x.model._jump_nlparameters[x.model._parameters[x.index].name]
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
            return x.model._parameters[x.index].value
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

function get_jump_variable_for_commodity(jm, commodity)
    if commodity.subindex===nothing
        return jm[get_name(commodity)]
    else
        return jm[get_name(commodity)][commodity.subindex]
    end
end

function get_jump_variable_for_consumer(jm, consumer)
    return jm[get_name(consumer)]
end

function get_prod_func_name(x::Production)
    return Symbol("$(get_name(x.sector, true))")
end

function get_demand_func_name(x::DemandFunction)
    return Symbol("$(get_name(x.consumer))")
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