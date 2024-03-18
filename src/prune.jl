function prune!(T::ScalarNetput)
    if quantity(T) != 0
        return T
    else
        return nothing
    end
end

function prune!(T::ScalarNest)
    if quantity(T) == 0
        return nothing
    end
    T.children = [e for e∈prune!.(children(T)) if !isnothing(e)]
    return T
end


#Needs a massive fix
function prune!(P::Production)
    P.nest_dict[P.input] = !isnothing(input(P)) ? prune!(input(P)) : nothing
    P.nest_dict[P.output] = !isnothing(output(P)) ? prune!(output(P)) : nothing
    if isnothing(input(P)) && isnothing(output(P))
        S = sector(P)
        M = model(S)
        delete!(M.productions,S)
        return nothing
    end
    @assert !isnothing(input(P)) && !isnothing(output(P)) "Production block for $(sector(P)) has a 0 quantity in either output or input, but not both."
    return P
end

function prune!(M::MPSGEModel)
    for (_,P) in M.productions
        prune!(P)
    end
end