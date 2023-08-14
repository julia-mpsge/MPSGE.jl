function build_zeroprofit!(m, jm)

    # Add zero profit constraints
    for s in m._productions
        exa = :(
            JuMP.@NLexpression(
                $jm,
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
        )

        exb = eval(swap_our_Ref_with_jump_var(jm, exa))

        Complementarity.add_complementarity(jm, get_jump_variable_for_sector(jm, s.sector), exb, string("F_", get_name(s.sector), s.sector.subindex!==nothing ? s.sector.subindex : ""))
        push!(m._nlexpressions, exb)
    end
end
