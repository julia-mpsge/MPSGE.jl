@testitem "123 model" begin
using XLSX, MPSGE.JuMP.Containers

# A replication of the 123 from https://www.gams.com/34/docs/UG_MPSGE_Intro.html#UG_MPSGE_Intro_Appendix_mge123 Static 123 Model Ala Devarjan

m = Model()
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

# Parameter values describing base year equilibrium:
pwm     = add!(m, Parameter(:pwm,     value=1.0)) # World price of imports
pwx     = add!(m, Parameter(:pwx,     value=1.0)) # World price of exports
etadx   = add!(m, Parameter(:etadx,   value=4.0)) # Elasticity of transformation (D versus X)
sigmadm = add!(m, Parameter(:sigmadm, value=4.0)) # Elasticity of substitution (D versus M)
esubkl  = add!(m, Parameter(:esubkl,  value=1.0)) # Elasticity of substitution (K versus L)
sigma   = add!(m, Parameter(:sigma,   value=0.4)) # Elasticity of substitution (C versus LS)
    
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
TM = add!(m, Parameter(:TM, value=mcm[:TM,:D]/mcm[:PFX,:D])) # Import tariff rate Parameter version of tm in order to be able to update for counterfactuals
pm0 =  1 + get_value(TM) # pm0  Reference price of imports
px0 = 1 - tx;
rr0 = 1 + tk # rr0  Reference price of capital
pl0 = 1 + tl # pl0  Reference wage
bopdef = mcm[:PFX,:GOVT] # bopdef  Balance of payments deficit
dtax = g0 - bopdef - get_value(TM)*m0 - ta*a0 - tl*ly0 - tk*kd0 - tx*x0 # dtax    Direct tax net transfers

Y = add!(m, Sector(:Y))
A = add!(m, Sector(:A))
M = add!(m, Sector(:M))
X = add!(m, Sector(:X))

PD = add!(m, Commodity(:PD)) # Domestic price index
PX = add!(m, Commodity(:PX)) # Export price index
PM = add!(m, Commodity(:PM)) # Import price index
PA = add!(m, Commodity(:PA)) # Armington price index
PL = add!(m, Commodity(:PL)) # Wage rate index
RK = add!(m, Commodity(:RK)) # Rental price index
PFX = add!(m, Commodity(:PFX)) # Foreign exchange

HH = add!(m, Consumer(:HH, benchmark=c0+l0))
GOVT = add!(m, Consumer(:GOVT, benchmark=35.583))

TAU_LS = add!(m,Aux(:TAU_LS, benchmark=0.)) # Lumpsum Replacement tax
TAU_TL = add!(m,Aux(:TAU_TL, benchmark=0.)) # Labor tax replacement
UR = add!(m,Aux(:UR, benchmark=0.)) # Unemployment rate

add!(m, Production(Y, :($etadx*1.0), :($esubkl*1.0),
 [Output(PD, d0), Output(PX, x0, [Tax(tx,GOVT)], px0)],
 [Input(RK, kd0, [Tax(tk, GOVT)], rr0), Input(PL, ly0, [Tax(:($tl+$TAU_TL),GOVT)], pl0)] ))
# add!(m, Production(Y, :($etadx*1.0), :($esubkl*1.0), [Output(PD, d0), Output(PX, x0, [Tax(tx,GOVT)], px0)], [Input(RK, kd0, [Tax(tk, GOVT)], rr0), Input(PL, ly0, [Tax(tl,GOVT), Tax(:($TAU_TL*1),GOVT)], pl0)] ))

add!(m, Production(A, 0., :($sigmadm*1.0), [Output(PA, a0, [Tax(ta,GOVT)])], [Input(PD, d0), Input(PM, m0, [Tax(:($TM*1.),GOVT)], pm0)] ))
add!(m, Production(M, 0., 1.0, [Output(PM, m0)], [Input(PFX, :($pwm*$m0))] ))
add!(m, Production(X, 0., 1.0, [Output(PFX, :($pwx*$x0))], [Input(PX, x0)] ))

add!(m, DemandFunction(GOVT, 0.,
 [Demand(PA , 35.583)],
 [Endowment(PA, :($g0*$TAU_LS)), Endowment(PA, dtax), Endowment(PFX, bopdef)]))

add!(m, AuxConstraint(UR, :($PL==$PA)))
add!(m, AuxConstraint(TAU_LS, :($GOVT==$PA*$g0)))
add!(m, AuxConstraint(TAU_TL, :($GOVT==$PA*$g0)))

add!(m, DemandFunction(HH, :($sigma*1.0),
 [Demand(PA, c0), Demand(PL,l0)], 
 [Endowment(PA, :(-$g0*$TAU_LS)), Endowment(PA, -dtax), Endowment(RK, kd0), Endowment(PA, -i0), Endowment(PL, (ly0+l0)), Endowment(PL, :(-($ly0+$l0)*$UR))]))

set_value(HH, 414.184)
set_fixed!(HH, true)
solve!(m, cumulative_iteration_limit=0.)

gams_results = XLSX.readxlsx(joinpath(@__DIR__, "MPSGEresults.xlsx"))
a_table = gams_results["The123"][:]  # Generated from JPMGE_MPSGE
The123 = DenseAxisArray(a_table[2:end,2:end],string.(a_table[2:end,1]),a_table[1,2:end])

# Benchmark
@test MPSGE.Complementarity.result_value(m._jump_model[:PFX]) ≈ The123["PFX","Benchmark"]#  1
@test MPSGE.Complementarity.result_value(m._jump_model[:PD]) ≈ The123["PD","Benchmark"]#  1
@test MPSGE.Complementarity.result_value(m._jump_model[:RK]) ≈ The123["RK","Benchmark"]#  1
@test MPSGE.Complementarity.result_value(m._jump_model[:PL]) ≈ The123["PL","Benchmark"]#  1
@test MPSGE.Complementarity.result_value(m._jump_model[:PA]) ≈ The123["PA","Benchmark"]#  1
@test MPSGE.Complementarity.result_value(m._jump_model[:GOVT]) ≈ The123["GOVT","Benchmark"]#  35.5830001
@test MPSGE.Complementarity.result_value(m._jump_model[:HH]) ≈ The123["HH","Benchmark"]#  414.184
@test MPSGE.Complementarity.result_value(m._jump_model[:PX]) ≈ The123["PX","Benchmark"]#  1
@test MPSGE.Complementarity.result_value(m._jump_model[:Y]) ≈ The123["Y","Benchmark"]#  1
@test MPSGE.Complementarity.result_value(m._jump_model[:A]) ≈ The123["A","Benchmark"]#  1
@test MPSGE.Complementarity.result_value(m._jump_model[:M]) ≈ The123["M","Benchmark"]#  1
@test MPSGE.Complementarity.result_value(m._jump_model[:X]) ≈ The123["X","Benchmark"]#  1
@test MPSGE.Complementarity.result_value(m._jump_model[:PM]) ≈ The123["PM","Benchmark"]#  1
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PD‡Y")]) ≈ The123["YD","Benchmark"]#  218.3079999
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX‡Y")]) ≈ The123["YX","Benchmark"]#  106.3860001
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("RK†Y")]) ≈ The123["KD","Benchmark"]#  143.8619999
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PL†Y")]) ≈ The123["LY","Benchmark"]#  163.3200001
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PD†A")]) ≈ The123["DA","Benchmark"]#  218.3079987
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PM†A")]) ≈ The123["MA","Benchmark"]#  144.7010012
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PAρHH")]) ≈ The123["CAHH","Benchmark"]#  291.694
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PAρGOVT")]) ≈ The123["CAG","Benchmark"]#  35.5830001
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PLρHH")]) ≈ The123["LD","Benchmark"]#  122.49
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PA‡A")]) ≈ The123["PAA","Benchmark"]#  413.653
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PM‡M")]) ≈ The123["PMM","Benchmark"]#  144.701
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PFX‡X")]) ≈ The123["PFXX","Benchmark"]#  106.386
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PFX†M")]) ≈ The123["PFXM","Benchmark"]#  144.701
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX†X")]) ≈ The123["PXX","Benchmark"]#  106.386
@test MPSGE.Complementarity.result_value(m._jump_model[:TAU_LS]) ≈ 0 # The123["TAU_LS","Benchmark"]#  0
@test MPSGE.Complementarity.result_value(m._jump_model[:TAU_TL]) ≈ 0 # The123["TAU_TL","Benchmark"]#  0
@test MPSGE.Complementarity.result_value(m._jump_model[:UR]) ≈ 0 # The123["UR","Benchmark"]#  0

# *   Tariff reform:
set_value(TM, 0.)
set_value(UR, 0.)
set_fixed!(UR, true)
set_value(TAU_TL, 0.)
set_fixed!(TAU_TL, true)
# Just testing for bunctionality, not effecting the results after the value reset
set_lower_bound(TAU_LS, 15.0)
set_lower_bound(TAU_LS, 0.0)
set_upper_bound(TAU_LS, 0.)
set_upper_bound(TAU_LS, 10e100)
solve!(m)
# Lump Sum Flexible
@test MPSGE.Complementarity.result_value(m._jump_model[:PFX]) ≈ The123["PFX","Lump Sum F"]#  1.0755262
@test MPSGE.Complementarity.result_value(m._jump_model[:PD]) ≈ The123["PD","Lump Sum F"]#  1.0070022
@test MPSGE.Complementarity.result_value(m._jump_model[:RK]) ≈ The123["RK","Lump Sum F"]#  1.0347436
@test MPSGE.Complementarity.result_value(m._jump_model[:PL]) ≈ The123["PL","Lump Sum F"]#  1.0281437
@test MPSGE.Complementarity.result_value(m._jump_model[:PA]) ≈ The123["PA","Lump Sum F"]#  0.9823864
@test MPSGE.Complementarity.result_value(m._jump_model[:GOVT]) ≈ The123["GOVT","Lump Sum F"]#  34.9562541
@test MPSGE.Complementarity.result_value(m._jump_model[:HH]) ≈ The123["HH","Lump Sum F"]#  414.184
@test MPSGE.Complementarity.result_value(m._jump_model[:PX]) ≈ The123["PX","Lump Sum F"]#  1.0755262
@test MPSGE.Complementarity.result_value(m._jump_model[:Y]) ≈ The123["Y","Lump Sum F"]#  1.0033053
@test MPSGE.Complementarity.result_value(m._jump_model[:A]) ≈ The123["A","Lump Sum F"]#  1.0068125
@test MPSGE.Complementarity.result_value(m._jump_model[:M]) ≈ The123["M","Lump Sum F"]#  1.1372188
@test MPSGE.Complementarity.result_value(m._jump_model[:X]) ≈ The123["X","Lump Sum F"]#  1.1866383
@test MPSGE.Complementarity.result_value(m._jump_model[:PM]) ≈ The123["PM","Lump Sum F"]#  1.0755262
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PD‡Y")]) ≈ The123["YD","Lump Sum F"]#  198.4233184
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX‡Y")]) ≈ The123["YX","Lump Sum F"]#  125.8258116
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("RK†Y")]) ≈ The123["KD","Lump Sum F"]#  143.3880636
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PL†Y")]) ≈ The123["LY","Lump Sum F"]#  163.8268966
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PD†A")]) ≈ The123["DA","Lump Sum F"]#  197.7321199
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PM†A")]) ≈ The123["MA","Lump Sum F"]#  163.4432502
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PAρHH")]) ≈ The123["CAHH","Lump Sum F"]#  294.5119929
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PAρGOVT")]) ≈ The123["CAG","Lump Sum F"]#  35.583
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PLρHH")]) ≈ The123["LD","Lump Sum F"]#  121.4416109
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PA‡A")]) ≈ The123["PAA","Lump Sum F"]#  413.653
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PM‡M")]) ≈ The123["PMM","Lump Sum F"]#  144.701
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PFX‡X")]) ≈ The123["PFXX","Lump Sum F"]#  106.386
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PFX†M")]) ≈ The123["PFXM","Lump Sum F"]#  144.701
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX†X")]) ≈ The123["PXX","Lump Sum F"]#  106.386
@test MPSGE.Complementarity.result_value(m._jump_model[:TAU_LS]) ≈ The123["TAU_LS","Lump Sum F"]#  0.3809004
@test MPSGE.Complementarity.result_value(m._jump_model[:TAU_TL]) ≈ 0 # The123["TAU_TL","Lump Sum F"]#  0
@test MPSGE.Complementarity.result_value(m._jump_model[:UR]) ≈ 0 # The123["UR","Lump Sum F"]#  0

set_fixed!(UR, false)
set_fixed!(TAU_LS, false)
set_value(TAU_TL, 0.)
set_fixed!(TAU_TL, true)
set_value(HH, 427.4988518)
solve!(m)
# Lump Sum Rigid Wage
@test MPSGE.Complementarity.result_value(m._jump_model[:PFX]) ≈ The123["PFX","Lump Sum R"]#  1.1101013
@test MPSGE.Complementarity.result_value(m._jump_model[:PD]) ≈ The123["PD","Lump Sum R"]#  1.0393745
@test MPSGE.Complementarity.result_value(m._jump_model[:RK]) ≈ The123["RK","Lump Sum R"]#  1.0680077
@test MPSGE.Complementarity.result_value(m._jump_model[:PL]) ≈ The123["PL","Lump Sum R"]#  1.0611957
@test MPSGE.Complementarity.result_value(m._jump_model[:PA]) ≈ The123["PA","Lump Sum R"]#  1.0139673
@test MPSGE.Complementarity.result_value(m._jump_model[:GOVT]) ≈ The123["GOVT","Lump Sum R"]#  36.0799995
@test MPSGE.Complementarity.result_value(m._jump_model[:HH]) ≈ The123["HH","Lump Sum R"]#  427.4988518
@test MPSGE.Complementarity.result_value(m._jump_model[:PX]) ≈ The123["PX","Lump Sum R"]#  1.1101013
@test MPSGE.Complementarity.result_value(m._jump_model[:Y]) ≈ The123["Y","Lump Sum R"]#  1.0033053
@test MPSGE.Complementarity.result_value(m._jump_model[:A]) ≈ The123["A","Lump Sum R"]#  1.0068125
@test MPSGE.Complementarity.result_value(m._jump_model[:M]) ≈ The123["M","Lump Sum R"]#  1.1372188
@test MPSGE.Complementarity.result_value(m._jump_model[:X]) ≈ The123["X","Lump Sum R"]#  1.1866383
@test MPSGE.Complementarity.result_value(m._jump_model[:PM]) ≈ The123["PM","Lump Sum R"]#  1.1101013
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PD‡Y")]) ≈ The123["YD","Lump Sum R"]#  198.4233184
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX‡Y")]) ≈ The123["YX","Lump Sum R"]#  125.8258116
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("RK†Y")]) ≈ The123["KD","Lump Sum R"]#  143.3880635
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PL†Y")]) ≈ The123["LY","Lump Sum R"]#  163.8268967
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PD†A")]) ≈ The123["DA","Lump Sum R"]#  197.7321199
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PM†A")]) ≈ The123["MA","Lump Sum R"]#  163.4432501
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PAρHH")]) ≈ The123["CAHH","Lump Sum R"]#  294.5119929
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PAρGOVT")]) ≈ The123["CAG","Lump Sum R"]#  35.583
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PLρHH")]) ≈ The123["LD","Lump Sum R"]#  121.441611
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PA‡A")]) ≈ The123["PAA","Lump Sum R"]#  413.653
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PM‡M")]) ≈ The123["PMM","Lump Sum R"]#  144.701
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PFX‡X")]) ≈ The123["PFXX","Lump Sum R"]#  106.386
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PFX†M")]) ≈ The123["PFXM","Lump Sum R"]#  144.701
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX†X")]) ≈ The123["PXX","Lump Sum R"]#  106.386
@test MPSGE.Complementarity.result_value(m._jump_model[:TAU_LS]) ≈ The123["TAU_LS","Lump Sum R"]#  0.3809004
@test MPSGE.Complementarity.result_value(m._jump_model[:TAU_TL]) ≈ 0 # The123["TAU_TL","Lump Sum R"]#  0
@test MPSGE.Complementarity.result_value(m._jump_model[:UR]) ≈ 0 # The123["UR","Lump Sum R"]#  0

set_fixed!(UR, true)
set_fixed!(TAU_TL, false)
set_value(TAU_LS, 0.0)
set_fixed!(TAU_LS, true)
solve!(m)
# Wage Tax Flexible
@test MPSGE.Complementarity.result_value(m._jump_model[:PFX]) ≈ The123["PFX","Wage Tax F"]#  1.1369323
@test MPSGE.Complementarity.result_value(m._jump_model[:PD]) ≈ The123["PD","Wage Tax F"]#  1.0647664
@test MPSGE.Complementarity.result_value(m._jump_model[:RK]) ≈ The123["RK","Wage Tax F"]#  1.0851742
@test MPSGE.Complementarity.result_value(m._jump_model[:PL]) ≈ The123["PL","Wage Tax F"]#  1.0058066
@test MPSGE.Complementarity.result_value(m._jump_model[:PA]) ≈ The123["PA","Wage Tax F"]#  1.0386148
@test MPSGE.Complementarity.result_value(m._jump_model[:GOVT]) ≈ The123["GOVT","Wage Tax F"]#  36.9570315
@test MPSGE.Complementarity.result_value(m._jump_model[:HH]) ≈ The123["HH","Wage Tax F"]#  427.4988518
@test MPSGE.Complementarity.result_value(m._jump_model[:PX]) ≈ The123["PX","Wage Tax F"]#  1.1369323
@test MPSGE.Complementarity.result_value(m._jump_model[:Y]) ≈ The123["Y","Wage Tax F"]#  0.9952223
@test MPSGE.Complementarity.result_value(m._jump_model[:A]) ≈ The123["A","Wage Tax F"]#  0.9995844
@test MPSGE.Complementarity.result_value(m._jump_model[:M]) ≈ The123["M","Wage Tax F"]#  1.1296638
@test MPSGE.Complementarity.result_value(m._jump_model[:X]) ≈ The123["X","Wage Tax F"]#  1.1763623
@test MPSGE.Complementarity.result_value(m._jump_model[:PM]) ≈ The123["PM","Wage Tax F"]#  1.1369323
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PD‡Y")]) ≈ The123["YD","Wage Tax F"]#  198.5041828
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX‡Y")]) ≈ The123["YX","Wage Tax F"]#  125.7492723
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("RK†Y")]) ≈ The123["KD","Wage Tax F"]#  144.5526315
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PL†Y")]) ≈ The123["LY","Wage Tax F"]#  162.5871086
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PD†A")]) ≈ The123["DA","Wage Tax F"]#  197.6379322
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PM†A")]) ≈ The123["MA","Wage Tax F"]#  163.5314481
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PAρHH")]) ≈ The123["CAHH","Wage Tax F"]#  291.5220694
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PAρGOVT")]) ≈ The123["CAG","Wage Tax F"]#  35.583
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PLρHH")]) ≈ The123["LD","Wage Tax F"]#  123.9996865
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PA‡A")]) ≈ The123["PAA","Wage Tax F"]#  413.653
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PM‡M")]) ≈ The123["PMM","Wage Tax F"]#  144.701
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PFX‡X")]) ≈ The123["PFXX","Wage Tax F"]#  106.386
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PFX†M")]) ≈ The123["PFXM","Wage Tax F"]#  144.701
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX†X")]) ≈ The123["PXX","Wage Tax F"]#  106.386
@test MPSGE.Complementarity.result_value(m._jump_model[:TAU_LS]) ≈ 0 # The123["TAU_LS","Wage Tax F"]#  0
@test MPSGE.Complementarity.result_value(m._jump_model[:TAU_TL]) ≈ The123["TAU_TL","Wage Tax F"]#  0.0909036
@test MPSGE.Complementarity.result_value(m._jump_model[:UR]) ≈ 0 # The123["UR","Wage Tax F"]#  0

set_fixed!(UR, false)
set_fixed!(TAU_TL, false)
set_value(TAU_LS, 0.)
set_fixed!(TAU_LS, true)
set_value(HH, 441.2417391)
solve!(m)
# Wage Tax Rigid Wage
@test MPSGE.Complementarity.result_value(m._jump_model[:PFX]) ≈ The123["PFX","Wage Tax R"]#  1.2591699
@test MPSGE.Complementarity.result_value(m._jump_model[:PD]) ≈ The123["PD","Wage Tax R"]#  1.1815615
@test MPSGE.Complementarity.result_value(m._jump_model[:RK]) ≈ The123["RK","Wage Tax R"]#  1.1324982
@test MPSGE.Complementarity.result_value(m._jump_model[:PL]) ≈ The123["PL","Wage Tax R"]#  1.1514792
@test MPSGE.Complementarity.result_value(m._jump_model[:PA]) ≈ The123["PA","Wage Tax R"]#  1.1514792
@test MPSGE.Complementarity.result_value(m._jump_model[:GOVT]) ≈ The123["GOVT","Wage Tax R"]#  40.9730843
@test MPSGE.Complementarity.result_value(m._jump_model[:HH]) ≈ The123["HH","Wage Tax R"]#  441.2417391
@test MPSGE.Complementarity.result_value(m._jump_model[:PX]) ≈ The123["PX","Wage Tax R"]#  1.2591699
@test MPSGE.Complementarity.result_value(m._jump_model[:Y]) ≈ The123["Y","Wage Tax R"]#  0.9366921
@test MPSGE.Complementarity.result_value(m._jump_model[:A]) ≈ The123["A","Wage Tax R"]#  0.9472409
@test MPSGE.Complementarity.result_value(m._jump_model[:M]) ≈ The123["M","Wage Tax R"]#  1.074973
@test MPSGE.Complementarity.result_value(m._jump_model[:X]) ≈ The123["X","Wage Tax R"]#  1.1019746
@test MPSGE.Complementarity.result_value(m._jump_model[:PM]) ≈ The123["PM","Wage Tax R"]#  1.2591699
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PD‡Y")]) ≈ The123["YD","Wage Tax R"]#  199.1279949
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX‡Y")]) ≈ The123["YX","Wage Tax R"]#  125.158171
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("RK†Y")]) ≈ The123["KD","Wage Tax R"]#  153.5851484
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PL†Y")]) ≈ The123["LY","Wage Tax R"]#  153.5909767
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PD†A")]) ≈ The123["DA","Wage Tax R"]#  196.910445
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PM†A")]) ≈ The123["MA","Wage Tax R"]#  164.2134275
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PAρHH")]) ≈ The123["CAHH","Wage Tax R"]#  269.8700375
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PAρGOVT")]) ≈ The123["CAG","Wage Tax R"]#  35.583
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PLρHH")]) ≈ The123["LD","Wage Tax R"]#  113.3255429
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PA‡A")]) ≈ The123["PAA","Wage Tax R"]#  413.653
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PM‡M")]) ≈ The123["PMM","Wage Tax R"]#  144.701
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PFX‡X")]) ≈ The123["PFXX","Wage Tax R"]#  106.386
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PFX†M")]) ≈ The123["PFXM","Wage Tax R"]#  144.701
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX†X")]) ≈ The123["PXX","Wage Tax R"]#  106.386
@test MPSGE.Complementarity.result_value(m._jump_model[:TAU_LS]) ≈ 0 # The123["TAU_LS","Wage Tax R"]#  0
@test MPSGE.Complementarity.result_value(m._jump_model[:TAU_TL]) ≈ The123["TAU_TL","Wage Tax R"]#  0.1190231
@test MPSGE.Complementarity.result_value(m._jump_model[:UR]) ≈ The123["UR","Wage Tax R"] atol=1e-8#  0.100126

end

@testitem "123 nested model" begin
    using XLSX, MPSGE.JuMP.Containers
# A replication of the 123 from https://www.gams.com/34/docs/UG_MPSGE_Intro.html#UG_MPSGE_Intro_Appendix_mgenested Static 123 Model Ala Devarjan

m = Model()
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

# Parameter values describing base year equilibrium:
pwm     = add!(m, Parameter(:pwm,     value=1.0)) # World price of imports
pwx     = add!(m, Parameter(:pwx,     value=1.0)) # World price of exports
etadx   = add!(m, Parameter(:etadx,   value=4.0)) # Elasticity of transformation (D versus X)
sigmadm = add!(m, Parameter(:sigmadm, value=4.0)) # Elasticity of substitution (D versus M)
esubkl  = add!(m, Parameter(:esubkl,  value=1.0)) # Elasticity of substitution (K versus L)
sigma   = add!(m, Parameter(:sigma,   value=0.4)) # Elasticity of substitution (C versus LS)
    
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
TM = add!(m, Parameter(:TM, value=mcm[:TM,:D]/mcm[:PFX,:D])) # Import tariff rate Parameter version of tm in order to be able to update for counterfactuals
pm0 =  1 + get_value(TM) # pm0  Reference price of imports

px0 = 1 - tx;
rr0 = 1 + tk # rr0  Reference price of capital
pl0 = 1 + tl # pl0  Reference wage
bopdef = mcm[:PFX,:GOVT] # bopdef  Balance of payments deficit
dtax = g0 - bopdef - get_value(TM)*m0 - ta*a0 - tl*ly0 - tk*kd0 - tx*x0 # dtax    Direct tax net transfers

# Updated for nesting
m0 = pm0*m0
# Set to use for a0 re-calculation
ta = a0*ta
# Added for nesting
# Impute final demand for domestic and imported goods:
cd0 = c0 * d0/(d0+m0) # Final demand for domestic good
cm0 = c0 * m0/(d0+m0) # Final demand for imports
sigmac = add!(m,Parameter(:sigmac, value=0.5)) # Armington elasticity in final demand
# Updating
# Armington supply net final demand:
a0 = d0+m0-cd0-cm0+ta
#  Recalibrate taxes on A so that tax revenue remains unchanged:
ta = ta/a0

Y = add!(m, Sector(:Y))
A = add!(m, Sector(:A))
M = add!(m, Sector(:M))
X = add!(m, Sector(:X))

# 
PD = add!(m, Commodity(:PD)) # Domestic price index
PX = add!(m, Commodity(:PX)) # Export price index
PM = add!(m, Commodity(:PM)) # Import price index
PA = add!(m, Commodity(:PA)) # Armington price index
PL = add!(m, Commodity(:PL)) # Wage rate index
RK = add!(m, Commodity(:RK)) # Rental price index
PFX = add!(m, Commodity(:PFX)) # Foreign exchange

HH = add!(m, Consumer(:HH, benchmark=c0+l0))
GOVT = add!(m, Consumer(:GOVT, benchmark=35.583))

TAU_LS = add!(m,Aux(:TAU_LS, benchmark=0.)) # Lumpsum Replacement tax
TAU_TL = add!(m,Aux(:TAU_TL, benchmark=0.)) # Labor tax replacement
UR = add!(m,Aux(:UR, benchmark=0.)) # Unemployment rate

add!(m, Production(Y, :($etadx*1.0), :($esubkl*1.0),
 [Output(PD, d0), Output(PX, x0, [Tax(tx,GOVT)], px0)],
 [Input(RK, kd0, [Tax(tk, GOVT)], rr0), Input(PL, ly0, [Tax(:($tl+$TAU_TL),GOVT)], pl0)] ))

add!(m, Production(X, 0., 1.0, [Output(PFX, :($pwx*$x0))], [Input(PX, x0)] ))
add!(m, Production(A, 0., :($sigmadm*1.0), [Output(PA, a0, [Tax(ta,GOVT)])], [Input(PD, (d0-cd0)), Input(PM, (m0-cm0))]))
add!(m, Production(M, 0., 1.0, [Output(PM, m0)], [Input(PFX, :($pwm*$m0/$pm0), [Tax(:($TM*1.), GOVT)])]))

add!(m, DemandFunction(HH, :($sigma*1.0),
 [Demand(PL,l0), Demand(Nest(:C, :($sigmac*1.), (cd0+cm0), [Input(PD, cd0), Input(PM, cm0)]),(cd0+cm0))], #Demand(PA, c0), ], 
 [Endowment(PA, :(-$g0*$TAU_LS)), Endowment(PA, -dtax), Endowment(RK, kd0), Endowment(PA, -i0), Endowment(PL, (ly0+l0)), Endowment(PL, :(-($ly0+$l0)*$UR))]))

 add!(m, DemandFunction(GOVT, 0.,
 [Demand(PA , 35.583)],
 [Endowment(PA, :($g0*$TAU_LS)), Endowment(PA, dtax), Endowment(PFX, bopdef)]))

add!(m, AuxConstraint(UR, :($PL==$PA)))
add!(m, AuxConstraint(TAU_LS, :($GOVT==$PA*$g0)))
add!(m, AuxConstraint(TAU_TL, :($GOVT==$PA*$g0)))

 #Benchmark
# set_value(HH, 414.184)
# set_fixed!(HH, true)
solve!(m, cumulative_iteration_limit=0.)

gams_results = XLSX.readxlsx(joinpath(@__DIR__, "MPSGEresults.xlsx"))
a_table = gams_results["The123Nested"][:]  # Generated from JPMGE_MPSGE
The123Nested = DenseAxisArray(a_table[2:end,2:end],string.(a_table[2:end,1]),a_table[1,2:end])

# Benchmark
@test MPSGE.Complementarity.result_value(m._jump_model[:PFX]) ≈ The123Nested["PFX","Benchmark"]#  1
@test MPSGE.Complementarity.result_value(m._jump_model[:PD]) ≈ The123Nested["PD","Benchmark"]#  1
@test MPSGE.Complementarity.result_value(m._jump_model[:RK]) ≈ The123Nested["RK","Benchmark"]#  1
@test MPSGE.Complementarity.result_value(m._jump_model[:PL]) ≈ The123Nested["PL","Benchmark"]#  1
@test MPSGE.Complementarity.result_value(m._jump_model[:PA]) ≈ The123Nested["PA","Benchmark"]#  1
@test MPSGE.Complementarity.result_value(m._jump_model[:GOVT]) ≈ The123Nested["GOVT","Benchmark"]#  35.583
@test MPSGE.Complementarity.result_value(m._jump_model[:HH]) ≈ The123Nested["HH","Benchmark"]#  414.184
@test MPSGE.Complementarity.result_value(m._jump_model[:PX]) ≈ The123Nested["PX","Benchmark"]#  1
@test MPSGE.Complementarity.result_value(m._jump_model[:Y]) ≈ The123Nested["Y","Benchmark"]#  1
@test MPSGE.Complementarity.result_value(m._jump_model[:A]) ≈ The123Nested["A","Benchmark"]#  1
@test MPSGE.Complementarity.result_value(m._jump_model[:M]) ≈ The123Nested["M","Benchmark"]#  1
@test MPSGE.Complementarity.result_value(m._jump_model[:X]) ≈ The123Nested["X","Benchmark"]#  1
@test MPSGE.Complementarity.result_value(m._jump_model[:PM]) ≈ The123Nested["PM","Benchmark"]#  1
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PD‡Y")]) ≈ The123Nested["YD","Benchmark"]#  218.3079999
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX‡Y")]) ≈ The123Nested["YX","Benchmark"]#  106.3860001
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("RK†Y")]) ≈ The123Nested["KD","Benchmark"]#  143.8619999
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PL†Y")]) ≈ The123Nested["LY","Benchmark"]#  163.3200001
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PD†A")]) ≈ The123Nested["DA","Benchmark"]#  51.4453288
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PM†A")]) ≈ The123Nested["MA","Benchmark"]#  38.4866712
# @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("")]) ≈ The123Nested["PDHHC","Benchmark"]#  166.862671 # Not clear how to report the equivalent nested variable results we have in GAMS, and these GAMS values don't match what we have
# @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("")]) ≈ The123Nested["PMHHC","Benchmark"]#  124.831329 # Not clear how to report the equivalent nested variable results we have in GAMS, and these GAMS values don't match what we have
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PAρGOVT")]) ≈ The123Nested["CAG","Benchmark"]#  35.583
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PLρHH")]) ≈ The123Nested["LD","Benchmark"]#  122.49
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PA‡A")]) ≈ The123Nested["PAA","Benchmark"]#  121.959
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PM‡M")]) ≈ The123Nested["PMM","Benchmark"]#  163.318
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PFX‡X")]) ≈ The123Nested["PFXX","Benchmark"]#  106.386
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PFX†M")]) ≈ The123Nested["PFXM","Benchmark"]#  144.701
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX†X")]) ≈ The123Nested["PXX","Benchmark"]#  106.386
@test MPSGE.Complementarity.result_value(m._jump_model[:TAU_LS]) ≈ 0 # The123Nested["TAU_LS","Benchmark"]#  0
@test MPSGE.Complementarity.result_value(m._jump_model[:TAU_TL]) ≈ 0 # The123Nested["TAU_TL","Benchmark"]#  0
@test MPSGE.Complementarity.result_value(m._jump_model[:UR]) ≈ 0 # The123Nested["UR","Benchmark"]#  0

# *   Tariff reform:
set_value(TM, 0.)
set_value(UR, 0.)
set_fixed!(UR, true)
set_value(TAU_TL, 0.)
set_fixed!(TAU_TL, true)
solve!(m)
# Lump Sum F
@test MPSGE.Complementarity.result_value(m._jump_model[:PFX]) ≈ The123Nested["PFX","Lump Sum F"]#  1.0574822
@test MPSGE.Complementarity.result_value(m._jump_model[:PD]) ≈ The123Nested["PD","Lump Sum F"]#  1.0213866
@test MPSGE.Complementarity.result_value(m._jump_model[:RK]) ≈ The123Nested["RK","Lump Sum F"]#  1.0378735
@test MPSGE.Complementarity.result_value(m._jump_model[:PL]) ≈ The123Nested["PL","Lump Sum F"]#  1.0297727
@test MPSGE.Complementarity.result_value(m._jump_model[:PA]) ≈ The123Nested["PA","Lump Sum F"]#  0.9816379
@test MPSGE.Complementarity.result_value(m._jump_model[:GOVT]) ≈ The123Nested["GOVT","Lump Sum F"]#  34.9296226
@test MPSGE.Complementarity.result_value(m._jump_model[:HH]) ≈ The123Nested["HH","Lump Sum F"]#  414.184
@test MPSGE.Complementarity.result_value(m._jump_model[:PX]) ≈ The123Nested["PX","Lump Sum F"]#  1.0574822
@test MPSGE.Complementarity.result_value(m._jump_model[:Y]) ≈ The123Nested["Y","Lump Sum F"]#  1.0040491
@test MPSGE.Complementarity.result_value(m._jump_model[:A]) ≈ The123Nested["A","Lump Sum F"]#  1
@test MPSGE.Complementarity.result_value(m._jump_model[:M]) ≈ The123Nested["M","Lump Sum F"]#  1.0733289
@test MPSGE.Complementarity.result_value(m._jump_model[:X]) ≈ The123Nested["X","Lump Sum F"]#  1.0997383
@test MPSGE.Complementarity.result_value(m._jump_model[:PM]) ≈ The123Nested["PM","Lump Sum F"]#  0.9369374
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PD‡Y")]) ≈ The123Nested["YD","Lump Sum F"]#  208.1001836
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX‡Y")]) ≈ The123Nested["YX","Lump Sum F"]#  116.5249453
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("RK†Y")]) ≈ The123Nested["KD","Lump Sum F"]#  143.2818415
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PL†Y")]) ≈ The123Nested["LY","Lump Sum F"]#  163.9409519
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PD†A")]) ≈ The123Nested["DA","Lump Sum F"]#  43.8925265
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PM†A")]) ≈ The123Nested["MA","Lump Sum F"]#  46.3738816
# @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("")]) ≈ The123Nested["PDHHC","Lump Sum F"]#  165.0502697 # Not clear how to report the equivalent nested variable results we have in GAMS, and these GAMS values don't match what we have
# @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("")]) ≈ The123Nested["PMHHC","Lump Sum F"]#  128.9200454 # Not clear how to report the equivalent nested variable results we have in GAMS, and these GAMS values don't match what we have
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PAρGOVT")]) ≈ The123Nested["CAG","Lump Sum F"]#  35.583
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PLρHH")]) ≈ The123Nested["LD","Lump Sum F"]#  121.2052394
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PA‡A")]) ≈ The123Nested["PAA","Lump Sum F"]#  121.959
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PM‡M")]) ≈ The123Nested["PMM","Lump Sum F"]#  163.318
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PFX‡X")]) ≈ The123Nested["PFXX","Lump Sum F"]#  106.386
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PFX†M")]) ≈ The123Nested["PFXM","Lump Sum F"]#  144.701
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX†X")]) ≈ The123Nested["PXX","Lump Sum F"]#  106.386
@test MPSGE.Complementarity.result_value(m._jump_model[:TAU_LS]) ≈ The123Nested["TAU_LS","Lump Sum F"]#  0.4077425
@test MPSGE.Complementarity.result_value(m._jump_model[:TAU_TL]) ≈ 0 # The123Nested["TAU_TL","Lump Sum F"]#  0
@test MPSGE.Complementarity.result_value(m._jump_model[:UR]) ≈ 0 # The123Nested["UR","Lump Sum F"]#  0

set_fixed!(UR, false)
set_fixed!(TAU_LS, false)
set_value(TAU_TL, 0.)
set_fixed!(TAU_TL, true)
set_fixed!(HH,false)
# set_value(HH, 428.4262913)
solve!(m)
# Lump Sum R
@test MPSGE.Complementarity.result_value(m._jump_model[:PFX]) ≈ The123Nested["PFX","Lump Sum R"]#  1.0938452
@test MPSGE.Complementarity.result_value(m._jump_model[:PD]) ≈ The123Nested["PD","Lump Sum R"]#  1.0565084
@test MPSGE.Complementarity.result_value(m._jump_model[:RK]) ≈ The123Nested["RK","Lump Sum R"]#  1.0735622
@test MPSGE.Complementarity.result_value(m._jump_model[:PL]) ≈ The123Nested["PL","Lump Sum R"]#  1.0651829
@test MPSGE.Complementarity.result_value(m._jump_model[:PA]) ≈ The123Nested["PA","Lump Sum R"]#  1.0153929
@test MPSGE.Complementarity.result_value(m._jump_model[:GOVT]) ≈ The123Nested["GOVT","Lump Sum R"]#  36.1307262
@test MPSGE.Complementarity.result_value(m._jump_model[:HH]) ≈ The123Nested["HH","Lump Sum R"]#  428.4262913
@test MPSGE.Complementarity.result_value(m._jump_model[:PX]) ≈ The123Nested["PX","Lump Sum R"]#  1.0938452
@test MPSGE.Complementarity.result_value(m._jump_model[:Y]) ≈ The123Nested["Y","Lump Sum R"]#  1.0040491
@test MPSGE.Complementarity.result_value(m._jump_model[:A]) ≈ The123Nested["A","Lump Sum R"]#  1
@test MPSGE.Complementarity.result_value(m._jump_model[:M]) ≈ The123Nested["M","Lump Sum R"]#  1.0733289
@test MPSGE.Complementarity.result_value(m._jump_model[:X]) ≈ The123Nested["X","Lump Sum R"]#  1.0997383
@test MPSGE.Complementarity.result_value(m._jump_model[:PM]) ≈ The123Nested["PM","Lump Sum R"]#  0.9691553
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PD‡Y")]) ≈ The123Nested["YD","Lump Sum R"]#  208.1001836
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX‡Y")]) ≈ The123Nested["YX","Lump Sum R"]#  116.5249453
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("RK†Y")]) ≈ The123Nested["KD","Lump Sum R"]#  143.2818415
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PL†Y")]) ≈ The123Nested["LY","Lump Sum R"]#  163.9409519
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PD†A")]) ≈ The123Nested["DA","Lump Sum R"]#  43.8925265
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PM†A")]) ≈ The123Nested["MA","Lump Sum R"]#  46.3738816
# @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("")]) ≈ The123Nested["PDHHC","Lump Sum R"]#  165.0502697 # Not clear how to report the equivalent nested variable results we have in GAMS, and these GAMS values don't match what we have
# @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("")]) ≈ The123Nested["PMHHC","Lump Sum R"]#  128.9200454 # Not clear how to report the equivalent nested variable results we have in GAMS, and these GAMS values don't match what we have
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PAρGOVT")]) ≈ The123Nested["CAG","Lump Sum R"]#  35.583
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PLρHH")]) ≈ The123Nested["LD","Lump Sum R"]#  121.2052394
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PA‡A")]) ≈ The123Nested["PAA","Lump Sum R"]#  121.959
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PM‡M")]) ≈ The123Nested["PMM","Lump Sum R"]#  163.318
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PFX‡X")]) ≈ The123Nested["PFXX","Lump Sum R"]#  106.386
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PFX†M")]) ≈ The123Nested["PFXM","Lump Sum R"]#  144.701
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX†X")]) ≈ The123Nested["PXX","Lump Sum R"]#  106.386
@test MPSGE.Complementarity.result_value(m._jump_model[:TAU_LS]) ≈ The123Nested["TAU_LS","Lump Sum R"]#  0.4077425
@test MPSGE.Complementarity.result_value(m._jump_model[:TAU_TL]) ≈ 0 # The123Nested["TAU_TL","Lump Sum R"]#  0
@test MPSGE.Complementarity.result_value(m._jump_model[:UR]) ≈ 0 # The123Nested["UR","Lump Sum R"]#  0

# set_fixed!(HH,true)
set_fixed!(UR, true)
set_fixed!(TAU_TL, false)
set_value(TAU_LS, 0.0)
set_fixed!(TAU_LS, true)
solve!(m)
# Wage Tax F
@test MPSGE.Complementarity.result_value(m._jump_model[:PFX]) ≈ The123Nested["PFX","Wage Tax F"]#  1.1208854
@test MPSGE.Complementarity.result_value(m._jump_model[:PD]) ≈ The123Nested["PD","Wage Tax F"]#  1.0829933
@test MPSGE.Complementarity.result_value(m._jump_model[:RK]) ≈ The123Nested["RK","Wage Tax F"]#  1.0908152
@test MPSGE.Complementarity.result_value(m._jump_model[:PL]) ≈ The123Nested["PL","Wage Tax F"]#  1.0063237
@test MPSGE.Complementarity.result_value(m._jump_model[:PA]) ≈ The123Nested["PA","Wage Tax F"]#  1.0406731
@test MPSGE.Complementarity.result_value(m._jump_model[:GOVT]) ≈ The123Nested["GOVT","Wage Tax F"]#  37.0302721
@test MPSGE.Complementarity.result_value(m._jump_model[:HH]) ≈ The123Nested["HH","Wage Tax F"]#  428.4262913
@test MPSGE.Complementarity.result_value(m._jump_model[:PX]) ≈ The123Nested["PX","Wage Tax F"]#  1.1208854
@test MPSGE.Complementarity.result_value(m._jump_model[:Y]) ≈ The123Nested["Y","Wage Tax F"]#  0.9953592
@test MPSGE.Complementarity.result_value(m._jump_model[:A]) ≈ The123Nested["A","Wage Tax F"]#  1
@test MPSGE.Complementarity.result_value(m._jump_model[:M]) ≈ The123Nested["M","Wage Tax F"]#  1.0656393
@test MPSGE.Complementarity.result_value(m._jump_model[:X]) ≈ The123Nested["X","Wage Tax F"]#  1.0892793
@test MPSGE.Complementarity.result_value(m._jump_model[:PM]) ≈ The123Nested["PM","Wage Tax F"]#  0.9931131
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PD‡Y")]) ≈ The123Nested["YD","Wage Tax F"]#  208.2031813
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX‡Y")]) ≈ The123Nested["YX","Wage Tax F"]#  116.4243725
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("RK†Y")]) ≈ The123Nested["KD","Wage Tax F"]#  144.5327464
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PL†Y")]) ≈ The123Nested["LY","Wage Tax F"]#  162.6081155
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PD†A")]) ≈ The123Nested["DA","Wage Tax F"]#  43.8631858
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PM†A")]) ≈ The123Nested["MA","Wage Tax F"]#  46.4058723
# @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("")]) ≈ The123Nested["PDHHC","Wage Tax F"]#  163.3737678 # Not clear how to report the equivalent nested variable results we have in GAMS, and these GAMS values don't match what we have
# @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("")]) ≈ The123Nested["PMHHC","Wage Tax F"]#  127.6322055 # Not clear how to report the equivalent nested variable results we have in GAMS, and these GAMS values don't match what we have
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PAρGOVT")]) ≈ The123Nested["CAG","Wage Tax F"]#  35.583
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PLρHH")]) ≈ The123Nested["LD","Wage Tax F"]#  123.956515
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PA‡A")]) ≈ The123Nested["PAA","Wage Tax F"]#  121.959
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PM‡M")]) ≈ The123Nested["PMM","Wage Tax F"]#  163.318
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PFX‡X")]) ≈ The123Nested["PFXX","Wage Tax F"]#  106.386
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PFX†M")]) ≈ The123Nested["PFXM","Wage Tax F"]#  144.701
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX†X")]) ≈ The123Nested["PXX","Wage Tax F"]#  106.386
@test MPSGE.Complementarity.result_value(m._jump_model[:TAU_LS]) ≈ 0 # The123Nested["TAU_LS","Wage Tax F"]#  0
@test MPSGE.Complementarity.result_value(m._jump_model[:TAU_TL]) ≈ The123Nested["TAU_TL","Wage Tax F"]#  0.0958143
@test MPSGE.Complementarity.result_value(m._jump_model[:UR]) ≈ 0 # The123Nested["UR","Wage Tax F"]#  0

set_fixed!(HH,false)
set_fixed!(UR, false)
set_fixed!(TAU_TL, false)
set_value(TAU_LS, 0.)
set_fixed!(TAU_LS, true)
# set_value(HH, 443.1583236)
solve!(m)
# Wage Tax R
@test MPSGE.Complementarity.result_value(m._jump_model[:PFX]) ≈ The123Nested["PFX","Wage Tax R"]#  1.215978
@test MPSGE.Complementarity.result_value(m._jump_model[:PD]) ≈ The123Nested["PD","Wage Tax R"]#  1.1770496
@test MPSGE.Complementarity.result_value(m._jump_model[:RK]) ≈ The123Nested["RK","Wage Tax R"]#  1.1308395
@test MPSGE.Complementarity.result_value(m._jump_model[:PL]) ≈ The123Nested["PL","Wage Tax R"]#  1.1300213
@test MPSGE.Complementarity.result_value(m._jump_model[:PA]) ≈ The123Nested["PA","Wage Tax R"]#  1.1300213
@test MPSGE.Complementarity.result_value(m._jump_model[:GOVT]) ≈ The123Nested["GOVT","Wage Tax R"]#  40.2095468
@test MPSGE.Complementarity.result_value(m._jump_model[:HH]) ≈ The123Nested["HH","Wage Tax R"]#  443.1583236
@test MPSGE.Complementarity.result_value(m._jump_model[:PX]) ≈ The123Nested["PX","Wage Tax R"]#  1.215978
@test MPSGE.Complementarity.result_value(m._jump_model[:Y]) ≈ The123Nested["Y","Wage Tax R"]#  0.9500636
@test MPSGE.Complementarity.result_value(m._jump_model[:A]) ≈ The123Nested["A","Wage Tax R"]#  1
@test MPSGE.Complementarity.result_value(m._jump_model[:M]) ≈ The123Nested["M","Wage Tax R"]#  1.025596
@test MPSGE.Complementarity.result_value(m._jump_model[:X]) ≈ The123Nested["X","Wage Tax R"]#  1.0348144
@test MPSGE.Complementarity.result_value(m._jump_model[:PM]) ≈ The123Nested["PM","Wage Tax R"]#  1.0773659
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PD‡Y")]) ≈ The123Nested["YD","Wage Tax R"]#  208.7639499
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX‡Y")]) ≈ The123Nested["YX","Wage Tax R"]#  115.8762057
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("RK†Y")]) ≈ The123Nested["KD","Wage Tax R"]#  151.4235414
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PL†Y")]) ≈ The123Nested["LY","Wage Tax R"]#  155.6491304
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PD†A")]) ≈ The123Nested["DA","Wage Tax R"]#  43.7032172
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PM†A")]) ≈ The123Nested["MA","Wage Tax R"]#  46.5804803
# @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("")]) ≈ The123Nested["PDHHC","Wage Tax R"]#  154.6358197 # Not clear how to report the equivalent nested variable results we have in GAMS, and these GAMS values don't match what we have
# @test MPSGE.Complementarity.result_value(m._jump_model[Symbol("")]) ≈ The123Nested["PMHHC","Wage Tax R"]#  120.9178099 # Not clear how to report the equivalent nested variable results we have in GAMS, and these GAMS values don't match what we have
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PAρGOVT")]) ≈ The123Nested["CAG","Wage Tax R"]#  35.583
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PLρHH")]) ≈ The123Nested["LD","Wage Tax R"]#  115.8133753
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PA‡A")]) ≈ The123Nested["PAA","Wage Tax R"]#  121.959
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PM‡M")]) ≈ The123Nested["PMM","Wage Tax R"]#  163.318
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PFX‡X")]) ≈ The123Nested["PFXX","Wage Tax R"]#  106.386
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PFX†M")]) ≈ The123Nested["PFXM","Wage Tax R"]#  144.701
@test MPSGE.Complementarity.result_value(m._jump_model[Symbol("PX†X")]) ≈ The123Nested["PXX","Wage Tax R"]#  106.386
@test MPSGE.Complementarity.result_value(m._jump_model[:TAU_LS]) ≈ 0 # The123Nested["TAU_LS","Wage Tax R"]#  0
@test MPSGE.Complementarity.result_value(m._jump_model[:TAU_TL]) ≈ The123Nested["TAU_TL","Wage Tax R"]#  0.1075146
@test MPSGE.Complementarity.result_value(m._jump_model[:UR]) ≈ The123Nested["UR","Wage Tax R"]#  0.0773942

end