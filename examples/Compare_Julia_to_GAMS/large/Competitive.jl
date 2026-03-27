"""
    Competitive

This module contains the necessary data structures and functions to construct a 
high-dimensional competitive model using the MPSGE framework. 

Each of the data structures and functions listed below is documented with a 
docstring that provides a detailed description of its purpose, its arguments, 
and its return value. You can view these docstrings two ways:

1. In the REPL, you can access the docstring for a specific function or data 
    structure by using the `?` help mode. For example, to view the docstring for the `Country`
    struct, you would enter `?Competitive.Country` in the REPL.
2. In your code editor, you can use the `@doc` macro to view the docstring for a 
    specific function or data structure. For example, to view the docstring for 
    the `trade_cost` function, you would enter `@doc Competitive.trade_cost` in your code.

# Data Structures

- `Country`: A struct representing a country in the model, with attributes for trade cost and endowment.
- `Good`: A struct representing a good in the model, with an attribute for weight.
- `Factor`: An abstract type representing a factor of production in the model.
- `Labor`: A subtype of `Factor` representing labor in the model.
- `Capital`: A subtype of `Factor` representing capital in the model.

# Functions

- `trade_cost`
- `endowment`
- `factor_share`
- `competitive_model`

# Example

Note: To run this example in a different file, you will need to include the file
containing the `Competitive` module and use the module before running the example code. 
This code has been commented out to avoid errors when running this file directly.

```julia
#include("path/to/Competitive.jl")
using .Competitive

countries = [Competitive.Country(i, j) for i in 1:9, j in 1:11]
factors = [Competitive.Labor(), Competitive.Capital()]
goods = [Competitive.Good(g) for g in 1:11]

M = Competitive.competitive_model(countries, factors, goods)
solve!(M)
df = generate_report(M)

df |>
    x -> subset(x, :value => ByRow(==(0)))
```

"""
module Competitive

    using MPSGE
    using DataFrames

    """
        Country

    A struct representing a country in the model, with attributes for trade cost and endowment.

    # Fields

    - `trade_cost::Int`: An integer representing the trade cost of the country.
    - `endowment::Int`: An integer representing the endowment of the country.
    """
    struct Country
        trade_cost::Int
        endowment::Int
        Country(trade_cost, endowment) = new(trade_cost, endowment)
    end

    Base.show(io::IO, c::Country) = print(io, "C($(c.trade_cost), $(c.endowment))")

    """
        trade_cost(x::Country; last_country = 9)

    Returns the trade cost for a given country. If the country's `trade_cost` 
    attribute is equal to `last_country`, returns a very low trade cost (1.0000025). 
    Otherwise, returns a trade cost that decreases linearly with the `trade_cost` attribute.

    # Arguments

    - `x::Country`: The country for which to calculate the trade cost.

    # Keyword Arguments

    - `last_country::Int`: The value of the `trade_cost` attribute that indicates the last country. 
    Defaults to 9.

    # Returns

    - `Float64`: The calculated trade cost for the given country.

    # Expression

    If `x.trade_cost != last_country`:
    ```
    1.45 - 0.05 * x.trade_cost
    ```

    Otherwise:

    ```
    1.0000025
    ```
    """
    function trade_cost(x::Country; last_country = 9)
        if x.trade_cost == last_country
            return 1.0000025
        end
        return 1.45 - 0.05*x.trade_cost
    end

    """ 
        Good

    A struct representing a good in the model, with an attribute for weight.

    # Fields

    - `weight::Int`: An integer representing the weight of the good.
    """
    struct Good 
        weight::Int
    end

    Base.show(io::IO, g::Good) = print(io, "G($(g.weight))")

    """
        Factor

    An abstract type representing a factor of production in the model.
    """
    abstract type Factor end

    """
        Labor <: Factor

    A subtype of `Factor` representing labor in the model.
    """
    struct Labor <: Factor end

    """
        Capital <: Factor

    A subtype of `Factor` representing capital in the model.
    """
    struct Capital <: Factor end

    Base.show(io::IO, f::Labor) = print(io, "Labor")
    Base.show(io::IO, f::Capital) = print(io, "Capital")

    """
        endowment(x::Country, f::Factor)
        endowment(x::Country, f::Labor)
        endowment(x::Country, f::Capital)

    Functions to calculate the endowment of a country for a given factor. The endowment
    depends on the type of factor. 

    # Arguments

    - `x::Country`: The country for which to calculate the endowment.
    - `f::Factor`: The factor for which to calculate the endowment.

    # Returns

    - `Int`: The calculated endowment for the given country and factor.

    # Expression

    If `f` is of type `Capital`:
    ```
    120 - 10 * x.endowment
    ```

    If `f` is of type `Labor`:
    ```
    10 * x.endowment
    ```

    If `f` is of type `Factor` (general case):
    ```
    10*x.endowment
    ```
    """
    endowment(x::Country, f::Factor) = 10*x.endowment
    endowment(x::Country, f::Labor) = 10*x.endowment
    endowment(x::Country, f::Capital) = 120 - 10*x.endowment

    """
        factor_share(f::Factor, g::Good)
        factor_share(f::Labor, g::Good)
        factor_share(f::Capital, g::Good)

    Functions to calculate the factor share of a factor for a given good. The factor share
    depends on the type of factor.

    # Arguments

    - `f::Factor`: The factor for which to calculate the factor share.
    - `g::Good`: The good for which to calculate the factor share.

    # Returns

    - `Int`: The calculated factor share for the given factor and good.

    # Expression

    If `f` is of type `Capital`:
    ```
    120 - 10 * g.weight
    ```

    If `f` is of type `Labor`:
    ```
    10 * g.weight
    ```

    If `f` is of type `Factor` (general case):
    ```
    10 * g.weight
    ```
    """
    factor_share(f::Factor, g::Good) = 10*g.weight
    factor_share(f::Capital, g::Good) = 120 - 10*g.weight
    factor_share(f::Labor, g::Good) = 10*g.weight



    """
        competitive_model(countries::Array{Country}, factors::Vector{Factor}, goods::Vector{Good})

    Constructs a competitive model using the MPSGE framework based on the provided countries, factors, and goods.

    # Arguments

    - `countries::Array{Country}`: An array of `Country` structs representing the countries in the model.
    - `factors::Vector{Factor}`: A vector of `Factor` types representing the factors of production in the model.
    - `goods::Vector{Good}`: A vector of `Good` structs representing the goods in the model.

    # Returns

    - `MPSGEModel`: A model constructed using the MPSGE framework based on the provided inputs.

    # Model Description

    ## Parameters

    The initial values for the parameters are given by the functions [`Competitive.trade_cost`](@ref), 
    [`Competitive.endowment`](@ref), and [`Competitive.factor_share`](@ref). 

    ```julia
    @parameters(M, begin
        Trade_Cost[country = countries], 
                trade_cost(country),                      
                (description = "Trade cost of country")
        Endowment[country = countries, factor = factors], 
                endowment(country, factor), 
                (description = "Endowment of country for factor")
        Factor_Share[factor = factors, good = goods], 
                factor_share(factor, good), 
                (description = "Factor share of factor for good")
        Scale, 
                1,
                (description = "Size of fringe in countries")
    end)
    ```    

    ## Sectors

    ```julia
    @sectors(M, begin
        Good_Production[country = countries, good = goods], 
                (description = "production activity for good")
        Export[country = countries, good = goods], 
                (description = "export activity for good")
        Import[country = countries, good = goods], 
                (description = "import activity for good")   
        Supply[country = countries, good = goods], 
                (description = "supply of domestically produced good to home")
        Welfare[country = countries], 
                (description = "welfare of country")
    end)
    ```

    ## Commodities

    ```julia
    @commodities(M, begin
        Utility_Price[country = countries], 
            (description = "utility price index for country")
        Producer_Price[country = countries, good = goods], 
            (description = "domestic producer price (mc) of good")
        Consumer_Price[country = countries, good = goods], 
            (description = "domestic consumer price of good")
        Factor_Price[country = countries, factor = factors], 
            (description = "price of factor in country")
        World_Price[good = goods], 
            (description = "world (central market) price of good")
    end)
    ```

    ## Consumer

    ```julia
    @consumer(M, Consumer[country = countries], description = "Income of representative consumer in country")
    ```

    ## Production

    ```julia
    @production(M, Good_Production[country = countries, good = goods], [t=0, s=1], begin
        @output(Producer_Price[country, good],        100,                        t)
        @input(Factor_Price[country, factor=factors], Factor_Share[factor, good], s)
    end)

    @production(M, Export[country = countries, good = goods], [t=0, s=0], begin
        @output(World_Price[good],            100,                     t)
        @input(Producer_Price[country, good], 100*Trade_Cost[country], s)
    end)

    @production(M, Import[country = countries, good = goods], [t=0, s=0], begin
        @output(Consumer_Price[country, good], 100,                     t)
        @input(World_Price[good],              100*Trade_Cost[country], s)
    end)

    @production(M, Supply[country = countries, good = goods], [t=0, s=0], begin
        @output(Consumer_Price[country, good], 100, t)
        @input(Producer_Price[country, good],  100, s)
    end)

    @production(M, Welfare[country = countries], [t=0, s=1], begin
        @output(Utility_Price[country],             100, t)
        @input(Consumer_Price[country, good=goods], 100, s)
    end)
    ```

    ## Demand

    ```julia
    @demand(M, Consumer[country = countries], begin
        @final_demand(Utility_Price[country],             sum(Endowment[country, factor] for factor in factors))
        @endowment(Factor_Price[country, factor=factors], Endowment[country, factor])
    end)
    ```

    """
    function competitive_model(countries::Array{Country}, factors::Vector{Factor}, goods::Vector{Good})
        M = MPSGEModel()

        @parameters(M, begin
            Trade_Cost[country = countries], 
                    trade_cost(country, last_country = maximum(x -> x.trade_cost, countries)),                      
                    (description = "Trade cost of country")
            Endowment[country = countries, factor = factors], 
                    endowment(country, factor), 
                    (description = "Endowment of country for factor")
            Factor_Share[factor = factors, good = goods], 
                    factor_share(factor, good), 
                    (description = "Factor share of factor for good")
            Scale, 
                    1,
                    (description = "Size of fringe in countries")
        end)



        @sectors(M, begin
            Good_Production[country = countries, good = goods], 
                    (description = "production activity for good")
            Export[country = countries, good = goods], 
                    (description = "export activity for good")
            Import[country = countries, good = goods], 
                    (description = "import activity for good")   
            Supply[country = countries, good = goods], 
                    (description = "supply of domestically produced good to home")
            Welfare[country = countries], 
                    (description = "welfare of country")
        end)

        @commodities(M, begin
            Utility_Price[country = countries], 
                (description = "utility price index for country")
            Producer_Price[country = countries, good = goods], 
                (description = "domestic producer price (mc) of good")
            Consumer_Price[country = countries, good = goods], 
                (description = "domestic consumer price of good")
            Factor_Price[country = countries, factor = factors], 
                (description = "price of factor in country")
            World_Price[good = goods], 
                (description = "world (central market) price of good")
        end)

        @consumer(M, Consumer[country = countries], description = "Income of representative consumer in country")

        @production(M, Good_Production[country = countries, good = goods], [t=0, s=1], begin
            @output(Producer_Price[country, good],        100,                        t)
            @input(Factor_Price[country, factor=factors], Factor_Share[factor, good], s)
        end)

        @production(M, Export[country = countries, good = goods], [t=0, s=0], begin
            @output(World_Price[good],            100,                     t)
            @input(Producer_Price[country, good], 100*Trade_Cost[country], s)
        end)

        @production(M, Import[country = countries, good = goods], [t=0, s=0], begin
            @output(Consumer_Price[country, good], 100,                     t)
            @input(World_Price[good],              100*Trade_Cost[country], s)
        end)

        @production(M, Supply[country = countries, good = goods], [t=0, s=0], begin
            @output(Consumer_Price[country, good], 100, t)
            @input(Producer_Price[country, good],  100, s)
        end)

        @production(M, Welfare[country = countries], [t=0, s=1], begin
            @output(Utility_Price[country],             100, t)
            @input(Consumer_Price[country, good=goods], 100, s)
        end)

        @demand(M, Consumer[country = countries], begin
            @final_demand(Utility_Price[country],             sum(Endowment[country, factor] for factor in factors))
            @endowment(Factor_Price[country, factor=factors], Endowment[country, factor])
        end)

        fix(World_Price[goods[div(length(goods), 2)+1]], 1)

        return M

    end

    export Country, Good, Labor, Capital
end




