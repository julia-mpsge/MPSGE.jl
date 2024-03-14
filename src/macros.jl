# This function is copied from JuMP
function _add_kw_args(call, kw_args)
    for kw in kw_args
        @assert Meta.isexpr(kw, :(=))
        push!(call.args, esc(Expr(:kw, kw.args...)))
    end
end


#Stolen from JuMP
function _plural_macro_code(model, block, macro_sym)
    if !Meta.isexpr(block, :block)
        error(
            "Invalid syntax for $(macro_sym)s. The second argument must be a " *
            "`begin end` block. For example:\n" *
            "```julia\n$(macro_sym)s(model, begin\n    # ... lines here ...\nend)\n```.",
        )
    end
    @assert block.args[1] isa LineNumberNode
    last_line = block.args[1]
    code = quote end #Expr(:tuple) #I don't know why this works in JuMP, but not for me. Perhaps a Julia 1.10 thing
    jump_macro = Expr(:., Main, QuoteNode(macro_sym)) #Change Main to module name here
    for arg in block.args
        if arg isa LineNumberNode
            last_line = arg
        elseif Meta.isexpr(arg, :tuple)  # Line with commas.
            macro_call = Expr(:macrocall, jump_macro, last_line, model)
            # Because of the precedence of "=", Keyword arguments have to appear
            # like: `x, (start = 10, lower_bound = 5)`
            for ex in arg.args
                if Meta.isexpr(ex, :tuple) # embedded tuple
                    append!(macro_call.args, ex.args)
                else
                    push!(macro_call.args, ex)
                end
            end
            push!(code.args, esc(macro_call))
        else  # Stand-alone symbol or expression.
            macro_call = Expr(:macrocall, jump_macro, last_line, model, arg)
            push!(code.args, esc(macro_call))
        end
    end
    return code
end


macro sector(model, name, kwargs...)
    constr_call = :(add_sector!($(esc(model)),$(QuoteNode(name))))
    _add_kw_args(constr_call, kwargs)
    return :($(esc(name)) = $constr_call)
end


macro sectors(model, block)
    return _plural_macro_code(model, block, Symbol("@sector"))
end

macro commodity(model, name, kwargs...)
    constr_call = :(add_commodity!($(esc(model)),$(QuoteNode(name))))
    _add_kw_args(constr_call, kwargs)
    return :($(esc(name)) = $constr_call)

end

macro commodities(model, block)
    return _plural_macro_code(model, block, Symbol("@commodity"))
end

macro consumer(model, name, kwargs...)
    constr_call = :(add_consumer!($(esc(model)),$(QuoteNode(name))))
    _add_kw_args(constr_call, kwargs)
    return :($(esc(name)) = $constr_call)
end

macro consumers(model, block)
    return _plural_macro_code(model, block, Symbol("@consumer"))
end

macro parameter(model, name, value, kwargs...)
    constr_call = :(add_parameter!($(esc(model)),$(QuoteNode(name)), $(esc(value))))
    _add_kw_args(constr_call, kwargs)
    return :($(esc(name)) = $constr_call)
end

macro parameters(model, block)
    return _plural_macro_code(model, block, Symbol("@parameter"))
end


macro auxiliary(model, name, kwargs...)
    constr_call = :(add_auxiliary!($(esc(model)),$(QuoteNode(name))))
    _add_kw_args(constr_call, kwargs)
    return :($(esc(name)) = $constr_call)
end

macro auxiliaries(model, block)
    return _plural_macro_code(model, block, Symbol("@auxiliary"))
end

macro demand(model, consumer, demands, endowments, kwargs...)
    constr_call = :(add_demand!($(esc(model)), $(esc(consumer)), $(esc(demands)), $(esc(endowments))))
    _add_kw_args(constr_call, kwargs)
    return :($constr_call)
end



macro aux_constraint(model, A, constraint)
    constr_call = :(add_aux_constraint!($(esc(model)), $(esc(A)), $(esc(constraint))))
    #_add_kw_args(constr_call, kwargs)
    return :($constr_call)
end

#######################
## Production Blocks ##
#######################

function _strip_value(nest)
    value = nest.args[2]
    if Meta.isexpr(value, :block)
        value = value.args[2]
    end
    return value
end

function _strip_nest_name(nest)
    parent = missing
    name = nest.args[1]
    if Meta.isexpr(name, :call)
        parent = name.args[3]
        name = name.args[2]
    end
    return parent, name
end

function _parse_nest(nest)
    if !Meta.isexpr(nest, :(=))
        error("Invalid syntax for nesting $nest. Required to have an = in "*
        "statement. `s = 0` or `va => s = 0`."
        )
    end
    value = _strip_value(nest)
    parent, name = _strip_nest_name(nest)
    if !ismissing(parent)
        return :(MPSGE_MP.Node($(QuoteNode(name)), $(value); parent = $(QuoteNode(parent))))
    else
        return :(MPSGE_MP.Node($(QuoteNode(name)), $(value)))
    end

end

macro Output(commodity, quantity, nest, kwargs...)
    constr_call = :(ScalarOutput($(esc(commodity)), $(esc(quantity)); parent = $(QuoteNode(nest))))
    _add_kw_args(constr_call, kwargs)
    return :($constr_call)
end


macro Input(commodity, quantity, nest, kwargs...)
    constr_call = :(ScalarInput($(esc(commodity)), $(esc(quantity)); parent = $(QuoteNode(nest))))
    MPSGE_MP._add_kw_args(constr_call, kwargs)
    return :($constr_call)
end

macro production(model, sector, nestings, netputs)
    nodes = esc.(_parse_nest.(nestings.args))
    node_expr = :([])
    for node in nodes
        push!(node_expr.args, node)
    end
    constr_call = :(add_production!($(esc(model)), $(esc(sector)),$node_expr))
    for netput in netputs.args
        if !isa(netput,LineNumberNode)
            push!(constr_call.args, esc(netput))
        end
    end
    #_add_kw_args(constr_call, kwargs)
    return :($constr_call)
end