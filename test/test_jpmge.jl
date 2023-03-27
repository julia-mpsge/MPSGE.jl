@testitem "JPMGE (Joint Production Intermediate Demand)" begin
    using XLSX, MPSGE.JuMP.Containers
    
#A replication of the JPMGE from https://www.gams.com/34/docs/UG_MPSGE_Intro.html#UG_MPSGE_Intro_Appendix_jpmge
    m = Model()
    goods = [:g1, :g2]
    factors = [:l, :k]
    sectors = [:s1, :s2]
    make0 = DenseAxisArray(Float64[6 2; 2 10], goods, sectors)
    use0 = DenseAxisArray(Float64[4 2; 2 6], goods, sectors)
    fd0 = DenseAxisArray(Float64[1 3; 1 1], factors, sectors)
    c0 = DenseAxisArray(Float64[2, 4], goods)
    e0 = DenseAxisArray(Float64[sum(fd0[f,:]) for f in factors], factors)
    endow = add!(m, Parameter(:endow, indices=(factors,), value=1.0)) 
    X = add!(m, Sector(:X, indices=(sectors,)))
    P = add!(m, Commodity(:P, indices=(goods,)))
    PF = add!(m, Commodity(:PF, indices=(factors,)))
    Y = add!(m, Consumer(:Y, benchmark=sum(fd0)))#example 4 has sum e0
    for j in sectors
        @production(m, X[j], 1., 1., [Output(P[i], make0[i,j]) for i in goods], [[Input(P[i], use0[i,j]) for i in goods]; [Input(PF[f], fd0[f,j]) for f in factors]])
    end

    @demand(m, Y, 1., [Demand(P[i], c0[i]) for i in goods], [Endowment(PF[:k], :($(endow[:k]) * $(e0[:k]))), Endowment(PF[:l], :($(endow[:l]) * $(e0[:l])))])

    avm = algebraic_version(m)
    @test typeof(avm) == MPSGE.AlgebraicWrapper

    solve!(m)

    gams_results = XLSX.readxlsx(joinpath(@__DIR__, "MPSGEresults.xlsx"))
    a_table = gams_results["JPMGE"][:]  # Generated from JPMGE_MPSGE
    two_by_two_jpmge = DenseAxisArray(a_table[2:end,3:end],string.(a_table[2:end,1],".",a_table[2:end,2]),a_table[1,3:end])

    @test MPSGE.Complementarity.result_value(m._jump_model[:X][:s1]) ≈ two_by_two_jpmge["X.s1","benchmark"] # 1.
    @test MPSGE.Complementarity.result_value(m._jump_model[:X][:s2]) ≈ two_by_two_jpmge["X.s2","benchmark"] # 1.
    @test MPSGE.Complementarity.result_value(m._jump_model[:P][:g1]) ≈ two_by_two_jpmge["P.g1","benchmark"] # 1.
    @test MPSGE.Complementarity.result_value(m._jump_model[:P][:g2]) ≈ two_by_two_jpmge["P.g2","benchmark"] # 1.
    @test MPSGE.Complementarity.result_value(m._jump_model[:PF][:l]) ≈ two_by_two_jpmge["PF.labor","benchmark"] # 1.
    @test MPSGE.Complementarity.result_value(m._jump_model[:PF][:k]) ≈ two_by_two_jpmge["PF.capital","benchmark"] # 1.
    @test MPSGE.Complementarity.result_value(m._jump_model[:Y]) ≈ two_by_two_jpmge["Y._","benchmark"] # 6.
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("P[g1]ρY")]) ≈ two_by_two_jpmge["PY.g1","benchmark"] # 2.
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("P[g2]ρY")]) ≈ two_by_two_jpmge["PY.g2","benchmark"] # 4.
#Implicit Variables
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("P[g1]‡X[s1]")]) ≈ two_by_two_jpmge["g1.s1","benchmark"] # 6.
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("P[g2]‡X[s1]")]) ≈ two_by_two_jpmge["g2.s1","benchmark"] # 2.
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("P[g1]‡X[s2]")]) ≈ two_by_two_jpmge["g1.s2","benchmark"] # 2.
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("P[g2]‡X[s2]")]) ≈ two_by_two_jpmge["g2.s2","benchmark"] # 10.
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PF[l]†X[s1]")]) ≈ two_by_two_jpmge["labor.s1","benchmark"] # 1.
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PF[k]†X[s1]")]) ≈ two_by_two_jpmge["capital.s1","benchmark"] # 1.
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PF[l]†X[s2]")]) ≈ two_by_two_jpmge["labor.s2","benchmark"] # 3.
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PF[k]†X[s2]")]) ≈ two_by_two_jpmge["capital.s2","benchmark"] # 1.
#Separate column in GAMS results bc of display limitation
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("P[g1]†X[s1]")]) ≈ two_by_two_jpmge["g1.s1","D benchmark"] # 4.
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("P[g1]†X[s2]")]) ≈ two_by_two_jpmge["g1.s2","D benchmark"] # 2.
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("P[g2]†X[s1]")]) ≈ two_by_two_jpmge["g2.s1","D benchmark"] # 2.
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("P[g2]†X[s2]")]) ≈ two_by_two_jpmge["g2.s2","D benchmark"] # 6.
    
    
    #Counter-factual 1, labour supply increased by 10%
    set_value(endow[:l], 1.1*get_value(endow[:l]))
    set_value(Y, 6.4)
    set_fixed!(Y, true)

    solve!(m)
    @test MPSGE.Complementarity.result_value(m._jump_model[:X][:s1]) ≈ two_by_two_jpmge["X.s1","Y=6.4"] # 0.996925617428787
    @test MPSGE.Complementarity.result_value(m._jump_model[:X][:s2]) ≈ two_by_two_jpmge["X.s2","Y=6.4"] # 1.09975731472318
    @test MPSGE.Complementarity.result_value(m._jump_model[:P][:g1]) ≈ two_by_two_jpmge["P.g1","Y=6.4"] # 1.01306317269818
    @test MPSGE.Complementarity.result_value(m._jump_model[:P][:g2]) ≈ two_by_two_jpmge["P.g2","Y=6.4"] # 0.994678919645561
    @test MPSGE.Complementarity.result_value(m._jump_model[:PF][:l]) ≈ two_by_two_jpmge["PF.labor","Y=6.4"] # 0.976659316086759
    @test MPSGE.Complementarity.result_value(m._jump_model[:PF][:k]) ≈ two_by_two_jpmge["PF.capital","Y=6.4"] # 1.05134950457745
    @test MPSGE.Complementarity.result_value(m._jump_model[:Y]) ≈ two_by_two_jpmge["Y._","Y=6.4"] # 6.4
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("P[g1]ρY")]) ≈ two_by_two_jpmge["PY.g1","Y=6.4"] # 2.10582458313179
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("P[g2]ρY")]) ≈ two_by_two_jpmge["PY.g2","Y=6.4"] # 4.28949139505944
    
    # Implicit variables
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("P[g1]‡X[s1]")]) ≈ two_by_two_jpmge["g1.s1","Y=6.4"]  # 6.02715706940893
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("P[g2]‡X[s1]")]) ≈ two_by_two_jpmge["g2.s1","Y=6.4"] # 1.97259369533903
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("P[g1]‡X[s2]")]) ≈ two_by_two_jpmge["g1.s2","Y=6.4"] # 2.03066185805148
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("P[g2]‡X[s2]")]) ≈ two_by_two_jpmge["g2.s2","Y=6.4"] # 9.96905522561061
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PF[l]†X[s1]")]) ≈ two_by_two_jpmge["labor.s1","Y=6.4"] # 1.03260012165563
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PF[k]†X[s1]")]) ≈ two_by_two_jpmge["capital.s1","Y=6.4"] # 0.959241930696129
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PF[l]†X[s2]")]) ≈ two_by_two_jpmge["labor.s2","Y=6.4"] # 3.06483479680894
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PF[k]†X[s2]")]) ≈ two_by_two_jpmge["capital.s2","Y=6.4"] # 0.949034056875742
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("P[g1]†X[s1]")]) ≈ two_by_two_jpmge["g1.s1","D Y=6.4"] # 3.98197686298778
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("P[g1]†X[s2]")]) ≈ two_by_two_jpmge["g1.s2","D Y=6.4"] # 1.96980111885026
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("P[g2]†X[s1]")]) ≈ two_by_two_jpmge["g2.s1","D Y=6.4"] # 2.02778707518332
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("P[g2]†X[s2]")]) ≈ two_by_two_jpmge["g2.s2","D Y=6.4"] # 6.01862449771618
        
    # Counter-factual 2, use Price of good 1 as the numeraire
    set_fixed!(Y,false)
    set_fixed!(P[:g1], true)
    solve!(m)
    
    @test MPSGE.Complementarity.result_value(m._jump_model[:X][:s1]) ≈ two_by_two_jpmge["X.s1","P(\"g1\")=1"] # 0.996925632214484
    @test MPSGE.Complementarity.result_value(m._jump_model[:X][:s2]) ≈ two_by_two_jpmge["X.s2","P(\"g1\")=1"] # 1.09975731240985
    @test MPSGE.Complementarity.result_value(m._jump_model[:P][:g1]) ≈ two_by_two_jpmge["P.g1","P(\"g1\")=1"] # 1
    @test MPSGE.Complementarity.result_value(m._jump_model[:P][:g2]) ≈ two_by_two_jpmge["P.g2","P(\"g1\")=1"] # 0.98185279887846
    @test MPSGE.Complementarity.result_value(m._jump_model[:PF][:l]) ≈ two_by_two_jpmge["PF.labor","P(\"g1\")=1"] atol=1.0e-7# 0.964065543125742
    @test MPSGE.Complementarity.result_value(m._jump_model[:PF][:k]) ≈ two_by_two_jpmge["PF.capital","P(\"g1\")=1"] # 1.03779263434603
    @test MPSGE.Complementarity.result_value(m._jump_model[:Y]) ≈ two_by_two_jpmge["Y._","P(\"g1\")=1"] # 6.31747365844532
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("P[g1]ρY")]) ≈ two_by_two_jpmge["PY.g1","P(\"g1\")=1"] # 2.10582455281511
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("P[g2]ρY")]) ≈ two_by_two_jpmge["PY.g2","P(\"g1\")=1"] # 4.28949136819802
        
    # Implicit variables
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("P[g1]‡X[s1]")]) ≈ two_by_two_jpmge["g1.s1","P(\"g1\")=1"]  # 6.0271570813322
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("P[g2]‡X[s1]")]) ≈ two_by_two_jpmge["g2.s1","P(\"g1\")=1"] # 1.97259368319538
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("P[g1]‡X[s2]")]) ≈ two_by_two_jpmge["g1.s2","P(\"g1\")=1"] # 2.03066187173167
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("P[g2]‡X[s2]")]) ≈ two_by_two_jpmge["g2.s2","P(\"g1\")=1"] # 9.96905521167758
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PF[l]†X[s1]")]) ≈ two_by_two_jpmge["labor.s1","P(\"g1\")=1"] # 1.03260013575074
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PF[k]†X[s1]")]) ≈ two_by_two_jpmge["capital.s1","P(\"g1\")=1"] # 0.95924193115089
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PF[l]†X[s2]")]) ≈ two_by_two_jpmge["labor.s2","P(\"g1\")=1"] # 3.06483482594899
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PF[k]†X[s2]")]) ≈ two_by_two_jpmge["capital.s2","P(\"g1\")=1"] # 0.949034053394531
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("P[g1]†X[s1]")]) ≈ two_by_two_jpmge["g1.s1","D P(\"g1\")=1"] # 3.98197684281702
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("P[g1]†X[s2]")]) ≈ two_by_two_jpmge["g1.s2","D P(\"g1\")=1"] # 1.9698011007128
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("P[g2]†X[s1]")]) ≈ two_by_two_jpmge["g2.s1","D P(\"g1\")=1"] # 2.02778708140645
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("P[g2]†X[s2]")]) ≈ two_by_two_jpmge["g2.s2","D P(\"g1\")=1"] # 6.01862449125626
                    
    # Counter-factual 3, use price of labour (wages) as the numeraire
    set_fixed!(P[:g1], false)
    set_fixed!(PF[:l], true)
    solve!(m)

    @test MPSGE.Complementarity.result_value(m._jump_model[:X][:s1]) ≈ two_by_two_jpmge["X.s1","PF(\"labor\")=1"] # 0.996925617427381
    @test MPSGE.Complementarity.result_value(m._jump_model[:X][:s2]) ≈ two_by_two_jpmge["X.s2","PF(\"labor\")=1"] # 1.09975731471612
    @test MPSGE.Complementarity.result_value(m._jump_model[:P][:g1]) ≈ two_by_two_jpmge["P.g1","PF(\"labor\")=1"] # 1.0372738538416
    @test MPSGE.Complementarity.result_value(m._jump_model[:P][:g2]) ≈ two_by_two_jpmge["P.g2","PF(\"labor\")=1"] # 1.01845024488663
    @test MPSGE.Complementarity.result_value(m._jump_model[:PF][:l]) ≈ two_by_two_jpmge["PF.labor","PF(\"labor\")=1"] # 1
    @test MPSGE.Complementarity.result_value(m._jump_model[:PF][:k]) ≈ two_by_two_jpmge["PF.capital","PF(\"labor\")=1"] # 1.07647517127483
    @test MPSGE.Complementarity.result_value(m._jump_model[:Y]) ≈ two_by_two_jpmge["Y._","PF(\"labor\")=1"] # 6.55295034254966
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("P[g1]ρY")]) ≈ two_by_two_jpmge["PY.g1","PF(\"labor\")=1"] # 2.10582458312251
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("P[g2]ρY")]) ≈ two_by_two_jpmge["PY.g2","PF(\"labor\")=1"] # 4.2894913950225
     
    # Implicit variables   
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("P[g1]‡X[s1]")]) ≈ two_by_two_jpmge["g1.s1","PF(\"labor\")=1"]  # 6.02715706940277
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("P[g2]‡X[s1]")]) ≈ two_by_two_jpmge["g2.s1","PF(\"labor\")=1"] # 1.9725936953453
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("P[g1]‡X[s2]")]) ≈ two_by_two_jpmge["g1.s2","PF(\"labor\")=1"] # 2.03066185804441
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("P[g2]‡X[s2]")]) ≈ two_by_two_jpmge["g2.s2","PF(\"labor\")=1"] # 9.96905522561781
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PF[l]†X[s1]")]) ≈ two_by_two_jpmge["labor.s1","PF(\"labor\")=1"] # 1.0326001216467
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PF[k]†X[s1]")]) ≈ two_by_two_jpmge["capital.s1","PF(\"labor\")=1"] # 0.959241930702248
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PF[l]†X[s2]")]) ≈ two_by_two_jpmge["labor.s2","PF(\"labor\")=1"] # 3.06483479679024
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PF[k]†X[s2]")]) ≈ two_by_two_jpmge["capital.s2","PF(\"labor\")=1"] # 0.949034056884212
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("P[g1]†X[s1]")]) ≈ two_by_two_jpmge["g1.s1","D PF(\"labor\")=1"] # 3.98197686299486
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("P[g1]†X[s2]")]) ≈ two_by_two_jpmge["g1.s2","D PF(\"labor\")=1"] # 1.96980111885878
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("P[g2]†X[s1]")]) ≈ two_by_two_jpmge["g2.s1","D PF(\"labor\")=1"] # 2.02778707517841
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("P[g2]†X[s2]")]) ≈ two_by_two_jpmge["g2.s2","D PF(\"labor\")=1"] # 6.01862449771691
        
end

@testitem "JPMGE Demand Elasticities" begin
using XLSX, MPSGE.JuMP.Containers
#A replication of the JPMGE from https://www.gams.com/34/docs/UG_MPSGE_Intro.html#UG_MPSGE_Intro_Appendix_jpmge
# Re-running the model and tests as checks on different Demand elasticities - here with Demand elasticity = 0 (Leontief)
    m = Model()
# All indexes and data as above, added for structure as @testitem
    goods = [:g1, :g2]
    factors = [:l, :k]
    sectors = [:s1, :s2]
    make0 = DenseAxisArray(Float64[6 2; 2 10], goods, sectors)
    use0 = DenseAxisArray(Float64[4 2; 2 6], goods, sectors)
    fd0 = DenseAxisArray(Float64[1 3; 1 1], factors, sectors)
    c0 = DenseAxisArray(Float64[2, 4], goods)
    e0 = DenseAxisArray(Float64[sum(fd0[f,:]) for f in factors], factors)

    endow = add!(m, Parameter(:endow, indices=(factors,), value=1.0)) 
    X = add!(m, Sector(:X, indices=(sectors,)))
    P = add!(m, Commodity(:P, indices=(goods,)))
    PF = add!(m, Commodity(:PF, indices=(factors,)))
    Y = add!(m, Consumer(:Y, benchmark=sum(fd0)))#example 4 has sum e0
    for j in sectors
        @production(m, X[j], 1, 1, [Output(P[i], make0[i,j]) for i in goods], [[Input(P[i], use0[i,j]) for i in goods]; [Input(PF[f], fd0[f,j]) for f in factors]])
    end

    @demand(m, Y, 0., [Demand(P[i], c0[i]) for i in goods], [Endowment(PF[:k], :($(endow[:k]) * $(e0[:k]))), Endowment(PF[:l], :($(endow[:l]) * $(e0[:l])))])

    avm = algebraic_version(m)
    @test typeof(avm) == MPSGE.AlgebraicWrapper

    solve!(m)

    gams_results = XLSX.readxlsx(joinpath(@__DIR__, "MPSGEresults.xlsx"))
    a_table = gams_results["JPMGE"][:]  # Generated from JPMGE_MPSGE
    two_by_two_jpmge = DenseAxisArray(a_table[2:end,3:end],string.(a_table[2:end,1],".",a_table[2:end,2]),a_table[1,3:end])

    @test MPSGE.Complementarity.result_value(m._jump_model[:X][:s1]) ≈ two_by_two_jpmge["X.s1","benchmark"] # 1.
    @test MPSGE.Complementarity.result_value(m._jump_model[:X][:s2]) ≈ two_by_two_jpmge["X.s2","benchmark"] # 1.
    @test MPSGE.Complementarity.result_value(m._jump_model[:P][:g1]) ≈ two_by_two_jpmge["P.g1","benchmark"] # 1.
    @test MPSGE.Complementarity.result_value(m._jump_model[:P][:g2]) ≈ two_by_two_jpmge["P.g2","benchmark"] # 1.
    @test MPSGE.Complementarity.result_value(m._jump_model[:PF][:l]) ≈ two_by_two_jpmge["PF.labor","benchmark"] # 1.
    @test MPSGE.Complementarity.result_value(m._jump_model[:PF][:k]) ≈ two_by_two_jpmge["PF.capital","benchmark"] # 1.
    @test MPSGE.Complementarity.result_value(m._jump_model[:Y]) ≈ two_by_two_jpmge["Y._","benchmark"] # 6.
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("P[g1]ρY")]) ≈ two_by_two_jpmge["PY.g1","benchmark"] # 2.
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("P[g2]ρY")]) ≈ two_by_two_jpmge["PY.g2","benchmark"] # 4.
#Implicit Variables
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("P[g1]‡X[s1]")]) ≈ two_by_two_jpmge["g1.s1","benchmark"] # 6.
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("P[g2]‡X[s1]")]) ≈ two_by_two_jpmge["g2.s1","benchmark"] # 2.
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("P[g1]‡X[s2]")]) ≈ two_by_two_jpmge["g1.s2","benchmark"] # 2.
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("P[g2]‡X[s2]")]) ≈ two_by_two_jpmge["g2.s2","benchmark"] # 10.
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PF[l]†X[s1]")]) ≈ two_by_two_jpmge["labor.s1","benchmark"] # 1.
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PF[k]†X[s1]")]) ≈ two_by_two_jpmge["capital.s1","benchmark"] # 1.
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PF[l]†X[s2]")]) ≈ two_by_two_jpmge["labor.s2","benchmark"] # 3.
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PF[k]†X[s2]")]) ≈ two_by_two_jpmge["capital.s2","benchmark"] # 1.
#Separate column in GAMS results bc of display limitation
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("P[g1]†X[s1]")]) ≈ two_by_two_jpmge["g1.s1","D benchmark"] # 4.
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("P[g1]†X[s2]")]) ≈ two_by_two_jpmge["g1.s2","D benchmark"] # 2.
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("P[g2]†X[s1]")]) ≈ two_by_two_jpmge["g2.s1","D benchmark"] # 2.
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("P[g2]†X[s2]")]) ≈ two_by_two_jpmge["g2.s2","D benchmark"] # 6.

    #Counter-factual 1, labour supply increased by 10%
    set_value(endow[:l], 1.1*get_value(endow[:l]))
    set_value(Y, 6.4)
    set_fixed!(Y, true)

    solve!(m)
    
    @test MPSGE.Complementarity.result_value(m._jump_model[:X][:s1]) ≈ two_by_two_jpmge["X.s1","D_elas=0,Y=6.4"] # 1.00695565465906
    @test MPSGE.Complementarity.result_value(m._jump_model[:X][:s2]) ≈ two_by_two_jpmge["X.s2","D_elas=0,Y=6.4"] # 1.09465569946758
    @test MPSGE.Complementarity.result_value(m._jump_model[:P][:g1]) ≈ two_by_two_jpmge["P.g1","D_elas=0,Y=6.4"] # 1.01368184594902
    @test MPSGE.Complementarity.result_value(m._jump_model[:P][:g2]) ≈ two_by_two_jpmge["P.g2","D_elas=0,Y=6.4"] # 0.994372399169793
    @test MPSGE.Complementarity.result_value(m._jump_model[:PF][:l]) ≈ two_by_two_jpmge["PF.labor","D_elas=0,Y=6.4"] # 0.975465157228405
    @test MPSGE.Complementarity.result_value(m._jump_model[:PF][:k]) ≈ two_by_two_jpmge["PF.capital","D_elas=0,Y=6.4"] # 1.05397665409715
    @test MPSGE.Complementarity.result_value(m._jump_model[:Y]) ≈ two_by_two_jpmge["Y._","D_elas=0,Y=6.4"] # 6.4
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("P[g1]ρY")]) ≈ two_by_two_jpmge["PY.g1","D_elas=0,Y=6.4"] # 2.13160911430573
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("P[g2]ρY")]) ≈ two_by_two_jpmge["PY.g2","D_elas=0,Y=6.4"] # 4.26321822861147
    
    # Implicit variables
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("P[g1]‡X[s1]")]) ≈ two_by_two_jpmge["g1.s1","D_elas=0,Y=6.4"]  # 6.02850291751314
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("P[g2]‡X[s1]")]) ≈ two_by_two_jpmge["g2.s1","D_elas=0,Y=6.4"] # 1.97122234273858
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("P[g1]‡X[s2]")]) ≈ two_by_two_jpmge["g1.s2","D_elas=0,Y=6.4"] # 2.03220726447235
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("P[g2]‡X[s2]")]) ≈ two_by_two_jpmge["g2.s2","D_elas=0,Y=6.4"] # 9.967480532769
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PF[l]†X[s1]")]) ≈ two_by_two_jpmge["labor.s1","D_elas=0,Y=6.4"] # 1.03426465263408
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PF[k]†X[s1]")]) ≈ two_by_two_jpmge["capital.s1","D_elas=0,Y=6.4"] # 0.957221517265679
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PF[l]†X[s2]")]) ≈ two_by_two_jpmge["labor.s2","D_elas=0,Y=6.4"] # 3.06812576890585
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PF[k]†X[s2]")]) ≈ two_by_two_jpmge["capital.s2","D_elas=0,Y=6.4"] # 0.946526273906878
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("P[g1]†X[s1]")]) ≈ two_by_two_jpmge["g1.s1","D D_elas=0,Y=6.4"] # 3.98108789667806
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("P[g1]†X[s2]")]) ≈ two_by_two_jpmge["g1.s2","D D_elas=0,Y=6.4"] # 1.96830316962702
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("P[g2]†X[s1]")]) ≈ two_by_two_jpmge["g2.s1","D D_elas=0,Y=6.4"] # 2.02919777910129
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("P[g2]†X[s2]")]) ≈ two_by_two_jpmge["g2.s2","D D_elas=0,Y=6.4"] # 6.01957533829582
      
    # Counter-factual 2, use Price of good 1 as the numeraire
    set_fixed!(Y,false)
    set_fixed!(P[:g1], true)
    solve!(m)
    
    @test MPSGE.Complementarity.result_value(m._jump_model[:X][:s1]) ≈ two_by_two_jpmge["X.s1","D_elas=0,P(\"g1\")=1"] atol=1.0e-7# 1.00695567662299
    @test MPSGE.Complementarity.result_value(m._jump_model[:X][:s2]) ≈ two_by_two_jpmge["X.s2","D_elas=0,P(\"g1\")=1"] # 1.09465569446489
    @test MPSGE.Complementarity.result_value(m._jump_model[:P][:g1]) ≈ two_by_two_jpmge["P.g1","D_elas=0,P(\"g1\")=1"] # 1
    @test MPSGE.Complementarity.result_value(m._jump_model[:P][:g2]) ≈ two_by_two_jpmge["P.g2","D_elas=0,P(\"g1\")=1"] # 0.980951166489968
    @test MPSGE.Complementarity.result_value(m._jump_model[:PF][:l]) ≈ two_by_two_jpmge["PF.labor","D_elas=0,P(\"g1\")=1"] atol=1.0e-7# 0.96229910684127
    @test MPSGE.Complementarity.result_value(m._jump_model[:PF][:k]) ≈ two_by_two_jpmge["PF.capital","D_elas=0,P(\"g1\")=1"] # 1.0397509357684
    @test MPSGE.Complementarity.result_value(m._jump_model[:Y]) ≈ two_by_two_jpmge["Y._","D_elas=0,P(\"g1\")=1"] atol=1.0e-6# 6.31361794163839
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("P[g1]ρY")]) ≈ two_by_two_jpmge["PY.g1","D_elas=0,P(\"g1\")=1"] # 2.13160909167667
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("P[g2]ρY")]) ≈ two_by_two_jpmge["PY.g2","D_elas=0,P(\"g1\")=1"] # 4.26321818335335
    
    # Implicit variables
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("P[g1]‡X[s1]")]) ≈ two_by_two_jpmge["g1.s1","D_elas=0,P(\"g1\")=1"]  # 6.02850293214301
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("P[g2]‡X[s1]")]) ≈ two_by_two_jpmge["g2.s1","D_elas=0,P(\"g1\")=1"] # 1.97122232782462
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("P[g1]‡X[s2]")]) ≈ two_by_two_jpmge["g1.s2","D_elas=0,P(\"g1\")=1"] # 2.03220728128503
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("P[g2]‡X[s2]")]) ≈ two_by_two_jpmge["g2.s2","D_elas=0,P(\"g1\")=1"] # 9.96748051562983
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PF[l]†X[s1]")]) ≈ two_by_two_jpmge["labor.s1","D_elas=0,P(\"g1\")=1"] atol=1.0e-7 # 1.0342646699325
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PF[k]†X[s1]")]) ≈ two_by_two_jpmge["capital.s1","D_elas=0,P(\"g1\")=1"] # 0.957221517072259
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PF[l]†X[s2]")]) ≈ two_by_two_jpmge["labor.s2","D_elas=0,P(\"g1\")=1"] # 3.06812580456063
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PF[k]†X[s2]")]) ≈ two_by_two_jpmge["capital.s2","D_elas=0,P(\"g1\")=1"] # 0.94652626888426
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("P[g1]†X[s1]")]) ≈ two_by_two_jpmge["g1.s1","D D_elas=0,P(\"g1\")=1"] # 3.98108787245412
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("P[g1]†X[s2]")]) ≈ two_by_two_jpmge["g1.s2","D D_elas=0,P(\"g1\")=1"] # 1.96830314760356
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("P[g2]†X[s1]")]) ≈ two_by_two_jpmge["g2.s1","D D_elas=0,P(\"g1\")=1"] # 2.02919778703114
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("P[g2]†X[s2]")]) ≈ two_by_two_jpmge["g2.s2","D D_elas=0,P(\"g1\")=1"] # 6.0195753310938
                
    # Counter-factual 3, use price of labour (wages) as the numeraire
    set_fixed!(P[:g1], false)
    set_fixed!(PF[:l], true)
    solve!(m)

    @test MPSGE.Complementarity.result_value(m._jump_model[:X][:s1]) ≈ two_by_two_jpmge["X.s1","D_elas=0,PF(\"l\")=1"] # 1.00695565465863
    @test MPSGE.Complementarity.result_value(m._jump_model[:X][:s2]) ≈ two_by_two_jpmge["X.s2","D_elas=0,PF(\"l\")=1"] # 1.09465569946539
    @test MPSGE.Complementarity.result_value(m._jump_model[:P][:g1]) ≈ two_by_two_jpmge["P.g1","D_elas=0,PF(\"l\")=1"] # 1.03917791264692
    @test MPSGE.Complementarity.result_value(m._jump_model[:P][:g2]) ≈ two_by_two_jpmge["P.g2","D_elas=0,PF(\"l\")=1"] # 1.01938279578823
    @test MPSGE.Complementarity.result_value(m._jump_model[:PF][:l]) ≈ two_by_two_jpmge["PF.labor","D_elas=0,PF(\"l\")=1"] # 1
    @test MPSGE.Complementarity.result_value(m._jump_model[:PF][:k]) ≈ two_by_two_jpmge["PF.capital","D_elas=0,PF(\"l\")=1"] # 1.08048621345859
    @test MPSGE.Complementarity.result_value(m._jump_model[:Y]) ≈ two_by_two_jpmge["Y._","D_elas=0,PF(\"l\")=1"] # 6.56097242691719
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("P[g1]ρY")]) ≈ two_by_two_jpmge["PY.g1","D_elas=0,PF(\"l\")=1"] # 2.13160911430459
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("P[g2]ρY")]) ≈ two_by_two_jpmge["PY.g2","D_elas=0,PF(\"l\")=1"] # 4.26321822860918
        
    # Implicit variables
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("P[g1]‡X[s1]")]) ≈ two_by_two_jpmge["g1.s1","D_elas=0,PF(\"l\")=1"]  # 6.02850291751269
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("P[g2]‡X[s1]")]) ≈ two_by_two_jpmge["g2.s1","D_elas=0,PF(\"l\")=1"] # 1.97122234273905
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("P[g1]‡X[s2]")]) ≈ two_by_two_jpmge["g1.s2","D_elas=0,PF(\"l\")=1"] # 2.03220726447182
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("P[g2]‡X[s2]")]) ≈ two_by_two_jpmge["g2.s2","D_elas=0,PF(\"l\")=1"] # 9.96748053276953
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PF[l]†X[s1]")]) ≈ two_by_two_jpmge["labor.s1","D_elas=0,PF(\"l\")=1"] # 1.03426465263337
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PF[k]†X[s1]")]) ≈ two_by_two_jpmge["capital.s1","D_elas=0,PF(\"l\")=1"] # 0.957221517267422
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PF[l]†X[s2]")]) ≈ two_by_two_jpmge["labor.s2","D_elas=0,PF(\"l\")=1"] # 3.06812576890445
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PF[k]†X[s2]")]) ≈ two_by_two_jpmge["capital.s2","D_elas=0,PF(\"l\")=1"] # 0.946526273908822
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("P[g1]†X[s1]")]) ≈ two_by_two_jpmge["g1.s1","D D_elas=0,PF(\"l\")=1"] # 3.98108789667772
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("P[g1]†X[s2]")]) ≈ two_by_two_jpmge["g1.s2","D D_elas=0,PF(\"l\")=1"] # 1.96830316962732
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("P[g2]†X[s1]")]) ≈ two_by_two_jpmge["g2.s1","D D_elas=0,PF(\"l\")=1"] # 2.02919777910049
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("P[g2]†X[s2]")]) ≈ two_by_two_jpmge["g2.s2","D D_elas=0,PF(\"l\")=1"] # 6.01957533829483
           
    #A replication of the JPMGE from https://www.gams.com/34/docs/UG_MPSGE_Intro.html#UG_MPSGE_Intro_Appendix_jpmge
    # Re-running the model and tests as checks on different Demand elasticities - here with Demand elasticity = 2. (A CES example)
    m = Model()
    goods = [:g1, :g2]
    factors = [:l, :k]
    sectors = [:s1, :s2]
    make0 = DenseAxisArray(Float64[6 2; 2 10], goods, sectors)
    use0 = DenseAxisArray(Float64[4 2; 2 6], goods, sectors)
    fd0 = DenseAxisArray(Float64[1 3; 1 1], factors, sectors)
    c0 = DenseAxisArray(Float64[2, 4], goods)
    e0 = DenseAxisArray(Float64[sum(fd0[f,:]) for f in factors], factors)
# All indices and data as above
    endow = add!(m, Parameter(:endow, indices=(factors,), value=1.0)) 
    X = add!(m, Sector(:X, indices=(sectors,)))
    P = add!(m, Commodity(:P, indices=(goods,)))
    PF = add!(m, Commodity(:PF, indices=(factors,)))
    Y = add!(m, Consumer(:Y, benchmark=sum(fd0)))#example 4 has sum e0
    for j in sectors
        @production(m, X[j], 1, 1, [Output(P[i], make0[i,j]) for i in goods], [[Input(P[i], use0[i,j]) for i in goods]; [Input(PF[f], fd0[f,j]) for f in factors]])
    end

    @demand(m, Y, 2., [Demand(P[i], c0[i]) for i in goods], [Endowment(PF[:k], :($(endow[:k]) * $(e0[:k]))), Endowment(PF[:l], :($(endow[:l]) * $(e0[:l])))])

    avm = algebraic_version(m)
    @test typeof(avm) == MPSGE.AlgebraicWrapper

    solve!(m)

    @test MPSGE.Complementarity.result_value(m._jump_model[:X][:s1]) ≈ two_by_two_jpmge["X.s1","benchmark"] # 1.
    @test MPSGE.Complementarity.result_value(m._jump_model[:X][:s2]) ≈ two_by_two_jpmge["X.s2","benchmark"] # 1.
    @test MPSGE.Complementarity.result_value(m._jump_model[:P][:g1]) ≈ two_by_two_jpmge["P.g1","benchmark"] # 1.
    @test MPSGE.Complementarity.result_value(m._jump_model[:P][:g2]) ≈ two_by_two_jpmge["P.g2","benchmark"] # 1.
    @test MPSGE.Complementarity.result_value(m._jump_model[:PF][:l]) ≈ two_by_two_jpmge["PF.labor","benchmark"] # 1.
    @test MPSGE.Complementarity.result_value(m._jump_model[:PF][:k]) ≈ two_by_two_jpmge["PF.capital","benchmark"] # 1.
    @test MPSGE.Complementarity.result_value(m._jump_model[:Y]) ≈ two_by_two_jpmge["Y._","benchmark"] # 6.
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("P[g1]ρY")]) ≈ two_by_two_jpmge["PY.g1","benchmark"] # 2.
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("P[g2]ρY")]) ≈ two_by_two_jpmge["PY.g2","benchmark"] # 4.
#Implicit Variables
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("P[g1]‡X[s1]")]) ≈ two_by_two_jpmge["g1.s1","benchmark"] # 6.
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("P[g2]‡X[s1]")]) ≈ two_by_two_jpmge["g2.s1","benchmark"] # 2.
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("P[g1]‡X[s2]")]) ≈ two_by_two_jpmge["g1.s2","benchmark"] # 2.
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("P[g2]‡X[s2]")]) ≈ two_by_two_jpmge["g2.s2","benchmark"] # 10.
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PF[l]†X[s1]")]) ≈ two_by_two_jpmge["labor.s1","benchmark"] # 1.
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PF[k]†X[s1]")]) ≈ two_by_two_jpmge["capital.s1","benchmark"] # 1.
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PF[l]†X[s2]")]) ≈ two_by_two_jpmge["labor.s2","benchmark"] # 3.
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PF[k]†X[s2]")]) ≈ two_by_two_jpmge["capital.s2","benchmark"] # 1.
#Separate column in GAMS results bc of display limitation
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("P[g1]†X[s1]")]) ≈ two_by_two_jpmge["g1.s1","D benchmark"] # 4.
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("P[g1]†X[s2]")]) ≈ two_by_two_jpmge["g1.s2","D benchmark"] # 2.
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("P[g2]†X[s1]")]) ≈ two_by_two_jpmge["g2.s1","D benchmark"] # 2.
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("P[g2]†X[s2]")]) ≈ two_by_two_jpmge["g2.s2","D benchmark"] # 6.

    #Counter-factual 1, labour supply increased by 10%
    set_value(endow[:l], 1.1*get_value(endow[:l]))
    set_value(Y, 6.4)
    set_fixed!(Y, true)

    solve!(m)

    @test MPSGE.Complementarity.result_value(m._jump_model[:X][:s1]) ≈ two_by_two_jpmge["X.s1","D_elas=2,Y=6.4"] # 0.987856533434743
    @test MPSGE.Complementarity.result_value(m._jump_model[:X][:s2]) ≈ two_by_two_jpmge["X.s2","D_elas=2,Y=6.4"] # 1.10437048613336
    @test MPSGE.Complementarity.result_value(m._jump_model[:P][:g1]) ≈ two_by_two_jpmge["P.g1","D_elas=2,Y=6.4"] # 1.01249987524683
    @test MPSGE.Complementarity.result_value(m._jump_model[:P][:g2]) ≈ two_by_two_jpmge["P.g2","D_elas=2,Y=6.4"] # 0.994953167286117
    @test MPSGE.Complementarity.result_value(m._jump_model[:PF][:l]) ≈ two_by_two_jpmge["PF.labor","D_elas=2,Y=6.4"] # 0.977738693937376
    @test MPSGE.Complementarity.result_value(m._jump_model[:PF][:k]) ≈ two_by_two_jpmge["PF.capital","D_elas=2,Y=6.4"] # 1.04897487333719
    @test MPSGE.Complementarity.result_value(m._jump_model[:Y]) ≈ two_by_two_jpmge["Y._","D_elas=2,Y=6.4"] # 6.4
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("P[g1]ρY")]) ≈ two_by_two_jpmge["PY.g1","D_elas=2,Y=6.4"] # 2.08251175868133
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("P[g2]ρY")]) ≈ two_by_two_jpmge["PY.g2","D_elas=2,Y=6.4"] # 4.31322523032984
        
    # Implicit variables
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("P[g1]‡X[s1]")]) ≈ two_by_two_jpmge["g1.s1","D_elas=2,Y=6.4"]  # 6.02593709632531
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("P[g2]‡X[s1]")]) ≈ two_by_two_jpmge["g2.s1","D_elas=2,Y=6.4"] # 1.97383569994486
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("P[g1]‡X[s2]")]) ≈ two_by_two_jpmge["g1.s2","D_elas=2,Y=6.4"] # 2.02926314124557
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("P[g2]‡X[s2]")]) ≈ two_by_two_jpmge["g2.s2","D_elas=2,Y=6.4"] # 9.97047920201986
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PF[l]†X[s1]")]) ≈ two_by_two_jpmge["labor.s1","D_elas=2,Y=6.4"] # 1.03109535932841
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PF[k]†X[s1]")]) ≈ two_by_two_jpmge["capital.s1","D_elas=2,Y=6.4"] # 0.96107338276594
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PF[l]†X[s2]")]) ≈ two_by_two_jpmge["labor.s2","D_elas=2,Y=6.4"] # 3.06185809486106
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PF[k]†X[s2]")]) ≈ two_by_two_jpmge["capital.s2","D_elas=2,Y=6.4"] # 0.95130881612284
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("P[g1]†X[s1]")]) ≈ two_by_two_jpmge["g1.s1","D D_elas=2,Y=6.4"] # 3.98278302882309
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("P[g1]†X[s2]")]) ≈ two_by_two_jpmge["g1.s2","D D_elas=2,Y=6.4"] # 1.97115885007637
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("P[g2]†X[s1]")]) ≈ two_by_two_jpmge["g2.s1","D D_elas=2,Y=6.4"] # 2.02651112253757
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("P[g2]†X[s2]")]) ≈ two_by_two_jpmge["g2.s2","D D_elas=2,Y=6.4"] # 6.01776492225618
           
    # Counter-factual 2, use Price of good 1 as the numeraire
    set_fixed!(Y,false)
    set_fixed!(P[:g1], true)
    solve!(m)

    @test MPSGE.Complementarity.result_value(m._jump_model[:X][:s1]) ≈ two_by_two_jpmge["X.s1","D_elas=2,P(\"g1\")=1"] # 0.987856539834064
    @test MPSGE.Complementarity.result_value(m._jump_model[:X][:s2]) ≈ two_by_two_jpmge["X.s2","D_elas=2,P(\"g1\")=1"] # 1.10437048704423
    @test MPSGE.Complementarity.result_value(m._jump_model[:P][:g1]) ≈ two_by_two_jpmge["P.g1","D_elas=2,P(\"g1\")=1"] # 1
    @test MPSGE.Complementarity.result_value(m._jump_model[:P][:g2]) ≈ two_by_two_jpmge["P.g2","D_elas=2,P(\"g1\")=1"] # 0.982669909969397
    @test MPSGE.Complementarity.result_value(m._jump_model[:PF][:l]) ≈ two_by_two_jpmge["PF.labor","D_elas=2,P(\"g1\")=1"] # 0.965667951333231
    @test MPSGE.Complementarity.result_value(m._jump_model[:PF][:k]) ≈ two_by_two_jpmge["PF.capital","D_elas=2,P(\"g1\")=1"] # 1.03602468782685
    @test MPSGE.Complementarity.result_value(m._jump_model[:Y]) ≈ two_by_two_jpmge["Y._","D_elas=2,P(\"g1\")=1"] # 6.32098836151992
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("P[g1]ρY")]) ≈ two_by_two_jpmge["PY.g1","D_elas=2,P(\"g1\")=1"] atol=1.0e-7 # 2.0825117266148
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("P[g2]ρY")]) ≈ two_by_two_jpmge["PY.g2","D_elas=2,P(\"g1\")=1"] # 4.31322521622455
    
    # Implicit variables
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("P[g1]‡X[s1]")]) ≈ two_by_two_jpmge["g1.s1","D_elas=2,P(\"g1\")=1"]  # 6.025937105223
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("P[g2]‡X[s1]")]) ≈ two_by_two_jpmge["g2.s1","D_elas=2,P(\"g1\")=1"] # 1.97383569089024
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("P[g1]‡X[s2]")]) ≈ two_by_two_jpmge["g1.s2","D_elas=2,P(\"g1\")=1"] # 2.02926315143946
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("P[g2]‡X[s2]")]) ≈ two_by_two_jpmge["g2.s2","D_elas=2,P(\"g1\")=1"] # 9.97047919164619
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PF[l]†X[s1]")]) ≈ two_by_two_jpmge["labor.s1","D_elas=2,P(\"g1\")=1"] # 1.03109536963407
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PF[k]†X[s1]")]) ≈ two_by_two_jpmge["capital.s1","D_elas=2,P(\"g1\")=1"] # 0.961073384566025
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PF[l]†X[s2]")]) ≈ two_by_two_jpmge["labor.s2","D_elas=2,P(\"g1\")=1"] # 3.0618581162154
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PF[k]†X[s2]")]) ≈ two_by_two_jpmge["capital.s2","D_elas=2,P(\"g1\")=1"] # 0.951308815031151
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("P[g1]†X[s1]")]) ≈ two_by_two_jpmge["g1.s1","D D_elas=2,P(\"g1\")=1"] # 3.98278301289486
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("P[g1]†X[s2]")]) ≈ two_by_two_jpmge["g1.s2","D D_elas=2,P(\"g1\")=1"] # 1.97115883623916
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("P[g2]†X[s1]")]) ≈ two_by_two_jpmge["g2.s1","D D_elas=2,P(\"g1\")=1"] # 2.02651112672153
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("P[g2]†X[s2]")]) ≈ two_by_two_jpmge["g2.s2","D D_elas=2,P(\"g1\")=1"] # 6.01776491650351
                    
    # Counter-factual 3, use price of labour (wages) as the numeraire
    set_fixed!(P[:g1], false)
    set_fixed!(PF[:l], true)
    solve!(m)

    @test MPSGE.Complementarity.result_value(m._jump_model[:X][:s1]) ≈ two_by_two_jpmge["X.s1","D_elas=2,PF(\"l\")=1"] # 0.987856533434657
    @test MPSGE.Complementarity.result_value(m._jump_model[:X][:s2]) ≈ two_by_two_jpmge["X.s2","D_elas=2,PF(\"l\")=1"] # 1.10437048613261
    @test MPSGE.Complementarity.result_value(m._jump_model[:P][:g1]) ≈ two_by_two_jpmge["P.g1","D_elas=2,PF(\"l\")=1"] # 1.03555262927087
    @test MPSGE.Complementarity.result_value(m._jump_model[:P][:g2]) ≈ two_by_two_jpmge["P.g2","D_elas=2,PF(\"l\")=1"] # 1.01760641514489
    @test MPSGE.Complementarity.result_value(m._jump_model[:PF][:l]) ≈ two_by_two_jpmge["PF.labor","D_elas=2,PF(\"l\")=1"] # 1
    @test MPSGE.Complementarity.result_value(m._jump_model[:PF][:k]) ≈ two_by_two_jpmge["PF.capital","D_elas=2,PF(\"l\")=1"] # 1.07285809576816
    @test MPSGE.Complementarity.result_value(m._jump_model[:Y]) ≈ two_by_two_jpmge["Y._","D_elas=2,PF(\"l\")=1"] # 6.54571619153632
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("P[g1]ρY")]) ≈ two_by_two_jpmge["PY.g1","D_elas=2,PF(\"l\")=1"] # 2.08251175868083
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("P[g2]ρY")]) ≈ two_by_two_jpmge["PY.g2","D_elas=2,PF(\"l\")=1"] # 4.31322523032828
        # Implicit variables
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("P[g1]‡X[s1]")]) ≈ two_by_two_jpmge["g1.s1","D_elas=2,PF(\"l\")=1"]  # 6.02593709632522
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("P[g2]‡X[s1]")]) ≈ two_by_two_jpmge["g2.s1","D_elas=2,PF(\"l\")=1"] # 1.97383569994494
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("P[g1]‡X[s2]")]) ≈ two_by_two_jpmge["g1.s2","D_elas=2,PF(\"l\")=1"] # 2.02926314124547
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("P[g2]‡X[s2]")]) ≈ two_by_two_jpmge["g2.s2","D_elas=2,PF(\"l\")=1"] # 9.97047920201996
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PF[l]†X[s1]")]) ≈ two_by_two_jpmge["labor.s1","D_elas=2,PF(\"l\")=1"] # 1.03109535932825
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PF[k]†X[s1]")]) ≈ two_by_two_jpmge["capital.s1","D_elas=2,PF(\"l\")=1"] # 0.961073382766426
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PF[l]†X[s2]")]) ≈ two_by_two_jpmge["labor.s2","D_elas=2,PF(\"l\")=1"] # 3.06185809486075
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PF[k]†X[s2]")]) ≈ two_by_two_jpmge["capital.s2","D_elas=2,PF(\"l\")=1"] # 0.951308816123371
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("P[g1]†X[s1]")]) ≈ two_by_two_jpmge["g1.s1","D D_elas=2,PF(\"l\")=1"] # 3.98278302882293
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("P[g1]†X[s2]")]) ≈ two_by_two_jpmge["g1.s2","D D_elas=2,PF(\"l\")=1"] # 1.97115885007639
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("P[g2]†X[s1]")]) ≈ two_by_two_jpmge["g2.s1","D D_elas=2,PF(\"l\")=1"] # 2.02651112253737
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("P[g2]†X[s2]")]) ≈ two_by_two_jpmge["g2.s2","D D_elas=2,PF(\"l\")=1"] # 6.0177649222559
       
end
