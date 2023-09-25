function Θ(jm, pf::Production, i::Input)
    return tojump(jm, i.quantity) *
        tojump(jm, i.price) *
        tojump(jm, get_commodity_benchmark(i.commodity)) /
        +(
            (
                tojump(jm, i.quantity) * tojump(jm, i.price) * tojump(jm, get_commodity_benchmark(i.commodity)) for i in pf.inputs
            )...
        )
end

function Θ(jm, pf::Production, o::Output)
    return tojump(jm, o.quantity) *
        tojump(jm, o.price) * 
        tojump(jm, get_commodity_benchmark(o.commodity)) /
        +(
            (
                tojump(jm, o.quantity) * tojump(jm, o.price) * tojump(jm, get_commodity_benchmark(o.commodity)) for o in pf.outputs
            )...
        )
end

function Θ(jm, df::DemandFunction, dm::Demand)   
    return tojump(jm, dm.quantity) *
        tojump(jm, dm.price) *
        tojump(jm, get_commodity_benchmark(dm.commodity)) /
        +(
            (
                tojump(jm, d.quantity) * tojump(jm, d.price) * tojump(jm, get_commodity_benchmark(d.commodity)) for d in df.demands
            )...
        )
end

function y_over_y_bar(jm, pf::Production)    
    if contains_our_param(pf.elasticity)
        jump_elasticity = tojump(jm, pf.elasticity)
        ρ = (
                jump_elasticity - 1
            ) / 
            jump_elasticity

        jump_expr =  
            JuMP.op_ifelse(
                JuMP.op_equal_to(jump_elasticity, 0.0),
                min(
                    (
                        jm[get_comp_demand_name(i)] / tojump(jm, i.quantity) for i in pf.inputs
                    )...
                ),
                JuMP.op_ifelse(
                    JuMP.op_equal_to(jump_elasticity,1.),
                    *(
                        (
                            (jm[get_comp_demand_name(i)]/tojump(jm, i.quantity))^Θ(jm, pf,i) for i in pf.inputs
                        )...
                    ),
                    (
                        +(
                            (
                                Θ(jm, pf,i) * (jm[get_comp_demand_name(i)]/tojump(jm, i.quantity))^ρ for i in pf.inputs
                            )...
                        )
                    ) ^ (1/ρ)
                )
            )

        return jump_expr
    else # This branch is an optimization: if the elasticity doesn't contain a parameter, we can at build time only insert one case into the expression
        if eval(swap_our_param_with_val(pf.elasticity))==0
            return min(
                 ( 
                     if eval(swap_our_param_with_val(i.quantity))>0.
                       tojump(jm, jm[get_comp_demand_name(i)])/tojump(jm, i.quantity)
                    else
                        0.
                    end
         for i in pf.inputs
                )...
            )
        elseif eval(swap_our_param_with_val(pf.elasticity))==1
            return *(
                (   
                    if eval(swap_our_param_with_val(i.quantity))>0.
                        (jm[get_comp_demand_name(i)]/tojump(jm, i.quantity))^Θ(jm, pf,i)
                    else
                        1.
                    end
                    for i in pf.inputs
                )...
            )
        else
            ρ = (tojump(jm, pf.elasticity)-1)/tojump(jm, pf.elasticity)
            return (
                    +((
                        if eval(swap_our_param_with_val(i.quantity))>0.
                        (
                          Θ(jm, pf,i) *
                            (   
                                    jm[get_comp_demand_name(i)]/tojump(jm, i.quantity)
                            )^ρ
                         )
                        else
                            0.
                        end 
                            for i in pf.inputs
                        )...
                    )
                )^(1/ρ)
        end
    end
end

function create_cost_expr(m, jm, pf::Production)
    if contains_our_param(pf.elasticity)
        return JuMP.op_ifelse(
            JuMP.op_equal_to(tojump(jm,pf.elasticity), 1.),
            *(
                (
                    (
                        get_expression_for_commodity_consumer_price(jm, pf, input.commodity) /
                        (
                            tojump(jm, get_commodity_benchmark(input.commodity)) * tojump(jm, input.price)
                        )
                    ) ^ Θ(jm, pf, input) for input in pf.inputs
                )...
            ) *
            y_over_y_bar(jm, pf),
            (
                +(
                    (
                        Θ(jm, pf, input) * (get_expression_for_commodity_consumer_price(jm, pf, input.commodity)/(tojump(jm, get_commodity_benchmark(input.commodity))*tojump(jm, input.price))) ^ (1-tojump(jm, pf.elasticity)) for input in pf.inputs
                    )...
                )
            )^(1/(1-tojump(jm, pf.elasticity))) * y_over_y_bar(jm, pf)
        )
    else # This branch is an optimization: if the elasticity doesn't contain a parameter, we can at build time only insert one case into the expression
        if eval(swap_our_param_with_val(pf.elasticity))==1
            return *(
                        (
                            (get_expression_for_commodity_consumer_price(jm, pf, input.commodity)/(tojump(jm, get_commodity_benchmark(input.commodity))*tojump(jm, input.price))) ^ Θ(jm, pf, input)
                            for input in pf.inputs
                        )...
                ) * y_over_y_bar(jm, pf)
        else 
            return (
                +(
                    (
                        Θ(jm, pf, input) * (get_expression_for_commodity_consumer_price(jm, pf, input.commodity)/(tojump(jm, get_commodity_benchmark(input.commodity))*tojump(jm, input.price))) ^ (1-tojump(jm, pf.elasticity)) for input in pf.inputs
                    )...
                )
            )^(1/(1-tojump(jm, pf.elasticity))) * y_over_y_bar(jm, pf)
        end
    end
end

function create_rev_expr(m, jm, pf::Production)
    jump_expr = (
            +(
                (
                    Θ(jm, pf, output) *
                        (
                            get_expression_for_commodity_producer_price(jm, pf, output.commodity) /
                            (
                                tojump(jm, get_commodity_benchmark(output.commodity))*tojump(jm, output.price)
                            )
                        )^(1.0 + tojump(jm, pf.tr_elasticity))
                    for output in pf.outputs
                )...
            )
        )^(1.0/(1.0+tojump(jm, pf.tr_elasticity)))

    return jump_expr
end

function u_over_u_bar(jm, dm::DemandFunction)
    if contains_our_param(dm.elasticity)
        ρ = (tojump(jm, dm.elasticity)-1)/tojump(jm, dm.elasticity)

        
                    # TODO #71 Figure out why the commented version doesn't work, it matches paper
                    # (+($((:( $(Θ(jm, dm,d)) * ($(jm[get_final_demand_name(d)])/$(d.quantity))^$ρ ) for d in dm.demands)...)))^(1/$ρ)
        expr = +(
            (
                Θ(jm, dm,d) * (tojump(jm, d.quantity)/tojump(jm, d.quantity))^ρ for d in dm.demands
            )...
        )^(1/ρ)
        return expr
    else # This branch is an optimization: if the elasticity doesn't contain a parameter, we can at build time only insert one case into the expression
            ρ = (tojump(jm, dm.elasticity)-1)/tojump(jm, dm.elasticity)
            return(
                +(
                    # TODO #71 Figure out why the commented version doesn't work, it matches paper
                    # $((:( $(Θ(jm, dm,d)) * ($(jm[get_final_demand_name(d)])/$(d.quantity))^$ρ ) for d in dm.demands)...)
                    (
                        Θ(jm, dm,d) * (tojump(jm, d.quantity)/tojump(jm, d.quantity))^ρ for d in dm.demands
                    )...
                )
            )^(1/ρ)
    end
end

function create_expenditure_expr(jm, df::DemandFunction)
    expr = +(
                (
                    Θ(jm, df, dm) *
                    (
                        /(tojump(jm, dm.commodity),
                        (tojump(jm, get_commodity_benchmark(dm.commodity)) *
                        tojump(jm, dm.price)))
                    )^(1-tojump(jm, df.elasticity))
                    for dm in df.demands
                )...
        ) ^ (1/(1-tojump(jm, df.elasticity))) *
        u_over_u_bar(jm, df)
    
    return expr
end

function build_implicitconstraints!(m, jm)
    # Add compensated demand (intermediate and factor)
    for s in m._productions
        for input in s.inputs

            jump_ex = 
                tojump(jm, input.quantity) *
                y_over_y_bar(jm, s) *
                (       
                    create_cost_expr(m, jm, s) * 
                    get_commodity_benchmark(input.commodity) * 
                    tojump(jm, input.price) /
                    get_expression_for_commodity_consumer_price(jm, s, input.commodity)
                )^tojump(jm,s.elasticity) - 
                tojump(jm, m._implicitvarsDict[get_comp_demand_name(input)])

            jump_var = jm[get_comp_demand_name(input)]

            @constraint(jm, jump_ex ⟂ jump_var)
            push!(m._nlexpressions.comp_demand, (expr=jump_ex, var=jump_var))
        end
    end

    # Add compensated supply
    for s in m._productions
        for output in s.outputs
            jump_ex =
                tojump(jm, output.quantity) *
                y_over_y_bar(jm, s) *
                (
                    get_expression_for_commodity_producer_price(jm, s, output.commodity) /
                    (
                        create_rev_expr(m, jm, s) *
                        get_commodity_benchmark(output.commodity) *
                        tojump(jm, output.price)
                    )
                )^tojump(jm, s.tr_elasticity) -
                tojump(jm, m._implicitvarsDict[get_comp_supply_name(output)])

            jump_var = jm[get_comp_supply_name(output)]

            @constraint(jm, jump_ex ⟂ jump_var)
            push!(m._nlexpressions.comp_supply, (expr=jump_ex, var=jump_var))
        end
    end

    # Add final demand
    for demand_function in m._demands
            for demand in demand_function.demands
                jump_ex = tojump(jm, demand.quantity) *
                    (
                        tojump(jm, demand_function.consumer) / # (consumer's) income
                        +(
                            (
                                tojump(jm, d.quantity) * tojump(jm, d.price) * tojump(jm, get_commodity_benchmark(d.commodity)) for d in demand_function.demands
                            )...
                        ) # benchmark income (?)
                    ) *
                    create_expenditure_expr(jm, demand_function) ^ (tojump(jm, demand_function.elasticity)-1) *
                    (
                        tojump(jm, get_commodity_benchmark(demand.commodity)) *
                        tojump(jm, demand.price) / # p__bar_i
                        tojump(jm, demand.commodity)
                    ) ^ tojump(jm, demand_function.elasticity) - # p_i
                    tojump(jm, m._implicitvarsDict[get_final_demand_name(demand)])

                jump_var = jm[get_final_demand_name(demand)]

                @constraint(jm, jump_ex ⟂ jump_var)
                push!(m._nlexpressions.final_demand, (expr=jump_ex, var=jump_var))
            end
    end
end
