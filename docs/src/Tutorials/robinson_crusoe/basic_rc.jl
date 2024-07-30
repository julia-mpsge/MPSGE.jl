# # One Consumer, One Producer, Two Goods
#
# ## Model Definition
# In this economy, Robinson Crusoe acts as both a producer and consumer
# of `coconuts` and `fish`. To disambiguate between the producer and 
# consumer, we will refer to the producer as `rc_producer` and the 
# consumer as `rc_consumer`. 
# 
# There are three commodities: `coconuts`, `fish` and `labor`. We will
# call these variables `price_coconuts`, `price_fish` and `price_labor`. 
# `rc_producer` takes in `price_labor` and outputs both `price_fish` and 
# `price_coconuts`. Conversely, `rc_consumer` demands both `price_fish` and
# `price_coconuts` and endows the market with `price_labor`.
#
# At this point we can initialize our model. The first step is load the
# MPSGE package and initialize our model.
#

using MPSGE

M = MPSGEModel()

# Next we define our [`@sector`](@ref), [`@commodities`](@ref), and [`@consumer`](@ref).
# Notice the use of singular and plural, we are using the singular `@sector` since we 
# only have one sector. We could have three `@commodity(M, price_X)` statements rather
# than the single `@commodities` using the plural is less typing.

# The last line prints the model. This is not a standard or necessary step. But it's 
# useful to verify our variables have been added to the model.

@sector(M, rc_producer)

@commodities(M, begin
    price_coconuts
    price_fish
    price_labor
end)

@consumer(M, rc_consumer)

print(M)

# Similar to JuMP, these macros put each variable name into the local scope. That
# means we can use `price_coconuts` rather than extracting from the model, e.g.
# `M[:price_coconuts]`.
#
# The code below works, but isn't interesting. It's just demonstrating that `price_coconuts`
# is in the local namespace.

price_coconuts

# A [`@production`](@ref) block defines the inputs and outputs from a sector. 
# Recall we said 
#   `rc_producer` takes in `price_labor` and outputs both `price_fish` and 
#   `price_coconuts`
# This tells us the inputs and outputs. For the moment we are going to set all 
# quantities to one. We will have examples later that deal with balanced data. 
#
# The code `[s=0,t=0]` defines the elasticity of substitution and the elasticity 
# transformation. By convention these are denoted `s` and `t`, but that is not
# a requirement any name is sufficient. Future examples will show a far more
# complex nesting structure.

@production(M, rc_producer, [s=0, t=0], begin
    @output(price_coconuts, 1, t)
    @output(price_fish, 1, t)
    @input(price_labor, 1, s)
end)

# We define the demands in a [`@demand`](@ref) block. This resembles a 
# production block with no elasticities. 
#

@demand(M, rc_consumer, begin
    @final_demand(price_coconuts, 1)
    @final_demand(price_fish, 1)
    end, begin
    @endowment(price_labor, 1)
end)

# We are going to set `price_coconuts` as the numeraire and fix it's
# value to 1. This is not a necessary step, if there is no numeraire 
# MPSGE will set fix the value of the largest consumer as the numeraire,
# this is reported to the user when the model is solved.

fix(price_coconuts, 1)

# Finally we solve the model and generate a report.

solve!(M)

generate_report(M)

# Results can also be extracted using `value`. Most JuMP features have
# been extended to work on MPSGE variables. 

value(price_fish)

# Discuss the results of the model
# 

# ## Extracting Model Equations
#
# There isn't much else we can do with this model, there are no
# parameters so we can't modify values and re-solve. However, in
# this simple model we can explore the equations and model structure.
#
# We can extract production blocks to ensure they were input correctly.
# This view uses a syntax similar to MPSGE.GAMS, but should be readable.

production(rc_producer)

# There are three types of constraints in a MPSGE model, `zero_profit`, 
# `market_clearance`, and `income_balance`. We can extract each of these.
#
# Zero profit takes in a `sector`:

MPSGE.zero_profit(rc_producer)

# Market clearance takes a `commodity`:

MPSGE.market_clearance(price_coconuts)

# And income balance takes a `consumer`:

MPSGE.income_balance(rc_consumer)

# We can extract the market clearing conditions for all the commodities
# using broadcasting.

MPSGE.market_clearance.(commodities(M))

