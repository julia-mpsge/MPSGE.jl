using MPSGE_MP
using Test

@testset "MPSGE_MP.jl" begin

    include("test_pruning.jl")
    include("test_123.jl")
    #include("test_Benchmark-Theta.jl")
    #include("test_jpmge.jl")
    #include("test_twobytwo_ces_functional.jl")
    #include("test_twobytwo_functional.jl")
    #include("test_twobytwo_indexed.jl")
    #include("test_twobytwo_macro.jl")
    #include("test_twobytwo_Price.jl")
    #include("test_twobytwo_wTaxes.jl")

end
