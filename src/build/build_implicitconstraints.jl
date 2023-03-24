function Θ(pf::Production, i::Input)
    return :( $(i.quantity) * $(get_commodity_benchmark(i.commodity)) / +($( (:( $(i.quantity) * $(get_commodity_benchmark(i.commodity)) ) for i in pf.inputs)...) ) )
end

function Θ(pf::Production, o::Output)
    return :( $(o.quantity) * $(get_commodity_benchmark(o.commodity)) / +($( (:( $(o.quantity) * $(get_commodity_benchmark(o.commodity)) ) for o in pf.outputs)...) ) )
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

function create_cost_expr(jm, pf::Production)
    if contains_our_param(pf.elasticity)
        return :(
            ifelse(
                $(pf.elasticity)==1.,
                *($((:(($(get_jump_variable_for_commodity(jm,input.commodity))/$(get_commodity_benchmark(input.commodity))) ^ $(Θ(pf, input))) for input in pf.inputs)...)) * $(y_over_y_bar(jm, pf)),
                (+($((:($(Θ(pf, input)) * ($(get_jump_variable_for_commodity(jm,input.commodity))/$(get_commodity_benchmark(input.commodity))) ^ (1-$(pf.elasticity))) for input in pf.inputs)...)))^(1/(1-$(pf.elasticity))) * $(y_over_y_bar(jm, pf))
            )
        )
    else # This branch is an optimization: if the elasticity doesn't contain a parameter, we can at build time only insert one case into the expression
        if eval(swap_our_param_with_val(pf.elasticity))==1
            return :(
                *(
                    $(
                        (:(
                            ($(get_jump_variable_for_commodity(jm,input.commodity))/$(get_commodity_benchmark(input.commodity))) ^ $(Θ(pf, input))
                        ) for input in pf.inputs)...
                    )
                ) * $(y_over_y_bar(jm, pf))
            )
        else 
            return :(
                (+(
                    $(
                        (:(
                            $(Θ(pf, input)) * ($(get_jump_variable_for_commodity(jm,input.commodity))/$(get_commodity_benchmark(input.commodity))) ^ (1-$(pf.elasticity))
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
                            ($(get_jump_expression_for_commodity_producer_price(m, jm, pf, output.commodity))/$(get_commodity_benchmark(output.commodity)))^(1.0 + $(pf.tr_elasticity))
                        ) for output in pf.outputs
                    )...
                )
            )
        )^(1.0/(1.0+$(pf.tr_elasticity)))
    )
end

function create_utility_expr(jm, dm::DemandFunction)
    return :( 
        (
            +(
                $(
                    (
                        :(
                            $( Θ(dm, demand) ) *
                            # TODO #71 Figure out why the commented version doesn't work, it matches paper
                            # (
                            #     $(jm[get_final_demand_name(demand)]) / $(demand.quantity)
                            # )^(
                            #     ($(dm.elasticity)-1)/$(dm.elasticity)
                            # )
                            ($(demand.quantity)/$(demand.quantity))^(($(dm.elasticity)-1)/$(dm.elasticity))
                        ) for demand in dm.demands
                    )...
                )
            )
        )^(
            1 / 
            (
                ($(dm.elasticity)-1) / 
                $(dm.elasticity)
            )
        )
    )
end

function create_expenditure_expr(jm, dm::DemandFunction)
    return :( 
        (
            +(
                $(
                    (
                        :(
                            $(Θ(dm, demand)) *
                            (
                                $(get_jump_variable_for_commodity(jm, demand.commodity)) /
                                $(get_commodity_benchmark(demand.commodity))
                            )^(1-$(dm.elasticity))
                        ) for demand in dm.demands
                    )...
                )
            )
       )^(1/(1-$(dm.elasticity))) *
       $(create_utility_expr(jm, dm))
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
                            $(create_cost_expr(jm, s)) * $(get_commodity_benchmark(input.commodity)) /
                        $(get_jump_variable_for_commodity(jm, input.commodity))
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
                            $(get_jump_variable_for_commodity(jm, output.commodity)) /
                            ( $(create_rev_expr(m, jm, s)) *
                            $(get_commodity_benchmark(output.commodity)))
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
        if eval(swap_our_param_with_val(demand_function.elasticity))==1
            for demand in demand_function.demands
                ex = :(
                    JuMP.@NLexpression(
                        $(jm),
                        $(demand.quantity) * 
                        ($(get_jump_variable_for_consumer(jm, demand_function.consumer)) / # (consumer's) income
                        $(swap_our_param_with_jump_param(jm, get_consumer_benchmark(demand_function.consumer)))) * # benchmark income (?)
                        (
                            $(get_commodity_benchmark(demand.commodity)) / # p__bar_i?
                            $(get_jump_variable_for_commodity(jm, demand.commodity))
                        ) - #p_bar
                        $(jm[get_final_demand_name(demand)])
                    )
                )
                exb = eval( swap_our_param_with_jump_param(jm, ex) )

                Complementarity.add_complementarity(jm, jm[get_final_demand_name(demand)], exb, string("F_", get_final_demand_name(demand)))
                push!(m._nlexpressions, exb)
            end
        elseif eval(swap_our_param_with_val(demand_function.elasticity))==0
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
