"""
You can't have a 0 quantity in the node of a Netput tree. Pruning
is an essential step in eliminating these zeros.

Fun fact: I don't think GAMS MPSGE does this. It will just error.
"""

@testitem "Pruning a non-indexed model" begin

    using MPSGE
    
    M = MPSGEModel()
    @sectors(M,begin
        W
        Q
    end)

    @commodities(M,begin
        PX
        PY
        PW
    end)

    @production(M, W, [t = 0, s = 1, zero => s = 1], begin
        @output(PW, 200, t)
        @input(PX, 100, s)
        @input(PX, 0, zero)
        @input(PY,0, zero)
    end)

    @production(M, Q, [t = 1, s = 2], begin
        @output(PW, 0, t)        
        @input(PX,0, s)
        @input(PY,0, s)
    end)

    # Ensure Q gets pruned
    @test ismissing(production(Q))
    P = production(W)

    @test length(get(P.netputs, PX, missing)) == 1
    @test ismissing(get(P.netputs, PY, missing))

end


@testitem "Pruning an indexed model" begin

    M = MPSGEModel()

    V = Dict(
        (:a, :b) => 0,
        (:b, :a) => 2,
        (:a, :a) => 3,
        (:b, :b) => 4
    )

    I = [:a, :b]

    @sectors(M,begin
        X[i=I]
        Y[i=I, j=I]
    end)

    @commodities(M, begin
        PX[i=I]
        PY[i=I, j=I]
    end)

    P = @production(M, X[i=I], [s=0, t=0], begin
        @output(PX[i], 1, t)
        @input(PY[i, j=I], V[i,j], s)
    end)

    @test !ismissing(get(P[:a].netputs, PY[:a,:a], missing))
    @test ismissing(get(P[:a].netputs, PY[:a,:b], missing))
    @test !ismissing(get(P[:b].netputs, PY[:b,:a], missing))
    @test !ismissing(get(P[:b].netputs, PY[:b,:b], missing))

    P = @production(M, Y[i=I, j=I], [s=0, t=0], begin
        @output(PY[i,j], V[i, j], t)
        @input(PY[i,j], V[i,j], s)
    end)

    @test !isnothing(P[:a,:a])
    @test isnothing(P[:a,:b])
    @test !isnothing(P[:b,:a])
    @test !isnothing(P[:b,:b])
end