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
            )
            ,
            (
                +(
                    (
                        Θ(jm, pf, input) * (get_expression_for_commodity_consumer_price(jm, pf, input.commodity)/(tojump(jm, get_commodity_benchmark(input.commodity))*tojump(jm, input.price))) ^ (1-tojump(jm, pf.elasticity)) for input in pf.inputs
                    )...
                )
            )^(1/(1-tojump(jm, pf.elasticity)))
        )
    else # This branch is an optimization: if the elasticity doesn't contain a parameter, we can at build time only insert one case into the expression
        if eval(swap_our_param_with_val(pf.elasticity))==1
            return *(
                        (
                            (get_expression_for_commodity_consumer_price(jm, pf, input.commodity)/(tojump(jm, get_commodity_benchmark(input.commodity))*tojump(jm, input.price))) ^ Θ(jm, pf, input)
                            for input in pf.inputs
                        )...
                )
        else 
            return (
                +(
                    (
                        Θ(jm, pf, input) * (get_expression_for_commodity_consumer_price(jm, pf, input.commodity)/(tojump(jm, get_commodity_benchmark(input.commodity))*tojump(jm, input.price))) ^ (1-tojump(jm, pf.elasticity)) for input in pf.inputs
                    )...
                )
            )^(1/(1-tojump(jm, pf.elasticity)))
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

function create_expenditure_expr(jm, df::DemandFunction)
    if contains_our_param(df.elasticity)
        return JuMP.op_ifelse(
            JuMP.op_equal_to(tojump(jm,df.elasticity), 1.), 
            *(
                (
                    (
                        tojump(jm, dm.commodity) 
                        /
                        (
                            tojump(jm, get_commodity_benchmark(dm.commodity)) *
                        tojump(jm, dm.price)
                        )
                    )^(Θ(jm, df, dm))
                    for dm in df.demands
                )...
            ),   
     +(
                (
                    Θ(jm, df, dm) *
                    (
                        tojump(jm, dm.commodity) 
                        /
                        (
                            tojump(jm, get_commodity_benchmark(dm.commodity)) *
                        tojump(jm, dm.price)
                        )
                    )^(1-tojump(jm, df.elasticity))
                    for dm in df.demands
                )...
        ) ^ (1/(1-tojump(jm, df.elasticity)))
        )
    else
        if eval(swap_our_param_with_val(df.elasticity))==1
            expr = 
            *(
                (
                    (
                        tojump(jm, dm.commodity) 
                        /
                        (
                            tojump(jm, get_commodity_benchmark(dm.commodity)) *
                        tojump(jm, dm.price)
                        )
                    )^(Θ(jm, df, dm))
                    for dm in df.demands
                )...
            )
        else
            expr =
            +(
                (
                    Θ(jm, df, dm) *
                    (
                        /(tojump(jm, dm.commodity),
                        (tojump(jm, get_commodity_benchmark(dm.commodity)) *
                        tojump(jm, dm.price)))
                    )^(1-tojump(jm, df.elasticity))
                    for dm in df.demands
                )...
            ) ^ (1/(1-tojump(jm, df.elasticity)))
        end
    return expr
    end
end

function build_implicitconstraints!(m, jm)
    # Add compensated demand (intermediate and factor)
    for s in m._productions
        for input in s.inputs
            jm[get_comp_demand_name(input)] = @expression(jm, 
            # jump_ex = 
                tojump(jm, input.quantity) *
                (       
                    create_cost_expr(m, jm, s) * 
                    get_commodity_benchmark(input.commodity) * 
                    tojump(jm, input.price) /
                    get_expression_for_commodity_consumer_price(jm, s, input.commodity)
                )^tojump(jm,s.elasticity) #- 
                # tojump(jm, m._implicitvarsDict[get_comp_demand_name(input)])
                )

            # jump_var = jm[get_comp_demand_name(input)]

            # @constraint(jm, jump_ex ⟂ jump_var)
            push!(m._nlexpressions.comp_demand, get_comp_demand_name(input) => jm[get_comp_demand_name(input)])
            # push!(m._nlexpressions.comp_demand, (@expression(jm, :($jump_var), :($jump_ex))))
            # push!(m._nlexpressions.comp_demand, (expr=jump_ex, var=jump_var))
        end
    end

    # Add compensated supply
    for s in m._productions
        for output in s.outputs
            # jump_ex =
            jm[get_comp_supply_name(output)] =
            @expression(jm, tojump(jm, output.quantity) *
                (
                    get_expression_for_commodity_producer_price(jm, s, output.commodity) /
                    (
                        create_rev_expr(m, jm, s) *
                        get_commodity_benchmark(output.commodity) *
                        tojump(jm, output.price)
                    )
                )^tojump(jm, s.tr_elasticity))# -
                # tojump(jm, m._implicitvarsDict[get_comp_supply_name(output)])

            # jump_var = jm[get_comp_supply_name(output)]

            # @constraint(jm, jump_ex ⟂ jump_var)
            # push!(m._nlexpressions.comp_supply, (expr=jump_ex, var=jump_var))
            push!(m._nlexpressions.comp_supply, get_comp_supply_name(output) => jm[get_comp_supply_name(output)])
        end
    end

    # Add final demand
    for demand_function in m._demands
            for demand in demand_function.demands
                # jump_ex = 
                jm[get_final_demand_name(demand)] =
                @expression(jm, tojump(jm, demand.quantity) *
                    (
                        tojump(jm, demand_function.consumer) / # (consumer's) income
                        +(
                            (
                                tojump(jm, d.quantity) * tojump(jm, d.price) * tojump(jm, get_commodity_benchmark(d.commodity)) for d in demand_function.demands
                            )...
                        ) # benchmark income
                    ) *
                    create_expenditure_expr(jm, demand_function) ^ (tojump(jm, demand_function.elasticity)-1) *
                    (
                        tojump(jm, get_commodity_benchmark(demand.commodity)) *
                        tojump(jm, demand.price) / # p__bar_i
                        tojump(jm, demand.commodity)
                    ) ^ tojump(jm, demand_function.elasticity)# - # p_i
                    # tojump(jm, m._implicitvarsDict[get_final_demand_name(demand)])
                )
                # jump_var = jm[get_final_demand_name(demand)]

                # @constraint(jm, jump_ex ⟂ jump_var)
                push!(m._nlexpressions.final_demand, get_final_demand_name(demand) => jm[get_final_demand_name(demand)])
                # push!(m._nlexpressions.final_demand, (expr=jump_ex, var=jump_var))
            end
    end
end
