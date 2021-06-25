function set_all_start_values(m)
    jm = m._jump_model
    for s in m._sectors
        if s.indices===nothing
            Complementarity.set_start_value(jm[s.name], s.benchmark)
        else
            for i in Iterators.product(s.indices...)
                Complementarity.set_start_value(jm[s.name][i...], s.benchmark)
            end
        end
    end

    for c in m._commodities
        if c.indices===nothing
            Complementarity.set_start_value(jm[c.name], c.benchmark)
        else
            for i in Iterators.product(c.indices...)
                Complementarity.set_start_value(jm[c.name][i...], c.benchmark)
            end
        end
    end

    for s in m._productions
        for i in s.inputs
            compensated_input1_demand_name = get_comp_demand_name(i)
            Complementarity.set_start_value(jm[compensated_input1_demand_name], eval(swap_our_param_with_val(i.quantity)))
        end
    end

    for c in m._consumers
        Complementarity.set_start_value(jm[c.name], c.benchmark)
    end
end

function set_all_bounds(m)
    jm = m._jump_model

    for c in m._commodities
        if c.indices===nothing
            jump_var = jm[c.name]
        else
            for i in Iterators.product(c.indices...)
                jump_var = jm[c.name][i...]
            end
        end
        ## Todo? Can fix all indexed or none so far
        if c.fixed
            JuMP.fix(jump_var, c.benchmark, force=true)
        else
            if JuMP.is_fixed(jump_var)
                JuMP.unfix(jump_var)
            end

            JuMP.set_lower_bound(jump_var, 0.001)
        end
    end
end

function set_all_parameters(m)
    jm = m._jump_model

    for p in m._parameters
        JuMP.set_value(m._jump_nlparameters[p.name], p.value)
    end
end
