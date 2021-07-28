function set_all_start_values(m)
    jm = m._jump_model
    for s in m._sectors
        if s isa ScalarSector
            Complementarity.set_start_value(jm[s.name], s.benchmark)
        else
            for i in Iterators.product(s.indices...)
                Complementarity.set_start_value(jm[s.name][i...], s.benchmark[i...])
            end
        end
    end

    for c in m._commodities
        if c isa ScalarCommodity
            Complementarity.set_start_value(jm[c.name], c.benchmark)
        else
            for i in Iterators.product(c.indices...)
                Complementarity.set_start_value(jm[c.name][i...], c.benchmark[i...])
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


    # Add compensated supply variables
    for s in m._productions
        for o in s.outputs
            Complementarity.set_start_value(jm[get_comp_supply_name(o)], eval(swap_our_param_with_val(o.quantity)))
        end
    end

    # Add final demand variables
    for demand_function in m._demands
        for demand in demand_function.demands
            Complementarity.set_start_value(jm[get_final_demand_name(demand)], eval(swap_our_param_with_val(demand.quantity)))
        end
    end
end

function set_all_bounds(m)
    jm = m._jump_model

    for c in m._commodities
        if c isa ScalarCommodity
            jump_var = jm[c.name]

            if c.fixed
                JuMP.fix(jump_var, c.benchmark, force=true)
            else
                if JuMP.is_fixed(jump_var)
                    JuMP.unfix(jump_var)
                end
    
                JuMP.set_lower_bound(jump_var, 0.001)
            end
        else
            for i in Iterators.product(c.indices...)
                jump_var = jm[c.name][i...]

                if c.fixed[i...]
                    JuMP.fix(jump_var, c.benchmark[i...], force=true)
                else
                    if JuMP.is_fixed(jump_var)
                        JuMP.unfix(jump_var)
                    end
        
                    JuMP.set_lower_bound(jump_var, 0.001)
                end
            end
        end
    
    end
    for cs in m._consumers
        jump_var = jm[cs.name]
        if cs.fixed
            JuMP.fix(jump_var, cs.benchmark, force=true)
        else
            if JuMP.is_fixed(jump_var)
                JuMP.unfix(jump_var)
            end
        end
    end
end

function set_all_parameters(m)
    jm = m._jump_model

    for p in m._parameters
        JuMP.set_value(jm[p.name], p.value)
    end
end
