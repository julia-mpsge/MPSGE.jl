struct AlgebraicWrapper
    _source
    n_comp_dem::Int
    n_comp_supply::Int
    n_final_demand::Int
    n_zero_profits::Int
    n_market_clearance::Int
    n_income_balance::Int
end

function algebraic_version(m::Model)    
    jump_model = m._jump_model===nothing ? build(m) : m._jump_model

    return AlgebraicWrapper(
        jump_model,
        sum(length(s.inputs) for s in m._productions),
        sum(length(s.outputs) for s in m._productions),
        sum(length(d.demands) for d in m._demands),
        length(m._productions),
        sum(length(s.demands)+length(s.endowments) for s in m._demands),
        length(m._demands)
    )
end

function constraint_values(m::Model)
    for j=1:length(m._nlexpressions)
        var_values = []
        println("Constraint $j: ", value(m._nlexpressions[j],i->begin
            val = MPSGE.Complementarity.result_value(i)
            push!(var_values, "  $i = $val")
            return val
        end))            

        for s in var_values
            println(s)
        end
    end
end

function Base.show(io::IO, m::AlgebraicWrapper)
    println(io, "Mixed complementarity problem with $(length(m._source.ext[:MCP])) constraints:")
    constraint_strings = [JuMP.nl_expr_string(m._source, JuMP.REPLMode, m._source.nlp_data.nlexpr[c.F.index]) for c in m._source.ext[:MCP]]
    
    column1_width = maximum(textwidth.(constraint_strings))

    for (i, (constraint_string, c)) in enumerate(zip(constraint_strings, m._source.ext[:MCP]))
        if i==1
            println(io, "  Compensated Demand")
        elseif i==m.n_comp_dem + 1
            println(io, "  Compensated Supply")
        elseif i==m.n_comp_dem + m.n_comp_supply + 1
            println(io, "  Final Demand")
        elseif i==m.n_comp_dem + m.n_comp_supply + m.n_final_demand + 1
            println(io, "  Zero Profit")
        elseif i==m.n_comp_dem + m.n_comp_supply + m.n_final_demand + m.n_zero_profits + 1
            println(io, "  Market clearance")
        elseif i==m.n_comp_dem + m.n_comp_supply + m.n_final_demand + m.n_zero_profits + m.n_market_clearance + 1
            println(io, "  Income balance")
        end

        print(io, "    ")

        print(io, rpad(constraint_string, column1_width))

        print(io, "  ┴  ")

        if !isinf(c.lb) && c.lb==c.ub
            print(io, c.var_name, " = $(c.ub)")
        else
            print(io, isinf(c.lb) ? "" : "$(c.lb) < ", c.var_name, isinf(c.ub) ? "" : " < $(c.ub)")
        end

        println(io)
    end
end

function Base.show(io::IO, ::MIME"text/latex", m::AlgebraicWrapper)
    println(io, raw"$$ \begin{alignat*}{3}\\")
    for (i, c) in enumerate(m._source.ext[:MCP])
        if i==1
            println(io, raw"& \text{Compensated Demand} \quad && \quad && \\\\")
        elseif i==m.n_comp_dem + 1
            println(io, raw"& \text{Compensated Supply} \quad && \quad && \\\\")
        elseif i==m.n_comp_dem + m.n_comp_supply + 1
            println(io, raw"& \text{Final Demand} \quad && \quad && \\\\")
        elseif i==m.n_comp_dem + m.n_comp_supply + m.n_final_demand + 1
            println(io, raw"& \text{Zero Profit} \quad && \quad && \\\\")
        elseif i==m.n_comp_dem + m.n_comp_supply + m.n_final_demand + m.n_zero_profits + 1
            println(io, raw"& \text{Market clearance} \quad && \quad && \\\\")
        elseif i==m.n_comp_dem + m.n_comp_supply + m.n_final_demand + m.n_zero_profits + m.n_market_clearance + 1
            println(io, raw"& \text{Income balance} \quad && \quad && \\\\")
        end

        print(io, "& \\quad ")

        print(io, JuMP.nl_expr_string(m._source, JuMP.IJuliaMode, m._source.nlp_data.nlexpr[c.F.index]))

        print(io, raw"\quad && \perp \quad && ")

        if !isinf(c.lb) && c.lb==c.ub
            print(io, c.var_name, " = $(c.ub)")
        else
            print(io, isinf(c.lb) ? "" : "$(c.lb) <", c.var_name, isinf(c.ub) ? "" : " < $(c.ub)")
        end

        println(io, "\\\\")
    end
    println(io, raw"\end{alignat*}")
    println(io, raw" $$")
end
