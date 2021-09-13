# This function is copied from JuMP
function _add_kw_args(call, kw_args)
    for kw in kw_args
        @assert Meta.isexpr(kw, :(=))
        push!(call.args, esc(Expr(:kw, kw.args...)))
    end
end

macro parameter(model, name, value, kwargs...)
    constr_call = :(Parameter($(QuoteNode(name)), value=($(esc(value)))))

    _add_kw_args(constr_call, kwargs)

    return :($(esc(name)) = add!($(esc(model)), $constr_call))
end

macro sector(model, name, kwargs...)
    constr_call = :(Sector($(QuoteNode(name))))

    _add_kw_args(constr_call, kwargs)

    return :($(esc(name)) = add!($(esc(model)), $constr_call))
end

macro commodity(model, name, kwargs...)
    constr_call = :(Commodity($(QuoteNode(name))))

    _add_kw_args(constr_call, kwargs)

    return :($(esc(name)) = add!($(esc(model)), $constr_call))
end

macro consumer(model, name, kwargs...)
    constr_call = :(Consumer($(QuoteNode(name))))

    _add_kw_args(constr_call, kwargs)

    return :($(esc(name)) = add!($(esc(model)), $constr_call))
end

macro production(model, args...)
    return :(add!($(esc(model)), Production($(esc.(args)...))))
end

macro demand(model, args...)
    return :(add!($(esc(model)), DemandFunction($(esc.(args)...))))
end