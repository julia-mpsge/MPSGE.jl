function build_auxconstraints!(m::Model, jm)
    # Add aux constraints
    for ac in m._auxconstraints
        ac.equation isa Expr || error("You must pass an expression as an aux constraint.")
        (ac.equation.head == :call && length(ac.equation.args) == 3 && ac.equation.args[1] == :(==)) || error("Must pass an equation with an == sign.")
# TODO Need >=, and possibly <=
        ex6b = JuMP.NonlinearExpr(swap_our_Ref_with_jump_var(jm, :( $(ac.equation.args[2]) - $(ac.equation.args[3]) )))
        
        var = get_jump_variable_for_aux(jm, ac.aux)

        @constraint(jm, complements(ex6b, var))
        push!(m._nlexpressions.aux, (expr=ex6b, var=var))
    end
end
