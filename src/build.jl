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

#Can be greatly simplified
function build_nested_compensated_demand!(P::ScalarProduction)
    for level in reverse(find_levels(input(P)))
        for T in level
            P.nested_compensated_demand[name(T),parent(T)] = build_nested_compensated_demand(P,T,-1)
        end
    end 

    for level in reverse(find_levels(output(P)))
        for T in level
            P.nested_compensated_demand[name(T),parent(T)] = build_nested_compensated_demand(P,T,1)
        end
    end

end

function build_nested_compensated_demand(P::ScalarProduction,T::ScalarNest, sign::Int)
    if !(isa(raw_elasticity(T), Real))

        jm = jump_model(model(sector(P)))

        #This must be an explicit expression, otherwise it's evaluated now. 
        return @expression(jm, JuMP.op_ifelse(
                    elasticity(T) * sign == -1,
                    cobb_douglass(P,T,sign), 
                    CES(P,T,sign)
                ))
    end

    if elasticity(T)*sign == -1 #Cobb-Douglas is only on demand side with σ=1
        return cobb_douglass(P,T,sign)
    else
        return CES(P,T,sign)
    end
end

function build_nested_compensated_demand(P::ScalarProduction,T::ScalarNetput, sign::Int)
    return get_variable(commodity(T))*(1 - sign*sum(tax(t) for t in taxes(T); init=0))/reference_price(T)
end

function cobb_douglass(P::ScalarProduction, T::ScalarNest, sign)
    return prod(P.nested_compensated_demand[name(child),name(T)]^(quantity(child)/quantity(T)) for child in children(T); init=1)
end

function CES(P::ScalarProduction, T::ScalarNest, sign::Int)
    return sum(quantity(child)/quantity(T) * P.nested_compensated_demand[name(child),name(T)]^(1+sign*elasticity(T)) for child in children(T); init=0) ^ (1/(1+sign*elasticity(T)))
end

#Needs a major refactor
function build_compensated_demand!(P::ScalarProduction)

    build_nested_compensated_demand!(P)

    prod_commodities = ScalarNetput[e for level∈find_levels(input(P)) for e∈level if e isa ScalarNetput]
    append!(prod_commodities,[e for level∈find_levels(output(P)) for e∈level if e isa ScalarNetput])

    #prod_commodities = commodity_netputs(P) #not exactly what I want ...

    #T = prod_commodities[1]
    for T∈prod_commodities
        C = commodity(T)
        nest = parent(T)

        sign = T isa ScalarInput ? -1 : 1

        #build taxes
        for t in taxes(T)
            H = tax_agent(t)
            if H∉keys(P.taxes)
                P.taxes[H] = Dict()
            end
            P.taxes[H][C,nest] = -sign*tax(t) #Should be a sum
        end

        if C ∉ keys(P.compensated_demand)
            P.compensated_demand[C] = Dict()
        end

        quantity = base_quantity(T)

        #build a vector of 2-tuples chaining from the leaf to the root
        nest_list = []
        while name(T) != name(parent(P,T))
            push!(nest_list, (T,parent(P,T)))
            T = parent(P,T)
        end
        P.compensated_demand[C][nest] = -sign * quantity * prod((P.nested_compensated_demand[name(parent_T), parent(parent_T)]/P.nested_compensated_demand[name(T),parent(T)])^(-sign*elasticity(parent_T)) for (T,parent_T)∈nest_list  if elasticity(parent_T)!=0; init = 1)
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
    D = demands(model(H))
    return D[H]
end

function endowment(H::Consumer, C::Commodity)
    D = demand(H)
    endows = endowments(D)
    if !haskey(endows,C)
        return 0
    else
        return quantity(endows[C])
    end
end

function demand(H::Consumer, C::Commodity)
    D = demand(H)
    total_quantity = quantity(D)
    if !haskey(D.demands, C)
        return 0
    end
    d = D.demands[C]
    return quantity(d)/total_quantity * get_variable(H)/get_variable(C) * ifelse(elasticity(D) != 1, (expenditure(D)*reference_price(d)/get_variable(C))^(elasticity(D)-1), 1)
end


function expenditure(D::ScalarDemand)
    total_quantity = quantity(D)
    σ = elasticity(D)
    return sum( quantity(d)/total_quantity * (get_variable(commodity(d))/reference_price(d))^(1-σ) for (_,d)∈demands(D))^(1/(1-σ))
end

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


"""
    build!(M::MPSGEModel)

"""
function build!(M::MPSGEModel)
    M.jump_model = JuMP.Model(PATHSolver.Optimizer)

    for (_,V) in object_dict(M) #Want IndexedVariables... Can be smarter
        add_variable!(M, V)
    end

    #Need to set start values of demands
    # This needs to be more elegant
    for (consumer,d) in M.demands
        var = get_variable(consumer)
        set_start_value(var, raw_quantity(d))
    end

    #Need to fix all parameter variables
    for P∈parameters(M)
        fix(P,value(P))
    end

    prune!(M)
    build_compensated_demands!(M)
    build_commodity_dictionary!(M)
    build_constraints!(M)




    return jump_model(M)
end


function build_constraints!(M::MPSGEModel)

    jm = jump_model(M)

    @constraint(jm, zero_profit[S = production_sectors(M)],
        sum(compensated_demand(S,C) * get_variable(C) for C∈commodities(S) if compensated_demand(S,C)!=0; init=0)  -   sum(tau(S,H) for H∈consumers(M) if tau(S,H)!=0; init=0) ⟂ get_variable(S)
    )

    @constraint(jm, market_clearance[C = commodities(M)],
        sum(compensated_demand(S,C) * get_variable(S) for S∈sectors(C)) - sum( endowment(H,C) - demand(H,C) for H∈consumers(M)) ⟂ get_variable(C)
    )

    @constraint(jm, income_balance[H = consumers(M)],
        get_variable(H) - (sum(endowment(H,C)*get_variable(C) for C∈commodities(M) if endowment(H,C)!=0) - sum(tau(S,H)*get_variable(S) for S∈production_sectors(M) if tau(S,H)!=0; init=0)) ⟂ get_variable(H)
    );

    aux_cons = aux_constraints(M)

    @constraint(jm, auxiliary_constraints[A∈keys(aux_cons)],
        constraint(aux_cons[A]) ⟂ get_variable(A)
    )


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