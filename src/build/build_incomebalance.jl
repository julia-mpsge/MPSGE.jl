function build_incomebalance!(m, jm)
    # Add income balance constraints
    for c in m._demands
        ex = :(
                +($((:($(en.quantity) * 
                $(en.commodity)) for en in c.endowments)...)) 
                +  $(get_tax_revenue_for_consumer(jm, m, c.consumer)) 
                -
                $(c.consumer)
        )

        jump_ex = convert_mpsge_expr_to_jump_nonlinearexpr(jm, ex)
        jump_var = get_jump_variable_for_consumer(jm, c.consumer)

        @constraint(jm, jump_ex ⟂ jump_var)
        push!(m._nlexpressions.income_balance, (expr=jump_ex, var=jump_var))
    end
end
