module SmallModel
    using MPSGE
    using DataFrames

    """
        small_model()

Two goods, two factors, one consumer compares a tax and a (iceberg) transactions cost; showing the substantial difference between the two

| Markets | X   | Y   | W    | CONS |
| :---:   | --- | --- | ---  | ---  |
| PX      | 100 |     | -100 |      |
| PY      |     | 100 | -100 |      |
| PL      | -25 | -75 |      | 100  |
| PK      | -75 | -25 |      | 100  |
| PW      |     |     | 200  | -200 |

    ```julia
    @parameters(M, begin
        TR,   0  , (description = "ad-valorem tax rate for X sector inputs")
        TC,   0  , (description = "iceberg transport (trade) cost on X")
        LBAR, 100, (description = "labor endowment")
        KBAR, 100, (description = "capital endowment")
    end)

    @sectors(M, begin
        X, (description = "Activity level for sector X")
        Y, (description = "Activity level for sector Y")
        W, (description = "Activity level for sector W (welfare index)")
    end)

    @commodities(M, begin
        PX, (description = "Price index for commodity X")
        PY, (description = "Price index for commodity Y")
        PL, (description = "Price index for primary factor L")
        PK, (description = "Price index for primary factor K")
        PW, (description = "Price index for welfare (expenditure function)")
    end)

    @consumer(M, CONS, description = "Income level for consumer CONS")

    @production(M, X, [t=0, s=1], begin
        @output(PX, 100/(1+TC), t)
        @input(PL, 25, s, taxes = [Tax(CONS, TR)])
        @input(PK, 75, s, taxes = [Tax(CONS, TR)])
    end)

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
        @endowment(PL, LBAR)
        @endowment(PK, KBAR)
    end)

    fix(PW, 1)
    ```
    """
    function small_model()
        M = MPSGEModel()

        @parameters(M, begin
            TR,   0  , (description = "ad-valorem tax rate for X sector inputs")
            TC,   0  , (description = "iceberg transport (trade) cost on X")
            LBAR, 100, (description = "labor endowment")
            KBAR, 100, (description = "capital endowment")
        end)

        @sectors(M, begin
            X, (description = "Activity level for sector X")
            Y, (description = "Activity level for sector Y")
            W, (description = "Activity level for sector W (welfare index)")
        end)

        @commodities(M, begin
            PX, (description = "Price index for commodity X")
            PY, (description = "Price index for commodity Y")
            PL, (description = "Price index for primary factor L")
            PK, (description = "Price index for primary factor K")
            PW, (description = "Price index for welfare (expenditure function)")
        end)

        @consumer(M, CONS, description = "Income level for consumer CONS")

        @production(M, X, [t=0, s=1], begin
            @output(PX, 100/(1+TC), t)
            @input(PL, 25, s, taxes = [Tax(CONS, TR)])
            @input(PK, 75, s, taxes = [Tax(CONS, TR)])
        end)

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
            @endowment(PL, LBAR)
            @endowment(PK, KBAR)
        end)

        fix(PW, 1)
        
        return M
    end


    
    export small_model
end