

using MPSGE
using NamedArrays
M = MPSGEModel()

people = [:robinson_crusoe, :man_friday]

goods = [:coconut, :fish]




@parameter(M, labor, 19)

@sectors(M, begin
    producer[people]
end)

@commodities(M, begin
    price_good[goods]
    price_labor
end)

@consumers(M, begin
    consumer[people]
end)

for person∈people
    @production(M, producer[person], [s=0,t=0], begin
        [@output(price_good[good], 1, t) for good∈goods]...
        @input(price_labor, 1, s)
    end)
end

for person∈people
    @demand(M, consumer[person], begin
        [@final_demand(price_good[good], 1) for good∈goods]...
        @final_demand(price_labor, 3)
        @endowment(price_labor, 13)
    end)
end


fix(price_good[:coconut], 1)
set_silent(M)

solve!(M, cumulative_iteration_limit=0)

println(generate_report(M))


set_value!(mf_labor, 40)

solve!(M)

generate_report(M)