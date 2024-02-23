@testitem "TWOBYTWO (functional version)" begin
    using XLSX, MPSGE.JuMP.Containers
    import JuMP

# Non-Nested version, nested version of the same model is below
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

# Comments out for nesting
A = add!(m, Sector(:A)) # Armington composite
PA = add!(m, Commodity(:PA)) #      ! Armington price index
add!(m, Production(A, 0., :($sigmadm* 1.), [Output(PA, 90)], [Input(PD, 30), Input(PM, 60)]))
# Alternates for Nested
add!(m, DemandFunction(GOVT, 1.,  [Demand(PX,20),Demand(PA, 90)],              [Endowment(RK, 110)])) # Non-Nested
#Nested Vesion
# add!(m, DemandFunction(GOVT, 1.,  [Demand(PX,20),Demand(Nest(:CN,:($sigmadm*1.),90.,
#                         [
#                           Input(PD, 30),
#                           Input(PM, 60)
#                         ]
#                                                              ),90.)],          [Endowment(RK, 110)])) # Nested

add!(m, Production(Y, :($t_elasy*1.), :($esubkl* 1.), [Output(PFX, 130), Output(PC, 60)], [Input(RK, 110), Input(PL, 80)]))
add!(m, Production(M, 0., 1., [Output(PX, 100)], [Input(PFX, 40), Input(PC, 60)]))
add!(m, DemandFunction(C, :(1*$sigmac),  [Demand(PFX, 90)],              [Endowment(PM, 60),Endowment(PD, 30)]))
add!(m, DemandFunction(HH, :(1*$sigma),  [Demand(PX, 80)], [Endowment(PL, :(80*$endow))])) #

solve!(m, cumulative_iteration_limit=0)

gams_results = XLSX.readxlsx(joinpath(@__DIR__, "MPSGEresults.xlsx"))
a_table = gams_results["SimpleDemNest"][:]  # Generated with SimpleDNestTest.gms
DNestTest = DenseAxisArray(a_table[2:end,2:end],a_table[2:end,1],a_table[1,2:end])

# Benchmark
@test JuMP.value(m._jump_model[:Y]) ≈ DNestTest["Y","Benchmark"]#  1
@test JuMP.value(m._jump_model[:M]) ≈ DNestTest["M","Benchmark"]#  1
@test JuMP.value(m._jump_model[:PC]) ≈ DNestTest["PC","Benchmark"]#  1
@test JuMP.value(m._jump_model[:PD]) ≈ DNestTest["PD","Benchmark"]#  1
@test JuMP.value(m._jump_model[:PM]) ≈ DNestTest["PM","Benchmark"]#  1
@test JuMP.value(m._jump_model[:PX]) ≈ DNestTest["PX","Benchmark"]#  1
@test JuMP.value(m._jump_model[:PL]) ≈ DNestTest["PL","Benchmark"]#  1
@test JuMP.value(m._jump_model[:RK]) ≈ DNestTest["RK","Benchmark"]#  1
@test JuMP.value(m._jump_model[:PFX]) ≈ DNestTest["PFX","Benchmark"]#  1
@test JuMP.value(m._jump_model[Symbol("PC‡Y")]) ≈ DNestTest["SCY","Benchmark"]#  60
@test JuMP.value(m._jump_model[Symbol("PFX‡Y")]) ≈ DNestTest["SFXY","Benchmark"]#  130
@test JuMP.value(m._jump_model[Symbol("PX‡M")]) ≈ DNestTest["SXM","Benchmark"]#  100
@test JuMP.value(m._jump_model[Symbol("RK†Y")]) ≈ DNestTest["DKY","Benchmark"]#  110
@test JuMP.value(m._jump_model[Symbol("PL†Y")]) ≈ DNestTest["DLY","Benchmark"]#  80
@test JuMP.value(m._jump_model[Symbol("PFX†M")]) ≈ DNestTest["DFXM","Benchmark"]#  40
@test JuMP.value(m._jump_model[:GOVT]) ≈ DNestTest["GOVT","Benchmark"]#  110
@test JuMP.value(m._jump_model[:HH]) ≈ DNestTest["HH","Benchmark"]#  80
@test JuMP.value(m._jump_model[:C]) ≈ DNestTest["C","Benchmark"]#  90
@test JuMP.value(m._jump_model[Symbol("PFXρC")]) ≈ DNestTest["CFXC","Benchmark"]#  90
@test JuMP.value(m._jump_model[Symbol("PXρGOVT")]) ≈ DNestTest["CXG","Benchmark"]#  20
@test JuMP.value(m._jump_model[Symbol("PXρHH")]) ≈ DNestTest["CXHH","Benchmark"]#  80

# endow=1.1
set_value(endow, 1.1)
set_fixed!(HH, true)
solve!(m)


@test JuMP.value(m._jump_model[:Y]) ≈ DNestTest["Y","endow=1.1"]#  1.04094672
@test JuMP.value(m._jump_model[:M]) ≈ DNestTest["M","endow=1.1"]#  1.04094672
@test JuMP.value(m._jump_model[:PC]) ≈ DNestTest["PC","endow=1.1"]#  0.96066397
@test JuMP.value(m._jump_model[:PD]) ≈ DNestTest["PD","endow=1.1"]#  1
@test JuMP.value(m._jump_model[:PM]) ≈ DNestTest["PM","endow=1.1"]#  1
@test JuMP.value(m._jump_model[:PX]) ≈ DNestTest["PX","endow=1.1"]#  0.96066397
@test JuMP.value(m._jump_model[:PL]) ≈ DNestTest["PL","endow=1.1"]#  0.90909091
@test JuMP.value(m._jump_model[:RK]) ≈ DNestTest["RK","endow=1.1"]#  1
@test JuMP.value(m._jump_model[:PFX]) ≈ DNestTest["PFX","endow=1.1"]#  0.96066397
@test JuMP.value(m._jump_model[Symbol("PC‡Y")]) ≈ DNestTest["SCY","endow=1.1"]#  60
@test JuMP.value(m._jump_model[Symbol("PFX‡Y")]) ≈ DNestTest["SFXY","endow=1.1"]#  130
@test JuMP.value(m._jump_model[Symbol("PX‡M")]) ≈ DNestTest["SXM","endow=1.1"]#  100
@test JuMP.value(m._jump_model[Symbol("RK†Y")]) ≈ DNestTest["DKY","endow=1.1"]#  105.673
@test JuMP.value(m._jump_model[Symbol("PL†Y")]) ≈ DNestTest["DLY","endow=1.1"]#  84.53842903
@test JuMP.value(m._jump_model[Symbol("PFX†M")]) ≈ DNestTest["DFXM","endow=1.1"]#  40
@test JuMP.value(m._jump_model[:GOVT]) ≈ DNestTest["GOVT","endow=1.1"]#  110
@test JuMP.value(m._jump_model[:HH]) ≈ DNestTest["HH","endow=1.1"]#  80
@test JuMP.value(m._jump_model[:C]) ≈ DNestTest["C","endow=1.1"]#  90
@test JuMP.value(m._jump_model[Symbol("PFXρC")]) ≈ DNestTest["CFXC","endow=1.1"]#  93.68520436
@test JuMP.value(m._jump_model[Symbol("PXρGOVT")]) ≈ DNestTest["CXG","endow=1.1"]#  20.8189343
@test JuMP.value(m._jump_model[Symbol("PXρHH")]) ≈ DNestTest["CXHH","endow=1.1"]#  83.2757372

# sigmac=0.5
set_value(sigmac, 0.5)
solve!(m)

@test JuMP.value(m._jump_model[:Y]) ≈ DNestTest["Y","sigmac=0.5"]#  1.04094672
@test JuMP.value(m._jump_model[:M]) ≈ DNestTest["M","sigmac=0.5"]#  1.04094672
@test JuMP.value(m._jump_model[:PC]) ≈ DNestTest["PC","sigmac=0.5"]#  0.96066397
@test JuMP.value(m._jump_model[:PD]) ≈ DNestTest["PD","sigmac=0.5"]#  1
@test JuMP.value(m._jump_model[:PM]) ≈ DNestTest["PM","sigmac=0.5"]#  1
@test JuMP.value(m._jump_model[:PX]) ≈ DNestTest["PX","sigmac=0.5"]#  0.96066397
@test JuMP.value(m._jump_model[:PL]) ≈ DNestTest["PL","sigmac=0.5"]#  0.90909091
@test JuMP.value(m._jump_model[:RK]) ≈ DNestTest["RK","sigmac=0.5"]#  1
@test JuMP.value(m._jump_model[:PFX]) ≈ DNestTest["PFX","sigmac=0.5"]#  0.96066397
@test JuMP.value(m._jump_model[Symbol("PC‡Y")]) ≈ DNestTest["SCY","sigmac=0.5"]#  60
@test JuMP.value(m._jump_model[Symbol("PFX‡Y")]) ≈ DNestTest["SFXY","sigmac=0.5"]#  130
@test JuMP.value(m._jump_model[Symbol("PX‡M")]) ≈ DNestTest["SXM","sigmac=0.5"]#  100
@test JuMP.value(m._jump_model[Symbol("RK†Y")]) ≈ DNestTest["DKY","sigmac=0.5"]#  105.673
@test JuMP.value(m._jump_model[Symbol("PL†Y")]) ≈ DNestTest["DLY","sigmac=0.5"]#  84.53842903
@test JuMP.value(m._jump_model[Symbol("PFX†M")]) ≈ DNestTest["DFXM","sigmac=0.5"]#  40
@test JuMP.value(m._jump_model[:GOVT]) ≈ DNestTest["GOVT","sigmac=0.5"]#  110
@test JuMP.value(m._jump_model[:HH]) ≈ DNestTest["HH","sigmac=0.5"]#  80
@test JuMP.value(m._jump_model[:C]) ≈ DNestTest["C","sigmac=0.5"]#  90
@test JuMP.value(m._jump_model[Symbol("PFXρC")]) ≈ DNestTest["CFXC","sigmac=0.5"]#  93.68520436
@test JuMP.value(m._jump_model[Symbol("PXρGOVT")]) ≈ DNestTest["CXG","sigmac=0.5"]#  20.8189343
@test JuMP.value(m._jump_model[Symbol("PXρHH")]) ≈ DNestTest["CXHH","sigmac=0.5"]#  83.2757372

# sigmadm=4
set_value(sigmadm,4.)
solve!(m)

@test JuMP.value(m._jump_model[:Y]) ≈ DNestTest["Y","sigmadm=4"]#  1.04094672
@test JuMP.value(m._jump_model[:M]) ≈ DNestTest["M","sigmadm=4"]#  1.04094672
@test JuMP.value(m._jump_model[:PC]) ≈ DNestTest["PC","sigmadm=4"]#  0.96066397
@test JuMP.value(m._jump_model[:PD]) ≈ DNestTest["PD","sigmadm=4"]#  1
@test JuMP.value(m._jump_model[:PM]) ≈ DNestTest["PM","sigmadm=4"]#  1
@test JuMP.value(m._jump_model[:PX]) ≈ DNestTest["PX","sigmadm=4"]#  0.96066397
@test JuMP.value(m._jump_model[:PL]) ≈ DNestTest["PL","sigmadm=4"]#  0.90909091
@test JuMP.value(m._jump_model[:RK]) ≈ DNestTest["RK","sigmadm=4"]#  1
@test JuMP.value(m._jump_model[:PFX]) ≈ DNestTest["PFX","sigmadm=4"]#  0.96066397
@test JuMP.value(m._jump_model[Symbol("PC‡Y")]) ≈ DNestTest["SCY","sigmadm=4"]#  60
@test JuMP.value(m._jump_model[Symbol("PFX‡Y")]) ≈ DNestTest["SFXY","sigmadm=4"]#  130
@test JuMP.value(m._jump_model[Symbol("PX‡M")]) ≈ DNestTest["SXM","sigmadm=4"]#  100
@test JuMP.value(m._jump_model[Symbol("RK†Y")]) ≈ DNestTest["DKY","sigmadm=4"]#  105.673
@test JuMP.value(m._jump_model[Symbol("PL†Y")]) ≈ DNestTest["DLY","sigmadm=4"]#  84.53842903
@test JuMP.value(m._jump_model[Symbol("PFX†M")]) ≈ DNestTest["DFXM","sigmadm=4"]#  40
@test JuMP.value(m._jump_model[:GOVT]) ≈ DNestTest["GOVT","sigmadm=4"]#  110
@test JuMP.value(m._jump_model[:HH]) ≈ DNestTest["HH","sigmadm=4"]#  80
@test JuMP.value(m._jump_model[:C]) ≈ DNestTest["C","sigmadm=4"]#  90
@test JuMP.value(m._jump_model[Symbol("PFXρC")]) ≈ DNestTest["CFXC","sigmadm=4"]#  93.68520436
@test JuMP.value(m._jump_model[Symbol("PXρGOVT")]) ≈ DNestTest["CXG","sigmadm=4"]#  20.8189343
@test JuMP.value(m._jump_model[Symbol("PXρHH")]) ≈ DNestTest["CXHH","sigmadm=4"]#  83.2757372

# sigma=0.4
set_value(sigma, 0.4)
solve!(m)

@test JuMP.value(m._jump_model[:Y]) ≈ DNestTest["Y","sigma=0.4"]#  1.04094672
@test JuMP.value(m._jump_model[:M]) ≈ DNestTest["M","sigma=0.4"]#  1.04094672
@test JuMP.value(m._jump_model[:PC]) ≈ DNestTest["PC","sigma=0.4"]#  0.96066397
@test JuMP.value(m._jump_model[:PD]) ≈ DNestTest["PD","sigma=0.4"]#  1
@test JuMP.value(m._jump_model[:PM]) ≈ DNestTest["PM","sigma=0.4"]#  1
@test JuMP.value(m._jump_model[:PX]) ≈ DNestTest["PX","sigma=0.4"]#  0.96066397
@test JuMP.value(m._jump_model[:PL]) ≈ DNestTest["PL","sigma=0.4"]#  0.90909091
@test JuMP.value(m._jump_model[:RK]) ≈ DNestTest["RK","sigma=0.4"]#  1
@test JuMP.value(m._jump_model[:PFX]) ≈ DNestTest["PFX","sigma=0.4"]#  0.96066397
@test JuMP.value(m._jump_model[Symbol("PC‡Y")]) ≈ DNestTest["SCY","sigma=0.4"]#  60
@test JuMP.value(m._jump_model[Symbol("PFX‡Y")]) ≈ DNestTest["SFXY","sigma=0.4"]#  130
@test JuMP.value(m._jump_model[Symbol("PX‡M")]) ≈ DNestTest["SXM","sigma=0.4"]#  100
@test JuMP.value(m._jump_model[Symbol("RK†Y")]) ≈ DNestTest["DKY","sigma=0.4"]#  105.673
@test JuMP.value(m._jump_model[Symbol("PL†Y")]) ≈ DNestTest["DLY","sigma=0.4"]#  84.53842903
@test JuMP.value(m._jump_model[Symbol("PFX†M")]) ≈ DNestTest["DFXM","sigma=0.4"]#  40
@test JuMP.value(m._jump_model[:GOVT]) ≈ DNestTest["GOVT","sigma=0.4"]#  110
@test JuMP.value(m._jump_model[:HH]) ≈ DNestTest["HH","sigma=0.4"]#  80
@test JuMP.value(m._jump_model[:C]) ≈ DNestTest["C","sigma=0.4"]#  90
@test JuMP.value(m._jump_model[Symbol("PFXρC")]) ≈ DNestTest["CFXC","sigma=0.4"]#  93.68520436
@test JuMP.value(m._jump_model[Symbol("PXρGOVT")]) ≈ DNestTest["CXG","sigma=0.4"]#  20.8189343
@test JuMP.value(m._jump_model[Symbol("PXρHH")]) ≈ DNestTest["CXHH","sigma=0.4"]#  83.2757372

# esubkl=1.5
set_value(esubkl, 1.5)
set_fixed!(GOVT, true)
set_fixed!(HH, false)
set_fixed!(C,true)
solve!(m)

@test JuMP.value(m._jump_model[:Y]) ≈ DNestTest["Y","esubkl=1.5"]#  1.04133159
@test JuMP.value(m._jump_model[:M]) ≈ DNestTest["M","esubkl=1.5"]#  1.0486808
@test JuMP.value(m._jump_model[:PC]) ≈ DNestTest["PC","esubkl=1.5"]#  0.98510801
@test JuMP.value(m._jump_model[:PD]) ≈ DNestTest["PD","esubkl=1.5"]#  1
@test JuMP.value(m._jump_model[:PM]) ≈ DNestTest["PM","esubkl=1.5"]#  1
@test JuMP.value(m._jump_model[:PX]) ≈ DNestTest["PX","esubkl=1.5"]#  0.97820432
@test JuMP.value(m._jump_model[:PL]) ≈ DNestTest["PL","esubkl=1.5"]#  0.93843647
@test JuMP.value(m._jump_model[:RK]) ≈ DNestTest["RK","esubkl=1.5"]#  1
@test JuMP.value(m._jump_model[:PFX]) ≈ DNestTest["PFX","esubkl=1.5"]#  0.9679394
@test JuMP.value(m._jump_model[Symbol("PC‡Y")]) ≈ DNestTest["SCY","esubkl=1.5"]#  60
@test JuMP.value(m._jump_model[Symbol("PFX‡Y")]) ≈ DNestTest["SFXY","esubkl=1.5"]#  130
@test JuMP.value(m._jump_model[Symbol("PX‡M")]) ≈ DNestTest["SXM","esubkl=1.5"]#  100
@test JuMP.value(m._jump_model[Symbol("RK†Y")]) ≈ DNestTest["DKY","esubkl=1.5"]#  105.634
@test JuMP.value(m._jump_model[Symbol("PL†Y")]) ≈ DNestTest["DLY","esubkl=1.5"]#  84.50718369
@test JuMP.value(m._jump_model[Symbol("PFX†M")]) ≈ DNestTest["DFXM","esubkl=1.5"]#  40.42419695
@test JuMP.value(m._jump_model[:GOVT]) ≈ DNestTest["GOVT","esubkl=1.5"]#  110
@test JuMP.value(m._jump_model[:HH]) ≈ DNestTest["HH","esubkl=1.5"]#  82.58240924
@test JuMP.value(m._jump_model[:C]) ≈ DNestTest["C","esubkl=1.5"]#  90
@test JuMP.value(m._jump_model[Symbol("PFXρC")]) ≈ DNestTest["CFXC","esubkl=1.5"]#  92.98102756
@test JuMP.value(m._jump_model[Symbol("PXρGOVT")]) ≈ DNestTest["CXG","esubkl=1.5"]#  20.44562626
@test JuMP.value(m._jump_model[Symbol("PXρHH")]) ≈ DNestTest["CXHH","esubkl=1.5"]#  84.42245376

# t_elasY=1
set_value(t_elasy, 1.)
set_fixed!(C,false)
solve!(m)

@test JuMP.value(m._jump_model[:Y]) ≈ DNestTest["Y","t_elasY=1"]#  1.04133159
@test JuMP.value(m._jump_model[:M]) ≈ DNestTest["M","t_elasY=1"]#  1.05128658
@test JuMP.value(m._jump_model[:PC]) ≈ DNestTest["PC","t_elasY=1"]#  0.97921692
@test JuMP.value(m._jump_model[:PD]) ≈ DNestTest["PD","t_elasY=1"]#  1
@test JuMP.value(m._jump_model[:PM]) ≈ DNestTest["PM","t_elasY=1"]#  1
@test JuMP.value(m._jump_model[:PX]) ≈ DNestTest["PX","t_elasY=1"]#  0.97577969
@test JuMP.value(m._jump_model[:PL]) ≈ DNestTest["PL","t_elasY=1"]#  0.93843647
@test JuMP.value(m._jump_model[:RK]) ≈ DNestTest["RK","t_elasY=1"]#  1
@test JuMP.value(m._jump_model[:PFX]) ≈ DNestTest["PFX","t_elasY=1"]#  0.97064645
@test JuMP.value(m._jump_model[Symbol("PC‡Y")]) ≈ DNestTest["SCY","t_elasY=1"]#  60.36096719
@test JuMP.value(m._jump_model[Symbol("PFX‡Y")]) ≈ DNestTest["SFXY","t_elasY=1"]#  129.6374
@test JuMP.value(m._jump_model[Symbol("PX‡M")]) ≈ DNestTest["SXM","t_elasY=1"]#  100
@test JuMP.value(m._jump_model[Symbol("RK†Y")]) ≈ DNestTest["DKY","t_elasY=1"]#  105.634
@test JuMP.value(m._jump_model[Symbol("PL†Y")]) ≈ DNestTest["DLY","t_elasY=1"]#  84.50718369
@test JuMP.value(m._jump_model[Symbol("PFX†M")]) ≈ DNestTest["DFXM","t_elasY=1"]#  40.21153908
@test JuMP.value(m._jump_model[:GOVT]) ≈ DNestTest["GOVT","t_elasY=1"]#  110
@test JuMP.value(m._jump_model[:HH]) ≈ DNestTest["HH","t_elasY=1"]#  82.58240907
@test JuMP.value(m._jump_model[:C]) ≈ DNestTest["C","t_elasY=1"]#  90
@test JuMP.value(m._jump_model[Symbol("PFXρC")]) ≈ DNestTest["CFXC","t_elasY=1"]#  92.72171175
@test JuMP.value(m._jump_model[Symbol("PXρGOVT")]) ≈ DNestTest["CXG","t_elasY=1"]#  20.49642989
@test JuMP.value(m._jump_model[Symbol("PXρHH")]) ≈ DNestTest["CXHH","t_elasY=1"]#  84.63222806

# endow=2
set_value(endow, 2.)
solve!(m)

@test JuMP.value(m._jump_model[:Y]) ≈ DNestTest["Y","endow=2"]#  1.36556375
@test JuMP.value(m._jump_model[:M]) ≈ DNestTest["M","endow=2"]#  1.46151811
@test JuMP.value(m._jump_model[:PC]) ≈ DNestTest["PC","endow=2"]#  0.84773894
@test JuMP.value(m._jump_model[:PD]) ≈ DNestTest["PD","endow=2"]#  1
@test JuMP.value(m._jump_model[:PM]) ≈ DNestTest["PM","endow=2"]#  1
@test JuMP.value(m._jump_model[:PX]) ≈ DNestTest["PX","endow=2"]#  0.82649461
@test JuMP.value(m._jump_model[:PL]) ≈ DNestTest["PL","endow=2"]#  0.62996052
@test JuMP.value(m._jump_model[:RK]) ≈ DNestTest["RK","endow=2"]#  1
@test JuMP.value(m._jump_model[:PFX]) ≈ DNestTest["PFX","endow=2"]#  0.79562215
@test JuMP.value(m._jump_model[Symbol("PC‡Y")]) ≈ DNestTest["SCY","endow=2"]#  62.60677993
@test JuMP.value(m._jump_model[Symbol("PFX‡Y")]) ≈ DNestTest["SFXY","endow=2"]#  127.3087
@test JuMP.value(m._jump_model[Symbol("PX‡M")]) ≈ DNestTest["SXM","endow=2"]#  100
@test JuMP.value(m._jump_model[Symbol("RK†Y")]) ≈ DNestTest["DKY","endow=2"]#  80.55281206
@test JuMP.value(m._jump_model[Symbol("PL†Y")]) ≈ DNestTest["DLY","endow=2"]#  117.1677
@test JuMP.value(m._jump_model[Symbol("PFX†M")]) ≈ DNestTest["DFXM","endow=2"]#  41.55211657
@test JuMP.value(m._jump_model[:GOVT]) ≈ DNestTest["GOVT","endow=2"]#  110
@test JuMP.value(m._jump_model[:HH]) ≈ DNestTest["HH","endow=2"]#  100.7937
@test JuMP.value(m._jump_model[:C]) ≈ DNestTest["C","endow=2"]#  90
@test JuMP.value(m._jump_model[Symbol("PFXρC")]) ≈ DNestTest["CFXC","endow=2"]#  113.119
@test JuMP.value(m._jump_model[Symbol("PXρGOVT")]) ≈ DNestTest["CXG","endow=2"]#  24.19858498
@test JuMP.value(m._jump_model[Symbol("PXρHH")]) ≈ DNestTest["CXHH","endow=2"]#  121.9532

# sigmac=4
set_value(sigmac, 4.)
solve!(m)

@test JuMP.value(m._jump_model[:Y]) ≈ DNestTest["Y","sigmac=4"]#  1.36556375
@test JuMP.value(m._jump_model[:M]) ≈ DNestTest["M","sigmac=4"]#  1.46151811
@test JuMP.value(m._jump_model[:PC]) ≈ DNestTest["PC","sigmac=4"]#  0.84773894
@test JuMP.value(m._jump_model[:PD]) ≈ DNestTest["PD","sigmac=4"]#  1
@test JuMP.value(m._jump_model[:PM]) ≈ DNestTest["PM","sigmac=4"]#  1
@test JuMP.value(m._jump_model[:PX]) ≈ DNestTest["PX","sigmac=4"]#  0.82649461
@test JuMP.value(m._jump_model[:PL]) ≈ DNestTest["PL","sigmac=4"]#  0.62996052
@test JuMP.value(m._jump_model[:RK]) ≈ DNestTest["RK","sigmac=4"]#  1
@test JuMP.value(m._jump_model[:PFX]) ≈ DNestTest["PFX","sigmac=4"]#  0.79562215
@test JuMP.value(m._jump_model[Symbol("PC‡Y")]) ≈ DNestTest["SCY","sigmac=4"]#  62.60677993
@test JuMP.value(m._jump_model[Symbol("PFX‡Y")]) ≈ DNestTest["SFXY","sigmac=4"]#  127.3087
@test JuMP.value(m._jump_model[Symbol("PX‡M")]) ≈ DNestTest["SXM","sigmac=4"]#  100
@test JuMP.value(m._jump_model[Symbol("RK†Y")]) ≈ DNestTest["DKY","sigmac=4"]#  80.55281206
@test JuMP.value(m._jump_model[Symbol("PL†Y")]) ≈ DNestTest["DLY","sigmac=4"]#  117.1677
@test JuMP.value(m._jump_model[Symbol("PFX†M")]) ≈ DNestTest["DFXM","sigmac=4"]#  41.55211657
@test JuMP.value(m._jump_model[:GOVT]) ≈ DNestTest["GOVT","sigmac=4"]#  110
@test JuMP.value(m._jump_model[:HH]) ≈ DNestTest["HH","sigmac=4"]#  100.7937
@test JuMP.value(m._jump_model[:C]) ≈ DNestTest["C","sigmac=4"]#  90
@test JuMP.value(m._jump_model[Symbol("PFXρC")]) ≈ DNestTest["CFXC","sigmac=4"]#  113.119
@test JuMP.value(m._jump_model[Symbol("PXρGOVT")]) ≈ DNestTest["CXG","sigmac=4"]#  24.19858498
@test JuMP.value(m._jump_model[Symbol("PXρHH")]) ≈ DNestTest["CXHH","sigmac=4"]#  121.9532

# sigma=3
set_value(sigma, 3.)
solve!(m)

@test JuMP.value(m._jump_model[:Y]) ≈ DNestTest["Y","sigma=3"]#  1.36556375
@test JuMP.value(m._jump_model[:M]) ≈ DNestTest["M","sigma=3"]#  1.46151811
@test JuMP.value(m._jump_model[:PC]) ≈ DNestTest["PC","sigma=3"]#  0.84773894
@test JuMP.value(m._jump_model[:PD]) ≈ DNestTest["PD","sigma=3"]#  1
@test JuMP.value(m._jump_model[:PM]) ≈ DNestTest["PM","sigma=3"]#  1
@test JuMP.value(m._jump_model[:PX]) ≈ DNestTest["PX","sigma=3"]#  0.82649461
@test JuMP.value(m._jump_model[:PL]) ≈ DNestTest["PL","sigma=3"]#  0.62996052
@test JuMP.value(m._jump_model[:RK]) ≈ DNestTest["RK","sigma=3"]#  1
@test JuMP.value(m._jump_model[:PFX]) ≈ DNestTest["PFX","sigma=3"]#  0.79562215
@test JuMP.value(m._jump_model[Symbol("PC‡Y")]) ≈ DNestTest["SCY","sigma=3"]#  62.60677993
@test JuMP.value(m._jump_model[Symbol("PFX‡Y")]) ≈ DNestTest["SFXY","sigma=3"]#  127.3087
@test JuMP.value(m._jump_model[Symbol("PX‡M")]) ≈ DNestTest["SXM","sigma=3"]#  100
@test JuMP.value(m._jump_model[Symbol("RK†Y")]) ≈ DNestTest["DKY","sigma=3"]#  80.55281206
@test JuMP.value(m._jump_model[Symbol("PL†Y")]) ≈ DNestTest["DLY","sigma=3"]#  117.1677
@test JuMP.value(m._jump_model[Symbol("PFX†M")]) ≈ DNestTest["DFXM","sigma=3"]#  41.55211657
@test JuMP.value(m._jump_model[:GOVT]) ≈ DNestTest["GOVT","sigma=3"]#  110
@test JuMP.value(m._jump_model[:HH]) ≈ DNestTest["HH","sigma=3"]#  100.7937
@test JuMP.value(m._jump_model[:C]) ≈ DNestTest["C","sigma=3"]#  90
@test JuMP.value(m._jump_model[Symbol("PFXρC")]) ≈ DNestTest["CFXC","sigma=3"]#  113.119
@test JuMP.value(m._jump_model[Symbol("PXρGOVT")]) ≈ DNestTest["CXG","sigma=3"]#  24.19858498
@test JuMP.value(m._jump_model[Symbol("PXρHH")]) ≈ DNestTest["CXHH","sigma=3"]#  121.9532

set_value(t_elasy,0.5)
solve!(m)

@test JuMP.value(m._jump_model[:Y]) ≈ DNestTest["Y","t_elY=0.5"]#  1.36556375
@test JuMP.value(m._jump_model[:M]) ≈ DNestTest["M","t_elY=0.5"]#  1.45318709
@test JuMP.value(m._jump_model[:PC]) ≈ DNestTest["PC","t_elY=0.5"]#  0.85984236
@test JuMP.value(m._jump_model[:PD]) ≈ DNestTest["PD","t_elY=0.5"]#  1
@test JuMP.value(m._jump_model[:PM]) ≈ DNestTest["PM","t_elY=0.5"]#  1
@test JuMP.value(m._jump_model[:PX]) ≈ DNestTest["PX","t_elY=0.5"]#  0.83123284
@test JuMP.value(m._jump_model[:PL]) ≈ DNestTest["PL","t_elY=0.5"]#  0.62996052
@test JuMP.value(m._jump_model[:RK]) ≈ DNestTest["RK","t_elY=0.5"]#  1
@test JuMP.value(m._jump_model[:PFX]) ≈ DNestTest["PFX","t_elY=0.5"]#  0.79009349
@test JuMP.value(m._jump_model[Symbol("PC‡Y")]) ≈ DNestTest["SCY","t_elY=0.5"]#  61.7255064
@test JuMP.value(m._jump_model[Symbol("PFX‡Y")]) ≈ DNestTest["SFXY","t_elY=0.5"]#  128.1996
@test JuMP.value(m._jump_model[Symbol("PX‡M")]) ≈ DNestTest["SXM","t_elY=0.5"]#  100
@test JuMP.value(m._jump_model[Symbol("RK†Y")]) ≈ DNestTest["DKY","t_elY=0.5"]#  80.55281207
@test JuMP.value(m._jump_model[Symbol("PL†Y")]) ≈ DNestTest["DLY","t_elY=0.5"]#  117.1677
@test JuMP.value(m._jump_model[Symbol("PFX†M")]) ≈ DNestTest["DFXM","t_elY=0.5"]#  42.08275888
@test JuMP.value(m._jump_model[:GOVT]) ≈ DNestTest["GOVT","t_elY=0.5"]#  110
@test JuMP.value(m._jump_model[:HH]) ≈ DNestTest["HH","t_elY=0.5"]#  100.7937
@test JuMP.value(m._jump_model[:C]) ≈ DNestTest["C","t_elY=0.5"]#  90
@test JuMP.value(m._jump_model[Symbol("PFXρC")]) ≈ DNestTest["CFXC","t_elY=0.5"]#  113.9106
@test JuMP.value(m._jump_model[Symbol("PXρGOVT")]) ≈ DNestTest["CXG","t_elY=0.5"]#  24.06064697
@test JuMP.value(m._jump_model[Symbol("PXρHH")]) ≈ DNestTest["CXHH","t_elY=0.5"]#  121.2581

# sigmac=.1
set_value(sigmac, .1)
solve!(m)

@test JuMP.value(m._jump_model[:Y]) ≈ DNestTest["Y","sigmac=.1"]#  1.36556375
@test JuMP.value(m._jump_model[:M]) ≈ DNestTest["M","sigmac=.1"]#  1.45318709
@test JuMP.value(m._jump_model[:PC]) ≈ DNestTest["PC","sigmac=.1"]#  0.85984236
@test JuMP.value(m._jump_model[:PD]) ≈ DNestTest["PD","sigmac=.1"]#  1
@test JuMP.value(m._jump_model[:PM]) ≈ DNestTest["PM","sigmac=.1"]#  1
@test JuMP.value(m._jump_model[:PX]) ≈ DNestTest["PX","sigmac=.1"]#  0.83123284
@test JuMP.value(m._jump_model[:PL]) ≈ DNestTest["PL","sigmac=.1"]#  0.62996052
@test JuMP.value(m._jump_model[:RK]) ≈ DNestTest["RK","sigmac=.1"]#  1
@test JuMP.value(m._jump_model[:PFX]) ≈ DNestTest["PFX","sigmac=.1"]#  0.79009349
@test JuMP.value(m._jump_model[Symbol("PC‡Y")]) ≈ DNestTest["SCY","sigmac=.1"]#  61.7255064
@test JuMP.value(m._jump_model[Symbol("PFX‡Y")]) ≈ DNestTest["SFXY","sigmac=.1"]#  128.1996
@test JuMP.value(m._jump_model[Symbol("PX‡M")]) ≈ DNestTest["SXM","sigmac=.1"]#  100
@test JuMP.value(m._jump_model[Symbol("RK†Y")]) ≈ DNestTest["DKY","sigmac=.1"]#  80.55281207
@test JuMP.value(m._jump_model[Symbol("PL†Y")]) ≈ DNestTest["DLY","sigmac=.1"]#  117.1677
@test JuMP.value(m._jump_model[Symbol("PFX†M")]) ≈ DNestTest["DFXM","sigmac=.1"]#  42.08275888
@test JuMP.value(m._jump_model[:GOVT]) ≈ DNestTest["GOVT","sigmac=.1"]#  110
@test JuMP.value(m._jump_model[:HH]) ≈ DNestTest["HH","sigmac=.1"]#  100.7937
@test JuMP.value(m._jump_model[:C]) ≈ DNestTest["C","sigmac=.1"]#  90
@test JuMP.value(m._jump_model[Symbol("PFXρC")]) ≈ DNestTest["CFXC","sigmac=.1"]#  113.9106
@test JuMP.value(m._jump_model[Symbol("PXρGOVT")]) ≈ DNestTest["CXG","sigmac=.1"]#  24.06064697
@test JuMP.value(m._jump_model[Symbol("PXρHH")]) ≈ DNestTest["CXHH","sigmac=.1"]#  121.2581


#This fails for most variables. The GAMS results has gaps/undefined/no value for PL, HH, and CXHH. This suggests we are not handling results with /0 or 0 results in the same way
# There's something not working about unfixing HH. Running without first fixing HH does match.  
set_fixed!(C, true)
set_lower_bound(HH, 0.0)
set_lower_bound(PL,0.0)
set_value(esubkl, 0.)
solve!(m) 
@test JuMP.value(m._jump_model[:Y]) ≈ DNestTest["Y","esubkl=0"]#  1
@test JuMP.value(m._jump_model[:M]) ≈ DNestTest["M","esubkl=0"]#  0.49256427
@test JuMP.value(m._jump_model[:PC]) ≈ DNestTest["PC","esubkl=0"]#  0.28503598
@test JuMP.value(m._jump_model[:PD]) ≈ DNestTest["PD","esubkl=0"]#  1
@test JuMP.value(m._jump_model[:PM]) ≈ DNestTest["PM","esubkl=0"]#  1
@test JuMP.value(m._jump_model[:PX]) ≈ DNestTest["PX","esubkl=0"]#  0.40603838
@test JuMP.value(m._jump_model[:PL]) ≈ 0 # missing in GAMS DNestTest["PL","esubkl=0"]#  
@test JuMP.value(m._jump_model[:RK]) ≈ DNestTest["RK","esubkl=0"]#  1
@test JuMP.value(m._jump_model[:PFX]) ≈ DNestTest["PFX","esubkl=0"]#  0.69034817
@test JuMP.value(m._jump_model[Symbol("PC‡Y")]) ≈ DNestTest["SCY","esubkl=0"]#  42.09994749
@test JuMP.value(m._jump_model[Symbol("PFX‡Y")]) ≈ DNestTest["SFXY","esubkl=0"]#  141.9574
@test JuMP.value(m._jump_model[Symbol("PX‡M")]) ≈ DNestTest["SXM","esubkl=0"]#  100
@test JuMP.value(m._jump_model[Symbol("RK†Y")]) ≈ DNestTest["DKY","esubkl=0"]#  110
@test JuMP.value(m._jump_model[Symbol("PL†Y")]) ≈ DNestTest["DLY","esubkl=0"]#  80
@test JuMP.value(m._jump_model[Symbol("PFX†M")]) ≈ DNestTest["DFXM","esubkl=0"]#  23.52658546
@test JuMP.value(m._jump_model[:GOVT]) ≈ DNestTest["GOVT","esubkl=0"]#  110
@test JuMP.value(m._jump_model[:HH]) ≈  0 # missing in GAMS DNestTest["HH","esubkl=0"]#  
@test JuMP.value(m._jump_model[:C]) ≈ DNestTest["C","esubkl=0"]#  90
@test JuMP.value(m._jump_model[Symbol("PFXρC")]) ≈ DNestTest["CFXC","esubkl=0"]#  130.369
@test JuMP.value(m._jump_model[Symbol("PXρGOVT")]) ≈ DNestTest["CXG","esubkl=0"]#  49.25642749
@test JuMP.value(m._jump_model[Symbol("PXρHH")]) ≈ 0 # missing in GAMS DNestTest["CXHH","esubkl=0"]#  


# And now the Nested Version of the same model with the same results
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

# Comment out for nesting
# A = add!(m, Sector(:A)) # Armington composite
# PA = add!(m, Commodity(:PA)) #      ! Armington price index
# add!(m, Production(A, 0., :($sigmadm* 1.), [Output(PA, 90)], [Input(PD, 30), Input(PM, 60)]))
# add!(m, DemandFunction(GOVT, 1.,  [Demand(PX,20),Demand(PA, 90)],              [Endowment(RK, 110)])) # Non-Nested

# Nested Version
add!(m, DemandFunction(GOVT, 1.,  [Demand(PX,20),Demand(Nest(:CN,:($sigmadm*1.),90.,
                        [
                          Input(PD, 30),
                          Input(PM, 60)
                        ]
                                                             ),90.)],          [Endowment(RK, 110)])) # Nested

add!(m, Production(Y, :($t_elasy*1.), :($esubkl* 1.), [Output(PFX, 130), Output(PC, 60)], [Input(RK, 110), Input(PL, 80)]))
add!(m, Production(M, 0., 1., [Output(PX, 100)], [Input(PFX, 40), Input(PC, 60)]))
add!(m, DemandFunction(C, :(1*$sigmac),  [Demand(PFX, 90)],              [Endowment(PM, 60),Endowment(PD, 30)]))
add!(m, DemandFunction(HH, :(1*$sigma),  [Demand(PX, 80)], [Endowment(PL, :(80*$endow))])) #

solve!(m, cumulative_iteration_limit=0)

# Benchmark
@test JuMP.value(m._jump_model[:Y]) ≈ DNestTest["Y","Benchmark"]#  1
@test JuMP.value(m._jump_model[:M]) ≈ DNestTest["M","Benchmark"]#  1
@test JuMP.value(m._jump_model[:PC]) ≈ DNestTest["PC","Benchmark"]#  1
@test JuMP.value(m._jump_model[:PD]) ≈ DNestTest["PD","Benchmark"]#  1
@test JuMP.value(m._jump_model[:PM]) ≈ DNestTest["PM","Benchmark"]#  1
@test JuMP.value(m._jump_model[:PX]) ≈ DNestTest["PX","Benchmark"]#  1
@test JuMP.value(m._jump_model[:PL]) ≈ DNestTest["PL","Benchmark"]#  1
@test JuMP.value(m._jump_model[:RK]) ≈ DNestTest["RK","Benchmark"]#  1
@test JuMP.value(m._jump_model[:PFX]) ≈ DNestTest["PFX","Benchmark"]#  1
@test JuMP.value(m._jump_model[Symbol("PC‡Y")]) ≈ DNestTest["SCY","Benchmark"]#  60
@test JuMP.value(m._jump_model[Symbol("PFX‡Y")]) ≈ DNestTest["SFXY","Benchmark"]#  130
@test JuMP.value(m._jump_model[Symbol("PX‡M")]) ≈ DNestTest["SXM","Benchmark"]#  100
@test JuMP.value(m._jump_model[Symbol("RK†Y")]) ≈ DNestTest["DKY","Benchmark"]#  110
@test JuMP.value(m._jump_model[Symbol("PL†Y")]) ≈ DNestTest["DLY","Benchmark"]#  80
@test JuMP.value(m._jump_model[Symbol("PFX†M")]) ≈ DNestTest["DFXM","Benchmark"]#  40
@test JuMP.value(m._jump_model[:GOVT]) ≈ DNestTest["GOVT","Benchmark"]#  110
@test JuMP.value(m._jump_model[:HH]) ≈ DNestTest["HH","Benchmark"]#  80
@test JuMP.value(m._jump_model[:C]) ≈ DNestTest["C","Benchmark"]#  90
@test JuMP.value(m._jump_model[Symbol("PFXρC")]) ≈ DNestTest["CFXC","Benchmark"]#  90
@test JuMP.value(m._jump_model[Symbol("PXρGOVT")]) ≈ DNestTest["CXG","Benchmark"]#  20
@test JuMP.value(m._jump_model[Symbol("PXρHH")]) ≈ DNestTest["CXHH","Benchmark"]#  80

# endow=1.1
set_value(endow, 1.1)
set_fixed!(HH, true)
solve!(m)

@test JuMP.value(m._jump_model[:Y]) ≈ DNestTest["Y","endow=1.1"]#  1.04094672
@test JuMP.value(m._jump_model[:M]) ≈ DNestTest["M","endow=1.1"]#  1.04094672
@test JuMP.value(m._jump_model[:PC]) ≈ DNestTest["PC","endow=1.1"]#  0.96066397
@test JuMP.value(m._jump_model[:PD]) ≈ DNestTest["PD","endow=1.1"]#  1
@test JuMP.value(m._jump_model[:PM]) ≈ DNestTest["PM","endow=1.1"]#  1
@test JuMP.value(m._jump_model[:PX]) ≈ DNestTest["PX","endow=1.1"]#  0.96066397
@test JuMP.value(m._jump_model[:PL]) ≈ DNestTest["PL","endow=1.1"]#  0.90909091
@test JuMP.value(m._jump_model[:RK]) ≈ DNestTest["RK","endow=1.1"]#  1
@test JuMP.value(m._jump_model[:PFX]) ≈ DNestTest["PFX","endow=1.1"]#  0.96066397
@test JuMP.value(m._jump_model[Symbol("PC‡Y")]) ≈ DNestTest["SCY","endow=1.1"]#  60
@test JuMP.value(m._jump_model[Symbol("PFX‡Y")]) ≈ DNestTest["SFXY","endow=1.1"]#  130
@test JuMP.value(m._jump_model[Symbol("PX‡M")]) ≈ DNestTest["SXM","endow=1.1"]#  100
@test JuMP.value(m._jump_model[Symbol("RK†Y")]) ≈ DNestTest["DKY","endow=1.1"]#  105.673
@test JuMP.value(m._jump_model[Symbol("PL†Y")]) ≈ DNestTest["DLY","endow=1.1"]#  84.53842903
@test JuMP.value(m._jump_model[Symbol("PFX†M")]) ≈ DNestTest["DFXM","endow=1.1"]#  40
@test JuMP.value(m._jump_model[:GOVT]) ≈ DNestTest["GOVT","endow=1.1"]#  110
@test JuMP.value(m._jump_model[:HH]) ≈ DNestTest["HH","endow=1.1"]#  80
@test JuMP.value(m._jump_model[:C]) ≈ DNestTest["C","endow=1.1"]#  90
@test JuMP.value(m._jump_model[Symbol("PFXρC")]) ≈ DNestTest["CFXC","endow=1.1"]#  93.68520436
@test JuMP.value(m._jump_model[Symbol("PXρGOVT")]) ≈ DNestTest["CXG","endow=1.1"]#  20.8189343
@test JuMP.value(m._jump_model[Symbol("PXρHH")]) ≈ DNestTest["CXHH","endow=1.1"]#  83.2757372

# sigmac=0.5
set_value(sigmac, 0.5)
solve!(m)

@test JuMP.value(m._jump_model[:Y]) ≈ DNestTest["Y","sigmac=0.5"]#  1.04094672
@test JuMP.value(m._jump_model[:M]) ≈ DNestTest["M","sigmac=0.5"]#  1.04094672
@test JuMP.value(m._jump_model[:PC]) ≈ DNestTest["PC","sigmac=0.5"]#  0.96066397
@test JuMP.value(m._jump_model[:PD]) ≈ DNestTest["PD","sigmac=0.5"]#  1
@test JuMP.value(m._jump_model[:PM]) ≈ DNestTest["PM","sigmac=0.5"]#  1
@test JuMP.value(m._jump_model[:PX]) ≈ DNestTest["PX","sigmac=0.5"]#  0.96066397
@test JuMP.value(m._jump_model[:PL]) ≈ DNestTest["PL","sigmac=0.5"]#  0.90909091
@test JuMP.value(m._jump_model[:RK]) ≈ DNestTest["RK","sigmac=0.5"]#  1
@test JuMP.value(m._jump_model[:PFX]) ≈ DNestTest["PFX","sigmac=0.5"]#  0.96066397
@test JuMP.value(m._jump_model[Symbol("PC‡Y")]) ≈ DNestTest["SCY","sigmac=0.5"]#  60
@test JuMP.value(m._jump_model[Symbol("PFX‡Y")]) ≈ DNestTest["SFXY","sigmac=0.5"]#  130
@test JuMP.value(m._jump_model[Symbol("PX‡M")]) ≈ DNestTest["SXM","sigmac=0.5"]#  100
@test JuMP.value(m._jump_model[Symbol("RK†Y")]) ≈ DNestTest["DKY","sigmac=0.5"]#  105.673
@test JuMP.value(m._jump_model[Symbol("PL†Y")]) ≈ DNestTest["DLY","sigmac=0.5"]#  84.53842903
@test JuMP.value(m._jump_model[Symbol("PFX†M")]) ≈ DNestTest["DFXM","sigmac=0.5"]#  40
@test JuMP.value(m._jump_model[:GOVT]) ≈ DNestTest["GOVT","sigmac=0.5"]#  110
@test JuMP.value(m._jump_model[:HH]) ≈ DNestTest["HH","sigmac=0.5"]#  80
@test JuMP.value(m._jump_model[:C]) ≈ DNestTest["C","sigmac=0.5"]#  90
@test JuMP.value(m._jump_model[Symbol("PFXρC")]) ≈ DNestTest["CFXC","sigmac=0.5"]#  93.68520436
@test JuMP.value(m._jump_model[Symbol("PXρGOVT")]) ≈ DNestTest["CXG","sigmac=0.5"]#  20.8189343
@test JuMP.value(m._jump_model[Symbol("PXρHH")]) ≈ DNestTest["CXHH","sigmac=0.5"]#  83.2757372

# sigmadm=4
set_value(sigmadm,4.)
solve!(m)

@test JuMP.value(m._jump_model[:Y]) ≈ DNestTest["Y","sigmadm=4"]#  1.04094672
@test JuMP.value(m._jump_model[:M]) ≈ DNestTest["M","sigmadm=4"]#  1.04094672
@test JuMP.value(m._jump_model[:PC]) ≈ DNestTest["PC","sigmadm=4"]#  0.96066397
@test JuMP.value(m._jump_model[:PD]) ≈ DNestTest["PD","sigmadm=4"]#  1
@test JuMP.value(m._jump_model[:PM]) ≈ DNestTest["PM","sigmadm=4"]#  1
@test JuMP.value(m._jump_model[:PX]) ≈ DNestTest["PX","sigmadm=4"]#  0.96066397
@test JuMP.value(m._jump_model[:PL]) ≈ DNestTest["PL","sigmadm=4"]#  0.90909091
@test JuMP.value(m._jump_model[:RK]) ≈ DNestTest["RK","sigmadm=4"]#  1
@test JuMP.value(m._jump_model[:PFX]) ≈ DNestTest["PFX","sigmadm=4"]#  0.96066397
@test JuMP.value(m._jump_model[Symbol("PC‡Y")]) ≈ DNestTest["SCY","sigmadm=4"]#  60
@test JuMP.value(m._jump_model[Symbol("PFX‡Y")]) ≈ DNestTest["SFXY","sigmadm=4"]#  130
@test JuMP.value(m._jump_model[Symbol("PX‡M")]) ≈ DNestTest["SXM","sigmadm=4"]#  100
@test JuMP.value(m._jump_model[Symbol("RK†Y")]) ≈ DNestTest["DKY","sigmadm=4"]#  105.673
@test JuMP.value(m._jump_model[Symbol("PL†Y")]) ≈ DNestTest["DLY","sigmadm=4"]#  84.53842903
@test JuMP.value(m._jump_model[Symbol("PFX†M")]) ≈ DNestTest["DFXM","sigmadm=4"]#  40
@test JuMP.value(m._jump_model[:GOVT]) ≈ DNestTest["GOVT","sigmadm=4"]#  110
@test JuMP.value(m._jump_model[:HH]) ≈ DNestTest["HH","sigmadm=4"]#  80
@test JuMP.value(m._jump_model[:C]) ≈ DNestTest["C","sigmadm=4"]#  90
@test JuMP.value(m._jump_model[Symbol("PFXρC")]) ≈ DNestTest["CFXC","sigmadm=4"]#  93.68520436
@test JuMP.value(m._jump_model[Symbol("PXρGOVT")]) ≈ DNestTest["CXG","sigmadm=4"]#  20.8189343
@test JuMP.value(m._jump_model[Symbol("PXρHH")]) ≈ DNestTest["CXHH","sigmadm=4"]#  83.2757372

# sigma=0.4
set_value(sigma, 0.4)
solve!(m)

@test JuMP.value(m._jump_model[:Y]) ≈ DNestTest["Y","sigma=0.4"]#  1.04094672
@test JuMP.value(m._jump_model[:M]) ≈ DNestTest["M","sigma=0.4"]#  1.04094672
@test JuMP.value(m._jump_model[:PC]) ≈ DNestTest["PC","sigma=0.4"]#  0.96066397
@test JuMP.value(m._jump_model[:PD]) ≈ DNestTest["PD","sigma=0.4"]#  1
@test JuMP.value(m._jump_model[:PM]) ≈ DNestTest["PM","sigma=0.4"]#  1
@test JuMP.value(m._jump_model[:PX]) ≈ DNestTest["PX","sigma=0.4"]#  0.96066397
@test JuMP.value(m._jump_model[:PL]) ≈ DNestTest["PL","sigma=0.4"]#  0.90909091
@test JuMP.value(m._jump_model[:RK]) ≈ DNestTest["RK","sigma=0.4"]#  1
@test JuMP.value(m._jump_model[:PFX]) ≈ DNestTest["PFX","sigma=0.4"]#  0.96066397
@test JuMP.value(m._jump_model[Symbol("PC‡Y")]) ≈ DNestTest["SCY","sigma=0.4"]#  60
@test JuMP.value(m._jump_model[Symbol("PFX‡Y")]) ≈ DNestTest["SFXY","sigma=0.4"]#  130
@test JuMP.value(m._jump_model[Symbol("PX‡M")]) ≈ DNestTest["SXM","sigma=0.4"]#  100
@test JuMP.value(m._jump_model[Symbol("RK†Y")]) ≈ DNestTest["DKY","sigma=0.4"]#  105.673
@test JuMP.value(m._jump_model[Symbol("PL†Y")]) ≈ DNestTest["DLY","sigma=0.4"]#  84.53842903
@test JuMP.value(m._jump_model[Symbol("PFX†M")]) ≈ DNestTest["DFXM","sigma=0.4"]#  40
@test JuMP.value(m._jump_model[:GOVT]) ≈ DNestTest["GOVT","sigma=0.4"]#  110
@test JuMP.value(m._jump_model[:HH]) ≈ DNestTest["HH","sigma=0.4"]#  80
@test JuMP.value(m._jump_model[:C]) ≈ DNestTest["C","sigma=0.4"]#  90
@test JuMP.value(m._jump_model[Symbol("PFXρC")]) ≈ DNestTest["CFXC","sigma=0.4"]#  93.68520436
@test JuMP.value(m._jump_model[Symbol("PXρGOVT")]) ≈ DNestTest["CXG","sigma=0.4"]#  20.8189343
@test JuMP.value(m._jump_model[Symbol("PXρHH")]) ≈ DNestTest["CXHH","sigma=0.4"]#  83.2757372

# esubkl=1.5
set_value(esubkl, 1.5)
set_fixed!(GOVT, true)
set_fixed!(HH, false)
set_fixed!(C,true)
solve!(m)

@test JuMP.value(m._jump_model[:Y]) ≈ DNestTest["Y","esubkl=1.5"]#  1.04133159
@test JuMP.value(m._jump_model[:M]) ≈ DNestTest["M","esubkl=1.5"]#  1.0486808
@test JuMP.value(m._jump_model[:PC]) ≈ DNestTest["PC","esubkl=1.5"]#  0.98510801
@test JuMP.value(m._jump_model[:PD]) ≈ DNestTest["PD","esubkl=1.5"]#  1
@test JuMP.value(m._jump_model[:PM]) ≈ DNestTest["PM","esubkl=1.5"]#  1
@test JuMP.value(m._jump_model[:PX]) ≈ DNestTest["PX","esubkl=1.5"]#  0.97820432
@test JuMP.value(m._jump_model[:PL]) ≈ DNestTest["PL","esubkl=1.5"]#  0.93843647
@test JuMP.value(m._jump_model[:RK]) ≈ DNestTest["RK","esubkl=1.5"]#  1
@test JuMP.value(m._jump_model[:PFX]) ≈ DNestTest["PFX","esubkl=1.5"]#  0.9679394
@test JuMP.value(m._jump_model[Symbol("PC‡Y")]) ≈ DNestTest["SCY","esubkl=1.5"]#  60
@test JuMP.value(m._jump_model[Symbol("PFX‡Y")]) ≈ DNestTest["SFXY","esubkl=1.5"]#  130
@test JuMP.value(m._jump_model[Symbol("PX‡M")]) ≈ DNestTest["SXM","esubkl=1.5"]#  100
@test JuMP.value(m._jump_model[Symbol("RK†Y")]) ≈ DNestTest["DKY","esubkl=1.5"]#  105.634
@test JuMP.value(m._jump_model[Symbol("PL†Y")]) ≈ DNestTest["DLY","esubkl=1.5"]#  84.50718369
@test JuMP.value(m._jump_model[Symbol("PFX†M")]) ≈ DNestTest["DFXM","esubkl=1.5"]#  40.42419695
@test JuMP.value(m._jump_model[:GOVT]) ≈ DNestTest["GOVT","esubkl=1.5"]#  110
@test JuMP.value(m._jump_model[:HH]) ≈ DNestTest["HH","esubkl=1.5"]#  82.58240924
@test JuMP.value(m._jump_model[:C]) ≈ DNestTest["C","esubkl=1.5"]#  90
@test JuMP.value(m._jump_model[Symbol("PFXρC")]) ≈ DNestTest["CFXC","esubkl=1.5"]#  92.98102756
@test JuMP.value(m._jump_model[Symbol("PXρGOVT")]) ≈ DNestTest["CXG","esubkl=1.5"]#  20.44562626
@test JuMP.value(m._jump_model[Symbol("PXρHH")]) ≈ DNestTest["CXHH","esubkl=1.5"]#  84.42245376

# t_elasY=1
set_value(t_elasy, 1.)
set_fixed!(C,false)
solve!(m)

@test JuMP.value(m._jump_model[:Y]) ≈ DNestTest["Y","t_elasY=1"]#  1.04133159
@test JuMP.value(m._jump_model[:M]) ≈ DNestTest["M","t_elasY=1"]#  1.05128658
@test JuMP.value(m._jump_model[:PC]) ≈ DNestTest["PC","t_elasY=1"]#  0.97921692
@test JuMP.value(m._jump_model[:PD]) ≈ DNestTest["PD","t_elasY=1"]#  1
@test JuMP.value(m._jump_model[:PM]) ≈ DNestTest["PM","t_elasY=1"]#  1
@test JuMP.value(m._jump_model[:PX]) ≈ DNestTest["PX","t_elasY=1"]#  0.97577969
@test JuMP.value(m._jump_model[:PL]) ≈ DNestTest["PL","t_elasY=1"]#  0.93843647
@test JuMP.value(m._jump_model[:RK]) ≈ DNestTest["RK","t_elasY=1"]#  1
@test JuMP.value(m._jump_model[:PFX]) ≈ DNestTest["PFX","t_elasY=1"]#  0.97064645
@test JuMP.value(m._jump_model[Symbol("PC‡Y")]) ≈ DNestTest["SCY","t_elasY=1"]#  60.36096719
@test JuMP.value(m._jump_model[Symbol("PFX‡Y")]) ≈ DNestTest["SFXY","t_elasY=1"]#  129.6374
@test JuMP.value(m._jump_model[Symbol("PX‡M")]) ≈ DNestTest["SXM","t_elasY=1"]#  100
@test JuMP.value(m._jump_model[Symbol("RK†Y")]) ≈ DNestTest["DKY","t_elasY=1"]#  105.634
@test JuMP.value(m._jump_model[Symbol("PL†Y")]) ≈ DNestTest["DLY","t_elasY=1"]#  84.50718369
@test JuMP.value(m._jump_model[Symbol("PFX†M")]) ≈ DNestTest["DFXM","t_elasY=1"]#  40.21153908
@test JuMP.value(m._jump_model[:GOVT]) ≈ DNestTest["GOVT","t_elasY=1"]#  110
@test JuMP.value(m._jump_model[:HH]) ≈ DNestTest["HH","t_elasY=1"]#  82.58240907
@test JuMP.value(m._jump_model[:C]) ≈ DNestTest["C","t_elasY=1"]#  90
@test JuMP.value(m._jump_model[Symbol("PFXρC")]) ≈ DNestTest["CFXC","t_elasY=1"]#  92.72171175
@test JuMP.value(m._jump_model[Symbol("PXρGOVT")]) ≈ DNestTest["CXG","t_elasY=1"]#  20.49642989
@test JuMP.value(m._jump_model[Symbol("PXρHH")]) ≈ DNestTest["CXHH","t_elasY=1"]#  84.63222806

# endow=2
set_value(endow, 2.)
solve!(m)

@test JuMP.value(m._jump_model[:Y]) ≈ DNestTest["Y","endow=2"]#  1.36556375
@test JuMP.value(m._jump_model[:M]) ≈ DNestTest["M","endow=2"]#  1.46151811
@test JuMP.value(m._jump_model[:PC]) ≈ DNestTest["PC","endow=2"]#  0.84773894
@test JuMP.value(m._jump_model[:PD]) ≈ DNestTest["PD","endow=2"]#  1
@test JuMP.value(m._jump_model[:PM]) ≈ DNestTest["PM","endow=2"]#  1
@test JuMP.value(m._jump_model[:PX]) ≈ DNestTest["PX","endow=2"]#  0.82649461
@test JuMP.value(m._jump_model[:PL]) ≈ DNestTest["PL","endow=2"]#  0.62996052
@test JuMP.value(m._jump_model[:RK]) ≈ DNestTest["RK","endow=2"]#  1
@test JuMP.value(m._jump_model[:PFX]) ≈ DNestTest["PFX","endow=2"]#  0.79562215
@test JuMP.value(m._jump_model[Symbol("PC‡Y")]) ≈ DNestTest["SCY","endow=2"]#  62.60677993
@test JuMP.value(m._jump_model[Symbol("PFX‡Y")]) ≈ DNestTest["SFXY","endow=2"]#  127.3087
@test JuMP.value(m._jump_model[Symbol("PX‡M")]) ≈ DNestTest["SXM","endow=2"]#  100
@test JuMP.value(m._jump_model[Symbol("RK†Y")]) ≈ DNestTest["DKY","endow=2"]#  80.55281206
@test JuMP.value(m._jump_model[Symbol("PL†Y")]) ≈ DNestTest["DLY","endow=2"]#  117.1677
@test JuMP.value(m._jump_model[Symbol("PFX†M")]) ≈ DNestTest["DFXM","endow=2"]#  41.55211657
@test JuMP.value(m._jump_model[:GOVT]) ≈ DNestTest["GOVT","endow=2"]#  110
@test JuMP.value(m._jump_model[:HH]) ≈ DNestTest["HH","endow=2"]#  100.7937
@test JuMP.value(m._jump_model[:C]) ≈ DNestTest["C","endow=2"]#  90
@test JuMP.value(m._jump_model[Symbol("PFXρC")]) ≈ DNestTest["CFXC","endow=2"]#  113.119
@test JuMP.value(m._jump_model[Symbol("PXρGOVT")]) ≈ DNestTest["CXG","endow=2"]#  24.19858498
@test JuMP.value(m._jump_model[Symbol("PXρHH")]) ≈ DNestTest["CXHH","endow=2"]#  121.9532

# sigmac=4
set_value(sigmac, 4.)
solve!(m)

@test JuMP.value(m._jump_model[:Y]) ≈ DNestTest["Y","sigmac=4"]#  1.36556375
@test JuMP.value(m._jump_model[:M]) ≈ DNestTest["M","sigmac=4"]#  1.46151811
@test JuMP.value(m._jump_model[:PC]) ≈ DNestTest["PC","sigmac=4"]#  0.84773894
@test JuMP.value(m._jump_model[:PD]) ≈ DNestTest["PD","sigmac=4"]#  1
@test JuMP.value(m._jump_model[:PM]) ≈ DNestTest["PM","sigmac=4"]#  1
@test JuMP.value(m._jump_model[:PX]) ≈ DNestTest["PX","sigmac=4"]#  0.82649461
@test JuMP.value(m._jump_model[:PL]) ≈ DNestTest["PL","sigmac=4"]#  0.62996052
@test JuMP.value(m._jump_model[:RK]) ≈ DNestTest["RK","sigmac=4"]#  1
@test JuMP.value(m._jump_model[:PFX]) ≈ DNestTest["PFX","sigmac=4"]#  0.79562215
@test JuMP.value(m._jump_model[Symbol("PC‡Y")]) ≈ DNestTest["SCY","sigmac=4"]#  62.60677993
@test JuMP.value(m._jump_model[Symbol("PFX‡Y")]) ≈ DNestTest["SFXY","sigmac=4"]#  127.3087
@test JuMP.value(m._jump_model[Symbol("PX‡M")]) ≈ DNestTest["SXM","sigmac=4"]#  100
@test JuMP.value(m._jump_model[Symbol("RK†Y")]) ≈ DNestTest["DKY","sigmac=4"]#  80.55281206
@test JuMP.value(m._jump_model[Symbol("PL†Y")]) ≈ DNestTest["DLY","sigmac=4"]#  117.1677
@test JuMP.value(m._jump_model[Symbol("PFX†M")]) ≈ DNestTest["DFXM","sigmac=4"]#  41.55211657
@test JuMP.value(m._jump_model[:GOVT]) ≈ DNestTest["GOVT","sigmac=4"]#  110
@test JuMP.value(m._jump_model[:HH]) ≈ DNestTest["HH","sigmac=4"]#  100.7937
@test JuMP.value(m._jump_model[:C]) ≈ DNestTest["C","sigmac=4"]#  90
@test JuMP.value(m._jump_model[Symbol("PFXρC")]) ≈ DNestTest["CFXC","sigmac=4"]#  113.119
@test JuMP.value(m._jump_model[Symbol("PXρGOVT")]) ≈ DNestTest["CXG","sigmac=4"]#  24.19858498
@test JuMP.value(m._jump_model[Symbol("PXρHH")]) ≈ DNestTest["CXHH","sigmac=4"]#  121.9532

# sigma=3
set_value(sigma, 3.)
solve!(m)

@test JuMP.value(m._jump_model[:Y]) ≈ DNestTest["Y","sigma=3"]#  1.36556375
@test JuMP.value(m._jump_model[:M]) ≈ DNestTest["M","sigma=3"]#  1.46151811
@test JuMP.value(m._jump_model[:PC]) ≈ DNestTest["PC","sigma=3"]#  0.84773894
@test JuMP.value(m._jump_model[:PD]) ≈ DNestTest["PD","sigma=3"]#  1
@test JuMP.value(m._jump_model[:PM]) ≈ DNestTest["PM","sigma=3"]#  1
@test JuMP.value(m._jump_model[:PX]) ≈ DNestTest["PX","sigma=3"]#  0.82649461
@test JuMP.value(m._jump_model[:PL]) ≈ DNestTest["PL","sigma=3"]#  0.62996052
@test JuMP.value(m._jump_model[:RK]) ≈ DNestTest["RK","sigma=3"]#  1
@test JuMP.value(m._jump_model[:PFX]) ≈ DNestTest["PFX","sigma=3"]#  0.79562215
@test JuMP.value(m._jump_model[Symbol("PC‡Y")]) ≈ DNestTest["SCY","sigma=3"]#  62.60677993
@test JuMP.value(m._jump_model[Symbol("PFX‡Y")]) ≈ DNestTest["SFXY","sigma=3"]#  127.3087
@test JuMP.value(m._jump_model[Symbol("PX‡M")]) ≈ DNestTest["SXM","sigma=3"]#  100
@test JuMP.value(m._jump_model[Symbol("RK†Y")]) ≈ DNestTest["DKY","sigma=3"]#  80.55281206
@test JuMP.value(m._jump_model[Symbol("PL†Y")]) ≈ DNestTest["DLY","sigma=3"]#  117.1677
@test JuMP.value(m._jump_model[Symbol("PFX†M")]) ≈ DNestTest["DFXM","sigma=3"]#  41.55211657
@test JuMP.value(m._jump_model[:GOVT]) ≈ DNestTest["GOVT","sigma=3"]#  110
@test JuMP.value(m._jump_model[:HH]) ≈ DNestTest["HH","sigma=3"]#  100.7937
@test JuMP.value(m._jump_model[:C]) ≈ DNestTest["C","sigma=3"]#  90
@test JuMP.value(m._jump_model[Symbol("PFXρC")]) ≈ DNestTest["CFXC","sigma=3"]#  113.119
@test JuMP.value(m._jump_model[Symbol("PXρGOVT")]) ≈ DNestTest["CXG","sigma=3"]#  24.19858498
@test JuMP.value(m._jump_model[Symbol("PXρHH")]) ≈ DNestTest["CXHH","sigma=3"]#  121.9532

set_value(t_elasy,0.5)
solve!(m)

@test JuMP.value(m._jump_model[:Y]) ≈ DNestTest["Y","t_elY=0.5"]#  1.36556375
@test JuMP.value(m._jump_model[:M]) ≈ DNestTest["M","t_elY=0.5"]#  1.45318709
@test JuMP.value(m._jump_model[:PC]) ≈ DNestTest["PC","t_elY=0.5"]#  0.85984236
@test JuMP.value(m._jump_model[:PD]) ≈ DNestTest["PD","t_elY=0.5"]#  1
@test JuMP.value(m._jump_model[:PM]) ≈ DNestTest["PM","t_elY=0.5"]#  1
@test JuMP.value(m._jump_model[:PX]) ≈ DNestTest["PX","t_elY=0.5"]#  0.83123284
@test JuMP.value(m._jump_model[:PL]) ≈ DNestTest["PL","t_elY=0.5"]#  0.62996052
@test JuMP.value(m._jump_model[:RK]) ≈ DNestTest["RK","t_elY=0.5"]#  1
@test JuMP.value(m._jump_model[:PFX]) ≈ DNestTest["PFX","t_elY=0.5"]#  0.79009349
@test JuMP.value(m._jump_model[Symbol("PC‡Y")]) ≈ DNestTest["SCY","t_elY=0.5"]#  61.7255064
@test JuMP.value(m._jump_model[Symbol("PFX‡Y")]) ≈ DNestTest["SFXY","t_elY=0.5"]#  128.1996
@test JuMP.value(m._jump_model[Symbol("PX‡M")]) ≈ DNestTest["SXM","t_elY=0.5"]#  100
@test JuMP.value(m._jump_model[Symbol("RK†Y")]) ≈ DNestTest["DKY","t_elY=0.5"]#  80.55281207
@test JuMP.value(m._jump_model[Symbol("PL†Y")]) ≈ DNestTest["DLY","t_elY=0.5"]#  117.1677
@test JuMP.value(m._jump_model[Symbol("PFX†M")]) ≈ DNestTest["DFXM","t_elY=0.5"]#  42.08275888
@test JuMP.value(m._jump_model[:GOVT]) ≈ DNestTest["GOVT","t_elY=0.5"]#  110
@test JuMP.value(m._jump_model[:HH]) ≈ DNestTest["HH","t_elY=0.5"]#  100.7937
@test JuMP.value(m._jump_model[:C]) ≈ DNestTest["C","t_elY=0.5"]#  90
@test JuMP.value(m._jump_model[Symbol("PFXρC")]) ≈ DNestTest["CFXC","t_elY=0.5"]#  113.9106
@test JuMP.value(m._jump_model[Symbol("PXρGOVT")]) ≈ DNestTest["CXG","t_elY=0.5"]#  24.06064697
@test JuMP.value(m._jump_model[Symbol("PXρHH")]) ≈ DNestTest["CXHH","t_elY=0.5"]#  121.2581

# sigmac=.1
set_value(sigmac, 0.1)
solve!(m)

@test JuMP.value(m._jump_model[:Y]) ≈ DNestTest["Y","sigmac=.1"]#  1.36556375
@test JuMP.value(m._jump_model[:M]) ≈ DNestTest["M","sigmac=.1"]#  1.45318709
@test JuMP.value(m._jump_model[:PC]) ≈ DNestTest["PC","sigmac=.1"]#  0.85984236
@test JuMP.value(m._jump_model[:PD]) ≈ DNestTest["PD","sigmac=.1"]#  1
@test JuMP.value(m._jump_model[:PM]) ≈ DNestTest["PM","sigmac=.1"]#  1
@test JuMP.value(m._jump_model[:PX]) ≈ DNestTest["PX","sigmac=.1"]#  0.83123284
@test JuMP.value(m._jump_model[:PL]) ≈ DNestTest["PL","sigmac=.1"]#  0.62996052
@test JuMP.value(m._jump_model[:RK]) ≈ DNestTest["RK","sigmac=.1"]#  1
@test JuMP.value(m._jump_model[:PFX]) ≈ DNestTest["PFX","sigmac=.1"]#  0.79009349
@test JuMP.value(m._jump_model[Symbol("PC‡Y")]) ≈ DNestTest["SCY","sigmac=.1"]#  61.7255064
@test JuMP.value(m._jump_model[Symbol("PFX‡Y")]) ≈ DNestTest["SFXY","sigmac=.1"]#  128.1996
@test JuMP.value(m._jump_model[Symbol("PX‡M")]) ≈ DNestTest["SXM","sigmac=.1"]#  100
@test JuMP.value(m._jump_model[Symbol("RK†Y")]) ≈ DNestTest["DKY","sigmac=.1"]#  80.55281207
@test JuMP.value(m._jump_model[Symbol("PL†Y")]) ≈ DNestTest["DLY","sigmac=.1"]#  117.1677
@test JuMP.value(m._jump_model[Symbol("PFX†M")]) ≈ DNestTest["DFXM","sigmac=.1"]#  42.08275888
@test JuMP.value(m._jump_model[:GOVT]) ≈ DNestTest["GOVT","sigmac=.1"]#  110
@test JuMP.value(m._jump_model[:HH]) ≈ DNestTest["HH","sigmac=.1"]#  100.7937
@test JuMP.value(m._jump_model[:C]) ≈ DNestTest["C","sigmac=.1"]#  90
@test JuMP.value(m._jump_model[Symbol("PFXρC")]) ≈ DNestTest["CFXC","sigmac=.1"]#  113.9106
@test JuMP.value(m._jump_model[Symbol("PXρGOVT")]) ≈ DNestTest["CXG","sigmac=.1"]#  24.06064697
@test JuMP.value(m._jump_model[Symbol("PXρHH")]) ≈ DNestTest["CXHH","sigmac=.1"]#  121.2581


#This fails for most variables. The GAMS results has gaps/undefined/no value for PL, HH, and CXHH. This suggests we are not handling results with /0 or 0 results in the same way
set_fixed!(C,true)
set_lower_bound(HH, 0.0)
set_lower_bound(PL, 0.0)
set_value(esubkl, 0.)
solve!(m)
@test JuMP.value(m._jump_model[:Y]) ≈ DNestTest["Y","esubkl=0"]#  1
@test JuMP.value(m._jump_model[:M]) ≈ DNestTest["M","esubkl=0"]#  0.49256427
@test JuMP.value(m._jump_model[:PC]) ≈ DNestTest["PC","esubkl=0"]#  0.28503598
@test JuMP.value(m._jump_model[:PD]) ≈ DNestTest["PD","esubkl=0"]#  1
@test JuMP.value(m._jump_model[:PM]) ≈ DNestTest["PM","esubkl=0"]#  1
@test JuMP.value(m._jump_model[:PX]) ≈ DNestTest["PX","esubkl=0"]#  0.40603838
@test JuMP.value(m._jump_model[:PL]) ≈0 # missing in GAMS DNestTest["PL","esubkl=0"]#  
@test JuMP.value(m._jump_model[:RK]) ≈ DNestTest["RK","esubkl=0"]#  1
@test JuMP.value(m._jump_model[:PFX]) ≈ DNestTest["PFX","esubkl=0"]#  0.69034817
@test JuMP.value(m._jump_model[Symbol("PC‡Y")]) ≈ DNestTest["SCY","esubkl=0"]#  42.09994749
@test JuMP.value(m._jump_model[Symbol("PFX‡Y")]) ≈ DNestTest["SFXY","esubkl=0"]#  141.9574
@test JuMP.value(m._jump_model[Symbol("PX‡M")]) ≈ DNestTest["SXM","esubkl=0"]#  100
@test JuMP.value(m._jump_model[Symbol("RK†Y")]) ≈ DNestTest["DKY","esubkl=0"]#  110
@test JuMP.value(m._jump_model[Symbol("PL†Y")]) ≈ DNestTest["DLY","esubkl=0"]#  80
@test JuMP.value(m._jump_model[Symbol("PFX†M")]) ≈ DNestTest["DFXM","esubkl=0"]#  23.52658546
@test JuMP.value(m._jump_model[:GOVT]) ≈ DNestTest["GOVT","esubkl=0"]#  110
@test JuMP.value(m._jump_model[:HH]) ≈ 0  # missing in GAMS DNestTest["HH","esubkl=0"]#  
@test JuMP.value(m._jump_model[:C]) ≈ DNestTest["C","esubkl=0"]#  90
@test JuMP.value(m._jump_model[Symbol("PFXρC")]) ≈ DNestTest["CFXC","esubkl=0"]#  130.369
@test JuMP.value(m._jump_model[Symbol("PXρGOVT")]) ≈ DNestTest["CXG","esubkl=0"]#  49.25642749
@test JuMP.value(m._jump_model[Symbol("PXρHH")]) ≈ 0 # missing in GAMS DNestTest["CXHH","esubkl=0"]#  

end