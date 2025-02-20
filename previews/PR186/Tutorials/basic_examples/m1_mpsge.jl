#  # Closed 2x2 Economy - An Introduction to the Basics


# Take a very simply economy, two sectors ($X$ and $Y$), two factors ($L$ and $K$), 
# and one representative consumer (utility function $W$).  $L$ and $K$ are in inelastic 
# (fixed) supply, but can move freely between sectors.  $PX$ ,  $PY$ ,  $PL$ , and 
# $PK$ are the prices of $X$, $Y$, $L$ and $K$, respectively.   $I$ is consumer's 
# income and $PW$ will be used later to denote the price of one unit of $W$.  
# 
# The initial data for this economy by a rectangular matrix, given below.  This 
# matrix is related to the concept of a "SAM" -  social accounting matrix.  But 
# the term SAM has been used in a rather different sense, so we will just refer to 
# our rectangular matrix as a "MCM" – micro-consistency matrix.
# 
# In the present example, there are two types of columns in the rectangular MCM, 
# corresponding to production sectors and consumers.  In the model outlined above, 
# there are three production sectors ($X$, $Y$ and $W$) and a single consumer 
# ($CONS$).  Rows correspond to markets in10 the present example.  Complementary 
# variables are prices, so we have listed the price variables on the left to 
# designate rows.  
# 
# In the MCM, there are both positive and negative entries.  
# A positive entry signifies a receipt (sale) in a particular market.  
# A negative entry signifies an expenditure (purchase) in a particular market.  
# Reading down a production column, we then observe a complete list of the 
# transactions associated with that activity.  
# 
# |Markets |    X  |     Y   |     W    |       CONS   |
# |---     |---    |  ---    |    ---   | ---          |
# |PX      |  100  |         |  -100    |              |
# |PY      |       |   100   |  -100    |              | 
# |PW      |       |         |   200    |       -200   |     
# |PL      |  -25  |   -75   |          |        100   |     
# |PK      |  -75  |   -25   |          |        100   |

# This MCM is balanced, or micro-consistent, as the sum of each row and column is 
# zero, meaning any flow into a sector (negative numbers) has a matching flow out 
# (positive numbers).

# Finally, we emphasize that the numbers of the matrix are values, prices times 
# quantities. The modeler is free as to how to interpret these as prices versus 
# quantities.  A good practice is to choose units so that as many things initially 
# are equal to one as possible.  Prices can be chosen as one, and 
# "representative quantities" for activities can be chosen such that activity 
# levels are also equal to one (e.g., activity $X$ run at level one produces 
# 100 units of good $X$).    In the case of taxes, both consumer and producer 
# prices cannot equal one of course.

 
# ## Model Specification

# We are now ready to define the model. The first step is to load the MPSGE 
# package and define our model. We are also going to load DataFrames and Plots
# to easily display our results. 

using MPSGE, DataFrames, Plots

M = MPSGEModel()

# In this model we will introduce two parameters, an ad-valorem tax rate on sector
# $X$ inputs and a labor endowment multiplier. The syntax for defining multiple 
# parameters follows the plural macro format, [`@parameters`](@ref). 
# Each parameter is on a separate line, with the name of the parameter followed
# by the initial value and an optional description. The optional description must
# be wrapped in parentheses due to how Julia parses expressions.

@parameters(M, begin
    TX, 0, (description = "ad-valorem tax rate on sector X inputs")
    labor_endowment, 1, (description = "labor endowment multiplier")
end)

# Next we define our [`@sectors`](@ref), [`@commodities`](@ref), and 
# [`@consumer`](@ref). Descriptions can be added to each of these, we demonstrate
# adding a description to the consumer, as there is only one.

@sectors(M, begin
    X
    Y
    W
end)

@commodities(M, begin
    PX
    PY
    PW
    PL
    PK
end)

@consumer(M, CONS, description = "Representative Consumer")


# The next step is to define the production and demand relationships. Each of these
# encodes a column in our MCM. The [`@production`](@ref) macro is used to define
# the production relationships. The `[t=0, s=1]` defines the underlying 
# input/output tree. This is a very basic example where everything is nested 
# directly under the root. The `t` and `s` are the recommended names for the 
# output and input respectively, standing for transformation and substitution. 
# The `t=0` means the elasticity of transformation is zero, and `s=1` means the
# elasticity of substitution is one. These can take any positive value or can be
# parameters.

# In the $X$ production block we are going to have a tax on each input. In this 
# case the tax is the same on each, but this is not necessary. A tax has two 
# parts, the value and the absorbing consumer. There can be any number of taxes 
# in the tax vector. 

@production(M, X, [t=0, s=1], begin
    @output(PX, 100, t)
    @input(PL, 25, s, taxes = [Tax(CONS, TX)])
    @input(PK, 75, s, taxes = [Tax(CONS, TX)])
end)


# The production block is printed in a concise format for easy reading.  

@production(M, Y, [t=0, s=1], begin
    @output(PY, 100, t)
    @input(PL, 75, s)
    @input(PK, 25, s)
end)    

@production(M, W, [t=0, s=1], begin
    @output(PW, 200, t)
    @input(PX, 100, s)
    @input(PY, 100, s)
end)

@demand(M, CONS, begin
    @final_demand(PW, 200)
    @endowment(PL, 100*labor_endowment)
    @endowment(PK, 100)
end)

# There is only one demand block since there is only one consumer. Consumers 
# have final demands and endowments.


# ## Benchmark Replication

# Finally, we fix the price of $PW$ to one. This is not necessary, but it sets 
# a numeraire for the model. If you do not set a numeraire, MPSGE will set the
# numeraire to the consumer with the largest total income. This is reported to 
# the user when the model is solved. 

# We will be solving this model at the benchmark, which means setting all 
# variables to their default value and verifying the equations are satisfied. 
# We do this by setting the cumulative iteration limit to zero in the solve call.

fix(PW, 1)

solve!(M, cumulative_iteration_limit=0)

# It's useful to read PATH output to understand what is happening in the model.
# If your data is balanced and the `Postsolved Residual` is non-zero then your 
# model has a specification error and you need to check your input quantities.

# A useful debugging tool is the [`generate_report`](@ref) function. This will
# create a DataFrame with the model equations and the residuals. If your model
# fails the benchmark look for non-zero margins in this report, odds are that 
# will reveal your error.

generate_report(M)

# ## Counterfactuals

# We can now use the model to perform counterfactuals. A counterfactual is a 
# change to one, or more, of the model parameters and analyzing the effect on
# the model.

# The first counterfactual is to increase the tax rate on sector $X$ inputs. We
# will set the tax rate to 0.5 and resolve the model. For emphasis we will also
# specify `labor_endowment` is 1, which is the benchmark value.

set_value!(TX, 0.5)
set_value!(labor_endowment, 1)

solve!(M)

generate_report(M)

# For the second counterfactual we set the labor endowment multiplier to 2 and 
# reset the tax rate to 0. 

set_value!(TX, 0)
set_value!(labor_endowment, 2)

solve!(M)

generate_report(M)
