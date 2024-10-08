###########################
## Create JuMP Variables ##
###########################
function add_variable!(m::MPSGEModel, S::MPSGEScalarVariable; start = 1)
    jm = jump_model(m)
    jm[name(S)] = @variable(jm,base_name = string(name(S)),start=start, lower_bound = 0)
end




function add_variable!(m::MPSGEModel, S::MPSGEIndexedVariable; start = 1)

    jm = jump_model(m)
    index = S.index

    dim = length.(index)
    
    x = JuMP.@variable(jm, [1:prod(dim)], lower_bound=0, start = start)

    for (i, ind) in enumerate(Iterators.product(index...))
        new_index = join(ind,",")
        JuMP.set_name(x[i], "$(name(S))[$new_index]")
    end

    output = JuMP.Containers.DenseAxisArray(reshape(x, Tuple(dim)), index...)
    jm[name(S)] = output
    return output

end

function add_variable!(m::MPSGEModel, S::Auxiliary)
    add_variable!(m, S; start = 0)
end

########################
## Compensated Demand ##
########################

function compensated_demands(S::ScalarSector)
    P = production(S)
    return P.compensated_demands
end

function netput_dict(S::ScalarSector)
    P = production(S)
    return P.netputs
end

# This should be rewritten. It finds all the parent
# names of the given netput. 
function parent_name_chain(N::MPSGE.Netput)
    found_parents = deepcopy(N.parents) #temporary?
    parent_names = []
    #print(found_parents)
    while !isempty(found_parents)
        n = pop!(found_parents)
        if name(n)∉parent_names
            push!(parent_names, MPSGE.name(n))
        end
        if !isnothing(MPSGE.parent(n))
            push!(found_parents, MPSGE.parent(n))
        end
    end
    return parent_names
end

function compensated_demand(S::ScalarSector, C::ScalarCommodity, nest::Symbol)
    cd = MPSGE.compensated_demands(S)
    all_netputs = MPSGE.netput_dict(S)
    if !haskey(all_netputs, C)
        return 0
    end
    netputs = [n for n∈all_netputs[C] if nest∈parent_name_chain(n)]

    return sum(sum(cd[netput]) for netput∈netputs)

end

function compensated_demand(S::ScalarSector,C::ScalarCommodity)
    cd = compensated_demands(S)
    netputs = netput_dict(S)
    if !haskey(netputs, C)
        return 0
    end
    sum(sum(cd[netput]) for netput∈netputs[C])
    #sum(sum(v) for (netput, v)∈cd if commodity(netput) == C; init = 0)
end


taxes(N::Netput, H::ScalarConsumer) = [-N.netput_sign*tax(t) for t∈taxes(N) if tax_agent(t) == H]

function total_tax(S::ScalarSector, C::ScalarCommodity, H::ScalarConsumer)
    P = production(S)
    return sum(Iterators.flatten(taxes.(P.netputs[C], Ref(H))); init = 0)
end

function total_tax(N::Netput, H::ScalarConsumer)
    sum(taxes(N, H); init=0)
end

#temporary fix
function tau(S::ScalarSector,H::ScalarConsumer)
    P = production(S)
    #jm = jump_model(model(S))
    -sum( sum(compensated_demands) * total_tax(netput, H) * commodity(netput) for (netput, compensated_demands)∈P.compensated_demands if total_tax(netput,H)!=0; init=0)
end


########################
## Demands/Endowments ##
########################

function demand(H::Consumer)
    D = demands(model(H))
    return D[H]
end

function endowment(H::Consumer, C::Commodity)
    D = demand(H)
    endows = endowments(D)
    if !haskey(endows,C) || length(endows[C])==0
        return 0
    else
        return sum(quantity.(endows[C]))
    end
end

function demand(H::Consumer, C::Commodity)
    jm = jump_model(model(H))
    D = demand(H)
    total_quantity = quantity(D)
    Final_Demands = final_demands(D)
    if !haskey(Final_Demands, C) || length(Final_Demands[C])==0
        return 0
    end
    DF = Final_Demands[C]

    total_income = []
    for d in DF
        if !(isa(elasticity(D), Real))
            income =  @expression(jm, 
                quantity(d)/total_quantity * H/C * ifelse(1*elasticity(D) == 1, 1, (expenditure(D)*reference_price(d)/C)^(elasticity(D)-1))
            )
        elseif elasticity(D) == 1
            income = quantity(d)/total_quantity * H/C
        else 
            income = quantity(d)/total_quantity * H/C * (expenditure(D)*reference_price(d)/C)^(elasticity(D)-1)
        end

        push!(total_income, income)
    end

    return sum(total_income)
end


function expenditure(D::ScalarDemand)
    jm = jump_model(model(consumer(D)))
    total_quantity = quantity(D)
    σ = elasticity(D)
    return @expression(jm, sum( quantity(d)/total_quantity * (get_variable(commodity(d))/reference_price(d))^(1-σ) for (_,DF)∈final_demands(D) for d∈DF)^(1/(1-σ)))
end

#################
## Constraints ##
#################

function zero_profit(S::ScalarSector)
    M = model(S)
    jm = jump_model(M)
    @expression(jm, sum(compensated_demand(S,C)*get_variable(C) for C∈commodities(S)) - sum(tau(S,H) for H∈consumers(M) if tau(S,H)!=0; init=0))
end

function market_clearance(C::ScalarCommodity)
    M = model(C)
    jm = jump_model(M)
    @expression(jm, -sum(compensated_demand(S,C) * get_variable(S) for S∈sectors(C);init=0) + sum( endowment(H,C) - demand(H,C) for H∈consumers(M); init=0))
end

function income_balance(H::ScalarConsumer)
    M = model(H)
    jm = jump_model(M)
    @expression(jm, get_variable(H) - (sum(get_variable(endowment(H,C))* get_variable(C) for C∈commodities(M) if endowment(H,C)!=0) - sum(tau(S,H)*S for S∈production_sectors(M) if tau(S,H)!=0; init=0)))
end



function build_constraints!(M::MPSGEModel)
    jm = jump_model(M)

    JuMP.@constraint(jm, zero_profit[S = MPSGE.production_sectors(M)],
        MPSGE.zero_profit(S) ⟂ get_variable(S)
    )
    
    JuMP.@constraint(jm, market_clearance[C = MPSGE.commodities(M)],
        MPSGE.market_clearance(C) ⟂ get_variable(C)
    )
    
    JuMP.@constraint(jm, income_balance[H = MPSGE.consumers(M)],
        MPSGE.income_balance(H) ⟂ get_variable(H)
    )

    aux_cons = aux_constraints(M)

    @constraint(jm, auxiliary_constraints[A∈keys(aux_cons)],
        constraint(aux_cons[A]) ⟂ get_variable(A)
    )

end


function consumer_income(consumer)
    m = model(consumer)
    jm = jump_model(m)
    
    if termination_status(jm) == OPTIMIZE_NOT_CALLED
        new_start = sum(
            raw_quantity(
                start_value, 
                endowment
            ) 
            for (_,E)∈endowments(demand(consumer)) for endowment∈E; init=0
        )
        new_start += -value(
            start_value, 
            sum(tau(sector, consumer) for sector in production_sectors(m); init = 0)
        )
    else
        __value_function(x) = is_fixed(x) ? fix_value(x) : value(x)
        new_start = sum(raw_quantity(__value_function, e) for (_,E)∈endowments(demand(consumer)) for e∈E; init=0)
        new_start += -value(
            __value_function,
            sum(tau(sector, consumer) for sector in production_sectors(m); init=0)
        )
    end
    return new_start
end


"""
    solve!(m::abstract_mpsge_model; keywords)
    Function to solve the model. Triggers the build if the model hasn't been built yet.
### Example
```julia-repl
julia> solve!(m, cumulative_iteration_limit=0)
```
"""
function solve!(m::AbstractMPSGEModel; kwargs...)
    jm = jump_model(m)

    

    if !haskey(JuMP.object_dictionary(jm), :zero_profit)
        build_constraints!(m)
    end


    #Set the default iteration limit to 10_000
    JuMP.set_attribute(jm, "cumulative_iteration_limit", 10_000)


    for (k,v) in kwargs
        JuMP.set_attribute(jm, string(k), v)
    end

    consumer = nothing
    # Check if any (non-auxiliary) variables are fixed. If not, set numeraire
    if sum(is_fixed.(MPSGE.production_sectors(m))) + sum(is_fixed.(commodities(m))) + sum(is_fixed.(consumers(m))) == 0 
        consumer = argmax(consumer_income, consumers(m))
        fix(consumer, consumer_income(consumer))
    end

    JuMP.optimize!(jm)

    # Need to check termination status here

    if !isnothing(consumer)
        unfix(consumer)
    end

    if !m.silent
        output = "\n\nSolver Status: $(termination_status(jm))\nModel Status: $(primal_status(jm))"

        if !isnothing(consumer)
            output *= "\n\nDefault price normalization using income for $consumer as numeraire, with the value of $(value(consumer)).\n"
        end
        print(output)
    end
end