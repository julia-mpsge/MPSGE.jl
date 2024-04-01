@testset "123 model" begin
    using XLSX, MPSGE_MP.JuMP.Containers
    import JuMP

    # A replication of the 123 from https://www.gams.com/34/docs/UG_MPSGE_Intro.html#UG_MPSGE_Intro_Appendix_mge123 Static 123 Model Ala Devarjan

  # table mcm(mcmrow,mcmcol)  Microconsistent matrix
    mcm = DenseAxisArray(Union{Float64,Missing}[
        106.386  -144.701 38.315  missing  missing;
        218.308  -218.308 missing missing  missing;
        missing  -32.027  32.027  missing  missing;
        missing  -18.617  18.617  missing  missing;
        -1.136   missing  1.136   missing  missing;
        -12.837  missing  12.837  missing  missing;
        -3.539   missing  3.539   missing  missing;
        -143.862 missing  missing 143.862  missing;
        -163.320 missing  missing 163.320  missing;
        missing  413.653  -35.583 -291.694 -86.376],
    [:PFX, :PD, :TA, :TM, :TX, :TK, :TL, :RK, :PL, :PA], [:S, :D, :GOVT, :HH, :INVEST])
   
   
   # parameter   px0  Reference price of exports
   d0  =  mcm[:PD,:S] # d0   Reference domestic supply
   x0  =  mcm[:PFX,:S] # x0   Reference exports
   kd0 = -mcm[:RK,:S] # kd0  Reference net capital earnings
   ly0 = -mcm[:PL,:S] # ly0  Reference net labor earnings  
   tk  =  mcm[:TK,:S]/mcm[:RK,:S] # tk   Capital tax rate
   tl  =  mcm[:TL,:S]/mcm[:PL,:S] # tl   Labor tax rate
   ta  = -mcm[:TA,:D]/mcm[:PA,:D] # ta   Excise and sales tax rate
   tx  = -mcm[:TX,:S]/mcm[:PFX,:S] # tx   Tax on exports
   a0  =  mcm[:PA,:D] # a0   Aggregate supply (gross of tax)
   g0  = -mcm[:PA,:GOVT] # g0   Government demand,
   m0  = -mcm[:PFX,:D] # m0   Imports
   l0  =  0.75*ly0 # l0   Leisure demand
   i0  =  -mcm[:PA,:INVEST] # i0   Aggregate investment
   c0  =  a0 - i0 - g0 # c0   Household consumption
   
   pm0 =  1 + mcm[:TM,:D]/mcm[:PFX,:D] # pm0  Reference price of imports
   px0 = 1 - tx;
   rr0 = 1 + tk # rr0  Reference price of capital
   pl0 = 1 + tl # pl0  Reference wage
   bopdef = mcm[:PFX,:GOVT] # bopdef  Balance of payments deficit
   dtax = g0 - bopdef - mcm[:TM,:D]/mcm[:PFX,:D]*m0 - ta*a0 - tl*ly0 - tk*kd0 - tx*x0 # dtax    Direct tax net transfers
   
   
   m = MPSGEModel()


   # Parameter values describing base year equilibrium:
   @parameters(m, begin
       pwm, 1.0,  (description = "World price of imports",)
       pwx, 1.0,  (description = "World price of exports",)
       etadx, 4.0,  (description = "Elasticity of transformation (D versus X)",)
       sigmadm, 4.0,  (description = "Elasticity of substitution (D versus M)",)
       esubkl, 1.0,  (description = "Elasticity of substitution (K versus L)",)
       sigma, 0.4,  (description = "Elasticity of substitution (C versus LS)",)
       TM, mcm[:TM,:D]/mcm[:PFX,:D], (description = "Import tariff rate Parameter version of tm in order to be able to update for counterfactuals",)
   end)
   
   @sectors(m, begin
       Y
       A
       M
       X
   end)
   
   @commodities(m, begin
       PD, (description = "Domestic price index",)
       PX, (description = "Export price index",)
       PM, (description = "Import price index",)
       PA, (description = "Armington price index",)
       PL, (description = "Wage rate index",)
       RK, (description = "Rental price index",)
       PFX, (description = "Foreign exchange",)
   end)
   
   @consumers(m, begin
       HH
       GOVT
   end)
   
   @auxiliaries(m, begin
       TAU_LS, (description = "Lumpsum Replacement tax",)
       TAU_TL, (description = "Labor tax replacement",)
       UR, (description = "Unemployment rate",)
   end)
   
   @production(m, Y, [t = etadx, s = esubkl], begin   
        @output(PD, d0, t)
        @output(PX, x0, t, taxes=[Tax(GOVT, tx)], reference_price=px0)
        @input(RK, kd0, s, taxes=[Tax(GOVT, tk)], reference_price=rr0)
        @input(PL, ly0, s, taxes=[Tax(GOVT, tl+TAU_TL)], reference_price=pl0)

    end)
   
   @production(m, A, [t = 0, s = sigmadm], begin
        @output(PA, a0, t, taxes=[Tax(GOVT, ta)])
        @input(PD, d0, s)
        @input(PM, m0, s, taxes=[Tax(GOVT, TM)], reference_price=pm0)
    end)
   
   @production(m, M, [t = 0, s = 1], begin
           @output(PM,m0, t)
           @input(PFX, pwm*m0, s)
    end)
   
   @production(m, X, [t = 0, s = 1], begin
        @output(PFX, pwx*x0, t)
        @input(PX, x0, s)
    end)
   
   
   @aux_constraint(m, UR, PL - PA)
   @aux_constraint(m, TAU_LS, GOVT - PA*g0)
   @aux_constraint(m, TAU_TL, GOVT - PA*g0)
   
   
   @demand(m, GOVT, begin
       @final_demand(PA, 35.583) #should this be a known number?
    end,begin
        @endowment(PA, g0*TAU_LS + dtax)
        @endowment(PFX, bopdef)
    end,
       elasticity = 0
   )
   
   
   @demand(m, HH, begin
        @final_demand(PA, c0)
        @final_demand(PL, l0)
    end,begin   
        @endowment(PA, -g0*TAU_LS - dtax - i0)
        @endowment(RK, kd0)
        @endowment(PL, (ly0+l0) - (ly0+l0)*UR)
    end,
       elasticity = sigma
   )
   
    build!(m)

    fix(HH, 414.184)
    solve!(m, cumulative_iteration_limit=0.)

    gams_results = XLSX.readxlsx(joinpath(@__DIR__, "MPSGEresults.xlsx"))
    a_table = gams_results["The123"][:]  # Generated from JPMGE_MPSGE
    The123 = DenseAxisArray(a_table[2:end,2:end],string.(a_table[2:end,1]),a_table[1,2:end])

    # Benchmark
    @test value(PFX) ≈ The123["PFX","Benchmark"]#  1
    @test value(PD) ≈ The123["PD","Benchmark"]#  1
    @test value(RK) ≈ The123["RK","Benchmark"]#  1
    @test value(PL) ≈ The123["PL","Benchmark"]#  1
    @test value(PA) ≈ The123["PA","Benchmark"]#  1
    @test value(GOVT) ≈ The123["GOVT","Benchmark"]#  35.5830001
    @test value(HH) ≈ The123["HH","Benchmark"]#  414.184
    @test value(PX) ≈ The123["PX","Benchmark"]#  1
    @test value(Y) ≈ The123["Y","Benchmark"]#  1
    @test value(A) ≈ The123["A","Benchmark"]#  1
    @test value(M) ≈ The123["M","Benchmark"]#  1
    @test value(X) ≈ The123["X","Benchmark"]#  1
    @test value(PM) ≈ The123["PM","Benchmark"]#  1
    @test value(compensated_demand(Y, PD, :t)) ≈ -The123["YD","Benchmark"]#  218.3079999
    @test value(compensated_demand(Y, PX, :t)) ≈ -The123["YX","Benchmark"]#  106.3860001
    @test value(compensated_demand(Y, RK, :s)) ≈ The123["KD","Benchmark"]#  143.8619999
    @test value(compensated_demand(Y, PL, :s)) ≈ The123["LY","Benchmark"]#  163.3200001
    @test value(compensated_demand(A, PD, :s)) ≈ The123["DA","Benchmark"]#  218.3079987
    @test value(compensated_demand(A, PM, :s)) ≈ The123["MA","Benchmark"]#  144.7010012
    @test value(demand(HH, PA)) ≈ The123["CAHH","Benchmark"]#  291.694
    @test value(demand(GOVT, PA)) ≈ The123["CAG","Benchmark"]#  35.5830001
    @test value(demand(HH, PL)) ≈ The123["LD","Benchmark"]#  122.49
    @test value(compensated_demand(A, PA, :t)) ≈ -The123["PAA","Benchmark"]#  413.653
    @test value(compensated_demand(M, PM, :t)) ≈ -The123["PMM","Benchmark"]#  144.701
    @test value(compensated_demand(X, PFX, :t)) ≈ -The123["PFXX","Benchmark"]#  106.386
    @test value(compensated_demand(M, PFX, :s)) ≈ The123["PFXM","Benchmark"]#  144.701
    @test value(compensated_demand(X, PX, :s)) ≈ The123["PXX","Benchmark"]#  106.386
    @test value(TAU_LS) ≈ 0 # The123["TAU_LS","Benchmark"]#  0
    @test value(TAU_TL) ≈ 0 # The123["TAU_TL","Benchmark"]#  0
    @test value(UR) ≈ 0 # The123["UR","Benchmark"]#  0

    # *   Tariff reform:
    set_value!(TM, 0)
    fix(UR, 0)
    #set_value(TAU_TL, 0.)
    fix(TAU_TL, 0)


    solve!(m)
    # Lump Sum Flexible
    @test value(PFX) ≈ The123["PFX","Lump Sum F"]#  1.0755262
    @test value(PD) ≈ The123["PD","Lump Sum F"]#  1.0070022
    @test value(RK) ≈ The123["RK","Lump Sum F"]#  1.0347436
    @test value(PL) ≈ The123["PL","Lump Sum F"]#  1.0281437
    @test value(PA) ≈ The123["PA","Lump Sum F"]#  0.9823864
    @test value(GOVT) ≈ The123["GOVT","Lump Sum F"]#  34.9562541
    @test value(HH) ≈ The123["HH","Lump Sum F"]#  414.184
    @test value(PX) ≈ The123["PX","Lump Sum F"]#  1.0755262
    @test value(Y) ≈ The123["Y","Lump Sum F"]#  1.0033053
    @test value(A) ≈ The123["A","Lump Sum F"]#  1.0068125
    @test value(M) ≈ The123["M","Lump Sum F"]#  1.1372188
    @test value(X) ≈ The123["X","Lump Sum F"]#  1.1866383
    @test value(PM) ≈ The123["PM","Lump Sum F"]#  1.0755262
    @test value(compensated_demand(Y, PD, :t)) ≈ -The123["YD","Lump Sum F"]#  198.4233184
    @test value(compensated_demand(Y, PX, :t)) ≈ -The123["YX","Lump Sum F"]#  125.8258116
    @test value(compensated_demand(Y, RK, :s)) ≈ The123["KD","Lump Sum F"]#  143.3880636
    @test value(compensated_demand(Y, PL, :s)) ≈ The123["LY","Lump Sum F"]#  163.8268966
    @test value(compensated_demand(A, PD, :s)) ≈ The123["DA","Lump Sum F"]#  197.7321199
    @test value(compensated_demand(A, PM, :s)) ≈ The123["MA","Lump Sum F"]#  163.4432502
    @test value(demand(HH, PA)) ≈ The123["CAHH","Lump Sum F"]#  294.5119929
    @test value(demand(GOVT, PA)) ≈ The123["CAG","Lump Sum F"]#  35.583
    @test value(demand(HH, PL)) ≈ The123["LD","Lump Sum F"]#  121.4416109
    @test value(compensated_demand(A, PA, :t)) ≈ -The123["PAA","Lump Sum F"]#  413.653
    @test value(compensated_demand(M, PM, :t)) ≈ -The123["PMM","Lump Sum F"]#  144.701
    @test value(compensated_demand(X, PFX, :t)) ≈ -The123["PFXX","Lump Sum F"]#  106.386
    @test value(compensated_demand(M, PFX, :s)) ≈ The123["PFXM","Lump Sum F"]#  144.701
    @test value(compensated_demand(X, PX, :s)) ≈ The123["PXX","Lump Sum F"]#  106.386
    @test value(TAU_LS) ≈ The123["TAU_LS","Lump Sum F"]#  0.3809004
    @test value(TAU_TL) ≈ 0 # The123["TAU_TL","Lump Sum F"]#  0
    @test value(UR) ≈ 0 # The123["UR","Lump Sum F"]#  0

    fix(UR, 0)
    #unfix(TAU_LS)
    #set_value(TAU_TL, 0.)
    fix(TAU_TL, 0)
    
    fix(HH, 427.4988518)
    
    solve!(m)
    # Lump Sum Rigid Wage
    @test value(PFX) ≈ The123["PFX","Lump Sum R"]#  1.1101013
    @test value(PD) ≈ The123["PD","Lump Sum R"]#  1.0393745
    @test value(RK) ≈ The123["RK","Lump Sum R"]#  1.0680077
    @test value(PL) ≈ The123["PL","Lump Sum R"]#  1.0611957
    @test value(PA) ≈ The123["PA","Lump Sum R"]#  1.0139673
    @test value(GOVT) ≈ The123["GOVT","Lump Sum R"]#  36.0799995
    @test value(HH) ≈ The123["HH","Lump Sum R"]#  427.4988518
    @test value(PX) ≈ The123["PX","Lump Sum R"]#  1.1101013
    @test value(Y) ≈ The123["Y","Lump Sum R"]#  1.0033053
    @test value(A) ≈ The123["A","Lump Sum R"]#  1.0068125
    @test value(M) ≈ The123["M","Lump Sum R"]#  1.1372188
    @test value(X) ≈ The123["X","Lump Sum R"]#  1.1866383
    @test value(PM) ≈ The123["PM","Lump Sum R"]#  1.1101013
    @test value(compensated_demand(Y, PD, :t)) ≈ -The123["YD","Lump Sum R"]#  198.4233184
    @test value(compensated_demand(Y, PX, :t)) ≈ -The123["YX","Lump Sum R"]#  125.8258116
    @test value(compensated_demand(Y, RK, :s)) ≈ The123["KD","Lump Sum R"]#  143.3880635
    @test value(compensated_demand(Y, PL, :s)) ≈ The123["LY","Lump Sum R"]#  163.8268967
    @test value(compensated_demand(A, PD, :s)) ≈ The123["DA","Lump Sum R"]#  197.7321199
    @test value(compensated_demand(A, PM, :s)) ≈ The123["MA","Lump Sum R"]#  163.4432501
    @test value(demand(HH, PA)) ≈ The123["CAHH","Lump Sum R"]#  294.5119929
    @test value(demand(GOVT, PA)) ≈ The123["CAG","Lump Sum R"]#  35.583
    @test value(demand(HH, PL)) ≈ The123["LD","Lump Sum R"]#  121.441611
    @test value(compensated_demand(A, PA, :t)) ≈ -The123["PAA","Lump Sum R"]#  413.653
    @test value(compensated_demand(M, PM, :t)) ≈ -The123["PMM","Lump Sum R"]#  144.701
    @test value(compensated_demand(X, PFX, :t)) ≈ -The123["PFXX","Lump Sum R"]#  106.386
    @test value(compensated_demand(M, PFX, :s)) ≈ The123["PFXM","Lump Sum R"]#  144.701
    @test value(compensated_demand(X, PX, :s)) ≈ The123["PXX","Lump Sum R"]#  106.386
    @test value(TAU_LS) ≈ The123["TAU_LS","Lump Sum R"]#  0.3809004
    @test value(TAU_TL) ≈ 0 # The123["TAU_TL","Lump Sum R"]#  0
    @test value(UR) ≈ 0 # The123["UR","Lump Sum R"]#  0

    fix(UR, 0)
    unfix(TAU_TL)
    fix(TAU_LS, 0)
    
    solve!(m)
    # Wage Tax Flexible
    @test value(PFX) ≈ The123["PFX","Wage Tax F"]#  1.1369323
    @test value(PD) ≈ The123["PD","Wage Tax F"]#  1.0647664
    @test value(RK) ≈ The123["RK","Wage Tax F"]#  1.0851742
    @test value(PL) ≈ The123["PL","Wage Tax F"]#  1.0058066
    @test value(PA) ≈ The123["PA","Wage Tax F"]#  1.0386148
    @test value(GOVT) ≈ The123["GOVT","Wage Tax F"]#  36.9570315
    @test value(HH) ≈ The123["HH","Wage Tax F"]#  427.4988518
    @test value(PX) ≈ The123["PX","Wage Tax F"]#  1.1369323
    @test value(Y) ≈ The123["Y","Wage Tax F"]#  0.9952223
    @test value(A) ≈ The123["A","Wage Tax F"]#  0.9995844
    @test value(M) ≈ The123["M","Wage Tax F"]#  1.1296638
    @test value(X) ≈ The123["X","Wage Tax F"]#  1.1763623
    @test value(PM) ≈ The123["PM","Wage Tax F"]#  1.1369323
    @test value(compensated_demand(Y, PD, :t)) ≈ -The123["YD","Wage Tax F"]#  198.5041828
    @test value(compensated_demand(Y, PX, :t)) ≈ -The123["YX","Wage Tax F"]#  125.7492723
    @test value(compensated_demand(Y, RK, :s)) ≈ The123["KD","Wage Tax F"]#  144.5526315
    @test value(compensated_demand(Y, PL, :s)) ≈ The123["LY","Wage Tax F"]#  162.5871086
    @test value(compensated_demand(A, PD, :s)) ≈ The123["DA","Wage Tax F"]#  197.6379322
    @test value(compensated_demand(A, PM, :s)) ≈ The123["MA","Wage Tax F"]#  163.5314481
    @test value(demand(HH, PA)) ≈ The123["CAHH","Wage Tax F"]#  291.5220694
    @test value(demand(GOVT, PA)) ≈ The123["CAG","Wage Tax F"]#  35.583
    @test value(demand(HH, PL)) ≈ The123["LD","Wage Tax F"]#  123.9996865
    @test value(compensated_demand(A, PA, :t)) ≈ -The123["PAA","Wage Tax F"]#  413.653
    @test value(compensated_demand(M, PM, :t)) ≈ -The123["PMM","Wage Tax F"]#  144.701
    @test value(compensated_demand(X, PFX, :t)) ≈ -The123["PFXX","Wage Tax F"]#  106.386
    @test value(compensated_demand(M, PFX, :s)) ≈ The123["PFXM","Wage Tax F"]#  144.701
    @test value(compensated_demand(X, PX, :s)) ≈ The123["PXX","Wage Tax F"]#  106.386
    @test value(TAU_LS) ≈ 0 # The123["TAU_LS","Wage Tax F"]#  0
    @test value(TAU_TL) ≈ The123["TAU_TL","Wage Tax F"]#  0.0909036
    @test value(UR) ≈ 0 # The123["UR","Wage Tax F"]#  0

    unfix(UR)
    #unfix(TAU_TL)
    fix(TAU_LS, 0)
    fix(HH, 441.2417391)

    solve!(m)
    # Wage Tax Rigid Wage
    @test value(PFX) ≈ The123["PFX","Wage Tax R"]#  1.2591699
    @test value(PD) ≈ The123["PD","Wage Tax R"]#  1.1815615
    @test value(RK) ≈ The123["RK","Wage Tax R"]#  1.1324982
    @test value(PL) ≈ The123["PL","Wage Tax R"]#  1.1514792
    @test value(PA) ≈ The123["PA","Wage Tax R"]#  1.1514792
    @test value(GOVT) ≈ The123["GOVT","Wage Tax R"]#  40.9730843
    @test value(HH) ≈ The123["HH","Wage Tax R"]#  441.2417391
    @test value(PX) ≈ The123["PX","Wage Tax R"]#  1.2591699
    @test value(Y) ≈ The123["Y","Wage Tax R"]#  0.9366921
    @test value(A) ≈ The123["A","Wage Tax R"]#  0.9472409
    @test value(M) ≈ The123["M","Wage Tax R"]#  1.074973
    @test value(X) ≈ The123["X","Wage Tax R"]#  1.1019746
    @test value(PM) ≈ The123["PM","Wage Tax R"]#  1.2591699
    @test value(compensated_demand(Y, PD, :t)) ≈ -The123["YD","Wage Tax R"]#  199.1279949
    @test value(compensated_demand(Y, PX, :t)) ≈ -The123["YX","Wage Tax R"]#  125.158171
    @test value(compensated_demand(Y, RK, :s)) ≈ The123["KD","Wage Tax R"]#  153.5851484
    @test value(compensated_demand(Y, PL, :s)) ≈ The123["LY","Wage Tax R"]#  153.5909767
    @test value(compensated_demand(A, PD, :s)) ≈ The123["DA","Wage Tax R"]#  196.910445
    @test value(compensated_demand(A, PM, :s)) ≈ The123["MA","Wage Tax R"]#  164.2134275
    @test value(demand(HH, PA)) ≈ The123["CAHH","Wage Tax R"]#  269.8700375
    @test value(demand(GOVT, PA)) ≈ The123["CAG","Wage Tax R"]#  35.583
    @test value(demand(HH, PL)) ≈ The123["LD","Wage Tax R"]#  113.3255429
    @test value(compensated_demand(A, PA, :t)) ≈ -The123["PAA","Wage Tax R"]#  413.653
    @test value(compensated_demand(M, PM, :t)) ≈ -The123["PMM","Wage Tax R"]#  144.701
    @test value(compensated_demand(X, PFX, :t)) ≈ -The123["PFXX","Wage Tax R"]#  106.386
    @test value(compensated_demand(M, PFX, :s)) ≈ The123["PFXM","Wage Tax R"]#  144.701
    @test value(compensated_demand(X, PX, :s)) ≈ The123["PXX","Wage Tax R"]#  106.386
    @test value(TAU_LS) ≈ 0 # The123["TAU_LS","Wage Tax R"]#  0
    @test value(TAU_TL) ≈ The123["TAU_TL","Wage Tax R"]#  0.1190231
    @test value(UR) ≈ The123["UR","Wage Tax R"] atol=1e-8#  0.100126

end