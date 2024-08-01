# # Two Consumers, Two Producers, Two Goods with leisure

# ## Model Definition

# Crusoe has been on the island alone for many years. He awakens
# one day to find a Spanish Galleon has run aground. He is overjoyed
# at the prospect of rescue, but finds all but one crew member has
# abandoned the ship. Crusoe names the remaining crew member Friday,
# he teaches Friday English and they begin to work together to survive.
# 
# Crusoe and Friday both produce and consume `coconuts` and `fish`.
# To disambiguate between the two producers and consumers, we will refer
# to Crusoe as `rc` and Friday as `mf`.

#Crusoe and Friday live like this for some time and patterns emerge. Crusoe
#finds that he can produce 8 coconuts or 4 fish in a day and Friday produces
#4 coconuts or 8 fish in a day. Crusoe finds that he can work 12 hours a day
#
#Crusoe builds the following model to describe the economy:

# |        | Crusoe-producer | Friday-producer | Crusoe-consumer | Friday-consumer |
# |---     |---              | ---             |---              |---              |
# |Coconuts| 8               | 4               | 3               | 9               |
# |Fish    | 4               | 8               | 7               | 5               |
# |Labor   | -12             | -12             | 3               | 5               |
# |Labor-endowment|          |                 | -13             | -19             |


using MPSGE

M = MPSGEModel()

@parameter(M, mf_labor, 19)

@sectors(M, begin
    rc_producer
    mf_producer 
end)

@commodities(M, begin
    price_coconuts
    price_fish
    price_labor
end)

@consumers(M, begin
    rc_consumer
    mf_consumer
end)

@production(M, rc_producer, [s=0,t=0], begin
    @output(price_coconuts, 8, t)
    @output(price_fish, 4, t)
    @input(price_labor, 12, s)
end)

@production(M, mf_producer, [s=0,t=0], begin
    @output(price_coconuts, 4, t)
    @output(price_fish, 8, t)
    @input(price_labor, 12, s)
end)

@demand(M, rc_consumer, begin
    @final_demand(price_coconuts, 3)
    @final_demand(price_fish, 7)
    @final_demand(price_labor, 3)
    end, begin
    @endowment(price_labor, 13)
end)

@demand(M, mf_consumer, begin
    @final_demand(price_coconuts, 9)
    @final_demand(price_fish, 5)
    @final_demand(price_labor, 5)
    end, begin
    @endowment(price_labor, mf_labor)
end)

fix(price_coconuts, 1)
set_silent(M)

solve!(M, cumulative_iteration_limit=0)

println(generate_report(M))


set_value!(mf_labor, 0)

solve!(M)

generate_report(M)