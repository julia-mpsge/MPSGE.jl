function build(m::Model)
    m._nlexpressions = (
        comp_demand=[],
        comp_supply=[],
        final_demand=[],
        zero_profit=[],
        market_clearance=[],
        income_balance=[],
        aux=[]
    )
    jm = JuMP.Model()

    build_variables!(m, jm)

    # add_implicitvars!(m)
    
    build_implicitconstraints!(m, jm)

    build_zeroprofit!(m, jm)

    build_marketclearance!(m, jm)

    build_incomebalance!(m, jm)  

    build_auxconstraints!(m, jm)

    return jm
end
