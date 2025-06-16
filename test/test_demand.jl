@testitem "Demand - Indexing" begin

    file_path = joinpath(@__DIR__, "test_production.jl")

    I = ["a","b"]

    values = Dict(
        ("a","b") => 0,
        ("b","a") => 2,
        ("a","a") => 3,
        ("b","b") => 4
    )

    M = MPSGEModel()
    @sector(M, X[i=I,j=I])
    @sector(M, Y[i=I])
    @sector(M, Z)
    @commodity(M, C[i=I,j=I])
    @consumers(M, begin
        H[i=I]
        G[i=I,j=I]
    end)


    L = @demand(M, H[i=I], begin
        @final_demand(C[i,j=I], values[i,j])
        @endowment(C[ii=I,j=I], values[ii,i])
    end)


    @test length(L) == 2
    @test length(MPSGE.demands(M)) == 2

    df = L["a"].demand_flow
    @test length(df) == 4
    @test length(df[C["a","a"]]) == 2
    @test length(df[C["a","b"]]) == 1

    @test length(L["b"].demand_flow) == 2


end