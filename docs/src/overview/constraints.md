# Model Equations

CGE models have three classes of constraints:

- Zero Profit - All money earned is allocated.
- Market Clearance - All goods produced are consumed.
- Income Balance - All income earned is spent.

MPSGE builds these equations automatically based on the production and demand blocks defined in the model. Before detailing exactly how these equations are built, we need to first discuss compensated demands.

## Compensated Demand

Sectoral profit is given by the difference between total revenue and total cost. Each production block defines the inputs (costs) and outputs (revenues) of a sector. In MPSGE syntax, the profit of a sector is given by:
```julia
revenue_function(X) - cost_function(X)
```
The compensated demand is defined for a sector and commodity, it is the derivative of profit with respect to the _tax adjusted_ price. If $\Pi_X$ is the profit of sector $X$ and $\bar{P}_C$ is the tax adjusted price of commodity $C$, then the compensated demand, $CD_{X,C}$, is given by:
```math
CD_{X,C} = \frac{\partial \Pi_X}{\partial \bar{P}_C}
```

By [Hotelling's Lemma](https://en.wikipedia.org/wiki/Hotelling%27s_lemma), we can view compensated demand as the "quantity" of good $C$ purchased/sold by sector $X$. To recover the adjusted "reference quantity", we need to multiply the compensated demand by the activity level $X$. The activity level adjusts the compensated demand to reflect changes in sectoral production given a shock to the economy.

!!! note "GAMS Report Block"
    In GAMS, the report block in MPSGE reports the compensated demand times the sectoral activity level.

Finally, we can compute the total value of good $C$ purchased/sold by sector $X$ by multiplying the adjusted quantity by the price:
```math
C\cdot X\cdot CD_{X,C}
```


## Zero Profit

This constraint is self explanatory, each sector's total revenue must equal its total cost. The actual constraint is:
```math
-\Pi_X = 0 \perp X
```
The reason we specify negative profit is that MPSGE uses the PATH Solver which is an oriented solver. You can think of this as PATH using an inequality constraint of the form $f(x) \geq 0$. By specifying negative profit, we ensure the inequality is oriented correctly. 


## Market Clearance

This constraint ensures that for each commodity, total supply equals total demand. Luckily, we've already established how to compute supply and demand using compensated demands. For a fixed commodity $C$, the total supply is the sum over all sectors, $X$, of $X\cdot CD_{X,C}$, plus any endowments provided by consumers minus any demands from consumers. The market clearance constraint is therefore:

```math
\sum_{X} X\cdot CD_{X,C} + \sum_{H\in {\rm consumers}} E_{H,C} - \sum_{H\in {\rm consumers}} D_{H,C} = 0 \perp C
```

Where $E_{H,C}$ is the endowment of good $C$ from consumer $H$. The term $D_{H,C}$ is the demand of good $C$ from consumer $H$, defined as
```math
D_{H,C} = \frac{Q_C}{Q_H}\cdot \frac{H}{C}
```
where $Q_C$ is the quantity of good $C$ demanded by consumer $H$ and $Q_H$ is the total quantity of all goods demanded by consumer $H$.


## Income Balance

The income balance constraint sets the total income of each consumer. The total income is defined to be the sum of endowments plus tax revenue. For a fixed consumer $H$, the income balance constraint is given by:

```math
H = \sum_{C} E_{H,C} \cdot P_C + \sum_{S\in{\rm sectors}} \sum_{C\in{\rm commodities}} \tau_{S,C,H} \cdot C \cdot S \cdot CD_{S,C} \perp H
```
The first term is straight forward, it is the total value of endowments provided by consumer $H$. The second term is the total tax revenue received by consumer $H$. Here, $\tau_{S,C,H}$ is the tax rate applied to sector $S$ for commodity $C$ that is paid to consumer $H$.



!!! note "Income Balance?"
    This isn't so much of a constraint as it is a definition of the variable $H$, which is the total income of consumer $H$. In a way, this is a sub-expression representing total income.