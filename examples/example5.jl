using MPSGE
using MPSGE.JuMP.Containers

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

# Added for nesting
# cd0  Final demand for domestic good
# cm0  Final demand for imports
# sigmac Armington elasticity in final demand /0.5/;

px0 = 1 - tx;
rr0 = 1 + tk # rr0  Reference price of capital
pl0 = 1 + tl # pl0  Reference wage
bopdef = mcm[:PFX,:GOVT] # bopdef  Balance of payments deficit
dtax = g0 - bopdef - get_value(TM)*m0 - ta*a0 - tl*ly0 - tk*kd0 - tx*x0 # dtax    Direct tax net transfers

# Updated for nesting
# m0 = pm0*m0;
# Set to use for a0 re-calculation
# ta = a0*ta;
# Impute final demand for domestic and imported goods:
# cd0 = c0 * d0/(d0+m0);
# cm0 = c0 * m0/(d0+m0);
# Armington supply net final demand:
# a0 = d0+m0-cd0-cm0+ta;
#  Recalibrate taxes on A so that tax revenue remains unchanged:
# ta = ta/a0;

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
# add!(m, Production(Y, :($etadx*1.0), :($esubkl*1.0), [Output(PD, d0), Output(PX, x0, [Tax(tx,GOVT)], px0)], [Input(RK, kd0, [Tax(tk, GOVT)], rr0), Input(PL, ly0, [Tax(tl,GOVT), Tax(:($TAU_TL*1),GOVT)], pl0)] ))

add!(m, Production(A, 0., :($sigmadm*1.0), [Output(PA, a0, [Tax(ta,GOVT)])], [Input(PD, d0), Input(PM, m0, [Tax(:($TM*1.),GOVT)], pm0)] ))
add!(m, Production(M, 0., 1.0, [Output(PM, m0)], [Input(PFX, :($pwm*$m0))] ))
add!(m, Production(X, 0., 1.0, [Output(PFX, :($pwx*$x0))], [Input(PX, x0)] ))

add!(m, DemandFunction(GOVT, 0.,
 [Demand(PA , 35.583)],
 [Endowment(PA, :($g0*$TAU_LS)), Endowment(PA, dtax), Endowment(PFX, bopdef)]))

add!(m, DemandFunction(HH, :($sigma*1.0),
 [Demand(PA, c0), Demand(PL,l0)], 
 [Endowment(PA, :(-$g0*$TAU_LS)), Endowment(PA, -dtax), Endowment(RK, kd0), Endowment(PA, -i0), Endowment(PL, (ly0+l0)), Endowment(PL, :(-($ly0+$l0)*$UR))]))

 add!(m, AuxConstraint(UR, :($PL==$PA)))
add!(m, AuxConstraint(TAU_LS, :($GOVT==$PA*$g0)))
add!(m, AuxConstraint(TAU_TL, :($GOVT==$PA*$g0)))

#Benchmark
# set_value(HH, 414.184)
# set_fixed!(HH, true)
solve!(m, cumulative_iteration_limit=0.)

# Tariff reform:
# Lump Sum F
set_value(TM, 0.)
set_value(UR, 0.)
set_fixed!(UR, true)
set_value(TAU_TL, 0.)
set_fixed!(TAU_TL, true)
solve!(m)

# Wage Tax F
set_fixed!(TAU_TL, false)
set_value(TAU_LS, 0.0)
set_fixed!(TAU_LS, true)
# set_value(HH, 427.4988518)
solve!(m)

# Lump Sum R
set_lower_bound(UR, 0.)
set_fixed!(UR, false)
set_fixed!(TAU_LS, false)
set_value(TAU_TL, 0.)
set_fixed!(TAU_TL, true)
solve!(m)

# Wage Tax R
set_fixed!(TAU_TL, false)
set_value(TAU_LS, 0.)
set_fixed!(TAU_LS, true)
# set_value(HH, 441.2417391)
solve!(m)
