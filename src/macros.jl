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
    jump_macro = Expr(:., MPSGE, QuoteNode(macro_sym)) #Change Main to module name here
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


macro aux_constraint(model, A, constraint)
    constr_call = :(add_aux_constraint!($(esc(model)), $(esc(A)), $(esc(constraint))))
    #_add_kw_args(constr_call, kwargs)
    return :($constr_call)
end



###################
## Demand Blocks ##
###################

"""
    @final_demand(commodity, quantity, kwargs...)


"""
macro final_demand(commodity, quantity, kwargs...)
    constr_call = :(ScalarFinalDemand($(esc(commodity)), $(esc(quantity))))
    _add_kw_args(constr_call, kwargs)
    return :($constr_call)
end

"""
    @endowment(commodity, quantity, kwargs...)

"""
macro endowment(commodity, quantity, kwargs...)
    constr_call = :(ScalarEndowment($(esc(commodity)), $(esc(quantity))))
    _add_kw_args(constr_call, kwargs)
    return :($constr_call)
end

"""
    @demand(model, consumer, demand_flow_block, kwargs...)

# Example

```julia
@demand(M, CONS, begin
    @final_demand(X, 10)
    @endowment(Y, 5)
    @endowment(Z, 10)
end)
```
"""
macro demand(model, consumer, demand_flow_block, kwargs...)
    local demand_flow = :(abstractDemandFlow[])
    #local endows = :(ScalarEndowment[])
    for d∈demand_flow_block.args
        if !isa(d, LineNumberNode)
            push!(demand_flow.args, esc(d))
        end
    end

    
    constr_call = :(add_demand!($(esc(model)), $(esc(consumer)), $demand_flow))
    _add_kw_args(constr_call, kwargs)
    return :($constr_call)
end