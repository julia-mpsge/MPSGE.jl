__NETPUT_KWARGS__ = [:taxes, :reference_price]

struct PreNetput
    commodity::Any
    quantity::Any
    nest::Any
    taxes::Any
    reference_price::Any
    netput_type::Any
    index_vars::Vector{Any} # Index variables for the commodity
end



# Used and safe
function parse_netput_macro_arguments(
    error_fn::Function, 
    input_args,
    netput_fn::DataType; 
    num_positional_args = 3, 
    valid_kwargs = __PARAMETER_KWARGS__
    )

    # Extract the model, name expression, value, and keyword arguments
    args, kwargs = Containers.parse_macro_arguments(
        error_fn, 
        input_args
        )

    if length(args) != num_positional_args
        error_fn("Invalid number of positional arguments. Expected " *
            "$num_positional_args, got $(length(args)). Recall the syntax for" *
            " the `@$netput_fn` macro is `@$netput_fn(commodity, quantity, nest, kwargs...)`\n\n")
    end

    non_valid_kwargs = filter(x -> !(x in valid_kwargs), keys(kwargs))
    if length(non_valid_kwargs) > 0
        error_fn("The following keyword arguments are not valid: \n\n" *
            "$(join(string.("* ", non_valid_kwargs), "\n"))\n\n " *
            " Valid keyword arguments for a parameter are: \n\n" *
            "$(join(string.("* ", valid_kwargs), "\n"))\n\n")
    end

    return args, kwargs

end


"""
    parse_netput(error_fn::Function, netput_arg::Any)

Main code that goes in the macro

## Return

    (netput, parent nest)
"""
function parse_netput(error_fn::Function, netput_arg::Any, netput_fn::DataType)

    args, kwargs = parse_netput_macro_arguments(
        error_fn,
        netput_arg,
        netput_fn;
        num_positional_args = 3,
        valid_kwargs = __NETPUT_KWARGS__
    )

    commodity = args[1]
    quantity = args[2]
    nest = args[3]
    taxes = get(kwargs, :taxes, [])
    reference_price = get(kwargs, :reference_price, 1)

    x, index_vars, indices, all_indices = parse_ref_sets(error_fn, commodity)
    commodity_name_expr = build_name_expr(x, all_indices, kwargs)

    # Check that the nest doesn't have an iterable index
    N, nest_index_vars, _, nest_index = parse_ref_sets(error_fn, nest)
    if !isempty(nest_index_vars) 
        error_fn("Nests must not have index variables. Got: $nest_index_vars") # Improve
    end

    nest_name = build_string_expr(N, nest_index, kwargs) # Error prone if index are not references

    build_code = JuMP.Containers.container_code(
        index_vars,
        indices,
        quote
            PreNetput(
                $commodity_name_expr,
                $(esc(quantity)),
                $nest_name,  # Revist this little guy
                $(esc(taxes)),
                $(esc(reference_price)),
                $(esc(netput_fn)),
                $index_vars
            )
        end,
        :DenseAxisArray
    )

    return build_code

end


"""
    @input(commodity, quantity, nest, kwargs...)

This macro is soley used within a [`@production`](@ref) block to define the inputs 
for a sector. 

## Required Arguments

- `commodity` - A commodity. This can either be a scalar `C` or indexed `C[i=R]`. 
- `quantity` - Either a number or expression. 
- `nest` - The parent nest of the input. 

## Keyword Arguments

- `taxes` associate a tax to the commodity. The syntax 
    `taxes = [Tax(RA, .1), Tax(GOVT, .3)]` defines two taxes, one associated the 
    consumer `RA` and another with `GOVT`. In this example the values are fixed, 
    but they can also be parameters.
- `reference_price=1` Set the reference price of a commodity.

## Examples

```julia
@input(C, 1, nest, taxes = [Tax(RA, .1), Tax(GOVT, .3)])
@input(C[i=R], 1, nest)
@input(C[i=R], quantity[i], nest[i])
@input(C[i=R], quantity[i], nest[i], reference_price = price[i])
@input(C[i=R], quantity[i], nest[i], taxes = [Tax(RA, tax[i]), Tax(GOVT, .5)])
```
"""
macro input(input_args...)
    error_fn = Containers.build_error_fn("input", input_args, __source__)
    return parse_netput(error_fn, input_args, Input)
end


"""
    @output(commodity, quantity, nest, kwargs...)

This macro is soley used within a [`@production`](@ref) block to define the outputs 
for a sector. 

## Required Arguments

- `commodity` - A commodity. This can either be a scalar `C` or indexed `C[i=R]`. 
- `quantity` - Either a number or expression. 
- `nest` - The parent nest of the output. 

## Keyword Arguments

- `taxes` associate a tax to the commodity. The syntax 
    `taxes = [Tax(RA, .1), Tax(GOVT, .3)]` defines two taxes, one associated the 
    consumer `RA` and another with `GOVT`. In this example the values are fixed, 
    but they can also be parameters.
- `reference_price=1` Set the reference price of a commodity.

## Examples

```julia
@output(C, 1, nest, taxes = [Tax(RA, .1), Tax(GOVT, .3)])
@output(C[i=R], 1, nest)
@output(C[i=R], quantity[i], nest[i])
@output(C[i=R], quantity[i], nest[i], reference_price = price[i])
@output(C[i=R], quantity[i], nest[i], taxes = [Tax(RA, tax[i]), Tax(GOVT, .5)])
```
"""
macro output(input_args...)
    error_fn = Containers.build_error_fn("output", input_args, __source__)
    return parse_netput(error_fn, input_args, Output)
end




function build_netput(error_fn::Function, netput::PreNetput, nodes, sector_index_vars)
    commodity = netput.commodity
    quantity = netput.quantity
    nest = Symbol(netput.nest)
    taxes = netput.taxes
    reference_price = netput.reference_price
    netput_fn = netput.netput_type

    index_vars = netput.index_vars

    common_index_vars = intersect(index_vars, sector_index_vars)
    if !isempty(common_index_vars)
        error_fn("The netput $commodity has index variables $common_index_vars " * 
            "that are already used in the sector. " *
            "This is not allowed, as it create ambiguity in the model.\n")
    end

    parent = nodes[nest]

    N = netput_fn(commodity, quantity, parent; taxes = taxes, reference_price = reference_price)
    set_sign(parent,N)#; add_child = true)

    push!(parent.children, N)

    return N

end


function build_netput(error_fn::Function, netput::AbstractArray{<:PreNetput}, nodes, sector_index_vars)
    build_netput.(error_fn, netput, Ref(nodes), Ref(sector_index_vars))
end



function build_netputs(raw_netputs::Expr, index_vars)
    # netputs is an expression of the form `begin @input(...) @output(...) end`
    # We extract the netputs and build them
    
    netputs = :(Any[])
    for netput in raw_netputs.args
        if !isa(netput, LineNumberNode)
            push!(netputs.args, :($(esc(netput))))
        end
    end

    return netputs
end