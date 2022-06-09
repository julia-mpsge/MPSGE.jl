function Θ(pf::Production, i)
    return :( $(i.quantity) * $(get_commodity_benchmark(i.commodity)) / +($( (:( $(o.quantity) * $(get_commodity_benchmark(o.commodity)) ) for o in pf.outputs)...) ) )
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
            )
        )
    else 
        return :(
            (+(
                $(
                    (:(
                        $(Θ(pf, input)) * ($(get_jump_variable_for_commodity(jm,input.commodity))/$(get_commodity_benchmark(input.commodity))) ^ (1-$(pf.elasticity))
                    ) for input in pf.inputs)...
                )
            ))^(1/(1-$(pf.elasticity)))
        )
    end
end

function create_rev_expr(jm, pf::Production)
    temp1 = :(
        +(
            $(
                (output.quantity for output in pf.outputs)...
            )
        )
    )

    return :(
        (
            +(
                $(
                    (
                        :(
                            $(output.quantity) * 
                            $(get_jump_variable_for_commodity(jm,output.commodity))^(1.0 + $(pf.tr_elasticity)) /
                            $temp1
                        ) for output in pf.outputs
                    )...
                )
            )
        )^(1.0/(1.0+$(pf.tr_elasticity)))
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
                        (
                            $(get_jump_variable_for_commodity(jm, output.commodity)) /
                            $(create_rev_expr(jm, s))
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
        temp1 = :(
            +(
                $(
                    (demand.quantity for demand in demand_function.demands)...
                )
            )
        )
        for demand in demand_function.demands
            ex = :(
                JuMP.@NLexpression(
                    $(jm),
                        $(demand.quantity) /
                        $temp1 *
                        $(get_jump_variable_for_consumer(jm, demand_function.consumer)) /
                        $(get_jump_variable_for_commodity(jm, demand.commodity)) - 
                        $(jm[get_final_demand_name(demand)])
                )
            )

            exb = eval( swap_our_param_with_jump_param(jm, ex) )

            Complementarity.add_complementarity(jm, jm[get_final_demand_name(demand)], exb, string("F_", get_final_demand_name(demand)))
            push!(m._nlexpressions, exb)
        end
    end
end
