function build_marketclearance!(m, jm)
    # Add market clearance constraints

    for s in m._productions
        # TODO Remove s.outputs[1] and make general
        price_name = get_name(s.outputs[1].commodity, true)

        # Find all the sectors where our current sector is an input
        input_into_sectors = Input[]
        for s2 in m._productions
            for input in s2.inputs
                if input.commodity==s.outputs[1].commodity
                    push!(input_into_sectors, input)
                end
            end
        end

        # Find all the demand functions where our current sector (or rather output) is a demand item
        input_into_consumers = Demand[]
        for demand_function in m._demands
            if demand_function.demands[1].commodity==s.outputs[1].commodity
                push!(input_into_consumers, demand_function.demands[1])
            end
        end

        ex4a = :(
            JuMP.@NLexpression(
                $jm,
                $(length(input_into_sectors)==0 ? 0. : 
                    :(+($((:($(jm[get_comp_demand_name(input)]) * $(get_jump_variable_for_sector(jm, input.production_function.sector))) for input in input_into_sectors)...)))
                ) +
                $(length(input_into_consumers)==0 ? 0. : 
                    :(+($((:($(jm[get_name(demand.demand_function.consumer)]) / $(jm[get_name(demand.commodity, true)])) for demand in input_into_consumers)...)))
                ) -
                $(s.outputs[1].quantity) * $(get_jump_variable_for_sector(jm, s.sector))
            )
        )
        ex4b = eval(swap_our_param_with_jump_param(ex4a))

        Complementarity.add_complementarity(jm, get_jump_variable_for_commodity(jm, s.outputs[1].commodity), ex4b, string("F_", price_name))

    end

# Loop over all endowments
endows = Dict{CommodityRef, Vector{Expr}}()

for c in m._demands
    for en in c.endowments
        if !haskey(endows, en.commodity)
            endows[en.commodity] = Expr[]
        end
        push!(endows[en.commodity], :(0. + $(en.quantity)))
    end
end

    for (commodity, endowment_levels) in endows
        endowment_level = :(+($(endowment_levels...)))

        endowment_level = swap_our_param_with_jump_param(endowment_level)

        # Find all the sectors where our current sector is an input
        input_into_sectors = Input[]
        for s2 in m._productions
            for input in s2.inputs
                if input.commodity==commodity
                    push!(input_into_sectors, input)
                end
            end
        end

        # Find all the demand functions where our current sector (or rather output) is a demand item
        input_into_consumers = Demand[]
        for demand_function in m._demands
            if demand_function.demands[1].commodity==commodity
                push!(input_into_consumers, demand_function.demands[1])
            end
        end

        ex5a = :(
            JuMP.@NLexpression(
                $jm,
                $(length(input_into_sectors)==0 ? 0. : 
                    :(+($((:($(jm[get_comp_demand_name(input)]) * $(get_jump_variable_for_sector(jm, input.production_function.sector))) for input in input_into_sectors)...)))
                ) +
                $(length(input_into_consumers)==0 ? 0. : 
                    :(+($((:($(jm[get_name(demand.demand_function.consumer)]) / $(jm[get_name(demand.commodity, true)])) for demand in input_into_consumers)...)))
                ) -
                $(endowment_level)
            )
        )

        ex5b = eval(swap_our_param_with_jump_param(ex5a))

        Complementarity.add_complementarity(jm, get_jump_variable_for_commodity(jm, commodity), ex5b, string("F_", get_name(commodity, true)))
    end    
end
