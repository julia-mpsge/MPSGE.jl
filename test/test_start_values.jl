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

    @auxiliary(M, A, start = 0.5)

    @production(M, X, [s=0, t=0], begin
        @output(PX, .5*A, t, reference_price = 2)
        @input(PY, 1, s, reference_price = 1)
    end)

    @demand(M, C, begin
        @final_demand(PX, 1*A)
        @endowment(PY, 2)
    end)

    @aux_constraint(M, A, 1 - A)

    solve!(M; cumulative_iteration_limit=0)

    @test !MPSGE.is_solved_and_feasible(M)

    solve!(M; cumulative_iteration_limit=0)
    
    set_start_value(A, 1; update_internal_start_values=false)
    set_start_value(X, 2)
    set_start_value(PX, 2)
    solve!(M; cumulative_iteration_limit=0)

    @test MPSGE.is_solved_and_feasible(M)
end

@testitem "Updating Start Values in Indexed Model" begin

    I = 1:5

    M = MPSGEModel()

    @sectors(M, begin
        X[i=I]
        Y[i=I]
    end)

    @commodities(M, begin
        PX[i=I]
        PY[i=I]
        PL[i=I]
    end)

    @consumer(M, CONS)


    @production(M, X[i=I], [s=1,t=0, va=>s=2], begin
        @output(PX[i], 10, t)
        @input(PY[j=I], 2, s)
        @input(PL[j=I], 1, va)
    end)


    @production(M, Y[i=I], [s=1,t=0, va=>s=2], begin
        @output(PY[i], 10, t)
        @input(PX[j=I], 2, s)
        @input(PL[j=I], 1, va)
    end)

    @demand(M, CONS, begin
        @final_demand(PX[i=I], 100)
        @final_demand(PY[i=I], 100)
        @endowment(PL[i=I], 100)
    end)

    fix(PL[1], 1)

    # Not balanced
    solve!(M, cumulative_iteration_limit=0)
    @test !MPSGE.is_solved_and_feasible(M)

    # Solve
    solve!(M)
    @test MPSGE.is_solved_and_feasible(M)

    # Update start values
    set_start_value.(X, value.(X))
    set_start_value.(Y, value.(Y))
    set_start_value.(PX, value.(PX))
    set_start_value.(PY, value.(PY))
    set_start_value.(PL, value.(PL))
    set_start_value(CONS, value(CONS))

    solve!(M, cumulative_iteration_limit=0)
    @test MPSGE.is_solved_and_feasible(M)


end