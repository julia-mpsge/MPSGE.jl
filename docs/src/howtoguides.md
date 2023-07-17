# How-tos
#### Add data
Use DenseAxisArrays for any data that's indexed, including a table. Use 'missing' to hold any spaces (see [example 5](https://github.com/anthofflab/MPSGE.jl/blob/main/examples/example5.jl)). For a simple scalar model, it's straightforward just to use the values when defining the quantities in Outputs and Inputs, but here's a single index DenseAxisArray for illustration.
```julia
using MPSGE.JuMP.Containers
sampleindex = [:x]
data = DenseAxisArray(Float64[100], sampleindex)
```
