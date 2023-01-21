function calc_thetas(m)
    jm = Complementarity.MCPModel()
    for pf in m._productions
        for i in pf.inputs
            val = eval(:( $(swap_our_param_with_val(i.quantity)) * $(get_commodity_benchmark(i.commodity)) / +($( (:( $(swap_our_param_with_val(o.quantity)) * $(get_commodity_benchmark(o.commodity)) ) for o in pf.outputs)...) ) ))
            # val = eval(:(($(i.quantity) + $(replaceinput(jm, i))) * $(get_commodity_benchmark(i.commodity)) / +($( (:( $(swap_our_param_with_val(o.quantity)) * $(get_commodity_benchmark(o.commodity)) ) for o in pf.outputs)...) ) ))
            
            add!(m, ShareParameter(Symbol(get_theta_name(pf,i)), val, ""))
            end
    end
    for pf in m._productions
        for out in pf.outputs
            val = eval(:( $(swap_our_param_with_val(out.quantity)) * $(get_commodity_benchmark(out.commodity)) / +($( (:( $(swap_our_param_with_val(o.quantity)) * $(get_commodity_benchmark(o.commodity)) ) for o in pf.outputs)...) ) ))
            add!(m, ShareParameter(Symbol(get_theta_name(pf,out)), val, ""))
            end
    end
    for df in m._demands
        for dm in df.demands
            val = eval(:( $(swap_our_param_with_val(dm.quantity)) * $(get_commodity_benchmark(dm.commodity))/ $(get_consumer_benchmark(df.consumer))))
            add!(m, ShareParameter(Symbol(get_theta_name(df,dm)), val, "")) 
        end
    end
end

function Θ(pf::Production, i::Input)
        m = pf.sector.model
    return get_theta_value(m, pf, i)    
    # return :( $(i.quantity) * $(get_commodity_benchmark(i.commodity)) / +($( (:( $(o.quantity) * $(get_commodity_benchmark(o.commodity)) ) for o in pf.outputs)...) ) )
end

function Θy(pf::Production, i::Input)
        # m = pf.sector.model
    # return get_theta_value(m, pf, i)    
    return :( $(i.quantity) * $(get_commodity_benchmark(i.commodity)) / +($( (:( $(o.quantity) * $(get_commodity_benchmark(o.commodity)) ) for o in pf.outputs)...) ) )
end

function get_theta_value(m, pf::Production, i::Input)
    for sh in m._shareparams
        if get_theta_name(pf, i) == sh.name
           return sh.value
        end
    end
end

function Θ(pf::Production, i::Output)
    m = pf.sector.model
    return get_theta_value(m, pf, i)    
    # return :( $(i.quantity) * $(get_commodity_benchmark(i.commodity)) / +($( (:( $(o.quantity) * $(get_commodity_benchmark(o.commodity)) ) for o in pf.outputs)...) ) )
end

function Θy(pf::Production, i::Output)
    # m = pf.sector.model
    # return get_theta_value(m, pf, i)    
    return :( $(i.quantity) * $(get_commodity_benchmark(i.commodity)) / +($( (:( $(o.quantity) * $(get_commodity_benchmark(o.commodity)) ) for o in pf.outputs)...) ) )
end

function get_theta_value(m, pf::Production, i::Output)
    for sh in m._shareparams
        if get_theta_name(pf, i) == sh.name
           return sh.value
        end
    end
end

function Θ(df::DemandFunction, dm)   
    # return :( $(i.quantity) * $(get_commodity_benchmark(i.commodity)) / $(get_consumer_benchmark(df.consumer)))
    m = df.consumer.model
    return get_theta_value(m, df, dm)    
end

function Θy(df::DemandFunction, dm)   
    return :( $(dm.quantity) * $(get_commodity_benchmark(dm.commodity)) / $(get_consumer_benchmark(df.consumer)))
end

function get_theta_value(m, df::DemandFunction, dm::Demand)
    for sh in m._shareparams
        if get_theta_name(df, dm) == sh.name
           return sh.value
        end
    end
end

function y_over_y_bar(jm, pf::Production)
    if eval(swap_our_param_with_val(pf.elasticity))==0
        println("sub_elas_0")
        return :(
            min(
                $(( :( $(jm[get_comp_demand_name(i)])/$(i.quantity) ) for i in pf.inputs)...)
                # $(( :( $(jm[get_comp_demand_name(i)])/$(swap_our_param_with_val(i.quantity))) for i in pf.inputs)...)
                )
        )
    elseif eval(swap_our_param_with_val(pf.elasticity))==1
        println("sub_elas_1")

        return :(
            *(
                $(( :( ($(jm[get_comp_demand_name(i)])/$(i.quantity))^$(Θ(pf,i)) ) for i in pf.inputs)...)
                # $(( :( ($(jm[get_comp_demand_name(i)])/$(swap_our_param_with_val(i.quantity)))^$(Θ(pf,i)) ) for i in pf.inputs)...)
                )
        )
    else
        ρ = :(($(pf.elasticity)-1)/$(pf.elasticity))
        # ρ = :($(pf.elasticity)-(1/$(pf.elasticity)))
        # println("sub_elas_other")
        # ρ = :(1+1/$(pf.tr_elasticity))
        return :(
            (
                +(
                    $((:( $(Θ(pf,i)) * ($(jm[get_comp_demand_name(i)])/$(i.quantity))^$ρ ) for i in pf.inputs)...)
                    # $((:(($(Θ(pf,i)) + $(replacetheta(jm, i))) * ($(jm[get_comp_demand_name(i)])/$(i.quantity))^$ρ ) for i in pf.inputs)...)
                    # $((:( $(Θy(pf,i)) * ($(jm[get_comp_demand_name(i)])/$(swap_our_param_with_val(i.quantity)))^$ρ ) for i in pf.inputs)...)
                    # $((:( $(Θy(pf,i)) * ($(jm[get_comp_demand_name(i)])/$(get_commodity_benchmark(i.commodity)))^$ρ ) for i in pf.inputs)...)
                    )
            )^(1/$ρ)
        )
    end
end

function y_over_y_bary(jm, pf::Production)
    if eval(swap_our_param_with_val(pf.elasticity))==0
        return :(
            min(
                $(( :( $(jm[get_comp_demand_name(i)])/$(i.quantity) ) for i in pf.inputs)...)
                # $(( :( $(jm[get_comp_demand_name(i)])/$(swap_our_param_with_val(i.quantity))) for i in pf.inputs)...)
            )
        )
    elseif eval(swap_our_param_with_val(pf.elasticity))==1
        return :(
            *(
                $(( :( ($(jm[get_comp_demand_name(i)])/$(i.quantity))^$(Θy(pf,i)) ) for i in pf.inputs)...)
            #    $(( :( ($(jm[get_comp_demand_name(i)])/$(swap_our_param_with_val(i.quantity)))^$(Θ(pf,i)) ) for i in pf.inputs)...)

            )
        )
    else
        ρ = :(($(pf.elasticity)-1)/$(pf.elasticity))
        # ρ = :($(pf.elasticity)-(1/$(pf.elasticity)))
        # ρ = :(1+1/$(pf.tr_elasticity))
        return :(
            (
                +(
                    $((:( $(Θy(pf,i)) * ($(jm[get_comp_demand_name(i)])/$(i.quantity))^$ρ ) for i in pf.inputs)...)
                    # $((:( $(Θy(pf,i)) * ($(jm[get_comp_demand_name(i)])/$(swap_our_param_with_val(i.quantity)))^$ρ ) for i in pf.inputs)...)
                    # $((:( $(Θy(pf,i)) * ($(jm[get_comp_demand_name(i)])/$(get_commodity_benchmark(i.commodity)))^$ρ ) for i in pf.inputs)...)
                    )
            )^(1/$ρ)  # HERE?
        )
    end
end

function create_cost_expr(jm, pf::Production)

    if eval(swap_our_param_with_val(pf.elasticity))==1
            return :(
            *(
                $(
                    (:(
                        ($(get_jump_variable_for_commodity(jm,input.commodity))/$(get_commodity_benchmark(input.commodity))) ^ $(Θ(pf, input))
                    ) for input in pf.inputs)...
                )
            ) * $(y_over_y_bar(jm, pf))
        )
    else 
        # println( :($(Θy(pf, pf.inputs[1]))),
        # :($(Θy(pf, pf.inputs[2]))),
        # :($(get_jump_variable_for_commodity(jm,pf.inputs[1].commodity))),:($(get_commodity_benchmark(pf.inputs[1].commodity))),eval(swap_our_param_with_val(pf.elasticity))),
        #  :($(get_jump_variable_for_commodity(jm,pf.inputs[2].commodity))), :($(get_commodity_benchmark(pf.inputs[2].commodity))),eval(swap_our_param_with_val(pf.elasticity))
        return :(
            (+(
                $(
                    (:(
                        $(Θ(pf, input)) * ($(get_jump_variable_for_commodity(jm,input.commodity))/$(get_commodity_benchmark(input.commodity))) ^ (1-$(pf.elasticity))
                        # ($(Θ(pf,input)) + $(replacetheta(jm, input))) * ($(get_jump_variable_for_commodity(jm,input.commodity))/$(get_commodity_benchmark(input.commodity))) ^ (1-$(pf.elasticity))
                        ) for input in pf.inputs)...
                )
            ))^(1/(1-$(pf.elasticity))) * $(y_over_y_bar(jm, pf))
        )
    end
end

function create_cost_expry(jm, pf::Production)

    if eval(swap_our_param_with_val(pf.elasticity))==1
            return :(
            *(
                $(
                    (:(
                        ($(get_jump_variable_for_commodity(jm,input.commodity))/$(get_commodity_benchmark(input.commodity))) ^ $(Θy(pf, input))
                    ) for input in pf.inputs)...
                )
            ) * $(y_over_y_bary(jm, pf))
        )
    else 
        return :(
            (+(
                $(
                    (:(
                        # $(Θ(pf, input)) * ($(get_jump_variable_for_commodity(jm,input.commodity))/$(get_commodity_benchmark(input.commodity))) ^ (1-$(pf.elasticity))
                        $(Θy(pf, input)) * ($(get_jump_variable_for_commodity(jm,input.commodity))/$(swap_our_param_with_val(input.commodity))) ^ (1-$(pf.elasticity))
                    ) for input in pf.inputs)...
                )
            ))^(1/(1-$(pf.elasticity))) * $(y_over_y_bary(jm, pf))
            # ))^(1/(1-$(pf.elasticity))) * $(y_over_y_bary(jm, pf))
            # ))^($(pf.elasticity)/(1-$(pf.elasticity))) * $(y_over_y_bar(jm, pf))
            # ))^($(pf.elasticity)/(1-$(pf.elasticity))) * $(y_over_y_bary(jm, pf))
            # ))^($(pf.elasticity)-(1/$(pf.elasticity))) * $(y_over_y_bar(jm, pf))
            # ))^($(pf.elasticity)-(1/$(pf.elasticity))) * $(y_over_y_bary(jm, pf))
            # ))^(1/(1+$(pf.elasticity))) * $(y_over_y_bar(jm, pf))
            # ))^(1/(1+$(pf.elasticity))) * $(y_over_y_bary(jm, pf))
            # ))^(1+(1/$(pf.elasticity))) * $(y_over_y_bar(jm, pf))
            # ))^(1+(1/$(pf.elasticity))) * $(y_over_y_bary(jm, pf))
            )
    end
end

function create_rev_expr(jm, pf::Production)
    return :(
        (
            +(
                $(
                    (
                        :(
                            $(Θ(pf, output)) * 
                            ($(get_jump_variable_for_commodity(jm,output.commodity))/$(get_commodity_benchmark(output.commodity)))^(1.0 + $(pf.tr_elasticity)) # should be ((1.0 + $(pf.tr_elasticity)/$(pf.tr_elasticity))?
                            # ($(get_jump_variable_for_commodity(jm,output.commodity))/$(get_commodity_benchmark(output.commodity)))^((1.0 + $(pf.tr_elasticity))/$(pf.tr_elasticity))
                            ) for output in pf.outputs
                    )...
                )
            )
        )^(1.0/(1.0+$(pf.tr_elasticity))) 
        # )^($(pf.tr_elasticity)/(1.0+$(pf.tr_elasticity))) #Should be?
    )
end

function create_rev_expry(jm, pf::Production)
    return :(
        (
            +(
                $(
                    (
                        :(
                            $(Θy(pf, output)) *
                            ($(get_jump_variable_for_commodity(jm,output.commodity))/$(get_commodity_benchmark(output.commodity)))^(1.0 + $(pf.tr_elasticity)) # should be ((1.0 + $(pf.tr_elasticity)/$(pf.tr_elasticity))?
                            # ($(get_jump_variable_for_commodity(jm,output.commodity))/$(get_commodity_benchmark(output.commodity)))^((1.0 + $(pf.tr_elasticity))/$(pf.tr_elasticity)) 
                        ) for output in pf.outputs
                    )...
                )
            )
        )^(1.0/(1.0+$(pf.tr_elasticity))) 
        # )^($(pf.tr_elasticity)/(1.0+$(pf.tr_elasticity))) #Should be $(pf.tr_elasticity)/(1.0+$(pf.tr_elasticity)) ?
    )
end

function create_utility_expr(dm::DemandFunction)
    return :( 
        (
            +(
                $(
                    (
                        :(
                            $( Θ(dm, demand) ) *
                            # TODO #71 Figure out why the commented version doesn't work, it matches paper
                            (
                            $(swap_our_param_with_val(demand.commodity)) # Attempted fix 2022-12-21
                                # $(demand.quantity)  # 71 version
                            #  / $(demand.quantity))  # 71 version
                          /$(get_commodity_benchmark(demand.commodity))) # Attempted fix 2022-12-21
                            ^(($(dm.elasticity)-1)/$(dm.elasticity))
                        ) for demand in dm.demands
                    )...
                )
            )
        )^(
            1 / 
            (
                ($(dm.elasticity)-1) / 
                $(dm.elasticity)
            )
        )
    )
end

function create_expenditure_expr(jm, dm::DemandFunction)
    return :( 
        (
            +(
                $(
                    (
                        :(
                            $(Θ(dm, demand)) *
                            (
                                $(get_jump_variable_for_commodity(jm, demand.commodity)) /
                                $(get_commodity_benchmark(demand.commodity))
                            )^(1-$(dm.elasticity))
                        ) for demand in dm.demands
                    )...
                )
            )
       )^(1/(1-$(dm.elasticity))) *
       $(create_utility_expr(dm))
    )
end

# function replaceinput(jm, input::Input, s)
#     return Symbol(eval(:($(jm[get_comp_demand_name(input)]))))===Symbol("PX†W") ? 109.8379 : input.quantity * eval(swap_our_param_with_val(y_over_y_bar(jm, s)))* eval(swap_our_param_with_val((create_cost_expr(jm, s))) * eval(swap_our_param_with_val(get_commodity_benchmark(input.commodity))) / eval(swap_our_param_with_val(get_jump_variable_for_commodity(jm, input.commodity))))^eval(swap_our_param_with_val(s.elasticity))
#     # input.quantity
# end

# function replacetheta(jm, input::Input)
#     return Symbol(eval(:($(jm[get_comp_demand_name(input)]))))===Symbol("PX†W") ? 0.02380952381 : 0         
#      #, Symbol(eval(:($(jm[get_comp_demand_name(input)]))))===Symbol("PY†W") ? -0.02380952381 : 0
# end

# function replaceinput(jm, ouput::Output)
#     return Symbol(eval(:($(jm[get_comp_supply_name(ouput)]))))===Symbol("PW‡W") ? 0 : 0
# end


function build_implicitconstraints!(m, jm)
    # Add compensated demand (intermediate and factor)
    for s in m._productions
        for input in s.inputs
            if (eval(swap_our_param_with_val(s.elasticity))==1) 
                ex = :(
                        JuMP.@NLexpression(
                            $(jm),
                            $(input.quantity) *
                                $(y_over_y_bary(jm, s)) * # This for tr_elasticity ==0
                        (       
                                    $(create_cost_expr(jm, s)) * $(get_commodity_benchmark(input.commodity)) /
                                $(get_jump_variable_for_commodity(jm, input.commodity))
                        )^$(s.elasticity) - 
                                $(jm[get_comp_demand_name(input)])
                        )
                    )
            # elseif (eval(swap_our_param_with_val(s.elasticity))==0.5) 
            #     println("s.elas", swap_our_param_with_val(:($(s.elasticity))), :($(jm[get_comp_demand_name(input)])), ": ", swap_our_param_with_val(:($(input.quantity))))
            #     ex = :(
            #         JuMP.@NLexpression(
            #             $(jm),
            #             # Symbol(eval(:($(jm[get_comp_demand_name(input)]))))===Symbol("PX†W") ? 109.8379 : 0 #input.quantity * y_over_y_bar(jm, s) * (create_cost_expr(jm, s) * get_commodity_benchmark(input.commodity) / get_jump_variable_for_commodity(jm, input.commodity))^s.elasticity
            #             # $(replaceinput(jm, input, s)) 
            #             # ($(input.quantity) + $(replaceinput(jm, input))) *
            #             # eval(:($(jm[get_comp_demand_name(input)])))===Symbol("PX†W") ? 110 : $(input.quantity)
            #             #  eval(swap_our_param_with_val($(input.quantity)))==100 ? $(input.quantity) : $(input.quantity)
            #             #  eval(swap_our_param_with_val(:($(input.quantity)+10))) : $(input.quantity)
            #             #  :($(jm[get_comp_demand_name(input)]))===Symbol("PX†W") ? 110 : 100 #$(input.quantity)
            #             #  swap_our_param_with_val(:($(input.quantity)+10)) : $(input.quantity)
            #             #   *
            #              $(input.quantity) *
            #                     $(y_over_y_bar(jm, s)) *
            #         (       
            #                     $(create_cost_expr(jm, s)) *
            #             # $(swap_our_param_with_val(input.quantity)) /
            #                     $(get_commodity_benchmark(input.commodity)) /
            #                 $(get_jump_variable_for_commodity(jm, input.commodity))
            #         )^$(s.elasticity) 
            #         - 
            #                 $(jm[get_comp_demand_name(input)])
            #         )
            #     )

            else
                #    println("Dem: s !=1", :($(jm[get_comp_demand_name(input)])))
                println(:($(jm[get_comp_demand_name(input)])), ": ", swap_our_param_with_val(:($(input.quantity))))
            
                ex = :(
                    JuMP.@NLexpression(
                        $(jm),
                        # Symbol(eval(:($(jm[get_comp_demand_name(input)]))))===Symbol("PX†W") ? 109.8379 : 0 #input.quantity * y_over_y_bar(jm, s) * (create_cost_expr(jm, s) * get_commodity_benchmark(input.commodity) / get_jump_variable_for_commodity(jm, input.commodity))^s.elasticity
                        # $(replaceinput(jm, input, s)) 
                        # ($(input.quantity) + $(replaceinput(jm, input))) *
                        # eval(:($(jm[get_comp_demand_name(input)])))===Symbol("PX†W") ? 110 : $(input.quantity)
                        #  eval(swap_our_param_with_val($(input.quantity)))==100 ? $(input.quantity) : $(input.quantity)
                        #  eval(swap_our_param_with_val(:($(input.quantity)+10))) : $(input.quantity)
                        #  :($(jm[get_comp_demand_name(input)]))===Symbol("PX†W") ? 110 : 100 #$(input.quantity)
                        #  swap_our_param_with_val(:($(input.quantity)+10)) : $(input.quantity)
                        #   *
                            $(input.quantity) *
                                $(y_over_y_bar(jm, s)) *
                    (       
                                $(create_cost_expr(jm, s)) *
                        # $(swap_our_param_with_val(input.quantity)) /
                                $(get_commodity_benchmark(input.commodity)) /
                            $(get_jump_variable_for_commodity(jm, input.commodity))
                    )^$(s.elasticity) 
                    - 
                            $(jm[get_comp_demand_name(input)])
                    )
                )
            end
            exb = eval( swap_our_param_with_jump_param(jm, ex) )

            Complementarity.add_complementarity(jm, jm[get_comp_demand_name(input)], exb, string("F_", get_comp_demand_name(input)))    
            push!(m._nlexpressions, exb)
        end
    end

    # Add compensated supply
    for s in m._productions
        for output in s.outputs
            if (eval(swap_our_param_with_val(s.elasticity))==1)
            ex = :(
                JuMP.@NLexpression(
                    $(jm),
                    $(output.quantity) *
                    $(y_over_y_bary(jm, s)) *
                        (
                                                       $(get_jump_variable_for_commodity(jm, output.commodity)) /
                            # $(get_jump_variable_for_commodity(jm, output.commodity)) /
                            # $(create_rev_expr(jm, s)) /
                            # $(get_commodity_benchmark(output.commodity))
                           ( $(create_rev_expry(jm, s)) *
                            
                            $(get_commodity_benchmark(output.commodity)))
                        )^$(s.tr_elasticity) -
                        $(jm[get_comp_supply_name(output)])
                )
            )
            else
                println("Out: s.elas", swap_our_param_with_val(:($(s.elasticity))), :($(jm[get_comp_supply_name(output)])), ": ", swap_our_param_with_val(:($(output.quantity))))
                # println("Supp: s !=1", :($(jm[get_comp_supply_name(output)])))
                ex = :(
                    JuMP.@NLexpression(
                        $(jm),
                        # ($(output.quantity) + $(replaceinput(jm, output))) *
                        $(output.quantity) *
                        $(y_over_y_bar(jm, s)) *
                            (
                                                           $(get_jump_variable_for_commodity(jm, output.commodity)) /
                               ( $(create_rev_expry(jm, s)) *  $(get_commodity_benchmark(output.commodity)))
                            )^$(s.tr_elasticity) -
                            $(jm[get_comp_supply_name(output)])
                    )
                )
            end
            exb = eval( swap_our_param_with_jump_param(jm, ex) )

            Complementarity.add_complementarity(jm, jm[get_comp_supply_name(output)], exb, string("F_", get_comp_supply_name(output)))
            push!(m._nlexpressions, exb)
        end
    end

    # Add final demand
    for demand_function in m._demands
        if eval(swap_our_param_with_val(demand_function.elasticity))==1
            for demand in demand_function.demands
                ex = :(
                    JuMP.@NLexpression(
                        $(jm),
                        # $(swap_our_param_with_val(demand.quantity)) *
                        $(demand.quantity) * 
                        ($(get_jump_variable_for_consumer(jm, demand_function.consumer)) / # (consumer's) income
                        $(swap_our_param_with_jump_param(jm, get_consumer_benchmark(demand_function.consumer)))) * # benchmark income (?)
                        # $(get_consumer_benchmark(demand_function.consumer))) * # benchmark income (?)
                        (
                            $(get_commodity_benchmark(demand.commodity)) / # p__bar_i?
                            $(get_jump_variable_for_commodity(jm, demand.commodity))
                        ) - #p_bar
                        $(jm[get_final_demand_name(demand)])
                    )
                )
                exb = eval( swap_our_param_with_jump_param(jm, ex) )

                Complementarity.add_complementarity(jm, jm[get_final_demand_name(demand)], exb, string("F_", get_final_demand_name(demand)))
                push!(m._nlexpressions, exb)
            end
        elseif eval(swap_our_param_with_val(demand_function.elasticity))==0
            for demand in demand_function.demands
                ex = :(
            JuMP.@NLexpression(
                $(jm),
                # $(swap_our_param_with_val(demand.quantity)) *
                $(demand.quantity) * 
                ($(get_jump_variable_for_consumer(jm, demand_function.consumer)) # (consumer's) income
                /$(get_consumer_benchmark(demand_function.consumer))) # benchmark income (?)
                *
                (       +($( (:($(Θ(demand_function, demand))*$(get_commodity_benchmark(demand.commodity)) ) for demand in demand_function.demands)...))  # sum(demand theta * p__bar_j)?
                   /
                        +($( (:($(Θ(demand_function, demand))*$(get_jump_variable_for_commodity(jm, demand.commodity))) for demand in demand_function.demands)...) ))# sum(demand theta * p_bar
                        - 
                    $(jm[get_final_demand_name(demand)])
                )
            )
            exb = eval( swap_our_param_with_jump_param(jm, ex) )

            Complementarity.add_complementarity(jm, jm[get_final_demand_name(demand)], exb, string("F_", get_final_demand_name(demand)))
            push!(m._nlexpressions, exb)
            end
        else
            for demand in demand_function.demands
                ex = :(
                    JuMP.@NLexpression(
                        $(jm),
                        # $(swap_our_param_with_val(demand.quantity)) *
                        $(demand.quantity) * 
                        (
                            $(get_jump_variable_for_consumer(jm, demand_function.consumer)) / # (consumer's) income
                            $(get_consumer_benchmark(demand_function.consumer)) # benchmark income (?)
                        ) *
                        (
                            $(create_expenditure_expr(jm, demand_function))
                        )^($(demand_function.elasticity)-1) *
                        (
                            $(get_commodity_benchmark(demand.commodity)) / # p__bar_i
                            $(get_jump_variable_for_commodity(jm, demand.commodity))
                        )^$(demand_function.elasticity) - # p_i
                        $(jm[get_final_demand_name(demand)])
                    )
                )
                exb = eval( swap_our_param_with_jump_param(jm, ex) )

                Complementarity.add_complementarity(jm, jm[get_final_demand_name(demand)], exb, string("F_", get_final_demand_name(demand)))
                push!(m._nlexpressions, exb)
            end
        end
    end
end
