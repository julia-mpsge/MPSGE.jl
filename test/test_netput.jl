@testitem "Netput - Tax Assignment" begin

    M = MPSGEModel()

    @sector(M, X)
    @commodities(M, begin
        P1
        P2
        P3
    end)

    @consumer(M, RA)

    @production(M, X, [s=0,t=0], begin
        @output(P1, 1, t)
        @input(P2, 1, s, taxes = [Tax(RA, .2), Tax(RA, .05)])
    end)


    @test length(MPSGE.taxes(X, RA)) == 1

end