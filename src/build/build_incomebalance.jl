function build_incomebalance!(m, jm)
    # Add income balance constraints
    for c in m._demands
        ex6a = :(
                +($((:($(en.quantity) * 
                $(en.commodity)) for en in c.endowments)...)) 
                +  $(get_tax_revenue_for_consumer(jm, m, c.consumer)) 
                -
                $(c.consumer)
        )

        ex6b = JuMP.NonlinearExpr(swap_our_Ref_with_jump_var(jm, ex6a))

        var = get_jump_variable_for_consumer(jm, c.consumer)

        @constraint(jm, complements(ex6b, var))

        push!(m._nlexpressions.income_balance, (expr=ex6b, var=var))
    end
end
