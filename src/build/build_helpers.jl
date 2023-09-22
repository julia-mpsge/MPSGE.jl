"""
    convert_mpsge_expr_to_jump_nonlinearexpr(jm, expr)

This function takes an expression tree and replaces all instances of
MPSGE types with corresponding JuMP types and converts `Expr`s into
`JuMP.NonlinearExpr`.
"""
function convert_mpsge_expr_to_jump_nonlinearexpr(jm, expr)
    return MacroTools.postwalk(expr) do x
        if x isa Expr
            if x.head==:call
                JuMP.NonlinearExpr(x.args[1], x.args[2:end])
            else
                error("Found illegal Expr in tree: $x.")
            end
        elseif x isa ParameterRef
            get_jump_variable_for_param(jm, x)
        elseif x isa CommodityRef
            get_jump_variable_for_commodity(jm, x)
        elseif x isa AuxRef
            get_jump_variable_for_aux(jm, x)
        elseif x isa SectorRef
            get_jump_variable_for_sector(jm, x)
        elseif x isa ConsumerRef
            get_jump_variable_for_consumer(jm, x)
        elseif x isa ImplicitvarRef
            get_jump_variable_for_implicitvar(jm, x)
        else
            x
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
        elseif x isa SectorRef
            s = get_full(x)
            if s isa ScalarSector
                return s.benchmark
            else
                return s.benchmark[x.subindex]
            end
        elseif x isa AuxRef
            a = get_full(x)
            if a isa ScalarAux
                return a.benchmark
            else
                return a.benchmark[x.subindex]
            end
        else
            return x
        end
    end
end

"""
contains_our_param(expr)

This function takes an expression tree and tests whether it contains
a `ParameterRef` or `CommodityRef`
"""
function contains_our_param(expr)
    if expr isa Expr
        for x in expr.args
            if contains_our_param(x)
                return true
            end
        end

        return false
    elseif expr isa ParameterRef || expr isa CommodityRef
        return true
    else
        return false
    end
end


function get_jump_variable_for_sector(jm, sector)
    if sector.subindex===nothing
        return jm[get_name(sector)]
    else
        return jm[get_name(sector)][sector.subindex]
    end
end

function get_jump_variable_for_param(jm, parameter::ParameterRef)
    if parameter.subindex===nothing
        return jm[parameter.model._parameters[parameter.index].name]
    else
        return jm[parameter.model._parameters[parameter.index].name][parameter.subindex]
    end
end

function get_jump_variable_for_sector(jm, sector::SectorRef)
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

function get_expression_for_commodity_producer_price(jm, pf, commodity::CommodityRef)

    taxes = []
        for output in pf.outputs
            if output.commodity == commodity
                for tax in output.taxes
                    push!(taxes, tax.rate)
                end
            end
        end

    return tojump(jm, commodity) * (1. - +(0., taxes...))
end

function get_expression_for_commodity_consumer_price(jm, pf, commodity::CommodityRef)

    taxes = []
    for input in pf.inputs
        if input.commodity == commodity
            for tax in input.taxes
                push!(taxes, tax.rate)
            end
        end
    end

    return tojump(jm, commodity) * +(1., taxes...)
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
                    push!(taxes, :($(tax.rate) * $(output.quantity) * $(output.commodity) * $(pf.sector) ))
                end
            end
        end
        for input in pf.inputs
            for tax in input.taxes
                if get_full(tax.agent) == consumer
                    push!(taxes, :($(tax.rate) * $(input.quantity) * $(input.commodity) * $(pf.sector) ))
                end
            end
        end
    end

    tax = :(+(0., $(taxes...)))

    return tax
end

function get_tax_revenue_for_consumer(jm, m, cr::ConsumerRef)
    taxes = []
    for pf in m._productions
        for output in pf.outputs
            for tax in output.taxes
                if cr.subindex === nothing
                    if get_full(tax.agent) == get_full(cr)    
                        push!(taxes, :($(tax.rate) * $(jm[get_comp_supply_name(output)]) * $(output.commodity) * $(pf.sector)))
                    end
                else
                    if jm[get_full(cr).name][tax.agent.subindex] ==  jm[get_full(cr).name][cr.subindex]
                        push!(taxes, :($(tax.rate) * $(jm[get_comp_supply_name(output)]) * $(output.commodity) * $(pf.sector)))
                    end
                end    
            end
        end
        for input in pf.inputs
            for tax in input.taxes
                if cr.subindex === nothing
                    if get_full(tax.agent) == get_full(cr)    
                        push!(taxes, :($(tax.rate) * $(jm[get_comp_demand_name(input)]) * $(input.commodity) * $(pf.sector)))
                    end
                else
                    if jm[get_full(cr).name][tax.agent.subindex] ==  jm[get_full(cr).name][cr.subindex]
                        push!(taxes, :($(tax.rate) * $(jm[get_comp_demand_name(input)]) * $(input.commodity) * $(pf.sector)))
                    end
                end    
            end
        end
    end

    tax = :(+(0., $(taxes...)))

    return tax
end

function get_jump_variable_for_aux(jm, aux::AuxRef)
    if aux.subindex===nothing
        return jm[get_name(aux)]
    else
        return jm[get_name(aux)][aux.subindex]
    end
end

function get_jump_variable_for_implicitvar(jm, im::ImplicitvarRef)
    # if im.subindex===nothing    
        return jm[get_name(im)]
    # else
        # return jm[get_name(im)][im.subindex]
    # end
end

function get_prod_func_name(x::Production)
    return Symbol("$(get_name(x.sector, true))")
end

function get_demand_func_name(x::DemandFunction)
    return Symbol("$(get_name(x.consumer, true))")
end

function get_comp_supply_name(o::Output)
    p = o.production_function::Production
    return Symbol("$(get_name(o.commodity, true))‡$(get_prod_func_name(p))")
end

function get_final_demand_name(demand::Demand)
    demand_function = demand.demand_function::DemandFunction
    return Symbol("$(get_name(demand.commodity, true))ρ$(get_demand_func_name(demand_function))")
end

function get_comp_demand_name(i::Input)
    p = i.production_function::Production 
    return Symbol("$(get_name(i.commodity, true))†$(get_prod_func_name(p))")
end

function tojump(jm, x::Float64)
    x
end

function tojump(jm, x::Expr)
    convert_mpsge_expr_to_jump_nonlinearexpr(jm, x)
end

function tojump(jm, x::CommodityRef)
    get_jump_variable_for_commodity(jm, x)
end

function tojump(jm, x::ConsumerRef)
    get_jump_variable_for_consumer(jm, x)
end


function tojump(jm, x::ImplicitvarRef)
    get_jump_variable_for_implicitvar(jm, x)
end
