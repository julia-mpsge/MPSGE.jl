##### Add the MPSGE package
##### Activate the package with 
```
using MPSGE
```
Start by naming the model using any Julia-legal variable name, without spaces etc. The Julia style guide suggests lower case for variable names.
``` 
m = Model()
```
## Store the model elements ready for build by adding them
!!! note
      * Scalars and arrays can be used to provide values, inlcuding for model parameters like elasticities, but can not be changed within the model in counterfactuals, so any value that needs to be updated should be added as a model Parameter.
      * To access model Parameters in model functions, at this point they must be part of expressions, so for referencing the value of `elast`, it must be within an evaluated expression :(1 * $elast).
      * The model can be built in any order, so long as all elements referred to have been previously defined. For that reason a standard structure is: load the data, scalars, indexes; add model parameters, sectors, commodities, auxiliary variables, and consumers; add production and demand functions, and auxilliary constraint equations.

#### Add data
Use DenseAxisArrays for any data that's indexed, including a table. Use 'missing' to hold any spaces (see [example 5](https://github.com/anthofflab/MPSGE.jl/blob/main/examples/example5.jl)). For a simple scalar model, it's straightforward just to use the values when defining the elements, but we'll include a DenseAxisArray for illustration.
```
MPSGE.JuMP.Containers
sampleindex = [:x]
data = DenseAxisArray(Float64[100], sampleindex)
```
#### Add Parameters
!!! note
    There is a 'functional' and macro version for all model definition elements. The macro versions *may* lag while the package is still in development.\
    We show both here - they are equivalent.
```
sub_elas_x = add!(m, Parameter(:sub_elas_x, value=1.5, description="Substitution elasticity between labor and kapital in sector X"))

# Without the optional description
sub_elas_y = add!(m, Parameter(:sub_elas_y, value=2.))

# The macro version
@parameter(m, sub_elas_u, 0.5)
@parameter(m, transf_elas_y, 0., description="Transformation Elasticity for sector Y, irrelevant because there's only 1 output")
```
#### Add Commodities, default benchmark price=1
```
PX = add!(m, Commodity(:PX))
PY = add!(m, Commodity(:PY), benchmark=1.)
PU = add!(m, Commodity(:PU, description="The Utility Commodity"))
@commodity(m, PU)
@commodity(m, PL)
@commodity(m, PK)
```
#### Add Sectors
```
@sector(m, X)
Y = add!(m, Sector(:Y))
@sector(m, U, description="Sector U")
```
#### Add Consumer(s)
Here the benchmark value is important. This value will be the sum of endowments any taxes transferred to the consumer in the benchmark callibration of the model.
```
@consumer(m, RA, benchmark = 150., description="Representative Agent")
```
#### Add Production Functions
!!! note
    Outputs and Inputs are within `[]` Arrays, even if single.  Outputs must always be first.
```
add!(m, Production(X,:($transf_elas_x*1.), :($sub_elas_x*1.), [Output(PX, data[:x])], [Input(PL, 50), Input(PK, 50)]))
@production(m, Y, :($transf_elas_y*1.), :($sub_elas_y*1.), [Output(PY, 50)], [Input(PL, 20), Input(PK, 30)])
@production(m, U, 0, :($sub_elas_u*1.), [Output(PU, 150)], [Input(PX, 100), Input(PY, 50)])
```
#### Add Demand Functions
```
@demand(m, RA, 1., [Demand(PU, 150)], [Endowment(PL, :(70 * $endow)), Endowment(PK, 80.)])
```
## Check the benchmark solution
After the model is established and saved under the model name, it is standard to check that the model is mathematically balanced in the benchmark by solving with 0 iterations.
```
solve!(m, cumulative_iteration_limit=0)
```
If the model solves with zero iterations, we know that the model and data are balanced and callibrated in the benchmark. 
    If not, you will get an error  ``` Did not solve with error: CumulativeMinorIterationLimit.```\  
    The ``` Major Iteration Log ``` from PATH will display the variable(s), preceded by "F_" ```(label)``` with the largest marginal value, that is the variables that have the ```residual```/solved value or ```inorm```that is larger than the tolerance set, which can be useful for troubleshooting.\  
    You can also run `solve!(m)` without the iteration limit and examine the values for all variables for more clues as to where the benchmark may be unbalanced.
## See the underlying model equations
You can print the equations and their associated variables.
```
algebraic_version(m)
```
## Run Counterfactuals
Once the benchmark is established, update variable values and/or parameters, fix or unfix variables etc. and see the solution as in the simulated counterfactual scenario.
```
# increase labor endowment by 10%
set_value(endow, 1.1)
# Set the consumer RA as the numeraire
set_fixed!(RA, true)
solve!(m)
```