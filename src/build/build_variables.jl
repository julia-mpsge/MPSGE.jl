function add_variable!(jm::JuMP.Model, name::Symbol, lower_bound::Union{Float64,Nothing}=nothing)    
    if lower_bound===nothing
        jm[name] = JuMP.@variable(jm, base_name=string(name))
    else    
        jm[name] = JuMP.@variable(jm, base_name=string(name), lower_bound=lower_bound)
    end
end

function add_variable!(jm::JuMP.Model, name::Symbol, indices, lower_bound::Union{Float64,Nothing}=nothing)
    dim = length.(indices)
    
    x = if lower_bound===nothing
        JuMP.@variable(jm, [1:prod(dim)])
    else    
        JuMP.@variable(jm, [1:prod(dim)], lower_bound=lower_bound)
    end

    for (i, index) in enumerate(Iterators.product(indices...))
        JuMP.set_name(x[i], "$(name)[$index]")
    end

    output = JuMP.Containers.DenseAxisArray(reshape(x, dim), indices...)
    jm[name] = output
    return output
end

function add_parameter_to_jump!(jm, parameter::ScalarParameter)
    jmp_p = JuMP.@variable(jm, set = JuMP.Parameter(parameter.value))
    jm[parameter.name] = jmp_p
end

function add_parameter_to_jump!(jm, parameter::IndexedParameter)
    # We set the parameter value to 1.0 here, but in a later model building phase that gets replaced
    # with the actual values
    dim = length.(parameter.indices)
    x = JuMP.@variable(jm, [i=1:prod(dim)], set = JuMP.Parameter(i))

    for (i, index) in enumerate(Iterators.product(parameter.indices...))
        JuMP.set_name(x[i], "$(parameter.name)[$index]")
    end

    output = JuMP.Containers.DenseAxisArray(reshape(x, dim), parameter.indices...)
    jm[parameter.name] = output
    return output
end

function add_sector_to_jump!(jm, sector::ScalarSector)
    add_variable!(jm, sector.name, 0.)
end

function add_sector_to_jump!(jm, sector::IndexedSector)        
    add_variable!(jm, sector.name, sector.indices, 0.)
end

function add_commodity_to_jump!(jm, commodity::ScalarCommodity)
    add_variable!(jm, commodity.name, 0.)
end

function add_commodity_to_jump!(jm, commodity::IndexedCommodity)
    add_variable!(jm, commodity.name, commodity.indices, 0.)
end

function add_consumer_to_jump!(jm, consumer::ScalarConsumer)
    add_variable!(jm, consumer.name, 0.)
end

function add_consumer_to_jump!(jm, consumer::IndexedConsumer)
    add_variable!(jm, consumer.name, consumer.indices, 0.)
end

function add_aux_to_jump!(jm, aux::ScalarAux)
    add_variable!(jm, aux.name, 0.)
end

function add_aux_to_jump!(jm, aux::IndexedAux)
    add_variable!(jm, aux.name, aux.indices, 0.)
end

# function add_implicitvars!(m)
#     # Add compensated supply variable Refs to model
#     for s in m._productions
#         for o in s.outputs
#             add!(m, Implicitvar(get_comp_supply_name(o), typeof(o)))
#         end
#     end
#     # Add compensated demand variables
#     for s in m._productions
#         for i in s.inputs
#             add!(m, Implicitvar(get_comp_demand_name(i), typeof(i)))
#         end
#     end
#    # Add final demand variables
#    for demand_function in m._demands
#         for demand in demand_function.demands
#             add!(m, Implicitvar(get_final_demand_name(demand), typeof(demand)))
#         end
#     end
# end

function build_variables!(m, jm)
    # Add all parameters

    for p in m._parameters
        add_parameter_to_jump!(jm, p)
    end

    # Add all required variables

    for s in m._sectors
        add_sector_to_jump!(jm, s)        
    end

    for c in m._commodities
        add_commodity_to_jump!(jm, c)
    end

    # Add aux variables
    for aux in m._auxs
        add_aux_to_jump!(jm, aux)
    end

    # Add compensated supply variables
    # for s in m._productions
    #     for o in s.outputs
    #         add_variable!(jm, get_comp_supply_name(o))
    #     end
    # end

    # Add compensated demand variables
    # for s in m._productions
    #     for i in s.inputs
    #         add_variable!(jm, get_comp_demand_name(i))
    #     end
    # end

    for c in m._consumers
        add_consumer_to_jump!(jm, c)
    end

    # Add final demand variables
    # for demand_function in m._demands
    #     for demand in demand_function.demands
    #         add_variable!(jm, get_final_demand_name(demand))
    #     end
    # end
end
