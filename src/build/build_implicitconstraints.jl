function Θ(pf::Production, i::Input)
    return :( $(i.quantity) * $(i.price) * $(get_commodity_benchmark(i.commodity)) / +($( (:( $(i.quantity) * $(i.price) * $(get_commodity_benchmark(i.commodity)) ) for i in pf.inputs)...) ) )
end

function Θ(pf::Production, o::Output)
    return :( $(o.quantity) * $(o.price) * $(get_commodity_benchmark(o.commodity)) / +($( (:( $(o.quantity) * $(o.price) * $(get_commodity_benchmark(o.commodity)) ) for o in pf.outputs)...) ) )
end

function Θ(df::DemandFunction, dm::Demand)   
    return :( $(dm.quantity) * $(get_commodity_benchmark(dm.commodity))/ $(get_consumer_benchmark(df.consumer)))
end

function y_over_y_bar(jm, pf::Production)
    if contains_our_param(pf.elasticity)
        ρ = :(($(pf.elasticity)-1)/$(pf.elasticity))

        return :(
            ifelse(
                $(pf.elasticity)==0.0,
                min($(( :( $(jm[get_comp_demand_name(i)])/$(i.quantity) ) for i in pf.inputs)...)),
                ifelse(
                    $(pf.elasticity)==1.,
                    *($(( :( ($(jm[get_comp_demand_name(i)])/$(i.quantity))^$(Θ(pf,i)) ) for i in pf.inputs)...)),
                    (+($((:( $(Θ(pf,i)) * ($(jm[get_comp_demand_name(i)])/$(i.quantity))^$ρ ) for i in pf.inputs)...)))^(1/$ρ)
                )
            )
        )
    else # This branch is an optimization: if the elasticity doesn't contain a parameter, we can at build time only insert one case into the expression
        if eval(swap_our_param_with_val(pf.elasticity))==0
            return :(
                min(
                    $(( :( $(jm[get_comp_demand_name(i)])/$(i.quantity) ) for i in pf.inputs)...)
                )
            )
        elseif eval(swap_our_param_with_val(pf.elasticity))==1
            return :(
                *(
                    $(( :( ($(jm[get_comp_demand_name(i)])/$(i.quantity))^$(Θ(pf,i)) ) for i in pf.inputs)...)
                )
            )
        else
            ρ = :(($(pf.elasticity)-1)/$(pf.elasticity))
            return :(
                (
                    +(
                        $((:( $(Θ(pf,i)) * ($(jm[get_comp_demand_name(i)])/$(i.quantity))^$ρ ) for i in pf.inputs)...)
                    )
                )^(1/$ρ)
            )
        end
    end
end

function create_cost_expr(m, jm, pf::Production)
    if contains_our_param(pf.elasticity)
        return :(
            ifelse(
                $(pf.elasticity)==1.,
                *($((:(($(get_jump_expression_for_commodity_consumer_price(m, jm, pf, input.commodity))/($(get_commodity_benchmark(input.commodity))*$(input.price))) ^ $(Θ(pf, input))) for input in pf.inputs)...)) * $(y_over_y_bar(jm, pf)),
                (+($((:($(Θ(pf, input)) * ($(get_jump_expression_for_commodity_consumer_price(m, jm, pf, input.commodity))/($(get_commodity_benchmark(input.commodity))*$(input.price))) ^ (1-$(pf.elasticity))) for input in pf.inputs)...)))^(1/(1-$(pf.elasticity))) * $(y_over_y_bar(jm, pf))
            )
        )
    else # This branch is an optimization: if the elasticity doesn't contain a parameter, we can at build time only insert one case into the expression
        if eval(swap_our_param_with_val(pf.elasticity))==1
            return :(
                *(
                    $(
                        (:(
                            ($(get_jump_expression_for_commodity_consumer_price(m, jm, pf, input.commodity))/($(get_commodity_benchmark(input.commodity))*$(input.price))) ^ $(Θ(pf, input))
                        ) for input in pf.inputs)...
                    )
                ) * $(y_over_y_bar(jm, pf))
            )
        else 
            return :(
                (+(
                    $(
                        (:(
                            $(Θ(pf, input)) * ($(get_jump_expression_for_commodity_consumer_price(m, jm, pf, input.commodity))/($(get_commodity_benchmark(input.commodity))*$(input.price))) ^ (1-$(pf.elasticity))  
                        ) for input in pf.inputs)...
                    )
                ))^(1/(1-$(pf.elasticity))) * $(y_over_y_bar(jm, pf))
            )
        end
    end
end

function create_rev_expr(m, jm, pf::Production)
    return :(
        (
            +(
                $(
                    (
                        :(
                            $(Θ(pf, output)) *
                            ($(get_jump_expression_for_commodity_producer_price(m, jm, pf, output.commodity))/($(get_commodity_benchmark(output.commodity))*$(output.price)))^(1.0 + $(pf.tr_elasticity))
                        ) for output in pf.outputs
                    )...
                )
            )
        )^(1.0/(1.0+$(pf.tr_elasticity)))
    )
end

function u_over_u_bar(jm, dm::DemandFunction)
    if contains_our_param(dm.elasticity)
        ρ = :(($(dm.elasticity)-1)/$(dm.elasticity))

        return :(
            ifelse(
                $(dm.elasticity)==0.0,
                min($(( :( $(jm[get_final_demand_name(d)])/$(d.quantity) ) for d in dm.demands)...)),
                ifelse(
                    $(dm.elasticity)==1.,
                    *($(( :( ($(jm[get_final_demand_name(d)])/$(d.quantity))^$(Θ(dm,d)) ) for d in dm.demands)...)),
                    # TODO #71 Figure out why the commented version doesn't work, it matches paper
                    # (+($((:( $(Θ(dm,d)) * ($(jm[get_final_demand_name(d)])/$(d.quantity))^$ρ ) for d in dm.demands)...)))^(1/$ρ)
                    (+($((:( $(Θ(dm,d)) * ($(d.quantity)/$(d.quantity))^$ρ ) for d in dm.demands)...)))^(1/$ρ)
                )
            )
        )
    else # This branch is an optimization: if the elasticity doesn't contain a parameter, we can at build time only insert one case into the expression
        if eval(swap_our_param_with_val(dm.elasticity))==0
            return :(
                min(
                    $(( :( $(jm[get_final_demand_name(d)])/$(d.quantity) ) for d in dm.demands)...)
                )
            )
        elseif eval(swap_our_param_with_val(dm.elasticity))==1
            return :(
                *(
                    $(( :( ($(jm[get_final_demand_name(d)])/$(d.quantity))^$(Θ(dm,d)) ) for d in dm.demands)...)
                )
            )
        else
            ρ = :(($(dm.elasticity)-1)/$(dm.elasticity))
            return :(
                (
                    +(
                        # TODO #71 Figure out why the commented version doesn't work, it matches paper
                        # $((:( $(Θ(dm,d)) * ($(jm[get_final_demand_name(d)])/$(d.quantity))^$ρ ) for d in dm.demands)...)
                        $((:( $(Θ(dm,d)) * ($(d.quantity)/$(d.quantity))^$ρ ) for d in dm.demands)...)
                    )
                )^(1/$ρ)
            )
        end
    end
end

function create_expenditure_expr(jm, df::DemandFunction)
    return :(
        (
            +(
                $(
                    (
                        :(
                            $(Θ(df, dm)) *
                            (
                                $(get_jump_variable_for_commodity(jm, dm.commodity)) /
                                $(get_commodity_benchmark(dm.commodity))
                            )^(1-$(df.elasticity))
                        ) for dm in df.demands
                    )...
                )
            )
        )^(1/(1-$(df.elasticity))) *
        $(u_over_u_bar(jm, df))
    )
end

function build_implicitconstraints!(m, jm)
    # Add compensated demand (intermediate and factor)
    for s in m._productions
        for input in s.inputs

            ex = :(
                JuMP.@NLexpression(
                    $(jm),
                    $(input.quantity) *
                    $(y_over_y_bar(jm, s)) *
                 (       
                            $(create_cost_expr(m, jm, s)) * $(get_commodity_benchmark(input.commodity))*$(input.price) /
                            $(get_jump_expression_for_commodity_consumer_price(m, jm, s, input.commodity))
                )^$(s.elasticity) - 
                        $(jm[get_comp_demand_name(input)])
                )
            )

            exb = eval( swap_our_param_with_jump_param(jm, ex) )

            Complementarity.add_complementarity(jm, jm[get_comp_demand_name(input)], exb, string("F_", get_comp_demand_name(input)))    
            push!(m._nlexpressions, exb)
        end
    end

    # Add compensated supply
    for s in m._productions
        for output in s.outputs
            ex = :(
                JuMP.@NLexpression(
                    $(jm),
                    $(output.quantity) *
                    $(y_over_y_bar(jm, s)) *
                        (
                            $(get_jump_expression_for_commodity_producer_price(m, jm, s, output.commodity))/
                            ( $(create_rev_expr(m, jm, s)) *
                            $(get_commodity_benchmark(output.commodity))*$(output.price))
                        )^$(s.tr_elasticity) -
                        $(jm[get_comp_supply_name(output)])
                )
            )

            exb = eval( swap_our_param_with_jump_param(jm, ex) )

            Complementarity.add_complementarity(jm, jm[get_comp_supply_name(output)], exb, string("F_", get_comp_supply_name(output)))
            push!(m._nlexpressions, exb)
        end
    end

    # Add final demand
    for demand_function in m._demands
        if eval(swap_our_param_with_val(demand_function.elasticity))==0
            for demand in demand_function.demands
                ex = :(
            JuMP.@NLexpression(
                $(jm),
                $(demand.quantity) * 
                ($(get_jump_variable_for_consumer(jm, demand_function.consumer)) # (consumer's) income
                /$(get_consumer_benchmark(demand_function.consumer))) # benchmark income (?)
                *
                (       +($( (:($(Θ(demand_function, demand))*$(get_commodity_benchmark(demand.commodity)) ) for demand in demand_function.demands)...))  # sum(demand theta * p__bar_j)?
                   /
                        +($( (:($(Θ(demand_function, demand))*$(get_jump_variable_for_commodity(jm, demand.commodity))) for demand in demand_function.demands)...) ))# sum(demand theta * p_bar
                        - 
                    $(jm[get_final_demand_name(demand)])
                )
            )
            exb = eval( swap_our_param_with_jump_param(jm, ex) )

            Complementarity.add_complementarity(jm, jm[get_final_demand_name(demand)], exb, string("F_", get_final_demand_name(demand)))
            push!(m._nlexpressions, exb)
            end
        else
            for demand in demand_function.demands
                ex = :(
                    JuMP.@NLexpression(
                        $(jm),
                        $(demand.quantity) * 
                        (
                            $(get_jump_variable_for_consumer(jm, demand_function.consumer)) / # (consumer's) income
                            $(get_consumer_benchmark(demand_function.consumer)) # benchmark income (?)
                        ) *
                        (
                            $(create_expenditure_expr(jm, demand_function))
                        )^($(demand_function.elasticity)-1) *
                        (
                            $(get_commodity_benchmark(demand.commodity)) / # p__bar_i
                            $(get_jump_variable_for_commodity(jm, demand.commodity))
                        )^$(demand_function.elasticity) - # p_i
                        $(jm[get_final_demand_name(demand)])
                    )
                )
                exb = eval( swap_our_param_with_jump_param(jm, ex) )

                Complementarity.add_complementarity(jm, jm[get_final_demand_name(demand)], exb, string("F_", get_final_demand_name(demand)))
                push!(m._nlexpressions, exb)
            end
        end
    end
end
