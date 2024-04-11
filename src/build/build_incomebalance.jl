function build_incomebalance!(m, jm)
    # Add income balance constraints
    jump_ex = Dict()
    jump_var = Dict()
    jump_var_ind = []
    for c in m._demands
        c_name = Symbol(get_jump_variable_for_consumer(jm, c.consumer))
        push!(jump_var_ind, c_name)
        push!(jump_var, c_name => get_jump_variable_for_consumer(jm, c.consumer))
        push!(jump_ex, c_name =>
           +(
                (tojump(jm, en.quantity) * tojump(jm, en.commodity) for en in c.endowments)...
            ) +
            get_tax_revenue_for_consumer(jm, m, c.consumer) -
            tojump(jm, c.consumer)
        )
        push!(m._nlexpressions.income_balance, (expr=jump_ex[c_name], var=jump_var[c_name]))
    end
    @constraint(jm, inc_blnc[c=jump_var_ind], jump_ex[c] ⟂ jump_var[c])
end
