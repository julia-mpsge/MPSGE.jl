

########################
## Compensated Demand ##
########################

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
        if name(n) ∉ parent_names
            push!(parent_names, MPSGE.name(n))
        end
        if !isnothing(MPSGE.parent(n))
            push!(found_parents, MPSGE.parent(n))
        end
    end
    return parent_names
end

function compensated_demand(N::MPSGE.Netput; virtual=false)
    child, parent = N, MPSGE.parent(N)[1]
    sign = -MPSGE.netput_sign(N)
    compensated_demand = sign * MPSGE.base_quantity(N)
    v = virtual ? :virtual : :full
    while !isnothing(parent)
        if MPSGE.elasticity(parent) != 0
            compensated_demand *= (cost_function(parent; virtual=v) / cost_function(child; virtual=v))^(sign * MPSGE.elasticity(parent))
        end
        child, parent = parent, MPSGE.parent(parent)
    end
    return compensated_demand
end

function compensated_demand(S::ScalarSector, C::ScalarCommodity; virtual=false)
    return sum(compensated_demand.(netputs(S, C); virtual=virtual); init=0)
end

function compensated_demand(S::ScalarSector, C::ScalarCommodity, nest::Symbol; virtual=false)
    N = [n for n ∈ netputs(S, C) if nest ∈ parent_name_chain(n)]
    return sum(compensated_demand.(N, virtual=virtual); init=0)
end


taxes(N::Netput, H::ScalarConsumer) = [-N.netput_sign * tax(t) for t ∈ taxes(N) if tax_agent(t) == H]

function total_tax(S::ScalarSector, C::ScalarCommodity, H::ScalarConsumer)
    P = production(S)
    return sum(Iterators.flatten(taxes.(P.netputs[C], Ref(H))); init=0)
end

function total_tax(N::Netput, H::ScalarConsumer)
    sum(taxes(N, H); init=0)
end


function tax_revenue(S::ScalarSector, H::ScalarConsumer; virtual=false)
    jm = jump_model(model(S))
    return @expression(jm, -sum(compensated_demand(N, virtual=virtual) * total_tax(N, H) * get_variable(S) * get_variable(commodity(N)) for N ∈ taxes(S, H); init=0))
end

########################
## Demands/Endowments ##
########################
function is_endowment(H, C)
    endows = endowments(demand(H))
    return haskey(endows, C) && length(endows[C]) != 0

end

function is_demand(H, C)
    D = demand(H)
    Final_Demands = final_demands(D)
    return haskey(Final_Demands, C) && !isempty(Final_Demands[C])
end



function demand(H::Consumer)
    D = demand_dict(model(H))
    return D[H]
end

function endowment(H::Consumer, C::Commodity)
    if !is_endowment(H, C)
        return 0
    else
        D = demand(H)
        endows = endowments(D)
        return sum(quantity.(endows[C]))
    end
end

function demand(H::Consumer, C::Commodity)
    if !is_demand(H, C)
        return 0
    end
    jm = jump_model(model(H))
    D = demand(H)
    total_quantity = quantity(D)
    Final_Demands = final_demands(D)
    DF = Final_Demands[C]

    total_income = []
    for d in DF
        if !(isa(elasticity(D), Real))
            income = @expression(jm,
                quantity(d) / total_quantity * H / C * ifelse(1 * elasticity(D) == 1, 1, (expenditure(D) * reference_price(d) / C)^(elasticity(D) - 1))
            )
        elseif elasticity(D) == 1
            income = quantity(d) / total_quantity * H / C
        else
            income = quantity(d) / total_quantity * H / C * (expenditure(D) * reference_price(d) / C)^(elasticity(D) - 1)
        end

        push!(total_income, income)
    end

    return sum(total_income; init=0)
end


function expenditure(D::ScalarDemand)
    jm = jump_model(model(consumer(D)))
    total_quantity = quantity(D)
    σ = elasticity(D)
    return @expression(jm, sum(quantity(d) / total_quantity * (get_variable(commodity(d)) / reference_price(d))^(1 - σ) for (_, DF) ∈ final_demands(D) for d ∈ DF)^(1 / (1 - σ)))
end

#################
## Constraints ##
#################


function zero_profit(S::MPSGE.ScalarSector; virtual=false)
    M = model(S)
    jm = jump_model(M)
    @expression(jm, cost_function(S; virtual=virtual) - revenue_function(S; virtual=virtual))
end

function market_clearance(C::ScalarCommodity; virtual=false)
    M = model(C)
    jm = jump_model(M)
    @expression(jm, -sum(compensated_demand(S, C; virtual=virtual) * get_variable(S) for S ∈ sectors(C); init=0) + sum(endowment(H, C) for H ∈ endowments(C); init=0) - sum(demand(H, C) for H ∈ final_demands(C); init=0))
end

function income_balance(H::ScalarConsumer; virtual=false)
    M = model(H)
    jm = jump_model(M)
    household_commodities = [C for C ∈ commodities(M) if H ∈ MPSGE.endowments(C)]

    @expression(jm, get_variable(H) - (sum(get_variable(endowment(H, C)) * get_variable(C) for C ∈ household_commodities) - sum(tax_revenue(S, H; virtual=virtual) for S ∈ production_sectors(M); init=0)))
end



function build_constraints!(M::MPSGEModel)
    jm = jump_model(M)

    JuMP.@constraint(jm, z_p[S=MPSGE.production_sectors(M)],
        MPSGE.zero_profit(S; virtual=true) ⟂ get_variable(S)
    )

    JuMP.@constraint(jm, m_c[C=MPSGE.commodities(M)],
        MPSGE.market_clearance(C; virtual=true) ⟂ get_variable(C)
    )

    JuMP.@constraint(jm, i_b[H=MPSGE.demand_consumers(M)],
        MPSGE.income_balance(H; virtual=true) ⟂ get_variable(H)
    )

    aux_cons = aux_constraints(M)

    @constraint(jm, a_c[A ∈ keys(aux_cons)],
        constraint(aux_cons[A]) ⟂ get_variable(A)
    )

end


function consumer_income(consumer::ScalarConsumer)
    M = model(consumer)
    jm = jump_model(M)
    household_commodities = [C for C ∈ commodities(M) if consumer ∈ MPSGE.endowments(C)]

    value_function = ifelse(
        termination_status(jm) == OPTIMIZE_NOT_CALLED,
        start_value,
        x -> is_fixed(x) ? fix_value(x) : value(x)
    )

    return sum(value(value_function, get_variable(endowment(consumer, C)) * get_variable(C)) for C ∈ household_commodities; init=0) - sum(value(value_function, tax_revenue(S, consumer; virtual=true)) for S ∈ production_sectors(M); init=0)
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

    if !haskey(JuMP.object_dictionary(jm), :z_p)
        build_constraints!(m)
    end

    #Set the default iteration limit to 10_000
    JuMP.set_attribute(jm, "cumulative_iteration_limit", 10_000)


    for (k, v) in kwargs
        JuMP.set_attribute(jm, string(k), v)
    end

    consumer = nothing
    # Check if any (non-auxiliary) variables are fixed. If not, set numeraire
    if sum(is_fixed.(MPSGE.production_sectors(m))) + sum(is_fixed.(commodities(m))) + sum(is_fixed.(consumers(m))) == 0
        consumer = argmax(consumer_income, demand_consumers(m))
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