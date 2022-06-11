@testset "JPMGE (Joint Production Intermediate Demand)" begin
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
        @production(m, X[j], 1, 1, [Output(P[i], make0[i,j]) for i in goods], [[Input(P[i], use0[i,j]) for i in goods]; [Input(PF[f], fd0[f,j]) for f in factors]])
    end

    @demand(m, Y, [Demand(P[i], c0[i]) for i in goods], [Endowment(PF[:k], :($(endow[:k]) * $(e0[:k]))), Endowment(PF[:l], :($(endow[:l]) * $(e0[:l])))])

    avm = algebraic_version(m)
    @test typeof(avm) == MPSGE.AlgebraicWrapper

    solve!(m)

    @test MPSGE.Complementarity.result_value(m._jump_model[:X][:s1]) ≈ 1.
    @test MPSGE.Complementarity.result_value(m._jump_model[:X][:s2]) ≈ 1.
    @test MPSGE.Complementarity.result_value(m._jump_model[:P][:g1]) ≈ 1.
    @test MPSGE.Complementarity.result_value(m._jump_model[:P][:g2]) ≈ 1.
    @test MPSGE.Complementarity.result_value(m._jump_model[:PF][:l]) ≈ 1.
    @test MPSGE.Complementarity.result_value(m._jump_model[:PF][:k]) ≈ 1.
    @test MPSGE.Complementarity.result_value(m._jump_model[:Y]) ≈ 6.
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("P[g1]‡X[s1]")]) ≈ 6.
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("P[g2]‡X[s1]")]) ≈ 2.
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("P[g1]‡X[s2]")]) ≈ 2.
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("P[g2]‡X[s2]")]) ≈10.
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("P[g1]†X[s1]")]) ≈ 4.
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("P[g2]†X[s1]")]) ≈ 2.
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PF[l]†X[s1]")]) ≈ 1.
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PF[k]†X[s1]")]) ≈ 1.
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("P[g1]†X[s2]")]) ≈ 2.
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("P[g2]†X[s2]")]) ≈ 6.
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PF[l]†X[s2]")]) ≈ 3.
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PF[k]†X[s2]")]) ≈ 1.
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("P[g1]ρY")]) ≈ 2.
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("P[g2]ρY")]) ≈ 4.
    

    #Counter-factual 1
    set_value(endow[:l], 1.1*get_value(endow[:l]))
    fd1 = fd0 .* convert(Vector, get_value.(endow))
    set_value(Y, sum(DenseAxisArray(Float64[sum(fd1[f,:]) for f in factors], factors)))
    set_fixed!(Y, true)

    solve!(m)
    @test MPSGE.Complementarity.result_value(m._jump_model[:X][:s1]) ≈ 0.99692562
    @test MPSGE.Complementarity.result_value(m._jump_model[:X][:s2]) ≈ 1.09975731
    @test MPSGE.Complementarity.result_value(m._jump_model[:P][:g1]) ≈ 1.01306317
    @test MPSGE.Complementarity.result_value(m._jump_model[:P][:g2]) ≈ 0.99467892
    @test MPSGE.Complementarity.result_value(m._jump_model[:PF][:l]) ≈ 0.97665932
    @test MPSGE.Complementarity.result_value(m._jump_model[:PF][:k]) ≈ 1.0513495
    @test MPSGE.Complementarity.result_value(m._jump_model[:Y]) ≈ 6.4   
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("P[g1]‡X[s1]")]) ≈ 6.0271570795595
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("P[g2]‡X[s1]")]) ≈ 1.97259368637181
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("P[g1]‡X[s2]")]) ≈ 2.03066186698742
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("P[g2]‡X[s2]")]) ≈ 9.96905522562002 #note - digits after 9.969 added from MPSGE.jl results bc GAMS not showing
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("P[g1]†X[s1]")]) ≈ 3.98197684247759
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("P[g2]†X[s1]")]) ≈ 2.02778707866119
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PF[l]†X[s1]")]) ≈ 1.03260012599366
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PF[k]†X[s1]")]) ≈ 0.959241925360056
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("P[g1]†X[s2]")]) ≈ 1.96980110341978
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("P[g2]†X[s2]")]) ≈ 6.018624497730061 #note - digits after 6.0186 added from MPSGE.jl results bc GAMS not showing
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PF[l]†X[s2]")]) ≈ 3.06483480444652
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PF[k]†X[s2]")]) ≈ 0.94903406
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("P[g1]ρY")]) ≈ 2.1058245831306
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("P[g2]ρY")]) ≈ 4.28949135539776

    set_fixed!(Y,false)

    set_fixed!(P[:g1], true)
    solve!(m)
    
    @test MPSGE.Complementarity.result_value(m._jump_model[:X][:s1]) ≈ 0.996925617439043 # not quite…0.99692552
    @test MPSGE.Complementarity.result_value(m._jump_model[:X][:s2]) ≈ 1.09975731474277 # not quite…1.09975733
    @test MPSGE.Complementarity.result_value(m._jump_model[:P][:g1]) ≈ 1
    @test MPSGE.Complementarity.result_value(m._jump_model[:P][:g2]) ≈ 0.981852806861767#note - digits after 0.9818528 added from MPSGE.jl results bc GAMS not showing
    @test MPSGE.Complementarity.result_value(m._jump_model[:PF][:l]) ≈ 0.964065561173485 # not quite…0.96406555
    @test MPSGE.Complementarity.result_value(m._jump_model[:PF][:k]) ≈ 1.0377926401152#note - digits after 1.0377926 added from MPSGE.jl results bc GAMS not showing
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("P[g1]‡X[s1]")]) ≈ 6.02715706941587#note - digits after 6.0272 added from MPSGE.jl results bc GAMS not showing
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("P[g2]‡X[s1]")]) ≈ 1.97259369533833#note - digits after 1.9726 added from MPSGE.jl results bc GAMS not showing
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("P[g1]‡X[s2]")]) ≈ 2.03066185804686#note - digits after 2.0307 added from MPSGE.jl results bc GAMS not showing
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("P[g2]‡X[s2]")]) ≈ 9.96905522562263#note - digits after 9.9691 added from MPSGE.jl results bc GAMS not showing
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("P[g1]†X[s1]")]) ≈ 3.98197686300985#note - digits after 3.982 added from MPSGE.jl results bc GAMS not showing
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("P[g2]†X[s1]")]) ≈ 2.02778707519236#note - digits after 2.0278 added from MPSGE.jl results bc GAMS not showing
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PF[l]†X[s1]")]) ≈ 1.0326001216173 # not quite…1.03260013
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PF[k]†X[s1]")]) ≈ 0.959241930675824#note - digits after 0.95924193 added from MPSGE.jl results bc GAMS not showing
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("P[g1]†X[s2]")]) ≈ 1.96980111885957#note - digits after 1.9698 added from MPSGE.jl results bc GAMS not showing
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("P[g2]†X[s2]")]) ≈ 6.01862449776752#note - digits after 6.0186 added from MPSGE.jl results bc GAMS not showing
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PF[l]†X[s2]")]) ≈ 3.06483479672782#note - digits after 3.0648348 added from MPSGE.jl results bc GAMS not showing
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PF[k]†X[s2]")]) ≈ 0.949034056851536#note - digits after 0.94903405 added from MPSGE.jl results bc GAMS not showing
    @test MPSGE.Complementarity.result_value(m._jump_model[:Y]) ≈ 6.31747374939373 # not quite…6.31747363
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("P[g1]ρY")]) ≈ 2.10582458313124 # not quite…2.10582454
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("P[g2]ρY")]) ≈ 4.28949139508602 # not quite…4.28949136
                 
    set_fixed!(P[:g1], false)
    set_fixed!(PF[:l], true)
    solve!(m)

    @test MPSGE.Complementarity.result_value(m._jump_model[:X][:s1]) ≈ 0.996925617406936# not quite…0.9969255
    @test MPSGE.Complementarity.result_value(m._jump_model[:X][:s2]) ≈ 1.09975731471521# not quite…1.09975741
    @test MPSGE.Complementarity.result_value(m._jump_model[:P][:g1]) ≈ 1.03727385383628# not quite…1.03727374
    @test MPSGE.Complementarity.result_value(m._jump_model[:P][:g2]) ≈ 1.01845024488441# not quite…1.01845009
    @test MPSGE.Complementarity.result_value(m._jump_model[:PF][:l]) ≈ 1
    @test MPSGE.Complementarity.result_value(m._jump_model[:PF][:k]) ≈ 1.07647517126301# not quite…1.07647514
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("P[g1]‡X[s1]")]) ≈ 6.02715706940364#note - digits after 6.0272 added from MPSGE.jl results bc GAMS not showing
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("P[g2]‡X[s1]")]) ≈ 1.97259369534545#note - digits after 1.9726 added from MPSGE.jl results bc GAMS not showing
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("P[g1]‡X[s2]")]) ≈ 2.03066185804338#note - digits after 2.0307 added from MPSGE.jl results bc GAMS not showing
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("P[g2]‡X[s2]")]) ≈ 9.96905522562005#note - digits after 9.9691 added from MPSGE.jl results bc GAMS not showing
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("P[g1]†X[s1]")]) ≈ 3.98197686299145#note - digits after 3.982 added from MPSGE.jl results bc GAMS not showing
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("P[g2]†X[s1]")]) ≈ 2.02778707517633#note - digits after 2.0278 added from MPSGE.jl results bc GAMS not showing
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PF[l]†X[s1]")]) ≈ 1.03260012164254# not quite…1.03260003
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PF[k]†X[s1]")]) ≈ 0.959241930707878# not quite…0.9592419
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("P[g1]†X[s2]")]) ≈ 1.96980111885675#note - digits after 1.9698 added from MPSGE.jl results bc GAMS not showing
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("P[g2]†X[s2]")]) ≈ 6.01862449771423#note - digits after 6.0186 added from MPSGE.jl results bc GAMS not showing
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PF[l]†X[s2]")]) ≈ 3.06483479678299# not quite…3.06483456
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PF[k]†X[s2]")]) ≈ 0.949034056889784# not quite…0.94903402
    @test MPSGE.Complementarity.result_value(m._jump_model[:Y]) ≈ 6.55295034252603# not quite…6.55295028
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("P[g1]ρY")]) ≈ 2.10582458311357# not quite…2.10582449
    @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("P[g2]ρY")]) ≈ 4.28949139501026# not quite…4.28949135                                                     
end
