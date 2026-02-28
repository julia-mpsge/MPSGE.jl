@testitem "Updating Start Values" begin

    M = MPSGEModel()

    @sectors(M, begin
        X
    end)

    @commodities(M, begin
        PX
        PY
    end)

    @consumer(M, C)

    @production(M, X, [s=0, t=0], begin
        @output(PX, .5, t, reference_price = 2)
        @input(PY, 1, s, reference_price = 1)
    end)

    @demand(M, C, begin
        @final_demand(PX, 1)
        @endowment(PY, 2)
    end)


    solve!(M; cumulative_iteration_limit=0)


    @test !MPSGE.is_solved_and_feasible(M)

    set_start_value(X, 2)
    set_start_value(PX, 2)

    solve!(M; cumulative_iteration_limit=0)

    @test MPSGE.is_solved_and_feasible(M)


end

@testitem "Updating Start Values in Indexed Model" begin

    M = MPSGEModel()

    @sectors(M, begin
        X[i=1:2]
    end)

    @commodities(M, begin
        PX[i=1:2]
        PY[i=1:2]
    end)

    @consumer(M, C)

    @production(M, X[i=1:2], [s=0, t=0], begin
        @output(PX[i], .5, t, reference_price = 2)
        @input(PY[i], 1, s, reference_price = 1)
    end)

    @demand(M, C, begin
        @final_demand(PX[i=1:2], 1)
        @endowment(PY[i=1:2], 2)
    end)


    solve!(M; cumulative_iteration_limit=0)


    @test !MPSGE.is_solved_and_feasible(M)

    set_start_value.(X, 2)
    set_start_value.(PX, 2)

    solve!(M; cumulative_iteration_limit=0)

    @test MPSGE.is_solved_and_feasible(M)


end