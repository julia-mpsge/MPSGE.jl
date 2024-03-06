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
    
    add_production!(M,
        X,
        ScalarNest(:t; elasticity = 0, children = 
            [ScalarOutput(PX, 120.)]
        ),
        ScalarNest(:s; elasticity = .5, children = [
            ScalarInput(PY,20),
            ScalarNest(:va; elasticity = 1, children = [
                ScalarInput(PL, 40; taxes = [Tax(CONS, 0.5)]),
                ScalarInput(PK, 60; taxes = [Tax(CONS, 0.5)])
                ])
            ]
            ) 
    )
    
    add_production!(M,
        Y,
        ScalarNest(:t; elasticity = 0, children = [
            ScalarOutput(PY, 120),
        ]),
        ScalarNest(:s; elasticity = .75, children = [
            ScalarInput(PX,20),
            ScalarNest(:va; elasticity = 1, children = [
                ScalarInput(PL, 60),
                ScalarInput(PK, 40)
            ])
        ])
    )
    
    
    add_production!(M,
        W,
        ScalarNest(:t; elasticity = 0, children = [
            ScalarOutput(PW, 200)
        ]),
        ScalarNest(:s, elasticity = 1, children = [
            ScalarInput(PX, 100),
            ScalarInput(PY, 100),
            ScalarNest(:zero, elasticity = 1, children = [
                ScalarInput(PX, 0)
                ScalarInput(PY,0)
            ])
        ])
    )

    add_production!(M,
        Q,
        ScalarNest(:t, elasticity = 1, children = [
            ScalarOutput(PW, 0)
        ]),
        ScalarNest(:s, elasticity = 2, children = [
            ScalarInput(PX,0)
            ScalarInput(PY,0)
        ])
    )

    
    add_demand!(M,
        CONS,
        [ScalarDem(PW, 200)],
        [
            ScalarEndowment(PL,100),
            ScalarEndowment(PK,100)
        ]
    )
    
    P = production(Q)

    #Ensure the 0 is in the production block
    @test length(P.input.children) == 2

    P = production(W)

    #Ensure the 0 is in the production block
    @test length(P.input.children) == 3

    build!(M);

    #Ensure it gets removed
    @test length(P.input.children) == 2

    # Test that the Q production block was removed
    @test_throws KeyError(Q) production(Q)
    
    solve!(M)

    # Make sure the solution is correct
    @test isapprox(value(W),0.9838272769615133,atol = 1e-6)
    @test isapprox(value(Y), 1.1091469981123894,atol = 1e-6)
    @test isapprox(value(X), 0.8618665918328441,atol = 1e-6)
    @test isapprox(value(PY), 0.09909680198537893,atol = 1e-6)
    @test isapprox(value(PW), 0.11407666201399301,atol = 1e-6)
    @test isapprox(value(PL), 0.09596021792565605,atol = 1e-6)
    @test isapprox(value(PX), 0.13132093625155308,atol = 1e-6)
    @test isapprox(value(PK), 0.08978538540360285,atol = 1e-6)
    @test isapprox(value(CONS), 22.446346350813023,atol = 1e-6)
    @test value(Q) == 0
    
end


