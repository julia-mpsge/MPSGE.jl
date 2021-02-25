using MPSGE

m = Model()

add!(m, Sector(:X, 1, 100, :L, 50, :K, 50))
add!(m, Sector(:Y, 1, 50, :L, 20, :K, 30))
add!(m, Sector(:U, 1, 150, :X, 100, :Y, 50))

add!(m, Consumer(
    name=:RA,
    demand_name=:U,
    endowments=[Endowment(:L, 70), Endowment(:K, 80)])
)

solve!(m)

for n in MPSGE.JuMP.all_variables(m._jump_model)
    println("$n:\t$(MPSGE.Complementarity.result_value(n))")
end