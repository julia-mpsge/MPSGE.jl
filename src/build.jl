"""
    swap_our_param_with_jump_param(expr)

This function takes an expression tree and replaces all instances of
`ParameterRef` with the corresponding `JuMP.NLParameter`.
"""
function swap_our_param_with_jump_param(expr)
    return MacroTools.postwalk(expr) do x
        if x isa ParameterRef
            return x.model._jump_nlparameters[x.model._parameters[x.index].name]
        else
            return x
        end
    end
end

"""
swap_our_param_with_val(expr)

This function takes an expression tree and replaces all instances of
`ParameterRef` with its value.
"""
function swap_our_param_with_val(expr)
    return MacroTools.postwalk(expr) do x
        if x isa ParameterRef
            return x.model._parameters[x.index].value
        else
            return x
        end
    end
end

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

function add_variable!(jm::JuMP.Model, name::Symbol, lower_bound::Union{Float64,Nothing}=nothing)    
    if lower_bound===nothing
        jm[name] = JuMP.@variable(jm, base_name=string(name))
    else    
        jm[name] = JuMP.@variable(jm, base_name=string(name), lower_bound=lower_bound)
    end
end

function add_sector_to_jump!(jm, sector)
    if sector.indices===nothing
        add_variable!(jm, sector.name, 0.)
    else
        jm[sector.name] = @eval(JuMP.@variable($jm, [$( ( :($(gensym())=$i) for i in sector.indices)... )], base_name=string($(QuoteNode(sector.name))), lower_bound=0.))
    end
end

function get_jump_variable_for_sector(jm, sector)
    if sector.subindex===nothing
        return jm[get_name(sector)]
    else
        return jm[get_name(sector)][sector.subindex]
    end
end

function add_commodity_to_jump!(jm, commodity)
    if commodity.indices===nothing
        add_variable!(jm, commodity.name, 0.)
    else
        jm[commodity.name] = @eval(JuMP.@variable($jm, [$( ( :($(gensym())=$i) for i in commodity.indices)... )], base_name=string($(QuoteNode(commodity.name))), lower_bound=0.))
    end
end

function get_jump_variable_for_commodity(jm, commodity)
    if commodity.subindex===nothing
        return jm[get_name(commodity)]
    else
        return jm[get_name(commodity)][commodity.subindex]
    end
end

function get_prod_func_name(x::Production)
    return Symbol("†$(get_name(x.sector, true))")
end

function get_comp_demand_name(i::Input)
    p = i.production_function::Production 
    return Symbol("‡$(get_name(i.commodity, true))$(get_prod_func_name(p))")
end

function build(m::Model)
    jm = Complementarity.MCPModel()

    # Add all parameters

    for p in m._parameters
        jmp_p = @eval(JuMP.@NLparameter($jm, $(p.name) == $(p.value)))
        jm[p.name] = jmp_p
        m._jump_nlparameters[p.name] = jmp_p
    end

    # Add all required variables

    for s in m._sectors
        add_sector_to_jump!(jm, s)        
    end

    for c in m._commodities
        add_commodity_to_jump!(jm, c)
    end

    for s in m._productions
        for i in s.inputs
            add_variable!(jm, get_comp_demand_name(i))
        end
    end

    for c in m._consumers
        add_variable!(jm, c.name)
    end

    
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

    # Add income balance constraints
    for c in m._demands
        level_name = get_name(c.consumer)

        ex6a = :(
            JuMP.@NLexpression(
                $jm,
                +($((:($(swap_our_param_with_jump_param(en.quantity)) * 
                $(get_jump_variable_for_commodity(jm, en.commodity))) for en in c.endowments)...)) - $(jm[level_name])
            )
        )

        ex6b = eval(swap_our_param_with_jump_param(ex6a))
        Complementarity.add_complementarity(jm, jm[level_name], ex6b, string("F_", level_name))
    end

    return jm
end