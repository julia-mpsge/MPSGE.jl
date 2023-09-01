function build(m::Model)
    m._nlexpressions = []
    jm = JuMP.Model(PATHSolver.Optimizer)

    build_variables!(m, jm)

    add_implicitvars!(m)
    
    build_implicitconstraints!(m, jm)

    build_zeroprofit!(m, jm)

    build_marketclearance!(m, jm)

    build_incomebalance!(m, jm)  

    build_auxconstraints!(m, jm)

    return jm
end
