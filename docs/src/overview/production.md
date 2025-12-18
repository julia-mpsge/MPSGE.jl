# Production Blocks

Production blocks build cost functions. To build a cost function, we need to specify the inputs (costs) and outputs (revenues) of the production process. In MPSGE, production blocks are created using the [`@production`](@ref) macro. The documentation for the `@production` macro does a great job of explaining the syntax and options available when defining a production block, but there is a lot going on behind the scenes that is not immediately obvious. This section aims to clarify some of those details.

## Netputs

A netput is general term for an [`@input`](@ref) or [`@output`](@ref). A netput is a leaf in the production tree structure, acting as the initial information for building the cost functions. A netput stores the following information:

- `commodity`: A commodity variable acting as the price.
- `quantity`: This acts more as a reference quantity. If the reference price is 1 this can be thought of as the total value exclusive of tax. This will be discussed below.
- `parent`: The nest that this netput belongs to.
- `reference_price = 1`: The price at the reference quantity, defaulting to 1.
- `taxes = []`: A vector of taxes applied to this netput, defaulting to no taxes.
- `netput_sign`: A value of `-1` for inputs and `1` for outputs.

The "cost function" of a netput is the adjusted price. For example, if the commodity is $P$, the reference price is $P_0$, and there is are taxes $\tau_i$, then the final price, $\bar{P}$, of the netput is given by:

```math
\bar{P}  = \frac{P\cdot(1 \mp \sum_i \tau)}{P_0}
```

where the $\mp$ is determined by the `netput_sign` (use `-` for outputs and `+` for inputs). 

!!! note "$\mp$ vs $\pm$"
    I've used $\mp$ here to indicate that the sign is opposite of the netput sign. This may change in the future, but will be documented clearly if it does.

If $Q$ is the reference quantity, then the effective quantity, $\bar{Q}$, is given by:

```math
\bar{Q} = Q \cdot P_0
```

Using this, the total value at the benchmark point is given by:
```math
\bar{P}\cdot \bar{Q} = P\cdot Q \cdot (1 \mp \sum_i \tau)
```

Notice that on the input side, the reference quantity should be **exclusive** of taxes, while on the output side, the reference quantity should be **inclusive** of taxes. The corresponding tax revenue is assigned to the consumer specified in the tax definition.

## Nests

The third argument to the [`@production`](@ref) macro is a list of nests with elasticities. These nests define a tree structure that describes how inputs/outputs are combined in the production process. 

There must always be exactly two nests with no parents, which represent the top-level input and output nests. These are denoted `nest_name = elasticity`. By convention we use `s` for the input nest, short for `elasticity of substitution` and `t` for the output nest, short for `elasticity of transformation`. However, we are free to use any names we like for the nests. Top level nests are not allowed to be indexed, mathematically these are defining the roots of the input and output trees.

Lower-level nests are defined using the syntax `child_nest => parent_nest = elasticity`, which indicates that `child_nest` is a child of `parent_nest` with the specified elasticity. Child nests can be indexed, for example if goods can be obtained per region and each region has its own elasticity, you could define `region_nest[r=region] => s = elasticity[r]`. 

!!! note "Images"
    This section could use some images to illustrate the nest structure.

!!! note "Nest Names"
    Nests have names given by the base name and index. However, it is currently not clear how to access nests by name. This will be updated soon.

## Nodes

Nodes are not typically used by the end user, but they are important to understand how MPSGE builds cost functions. A node is an internal representation of a non-leaf vertex in the production tree. Each node stores the following information:

- `model`: A reference to the MPSGE model.
- `parent`: The parent node, defaults to `nothing` for the root nodes.
- `children`: A vector of child nodes or netputs.
- `data`: A reference to the nest that defines the node
- `cost_function_virtual`: The variable representing the cost function at this node.
- `cost_function`: The cost function associated with the node.
- `netput_sign`: A value of `-1` for input nests and `1` for output nests.

!!! note "Refactoring Nodes"
    Nodes are in need of refactoring. There are many places where the code is more complicated than it needs to be and could be improved for performance. This will be addressed in a future release.

Nodes are responsible for building and storing the cost functions. Cost functions are built recursively, the cost function for a node depends on the cost functions of its children. Cost functions can get large and may be repeated many times. Because of this, an optimization is performed where cost functions are stored as variables in the underlying JuMP model. This significantly reduces the size of the generated model and speeds up solving time as large expressions do not need to be re-evaluated.

## Building Cost Functions

Cost functions are built recursively starting from the leaves of the production tree (the netputs) and working up to the root nodes. This process will best be described with an example. 

We will focus on the input side, as the output side is analogous. Consider a production block with the following structure:
```
          (s)
         /   \
        /     \
(P_X, Q_X)    (P_Y, Q_Y)
```
Or one top level nest `s` with two inputs `X` and `Y`. The cost functions for the two leaves are given above. Let $Q_T = Q_X + Q_Y$ be the total reference quantity for the nest `s`. The CES cost function with elasticity $\sigma\ne1$ for the top-level nest `s` is given by:
```math
\begin{align*}
  CF(s) = &  Q_T \cdot \left( \frac{Q_X}{Q_T}\cdot CF(X)^{1-\sigma} + \frac{Q_Y}{Q_T}\cdot CF(Y)^{1-\sigma}   \right) ^ {\frac{1}{1-\sigma}} \\
   = & Q_T \cdot \left( \frac{Q_X}{Q_T}\cdot (P_X)^{1-\sigma} + \frac{Q_Y}{Q_T}\cdot (P_Y)^{1-\sigma}   \right) ^ {\frac{1}{1-\sigma}}
\end{align*}
```

!!! note "Clarity"
    This is feels a little off. Verify this is correct and generalizes correctly.

This example generalizes to more complex nest structures by recursively applying the same logic. Each node computes its cost function based on the cost functions of its children, ultimately leading to the top-level cost functions for inputs and outputs.

!!! note "More Detail"
    This section could be expanded with more mathematical detail and examples. Consider adding examples with multiple nests and indexed nests.