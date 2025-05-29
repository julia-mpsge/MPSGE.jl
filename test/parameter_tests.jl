@testitem "parameters" begin
    
    R = Symbol.(:r, 1:5)
    data = Dict(r => rand() for r in R)
    
    M = MPSGEModel()
    
    @parameter(M, X0, 5)
    @test value(X0) == 5
    @test description(X0) == ""


    @parameter(M, X1[r=R], data[r], description = "A parameter")
    @test all(value(X1[r]) == data[r] for r in R)
    @test description(X1) == "A parameter"
    
    @test_throws Exception @parameter(M, X2[r], 1)
    
    @parameter(M, X3[r=R, R], data[r])
    @test all(value(X3[r, rr]) == data[r] for r in R, rr in R)

    @parameter(M, X4[r=R, rr=R], data[rr])
    @test all(value(X4[r, rr]) == data[rr] for r in R, rr in R)

    @parameters(M, begin
        X5[R, r=R], data[r], (description = "A parameter")
        X6[r=R], data[r]
    end)
    @test all(value(X5[r, rr]) == data[rr] for r in R, rr in R)
    @test all(value(X6[r]) == data[r] for r in R)

end