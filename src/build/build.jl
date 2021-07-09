function build(m::Model)
    m._nlexpressions = []
    jm = Complementarity.MCPModel()

    build_variables!(m, jm)
    
    build_implicitconstraints!(m, jm)

    build_zeroprofit!(m, jm)

    build_marketclearance!(m, jm)

    build_incomebalance!(m, jm)  

    return jm
end
