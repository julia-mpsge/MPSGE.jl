function build_marketclearance!(m, jm)
    # Add market clearance constraints

    commodities = Set{CommodityRef}()
    for pf in m._productions
        for input in pf.inputs
            push!(commodities, input.commodity)
        end

        for output in pf.outputs
            push!(commodities, output.commodity)
        end
    end
    for df in m._demands
        for demand in df.demands
            push!(commodities, demand.commodity)
        end
    end


    # Loop over commodities
    for commodity in commodities
        # Find all endowments for current commodity
        endows = []
        for demand_function in m._demands
            for en in demand_function.endowments
                if en.commodity==commodity
                    push!(endows, :($(en.quantity)))
                end
            end
        end

        # Find all intermediate supplies for current commodity
        comp_supplies = []
        for production_function in m._productions
            for output in production_function.outputs
                if output.commodity==commodity
                    push!(comp_supplies, :($(production_function.sector) * $(jm[get_comp_supply_name(output)])))#$(jm[get_comp_supply_name(output)])))#$(get_jump_variable_for_intermediate_supply(jm, output))))
                end
            end
        end

        # Find all final demand for current commodity
        final_demand = []
        for demand_function in m._demands
            for demand in demand_function.demands
                if demand.commodity == commodity
                    push!(final_demand, :($(jm[get_final_demand_name(demand)])))#$(get_jump_variable_for_final_demand(jm, demand))))
                end
            end
        end

        # Find all the intermediate demands for current commodity
        comp_demands = []
        for production_function in m._productions
            for input in production_function.inputs
                if input.commodity==commodity
                    push!(comp_demands, :($(production_function.sector) * $(jm[get_comp_demand_name(input)])))#$(get_jump_variable_for_intermediate_demand(jm, input))))
                end
            end
        end

        exa = :(
            JuMP.@NLexpression(
                $jm,
                +(0., $(endows...), $(comp_supplies...)) - +(0., $(final_demand...), $(comp_demands...))
            )
        )
        exb = eval(swap_our_Ref_with_jump_var(jm, exa))

        Complementarity.add_complementarity(jm, get_jump_variable_for_commodity(jm, commodity), exb, string("F_", get_name(commodity, true)))
        push!(m._nlexpressions, exb)
    end
end
