@testitem "Report Verification" begin

    using DataFrames

    M = MPSGEModel()
        
    @sectors(M, begin
        X[i=1:2]
    end)

    @commodities(M, begin
        PX[i=1:2]
        PY
    end)

    @consumer(M, RA)

    @production(M, X[i=1:2], [s=0,t=0], begin
        @output(PY, 10, t)
        @input(PX[j=1:2], 5, s)
    end)

    @demand(M, RA, begin
        @final_demand(PY, 20)
        @endowment(PX[i=1:2], 10)
    end)

    solve!(M; cumulative_iteration_limit=0)

    X_report = DataFrame([
        (var = X[i], value = value(X[i]), margin = value(zero_profit(X[i]))) for i ∈ 1:2
    ])

    PX_report = DataFrame([
        (var = PX[i], value = value(PX[i]), margin = value(market_clearance(PX[i]))) for i ∈ 1:2
    ])

    PY_report = DataFrame(var = PY, value = value(PY), margin = value(market_clearance(PY)))

    RA_report = DataFrame(var = RA, value = value(RA), margin = value(income_balance(RA)))

    @test generate_report(X) == X_report
    @test generate_report(PX) == PX_report
    @test generate_report(PY) == PY_report
    @test generate_report(RA) == RA_report

    @test generate_report(X, PX, PY, RA) == vcat(X_report, PX_report, PY_report, RA_report)

    df = generate_report(M) |>
        x -> innerjoin(
            x, 
            vcat(X_report, PX_report, PY_report, RA_report), 
            on=:var,
            renamecols = "" => "_report"
        ) |>
        x -> transform(x,
            [:value, :value_report] => ((x,y) -> x ≈ y) => :value_match,
            [:margin, :margin_report] => ((x,y) -> x ≈ y) => :margin_match
        ) |>
        x -> combine(x, 
            :value_match => all => :value,
            :margin_match => all => :margin
        )

    @test df[1, :value]
    @test df[1, :margin]


    
end