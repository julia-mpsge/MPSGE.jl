function Θ(pf::Production, i::Input)
    return :( $(i.quantity) * $(i.price) * $(get_commodity_benchmark(i.commodity)) / +($( (:( $(i.quantity) * $(i.price) * $(get_commodity_benchmark(i.commodity)) ) for i in pf.inputs)...) ) )
end

function Θ(pf::Production, o::Output)
    return :( $(o.quantity) * $(o.price) * $(get_commodity_benchmark(o.commodity)) / +($( (:( $(o.quantity) * $(o.price) * $(get_commodity_benchmark(o.commodity)) ) for o in pf.outputs)...) ) )
end

function Θ(jm, df::DemandFunction, dm::Demand)   
    # return :($(dm.quantity) * $(dm.price) * $(get_commodity_benchmark(dm.commodity))/ $(get_consumer_benchmark(df.consumer)))
    # return :( $(dm.quantity) * $(dm.price) / $(get_consumer_benchmark(df.consumer)))
    # return :( $(get_jump_variable_for_commodity(jm, dm.commodity)) * $(dm.price) * $(get_commodity_benchmark(dm.commodity))/ $(get_consumer_benchmark(df.consumer)))
    # return :( $(dm.quantity) * $(get_commodity_benchmark(dm.commodity))/ $(get_consumer_benchmark(df.consumer)))
    return :( $(dm.quantity) * $(dm.price) * $(get_commodity_benchmark(dm.commodity))/ +($( (:( $(demand.quantity) * $(demand.price) * $(get_commodity_benchmark(demand.commodity))) for demand in df.demands)...) ) )
    # return :($(dm.quantity) * $(dm.price) * $(get_commodity_benchmark(dm.commodity))/ +($( (:( $(dm.quantity)  * $(get_commodity_benchmark(dm.commodity))) for dm in df.demands)...) ) )
    # return :( $(dm.price) * $(get_commodity_benchmark(dm.commodity))/ $(get_consumer_benchmark(df.consumer)))

    # return :($(dm.quantity) / $(get_consumer_benchmark(df.consumer)))
    # return :( $(dm.quantity) / +($( (:( $(get_consumer_benchmark(df.consumer)) ) for dm in df.demands)...) ) )
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

function u_over_u_bar(jm, df::DemandFunction)
    if contains_our_param(df.elasticity)
        println("First call")
        ρ = :(($(df.elasticity)-1)/$(df.elasticity))
        ubar = eval(swap_our_param_with_val(:((+($((:( $(Θ(jm,df,d)) * ($(d.quantity)/$(get_commodity_benchmark(d.commodity)))^$ρ ) for d in df.demands)...)))^(1/$ρ))))
println("Ubar=", ubar)
        return :(
            (+($((:( $(Θ(jm,df,d)) * ($(d.quantity)/$(d.quantity))^$ρ ) for d in df.demands)...)))^(1/$ρ)
            # (+($((:( $(Θ(jm,df,d)) * ($(jm[get_final_demand_name(d)])/$(get_commodity_benchmark(d.commodity)))^$ρ ) for d in df.demands)...)))^(1/$ρ)
                    # (+($((:( $(Θ(jm,df,d)) * ($(jm[get_final_demand_name(d)])/$(get_commodity_benchmark(d.commodity)))^$ρ ) for d in df.demands)...)))^(1/$ρ)
                )
    else # This branch is an optimization: if the elasticity doesn't contain a parameter, we can at build time only insert one case into the expression
    println("Second call")
        ρ = :(($(df.elasticity)-1)/$(df.elasticity))
            return :(
                (
                    +(
                        # $((:( $(Θ(jm,df,d)) * ($(d.quantity)/$(get_commodity_benchmark(d.commodity)))^$ρ ) for d in df.demands)...)
                        $((:( $(Θ(jm,df,d)) * ($(jm[get_final_demand_name(d)])/$(get_commodity_benchmark(d.commodity)))^$ρ ) for d in df.demands)...)
                    )
                )^(1/$ρ)
            )
        
    end
end

function create_utility_expr(jm, dm::DemandFunction)
    return :( 
        (
            +(
                $(
                    (
                        :(
                            $( Θ(jm, dm, demand) ) *# $(demand.price) *
                            # TODO #71 Figure out why the commented version doesn't work (for indexed), it matches paper
                            # (

                                # $(jm[get_final_demand_name(demand)]) / $(demand.quantity)
                            # )^(
                            #     ($(dm.elasticity)-1)/$(dm.elasticity)
                            # )
                            # (($(demand.quantity))/($(get_commodity_benchmark(demand.commodity))))^(($(dm.elasticity)-1)/$(dm.elasticity))                            
                            # ($(demand.quantity)/($(get_jump_variable_for_commodity(jm, demand.commodity))*$(demand.price)))^(($(dm.elasticity)-1)/$(dm.elasticity))                            
                            # ($(demand.quantity)/$(get_commodity_benchmark(demand.commodity)))^(($(dm.elasticity)-1)/$(dm.elasticity))                            
                            # ($(jm[get_final_demand_name(demand)])/($(get_commodity_benchmark(demand.commodity))*$(demand.price)))^(($(dm.elasticity)-1)/$(dm.elasticity))                            
                            # ($(jm[get_final_demand_name(demand)])/$(get_commodity_benchmark(demand.commodity)))^(($(dm.elasticity)-1)/$(dm.elasticity))                            
                            # ($(jm[get_final_demand_name(demand)])/($(demand.quantity)))^(($(dm.elasticity)-1)/$(dm.elasticity))
                            # (($(jm[get_final_demand_name(demand)])*$(demand.price))/($(demand.quantity)))^(($(dm.elasticity)-1)/$(dm.elasticity))
                            # (($(jm[get_final_demand_name(demand)])*$(demand.price))/($(demand.quantity)*$(demand.price)))^(($(dm.elasticity)-1)/$(dm.elasticity))
                            # ($(get_jump_variable_for_commodity(jm, demand.commodity))/$(jm[get_final_demand_name(demand)]))^(($(dm.elasticity)-1)/$(dm.elasticity))
                            # ($(jm[get_final_demand_name(demand)])/$(get_jump_variable_for_commodity(jm, demand.commodity)))^(($(dm.elasticity)-1)/$(dm.elasticity))
                            # ($(demand.quantity)/($(demand.quantity)*$(demand.price)))^(($(dm.elasticity)-1)/$(dm.elasticity))
                            # (($(demand.quantity)*$(demand.price))/$(demand.quantity))^(($(dm.elasticity)-1)/$(dm.elasticity))
                            # (($(get_jump_variable_for_commodity(jm, demand.commodity))*$(demand.price))/($(get_commodity_benchmark(demand.commodity))*$(demand.price)))^(($(dm.elasticity)-1)/$(dm.elasticity))
                            # (($(get_jump_variable_for_commodity(jm, demand.commodity))*$(demand.price))/$(get_commodity_benchmark(demand.commodity)))^(($(dm.elasticity)-1)/$(dm.elasticity))
                            # ($(get_jump_variable_for_commodity(jm, demand.commodity))/($(get_commodity_benchmark(demand.commodity))))^(($(dm.elasticity)-1)/$(dm.elasticity))                          

                            # ($(get_commodity_benchmark(demand.commodity))/$(get_commodity_benchmark(demand.commodity)))^(($(dm.elasticity)-1)/$(dm.elasticity))                          
                            # ($(get_jump_variable_for_commodity(jm, demand.commodity))/$(get_jump_variable_for_commodity(jm, demand.commodity)))^(($(dm.elasticity)-1)/$(dm.elasticity))
                            # ($(jm[get_final_demand_name(demand)])/$(jm[get_final_demand_name(demand)])) ^(($(dm.elasticity)-1)/$(dm.elasticity))
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

function create_expenditure_expr(jm, df::DemandFunction)
    return :( 
        (
            +(
                $(
                    (
                        :(
                            $(Θ(jm, df, dm)) *# $(dm.price) *
                            (
                                # $(jm[get_final_demand_name(dm)])/
                                # ($(dm.quantity)) /
                                # ($(dm.quantity)*$(dm.price))/
                                # ($(get_jump_variable_for_commodity(jm, dm.commodity))*$(dm.price)) /
                                # Equivalent of get_jump_expression_for_commodity_consumer_price?
                                # (1.0+$(dm.price)) /
                                $(get_jump_variable_for_commodity(jm, dm.commodity)) /
                                ($(get_commodity_benchmark(dm.commodity))*$(dm.price))#*$(dm.quantity))
                                # $(get_commodity_benchmark(dm.commodity))
                                # ($(dm.quantity)*$(dm.price))

                            )^(1-$(df.elasticity))
                        ) for dm in df.demands
                    )...
                )
            )
       )^(1/(1-$(df.elasticity))) *
        $(create_utility_expr(jm,df))
        #   $(u_over_u_bar(jm, df))
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
        if eval(swap_our_param_with_val(demand_function.elasticity))==1
            println("ONE")
            for demand in demand_function.demands
                ex = :(
                    JuMP.@NLexpression(
                        $(jm),
                        $(demand.quantity) * 
                        ($(get_jump_variable_for_consumer(jm, demand_function.consumer)) / # (consumer's) income
                        $(swap_our_param_with_jump_param(jm, get_consumer_benchmark(demand_function.consumer)))) * # benchmark income (?)
                        (
                            # ($(demand.quantity) * $(demand.price)) / # p__bar_i?
                            # ($(get_commodity_benchmark(demand.commodity)) * $(demand.price)) / # p__bar_i?
                            $(get_commodity_benchmark(demand.commodity)) / # p__bar_i?
                            # $(demand.price)
                            # $(get_jump_variable_for_commodity(jm, demand.commodity))
                            ($(get_jump_variable_for_commodity(jm, demand.commodity))*$(demand.price))
                        ) - #p_bar
                        $(jm[get_final_demand_name(demand)])
                    )
                )
                exb = eval( swap_our_param_with_jump_param(jm, ex) )

                Complementarity.add_complementarity(jm, jm[get_final_demand_name(demand)], exb, string("F_", get_final_demand_name(demand)))
                push!(m._nlexpressions, exb)
            end
        elseif eval(swap_our_param_with_val(demand_function.elasticity))==0
            println("ZERO")
            for demand in demand_function.demands
                ex = :(
            JuMP.@NLexpression(
                $(jm),
                $(demand.quantity) * 
                ($(get_jump_variable_for_consumer(jm, demand_function.consumer)) # (consumer's) income
                /$(get_consumer_benchmark(demand_function.consumer))) # benchmark income (?)
                *
                # (       +($( (:($(Θ(demand_function, demand))*($(get_commodity_benchmark(demand.commodity))*$(demand.price)) ) for demand in demand_function.demands)...))  # sum(demand theta * p__bar_j)?
                (       +($( (:($(Θ(jm, demand_function, demand))*$(get_commodity_benchmark(demand.commodity)) ) for demand in demand_function.demands)...))  # sum(demand theta * p__bar_j)?
                   /
                   +($( (:($(Θ(jm, demand_function, demand))*($(get_jump_variable_for_commodity(jm, demand.commodity))*$(demand.price))) for demand in demand_function.demands)...) ))# sum(demand theta * p_bar
                #    +($( (:($(Θ(demand_function, demand))*$(get_jump_variable_for_commodity(jm, demand.commodity))) for demand in demand_function.demands)...) ))# sum(demand theta * p_bar
                        - 
                    $(jm[get_final_demand_name(demand)])
                )
            )
            exb = eval( swap_our_param_with_jump_param(jm, ex) )

            Complementarity.add_complementarity(jm, jm[get_final_demand_name(demand)], exb, string("F_", get_final_demand_name(demand)))
            push!(m._nlexpressions, exb)
            end
        else
            println("YES!")
            for demand in demand_function.demands
                # println(swap_our_param_with_val(:((
                #     $(create_expenditure_expr(jm, demand_function))
                # ))))
                # println(eval(swap_our_param_with_val(:((
                #     $(create_expenditure_expr(jm, demand_function))
                # )))))
                ex = :(
                    JuMP.@NLexpression(
                        $(jm),
                        # $(get_commodity_benchmark(demand.commodity)) * $(demand.price) *
                        $(demand.quantity) *# $(demand.price) *
                        ($(get_jump_variable_for_consumer(jm, demand_function.consumer)) / # (consumer's) income
                        $(get_consumer_benchmark(demand_function.consumer)) # benchmark income (?)
                        ) * 
                        # 1.000159235
                        (
                            $(create_expenditure_expr(jm, demand_function))* $(demand.price)
                        )^($(demand_function.elasticity)-1) *
                        (
                      
                        # (( $(demand.quantity) * $(demand.price)) )/ # p__bar_i
                            ( ($(get_commodity_benchmark(demand.commodity)) * $(demand.price)) )/ # p__bar_i
                            # $(get_commodity_benchmark(demand.commodity)) / # p__bar_i
                            # (1.0+$(demand.price))
                            # Equivalent of get_jump_expression_for_commodity_consumer_price?
                            $(get_jump_variable_for_commodity(jm, demand.commodity))
                            # ($(get_jump_variable_for_commodity(jm, demand.commodity))*$(demand.price))
                            # ($(demand.quantity)*$(demand.price))
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
