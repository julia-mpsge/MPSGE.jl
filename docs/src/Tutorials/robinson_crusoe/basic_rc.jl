# # 1. Two Goods
#
# In this economy, Robinson Crusoe acts as both a producer and consumer
# He will produce and consume `coconuts` and `fish`. 



using MPSGE

M = MPSGEModel()

@sector(M, robinson)

@commodities(M, begin
    PC
    PF
    PL
end)

@consumer(M, crusoe)

@production(M, robinson, [s=0, t=0], begin
    @output(PC, 1, t)
    @output(PF, 1, t)
    @input(PL, 1, s)
end)

@demand(M, crusoe, begin
    @final_demand(PC, 1)
    @final_demand(PF, 1)
    end, begin
    @endowment(PL, 1)
end)

solve!(M)

generate_report(M)