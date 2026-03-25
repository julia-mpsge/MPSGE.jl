@testitem "Macro Parsing - Ref Sets" begin

    I = [:a,:b]

    # Non indexed
    name, index_vars, indices, all_indices = MPSGE.parse_ref_sets(error, :Y)
    @test name == :Y
    @test index_vars == []
    @test indices == :(Containers.vectorized_product())
    @test all_indices == Any[]


    # Single Variate
    name, index_vars, indices, all_indices = MPSGE.parse_ref_sets(error, :(Y[i=I]))
    @test name == :Y
    @test index_vars == [:i]
    @test indices == :(Containers.vectorized_product($(Expr(:escape, :I))))
    @test all_indices == Any[:($(Expr(:escape, :i)))]

    # Multivariate
    name, index_vars, indices, all_indices = MPSGE.parse_ref_sets(error, :(Y[i=I,j=I]))
    @test name == :Y
    @test index_vars == [:i,:j]
    @test indices == :(Containers.vectorized_product($(Expr(:escape, :I)), $(Expr(:escape, :I))))
    @test all_indices == Any[:($(Expr(:escape, :i))),:($(Expr(:escape, :j)))]

    

    # Testing the error cases
    @test_throws "The index i appears more than once. The index associated with each set must be unique." MPSGE.parse_ref_sets(error, :(Y[i=I,i=I]))
    @test_throws "Invalid syntax for reference set [i = I]. Must have a name, for example, `Y[i=I]`" MPSGE.parse_ref_sets(error, :([i=I])) 
    @test_throws "Repeated index variable Set(Any[:i]) in reference set Y. Check your sector index variables, these cannot be repeated elsewhere in the macro." MPSGE.parse_ref_sets(error, :(Y[i=I]), invalid_index_variables = Any[:i])

end


@testitem "Macro Parsing - Building Expressions" begin

    I = [:a,:b]


    name, index_vars, indices, all_indices = MPSGE.parse_ref_sets(error, :(Y[i=I,j=I]))
    expr = MPSGE.build_name_expr(name, index_vars, Dict{Symbol, Any}())
    @test expr == :(($(Expr(:escape, :Y)))[i, j])

    str_expr = MPSGE.build_string_expr(name, index_vars, Dict{Symbol, Any}())
    @test str_expr == :(string("Y", "[", string(i), ", ", string(j), "]"))


end


@testitem "Macro Parsing - MPSGE Ref Sets" begin

    index_vars = []
    index_sets = []
    all_indices = Any[]

    MPSGE.parse_mpsge_ref_sets(error, index_vars, index_sets, all_indices, :(i=I))

    @test index_vars == [:i]
    @test index_sets == [:($(Expr(:escape, :I)))]
    @test all_indices == Any[:($(Expr(:escape, :i)))]


    @test_throws "The index i appears more than once. The index associated with each set must be unique." MPSGE.parse_mpsge_ref_sets(error, index_vars, index_sets, all_indices, :(i))

    MPSGE.parse_mpsge_ref_sets(error, index_vars, index_sets, all_indices, :(j))
    @test index_vars == [:i]
    @test index_sets == [:($(Expr(:escape, :I)))]
    @test all_indices == Any[:($(Expr(:escape, :($i)))) for i in [:i,:j]]


    MPSGE.parse_mpsge_ref_sets(error, index_vars, index_sets, all_indices, :(k∈I))
    @test index_vars == [:i,:k]
    @test index_sets == [:($(Expr(:escape, :I))) for i in 1:2]
    @test all_indices == Any[:($(Expr(:escape, :($i)))) for i in [:i,:j,:k]]

    MPSGE.parse_mpsge_ref_sets(error, index_vars, index_sets, all_indices, :(l in I))
    @test index_vars == [:i,:k,:l]
    @test index_sets == [:($(Expr(:escape, :I))) for i in 1:3]
    @test all_indices == Any[:($(Expr(:escape, :($i)))) for i in [:i,:j,:k,:l]]
    
    # Test other types of expressions

    expected_indices = Any[:($(Expr(:escape, :($i)))) for i in [:i,:j,:k,:l]]
    
    MPSGE.parse_mpsge_ref_sets(error, index_vars, index_sets, all_indices, :(l+1))
    push!(expected_indices, :($(Expr(:escape, :(l+1)))))
    @test index_vars == [:i,:k,:l]
    @test index_sets == [:($(Expr(:escape, :I))) for i in 1:3]
    @test all_indices == expected_indices


    MPSGE.parse_mpsge_ref_sets(error, index_vars, index_sets, all_indices, :(test[l]))
    push!(expected_indices, :($(Expr(:escape, :(test[l])))))
    @test index_vars == [:i,:k,:l]
    @test index_sets == [:($(Expr(:escape, :I))) for i in 1:3]
    @test all_indices == expected_indices


    MPSGE.parse_mpsge_ref_sets(error, index_vars, index_sets, all_indices, :(l-a))
    push!(expected_indices, :($(Expr(:escape, :(l-a)))))
    @test index_vars == [:i,:k,:l]
    @test index_sets == [:($(Expr(:escape, :I))) for i in 1:3]
    @test all_indices == expected_indices

end