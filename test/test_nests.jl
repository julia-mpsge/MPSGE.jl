@testitem "Nests - Parsing" begin

    @test MPSGE._strip_nest_elasticity(:(va=>s=value)) == :value
    @test MPSGE._strip_nest_name(:(va=>s=value)) == (:s, :va)
    @test MPSGE._strip_nest_name(:(va[i=I]=>s=value)) == (:s, :(va[i=I]))
    @test MPSGE._parse_nest(:(va=>s=value)) == (:va, :value, :s)
    @test MPSGE._strip_nest_name(:(va[i=I]=>s[j]=value))  == (:(s[j]), :(va[i=I]))

    @test_throws "Invalid syntax for nesting `va => s`. Required to have an `=` in statement. `s = 0` or `va => s = 0`." MPSGE._parse_nest(:(va => s))
    @test_throws "Invalid syntax for nesting `s`. Required to have an `=` in statement. `s = 0` or `va => s = 0`." MPSGE._parse_nest(:(s))
    @test_throws "Invalid syntax for parent nesting s[j = J]. Parents must only use index variables, not sets. Use `parent[i,j]`, not `parent[i=S, j=T]`." MPSGE.parse_nest_parent(error, :(s[j=J]))

end