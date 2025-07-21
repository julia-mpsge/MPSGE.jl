@testitem "Elasticities - Extracting" begin


    M = MPSGEModel()

    @sector(M, X)
    @commodity(M, C)
    @consumer(M, H)

    @production(M, X, [t=0, s=1, va=>s=5, d=>va=6], begin
        @output(C, 1, t)
        @input(C, 1, s)
        @input(C, 2, va)
        @input(C, 3, d)
    end)


    @test MPSGE.elasticity(X, :t) == 0
    @test MPSGE.elasticity(X, :s) == 1
    @test MPSGE.elasticity(X, :va) == 5
    @test MPSGE.elasticity(X, :d) == 6    


end