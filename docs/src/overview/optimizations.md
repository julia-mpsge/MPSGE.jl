# Optimizations

This section is going to detail some of the optimizations that MPSGE employs to speed up model construction and solving. This is what sets MPSGE apart from explicitly writing the equivalent model in JuMP.

## Subexpressions

The first major optimization is the use of subexpressions to reduce the size of the generated JuMP model. Cost functions can get very large, depending on the nesting and index, and get used multiple times in the model. To avoid multiple evaluations of large expressions, MPSGE stores cost functions as variables in the JuMP model. This significantly reduces the size of the generated model and speeds up solving time as large expressions do not need to be re-evaluated.


!!! note "PATH Instability"
    The PATH solver may be slightly unstable when there are a large number of subexpressions. We are working on recommendations to mitigate this issue.

## What the Model stores

An MPSGE Model stores references to objects to make constructing the constraints faster. Specifically, the model stores the following mappings:

- Sectors to their production blocks.
- Consumers to their demand blocks.
- Commodities to a list of sectors that produce/consume them.
- Commodities that consumers demand/endow them. 

Each of these is designed to make constructing the model equations faster by avoiding searching through all production/demand blocks. For example, consider calculating the market clearance constraint for a commodity. Instead of searching through all production blocks to find which sectors produce/consume the commodity, we can simply look up the list of sectors that produce/consume the commodity in the model's mapping. When first implemented this resulted in a significant speedup for large models.
