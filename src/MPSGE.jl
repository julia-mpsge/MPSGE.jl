module MPSGE

import JuMP, Complementarity

export add!, Sector, Model, Consumer, Endowment, solve!

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

mutable struct Model
    _sectors::Vector{Sector}
    _consumers::Vector{Consumer}

    _jump_model::Union{Nothing,JuMP.Model}
    _status

    function Model()
        new(Sector[], Consumer[], nothing, nothing)
    end
end

function Base.show(io::IO, m::Model)
    println(io, "MPSGE model with $(length(m._sectors)) sectors and $(length(m._consumers)) consumers.")
    if length(m._sectors) > 0
        println(io, "  Sectors:")
        for s in m._sectors
            println(io, "    $(s.name)")
        end
    end

    if length(m._consumers) > 0
        println(io, "  Consumers:")
        for c in m._consumers            
            println(io, "    $(c.name)")
        end
    end

    if m._jump_model!==nothing
        println(io, "Solution:")

        for s in m._sectors
            println(io, "  $(s.name): level=$(Complementarity.result_value(m._jump_model[s.name])), price=$(Complementarity.result_value(m._jump_model[Symbol("P$(s.name)")]))")
        end

        for c in m._consumers
            println(io, "  $(c.name): level=$(Complementarity.result_value(m._jump_model[c.name]))")
        end
    end
end

function add!(m::Model, s::Sector)
    m._jump_model = nothing
    push!(m._sectors, s)
    return m
end

function add!(m::Model, c::Consumer)
    m._jump_model = nothing
    push!(m._consumers, c)
    return m
end

function add_variable!(jm::JuMP.Model, name::Symbol, lower_bound::Union{Float64,Nothing}=nothing)
    if lower_bound===nothing
        jm[name] = JuMP.@variable(jm, base_name=string(name))
    else    
        jm[name] = JuMP.@variable(jm, base_name=string(name), lower_bound=lower_bound)
    end
end

function add_variable!(jm::JuMP.Model, name::String, lower_bound::Union{Float64,Nothing}=nothing)
    add_variable!(jm, Symbol(name), lower_bound)
end

function build(m::Model)
    jm = Complementarity.MCPModel()

    # Add all required variables

    for s in m._sectors
        level_name = s.name        
        add_variable!(jm, level_name, 0.)

        price_name = "P$(s.name)"
        # TODO Remove this special casing
        if price_name == "PX"
            jm[Symbol(price_name)] = JuMP.@variable(jm, base_name=price_name, lower_bound=1.0, upper_bound=1.0)
        else
            add_variable!(jm, price_name, 0.001)
        end

        compensated_input1_demand_name = "$(s.input1_name)$(s.name)"
        add_variable!(jm, compensated_input1_demand_name)

        compensated_input2_demand_name = "$(s.input2_name)$(s.name)"
        add_variable!(jm, compensated_input2_demand_name)
    end

    for c in m._consumers
        for en in c.endowments
            price_name = "P$(en.name)"
            add_variable!(jm, price_name, 0.001)
        end

        level_name = c.name
        add_variable!(jm, level_name)
    end

    # Add compensated demand equations
    for s in m._sectors        
        compensated_input1_demand_name = Symbol("$(s.input1_name)$(s.name)")
        compensated_input2_demand_name = Symbol("$(s.input2_name)$(s.name)")
        price_input1_name = Symbol("P$(s.input1_name)")
        price_input2_name = Symbol("P$(s.input2_name)")

        exp_1 = s.input1_quantity/s.output_quantity
        exp_2 = s.input2_quantity/s.output_quantity

        ex1 = JuMP.@NLexpression(jm,
            s.input1_quantity * ( 
                jm[price_input1_name]^exp_1 * jm[price_input2_name]^exp_2
            ) / jm[price_input1_name] - jm[compensated_input1_demand_name]
        )

        Complementarity.add_complementarity(jm, jm[compensated_input1_demand_name], ex1, string("F_", compensated_input1_demand_name))

        ex2 = JuMP.@NLexpression(jm,
            s.input2_quantity * ( 
                jm[price_input1_name]^exp_1 * jm[price_input2_name]^exp_2
            ) / jm[price_input2_name] - jm[compensated_input2_demand_name]
        )

        Complementarity.add_complementarity(jm, jm[compensated_input2_demand_name], ex2, string("F_", compensated_input2_demand_name))
    end

    # Add zero profit constraints
    for s in m._sectors
        price_name = Symbol("P$(s.name)")
        input1_price_name = Symbol("P$(s.input1_name)")
        input2_price_name = Symbol("P$(s.input2_name)")
        compensated_input1_demand_name = Symbol("$(s.input1_name)$(s.name)")
        compensated_input2_demand_name = Symbol("$(s.input2_name)$(s.name)")

        ex3 = JuMP.@NLexpression(jm, jm[input1_price_name]*jm[compensated_input1_demand_name] + jm[input2_price_name]*jm[compensated_input2_demand_name] - s.output_quantity * jm[price_name])

        Complementarity.add_complementarity(jm, jm[s.name], ex3, string("F_", s.name))
    end

    # Add market clearance constraints

    for s in m._sectors
        level_name = s.name
        price_name = Symbol("P$(s.name)")

        # Find all the sectors where our current sector is an input
        input_into_sectors = [s2.name for s2 in m._sectors if s2.input1_name==s.name || s2.input2_name==s.name]
        input_into_consumers = [c.name for c in m._consumers if c.demand_name==s.name]

        ex4 = @eval(
            JuMP.@NLexpression(
                $jm,
                $(length(input_into_sectors)==0 ? 0. : 
                    :(+($((:($(jm[Symbol("$(s.name)$i")]) * $(jm[Symbol(i)])) for i in input_into_sectors)...)))
                ) +
                $(length(input_into_consumers)==0 ? 0. : 
                    :(+($((:($(jm[Symbol(i)]) / $(jm[Symbol("P$(s.name)")])) for i in input_into_consumers)...)))
                ) -
                $(s.output_quantity) * $(jm[level_name])
            )
        )
        Complementarity.add_complementarity(jm, jm[price_name], ex4, string("F_", price_name))
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
        price_name = Symbol("P$(level_name)")
        # Find all the sectors where our current sector is an input
        input_into_sectors = [s.name for s in m._sectors if s.input1_name==level_name || s.input2_name==level_name]
        input_into_consumers = [c.name for c in m._consumers if c.demand_name==level_name]

        ex5 = @eval(
            JuMP.@NLexpression(
                $jm,
                $(length(input_into_sectors)==0 ? 0. : 
                    :(+($((:($(jm[Symbol("$(level_name)$i")]) * $(jm[Symbol(i)])) for i in input_into_sectors)...)))
                ) +
                $(length(input_into_consumers)==0 ? 0. : 
                    :(+($((:($(jm[Symbol(i)]) / $(jm[Symbol("P$(level_name)")])) for i in input_into_consumers)...)))
                ) -
                $(endowment_level)
            )
        )
        Complementarity.add_complementarity(jm, jm[price_name], ex5, string("F_", price_name))
    end

    # Add income balance constraints
    for c in m._consumers
        level_name = c.name

        ex6 = @eval(
            JuMP.@NLexpression(
                $jm,
                +($((:($(en.quantity) * $(jm[Symbol("P$(en.name)")])) for en in c.endowments)...)) - $(jm[level_name])
            )
        )
        Complementarity.add_complementarity(jm, jm[level_name], ex6, string("F_", level_name))
    end

    # TODO Remove this special casing
    Complementarity.setvalue(jm[:X], 1.)
    Complementarity.setvalue(jm[:Y], 1.)
    Complementarity.setvalue(jm[:U], 1.)
    Complementarity.setvalue(jm[:PX], 1.)
    Complementarity.setvalue(jm[:PY], 1.)
    Complementarity.setvalue(jm[:PK], 1.)
    Complementarity.setvalue(jm[:PU], 1.)
    Complementarity.setvalue(jm[:RA], 150.)
    Complementarity.setvalue(jm[:LX], 50.)
    Complementarity.setvalue(jm[:LY], 20.)
    Complementarity.setvalue(jm[:KX], 50.)
    Complementarity.setvalue(jm[:KY], 30.)
    Complementarity.setvalue(jm[:XU], 100.)
    Complementarity.setvalue(jm[:YU], 50.)

    return jm
end

function solve!(m::Model; solver::Symbol=:PATH, kwargs...)
    m._jump_model = build(m)
    m._status = Complementarity.solveMCP(m._jump_model; solver=solver, kwargs...)

    return m
end

end
