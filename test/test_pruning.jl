"""
You can't have a 0 quantity in the node of a Netput tree. Pruning
is an essential step in eliminating these zeros.

Fun fact: I don't think GAMS MPSGE does this. It will just error.
"""

@testset "Pruning a sector/nest from a Model" begin

    using MPSGE_MP
    
    M = MPSGEModel()

    @sectors(M,begin
        X
        Y
        W
        Q
    end)
    
    @commodities(M,begin
        PX
        PY
        PL
        PK
        PW
    end)
    
    @consumer(M, CONS)
    
    @production(M, X, [t =0, s = .5, va => s = 1], begin
        @Output(PX, 120., t)
        @Input(PY,20, s)
        @Input(PL, 40, va, taxes = [Tax(CONS, 0.5)])
        @Input(PK, 60, va, taxes = [Tax(CONS, 0.5)])
    end)
    
    @production(M, Y, [t = 0, s = .75, va => s = 1], begin
        @Output(PY, 120, t)
        @Input(PX,20, s)
        @Input(PL, 60, va)
        @Input(PK, 40, va)
    end)
    
    
    @production(M, W, [t = 0, s = 1, zero => s = 1], begin
        @Output(PW, 200, t)
        @Input(PX, 100, s)
        @Input(PY, 100, s)
        @Input(PX, 0, zero)
        @Input(PY,0, zero)
    end)

    @production(M, Q, [t = 1, s = 2], begin
        @Output(PW, 0, t)        
        @Input(PX,0, s)
        @Input(PY,0, s)
    end)

    
    @demand(M, CONS, begin
            @final_demand(PW, 200)
        end, begin
            @endowment(PL,100)
            @endowment(PK,100)
    end)
    
    #P = production(Q)

    #Ensure the 0 is in the production block
    #@test length(input(P).children) == 2

    #P = production(W)

    #Ensure the 0 is in the production block
    #@test length(input(P).children) == 3

    build!(M);

    #Ensure it gets removed
    #@test length(input(P).children) == 2

    # Test that the Q production block was removed
    #@test_throws KeyError(Q) production(Q)
    
    solve!(M)

    # Make sure the solution is correct
    @test isapprox(value(W),0.9838272769613801,atol = 1e-6)
    @test isapprox(value(Y), 1.1091469981122113,atol = 1e-6)
    @test isapprox(value(X), 0.8618665918327036,atol = 1e-6)
    @test isapprox(value(PY), 0.882965988643779,atol = 1e-6)
    @test isapprox(value(PW), 1.0164385796341864,atol = 1e-6)
    @test isapprox(value(PL), 0.8550185979160754,atol = 1e-6)
    @test isapprox(value(PX), 1.170087409318743,atol = 1e-6)
    @test isapprox(value(PK), 0.7999999999999832,atol = 1e-6)
    @test isapprox(value(CONS), 200,atol = 1e-6)
    @test value(Q) == 0
    
end


