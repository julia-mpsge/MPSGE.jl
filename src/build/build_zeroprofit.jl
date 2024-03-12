function build_zeroprofit!(m, jm)

    # Add zero profit constraints
    jump_ex = Dict()
    jump_var = Dict()
    jump_var_ind = []
    for s in m._productions
        s_name = Symbol(get_jump_variable_for_sector(jm, s.sector))
            push!(jump_ex, s_name =>
  +(
            (
                    get_expression_for_commodity_consumer_price(jm, s, input.commodity) * (jm[get_comp_demand_name(input)]) for input in s.inputs
                )...
            ) -
            +(
                (
                    get_expression_for_commodity_producer_price(jm, s, output.commodity) * (jm[get_comp_supply_name(output)]) for output in s.outputs
                )...
            )
            )
        push!(jump_var_ind, s_name)
        push!(jump_var, s_name => get_jump_variable_for_sector(jm, s.sector))
        push!(m._nlexpressions.zero_profit, (expr=jump_ex[s_name], var=jump_var[s_name]))
    end
     @constraint(jm, zero_profit[s=jump_var_ind], jump_ex[s] ⟂ jump_var[s])
end
