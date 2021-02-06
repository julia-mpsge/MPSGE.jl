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

function build(m::Model)
    jm = JuMP.Model(m._solver)

    # Add all required variables

    for s in m._sectors
        level_name = s.name
        jm[level_name] = JuMP.@variable(jm, base_name=string(level_name), lower_bound=0.)

        price_name = Symbol("P$(s.name)")
        jm[price_name] = JuMP.@variable(jm, base_name=string(price_name), lower_bound=0.)

        compensated_input1_demand_name = Symbol("$(s.input1_name)$(s.name)")
        jm[compensated_input1_demand_name] = JuMP.@variable(jm, base_name=string(compensated_input1_demand_name), lower_bound=0.)

        compensated_input2_demand_name = Symbol("$(s.input2_name)$(s.name)")
        jm[compensated_input2_demand_name] = JuMP.@variable(jm, base_name=string(compensated_input2_demand_name), lower_bound=0.)
    end

    for c in m._consumers
        for en in c.endowments
            price_name = Symbol("P$(en.name)")
            jm[price_name] = JuMP.@variable(jm, base_name=string(price_name), lower_bound=0.)
        end

        level_name = c.name
        jm[level_name] = JuMP.@variable(jm, base_name=string(level_name), lower_bound=0.)
    end

    # Add compensated demand equations
    for s in m._sectors
        # TODO
    end

    # Add zero profit constraints
    for s in m._sectors
        price_name = Symbol("P$(s.name)")
        input1_price_name = Symbol("P$(s.input1_name)")
        input2_price_name = Symbol("P$(s.input2_name)")
        compensated_input1_demand_name = Symbol("$(s.input1_name)$(s.name)")
        compensated_input2_demand_name = Symbol("$(s.input2_name)$(s.name)")

        foo = JuMP.@NLconstraint(jm, jm[input1_price_name]*jm[compensated_input1_demand_name] + jm[input2_price_name]*jm[compensated_input2_demand_name]  == s.output_quantity * jm[price_name])
    end

    # Add market clearance constraints
    
    # TODO

    # Add income balance constraints

    # TODO

    return jm
end

function solve(m::Model)
    jm = build(m)

    JuMP.optimize!(jm)

    return jm
end

end
