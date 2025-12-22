# Demand Blocks

!!! note "Warning"
    Demand blocks will be undergoing significant changes in future releases. We will highlight where changes are likely to occur. The current implementation is stable.

Demand blocks collect the final demands and endowments for each consumer. In MPSGE, demand blocks are created using the [`@demand`](@ref) macro. 

## Final Demands

Each consumer demands goods, defined by the [`@final_demand`](@ref) macro. It is possible that these goods are the result of a production process, with nestings and elasticities. Because of this you can view final demands as an input from a production block. Currently, this is restricted to a single nest. This is related to [Issue #161](https://github.com/julia-mpsge/MPSGE.jl/issues/161).



### Proposal to Change

Here is an example of a current demand structure with a non-trivial nest:
```julia
@demand(M, RA, begin
    @final_demand(X, Qx)
    @final_demand(Y, Qy)
    @final_demand(Z, Qz)
    @endowment(L, L0)
end; elasticity = 5)
```

I propose that we change this to:

```julia
@sector(M, X_RA)
@commodity(M, PX_RA)

@production(M, X_RA, [s=5, t=0], begin
    @output(PX_RA, Qx+Qy+Qz, t)
    @input(X, Qx, s)
    @input(Y, Qy, s)
    @input(Z, Qz, s)
end)

@demand(M, RA, PX_RA, begin
    @endowment(L, L0)
end)
```

There are several advantages to this approach. First, it reduces code duplication between production and demand blocks. Currently, a lot of the code to deal with building cost functions needs to be duplicated between production and demand blocks. Second, it allows for more complex nestings structures in the demand side. Currently, we are limited to a single nest in the demand block, but with this approach, we can have arbitrary nest structures. Third, it makes the model structure more explicit. By defining a sector and commodity for each consumer's demand, it is clear what goods are being demanded and how they are produced. Finally, it simplifies the process of extracting information from the model. With this approach, we can easily extract compensated demands for the consumers goods using existing production block functionality.

Of course, the primary disadvantage is that it requires more code to define the demand structure. There are also concerns that this approach will make some information more difficult to extract. 


## Endowments

Endowments are straightforward, they are defined using the [`@endowment`](@ref) macro within a demand block. Endowments are simply quantities of goods that a consumer provides to the market at a certain price. You can think of endowments as outputs from the consumer to the market.

## Tax Revenue

Tax revenue is not explicitly defined in demand blocks. Instead, tax revenue is collected from the taxes applied to netputs in production blocks. Each tax specifies a consumer that receives the tax revenue. This tax revenue is automatically accounted for the income condition.