function build_incomebalance!(m, jm)
    # Add income balance constraints
    for df in m.demand_functions
        # ex6a = :(
        #     JuMP.@NLexpression(
        #         $jm,
        #         +(
        #             $((:($(en.quantity) * $(en.commodity)) for en in c.endowments)...)
        #         ) 
        #         +  $(get_tax_revenue_for_consumer(jm, m, c.consumer)) 
        #         -
        #         $(c.consumer)
        #     )
        # )

        # ex6b = eval(swap_our_Ref_with_jump_var(jm, ex6a))
        # Complementarity.add_complementarity(jm, get_jump_variable_for_consumer(jm, c.consumer), ex6b, string("F_", get_name(c.consumer, true)))
        # push!(m._nlexpressions, ex6b)
        foo = 0

        @constraint(jm, sum(en.quantity * en.commodity for en in df.endowments) + foo - df.consumer ⟂ df.consumer)
    end
end
