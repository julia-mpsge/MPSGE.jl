function cobb_douglas(N::MPSGE.Node; depth = -1)
    sign = MPSGE.netput_sign(N)
    return prod(unit_cost_function(child; depth = depth)^(quantity(child)/quantity(N)) for child in MPSGE.children(N); init=1)
end

function CES(N::MPSGE.Node; depth = -1)
    sign = MPSGE.netput_sign(N)
    return sum(quantity(child)/quantity(N) * unit_cost_function(child; depth = depth)^(1+sign*elasticity(N)) for child in MPSGE.children(N); init=0) ^ (1/(1+sign*elasticity(N)))
end


function unit_cost_function(N::MPSGE.Netput; depth = -1)
    C = commodity(N)
    sign = netput_sign(N)
    rp = reference_price(N)
    return C*(1-sign*sum(tax(t) for t∈taxes(N);init = 0))/rp
end

function unit_cost_function(N::MPSGE.Node; depth = -1)
    if depth == 0
        return N.cost_function_virtual
    end

    sign = MPSGE.netput_sign(N)
    if !(isa(MPSGE.elasticity(N), Real))

        jm = jump_model(model(N))

        #This must be an explicit expression, otherwise it's evaluated now. 
        cost_function = @expression(jm, ifelse(
                    MPSGE.elasticity(N) * sign == -1,
                    cobb_douglas(N; depth = depth-1), 
                    CES(N; depth = depth-1)
                ))
    elseif MPSGE.elasticity(N)*sign == -1 #Cobb-Douglas is only on demand side with σ=1
        cost_function = cobb_douglas(N; depth = depth-1)
    else
        cost_function = CES(N; depth = depth-1)
    end
end


function cost_function(N::Netput; depth = -1)
    return quantity(N)*unit_cost_function(N; depth = depth)
end

function cost_function(N::Node; depth = -1)
    return quantity(N)*unit_cost_function(N; depth = depth)
end

"""
    cost_function(S::ScalarSector; depth = -1)
    cost_function(S::ScalarSector, nest::Symbol; depth = -1)
    
Return a vector of cost functions for the given sector and nest. If `nest` is 
not provided return the cost function for input tree. 

`nest` is the symbol representing the nest. This can also be the name of a 
commodity. 

If `virtual` is true, return the virtual cost functions.
"""
function cost_function(P::ScalarProduction, nest::Symbol; depth = -1, search = :all)
    N = find_nodes(P; search = search)
    if haskey(N, nest)
        return sum(quantity.(N[nest]).*unit_cost_function.(N[nest]; depth = depth))
    end
    return 0
end


cost_function(P::ScalarProduction; depth = -1) = cost_function(P, name(input(P)), depth = depth)
cost_function(S::ScalarSector, nest::Symbol; depth = -1) = cost_function(production(S), nest, depth = depth, search = :input)
cost_function(S::ScalarSector; depth = -1) = cost_function(production(S), depth = depth)


"""
    revenue_function(S::ScalarSector; depth = -1)    
    revenue_function(S::ScalarSector, nest::Symbol; depth = -1)
    
Return a vector of revenue functions for the given sector and nest. If `nest` is 
not provided return the revenue function for input tree. 

`nest` is the symbol representing the nest. This can also be the name of a 
commodity. 

If `virtual` is true, return the virtual revenue functions.

"""
revenue_function(P::ScalarProduction; depth = -1) = cost_function(P, name(output(P)), depth = depth, search = :output)
revenue_function(S::ScalarSector, nest::Symbol; depth = -1) = cost_function(production(S), nest, depth = depth, search = :output)
revenue_function(S::ScalarSector; depth = -1) = revenue_function(production(S); depth = depth)


#function cost_function(N::MPSGE.Netput; virtual = false, sector = nothing)
#    return 
#    C = commodity(N)
#    sign = MPSGE.netput_sign(N)
#    rp = MPSGE.reference_price(N)
#    return C*(1-sign*sum(MPSGE.tax(t) for t∈taxes(N);init = 0))/rp
#end
#
#
#function cost_function(N::MPSGE.Node; virtual = :full, cf = cost_function, sector = nothing)
#
#    @assert virtual in [:full, :virtual, :partial] "virtual must be one of :full, :virtual, or :partial"
#
#    if virtual == :virtual
#        return N.cost_function_virtual
#    end
#
#    virtual_adjust = if virtual == :partial
#        :virtual
#    else
#        :full
#    end
#
#    sign = MPSGE.netput_sign(N)
#    if !(isa(MPSGE.elasticity(N), Real))
#
#        jm = jump_model(model(N))
#
#        #This must be an explicit expression, otherwise it's evaluated now. 
#        cost_function = @expression(jm, ifelse(
#                    MPSGE.elasticity(N) * sign == -1,
#                    cobb_douglas(N, virtual = virtual_adjust, cf = cf), 
#                    CES(N, virtual = virtual_adjust, cf = cf)
#                ))
#    elseif MPSGE.elasticity(N)*sign == -1 #Cobb-Douglas is only on demand side with σ=1
#        cost_function = cobb_douglas(N; virtual = virtual_adjust, cf = cf, sector = sector)
#    else
#        cost_function = CES(N; virtual = virtual_adjust, cf = cf, sector = sector)
#    end
#
#    return cost_function
#
#end
#
#function cost_function(P::ScalarProduction, nest::Symbol; virtual = false, search = :all)
#    N = find_nodes(P; search = search)
#    if haskey(N, nest)
#        v = virtual ? :virtual : :full
#        return sum(quantity.(N[nest]).*cost_function.(N[nest]; virtual = v))
#    end
#    return 0
#end

# """
#     cost_function(S::ScalarSector; virtual = false)
#     cost_function(S::ScalarSector, nest::Symbol; virtual = false)
#     
# Return a vector of cost functions for the given sector and nest. If `nest` is 
# not provided return the cost function for input tree. 
# 
# `nest` is the symbol representing the nest. This can also be the name of a 
# commodity. 
# 
# If `virtual` is true, return the virtual cost functions.
# """
# cost_function(P::ScalarProduction; virtual=false) = cost_function(P, name(input(P)), virtual=virtual)
# cost_function(S::ScalarSector, nest::Symbol; virtual = false) = cost_function(production(S), nest, virtual=virtual, search = :input)
# cost_function(S::ScalarSector; virtual = false) = cost_function(production(S), virtual=virtual)
# 
# 
# """
#     revenue_function(S::ScalarSector; virtual = false)    
#     revenue_function(S::ScalarSector, nest::Symbol; virtual = false)
#     
# Return a vector of revenue functions for the given sector and nest. If `nest` is 
# not provided return the revenue function for input tree. 
# 
# `nest` is the symbol representing the nest. This can also be the name of a 
# commodity. 
# 
# If `virtual` is true, return the virtual revenue functions.
# 
# """
# revenue_function(P::ScalarProduction; virtual = false) = cost_function(P, name(output(P)), virtual = virtual, search = :output)
# revenue_function(S::ScalarSector, nest::Symbol; virtual = false) = cost_function(production(S), nest, virtual = virtual, search = :output)
# revenue_function(S::ScalarSector; virtual = false) = revenue_function(production(S); virtual = virtual)


#############################
## Building Cost Functions ##
#############################





function build_cost_function(tree::Netput; virtual = :full, sector = nothing)
    return unit_cost_function(tree)
end

function build_cost_function(N::Node; virtual = :full, sector = nothing)

    # If the cost function exists, return it
    #if !isnothing(N.cost_function_virtual)
    #    return unit_cost_function(N; depth = 0)
    #end

    #return 0
    #cost_function = MPSGE.cost_function(N; virtual = :partial, cf = MPSGE.build_cost_function, sector = sector)

    ucf = unit_cost_function(N; depth = 1)

    jm = jump_model(model(N))
    @constraint(jm, N.cost_function_virtual - ucf ⟂ N.cost_function_virtual)

    build_cost_function.(children(N))

    #if isnothing(N.cost_function_virtual)
        #jm = jump_model(model(N))
        #name = string("cf(", sector, ", :", MPSGE.name(N), ")")
        #N.cost_function_virtual = @variable(jm, start = value(start_value, cost_function), base_name = name) 
        #N.cost_function = cost_function
        #@constraint(jm, N.cost_function_virtual - cost_function ⟂ N.cost_function_virtual)
    #end

    return N.cost_function_virtual
end
