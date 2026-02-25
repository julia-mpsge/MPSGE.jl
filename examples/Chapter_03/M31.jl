# # M-3.1 Closed 2x2 Economy - Calibrate to an Existing Tax

# Closed economy 2x2 with taxes in the benchmark
# 
# 
# | Markets | X   | Y   | W   |     | CONS|
# | ---     | --- | --- | --- | --- | --- |
# | PX      | 100 |     | -100|     |     |
# | PY      |     | 100 | -100|     |     |
# | PW      |     |     | 200 |     | -200|
# | PL      | -20 | -60 |     |     | 80  |
# | PK      | -60 | -40 |     |     | 100 |
# |         |     |     |     |     |     |
# | TAX     | -20 |     |     |     | 20  |

using MPSGE
using DataFrames

# Model instantiation

M31 = MPSGEModel()

tx0 = 0
ty0 = 0
tlx0 = 1
tkx0 = 0

@parameters(M31, begin
    TX, tx0,  (description = "Proportional output tax on sector X",)
    TY, ty0,  (description = "Proportional output tax on sector Y",)
    TLX, tlx0, (description = "Ad-valorem tax on labor inputs to X",)
    TKX, tkx0, (description = "Ad-valorem tax on captial inputs to X",)
end)

@sectors(M31, begin
    X
    Y
    W
end)

@commodities(M31, begin
    PX
    PY
    PW
    PL
    PK
end)

@consumer(M31, CONS)

@production(M31, X, [s=1, t=0], begin
    @output(PX, 100, t, taxes = [Tax(CONS, TX)])#, reference_price = 1 - tx0)
    @input(PL, 20, s, taxes = [Tax(CONS, TLX)], reference_price = 1+tlx0)
    @input(PK, 60, s, taxes = [Tax(CONS,TKX)])#, reference_price = 1+tkx0
end)


@production(M31, Y, [s=1, t=0], begin
    @output(PY, 100, t, taxes = [Tax(CONS, TY)])
    @input(PL, 60, s)
    @input(PK, 40, s)
end)

@production(M31, W, [s=1, t=0], begin
    @output(PW, 200, t)
    @input(PX, 100, s)
    @input(PY, 100, s)
end)

@demand(M31, CONS, begin
    @final_demand(PW, 200)
    @endowment(PL, 80)
    @endowment(PK, 100)
end);

# View the model

M31


# Set the numeraire

fix(PW, 1)

# ## Benchmark Verification

solve!(M31; cumulative_iteration_limit=0)
generate_report(M31)

# ## First Counterfactual
# 
# Replace tax on labor inputs by a uniform tax on both factors

set_value!(TLX, .25)
set_value!(TKX, .25)
set_value!(TX, 0)
set_value!(TY, 0)

solve!(M31)
CF1 = generate_report(M31) |>
    x -> rename(x, :value => :CF1)


# ## Second Counterfactual
# 
# Demonstrate that a 25% tax on all inputs is equivalent to a 20% tax on the 
# output (or all outputs if more than one)


set_value!(TLX, 0)
set_value!(TKX, 0)
set_value!(TX, .2)
set_value!(TY, 0)

solve!(M31)
CF2 = generate_report(M31) |>
    x -> rename(x, :value => :CF2)


# ## Counterfactual 3
# 
# Finally, demonstrate that a 20% tax on the $X$ sector output is equivalent to 
# a 25% subsidy on $Y$ sector output (assumes that the funds for the subsidy can 
# be raised lump sum from the consumer!) 

set_value!(TLX, 0)
set_value!(TKX, 0)
set_value!(TX, 0)
set_value!(TY, -.25)

solve!(M31)
CF3 = generate_report(M31) |>
    x -> rename(x, :value => :CF3)


# ## Verifying Solutions Match

innerjoin(CF1, CF2, on = :var; makeunique=true) |>
    x-> innerjoin(x, CF3, on = :var, makeunique=true) |>
    x -> select(x, :var, :CF1, :CF2, :CF3)


# ## The Missing MCP Code

# MPSGE.jl builds the MCP model in the background, but the user can extract any
# part of the model. For example, the cost function for the production of good 
# X is given by:

cost_function(X)

# Similarly, the zero profit condition for the production of good X is given by:

zero_profit(X)

# The user can also display the market clearance condition:

market_clearance(PX)

# Finally, the income balance condition:

income_balance(CONS; virtual = true)

# #

P = production(X)

I = P.input


I

