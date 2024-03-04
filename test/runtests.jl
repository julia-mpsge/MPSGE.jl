using MPSGE_MP
using Test

@testset "MPSGE_MP.jl" begin

    include("test_pruning.jl")
    include("test_Benchmark-Theta.jl")
end
