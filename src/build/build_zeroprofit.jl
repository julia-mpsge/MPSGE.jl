function build_zeroprofit!(m, jm)

    # Add zero profit constraints
    for s in m._productions
        ex = :(
                +(
                    $(
                        (:(
                            $(get_expression_for_commodity_consumer_price(s, input.commodity)) * $(m._implicitvarsDict[get_comp_demand_name(input)]) 
                        ) for input in s.inputs)...
                )
                ) -
                +(
                    $(
                        (:(
                            $(get_expression_for_commodity_producer_price(s, output.commodity)) * $(m._implicitvarsDict[get_comp_supply_name(output)])
                        ) for output in s.outputs)...
                    )
                )
        )

        jump_ex = convert_mpsge_expr_to_jump_nonlinearexpr(jm, ex)
        jump_var = get_jump_variable_for_sector(jm, s.sector)

        @constraint(jm, jump_ex ⟂ jump_var)
        push!(m._nlexpressions.zero_profit, (expr=jump_ex, var=jump_var))
    end
end
