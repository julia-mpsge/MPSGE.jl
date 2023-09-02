struct AlgebraicWrapper
    _source
    _jmpsource
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
        m,
        jump_model,
        sum(length(s.inputs) for s in m._productions),
        sum(length(s.outputs) for s in m._productions),
        sum(length(d.demands) for d in m._demands),
        length(m._productions),
        sum(c isa ScalarCommodity ? 1 : c isa IndexedCommodity ? prod(length.(c.indices)) : error("Invalid") for c in m._commodities),
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
    constraint_strings = [sprint(show, c.expr) for c in Iterators.flatten(m._source._nlexpressions)]
    
    column1_width = maximum(textwidth.(constraint_strings))

    println(io, "  Compensated Demand")
    for i in m._source._nlexpressions.comp_demand
        print(io, "    ")

        print(io, rpad(sprint(show, i.expr), column1_width))

        print(io, "  ┴  ")

        c = i.var

        if JuMP.is_fixed(c)
            print(io, JuMP.name(c), " = $(JuMP.fix_value(c))")
        else
            print(io, !JuMP.has_lower_bound(c) ? "" : "$(JuMP.lower_bound(c)) < ", JuMP.name(c), !JuMP.has_upper_bound(c) ? "" : " < $(JuMP.upper_bound(c))")
        end

        println(io)
    end

    println(io, "  Compensated Supply")
    for i in m._source._nlexpressions.comp_supply
        print(io, "    ")

        print(io, rpad(sprint(show, i.expr), column1_width))

        print(io, "  ┴  ")

        c = i.var

        if JuMP.is_fixed(c)
            print(io, JuMP.name(c), " = $(JuMP.fix_value(c))")
        else
            print(io, !JuMP.has_lower_bound(c) ? "" : "$(JuMP.lower_bound(c)) < ", JuMP.name(c), !JuMP.has_upper_bound(c) ? "" : " < $(JuMP.upper_bound(c))")
        end

        println(io)
    end

    println(io, "  Final Demand")
    for i in m._source._nlexpressions.final_demand
        print(io, "    ")

        print(io, rpad(sprint(show, i.expr), column1_width))

        print(io, "  ┴  ")

        c = i.var

        if JuMP.is_fixed(c)
            print(io, JuMP.name(c), " = $(JuMP.fix_value(c))")
        else
            print(io, !JuMP.has_lower_bound(c) ? "" : "$(JuMP.lower_bound(c)) < ", JuMP.name(c), !JuMP.has_upper_bound(c) ? "" : " < $(JuMP.upper_bound(c))")
        end

        println(io)
    end

    println(io, "  Zero Profit")
    for i in m._source._nlexpressions.zero_profit
        print(io, "    ")

        print(io, rpad(sprint(show, i.expr), column1_width))

        print(io, "  ┴  ")

        c = i.var

        if JuMP.is_fixed(c)
            print(io, JuMP.name(c), " = $(JuMP.fix_value(c))")
        else
            print(io, !JuMP.has_lower_bound(c) ? "" : "$(JuMP.lower_bound(c)) < ", JuMP.name(c), !JuMP.has_upper_bound(c) ? "" : " < $(JuMP.upper_bound(c))")
        end

        println(io)
    end

    println(io, "  Market clearance")
    for i in m._source._nlexpressions.market_clearance
        print(io, "    ")

        print(io, rpad(sprint(show, i.expr), column1_width))

        print(io, "  ┴  ")

        c = i.var

        if JuMP.is_fixed(c)
            print(io, JuMP.name(c), " = $(JuMP.fix_value(c))")
        else
            print(io, !JuMP.has_lower_bound(c) ? "" : "$(JuMP.lower_bound(c)) < ", JuMP.name(c), !JuMP.has_upper_bound(c) ? "" : " < $(JuMP.upper_bound(c))")
        end

        println(io)
    end

    println(io, "  Income balance")
    for i in m._source._nlexpressions.income_balance
        print(io, "    ")

        print(io, rpad(sprint(show, i.expr), column1_width))

        print(io, "  ┴  ")

        c = i.var

        if JuMP.is_fixed(c)
            print(io, JuMP.name(c), " = $(JuMP.fix_value(c))")
        else
            print(io, !JuMP.has_lower_bound(c) ? "" : "$(JuMP.lower_bound(c)) < ", JuMP.name(c), !JuMP.has_upper_bound(c) ? "" : " < $(JuMP.upper_bound(c))")
        end

        println(io)
    end
end

function Base.show(io::IO, ::MIME"text/latex", m::AlgebraicWrapper)
    println(io, raw"$$ \begin{alignat*}{3}\\")

    println(io, raw"& \text{Compensated Demand} \quad && \quad && \\\\")
    for i in m._source._nlexpressions.comp_demand
        print(io, "& \\quad ")

        s = sprint((io, val) -> show(io, "text/latex", val), i.expr)
        print(io, s[3:end-2])

        print(io, raw"\quad && \perp \quad && ")

        c = i.var

        if JuMP.is_fixed(c)
            print(io, JuMP.name(c), " = $(JuMP.fix_value(c))")
        else
            print(io, !JuMP.has_lower_bound(c) ? "" : "$(JuMP.lower_bound(c)) <", JuMP.name(c), !JuMP.has_upper_bound(c) ? "" : " < $(JuMP.upper_bound(c))")
        end

        println(io, "\\\\")
    end

    println(io, raw"& \text{Compensated Supply} \quad && \quad && \\\\")
    for i in m._source._nlexpressions.comp_supply
        print(io, "& \\quad ")

        s = sprint((io, val) -> show(io, "text/latex", val), i.expr)
        print(io, s[3:end-2])

        print(io, raw"\quad && \perp \quad && ")

        c = i.var

        if JuMP.is_fixed(c)
            print(io, JuMP.name(c), " = $(JuMP.fix_value(c))")
        else
            print(io, !JuMP.has_lower_bound(c) ? "" : "$(JuMP.lower_bound(c)) <", JuMP.name(c), !JuMP.has_upper_bound(c) ? "" : " < $(JuMP.upper_bound(c))")
        end

        println(io, "\\\\")
    end
    
    println(io, raw"& \text{Final Demand} \quad && \quad && \\\\")
    for i in m._source._nlexpressions.final_demand
        print(io, "& \\quad ")

        s = sprint((io, val) -> show(io, "text/latex", val), i.expr)
        print(io, s[3:end-2])

        print(io, raw"\quad && \perp \quad && ")

        c = i.var

        if JuMP.is_fixed(c)
            print(io, JuMP.name(c), " = $(JuMP.fix_value(c))")
        else
            print(io, !JuMP.has_lower_bound(c) ? "" : "$(JuMP.lower_bound(c)) <", JuMP.name(c), !JuMP.has_upper_bound(c) ? "" : " < $(JuMP.upper_bound(c))")
        end

        println(io, "\\\\")
    end

    println(io, raw"& \text{Zero Profit} \quad && \quad && \\\\")
    for i in m._source._nlexpressions.zero_profit
        print(io, "& \\quad ")

        s = sprint((io, val) -> show(io, "text/latex", val), i.expr)
        print(io, s[3:end-2])

        print(io, raw"\quad && \perp \quad && ")

        c = i.var

        if JuMP.is_fixed(c)
            print(io, JuMP.name(c), " = $(JuMP.fix_value(c))")
        else
            print(io, !JuMP.has_lower_bound(c) ? "" : "$(JuMP.lower_bound(c)) <", JuMP.name(c), !JuMP.has_upper_bound(c) ? "" : " < $(JuMP.upper_bound(c))")
        end

        println(io, "\\\\")
    end

    println(io, raw"& \text{Market clearance} \quad && \quad && \\\\")
    for i in m._source._nlexpressions.market_clearance
        print(io, "& \\quad ")

        s = sprint((io, val) -> show(io, "text/latex", val), i.expr)
        print(io, s[3:end-2])

        print(io, raw"\quad && \perp \quad && ")

        c = i.var

        if JuMP.is_fixed(c)
            print(io, JuMP.name(c), " = $(JuMP.fix_value(c))")
        else
            print(io, !JuMP.has_lower_bound(c) ? "" : "$(JuMP.lower_bound(c)) <", JuMP.name(c), !JuMP.has_upper_bound(c) ? "" : " < $(JuMP.upper_bound(c))")
        end

        println(io, "\\\\")
    end

    println(io, raw"& \text{Income balance} \quad && \quad && \\\\")
    for i in m._source._nlexpressions.income_balance
        print(io, "& \\quad ")

        s = sprint((io, val) -> show(io, "text/latex", val), i.expr)
        print(io, s[3:end-2])

        print(io, raw"\quad && \perp \quad && ")

        c = i.var

        if JuMP.is_fixed(c)
            print(io, JuMP.name(c), " = $(JuMP.fix_value(c))")
        else
            print(io, !JuMP.has_lower_bound(c) ? "" : "$(JuMP.lower_bound(c)) <", JuMP.name(c), !JuMP.has_upper_bound(c) ? "" : " < $(JuMP.upper_bound(c))")
        end

        println(io, "\\\\")
    end

    println(io, raw"\end{alignat*}")
    println(io, raw" $$")
end
