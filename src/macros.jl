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


"""
$(variable_description("sector"))
"""
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

"""
$(variables_description("sectors"))
"""
macro sectors(model, block)
    return _plural_macro_code(model, block, Symbol("@sector"))
end

"""
$(variable_description("commodity"))
"""
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

"""
$(variables_description("commodities"))
"""
macro commodities(model, block)
    return _plural_macro_code(model, block, Symbol("@commodity"))
end

"""
$(variable_description("consumer"))
"""
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

"""
$(variables_description("consumers"))
"""
macro consumers(model, block)
    return _plural_macro_code(model, block, Symbol("@consumer"))
end

"""
    @parameter(model, expr, value, kwargs...)

Create a `parameter` in the `model` described by the `expr` with initial `value` and  keyword arguments `kwargs`.

*parameter names*

`expr` must be one of the forms:

- A single symbol like `@parameter(model, X)`
- A container like expression `@parameter(model, X[I])`

*values*

The value can either be a single float or an array. Currently using an array is finicky and it's recommended to set the value with `set_parameter_value` after creation if there are difficulties.

*Keyword Arguments*

- `index`: Explicity sets the index. For example, this `@parameter(model, X, index = [I])` is equivalent to `@parameter(model, X[I])`.
- `description`: Set a description on a variable. 
"""
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

"""
    @parameters(model, block)

Pluralized version of [`@parameter`](@ref). 
"""
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

"""
$(netput_documentation("input"))
"""
macro input(commodity, quantity, nest, kwargs...)
    constr_call = :(Input($(esc(commodity)), $(esc(quantity))))
    _add_kw_args(constr_call, kwargs)
    return :(($constr_call, $(QuoteNode(nest))))#@nest($nest,0)))
end

"""
$(netput_documentation("output"))
"""
macro output(commodity, quantity, nest, kwargs...)
    constr_call = :(Output($(esc(commodity)), $(esc(quantity))))
    _add_kw_args(constr_call, kwargs)
    return :(($constr_call, $(QuoteNode(nest))))
end

"""
    @production(model, sector, nestings, netputs)

Define a production for the `sector` in the `model` with given `nestings` and `netputs`. 

**sector**

This is any `ScalarSector` in the model. 

**nestings**

This is where the nesting structure is defined and the associated elasticities. At minimum you must declare at least two nests and elasticities, one for the elasticity of substitution (`input`) and one for the elasticity of transformation (`output`), by convention these are denoted `s` and `t` respectively, although any identifier may be used. 

As a minimal example, `[s=1, t=0]` will set the `s` nest to have an elasticity of 1 and the `t` nest 0. Suppose you want a nest below `s` called `va` with an elasticity of 2, this is created with `[s=1, t=0, va=>s=2]`. The `va` points at its parent nest `s` and the elasticity follows. Nestings can be aribrarily deep, for example 
```
[s=1, t=0, va=>s=2, dm=>s=1, d=>dm=2]
```
will have two nests below `s` and one below `dm`. 

**netputs**

A netput is either an [`@input`](@ref) or an [`@output`](@ref). The netputs get wrapped in a `begin ... end` block and each netput must be on its own line.

**Examples**

In the below example we define the production blocks for two sectors `X` and `Y`. This is a non-function example solely created to show syntax. The `X` sector only has the two require elasticities where as `Y` has a more interesting nesting structure. A tax is included in the `Y` production block. 

```julia
julia> M = MPSGEModel();

julia> @sectors(M, begin
            X
            Y
        end);

julia> @commodities(M, begin
            PX
            PY
            PL
            PK
        end);

julia> @consumer(M, RA);

julia> @production(M, X, [s=1,t=0], begin
            @output(PX, 10, t)
            @input(PL, 5, s)
            @input(PK, 5, s)
        end);

julia> @production(M, Y, [s=2, t=1, va=>s=1], begin
            @output(PY, 15, t)
            @input(PX, 3, s)
            @input(PL, 4, va, taxes = [Tax(RA, .5)])
            @input(PK, 6, va)
        end);
```

For examples using indexed sectors and commodities we recommend looking at the WiNDC national model. This will be linked when the appropriate write-up is ready.

"""
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