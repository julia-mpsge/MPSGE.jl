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


