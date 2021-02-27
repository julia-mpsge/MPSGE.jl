struct AlgebraicWrapper
    _source
end

function algebraic_version(m::Model)
    if m._jump_model===nothing
        return AlgebraicWrapper(build(m))
    else
        return AlgebraicWrapper(m._jump_model)
    end
end

function Base.show(io::IO, m::AlgebraicWrapper)
    println(io, "Mixed complementarity problem with $(length(m._source.ext[:MCP])) constraints:")
    constraint_strings = [JuMP.nl_expr_string(m._source, JuMP.REPLMode, m._source.nlp_data.nlexpr[c.F.index]) for c in m._source.ext[:MCP]]
    
    column1_width = maximum(textwidth.(constraint_strings))

    for (constraint_string, c) in zip(constraint_strings, m._source.ext[:MCP])

        print(io, "  ")

        print(io, rpad(constraint_string, column1_width))

        print(io, "  ┴  ")

        print(io, isinf(c.lb) ? "" : "$(c.lb) < ", c.var_name, isinf(c.ub) ? "" : "$(c.ub) < ")

        println(io)
    end
end

function Base.show(io::IO, ::MIME"text/latex", m::AlgebraicWrapper)
    println(io, raw"\begin{alignat*}{3}\\")
    for c in m._source.ext[:MCP]

        print(io, "& ")

        println(io, JuMP.nl_expr_string(m._source, JuMP.IJuliaMode, m._source.nlp_data.nlexpr[c.F.index]))

        print(io, raw"\quad && ┴ \quad && ")

        print(io, isinf(c.lb) ? "" : "$(c.lb) <", c.var_name, isinf(c.ub) ? "" : "$(c.ub) < ")

        print(io, "\\\\")
    end
    println(io, raw"\end{alignat*}")
end
