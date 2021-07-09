function create_cost_expr(jm, pf::Production)
    temp1 = :(
        +(
            $(
                (input.quantity for input in pf.inputs)...
            )
        )
    )

    return :(
        *(
            $(
                (:(
                    $(get_jump_variable_for_commodity(jm,input.commodity)) ^ ($(input.quantity)/$temp1)
                ) for input in pf.inputs)...
            )
        )
    )
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
        sqrt(
            +(
                $(
                    (
                        :(
                            $(output.quantity) * 
                            $(get_jump_variable_for_commodity(jm,output.commodity))^2 /
                            $temp1
                        ) for output in pf.outputs
                    )...
                )
            )
        )        
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
                        $(create_cost_expr(jm, s)) /
                        $(get_jump_variable_for_commodity(jm, input.commodity)) - 
                        $(jm[get_comp_demand_name(input)])
                )
            )

            exb = eval( swap_our_param_with_jump_param(ex) )

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
                        $(get_jump_variable_for_commodity(jm, output.commodity)) /
                        $(create_rev_expr(jm, s)) - 
                        $(jm[get_comp_supply_name(output)])
                )
            )

            exb = eval( swap_our_param_with_jump_param(ex) )

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

            exb = eval( swap_our_param_with_jump_param(ex) )

            Complementarity.add_complementarity(jm, jm[get_final_demand_name(demand)], exb, string("F_", get_final_demand_name(demand)))
            push!(m._nlexpressions, exb)
        end
    end
end
