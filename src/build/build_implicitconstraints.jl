function Θ(pf::Production, i::Input)
    return :( $(i.quantity) * $(i.price) * $(get_commodity_benchmark(i.commodity)) / +($( (:( $(i.quantity) * $(i.price) * $(get_commodity_benchmark(i.commodity)) ) for i in pf.inputs)...) ) )
end

function Θ(pf::Production, o::Output)
    return :( $(o.quantity) * $(o.price) * $(get_commodity_benchmark(o.commodity)) / +($( (:( $(o.quantity) * $(o.price) * $(get_commodity_benchmark(o.commodity)) ) for o in pf.outputs)...) ) )
end

function Θ(df::DemandFunction, dm::Demand)   
    return :( $(dm.quantity) * $(dm.price) * $(get_commodity_benchmark(dm.commodity))/ +($( (:( $(d.quantity) * $(d.price) * $(get_commodity_benchmark(d.commodity)) ) for d in df.demands)...) ) )
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
                *($((:(($(get_expression_for_commodity_consumer_price(pf, input.commodity))/($(get_commodity_benchmark(input.commodity))*$(input.price))) ^ $(Θ(pf, input))) for input in pf.inputs)...)) * $(y_over_y_bar(jm, pf)),
                (+($((:($(Θ(pf, input)) * ($(get_expression_for_commodity_consumer_price(pf, input.commodity))/($(get_commodity_benchmark(input.commodity))*$(input.price))) ^ (1-$(pf.elasticity))) for input in pf.inputs)...)))^(1/(1-$(pf.elasticity))) * $(y_over_y_bar(jm, pf))
            )
        )
    else # This branch is an optimization: if the elasticity doesn't contain a parameter, we can at build time only insert one case into the expression
        if eval(swap_our_param_with_val(pf.elasticity))==1
            return :(
                *(
                    $(
                        (:(
                            ($(get_expression_for_commodity_consumer_price(pf, input.commodity))/($(get_commodity_benchmark(input.commodity))*$(input.price))) ^ $(Θ(pf, input))
                        ) for input in pf.inputs)...
                    )
                ) * $(y_over_y_bar(jm, pf))
            )
        else 
            return :(
                (+(
                    $(
                        (:(
                            $(Θ(pf, input)) * ($(get_expression_for_commodity_consumer_price(pf, input.commodity))/($(get_commodity_benchmark(input.commodity))*$(input.price))) ^ (1-$(pf.elasticity))  
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
                            ($(get_expression_for_commodity_producer_price(pf, output.commodity))/($(get_commodity_benchmark(output.commodity))*$(output.price)))^(1.0 + $(pf.tr_elasticity))
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
                    # TODO #71 Figure out why the commented version doesn't work, it matches paper
                    # (+($((:( $(Θ(dm,d)) * ($(jm[get_final_demand_name(d)])/$(d.quantity))^$ρ ) for d in dm.demands)...)))^(1/$ρ)
                    (+($((:( $(Θ(dm,d)) * ($(d.quantity)/$(d.quantity))^$ρ ) for d in dm.demands)...)))^(1/$ρ)
                )
    else # This branch is an optimization: if the elasticity doesn't contain a parameter, we can at build time only insert one case into the expression
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

function create_expenditure_expr(jm, df::DemandFunction)
    return :(
        (
            +(
                $(
                    (
                        :(
                            $(Θ(df, dm)) *
                            (
                                $(dm.commodity) /
                                ($(get_commodity_benchmark(dm.commodity)) * $(dm.price))
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
                    $(input.quantity) *
                    $(y_over_y_bar(jm, s)) *
                 (       
                            $(create_cost_expr(m, jm, s)) * $(get_commodity_benchmark(input.commodity))*$(input.price) /
                            $(get_expression_for_commodity_consumer_price(s, input.commodity))
                )^$(s.elasticity) - 
                        $(m._implicitvarsDict[get_comp_demand_name(input)])
            )

            exb = JuMP.NonlinearExpr(swap_our_Ref_with_jump_var(jm, ex))

            var = jm[get_comp_demand_name(input)]

            @constraint(jm, exb ⟂ var)

            push!(m._nlexpressions, exb)
        end
    end

    # Add compensated supply
    for s in m._productions
        for output in s.outputs
            ex = :(
                    $(output.quantity) *
                    $(y_over_y_bar(jm, s)) *
                        (
                            $(get_expression_for_commodity_producer_price(s, output.commodity))/
                            ( $(create_rev_expr(m, jm, s)) *
                            $(get_commodity_benchmark(output.commodity))*$(output.price))
                        )^$(s.tr_elasticity) -
                        $(m._implicitvarsDict[get_comp_supply_name(output)])
                
            )

            exb = JuMP.NonlinearExpr( swap_our_Ref_with_jump_var(jm, ex) )
            var = jm[get_comp_supply_name(output)]

            @constraint(jm, exb ⟂ var)
            push!(m._nlexpressions, exb)
        end
    end

    # Add final demand
    for demand_function in m._demands
            for demand in demand_function.demands
                ex = :(
                        $(demand.quantity) * 
                        (
                            $(demand_function.consumer) / # (consumer's) income
                            (+($( (:( $(d.quantity) * $(d.price) * $(get_commodity_benchmark(d.commodity)) ) for d in demand_function.demands)...) )) # benchmark income (?)
                        ) *
                        (
                            $(create_expenditure_expr(jm, demand_function))
                        )^($(demand_function.elasticity)-1) *
                        (
                            $(get_commodity_benchmark(demand.commodity)) * $(demand.price) / # p__bar_i
                            $(demand.commodity)
                        )^$(demand_function.elasticity) - # p_i
                        $(m._implicitvarsDict[get_final_demand_name(demand)])
                )
                exb = JuMP.NonlinearExpr(swap_our_Ref_with_jump_var(jm, ex))

                var = jm[get_final_demand_name(demand)]

                @constraint(jm, exb ⟂ var)
                push!(m._nlexpressions, exb)
            end
    end
end
