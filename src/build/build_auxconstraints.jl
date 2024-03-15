function build_auxconstraints!(m::Model, jm)
    # Add aux constraints
    jump_ex = Dict()
    jump_var = Dict()
    jump_var_ind = []
    for ac in m._auxconstraints
        ac.equation isa Expr || error("You must pass an expression as an aux constraint.")
        (ac.equation.head == :call && length(ac.equation.args) == 3 && ac.equation.args[1] == :(==)) || error("Must pass an equation with an == sign.")

        ac_name = Symbol(get_jump_variable_for_aux(jm, ac.aux))
        push!(jump_var_ind, ac_name)
        push!(jump_var, ac_name => get_jump_variable_for_aux(jm, ac.aux))
        push!(jump_ex, ac_name =>
          convert_mpsge_expr_to_jump_nonlinearexpr(jm, :( $(ac.equation.args[2]) - $(ac.equation.args[3]) ))        
        # TODO Need >=, and possibly <=
        )

        push!(m._nlexpressions.aux, (expr=jump_ex[ac_name], var=jump_var[ac_name]))
    end
    @constraint(jm, aux_cnstr[ac = jump_var_ind], jump_ex[ac] ⟂ jump_var[ac])
end
