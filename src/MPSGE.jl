module MPSGE

import JuMP, PATHSolver, Ipopt

export add!, Sector, Model, Consumer, build, Endowment, solve

struct Sector
    name::Symbol    
    elasticity::Float64
    output_quantity::Float64
    input1_name::Symbol
    input1_quantity::Float64
    input2_name::Symbol
    input2_quantity::Float64
end

struct Endowment
    name::Symbol
    quantity::Float64
end

struct Consumer
    name::Symbol
    demand_name::Symbol
    endowments::Vector{Endowment}

    function Consumer(;
        name=nothing,
        demand_name=nothing,
        endowments=nothing)

        return new(name, demand_name, endowments)
    end
        
end

struct Model
    _solver

    _sectors::Vector{Sector}
    _consumers::Vector{Consumer}

    function Model()
        new(Ipopt.Optimizer, Sector[], Consumer[])
    end
end

function add!(m::Model, s::Sector)
    push!(m._sectors, s)
end

function add!(m::Model, c::Consumer)
    push!(m._consumers, c)
end

function add_variable!(jm::JuMP.Model, name::Symbol, lower_bound::Float64)
    jm[name] = JuMP.@variable(jm, base_name=string(name), lower_bound=lower_bound)
end

function add_variable!(jm::JuMP.Model, name::String, lower_bound::Float64)
    add_variable!(jm, Symbol(name), lower_bound)
end

function build(m::Model)
    jm = JuMP.Model(m._solver)

    # Add all required variables

    for s in m._sectors
        level_name = s.name        
        add_variable!(jm, level_name, 0.001)

        price_name = "P$(s.name)"
        add_variable!(jm, price_name, 0.001)

        compensated_input1_demand_name = "$(s.input1_name)$(s.name)"
        add_variable!(jm, compensated_input1_demand_name, 0.001)

        compensated_input2_demand_name = "$(s.input2_name)$(s.name)"
        add_variable!(jm, compensated_input2_demand_name, 0.001)
    end

    for c in m._consumers
        for en in c.endowments
            price_name = "P$(en.name)"
            add_variable!(jm, price_name, 0.001)
        end

        level_name = c.name
        add_variable!(jm, level_name, 0.001)
    end

    # Add compensated demand equations
    for s in m._sectors        
        compensated_input1_demand_name = Symbol("$(s.input1_name)$(s.name)")
        compensated_input2_demand_name = Symbol("$(s.input2_name)$(s.name)")
        price_input1_name = Symbol("P$(s.input1_name)")
        price_input2_name = Symbol("P$(s.input2_name)")

        JuMP.@NLconstraint(jm,
            jm[compensated_input1_demand_name] == 
            s.input1_quantity * ( 
                jm[price_input1_name]^(s.input1_quantity/s.output_quantity) * jm[price_input2_name]^(s.input2_quantity/s.output_quantity)
            ) / jm[price_input1_name] )

        JuMP.@NLconstraint(jm,
            jm[compensated_input2_demand_name] == 
            s.input2_quantity * ( 
                jm[price_input1_name]^(s.input1_quantity/s.output_quantity) * jm[price_input2_name]^(s.input2_quantity/s.output_quantity)
            ) / jm[price_input2_name] )
    end

    # Add zero profit constraints
    for s in m._sectors
        price_name = Symbol("P$(s.name)")
        input1_price_name = Symbol("P$(s.input1_name)")
        input2_price_name = Symbol("P$(s.input2_name)")
        compensated_input1_demand_name = Symbol("$(s.input1_name)$(s.name)")
        compensated_input2_demand_name = Symbol("$(s.input2_name)$(s.name)")

        JuMP.@NLconstraint(jm, jm[input1_price_name]*jm[compensated_input1_demand_name] + jm[input2_price_name]*jm[compensated_input2_demand_name]  == s.output_quantity * jm[price_name])
    end

    # Add market clearance constraints

    for s in m._sectors
        level_name = s.name

        # Find all the sectors where our current sector is an input
        input_into_sectors = [s2.name for s2 in m._sectors if s2.input1_name==s.name || s2.input2_name==s.name]
        input_into_consumers = [c.name for c in m._consumers if c.demand_name==s.name]

        JuMP.add_NL_constraint(jm, 
            :($(s.output_quantity) * $(jm[level_name]) == 
                $(length(input_into_sectors)==0 ? 0. : 
                    :(+($((:($(jm[Symbol("$(s.name)$i")]) * $(jm[Symbol(i)])) for i in input_into_sectors)...)))
                ) +
                $(length(input_into_consumers)==0 ? 0. : 
                    :(+($((:($(jm[Symbol(i)]) / $(jm[Symbol("P$(s.name)")])) for i in input_into_consumers)...)))
                )
            )
        )
    end

    # Loop over all endowments
    endows = Dict{Symbol, Float64}()

    for c in m._consumers
        for en in c.endowments
            if !haskey(endows, en.name)
                endows[en.name] = 0.
            end
            endows[en.name] += en.quantity
        end
    end

    for (level_name, endowment_level) in endows
        # Find all the sectors where our current sector is an input
        input_into_sectors = [s.name for s in m._sectors if s.input1_name==level_name || s.input2_name==level_name]
        input_into_consumers = [c.name for c in m._consumers if c.demand_name==level_name]

        JuMP.add_NL_constraint(jm, 
            :($(endowment_level) == 
                $(length(input_into_sectors)==0 ? 0. : 
                    :(+($((:($(jm[Symbol("$(level_name)$i")]) * $(jm[Symbol(i)])) for i in input_into_sectors)...)))
                ) +
                $(length(input_into_consumers)==0 ? 0. : 
                    :(+($((:($(jm[Symbol(i)]) / $(jm[Symbol("P$(level_name)")])) for i in input_into_consumers)...)))
                )
            )
        )
    end

    # Add income balance constraints
    for c in m._consumers
        level_name = c.name

        JuMP.add_NL_constraint(jm, :($(jm[level_name]) == +($((:($(en.quantity) * $(jm[Symbol("P$(en.name)")])) for en in c.endowments)...))))
    end

    return jm
end

function solve(m::Model)
    jm = build(m)

    JuMP.optimize!(jm)

    return jm
end

end
