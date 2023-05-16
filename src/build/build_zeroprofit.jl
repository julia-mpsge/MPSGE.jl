function build_zeroprofit!(m, jm)

    # Add zero profit constraints
    for s in m._productions
        exa = :(
            JuMP.@NLexpression(
                $jm,
                +(
                    $(
                        (:(
                            # $(get_jump_expression_for_commodity_consumer_price(m, jm, s, input.commodity)) * $(jm[get_comp_demand_name(input)]) *$(input.price) 
                            $(get_jump_expression_for_commodity_consumer_price(m, jm, s, input.commodity)) * $(jm[get_comp_demand_name(input)]) #*$(input.price) 
                        ) for input in s.inputs)...
                )
                ) -
                +(
                    $(
                        (:(
                            # $(get_jump_expression_for_commodity_producer_price(m, jm, s, output.commodity)) * $(jm[get_comp_supply_name(output)]) *$(output.price)
                            $(get_jump_expression_for_commodity_producer_price(m, jm, s, output.commodity)) * $(jm[get_comp_supply_name(output)]) #*$(output.price)
                        ) for output in s.outputs)...
                    )
                )
            )
        )

        exb = eval(swap_our_param_with_jump_param(jm, exa))

        Complementarity.add_complementarity(jm, get_jump_variable_for_sector(jm, s.sector), exb, string("F_", get_name(s.sector), s.sector.subindex!==nothing ? s.sector.subindex : ""))
        push!(m._nlexpressions, exb)
    end
end
