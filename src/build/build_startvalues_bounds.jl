function set_all_start_values(m)
    jm = m._jump_model
    for s in m._sectors
        if s isa ScalarSector
            JuMP.set_start_value(jm[s.name], s.benchmark)
        else
            for i in Iterators.product(s.indices...)
                JuMP.set_start_value(jm[s.name][i...], s.benchmark[i...])
            end
        end
    end

    for c in m._commodities
        if c isa ScalarCommodity
            JuMP.set_start_value(jm[c.name], c.benchmark)
        else
            for i in Iterators.product(c.indices...)
                JuMP.set_start_value(jm[c.name][i...], c.benchmark[i...])
            end
        end
    end

    for s in m._productions
        for i in s.inputs
            compensated_input1_demand_name = get_comp_demand_name(i)
            JuMP.set_start_value(jm[compensated_input1_demand_name], eval(swap_our_param_with_val(i.quantity)))
        end
    end

    for c in m._consumers
        if c isa ScalarConsumer
            if c.fixed
                start_val = c.benchmark
            else
                start_val = eval(swap_our_param_with_val(get_consumer_total_endowment_old(jm, m, c)))
            end 
            JuMP.set_start_value(jm[c.name], start_val)
        else
            for i in Iterators.product(c.indices...)
                if c.fixed[i[1]] 
                    start_val = c.benchmark[i[1]]
                else
                    start_val = eval(swap_our_param_with_val(get_consumer_total_endowment_old(jm, m, c, i)))
                end
                JuMP.set_start_value(jm[c.name][i...], start_val)
            end
        end
    end

    for aux in m._auxs
        if aux isa ScalarAux
            JuMP.set_start_value(jm[aux.name], aux.benchmark)
        else
            for i in Iterators.product(aux.indices...)
                JuMP.set_start_value(jm[aux.name][i...], aux.benchmark[i...])
            end
        end
    end

    # Add compensated supply variables
    for s in m._productions
        for o in s.outputs
            JuMP.set_start_value(jm[get_comp_supply_name(o)], eval(swap_our_param_with_val(o.quantity)))
        end
    end

    # Add final demand variables
    for demand_function in m._demands
        for demand in demand_function.demands
            JuMP.set_start_value(jm[get_final_demand_name(demand)], eval(swap_our_param_with_val(demand.quantity)))
        end
    end
end

function set_all_bounds(m)
    jm = m._jump_model

    for c in m._commodities
        if c isa ScalarCommodity
            jump_var = jm[c.name]
# TODONE: Allow user defined lower and upper bounds with defaults
            if c.fixed
                JuMP.fix(jump_var, c.benchmark, force=true)
            else
                if JuMP.is_fixed(jump_var)
                    JuMP.unfix(jump_var)
                end
# TODONE: Allow user defined lower and upper bounds with defaults    
                JuMP.set_lower_bound(jump_var, c.lower_bound)
                JuMP.set_upper_bound(jump_var, c.upper_bound)
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
                    JuMP.set_lower_bound(jump_var, c.lower_bound[i...])
                    JuMP.set_upper_bound(jump_var, c.upper_bound[i...])
                end
            end
        end
    
    end
    for cs in m._consumers
        if cs isa ScalarConsumer
            jump_var = jm[cs.name]
            if cs.fixed
                start_val = cs.benchmark
                JuMP.fix(jump_var, start_val, force=true)
            else
                if JuMP.is_fixed(jump_var)
                    JuMP.unfix(jump_var)
                end
                JuMP.set_lower_bound(jump_var, cs.lower_bound)
                    JuMP.set_upper_bound(jump_var, cs.upper_bound)
            end
        else
            for i in Iterators.product(cs.indices...)
                jump_var = jm[cs.name][i...]
                if cs.fixed[i...]
                    start_val = cs.benchmark[i...]
                    JuMP.fix(jump_var, start_val, force=true)
                else
                    if JuMP.is_fixed(jump_var)
                        JuMP.unfix(jump_var)
                    end
                    JuMP.set_lower_bound(jump_var, cs.lower_bound[i...])
                    JuMP.set_upper_bound(jump_var, cs.upper_bound[i...])
                end
            end
        end
    end

    for a in m._auxs
        if a isa ScalarAux
            jump_var = jm[a.name]
# TODONE: Allow user defined llower and upper bounds with defaults
            if a.fixed
                JuMP.fix(jump_var, a.benchmark, force=true)
            else
                if JuMP.is_fixed(jump_var)
                    JuMP.unfix(jump_var)
                end
# TODONE: Allow user defined llower and upper bounds with defaults    
                JuMP.set_lower_bound(jump_var, a.lower_bound)
                    JuMP.set_upper_bound(jump_var, a.upper_bound)
            end
        else
            for i in Iterators.product(a.indices...)
                jump_var = jm[a.name][i...]

                if a.fixed[i...]
                    JuMP.fix(jump_var, a.benchmark[i...], force=true)
                else
                    if JuMP.is_fixed(jump_var)
                        JuMP.unfix(jump_var)
                    end
        
                    JuMP.set_lower_bound(jump_var, a.lower_bound[i...])
                    JuMP.set_upper_bound(jump_var, a.upper_bound[i...])
                end
            end
        end
    
    end

    for s in m._sectors
        if s isa ScalarSector
            jump_var = jm[s.name]
# TODONE: Allow user defined llower and upper bounds with defaults
            if s.fixed
                JuMP.fix(jump_var, s.benchmark, force=true)
            else
                if JuMP.is_fixed(jump_var)
                    JuMP.unfix(jump_var)
                end
# TODONE: Allow user defined llower and upper bounds with defaults    
                JuMP.set_lower_bound(jump_var, s.lower_bound)
                JuMP.set_upper_bound(jump_var, s.upper_bound)
            end
        else
            for i in Iterators.product(s.indices...)
                jump_var = jm[s.name][i...]

                if s.fixed[i...]
                    JuMP.fix(jump_var, s.benchmark[i...], force=true)
                else
                    if JuMP.is_fixed(jump_var)
                        JuMP.unfix(jump_var)
                    end

                    JuMP.set_lower_bound(jump_var, s.lower_bound[i...])
                    JuMP.set_upper_bound(jump_var, s.upper_bound[i...])
                end
            end
        end
    
    end

end

function set_all_parameters(m)
    jm = m._jump_model

    for p in m._parameters
        if p isa ScalarParameter
            JuMP.set_parameter_value(jm[p.name], p.value)
        else
            for pp in Iterators.product(p.indices...)
                JuMP.set_parameter_value(jm[p.name][pp...], p.value[pp...])
            end
        end
    end
end
