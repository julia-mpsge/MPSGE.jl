# # One Consumer, One Producer, Two Goods with leisure
#
# ## Model Definition
# 
# After several years Crusoe realises he is spending all his time 
# working and decides to allocate some of his time to leisure. 


using MPSGE

Lesiure = MPSGEModel()


@sector(Lesiure,  rc_producer)

@commodities(Lesiure,  begin
    price_coconuts
    price_fish
    price_labor
end)

@consumer(Lesiure,  rc_consumer)



@production(Lesiure,  rc_producer, [s=0, t=0], begin
    @output(price_coconuts, 1, t)
    @output(price_fish, 1, t)
    @input(price_labor, 1, s)
end)


@demand(Lesiure,  rc_consumer, begin
    @final_demand(price_coconuts, 1)
    @final_demand(price_fish, 1)
    @final_demand(price_labor, .5)
    end, begin
    @endowment(price_labor, 1)
end)


fix(price_coconuts, 1)


solve!(Lesiure)

generate_report(Lesiure)

