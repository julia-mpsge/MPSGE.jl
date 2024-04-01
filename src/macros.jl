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

# This function heavily inspired by JuMP
function _parse_ref_sets(c)
    name = missing
    index = :([])
    index_vars = :([])
    if Meta.isexpr(c, :ref)
        name = c.args[1]
        for arg in c.args[2:end]
            if Meta.isexpr(arg, :kw)
                push!(index.args, esc(arg.args[2]))
                push!(index_vars.args, esc(arg.args[1]))
            else isa(arg, Symbol)
                push!(index.args, esc(arg))
                push!(index_vars.args, missing)
            end
        end
    else c isa Symbol
        name = c
    end
    return [name, index, index_vars]
end



macro sector(model, name, kwargs...)
    name, index, _ = _parse_ref_sets(name)
    if isempty(index.args) #This could be better
        constr_call = :(add_sector!($(esc(model)),$(QuoteNode(name))))
    else
        constr_call = :(add_sector!($(esc(model)),$(QuoteNode(name)); index = $index))
    end
    _add_kw_args(constr_call, kwargs)
    return :($(esc(name)) = $constr_call)
end


macro sectors(model, block)
    return _plural_macro_code(model, block, Symbol("@sector"))
end

macro commodity(model, name, kwargs...)
    name, index, _ = _parse_ref_sets(name)
    if isempty(index.args) #This could be better
        constr_call = :(add_commodity!($(esc(model)),$(QuoteNode(name))))
    else
        constr_call = :(add_commodity!($(esc(model)),$(QuoteNode(name)); index = $index))
    end
    _add_kw_args(constr_call, kwargs)
    return :($(esc(name)) = $constr_call)
end

macro commodities(model, block)
    return _plural_macro_code(model, block, Symbol("@commodity"))
end

macro consumer(model, name, kwargs...)
    name, index, _ = _parse_ref_sets(name)
    if isempty(index.args) #This could be better
        constr_call = :(add_consumer!($(esc(model)),$(QuoteNode(name))))
    else
        constr_call = :(add_consumer!($(esc(model)),$(QuoteNode(name)); index = $index))
    end
    _add_kw_args(constr_call, kwargs)
    return :($(esc(name)) = $constr_call)
end

macro consumers(model, block)
    return _plural_macro_code(model, block, Symbol("@consumer"))
end

macro parameter(model, name, value, kwargs...)
    name, index, _ = _parse_ref_sets(name)
    if isempty(index.args) #This could be better
        constr_call = :(add_parameter!($(esc(model)),$(QuoteNode(name)), $(esc(value))))
    else
        constr_call = :(add_parameter!($(esc(model)),$(QuoteNode(name)), $(esc(value)); index = $index))
    end
    _add_kw_args(constr_call, kwargs)
    return :($(esc(name)) = $constr_call)
end

macro parameters(model, block)
    return _plural_macro_code(model, block, Symbol("@parameter"))
end


macro auxiliary(model, name, kwargs...)
    name, index, _ = _parse_ref_sets(name)
    if isempty(index.args) #This could be better
        constr_call = :(add_auxiliary!($(esc(model)),$(QuoteNode(name))))
    else
        constr_call = :(add_auxiliary!($(esc(model)),$(QuoteNode(name)); index = $index))
    end
    _add_kw_args(constr_call, kwargs)
    return :($(esc(name)) = $constr_call)
end

macro auxiliaries(model, block)
    return _plural_macro_code(model, block, Symbol("@auxiliary"))
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
        return :(Node($(QuoteNode(name)), $(value); parent = $(QuoteNode(parent))))
    else
        return :(Node($(QuoteNode(name)), $(value)))
    end

end

macro input(commodity, quantity, nest, kwargs...)
    constr_call = :(Input($(esc(commodity)), $(esc(quantity))))
    _add_kw_args(constr_call, kwargs)
    return :(($constr_call, $(QuoteNode(nest))))#@nest($nest,0)))
end

macro output(commodity, quantity, nest, kwargs...)
    constr_call = :(Output($(esc(commodity)), $(esc(quantity))))
    _add_kw_args(constr_call, kwargs)
    return :(($constr_call, $(QuoteNode(nest))))
end


macro production(model, sector, nestings, netputs)

    #nests
    nests = :(Nest[])
    top_nests = :(Symbol[])
    nest_connect = :(Tuple{Symbol,Symbol}[])
    for nest in nestings.args
        if !Meta.isexpr(nest, :(=))
            error("Invalid syntax for nesting $nest. Required to have an = in "*
            "statement. `s = 0` or `va => s = 0`."
            )
        end
        elasticity = _strip_value(nest)
        parent, nest = _strip_nest_name(nest)

        name, index, _ = _parse_ref_sets(nest)
    
        if isempty(index.args)
            push!(nests.args, :(ScalarNest($(QuoteNode(name)), $(esc(elasticity)))))
        else
            push!(nests.args, :(IndexedNest($(QuoteNode(name)), $(esc(elasticity)), $index)))
        end
    
        if !ismissing(parent)
            push!(nest_connect.args, :(($(QuoteNode(name)), $(QuoteNode(parent)))))
        else
            push!(top_nests.args, :($(QuoteNode(name))))
        end
    end

    #netputs
    nets = :(Tuple{Netput,Symbol}[])
    for arg in netputs.args
        if arg isa LineNumberNode
            continue
        end
        push!(nets.args, esc(arg))
    end

    return :(add_production!($(esc(model)), Production($(esc(sector)), $nests, $top_nests, $nest_connect, $nets)))
end


###################
## Demand Blocks ##
###################

macro final_demand(commodity, quantity, kwargs...)
    constr_call = :(ScalarDem($(esc(commodity)), $(esc(quantity))))
    _add_kw_args(constr_call, kwargs)
    return :($constr_call)
end

macro endowment(commodity, quantity, kwargs...)
    constr_call = :(ScalarEndowment($(esc(commodity)), $(esc(quantity))))
    _add_kw_args(constr_call, kwargs)
    return :($constr_call)
end


macro demand(model, consumer, demand_block, endowment_block, kwargs...)
    local demands = :([])
    local endows = :([])
    for d∈demand_block.args
        if !isa(d, LineNumberNode)
            push!(demands.args, esc(d))
        end
    end
    for e∈endowment_block.args
        if !isa(e, LineNumberNode)
            push!(endows.args, esc(e))
        end
    end
    
    constr_call = :(add_demand!($(esc(model)), $(esc(consumer)), $demands, $endows))
    _add_kw_args(constr_call, kwargs)
    return :($constr_call)
end