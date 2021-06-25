function build_implicitconstraints!(m, jm)
    for s in m._productions
        # TODO Remove all s.outputs[1] and make general
        compensated_input1_demand_name = get_comp_demand_name(s.inputs[1])
        compensated_input2_demand_name = get_comp_demand_name(s.inputs[2])

        ex1a = :(
            JuMP.@NLexpression(
                $(jm),
                $(s.inputs[1].quantity) * ( 
                    $(get_jump_variable_for_commodity(jm, s.inputs[1].commodity))^($(s.inputs[1].quantity)/$(s.outputs[1].quantity)) *
                    $(get_jump_variable_for_commodity(jm, s.inputs[2].commodity))^($(s.inputs[2].quantity)/$(s.outputs[1].quantity))
                ) / $(get_jump_variable_for_commodity(jm, s.inputs[1].commodity)) - $(jm[compensated_input1_demand_name])
            )
        )

        ex1b = eval( swap_our_param_with_jump_param(ex1a) )

        Complementarity.add_complementarity(jm, jm[compensated_input1_demand_name], ex1b, string("F_", compensated_input1_demand_name))

        ex2a = :(
            JuMP.@NLexpression(
                $jm,
                $(s.inputs[2].quantity) * ( 
                    $(get_jump_variable_for_commodity(jm, s.inputs[1].commodity))^($(s.inputs[1].quantity)/$(s.outputs[1].quantity)) *
                    $(get_jump_variable_for_commodity(jm, s.inputs[2].commodity))^($(s.inputs[2].quantity)/$(s.outputs[1].quantity))
                ) / $(get_jump_variable_for_commodity(jm, s.inputs[2].commodity)) - $(jm[compensated_input2_demand_name])
            )
        )

        ex2b = eval(swap_our_param_with_jump_param(ex2a))

        Complementarity.add_complementarity(jm, jm[compensated_input2_demand_name], ex2b, string("F_", compensated_input2_demand_name))
    end
end
