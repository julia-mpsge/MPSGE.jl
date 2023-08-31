struct JuMPEndowment
    commodity::JuMP.VariableRef
    quantity::JuMP.NonlinearExpression
end

struct JuMPDemand
    commodity::JuMP.VariableRef
    quantity::JuMP.NonlinearExpression
    price::JuMP.NonlinearExpression
    # parent::Any
end

struct JuMPDemandFunction
    consumer::JuMP.VariableRef
    elasticity::JuMP.NonlinearExpression
    demands::Vector{JuMPDemand}
    endowments::Vector{JuMPEndowment}
end

struct JuMPModel
    demand_functions::Vector{JuMPDemandFunction}
end

function build_jump_model(m::Model)
    jump_model =  JuMPModel(
        [
            JuMPDemandFunction(
                get_jump_variable_for_consumer(i.consumer),
                i.elasticity,
                [
                    JuMPDemand(
                        get_jump_variable_for_commodity(j.commodity),
                        j.quantity,
                        j.price,
                        # nothing
                    ) for j in i.demands
                ],
                [
                    JuMPEndowment(
                        get_jump_variable_for_commodity(j.commodity),
                        j.quantity
                    ) for j in i.endowments
                ]
            ) for i in m._demands
        ]
    )    

    return jump_model
end
