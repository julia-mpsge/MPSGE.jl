function build(m::Model)
    jm = Complementarity.MCPModel()

    # Add all required variables

    for s in m._sectors
        add_variable!(jm, s.name, 0.)

        Complementarity.set_start_value(jm[s.name], s.benchmark)
    end

    for c in m._commodities
        add_variable!(jm, c.name, 0.001)

        Complementarity.set_start_value(jm[c.name], c.benchmark)
    end

    for s in m._productions
        for i in s.inputs
            compensated_input1_demand_name = Symbol("$(i.commodity)$(s.output)")
            add_variable!(jm, compensated_input1_demand_name)

            Complementarity.set_start_value(jm[compensated_input1_demand_name], i.quantity)
        end
    end

    for c in m._consumsers
        add_variable!(jm, c.name)

        Complementarity.set_start_value(jm[c.name], c.benchmark)
    end

    # Add compensated demand equations
    for s in m._productions
        compensated_input1_demand_name = Symbol("$(s.inputs[1].commodity)$(s.output)")
        compensated_input2_demand_name = Symbol("$(s.inputs[2].commodity)$(s.output)")
        price_input1_name = s.inputs[1].commodity
        price_input2_name = s.inputs[2].commodity

        exp_1 = s.inputs[1].quantity/s.output_quantity
        exp_2 = s.inputs[2].quantity/s.output_quantity

        ex1 = JuMP.@NLexpression(jm,
            s.inputs[1].quantity * ( 
                jm[price_input1_name]^exp_1 * jm[price_input2_name]^exp_2
            ) / jm[price_input1_name] - jm[compensated_input1_demand_name]
        )

        Complementarity.add_complementarity(jm, jm[compensated_input1_demand_name], ex1, string("F_", compensated_input1_demand_name))

        ex2 = JuMP.@NLexpression(jm,
            s.inputs[2].quantity * ( 
                jm[price_input1_name]^exp_1 * jm[price_input2_name]^exp_2
            ) / jm[price_input2_name] - jm[compensated_input2_demand_name]
        )

        Complementarity.add_complementarity(jm, jm[compensated_input2_demand_name], ex2, string("F_", compensated_input2_demand_name))
    end

    # Add zero profit constraints
    for s in m._productions
        price_name = s.output
        input1_price_name = s.inputs[1].commodity
        input2_price_name = s.inputs[2].commodity
        compensated_input1_demand_name = Symbol("$(s.inputs[1].commodity)$(s.output)")
        compensated_input2_demand_name = Symbol("$(s.inputs[2].commodity)$(s.output)")

        ex3 = JuMP.@NLexpression(jm, jm[input1_price_name]*jm[compensated_input1_demand_name] + jm[input2_price_name]*jm[compensated_input2_demand_name] - s.output_quantity * jm[price_name])

        Complementarity.add_complementarity(jm, jm[s.sector], ex3, string("F_", s.sector))
    end

    # Add market clearance constraints

    for s in m._productions
        level_name = s.sector
        price_name = s.output

        # Find all the sectors where our current sector is an input
        input_into_sectors = [(s2.output, s2.sector) for s2 in m._productions if s2.inputs[1].commodity==s.output || s2.inputs[2].commodity==s.output]
        input_into_consumers = [c.consumer for c in m._demands if c.commodity==s.output]

        ex4 = @eval(
            JuMP.@NLexpression(
                $jm,
                $(length(input_into_sectors)==0 ? 0. : 
                    :(+($((:($(jm[Symbol("$(s.output)$i")]) * $(jm[Symbol(ii)])) for (i,ii) in input_into_sectors)...)))
                ) +
                $(length(input_into_consumers)==0 ? 0. : 
                    :(+($((:($(jm[Symbol(i)]) / $(jm[Symbol("$(s.output)")])) for i in input_into_consumers)...)))
                ) -
                $(s.output_quantity) * $(jm[level_name])
            )
        )
        Complementarity.add_complementarity(jm, jm[price_name], ex4, string("F_", price_name))
    end

    # Loop over all endowments
    endows = Dict{Symbol, Float64}()

    for c in m._demands
        for en in c.endowments
            if !haskey(endows, en.commodity)
                endows[en.commodity] = 0.
            end
            endows[en.commodity] += en.quantity
        end
    end

    for (level_name, endowment_level) in endows
        price_name = level_name
        # Find all the sectors where our current sector is an input
        input_into_sectors = [(s.output, s.sector) for s in m._productions if s.inputs[1].commodity==level_name || s.inputs[2].commodity==level_name]
        input_into_consumers = [c.name for c in m._demands if c.commodity==level_name]

        ex5 = @eval(
            JuMP.@NLexpression(
                $jm,
                $(length(input_into_sectors)==0 ? 0. : 
                    :(+($((:($(jm[Symbol("$(level_name)$i")]) * $(jm[Symbol(ii)])) for (i,ii) in input_into_sectors)...)))
                ) +
                $(length(input_into_consumers)==0 ? 0. : 
                    :(+($((:($(jm[Symbol(i)]) / $(jm[Symbol("$(level_name)")])) for i in input_into_consumers)...)))
                ) -
                $(endowment_level)
            )
        )
        Complementarity.add_complementarity(jm, jm[price_name], ex5, string("F_", price_name))
    end

    # Add income balance constraints
    for c in m._demands
        level_name = c.consumer

        ex6 = @eval(
            JuMP.@NLexpression(
                $jm,
                +($((:($(en.quantity) * $(jm[Symbol("$(en.commodity)")])) for en in c.endowments)...)) - $(jm[level_name])
            )
        )
        Complementarity.add_complementarity(jm, jm[level_name], ex6, string("F_", level_name))
    end

    return jm
end
