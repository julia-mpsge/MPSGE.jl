@testitem "sectors" begin
    using MPSGE.JuMP
    var_error_message(var::String, line::Int; file_path::String = joinpath(@__DIR__, "test_variable.jl")) = "At $file_path:$(line): `@$var(M, begin\n    S\nend)`: Invalid syntax. Did you mean to use `@$(var)s`?"

    R = Symbol.(:r, 1:5)
    data = Dict(r => rand() for r in R)

    M = MPSGEModel()

    # Macro Constructors
    @sector(M, X)
    @test X == M[:X] # Check that the sector is created in the model

    @sector(M, Y[r=R], description = "A sector")
    @test Y == M[:Y] # Check that the sector is created in the model
    @test description(Y) == "A sector"
    
    for r∈R
        @test Y[r] == M[:Y][r] # Check that the sector is created in the model
        @test JuMP.name(get_variable(Y[r])) == "Y[$r]" # Check that the variable name is correct
        @test description(Y[r]) == "A sector" # Check that the variable name is correct
    end

    @test_throws ErrorException(var_error_message("sector", @__LINE__)) @macroexpand(@sector(M, begin
            S
        end))
end

@testitem "commodities" begin
    using MPSGE.JuMP
    var_error_message(var::String, line::Int; file_path::String = joinpath(@__DIR__, "test_variable.jl")) = "At $file_path:$(line): `@$var(M, begin\n    S\nend)`: Invalid syntax. Did you mean to use `@commodities`?"

    R = Symbol.(:r, 1:5)
    data = Dict(r => rand() for r in R)

    M = MPSGEModel()

    # Macro Constructors
    @commodity(M, X)
    @test X == M[:X] # Check that the commodity is created in the model

    @commodity(M, Y[r=R], description = "A commodity")
    @test Y == M[:Y] # Check that the commodity is created in the model
    @test description(Y) == "A commodity"
    
    for r∈R
        @test Y[r] == M[:Y][r] # Check that the commodity is created in the model
        @test JuMP.name(get_variable(Y[r])) == "Y[$r]" # Check that the variable name is correct
        @test description(Y[r]) == "A commodity" # Check that the variable name is correct
    end

    @test_throws ErrorException(var_error_message("commodity", @__LINE__)) @macroexpand(@commodity(M, begin
            S
        end))
end

@testitem "consumers" begin
    using MPSGE.JuMP
    var_error_message(var::String, line::Int; file_path::String = joinpath(@__DIR__, "test_variable.jl")) = "At $file_path:$(line): `@$var(M, begin\n    S\nend)`: Invalid syntax. Did you mean to use `@$(var)s`?"

    R = Symbol.(:r, 1:5)
    data = Dict(r => rand() for r in R)

    M = MPSGEModel()

    # Macro Constructors
    @consumer(M, X)
    @test X == M[:X] # Check that the consumer is created in the model

    @consumer(M, Y[r=R], description = "A consumer")
    @test Y == M[:Y] # Check that the consumer is created in the model
    @test description(Y) == "A consumer"
    
    for r∈R
        @test Y[r] == M[:Y][r] # Check that the consumer is created in the model
        @test JuMP.name(get_variable(Y[r])) == "Y[$r]" # Check that the variable name is correct
        @test description(Y[r]) == "A consumer" # Check that the variable name is correct
    end
    @test_throws ErrorException(var_error_message("consumer", @__LINE__)) @macroexpand(@consumer(M, begin
            S
        end))
end

@testitem "auxiliary" begin
    using MPSGE.JuMP
    var_error_message(var::String, line::Int; file_path::String = joinpath(@__DIR__, "test_variable.jl")) = "At $file_path:$(line): `@$var(M, begin\n    S\nend)`: Invalid syntax. Did you mean to use `@auxiliaries`?"

    R = Symbol.(:r, 1:5)
    data = Dict(r => rand() for r in R)

    M = MPSGEModel()

    # Macro Constructors
    @auxiliary(M, X)
    @test X == M[:X] # Check that the auxiliary is created in the model

    @auxiliary(M, Y[r=R], description = "An auxiliary")
    @test Y == M[:Y] # Check that the auxiliary is created in the model
    @test description(Y) == "An auxiliary"
    
    for r∈R
        @test Y[r] == M[:Y][r] # Check that the auxiliary is created in the model
        @test JuMP.name(get_variable(Y[r])) == "Y[$r]" # Check that the variable name is correct
        @test description(Y[r]) == "An auxiliary" # Check that the variable name is correct
    end
    @test_throws ErrorException(var_error_message("auxiliary", @__LINE__)) @macroexpand(@auxiliary(M, begin
            S
        end))
end