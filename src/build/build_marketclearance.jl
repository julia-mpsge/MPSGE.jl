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
                    push!(comp_supplies, :($(production_function.sector) * $(m._implicitvarsDict[get_comp_supply_name(output)])))
                end
            end
        end

        # Find all final demand for current commodity
        final_demand = []
        for demand_function in m._demands
            for demand in demand_function.demands
                if demand.commodity == commodity
                    push!(final_demand, :($(m._implicitvarsDict[get_final_demand_name(demand)])))
                end
            end
        end

        # Find all the intermediate demands for current commodity
        comp_demands = []
        for production_function in m._productions
            for input in production_function.inputs
                if input.commodity==commodity
                    push!(comp_demands, :($(production_function.sector) * $(m._implicitvarsDict[get_comp_demand_name(input)])))
                end
            end
        end

        exa = :(
                +(0., $(endows...), $(comp_supplies...)) - +(0., $(final_demand...), $(comp_demands...))
        )
        exb = JuMP.NonlinearExpr(swap_our_Ref_with_jump_var(jm, exa))

        var = get_jump_variable_for_commodity(jm, commodity)

        @constraint(jm, complements(exb, var))

        push!(m._nlexpressions.market_clearance, (expr=exb, var=var))
    end
end
