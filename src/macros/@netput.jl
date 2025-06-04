__NETPUT_KWARGS__ = [:taxes, :reference_price]

struct PreNetput
    commodity::Any
    quantity::Any
    nest::Any
    taxes::Any
    reference_price::Any
end


"""
    parse_netput_commodity_index_vars(error_fn::Function, expr::Expr)

This will take elements inside the commodity index `C[i=R, :r]` and ensure they
are either keywords, `i=R`. If they aren't make them a vector.
"""
function parse_netput_commodity_index_vars(error_fn::Function, expr::Expr)
    if Meta.isexpr(expr, :kw)
        return expr
    end
    return Expr(:vect, expr) 
end

# When the input is just a symbol
parse_netput_commodity_index_vars(error_fn::Function, input::QuoteNode) = Expr(:vect, input)
function parse_netput_commodity_index_vars(error_fn::Function, input::GlobalRef) 
    return input
end

parse_netput_commodity_index_vars(error_fn::Function, input) = Expr(:vect, input)



"""
    parse_netput_commodity(error_fn::Function, expr::Expr)


## Return

    (commodity_name, index_vars, indices)
"""
function parse_netput_commodity(error_fn::Function, expr::Expr)
    if !Meta.isexpr(expr, :ref)
        error_fn("Invalid syntax for commodity $expr. Must be of the form "*
            "`commodity_name[r=R]` or `commodity_name[g, r=R]."
        )
    end

    correct_expr = Expr(:ref, expr.args[1], MPSGE.parse_netput_commodity_index_vars.(error_fn, expr.args[2:end])...)

    C, index_vars, indices = Containers.parse_ref_sets(error_fn, correct_expr)
    return (C, index_vars, indices)

end

function parse_netput_commodity(error_fn::Function, expr::Symbol)
    return (expr, Any[], :(Containers.vectorized_product()))
end


function build_netput(error_fn::Function, netput::PreNetput, netput_fn::DataType)
    return netput_fn(
        netput.commodity,
        netput.quantity,
        reference_price = netput.reference_price,
        taxes = netput.taxes,
    )
end


function build_netput(error_fn::Function, netputs::AbstractArray{<:PreNetput}, netput_fn::DataType)
    build_netput.(error_fn, netputs, netput_fn)
end

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

struct NetputParent
    netput::Netput
    parent::Symbol
    NetputParent(netput::Netput, Parent::String) = new(netput, Symbol(Parent))
    NetputParent(test) = new(test[1], test[2])
end

#Base.iterate(nest::NetputParent) = nest

function create_netput_list(N::MPSGE.Netput, P::String)
    return MPSGE.NetputParent(N, P)
end

function create_netput_list(N::AbstractArray{<:MPSGE.Netput}, P::AbstractArray{String})
    return create_netput_list.(N,P)
end

"""
    parse_netput(error_fn::Function, netput_arg::Any)



## Return

    (netput, parent nest)
"""
function parse_netput(error_fn::Function, netput_arg::Any, netput_fn::DataType)

    args, kwargs = MPSGE.parse_netput_macro_arguments(
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

    x, index_vars, indices = MPSGE.parse_netput_commodity(error, commodity)

    commodity_name = isempty(index_vars) ? esc(x) : Expr(:ref, esc(x), esc.(index_vars)...)

    #return commodity_name

    build_code = JuMP.Containers.container_code(
        index_vars,
        indices,
        quote
            MPSGE.PreNetput(
                $commodity_name,
                $(esc(quantity)),
                1, #$(esc(nest)),  # Revist this little guy
                $(esc(taxes)),
                $(esc(reference_price))
            )
        end,
        :DenseAxisArray
    )

    #return build_code

    netput_code = quote
        try
            MPSGE.build_netput(
                $error_fn,
                $build_code,
                $netput_fn
                )
        catch e
            $error_fn("Error in netput macro: $(e)")
        end
    end

    nest_code = MPSGE.parent_container(
        error_fn,
        nest,
        index_vars,
        indices
    )

    return :(create_netput_list($netput_code, $nest_code))

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
    return MPSGE.parse_netput(error_fn, input_args, MPSGE.Input)
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
    return MPSGE.parse_netput(error_fn, input_args, MPSGE.Output)
end