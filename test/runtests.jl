using MPSGE
using Test
using MPSGE.JuMP.Containers
using XLSX

@testset "MPSGE" begin
    include("test_twobytwo_functional.jl")
    include("test_twobytwo_ces_functional.jl")
    include("test_twobytwo_macro.jl")
    include("test_twobytwo_indexed.jl")
    include("test_jpmge.jl")
end
