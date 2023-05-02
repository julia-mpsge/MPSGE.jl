using MPSGE

m = Model()

sigmac = add!(m, Parameter(:sigmac, value=1.)) #  Armington elasticity in final demand /0.5/
endow = add!(m, Parameter(:endow, value=1.)) #       change in labour supply      /1/
sigmadm = add!(m, Parameter(:sigmadm, value=1.)) #    Elasticity of substitution (D versus M) /4/
esubkl = add!(m, Parameter(:esubkl, value=1.)) #     Elasticity of substitution (K versus L) /1/
t_elasy = add!(m, Parameter(:t_elasy, value=0.))
sigma = add!(m, Parameter(:sigma, value=1.)) #      Elasticity of substitution (C versus LS) /0.4/;

Y = add!(m, Sector(:Y)) #Production
M = add!(m, Sector(:M)) # Imports

PX = add!(m, Commodity(:PX)) # 
PC = add!(m, Commodity(:PC)) # 
PM = add!(m, Commodity(:PM)) #      ! Import price index
PL = add!(m, Commodity(:PL)) #      ! Wage rate index
RK = add!(m, Commodity(:RK)) #      ! Rental price index
PFX = add!(m, Commodity(:PFX)) #     ! Foreign exchange
PD = add!(m, Commodity(:PD)) #      ! Domestic price index

C  = add!(m, Consumer(:C, benchmark=90.))
GOVT  = add!(m, Consumer(:GOVT, benchmark=110.))
HH = add!(m, Consumer(:HH, benchmark=80.)) #      ! Private households

# Remove for nesting
A = add!(m, Sector(:A)) # Armington composite
PA = add!(m, Commodity(:PA)) #      ! Armington price index
add!(m, Production(A, 0., :($sigmadm* 1.), [Output(PA, 90)], [Input(PD, 30), Input(PM, 60)]))
# Alternates for Nested
add!(m, DemandFunction(GOVT, 1.,  [Demand(PA, 90),Demand(PX,20)],              [Endowment(RK, 110)])) # Non-Nested
# add!(m, DemandFunction(GOVT, 1.,  [Demand(PM, 20), Demand(Nest(C, sigmadm, Demand(PD, 30), Demand(PM,60)))],              [Endowment(RK, 110)])) # Nested

add!(m, Production(Y, :(t_elasy*1.), :($esubkl* 1.), [Output(PC, 60),Output(PFX, 130)], [Input(RK, 110), Input(PL, 80)]))
add!(m, Production(M, 0., 1., [Output(PX, 100)], [Input(PFX, 40), Input(PC, 60)]))
add!(m, DemandFunction(C, :(1*$sigmac),  [Demand(PFX, 90)],              [Endowment(PM, 60),Endowment(PD, 30)]))
add!(m, DemandFunction(HH, :(1*$sigma),  [Demand(PX, 80)], [Endowment(PL, :(80*$endow))])) #

solve!(m, cumulative_iteration_limit=0)

set_value(endow, 1.1)
set_fixed!(HH, true)
# set_fixed!(C, true)

solve!(m)
set_value(sigmac, 0.5)
set_value(sigmadm,4.)
set_value(sigma, 0.4)
solve!(m)
set_value(esubkl, 1.5)
set_fixed!(GOVT, true)
set_fixed!(HH, false)
solve!(m)

set_value(t_elasy, 1.)
solve!(m)

set_value(esubkl, 0)
solve!(m)