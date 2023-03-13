function build_incomebalance!(m, jm)
    # Add income balance constraints
    for c in m._demands
        ex6a = :(
            JuMP.@NLexpression(
                $jm,
                +($((:($(swap_our_param_with_jump_param(jm, en.quantity)) * 
                $(get_jump_variable_for_commodity(jm, en.commodity))) for en in c.endowments)...)) 
                +  $(get_tax_revenue_for_consumer(jm, m, c.consumer)) 
                -
                $(get_jump_variable_for_consumer(jm, c.consumer))
            )
        )

        ex6b = eval(swap_our_param_with_jump_param(jm, ex6a))
        Complementarity.add_complementarity(jm, get_jump_variable_for_consumer(jm, c.consumer), ex6b, string("F_", get_name(c.consumer, true)))
        push!(m._nlexpressions, ex6b)
    end
end
