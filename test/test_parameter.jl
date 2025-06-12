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


@testset "variable - Sectors" begin

    R = Symbol.(:r, 1:5)
    data = Dict(r => rand() for r in R)
    
    M = MPSGEModel()
    
    # Scalar Sectors
    @sector(M, X0, start = 5, upper_bound = 100, lower_bound = 3)
    @test X0 == M[:X0]
    @test start_value(X0) == 5
    @test upper_bound(X0) == 100
    @test lower_bound(X0) == 3
    @test description(X0) == ""
    @test !is_fixed(X0)


    function var_error_message(
        line::Int,
        error_message::String
        ; 
        file_path::String = joinpath(@__DIR__, "test_parameter.jl"),
        )  
        
        return "At $file_path:$(line): $error_message"
    end


    @sector(M, X1[r=R], description = "A sector", start = data[r], upper_bound = 2*data[r], lower_bound = 0.5*data[r])
    @test all(start_value(X1[r]) == data[r] for r in R)
    @test all(lower_bound(X1[r]) == .5*data[r] for r in R)
    @test all(upper_bound(X1[r]) == 2*data[r] for r in R)
    @test description(X1) == "A sector"
    
    @test_throws Exception @sector(M, X2[r])
    
    @sector(M, X3[r=R, R], start = data[r], upper_bound = 2*data[r], lower_bound = 0.5*data[r])
    @test all(start_value(X3[r, rr]) == data[r] for r in R, rr in R)
    @test all(lower_bound(X3[r, rr]) == .5*data[r] for r in R, rr in R)
    @test all(upper_bound(X3[r, rr]) == 2*data[r] for r in R, rr in R)

    @sector(M, X4[r=R, rr=R], start = data[rr], upper_bound = 2*data[rr], lower_bound = 0.5*data[rr])
    @test all(start_value(X4[r, rr]) == data[rr] for r in R, rr in R)
    @test all(lower_bound(X4[r, rr]) == .5*data[rr] for r in R, rr in R)
    @test all(upper_bound(X4[r, rr]) == 2*data[rr] for r in R, rr in R)

    @sectors(M, begin
        X5[R, r=R],(description = "A sector", start = data[r], upper_bound = 2*data[r], lower_bound = 0.5*data[r])
        X6[r=R], (start = data[r])
    end)
    @test all(start_value(X5[r, rr]) == data[rr] for r in R, rr in R)
    @test all(lower_bound(X5[r, rr]) == .5*data[rr] for r in R, rr in R)
    @test all(upper_bound(X5[r, rr]) == 2*data[rr] for r in R, rr in R)
    @test all(start_value(X6[r]) == data[r] for r in R)
    @test_throws Exception upper_bound(X6[:r1]) # No upper bound defined
    @test_throws Exception lower_bound(X6[:r1]) # No lower bound defined

    msg = "`@sector(M, begin\n    (X7, 1)\nend)`: Invalid syntax. Did you mean to use `@sectors`?"
    @test_throws ErrorException(var_error_message( @__LINE__, msg)) @macroexpand(@sector(M, begin
            X7, 1
        end))

end




@testset "variable - Commodities" begin

    R = Symbol.(:r, 1:5)
    data = Dict(r => rand() for r in R)
    
    M = MPSGEModel()
    
    # Scalar Commodities
    @commodity(M, X0, start = 5, upper_bound = 100, lower_bound = 3)
    @test X0 == M[:X0]
    @test start_value(X0) == 5
    @test upper_bound(X0) == 100
    @test lower_bound(X0) == 3
    @test description(X0) == ""
    @test !is_fixed(X0)


    function var_error_message(
        line::Int,
        error_message::String
        ; 
        file_path::String = joinpath(@__DIR__, "test_parameter.jl"),
        )  
        
        return "At $file_path:$(line): $error_message"
    end


    @commodity(M, X1[r=R], description = "A commodity", start = data[r], upper_bound = 2*data[r], lower_bound = 0.5*data[r])
    @test all(start_value(X1[r]) == data[r] for r in R)
    @test all(lower_bound(X1[r]) == .5*data[r] for r in R)
    @test all(upper_bound(X1[r]) == 2*data[r] for r in R)
    @test description(X1) == "A commodity"
    
    @test_throws Exception @commodity(M, X2[r])
    
    @commodity(M, X3[r=R, R], start = data[r], upper_bound = 2*data[r], lower_bound = 0.5*data[r])
    @test all(start_value(X3[r, rr]) == data[r] for r in R, rr in R)
    @test all(lower_bound(X3[r, rr]) == .5*data[r] for r in R, rr in R)
    @test all(upper_bound(X3[r, rr]) == 2*data[r] for r in R, rr in R)

    @commodity(M, X4[r=R, rr=R], start = data[rr], upper_bound = 2*data[rr], lower_bound = 0.5*data[rr])
    @test all(start_value(X4[r, rr]) == data[rr] for r in R, rr in R)
    @test all(lower_bound(X4[r, rr]) == .5*data[rr] for r in R, rr in R)
    @test all(upper_bound(X4[r, rr]) == 2*data[rr] for r in R, rr in R)

    @commodities(M, begin
        X5[R, r=R],(description = "A commodity", start = data[r], upper_bound = 2*data[r], lower_bound = 0.5*data[r])
        X6[r=R], (start = data[r])
    end)
    @test all(start_value(X5[r, rr]) == data[rr] for r in R, rr in R)
    @test all(lower_bound(X5[r, rr]) == .5*data[rr] for r in R, rr in R)
    @test all(upper_bound(X5[r, rr]) == 2*data[rr] for r in R, rr in R)
    @test all(start_value(X6[r]) == data[r] for r in R)
    @test_throws Exception upper_bound(X6[:r1]) # No upper bound defined
    @test_throws Exception lower_bound(X6[:r1]) # No lower bound defined

    msg = "`@commodity(M, begin\n    (X7, 1)\nend)`: Invalid syntax. Did you mean to use `@commodities`?"
    @test_throws ErrorException(var_error_message( @__LINE__, msg)) @macroexpand(@commodity(M, begin
            X7, 1
        end))

end


@testset "variable - Consumers" begin

    R = Symbol.(:r, 1:5)
    data = Dict(r => rand() for r in R)
    
    M = MPSGEModel()
    
    # Scalar Consumers
    @consumer(M, X0, start = 5, upper_bound = 100, lower_bound = 3)
    @test X0 == M[:X0]
    @test start_value(X0) == 5
    @test upper_bound(X0) == 100
    @test lower_bound(X0) == 3
    @test description(X0) == ""
    @test !is_fixed(X0)


    function var_error_message(
        line::Int,
        error_message::String
        ; 
        file_path::String = joinpath(@__DIR__, "test_parameter.jl"),
        )  
        
        return "At $file_path:$(line): $error_message"
    end


    @consumer(M, X1[r=R], description = "A consumer", start = data[r], upper_bound = 2*data[r], lower_bound = 0.5*data[r])
    @test all(start_value(X1[r]) == data[r] for r in R)
    @test all(lower_bound(X1[r]) == .5*data[r] for r in R)
    @test all(upper_bound(X1[r]) == 2*data[r] for r in R)
    @test description(X1) == "A consumer"
    
    @test_throws Exception @consumer(M, X2[r])
    
    @consumer(M, X3[r=R, R], start = data[r], upper_bound = 2*data[r], lower_bound = 0.5*data[r])
    @test all(start_value(X3[r, rr]) == data[r] for r in R, rr in R)
    @test all(lower_bound(X3[r, rr]) == .5*data[r] for r in R, rr in R)
    @test all(upper_bound(X3[r, rr]) == 2*data[r] for r in R, rr in R)

    @consumer(M, X4[r=R, rr=R], start = data[rr], upper_bound = 2*data[rr], lower_bound = 0.5*data[rr])
    @test all(start_value(X4[r, rr]) == data[rr] for r in R, rr in R)
    @test all(lower_bound(X4[r, rr]) == .5*data[rr] for r in R, rr in R)
    @test all(upper_bound(X4[r, rr]) == 2*data[rr] for r in R, rr in R)

    @consumers(M, begin
        X5[R, r=R],(description = "A consumer", start = data[r], upper_bound = 2*data[r], lower_bound = 0.5*data[r])
        X6[r=R], (start = data[r])
    end)
    @test all(start_value(X5[r, rr]) == data[rr] for r in R, rr in R)
    @test all(lower_bound(X5[r, rr]) == .5*data[rr] for r in R, rr in R)
    @test all(upper_bound(X5[r, rr]) == 2*data[rr] for r in R, rr in R)
    @test all(start_value(X6[r]) == data[r] for r in R)
    @test_throws Exception upper_bound(X6[:r1]) # No upper bound defined
    @test_throws Exception lower_bound(X6[:r1]) # No lower bound defined

    msg = "`@consumer(M, begin\n    (X7, 1)\nend)`: Invalid syntax. Did you mean to use `@consumers`?"
    @test_throws ErrorException(var_error_message( @__LINE__, msg)) @macroexpand(@consumer(M, begin
            X7, 1
        end))

end


@testset "variable - Auxiliaries" begin

    R = Symbol.(:r, 1:5)
    data = Dict(r => rand() for r in R)
    
    M = MPSGEModel()
   
    # Test defaults!!
    @auxiliary(M, X)
    @test_throws Exception upper_bound(X) # No upper bound defined
    @test_throws Exception lower_bound(X) # No lower bound defined

    @test start_value(X) == 0.0


    # Scalar Auxiliaries
    @auxiliary(M, X0, start = 5, upper_bound = 100, lower_bound = 3)
    @test X0 == M[:X0]
    @test start_value(X0) == 5
    @test upper_bound(X0) == 100
    @test lower_bound(X0) == 3
    @test description(X0) == ""
    @test !is_fixed(X0)


    function var_error_message(
        line::Int,
        error_message::String
        ; 
        file_path::String = joinpath(@__DIR__, "test_parameter.jl"),
        )  
        
        return "At $file_path:$(line): $error_message"
    end


    @auxiliary(M, X1[r=R], description = "A auxiliary", start = data[r], upper_bound = 2*data[r], lower_bound = 0.5*data[r])
    @test all(start_value(X1[r]) == data[r] for r in R)
    @test all(lower_bound(X1[r]) == .5*data[r] for r in R)
    @test all(upper_bound(X1[r]) == 2*data[r] for r in R)
    @test description(X1) == "A auxiliary"
    
    @test_throws Exception @auxiliary(M, X2[r])
    
    @auxiliary(M, X3[r=R, R], start = data[r], upper_bound = 2*data[r], lower_bound = 0.5*data[r])
    @test all(start_value(X3[r, rr]) == data[r] for r in R, rr in R)
    @test all(lower_bound(X3[r, rr]) == .5*data[r] for r in R, rr in R)
    @test all(upper_bound(X3[r, rr]) == 2*data[r] for r in R, rr in R)

    @auxiliary(M, X4[r=R, rr=R], start = data[rr], upper_bound = 2*data[rr], lower_bound = 0.5*data[rr])
    @test all(start_value(X4[r, rr]) == data[rr] for r in R, rr in R)
    @test all(lower_bound(X4[r, rr]) == .5*data[rr] for r in R, rr in R)
    @test all(upper_bound(X4[r, rr]) == 2*data[rr] for r in R, rr in R)

    @auxiliaries(M, begin
        X5[R, r=R],(description = "A auxiliary", start = data[r], upper_bound = 2*data[r], lower_bound = 0.5*data[r])
        X6[r=R], (start = data[r])
    end)
    @test all(start_value(X5[r, rr]) == data[rr] for r in R, rr in R)
    @test all(lower_bound(X5[r, rr]) == .5*data[rr] for r in R, rr in R)
    @test all(upper_bound(X5[r, rr]) == 2*data[rr] for r in R, rr in R)
    @test all(start_value(X6[r]) == data[r] for r in R)
    @test_throws Exception upper_bound(X6[:r1]) # No upper bound defined
    @test_throws Exception lower_bound(X6[:r1]) # No lower bound defined

    msg = "`@auxiliary(M, begin\n    (X7, 1)\nend)`: Invalid syntax. Did you mean to use `@auxiliaries`?"
    @test_throws ErrorException(var_error_message( @__LINE__, msg)) @macroexpand(@auxiliary(M, begin
            X7, 1
        end))

end