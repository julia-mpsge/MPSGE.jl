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

    jump_ex = Dict()
    jump_var = Dict()
    jump_var_ind = []
    # Loop over commodities
    for commodity in commodities
        # Find all endowments for current commodity
        endows = []
        for demand_function in m._demands
            for en in demand_function.endowments
                if en.commodity==commodity
                    push!(endows, tojump(jm, en.quantity))
                end
            end
        end

        # Find all intermediate supplies for current commodity
        comp_supplies = []
        for production_function in m._productions
            for output in production_function.outputs
                if output.commodity==commodity
                    push!(comp_supplies, tojump(jm, production_function.sector) * jm[get_comp_supply_name(output)])
                end
            end
        end

        # Find all final demand for current commodity
        final_demand = []
        for demand_function in m._demands
            for demand in demand_function.demands
                if demand.commodity == commodity
                    push!(final_demand, jm[get_final_demand_name(demand)])
                end
            end
        end

        # Find all the intermediate demands for current commodity
        comp_demands = []
        for production_function in m._productions
            for input in production_function.inputs
                if input.commodity==commodity
                    push!(comp_demands, tojump(jm, production_function.sector) * jm[get_comp_demand_name(input)])
                end
            end
        end

        cm_name = Symbol(get_jump_variable_for_commodity(jm, commodity))
        push!(jump_var_ind, cm_name)
        push!(jump_var, cm_name => get_jump_variable_for_commodity(jm, commodity))
        push!(jump_ex, cm_name =>
        +(
            0.,
            endows...,
            comp_supplies...) -
            +(0., final_demand..., comp_demands...)
        )
        push!(m._nlexpressions.market_clearance, (expr=jump_ex[cm_name], var=jump_var[cm_name]))
    end
    @constraint(jm, mkt_clr[cm=jump_var_ind], jump_ex[cm] ⟂ jump_var[cm])
end
