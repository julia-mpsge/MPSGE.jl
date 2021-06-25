function build_zeroprofit!(m, jm)

    # Add zero profit constraints
    for s in m._productions
        # TODO Remove all s.outputs[1] and make general
        compensated_input1_demand_name = get_comp_demand_name(s.inputs[1])
        compensated_input2_demand_name = get_comp_demand_name(s.inputs[2])

        ex3a = :(
            JuMP.@NLexpression(
                $jm,
                $(get_jump_variable_for_commodity(jm, s.inputs[1].commodity))*$(jm[compensated_input1_demand_name]) + $(get_jump_variable_for_commodity(jm, s.inputs[2].commodity))*
        $(jm[compensated_input2_demand_name]) - $(s.outputs[1].quantity) * $(get_jump_variable_for_commodity(jm, s.outputs[1].commodity))
            )
        )

        ex3b = eval(swap_our_param_with_jump_param(ex3a))

        Complementarity.add_complementarity(jm, get_jump_variable_for_sector(jm, s.sector), ex3b, string("F_", get_name(s.sector), s.sector.subindex!==nothing ? s.sector.subindex : ""))
    end
end
