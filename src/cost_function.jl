function cobb_douglass(N::Node; virtual = :full, cf = cost_function, sector = nothing)
    sign = netput_sign(N)
    return prod(cf(child; virtual = virtual, sector = sector)^(quantity(child)/quantity(N)) for child in children(N); init=1)
end

function CES(N::Node; virtual = :full,  cf = cost_function, sector = nothing)
    sign = netput_sign(N)
    return sum(quantity(child)/quantity(N) * cf(child; virtual = virtual, sector = sector)^(1+sign*elasticity(N)) for child in children(N); init=0) ^ (1/(1+sign*elasticity(N)))
end




#cost_function(N::Node; virtual = false) = !virtual ? N.cost_function : N.cost_function_virtual

function cost_function(N::MPSGE.Netput; virtual = false, sector = nothing)
    C = commodity(N)
    sign = MPSGE.netput_sign(N)
    rp = MPSGE.reference_price(N)
    return C*(1-sign*sum(MPSGE.tax(t) for t∈taxes(N);init = 0))/rp
end


function cost_function(N::MPSGE.Node; virtual = :full, cf = cost_function, sector = nothing)

    @assert virtual in [:full, :virtual, :partial] "virtual must be one of :full, :virtual, or :partial"

    if virtual == :virtual
        return N.cost_function_virtual
    end

    virtual_adjust = if virtual == :partial
        :virtual
    else
        :full
    end

    sign = MPSGE.netput_sign(N)
    if !(isa(MPSGE.elasticity(N), Real))

        jm = jump_model(model(N))

        #This must be an explicit expression, otherwise it's evaluated now. 
        cost_function = @expression(jm, ifelse(
                    MPSGE.elasticity(N) * sign == -1,
                    cobb_douglass(N, virtual = virtual_adjust, cf = cf), 
                    CES(N, virtual = virtual_adjust, cf = cf)
                ))
    elseif MPSGE.elasticity(N)*sign == -1 #Cobb-Douglas is only on demand side with σ=1
        cost_function = cobb_douglass(N; virtual = virtual_adjust, cf = cf, sector = sector)
    else
        cost_function = CES(N; virtual = virtual_adjust, cf = cf, sector = sector)
    end

    return cost_function

end

function cost_function(P::ScalarProduction, nest::Symbol; virtual = false, search = :all)
    N = find_nodes(P; search = search)
    if haskey(N, nest)
        v = virtual ? :virtual : :full
        return sum(quantity.(N[nest]).*cost_function.(N[nest]; virtual = v))
    end
    return 0
end

"""
    cost_function(S::ScalarSector; virtual = false)
    cost_function(S::ScalarSector, nest::Symbol; virtual = false)
    
Return a vector of cost functions for the given sector and nest. If `nest` is 
not provided return the cost function for input tree. 

`nest` is the symbol representing the nest. This can also be the name of a 
commodity. 

If `virtual` is true, return the virtual cost functions.
"""
cost_function(P::ScalarProduction; virtual=false) = cost_function(P, name(input(P)), virtual=virtual)
cost_function(S::ScalarSector, nest::Symbol; virtual = false) = cost_function(production(S), nest, virtual=virtual, search = :input)
cost_function(S::ScalarSector; virtual = false) = cost_function(production(S), virtual=virtual)


"""
    revenue_function(S::ScalarSector; virtual = false)    
    revenue_function(S::ScalarSector, nest::Symbol; virtual = false)
    
Return a vector of revenue functions for the given sector and nest. If `nest` is 
not provided return the revenue function for input tree. 

`nest` is the symbol representing the nest. This can also be the name of a 
commodity. 

If `virtual` is true, return the virtual revenue functions.

"""
revenue_function(P::ScalarProduction; virtual = false) = cost_function(P, name(output(P)), virtual = virtual, search = :output)
revenue_function(S::ScalarSector, nest::Symbol; virtual = false) = cost_function(production(S), nest, virtual = virtual, search = :output)
revenue_function(S::ScalarSector; virtual = false) = revenue_function(production(S); virtual = virtual)


#############################
## Building Cost Functions ##
#############################





function build_cost_function(tree::Netput; virtual = :full, sector = nothing)
    return cost_function(tree)
end

function build_cost_function(N::Node; virtual = :full, sector = nothing)

    # If the cost function exists, return it
    if !isnothing(N.cost_function_virtual)
        return MPSGE.cost_function(N, virtual = :virtual)
    end

    cost_function = MPSGE.cost_function(N; virtual = :partial, cf = MPSGE.build_cost_function, sector = sector)

    if isnothing(N.cost_function_virtual)
        jm = jump_model(model(N))
        name = string("cf(", sector, ", :", MPSGE.name(N), ")")
        N.cost_function_virtual = @variable(jm, start = value(start_value, cost_function), base_name = name) 
        N.cost_function = cost_function
        @constraint(jm, N.cost_function_virtual - cost_function ⟂ N.cost_function_virtual)
    end

    return N.cost_function_virtual
end
