function build_incomebalance!(m, jm)
    # Add income balance constraints
    for c in m._demands
        level_name = get_name(c.consumer)

        ex6a = :(
            JuMP.@NLexpression(
                $jm,
                +($((:($(swap_our_param_with_jump_param(en.quantity)) * 
                $(get_jump_variable_for_commodity(jm, en.commodity))) for en in c.endowments)...)) -
                $(jm[level_name])
            )
        )

        ex6b = eval(swap_our_param_with_jump_param(ex6a))
        Complementarity.add_complementarity(jm, jm[level_name], ex6b, string("F_", level_name))
        push!(m._nlexpressions, ex6b)
    end
end
