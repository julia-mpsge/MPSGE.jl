function Θ(pf::Production, i)
    return :( $(i.quantity) * $(get_commodity_benchmark(i.commodity)) / +($( (:( $(o.quantity) * $(get_commodity_benchmark(o.commodity)) ) for o in pf.outputs)...) ) )
end

function y_over_y_bar(jm, pf::Production)
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

function create_cost_expr(jm, pf::Production)

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

function create_rev_expr(jm, pf::Production)
    return :(
        (
            +(
                $(
                    (
                        :(
                            $(Θ(pf, output)) *
                            ($(get_jump_variable_for_commodity(jm,output.commodity))/$(get_commodity_benchmark(output.commodity)))^(1.0 + $(pf.tr_elasticity))
                        ) for output in pf.outputs
                    )...
                )
            )
        )^(1.0/(1.0+$(pf.tr_elasticity)))
    )
end

function create_expenditure_expr(jm, dm::DemandFunction)
    Θ(d) = :( $(d.quantity) * $(get_commodity_benchmark(d.commodity)) / +($( (:( $(get_commodity_benchmark(e.commodity)) ) for e in dm.endowments)...) ) )

    temp1 = :(
        +(
            $(
                (demand.quantity for demand in dm.demands)...
            )
        )
    )
    if eval(swap_our_param_with_val(dm.elasticity))==1
        return :(
            *(
                $(
                    (:(
                        # $(get_jump_variable_for_consumer(jm,dm.consumer)) ^ ($(demand.quantity)/$temp1)
                    $(get_jump_variable_for_consumer(jm,dm.consumer))/$(get_consumer_benchmark(dm.consumer)) ^ ($(Θ(demand)))
                    ) for demand in dm.demands)...
                )
            )
        )
    else 
        return :(
            (#(
                $(
                    (:(
                        ($(demand.quantity)/$temp1) * $(get_jump_variable_for_consumer(jm,dm.consumer)) ^ (1-$(dm.elasticity))
                    )# for demand in dm.demands)...
                )
            ))^(1/(1-$(dm.elasticity)))
        )
    end
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
                            $(create_rev_expr(jm, s)) /
                            $(get_commodity_benchmark(output.commodity))
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
    # temp1 = :(
    #             +(
    #                 $(
    #                     (demand.quantity for demand in demand_function.demands)...
    #                 )
    #             )
    #         )            
        if eval(swap_our_param_with_val(demand_function.elasticity))==1
            for demand in demand_function.demands
                ex = :(
            JuMP.@NLexpression(
                $(jm),
                (
                $(demand.quantity)* #^$(demand_function.elasticity) *
                    (
                        $(create_expenditure_expr(jm, demand_function))) * $(get_commodity_benchmark(demand.commodity))#^$(demand_function.elasticity)
                #    )^$(demand_function.elasticity) 
                   /
                        # ($(demand.quantity)/$temp1) * $(get_jump_variable_for_consumer(jm,demand_function.consumer)) ^ (1-$(demand_function.elasticity)))/
                    $(get_jump_variable_for_commodity(jm, demand.commodity))
                    )^$(demand_function.elasticity)
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
                    $(demand.quantity)^$(demand_function.elasticity) *
                        (
                            # $(create_expenditure_expr(jm, demand_function)))^$(demand_function.elasticity) /
                            ($(demand.quantity)/$temp1) * $(get_jump_variable_for_consumer(jm,demand_function.consumer)) ^ (1-$(demand_function.elasticity)))/
                        $(get_jump_variable_for_commodity(jm, demand.commodity))
                            - 
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
