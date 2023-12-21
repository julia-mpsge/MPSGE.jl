function build_auxconstraints!(m::Model, jm)
    # Add aux constraints
    for ac in auxconstraints(m)
        ac.equation isa Expr || error("You must pass an expression as an aux constraint.")
        (ac.equation.head == :call && length(ac.equation.args) == 3 && ac.equation.args[1] == :(==)) || error("Must pass an equation with an == sign.")

        # TODO Need >=, and possibly <=

        jump_ex = convert_mpsge_expr_to_jump_nonlinearexpr(jm, :( $(ac.equation.args[2]) - $(ac.equation.args[3]) ))        
        jump_var = get_jump_variable_for_aux(jm, ac.aux)

        @constraint(jm, jump_ex ⟂ jump_var)
        push!(m._nlexpressions.aux, (expr=jump_ex, var=jump_var))
    end
end
