# Tutorial 1: basics
!!! note    
    This tutorial assumes you have 
    - installed Julia, for example from [here](https://apps.microsoft.com/store/detail/julia/9NJNWW8PVKMN?hl=en-us&gl=us&rtc=1), or [here](https://julialang.org/downloads/), and
    -  [installed](https://anthofflab.berkeley.edu/MPSGE.jl/dev/) the MPSGE package, 
    - have some kind of source-code editor/Integrated Development Environment (IDE), for example the free [VS Code](https://code.visualstudio.com/), with the [julia Language Support extension](https://github.com/julia-vscode/julia-vscode#installing-juliavs-codevs-code-julia-extension) also recommended, or otherwise are able to run Julia code, 
    - have a basic understanding of [Julia syntax](https://docs.julialang.org/en/v1/manual/getting-started/), and
    - have a [general understanding of CGE and the MPSGE structure](./explanation.md).
This first tutorial follows the first section in [example 1](https://github.com/anthofflab/MPSGE.jl/blob/main/examples/example1.jl) from our code repository, which is an edited translation of the [simple 2x2 example model](https://www.gams.com/latest/docs/UG_MPSGE_Intro.html#UG_MPSGE_Intro_Appendix_twobytwo) from the GAMS MPSGE documentation.
###### You can run the commands line-by-line wherever you run Julia code, or all together as a .jl script, either transcribing, or copying and pasting from here, or [example 1](https://github.com/anthofflab/MPSGE.jl/blob/main/examples/example1.jl).  

##### Activate the package with 
```julia-repl
julia>using MPSGE
```
Start by naming the model using any Julia-legal variable name, without spaces etc. The Julia style guide suggests lower case for variable names.
```julia-repl 
m = Model()
```
## Store the model elements ready for build by adding them
As in the [overview explanation](./explanation.md), each model will have a number on elements. We store all those elements
in the named model, and then we can test, solve, alter, print, re-solve e.t.c.
!!! note
      * Scalar values and arrays can be used to provide values for data and parameters such as elasticities, but cannot be tracked or changed within the model and counterfactuals, so any value that needs to be updated should be added as a model Parameter.
      * After being defined, asimmediately below, in order to access model Parameters within other model elements, they must be part of expressions (like a sentence of code). So, for referencing the value of `sub_elas_x`, it must be within an evaluated expression, like  
      * ```
        :(1 * $sub_elas_x)
        ```
        including being multiplied by a scalar, or in some other equation, rather than just `sub_elas_x` 
       - The model can be built in any order, so long as all elements referred to have been previously defined. For that reason a standard structure is: load the data, scalars, indexes; add model parameters, sectors, commodities, auxiliary variables, and consumers; add production and demand functions, and auxilliary constraint equations.
       - Extra spaces aren't a problem in Julia, so can we align parallel elements - for instance the elements of the 3 Parameters immediately below - to help readability.
### Add Parameters
We'll start by defining 6 Paramters, and giving them a value. Each is just a name with a number attached, but defining them within the model as Parameters, instead of just using the numbers, or a Julia variables, allows us to update those values for future runs/solves or the model.
```julia
# Adding a Parameter with the optional description
sub_elas_x    = add!(m, Parameter(:sub_elas_x,    value=1.5, description="Substitution elasticity between labor and kapital in sector X"))
# Adding Parameters without the optional description
sub_elas_y    = add!(m, Parameter(:sub_elas_y,    value=2.))
transf_elas_x = add!(m, Parameter(:transf_elas_x, value=0.))
```
!!! note
    There is a 'functional' and macro version (begninning with @) for all model definition elements. The macro versions *may* lag in terms of incorporating all elements while the package is still in development.
    We show examples of both versions here as part of this tutorial, they are equivalent.
#### The macro version for adding Parameters
```julia 
@parameter(m, sub_elas_u,    0.5)
@parameter(m, transf_elas_y, 0.,  description="Transformation Elasticity for sector Y, actually irrelevant because there's only 1 output")
@parameter(m, endow, value = 1.0)
```
### Add Commodities
Commodities are one of the basic elements in an MPSGE model, they are produced by sectors/firms, factors used in the production of other commodities, or both. Here again, we show both the 'functional' and macro versions for adding these elements, with and without the options of a description, or a 'benchmark' price. The default benchmark price is 1. To set a different price or to articulately set it as 1, use the keyword `benchmark=`, and similarly, to include an optional description, use the keyword `description=`, as below.
```julia
PX = add!(m, Commodity(:PX))
PY = add!(m, Commodity(:PY, benchmark=1.))
PU = add!(m, Commodity(:PU, description="The Utility Commodity"))
# The macro version
@commodity(m, PL, description="wage: the price of labour")
@commodity(m, PK, benchmark=1.)
```
### Add Sectors
Sectors use commodities (Inputs), and generate commodities (Outputs).
```julia
X = add!(m, Sector(:X))
@sector(m, Y)
@sector(m, U, description="Sector U: This 'sector' uses the two produced goods to generate utility")
```
### Add a Consumer
For Consumers in the model the benchmark value is important. In the benchmark callibration of the model, this value will be the sum of endowments, plus the value of any taxes transferred to the consumer.
```julia
@consumer(m, RA, benchmark = 150., description="Representative Agent")
```
### Add Production Functions
Here we define a production function for every sector/firm. That is:
- what commodities are used by the sector and in what quantities,
- what commodities are produced by the sector and in what quantities,
- how interchangeable are the inputs (substitution elasticities)
- how interchangeable are the outputs (transformation elasticities),
- what taxes are paid, if any, and
- what price per unit of each commodity (default is 1. for all commodities as is standard the convention for CGE models)
!!! note
    Outputs and Inputs are within `[]` Arrays, even if there is only one.  Outputs must always be first.
    * Production Functions don't need names assigned (that is we don't have **X =** `add!(m, Production(...))`) bc they are named by the sector.
```julia
add!(m, Production(X, :($transf_elas_x*1.), :($sub_elas_x*1.), [Output(PX, 100)], [Input(PL, 50),  Input(PK, 50)]))
@production(m,     Y, :($transf_elas_y*1.), :($sub_elas_y*1.), [Output(PY, 50)],  [Input(PL, 20),  Input(PK, 30)])
@production(m,     U, 0,                    :($sub_elas_u*1.), [Output(PU, 150)], [Input(PX, 100), Input(PY, 50)])
```
### Add Demand Functions
The Demand function defines the basic supplies that enter our modelled economy (endowments),  which come from 'consumers', and their final consumption. Final consumption is the end point of a commodity's production cycle, as the name suggests. Commodities demanded are assumed to be consumeed at that point, or at least kept, and and not used in any production in the modelled part of the economy Consumers can be households, governments, or other agents. In the benchmark callibration of a model, the total value of the consumers contributions (endowments) must equal the value of their total demands.
```
@demand(m, RA, 1., [Demand(PU, 150)], [Endowment(PL, :(70 * $endow)), Endowment(PK, 80.)])
```
## Check the benchmark solution
After the model is established and saved under the model name, it is important to check that the model is mathematically balanced in the benchmark by solving with 0 iterations. This will only solve if all elements of the model are in balance, that is:
- total supply of each commodity = its total demand
- the value of the inputs for each sector and consumer = their outputs
- the value of all inputs in each sector = the value of all the sector's outputs.
```
solve!(m, cumulative_iteration_limit=0)
```
If the model solves with zero iterations, we know that the model and data are balanced and callibrated in the benchmark. 
    If not, you will get the error  ``` Did not solve with error: CumulativeMinorIterationLimit.```  
!!! tip    
    The ``` Major Iteration Log ``` from PATH will display the variable(s), preceded by "F_" ```(label)``` with the largest marginal value, that is the variables that have the ```residual``` solved value or ```inorm```that is larger than the tolerance set, which can be useful for troubleshooting.  
    You can also run `solve!(m)` without the iteration limit and examine the values for all variables for more clues as to where the benchmark may be unbalanced.
## See the underlying model equations
You can print all the equations and their associated variables.
```
algebraic_version(m)
```
## Run Counterfactuals
Once the benchmark is established, update variable values and/or parameters, fix or unfix variables etc. and see the solution as in the simulated counterfactual scenario.
###### Example: Increase labor endowment by 10%
We used the paramater we called `endow`, initially set at a value of 1.0, to enable us to alter the total amount/value of the endowments of labour and see its effect on our toy economy. By setting the value of `endow` as 10% higher, at 1.1, we alter the model to increase the amount of labour in this economy by 10%.
```julia
set_value(endow, 1.1)
```
###### And set the consumer RA as the numeraire
Because all the changes in our results are relative, it is usually useful to select a variable to serve as the 'numeraire', that is, a variable whose value is fixed and set such that all the other changes can be interpreted in relative terms to that variable.
```julia
set_fixed!(RA, true)
solve!(m)
```
Or we can look at the results relative to the price of the commodity PX.
```julia
set_fixed!(RA, false)
set_fixed!(PX, true)
solve!(m)
```
Or we can look at the results relative to wages, the price of labour in our toy economy.
```julia
set_fixed!(PX, false)
set_fixed!(PL, true)
solve!(m)
```
Or here we test the impact of different set of assumptions about how interchangeable kapital and labour are in the X and Y sectors.
```julia
# Re-running with non-1 elasticities of substitution, non-Cobb-Douglas forms for production in the cost function
set_value(sub_elas_x, 0.5)
set_value(sub_elas_y, 0.6)
set_fixed!(RA, true)
solve!(m)

set_fixed!(PX, true)
set_fixed!(RA, false)
solve!(m)

set_fixed!(PX, false)
set_fixed!(PL, true)
solve!(m)
```
