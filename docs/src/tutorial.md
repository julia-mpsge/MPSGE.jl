Add the MPSGE package <p>
Activate the package with 
```
using MPSGE
```
Start by naming the model using any Julia-legal variable name, without spaces etc. The Julia style guide suggests lower case for variable names.
``` 
m = Model()
```
## Build the model by adding all the elements
!!! note
Scalars and arrays can be used to provide values, inlcuding for model parameters like elasticities, but can not be changed within the model in counterfactuals, so any value that needs to be updated should be added as a model Parameter.<br>
Add Parameters <br>
```
P = add!()
```
Add Commodities
```
C = add!()
```

## Check the benchmark solution
After the model is established and saved under the model name, it is standard to check that the model is mathematically balanced in the benchmark by solving with 0 iterations.
```
solve!(m, cumulative_iteration_limit=0)
```