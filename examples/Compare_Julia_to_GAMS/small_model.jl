using Pkg
Pkg.activate(".")
Pkg.instantiate()

include("small/SmallModel.jl")
using .SmallModel

using .SmallModel.MPSGE
using .SmallModel.DataFrames

M = small_model()
solve!(M, cumulative_iteration_limit=0)


# A begin..end block ensures all code is executed. This prevents adding additiona
# rows to the DataFrame if the loop is run twice. The indentation is purely 
# aesthetic, but recommended to visually separate the loop from the rest of the code.
#
# Note that we use a single loop rather than two nested loops. This code also directly
# labels rows as "tariff" or "trade" scenarios, which makes the results more 
# readable. The DataFrame is also presented in long format with the `X` and `Y`
# values reported as well.
begin
    df = DataFrame()

    for t=1:25
        set_value!(M[:TR], 0)

        rate = (t-1)*0.05

        set_value!(M[:TR], rate)
        solve!(M)

        push!(df, (index = t, rate = rate, scenario = :tariff, X = value(M[:X]), Y = value(M[:Y]), W = value(M[:W])))

        set_value!(M[:TR], 0)
        set_value!(M[:TC], rate)
        solve!(M)
        push!(df, (index = t, rate = rate, scenario = :trade, X = value(M[:X]), Y = value(M[:Y]), W = value(M[:W])))
        set_value!(M[:TC], 0)
    end
end

df