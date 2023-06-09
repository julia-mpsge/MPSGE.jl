function build_auxconstraints!(m::Model, jm)
    # Add aux constraints
    for ac in m._auxconstraints
        ac.equation isa Expr || error("You must pass an expression as an aux constraint.")
        (ac.equation.head == :call && length(ac.equation.args) == 3 && ac.equation.args[1] == :(==)) || error("Must pass an equation with an == sign.")
# TODO Need >=, and possibly <=
        equation_expr = swap_our_param_with_jump_param(jm, :( $(ac.equation.args[2]) - $(ac.equation.args[3]) ))
        
        ex6a = :(
            JuMP.@NLexpression(
                $jm,
                $equation_expr
            )
        )

        ex6b = eval(swap_our_param_with_jump_param(jm, ex6a))
        Complementarity.add_complementarity(jm, get_jump_variable_for_aux(jm, ac.aux), ex6b, string("F_", get_name(ac.aux, true)))
        push!(m._nlexpressions, ex6b)
    end
end
