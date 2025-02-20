# # Getting Started with MPSGE

# In this opening tutorial we will introduce the basics of MPSGE. We will start 
# with a simple example and build from there. 


# ## Statement of Problem

# We start with our data. The following table is related to a social accounting matrix, 
# SAM, in that the row and columns both sum to zero. 

# | Markets | X   | Y   | W   | CONS |
# | ---     | --- | --- | --- | ---  |
# | PX      | 100 |     | -100|      |
# | PY      |     | 100 |-100 |      |
# | PW      |     |     | 200 | -200 |
# | PL      |  -25| -75 |     | 100  |
# | PK      | -75 | -25 |     | 100  |

# There are two types of columns in this matrix, `sectors` (`X`, `Y`, `W`) 
# and `consumers` (CONS). These take in and produce commodities (`PX`, `PY`, 
# `PW`, `PL`, `PK`). For example, sector `X` produces 100 units of `PX` 
# and consumes 25 units of `PL` and 75 units of `PK`. This is the justification 
# for why each column sums to zero, the inputs and outputs are balanced. Technically,
# the consumer, `CONS`, does not "produce" anything, the consumer is demanding `PW`
# and endowing the market with `PL` and `PK`.

# The `commodities` (`PX`, `PY`, `PW`, `PL`, `PK`) are represented in rows. For 
# example, `PX` is produced in `X` and consumed in `W`. We assume all generated 
# commodities get used, so the sum of the rows is zero.

# !!! note 
#       We've explicity used `units` in the discussion above. The values in the matrix 
#       are prices times quantities, but interpreting them in this context makes 
#       modelling more difficult. It is better to think of these as "representative
#       quantities" and then set initial prices to be 1. We will return to this dicsussion
#       later, but it's useful to keep in mind.

# In this example we see `PX` and `PY` as the commodities produced by sectors `X` and `Y`
# respectively. `PW` is the commodity produced by sector `W` and represets welfare of 
# the consumers, they want to consume `PX` and `PY`. `PL` and `PK` are the factors of
# production, labor and capital, respectively.

# ## Modeling the Problem

# We will now define the model. We start by loading the MPSGE package and defining
# our model.

using MPSGE

# Define the model
M_basic = MPSGEModel()

# Initialize the [`@sectors`](@ref), [`@commodities`](@ref), and [`@consumer`](@ref).
# We use the plural form of `sectors` and `commodities` as we have multiple of each,
# and the singular form of `consumer` as we only have one consumer.
@sectors(M_basic, begin
    X, (description = "Sector X")
    Y
    W
end)

@commodities(M_basic, begin
    PX
    PY
    PW
    PL
    PK
end)

@consumer(M_basic, CONS)

# We now define the production and demand relationships. We use the [`@production`](@ref)
# and [`@demand`](@ref) macros to define these relationships.
#
# In this first example we will assume a Cobb-Douglass production function on the inputs
# of each sector. To do this we set the elasticity of substitution, `s`, to 1. Since each
# sector has only a single output the elasticity of transformation, `t`, is largely irrelevant,
# but we set it to zero.
#
# At this point you should compare these values to the matrix above. The values 
# in each block correspond to columns in the matrix.
@production(M_basic, X, [s=1, t=0], begin
    @output(PX, 100, t)
    @input(PL, 25, s)
    @input(PK, 75, s)
end)

@production(M_basic, Y, [s=1, t=0], begin
    @output(PY, 100, t)
    @input(PL, 75, s)
    @input(PK, 25, s)
end)

@production(M_basic, W, [s=1, t=0], begin
    @output(PW, 200, t)
    @input(PX, 100, s)
    @input(PY, 100, s)
end)

@demand(M_basic, CONS, begin
    @final_demand(PW, 200)
    @endowment(PL, 100)
    @endowment(PK, 100)
end)

# In this simple model it can be useful to print the model to verify everything is
# as expected. This is not a standard step, but it can be useful for debugging.

M_basic

# Now we solve the model. We use the [`solve!`](@ref) function to solve the model.
# The first solve is usually at the benchmark level, which means all values are
# as they appear in the table. This means the system should already be solved and 
# we should see that reflected in the output, the residual should be zero (or close to it)
solve!(M_basic, cumulative_iteration_limit=0)

# This model solves as expected. We can view the solution as a dataframe using the
# [`generate_report`](@ref) function.

generate_report(M_basic)

# If the model had not solved we would use this report to identify which marginal 
# value was not zero and then adjust the model accordingly. The margin value is 
# is a measure of how far the model is from solving in the given variable.

# You can also access the values of the variables directly. For example, to get the
# value of `PX` you can use the following code.

value(PX)

# ## Expanding the Model

# The model `M_basic` is a simple model that demonstrates the basic structure of an MPSGE model.
# However, it is not a very interesting model, all it does is represent the data 
# in the table. We can't change anything or ask questions, like what happens if we
# impose a tax on labor `PL` or capital `PK`?

# Let's expand the model to include taxes on labor and capital. To do this we write
# a new model and introduce some parameters. 

M_tax = MPSGEModel()

# We introduce two parameters, `labor_tax` and `capital_tax`. These will be used to
# set the tax rates on labor and capital. We set the default values to zero, but we
# can change these values later.
@parameters(M_tax, begin
    labor_tax, 0
    capital_tax, 0
end)

@sectors(M_tax, begin
    X, (description = "Sector X")
    Y
    W
end)

@commodities(M_tax, begin
    PX
    PY
    PW
    PL
    PK
end)

@consumer(M_tax, CONS)

# We are going to impose the labor and capital taxes on the production of `X`. We do this
# by adding the taxes to the inputs of `X`. Taxes need a consumer, to collect the tax,
# and a tax rate. You can add taxes to either inputs or outputs, but in this case we are
# adding them to the inputs.
@production(M_tax, X, [s=1, t=0], begin
    @output(PX, 100, t)
    @input(PL, 25, s, taxes = [Tax(CONS, labor_tax)])
    @input(PK, 75, s, taxes = [Tax(CONS, capital_tax)])
end)

@production(M_tax, Y, [s=1, t=0], begin
    @output(PY, 100, t)
    @input(PL, 75, s)
    @input(PK, 25, s)
end)

@production(M_tax, W, [s=1, t=0], begin
    @output(PW, 200, t)
    @input(PX, 100, s)
    @input(PY, 100, s)
end)

@demand(M_tax, CONS, begin
    @final_demand(PW, 200)
    @endowment(PL, 100)
    @endowment(PK, 100)
end)

# First, we check the model at the benchmark level. This is to ensure we've 
# entered our data correctly.
solve!(M_tax, cumulative_iteration_limit=0)

# Let's impose a 10% tax on labor. We do this by setting the value of `labor_tax`
# to 0.1 and then solving the model. Notice we do not set the cumulative iteration
# limit to zero, this is because we are not at the benchmark level. Feel free to 
# try, you'll see what an unbalanced model looks like.

set_value!(labor_tax, 0.1)

solve!(M_tax)

# We see the solver output has changed. The residual should be, essentially, zero and
# the solve has gone through a few iterations. Let's generate a report to see the
# results.

generate_report(M_tax)



# We see some interesting information in this model. The value of `PL` has changed from
# 1 to 0.988378, so the value of labor has decreased by about 1.2%. 

# What does this really mean? What impact does have on the welfare of the consumer?
# We can answer this question by calculating the welfare index of the consumer.
# This is the consumer value divided by the price of welfare, `PW`. We'll store this
# value in a variable, `labor_tax_welfare` for later use.

labor_tax_welfare = value(CONS/PW)

# What we see is that the overall welfare of the consumer has decreased, the base
# line was 200 and now it's 199.916. This makes intuitive sense, an imposed tax
# increases the cost of production, which is passed on to the consumer.

# Now let's impose a 10% tax on capital. To do this we reset the value of `labor_tax`
# to zero and set the value of `capital_tax` to 0.1. We then solve the model and
# generate a report.

set_value!(labor_tax, 0.0)
set_value!(capital_tax, 0.1)

solve!(M_tax)

generate_report(M_tax)

# Again, let's calculate the welfare index of the consumer.

capital_tax_welfare = value(CONS/PW)

# Subtracting, it appears the labor_tax is less harmful to the consumer than the capital_tax.
labor_tax_welfare - capital_tax_welfare

# ## Plotting Welfare

# Let's make a graph comparing the welfare of the consumer under different tax rates.
# We'll use the PlotlyJS and DataFrames packages. The PlotlyDocumenter package is used
# to display the plot in the documentation. 

using PlotlyJS, DataFrames, PlotlyDocumenter

# We'll be solving about 100 models, so we'll suppress the output.
set_silent(M_tax)

# The idea is to initialize a DataFrame and then loop over a range of tax rates.

df = DataFrame()
for i in 0:.01:.5
    set_value!(labor_tax, i)
    set_value!(capital_tax, 0)
    solve!(M_tax)
    push!(df, (tax_value = i, type = :labor, welfare = value(CONS/PW)))

    set_value!(labor_tax, 0)
    set_value!(capital_tax, i)
    solve!(M_tax)
    push!(df, (tax_value = i, type = :capital, welfare = value(CONS/PW)))
end

p = plot(df, x=:tax_value, y=:welfare, color=:type,
    Layout(title= "Labor vs Capital tax rates")
)

to_documenter(p)
