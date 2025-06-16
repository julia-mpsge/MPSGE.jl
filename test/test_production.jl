@testitem "Production - Repeat Indices" begin

    file_path = joinpath(@__DIR__, "test_production.jl")

    I = [:a,:b]
    M = MPSGEModel()

    @sector(M, X[i=I])
    @sector(M, Y[i=I,j=I])
    @commodity(M, PX[i=I])

    # The error occurs during macro expansion? May not be desireable. 
    # Repeated index variable in nest.
    try
        @macroexpand(@production(M, X[i=I], [s=0, t=1, err[i=I] => s = 0], begin
            @input(PX[j=I], 100, s)
            @output(PX[j=I], 200, t)
        end))
    catch e
        line = @__LINE__() - 5
        msg = "At $file_path:$line: `@nest(err[i = I] => s = begin\n        #= $file_path:$line =#\n        0\n    end)`: Repeated index variable Set(Any[:i]) in reference set err. Check your sector index variables, these cannot be repeated elsewhere in the macro."
        @test e == ErrorException(msg)
    end

    ## Repeated index variables in the netput PX[i] that are already used in the sector.
    try
        @production(M, X[i=I], [s=0, t=1, err[j=I] => s = 0], begin
            @input(PX[i=I], 100, s)
            @output(PX[i=I], 200, t)
        end)
    catch e
        line = @__LINE__() - 5
        msg = "At $file_path:$line: `@production(M, X[i = I], [s = 0, t = 1, err[j = I] => s = begin\n            #= $file_path:$line =#\n            0\n        end], begin\n    #= $file_path:$(line+1) =# @input PX[i = I] 100 s\n    #= $file_path:$(line+2) =# @output PX[i = I] 200 t\nend)`: The netput PX[a] has index variables Any[:i] that are already used in the sector. This is not allowed, as it create ambiguity in the model.\n"
        @test e == ErrorException(msg)
    end



    ## Repeat index in sector
    try
        @macroexpand @production(M, Y[i=I,i=I], [s=0, t=1, err[j=I] => s = 0], begin
            @input(PX[i=I], 100, s)
            @output(PX[i=I], 200, t)
        end)
    catch e
        line = @__LINE__() - 5
        msg = "At $file_path:$(line+0): `@production(M, Y[i = I, i = I], [s = 0, t = 1, err[j = I] => s = begin\n            #= $file_path:$(line+0) =#\n            0\n        end], begin\n    #= $file_path:$(line+1) =# @input PX[i = I] 100 s\n    #= $file_path:$(line+2) =# @output PX[i = I] 200 t\nend)`: The index i appears more than once. The index associated with each set must be unique."
        @test e == ErrorException(msg)
    end


end


@testitem "Production - Nesting Assignments" begin
    I = [:a,:b]
    M = MPSGEModel()

    @sector(M, Z)
    @commodity(M, PY)
    @commodity(M, PX[i=I])


    # Scalar Nests
    P = @production(M, Z, [s=0, t=0, va=>s=1], begin
        @output(PY, 1, t)
        @input(PY, 2, s)
        @input(PY, 3, va)
    end)


    N = input(P)
    @test name(N) == :s

    L = MPSGE.children(N)
    @test length(L) == 2

    (N2, C) = isa(L[1], MPSGE.Node) ? (L[1], L[2])  : (L[2], L[1])

    @test commodity(C) == PY
    @test quantity(C) == 2

    @test name(N2) == :va
    L = MPSGE.children(N2)
    @test length(L) == 1

    N3 = L[1]
    @test commodity(N3) == PY
    @test quantity(N3) == 3


    d = Dict(
        :a => 3,
        :b => 4
    )
    P = @production(M, Z, [s=0, t=0, va[i=I]=>s=1], begin
        @output(PY, 1, t)
        @input(PY, 2, s)
        @input(PX[i=I], d[i], va[i])
    end)

    N = input(P)

    L = Dict(name(n) => n for n in MPSGE.children(N))

    quantity(L[:PY]) == 2

    quantity(L[Symbol("va[b]")].children[1]) == d[:b]
    quantity(L[Symbol("va[a]")].children[1]) == d[:a]


end



@testitem "Production - Virtual Cost Functions" begin

    M = MPSGEModel()

    @parameter(M, sigma, 0)
    @parameter(M, sigma2, 0)
    @sector(M, X)
    @commodity(M, C)

    P = @production(M, X, [t=0, s=sigma, va=>s=sigma2, tmp=>va = 0], begin
        @output(C, 1, t)
        @input(C, 1, s)
        @input(C, 1, va)
        @input(C, 1, tmp)
    end)


    @test !isnothing(cost_function(P, :s, virtual = true))

    @test !isnothing(cost_function(P, :va, virtual = true))

end