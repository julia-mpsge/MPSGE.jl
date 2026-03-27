""" 
    CompetitiveDirect

This module provides a direct translation of the GAMS code in `bigmps.gms` into 
Julia using the MPSGE framework. Variable names have not been changed from the 
GAMS code. Note that initial parameter values are set earlier in this version of
the model.

The only provided function is `competitive_model`, which constructs the MPSGE model.
The documentation string for this function provides a detailed description of the model.

# Example

```julia
using .CompetitiveDirect

M_direct = CompetitiveDirect.competitive_model(1:9, 1:11, [:L, :K], 1:11)

solve!(M_direct)
df_direct = generate_report(M_direct)


df_direct |>
    x -> subset(x, :value => ByRow(==(0)))
```
"""
module CompetitiveDirect

    using MPSGE
    using JuMP
    import MPSGE.PATHSolver
    using DataFrames


    """
        competitive_model(I::UnitRange, J::UnitRange, F::Vector{Symbol}, G::UnitRange)

    Constructs a competative model using the MPSGE framework. This is a direct translation
    of the GAMS code in `bigmps.gms`, without any special Julia structures. The model is parameterized
    by the number of countries (I), the number of sectors (J), the set of factors (F), and the set of goods (G).

    # Arguments

    - `I::UnitRange`: A range representing the number of countries.
    - `J::UnitRange`: A range representing the number of sectors.
    - `F::Vector{Symbol}`: A vector of symbols representing the factors (e.g., `[:L, :K]`).
    - `G::UnitRange`: A range representing the number of goods.

    # Returns

    - `M::MPSGEModel`: An instance of the MPSGE model representing the competitive equilibrium.

    # Model Description

    ## Parameters

    ```julia
    @parameters(M, begin
        TC[i=I],              1.45-.05*i,                        (description = "Trade cost of country i")
        ENDOW[i=I, j=J, f=F], ifelse(f == :K, 120 - 10*j, 10*j), (description = "Country i's endowment j factor f")
        FX[f=F, g=G],         ifelse(f==:K, 120 - 10*g, 10*g),   (description = "Factor f's share in good g")
        SCALE,                1,                                 (description = "Size of fringe in countries")
    end)

    set_value!(TC[end], 1.0000025)
    ```

    ## Sectors

    ```julia
    @sectors(M, begin
        X[i=I,j=J ,g=G] ,  (description = "production activity for good g")
        EX[i=I,j=J,g=G] ,  (description = "export activity for good g")
        IX[i=I,j=J,g=G] ,  (description = "import activity for good g")
        XX[i=I,j=J,g=G] ,  (description = "supply of domestically produced g to home")
        W[i=I,j=J]      ,  (description = "welfare of country ij")
    end)
    ```

    ## Commodities

    ```julia
    @commodities(M, begin
        PW[i=I,j=J]     , (description = "utility price index for country j")
        PX[i=I,j=J,g=G] , (description = "domestic producer price (mc) of good G")
        PCX[i=I,j=J,g=G], (description = "domestic consumer price of good G")
        PF[i=I,j=J,f=F] , (description = "price of factor F in country ij")
        PFX[g=G]        , (description = "world (central market) price of good G")
    end)
    ```

    ## Consumer

    ```julia
    @consumer(M, CONS[i=I,j=J], description = "Income of representative consumer in ij")
    ```

    ## Production

    ```julia
    @production(M, X[i=I, j=J, g=G], [t=0, s=1], begin
        @output(PX[i,j,g], 100, t)
        @input(PF[i, j, f=F], FX[f,g], s)
    end)

    @production(M, EX[i=I, j=J, g=G], [t=0, s=0], begin
        @output(PFX[g], 100, t)
        @input(PX[i, j, g], 100*TC[i], s)
    end)

    @production(M, IX[i=I, j=J, g=G], [t=0, s=0], begin
        @output(PCX[i, j, g], 100, t)
        @input(PFX[g], 100*TC[i], s)
    end)

    @production(M, XX[i=I, j=J, g=G], [t=0, s=0], begin
        @output(PCX[i, j, g], 100, t)
        @input(PX[i, j, g], 100, s)
    end)

    @production(M, W[i=I, j=J], [t=0, s=1], begin
        @output(PW[i, j], 100, t)
        @input(PCX[i, j, g=G], 100, s)
    end)
    ```

    ## Demand

    ```julia
    @demand(M, CONS[i=I,j=J], begin
        @final_demand(PW[i,j], sum(ENDOW[i,j,f] for f in F))
        @endowment(PF[i,j,f=F], ENDOW[i,j,f])
    end)
    ```
    """
    function competitive_model(I::UnitRange, J::UnitRange, F::Vector{Symbol}, G::UnitRange)

        M = MPSGEModel()
        
        @parameters(M, begin
            TC[i=I],          ifelse(i<length(I), 1 + length(I)*.05-.05*i, 1.0000025), (description = "Trade cost of country i")
            ENDOW[i=I, j=J, f=F], ifelse(f == :K, 120 - 10*j, 10*j), (description = "Country i's endowment j factor f")
            FX[f=F, g=G],         ifelse(f==:K, 120 - 10*g, 10*g),   (description = "Factor f's share in good g")
            SCALE,                1,                                 (description = "Size of fringe in countries")
        end)

        @sectors(M, begin
            X[i=I,j=J ,g=G] ,  (description = "production activity for good g")
            EX[i=I,j=J,g=G] ,  (description = "export activity for good g")
            IX[i=I,j=J,g=G] ,  (description = "import activity for good g")
            XX[i=I,j=J,g=G] ,  (description = "supply of domestically produced g to home")
            W[i=I,j=J]      ,  (description = "welfare of country ij")
        end)

        @commodities(M, begin
            PW[i=I,j=J]     , (description = "utility price index for country j")
            PX[i=I,j=J,g=G] , (description = "domestic producer price (mc) of good G")
            PCX[i=I,j=J,g=G], (description = "domestic consumer price of good G")
            PF[i=I,j=J,f=F] , (description = "price of factor F in country ij")
            PFX[g=G]        , (description = "world (central market) price of good G")
        end)

        @consumer(M, CONS[i=I,j=J], description = "Income of representative consumer in ij")





        @production(M, X[i=I, j=J, g=G], [t=0, s=1], begin
            @output(PX[i,j,g], 100, t)
            @input(PF[i, j, f=F], FX[f,g], s)
        end)

        @production(M, EX[i=I, j=J, g=G], [t=0, s=0], begin
            @output(PFX[g], 100, t)
            @input(PX[i, j, g], 100*TC[i], s)
        end)

        @production(M, IX[i=I, j=J, g=G], [t=0, s=0], begin
            @output(PCX[i, j, g], 100, t)
            @input(PFX[g], 100*TC[i], s)
        end)

        @production(M, XX[i=I, j=J, g=G], [t=0, s=0], begin
            @output(PCX[i, j, g], 100, t)
            @input(PX[i, j, g], 100, s)
        end)

        @production(M, W[i=I, j=J], [t=0, s=1], begin
            @output(PW[i, j], 100, t)
            @input(PCX[i, j, g=G], 100, s)
        end)

        @demand(M, CONS[i=I,j=J], begin
            @final_demand(PW[i,j], sum(ENDOW[i,j,f] for f in F))
            @endowment(PF[i,j,f=F], ENDOW[i,j,f])
        end)

        fix(PFX[div(length(G),2)+1], 1)

        return M

    end


    function mcp_competitive_model(I::UnitRange, J::UnitRange, F::Vector{Symbol}, G::UnitRange)
         M = Model(PATHSolver.Optimizer)
    
        @variables(M, begin
            TC[i=I] in JuMP.Parameter(ifelse(i<length(I), 1 + length(I)*.05-.05*i, 1.0000025))
            ENDOW[i=I, j=J, f=F] in JuMP.Parameter(ifelse(f == :K, 120 - 10*j, 10*j))
            FX[f=F, g=G] in JuMP.Parameter(ifelse(f==:K, 120 - 10*g, 10*g))
            SCALE in JuMP.Parameter(1)
        
            X[i=I, j=J, g=G] >= 0,   (start = 1)
            EX[i=I, j=J, g=G] >= 0,  (start = 1)
            IX[i=I, j=J, g=G] >= 0,  (start = 1)
            XX[i=I, j=J, g=G] >= 0,  (start = 1)
            W[i=I, j=J] >= 0,        (start = 1)
        
            PW[i=I, j=J] >= 0,       (start = 1)
            PX[i=I, j=J, g=G] >= 0,  (start = 1)
            PCX[i=I, j=J, g=G] >= 0, (start = 1)
            PF[i=I, j=J, f=F] >= 0,  (start = 1)
            PFX[g=G] >= 0,           (start = 1)
        
            CONS[i=I, j=J] >= 0,     (start = 120)
        
        end)
        
        
        
        # Cost Functions

        ## X
        @expression(M, unit_revenue_X[i=I, j=J, g=G], PX[i,j,g])
        @expression(M, unit_cost_X[i=I, j=J, g=G],
            prod( PF[i,j,f]^(FX[f,g]/(sum(FX[ff, g] for ff=F))) for f in F)
        )

        ## EX
        @expression(M, unit_revenue_EX[i=I, j=J, g=G], PFX[g])
        @expression(M, unit_cost_EX[i=I, j=J, g=G], PX[i,j,g])
        

        ## IX
        @expression(M, unit_revenue_IX[i=I, j=J, g=G], PCX[i,j,g])
        @expression(M, unit_cost_IX[i=I, j=J, g=G], PFX[g])

        ## XX
        @expression(M, unit_revenue_XX[i=I, j=J, g=G], PCX[i,j,g])
        @expression(M, unit_cost_XX[i=I, j=J, g=G], PX[i,j,g])

        ## W
        @expression(M, unit_revenue_W[i=I, j=J], PW[i,j])
        @expression(M, unit_cost_W[i=I, j=J], prod(PCX[i,j,g]^(1/length(G)) for g in G))

        # Zero Profit

        @constraints(M, begin
            zero_profit_X[i=I, j=J, g=G],  sum(FX[f,g] for f in F)*unit_cost_X[i,j,g] - 100*unit_revenue_X[i,j,g]  ⟂ X[i,j,g]
            zero_profit_EX[i=I, j=J, g=G], 100*TC[i]*unit_cost_EX[i,j,g] - 100*unit_revenue_EX[i,j,g] ⟂ EX[i,j,g]
            zero_profit_IX[i=I, j=J, g=G], 100*TC[i]*unit_cost_IX[i,j,g] - 100*unit_revenue_IX[i,j,g] ⟂ IX[i,j,g]
            zero_profit_XX[i=I, j=J, g=G], 100*unit_cost_XX[i,j,g] - 100*unit_revenue_XX[i,j,g] ⟂ XX[i,j,g]
            zero_profit_W[i=I, j=J],       100*length(G)*unit_cost_W[i,j] - 100*unit_revenue_W[i,j] ⟂ W[i,j]
        end)



        # Market Clearing
        @constraints(M, begin
            market_clearing_PW[i=I,j=J],      100*W[i,j] - CONS[i,j]/PW[i,j] ⟂ PW[i,j]
            market_clearing_PX[i=I,j=J,g=G],  100*X[i,j,g] - 100*TC[i]*EX[i,j,g] - 100*XX[i,j,g] ⟂ PX[i,j,g]
            market_clearing_PCX[i=I,j=J,g=G], 100*IX[i,j,g] + 100*XX[i,j,g] - 100*W[i,j]*unit_cost_W[i,j]/PCX[i,j,g] ⟂ PCX[i,j,g]
            market_clearing_PF[i=I,j=J,f=F], -sum(FX[f,g]*X[i,j,g]*unit_cost_X[i,j,g]/PF[i,j,f] for g∈G) + ENDOW[i,j,f] ⟂ PF[i,j,f]
            market_clearing_PFX[g=G],         100*sum(EX[i,j,g] for i=I, j=J) - 100*sum(TC[i]*IX[i,j,g] for i=I, j=J) ⟂ PFX[g]
        end)

        # Income Balance

        @constraint(M, income_CONS[i=I,j=J], 
            CONS[i,j] - sum(PF[i,j,f]*ENDOW[i,j,f] for f in F) ⟂ CONS[i,j]
        )

        fix(PFX[div(length(G),2)+1], 1; force=true)
        return M

    end
end

