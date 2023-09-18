function build_incomebalance!(m, jm)
    # Add income balance constraints
    for c in m._demands
        jump_ex = (
                +((((tojump(jm, en.quantity) * 
                tojump(jm, en.commodity)) for en in c.endowments)...)) 
                +  (get_tax_revenue_for_consumer(jm, m, c.consumer)) 
                -
                tojump(jm, c.consumer)
        )

        jump_var = get_jump_variable_for_consumer(jm, c.consumer)

        @constraint(jm, jump_ex ⟂ jump_var)
        push!(m._nlexpressions.income_balance, (expr=jump_ex, var=jump_var))
    end
end
