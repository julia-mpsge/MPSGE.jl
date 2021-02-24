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
        add_variable!(jm, level_name, 0.)

        price_name = "P$(s.name)"
        add_variable!(jm, price_name, 0.)

        compensated_input1_demand_name = "$(s.input1_name)$(s.name)"
        add_variable!(jm, compensated_input1_demand_name, 0.)

        compensated_input2_demand_name = "$(s.input2_name)$(s.name)"
        add_variable!(jm, compensated_input2_demand_name, 0.)
    end

    for c in m._consumers
        for en in c.endowments
            price_name = "P$(en.name)"
            add_variable!(jm, price_name, 0.)
        end

        level_name = c.name
        add_variable!(jm, level_name, 0.)
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
    # FOR NOW THIS IS TOO HARD
    # for s in m._sectors
    #     level_name = s.name 
    #     JuMP.@NLconstraint(jm, s.output_quantity * jm[level_name] == 

    #     )
    # end

    # Add income balance constraints

    for c in m._consumers
        # TODO Make this work with arbitrary number of endowments
        level_name = c.name
        price1_name = Symbol("P$(c.endowments[1].name)")
        price2_name = Symbol("P$(c.endowments[2].name)")

        JuMP.@NLconstraint(jm, jm[level_name] == c.endowments[1].quantity * jm[price1_name] + c.endowments[2].quantity * jm[price2_name])
    end

    return jm
end

function solve(m::Model)
    jm = build(m)

    JuMP.optimize!(jm)

    return jm
end

end
