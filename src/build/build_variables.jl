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

function add_commodity_to_jump!(jm, commodity::ScalarCommodity)
    add_variable!(jm, commodity.name, 0.)
end

function add_commodity_to_jump!(jm, commodity::IndexedCommodity)
    jm[commodity.name] = @eval(JuMP.@variable($jm, [$( ( :($(gensym())=$i) for i in commodity.indices)... )], base_name=string($(QuoteNode(commodity.name))), lower_bound=0.))
end


function build_variables!(m, jm)
    # Add all parameters

    for p in m._parameters
        jmp_p = @eval(JuMP.@NLparameter($jm, $(p.name) == $(p.value)))
        jm[p.name] = jmp_p
    end

    # Add all required variables

    for s in m._sectors
        add_sector_to_jump!(jm, s)        
    end

    for c in m._commodities
        add_commodity_to_jump!(jm, c)
    end

    # Add compensated supply variables
    for s in m._productions
        for o in s.outputs
            add_variable!(jm, get_comp_supply_name(o))
        end
    end

    # Add compensated demand variables
    for s in m._productions
        for i in s.inputs
            add_variable!(jm, get_comp_demand_name(i))
        end
    end

    for c in m._consumers
        add_variable!(jm, c.name)
    end

    # Add final demand variables
    for demand_function in m._demands
        for demand in demand_function.demands
            add_variable!(jm, get_final_demand_name(demand))
        end
    end
end
