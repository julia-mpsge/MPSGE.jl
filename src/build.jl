function find_levels(T::ScalarNest)
    current_children = Any[[T]]

    out = []
    while current_children != Any[]
        level = popfirst!(current_children)
        push!(current_children,[])
        push!(out,[])
        for T∈level
            push!(out[end],T)
            append!(current_children[end], children(T))
        end
        if current_children[end] == []
            pop!(current_children)
        end
    end

    return out
end


function build_nested_compensated_demand!(P::ScalarProduction)
    for level in reverse(find_levels(P.input))
        for T in level
            P.nested_compensated_demand[T,parent(T)] = build_nested_compensated_demand(P,T,-1)
        end
    end 

    for level in reverse(find_levels(P.output))
        for T in level
            P.nested_compensated_demand[T,parent(T)] = build_nested_compensated_demand(P,T,1)
        end
    end

end

function build_nested_compensated_demand(P::ScalarProduction,T::ScalarNest, sign::Int)
    if T.elasticity == 1
        return cobb_douglass(P,T,sign)
    else
        return CES(P,T,sign)
    end
end

function build_nested_compensated_demand(P::ScalarProduction,T::ScalarNetput, sign::Int)
    return get_variable(T.commodity)*(1 - sign*sum(tax.tax for tax in T.taxes; init=0))/T.reference_price
end

function cobb_douglass(P::ScalarProduction, T::ScalarNest, sign)
    return prod(P.nested_compensated_demand[child,T]^(quantity(child)/quantity(T)) for child in T.children; init=1)
end

function CES(P::ScalarProduction, T::ScalarNest, sign::Int)
    return sum(quantity(child)/quantity(T) * P.nested_compensated_demand[child,T]^(1+sign*T.elasticity) for child in T.children; init=0) ^ (1/(1+sign*T.elasticity))
end


function build_compensated_demand!(P::ScalarProduction)

    build_nested_compensated_demand!(P)

    prod_commodities = ScalarNetput[e for level∈find_levels(P.input) for e∈level if e isa ScalarNetput]
    append!(prod_commodities,[e for level∈find_levels(P.output) for e∈level if e isa ScalarNetput])

    #T = prod_commodities[1]
    for T∈prod_commodities
        commodity = T.commodity
        nest = name(parent(T))

        sign = T isa ScalarInput ? -1 : 1

        #build taxes
        for tax in taxes(T)
            H = tax.agent
            if H∉keys(P.taxes)
                P.taxes[H] = Dict()
            end
            P.taxes[H][commodity,nest] = -sign*tax.tax #Should be a sum
        end

        if commodity ∉ keys(P.compensated_demand)
            P.compensated_demand[commodity] = Dict()
        end

        quantity = base_quantity(T)

        #build a vector of 2-tuples chaining from the leaf to the root
        nest_list = []
        while T != parent(T)
            push!(nest_list, (T,parent(T)))
            T = parent(T)
        end
        P.compensated_demand[commodity][nest] = -sign * quantity * prod((P.nested_compensated_demand[parent_T,parent(parent_T)]/P.nested_compensated_demand[T,parent(T)])^(-sign*parent_T.elasticity) for (T,parent_T)∈nest_list  if parent_T.elasticity!=0; init = 1)
    end
end

function build_compensated_demands!(M::MPSGEModel)
    for (_,P) ∈ M.productions
        build_compensated_demand!(P)
    end
end

function build_commodity_dictionary!(M::MPSGEModel)
    M.commodities = Dict(C=>[] for C∈commodities(M))
    for S∈keys(M.productions)#sectors(M)
        for C∈commodities(S)
            push!(M.commodities[C],S)
        end
    end
end


function compensated_demand_dictionary(X::Sector)
    P = production(X)
    return P.compensated_demand
end


function compensated_demand_dictionary(X::Sector,C::Commodity)
    P = compensated_demand_dictionary(X)
    return get(P, C, Dict())
end

function compensated_demand(X::Sector,C::Commodity, n::Symbol)
    P = compensated_demand_dictionary(X,C)
    return get(P, n, 0)
end

@inline compensated_demand(X::Sector,C::Commodity) = sum(e for (_,e)∈compensated_demand_dictionary(X,C); init=0)

function tau(X::Sector,H::Consumer)
    Taxes = taxes(X,H)
    return -sum( compensated_demand(X,C,n)* tax * get_variable(C) for ((C,n),tax)∈Taxes; init=0)
end



########################
## Demands/Endowments ##
########################

function demand(H::Consumer)
    M = H.model
    return M.demands[H]
end

function endowment(H::Consumer, C::Commodity)
    D = demand(H)
    if !haskey(D.endowments,C)
        return 0
    else
        return D.endowments[C].quantity
    end
end

function demand(H::Consumer, C::Commodity)
    D = demand(H)
    total_quantity = D.quantity
    if !haskey(D.demands, C)
        return 0
    end
    d = D.demands[C]
    return d.quantity/total_quantity * get_variable(H)/get_variable(C)
end

###########################
## Create JuMP Variables ##
###########################
function add_variable!(m::MPSGEModel, S::MPSGEScalarVariable)
    jm = jump_model(m)
    jm[name(S)] = @variable(jm,base_name = string(name(S)),start=1)
end

function add_variable!(m::MPSGEModel, S::MPSGEIndexedVariable)

    jm = jump_model(m)
    index = S.index

    dim = length.(index)
    
    x = JuMP.@variable(jm, [1:prod(dim)], lower_bound=0, start = 1)

    for (i, ind) in enumerate(Iterators.product(index...))
        new_index = join(ind,",")
        JuMP.set_name(x[i], "$(name(S))[$new_index]")
    end

    output = JuMP.Containers.DenseAxisArray(reshape(x, Tuple(dim)), index...)
    jm[name(S)] = output
    return output

end



"""
    build!(M::MPSGEModel)

Currently, I'm creating the variables when the sector is added to the
model. However, I *think* we can do this here without issue. I would
prefer doing it here.
"""
function build!(M::MPSGEModel)
    M.jump_model = JuMP.Model(PATHSolver.Optimizer)

    for (_,V) in object_dict(M)
        add_variable!(M, V)
    end

    #Need to set start values of demands
    # This needs to be more elegant
    for (consumer,d) in M.demands
        var = get_variable(consumer)
        set_start_value(var, d.quantity)
    end


    build_compensated_demands!(M)
    build_commodity_dictionary!(M)
    build_constraints!(M)

    return jump_model(M)
end


function build_constraints!(M::MPSGEModel)

    jm = jump_model(M)

    # sectors(M) may not be correct here. You really want the production blocks. 
    # Conversely, every sector *should* have a production block. 
    @constraint(jm, zero_profit[S = sectors(M)],
        -sum(compensated_demand(S,C) * get_variable(C) for C∈commodities(S) if compensated_demand(S,C)!=0; init=0)  +   sum(tau(S,H) for H∈consumers(M) if tau(S,H)!=0; init=0) ⟂ get_variable(S)
    )

    @constraint(jm, market_clearance[C = commodities(M)],
        sum(compensated_demand(S,C) * get_variable(S) for S∈sectors(C)) - sum( endowment(H,C) - demand(H,C) for H∈consumers(M)) ⟂ get_variable(C)
    )

    @constraint(jm, income_balance[H = consumers(M)],
        get_variable(H) - (sum(endowment(H,C)*get_variable(C) for C∈commodities(M) if endowment(H,C)!=0) - sum(tau(S,H)*get_variable(S) for S∈sectors(M) if tau(S,H)!=0; init=0)) ⟂ get_variable(H)
    );

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
    if jm===nothing
        jm = build!(m)
    end

    JuMP.set_optimizer(jm, PATHSolver.Optimizer)

    for (k,v) in kwargs
        JuMP.set_attribute(jm, string(k), v)
    end

    JuMP.optimize!(jm)

    #return m
end