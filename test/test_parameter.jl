@testitem "parameters" begin

    function var_error_message(
        line::Int,
        error_message::String
        ; 
        file_path::String = joinpath(@__DIR__, "test_parameter.jl"),
        )  
        
        return "At $file_path:$(line): $error_message"
    end

    
    R = Symbol.(:r, 1:5)
    data = Dict(r => rand() for r in R)
    
    M = MPSGEModel()
    
    @parameter(M, X0, 5)
    @test X0 == M[:X0]
    @test value(X0) == 5
    @test description(X0) == ""
    @test is_fixed(X0)


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

    msg = "`@parameter(M, begin\n    (X7, 1)\nend)`: Invalid syntax. Did you mean to use `@parameters`?"
    @test_throws ErrorException(var_error_message( @__LINE__, msg)) @macroexpand(@parameter(M, begin
            X7, 1
        end))


    @parameters(M, begin
        X8, 1, (description = "A parameter")
        X9[r=R], data[r], (description = "A parameter")
    end)

    @test X8 == M[:X8]
    @test value(X8) == 1
    @test description(X8) == "A parameter"
    @test is_fixed(X8)

    @test X9 == M[:X9]
    @test all(value(X9[r]) == data[r] for r in R)
    @test all(description(x) == "A parameter" for x in X9)
    @test description(X9) == "A parameter"
    


end