function prune!(T::MPSGE_MP.ScalarNetput)
    if quantity(T) != 0
        return T
    else
        return nothing
    end
end

function prune!(T::MPSGE_MP.ScalarNest)
    if quantity(T) == 0
        return nothing
    end
    T.children = [e for e∈prune!.(MPSGE_MP.children(T)) if !isnothing(e)]
    return T
end

function prune!(P::MPSGE_MP.Production)
    P.input = prune!(P.input)
    P.output = prune!(P.output)
    if isnothing(P.input) && isnothing(P.output)
        S = sector(P)
        M = MPSGE_MP.model(S)
        delete!(M.productions,S)
        return nothing
    end
    @assert !isnothing(P.input) && !isnothing(P.output) "Production block for $(sector(P)) has a 0 quantity in either output or input, but not both."
    return P
end

function prune!(M::MPSGEModel)
    for (_,P) in M.productions
        prune!(P)
    end
end