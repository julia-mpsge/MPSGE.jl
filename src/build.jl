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
        Complementarity.set_start_value(jm[c.name], c.benchmark)
    end

    for s in m._productions
        for i in s.inputs
            compensated_input1_demand_name = Symbol("$(get_name(i.commodity))$(get_name(s.output))")
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
        jump_var = jm[c.name]
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
        add_variable!(jm, c.name, 0.001)
    end

    for s in m._productions
        for i in s.inputs
            compensated_input1_demand_name = Symbol("$(get_name(i.commodity))$(get_name(s.output))")
            add_variable!(jm, compensated_input1_demand_name)
        end
    end

    for c in m._consumers
        add_variable!(jm, c.name)
    end

    # Add compensated demand equations
    for s in m._productions
        compensated_input1_demand_name = Symbol("$(get_name(s.inputs[1].commodity))$(get_name(s.output))")
        compensated_input2_demand_name = Symbol("$(get_name(s.inputs[2].commodity))$(get_name(s.output))")
        price_input1_name = get_name(s.inputs[1].commodity)
        price_input2_name = get_name(s.inputs[2].commodity)

        ex1a = :(
            JuMP.@NLexpression(
                $(jm),
                $(s.inputs[1].quantity) * ( 
                    $(jm[price_input1_name])^($(s.inputs[1].quantity)/$(s.output_quantity)) *
                     $(jm[price_input2_name])^($(s.inputs[2].quantity)/$(s.output_quantity))
                ) / $(jm[price_input1_name]) - $(jm[compensated_input1_demand_name])
            )
        )

        ex1b = eval( swap_our_param_with_jump_param(ex1a) )

        Complementarity.add_complementarity(jm, jm[compensated_input1_demand_name], ex1b, string("F_", compensated_input1_demand_name))

        ex2a = :(
            JuMP.@NLexpression(
                $jm,
                $(s.inputs[2].quantity) * ( 
                    $(jm[price_input1_name])^($(s.inputs[1].quantity)/$(s.output_quantity)) * $(jm[price_input2_name])^($(s.inputs[2].quantity)/$(s.output_quantity))
                ) / $(jm[price_input2_name]) - $(jm[compensated_input2_demand_name])
            )
        )

        ex2b = eval(swap_our_param_with_jump_param(ex2a))

        Complementarity.add_complementarity(jm, jm[compensated_input2_demand_name], ex2b, string("F_", compensated_input2_demand_name))
    end

    # Add zero profit constraints
    for s in m._productions
        price_name = get_name(s.output)
        input1_price_name = get_name(s.inputs[1].commodity)
        input2_price_name = get_name(s.inputs[2].commodity)
        compensated_input1_demand_name = Symbol("$(get_name(s.inputs[1].commodity))$(get_name(s.output))")
        compensated_input2_demand_name = Symbol("$(get_name(s.inputs[2].commodity))$(get_name(s.output))")

        ex3a = :(
            JuMP.@NLexpression(
                $jm,
                $(jm[input1_price_name])*$(jm[compensated_input1_demand_name]) + $(jm[input2_price_name])*
        $(jm[compensated_input2_demand_name]) - $(s.output_quantity) * $(jm[price_name])
            )
        )

        ex3b = eval(swap_our_param_with_jump_param(ex3a))

        Complementarity.add_complementarity(jm, get_jump_variable_for_sector(jm, s.sector), ex3b, string("F_", get_name(s.sector), s.sector.subindex!==nothing ? s.sector.subindex : ""))
    end

    # Add market clearance constraints

    for s in m._productions
        price_name = get_name(s.output)

        # Find all the sectors where our current sector is an input
        input_into_sectors = [(get_name(s2.output), s2.sector) for s2 in m._productions if s2.inputs[1].commodity==s.output || s2.inputs[2].commodity==s.output]
        input_into_consumers = [get_name(c.consumer) for c in m._demands if c.commodity==s.output]

        ex4a = :(
            JuMP.@NLexpression(
                $jm,
                $(length(input_into_sectors)==0 ? 0. : 
                    :(+($((:($(jm[Symbol("$(get_name(s.output))$i")]) * $(get_jump_variable_for_sector(jm, ii))) for (i,ii) in input_into_sectors)...)))
                ) +
                $(length(input_into_consumers)==0 ? 0. : 
                    :(+($((:($(jm[Symbol(i)]) / $(jm[Symbol("$(get_name(s.output))")])) for i in input_into_consumers)...)))
                ) -
                $(s.output_quantity) * $(get_jump_variable_for_sector(jm, s.sector))
            )
        )
        ex4b = eval(swap_our_param_with_jump_param(ex4a))

        Complementarity.add_complementarity(jm, jm[price_name], ex4b, string("F_", price_name))

    end

    # Loop over all endowments
    endows = Dict{Symbol, Vector{Expr}}()

    for c in m._demands
        for en in c.endowments
            if !haskey(endows, get_name(en.commodity))
                endows[get_name(en.commodity)] = Expr[]
            end
            push!(endows[get_name(en.commodity)], :(0. + $(en.quantity)))
        end
    end

    for (level_name, endowment_levels) in endows
        endowment_level = :(+($(endowment_levels...)))

        endowment_level = swap_our_param_with_jump_param(endowment_level)

        price_name = level_name
        # Find all the sectors where our current sector is an input
        input_into_sectors = [(get_name(s.output), s.sector) for s in m._productions if get_name(s.inputs[1].commodity)==level_name || get_name(s.inputs[2].commodity)==level_name]
        input_into_consumers = [c.name for c in m._demands if get_name(c.commodity)==level_name]

        ex5a = :(
            JuMP.@NLexpression(
                $jm,
                $(length(input_into_sectors)==0 ? 0. : 
                    :(+($((:($(jm[Symbol("$(level_name)$i")]) * $(get_jump_variable_for_sector(jm, ii))) for (i,ii) in input_into_sectors)...)))
                ) +
                $(length(input_into_consumers)==0 ? 0. : 
                    :(+($((:($(jm[Symbol(i)]) / $(jm[Symbol("$(level_name)")])) for i in input_into_consumers)...)))
                ) -
                $(endowment_level)
            )
        )

        ex5b = eval(swap_our_param_with_jump_param(ex5a))
        Complementarity.add_complementarity(jm, jm[price_name], ex5b, string("F_", price_name))
    end

    # Add income balance constraints
    for c in m._demands
        level_name = get_name(c.consumer)

        ex6a = :(
            JuMP.@NLexpression(
                $jm,
                +($((:($(swap_our_param_with_jump_param(en.quantity)) * 
                $(jm[Symbol("$(get_name(en.commodity))")])) for en in c.endowments)...)) - $(jm[level_name])
            )
        )

        ex6b = eval(swap_our_param_with_jump_param(ex6a))
        Complementarity.add_complementarity(jm, jm[level_name], ex6b, string("F_", level_name))
    end

    return jm
end