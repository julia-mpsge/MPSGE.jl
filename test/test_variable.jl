@testitem "sectors" begin
    using MPSGE.JuMP

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

    msg = r".*Invalid syntax. Did you mean to use `@sectors`?"
    @test_throws msg @macroexpand(@sector(M, begin
            S
        end))
end

@testitem "commodities" begin
    using MPSGE.JuMP

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

    msg = r".*Invalid syntax. Did you mean to use `@commodities`?"
    @test_throws msg @macroexpand(@commodity(M, begin
            S
        end))
end

@testitem "consumers" begin
    using MPSGE.JuMP

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

    msg = r".*Invalid syntax. Did you mean to use `@consumers`?"
    @test_throws msg @macroexpand(@consumer(M, begin
            S
        end))
end

@testitem "auxiliary" begin
    using MPSGE.JuMP

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

    msg = r".*Invalid syntax. Did you mean to use `@auxiliaries`?"
    @test_throws msg @macroexpand(@auxiliary(M, begin
            S
        end))
end