function cobb_douglas(N::MPSGE.Node; depth = -1)
    sign = MPSGE.netput_sign(N)
    return prod(unit_cost_function(child; depth = depth)^(quantity(child)/quantity(N)) for child in MPSGE.children(N); init=1)
end

function CES(N::MPSGE.Node; depth = -1)
    sign = MPSGE.netput_sign(N)
    if isempty(children(N))
        return 0
    end

    return sum(quantity(child)/quantity(N) * unit_cost_function(child; depth = depth)^(1+sign*elasticity(N)) for child in MPSGE.children(N)) ^ (1/(1+sign*elasticity(N)))
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

function unit_cost_function(P::ScalarProduction, nest::Symbol; depth = -1, search = :all)
    N = find_nodes(P; search = search)
    if haskey(N, nest)
        return sum(unit_cost_function.(N[nest]; depth = depth))
    end
    return 0
end



unit_cost_function(P::ScalarProduction; depth = -1) = unit_cost_function(P, name(input(P)), depth = depth)

"""
    unit_cost_function(S::ScalarSector; depth = -1)
    unit_cost_function(S::ScalarSector, nest::Symbol; depth = -1)

Return the unit cost function for the given sector and nest. If `nest` is not provided
return the unit cost function for input tree.

## Optional Arguments

- `depth=-1`: The maximum depth to which to evaluate the unit cost function. `depth=0` 
    returns the virtual cost function, `depth=1` evaluates one level of the unit 
    cost function, and so on. The default is `-1`, which will return the complete unit 
    cost function.

## Expression

The unit cost function for a node in the production tree is defined recursively 
using the functional form combination of the unit cost functions of its children.

The available functional forms are Cobb-Douglas and CES.
"""
unit_cost_function(S::ScalarSector, nest::Symbol; depth = -1) = unit_cost_function(production(S), nest, depth = depth)
unit_cost_function(S::ScalarSector; depth = -1) = unit_cost_function(production(S), depth = depth)



function cost_function(N::Netput; depth = -1)
    return quantity(N)*unit_cost_function(N; depth = depth)
end

function cost_function(N::Node; depth = -1)
    return quantity(N)*unit_cost_function(N; depth = depth)
end


function cost_function(P::ScalarProduction, nest::Symbol; depth = -1, search = :all)
    N = find_nodes(P; search = search)
    if haskey(N, nest)
        return sum(quantity.(N[nest]).*unit_cost_function.(N[nest]; depth = depth))
    end
    return 0
end

"""
    cost_function(S::ScalarSector; depth = -1)
    cost_function(S::ScalarSector, nest::Symbol; depth = -1)
    
Return the cost function for the given sector and nest. If `nest` is not provided
return the cost function for input tree.

## Optional Arguments

- `depth=-1`: The maximum depth to which to evaluate the cost function. `depth=0` 
    returns the virtual cost function, `depth=1` evaluates one level of the cost 
    function, and so on. The default is `-1`, which will return the complete cost 
    function.

## Expression

The cost function is the quantity multiplied by the [`unit_cost_function`](@ref):

```julia
quantity(S) * unit_cost_function(S; depth = depth)
```
"""
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




#############################
## Building Cost Functions ##
#############################





function build_cost_function(tree::Netput)
    return unit_cost_function(tree)
end

function build_cost_function(N::Node)

    ucf = unit_cost_function(N; depth = 1)

    jm = jump_model(model(N))
    @constraint(jm, N.cost_function_virtual - ucf ⟂ N.cost_function_virtual)

    return N.cost_function_virtual
end
