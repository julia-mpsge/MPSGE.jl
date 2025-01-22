"""
Tests that you can compute the compensated demand for a sector whose production 
block that has been pruned. The compensated demand should be zero.
"""
@testitem "Compensated Demand" begin
    
    using MPSGE

    M = MPSGEModel()


    @sectors(M, begin
        X
        Y
    end)

    @commodities(M, begin
        PX
        PY
        PZ
    end)

    @consumer(M, RA) 

    @production(M, X, [t=0,s=0], begin
        @output(PX, 100, t)
        @input(PY, 50, s)
        @input(PZ, 50, s)
    end)

    @production(M, Y, [t=0,s=0], begin
        @output(PY, 0, t)
        @input(PX, 0, s)
        @input(PZ, 0, s)
    end)

    @demand(M, RA, begin
        @final_demand(PX, 100)
        @endowment(PZ, 50)
        @endowment(PY, 50)
    end)

    solve!(M, cumulative_iteration_limit=0)

    @test compensated_demand(X, PY) == 50

    @test compensated_demand(Y, PY) == 0


end

