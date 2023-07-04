using MPSGE

using XLSX, MPSGE.JuMP.Containers
    
    m = Model()
    goods = [:x, :y]
    factors = [:l, :k]
    consumers = [:ra]
    factor = DenseAxisArray(Float64[50 50; 20 30], goods, factors)
    supply = DenseAxisArray(Float64[100, 50], goods)
    # pricepci = DenseAxisArray(Float64[1., 1.], goods)
    pricepci = add!(m, Parameter(:pricepci, indices=(goods,), value=1.))#value=DenseAxisArray(Float64[1., 1.])))
    endow    = add!(m, Parameter(:endow, indices=(factors,), value=1.0)) 
    
    Y = add!(m, Sector(:Y, indices=(goods,)))
    U = add!(m, Sector(:U))
    PC = add!(m, Commodity(:PC, indices=(goods,)))
    PU = add!(m, Commodity(:PU))
    PF = add!(m, Commodity(:PF, indices=(factors,)))
    C = add!(m, Consumer(:C, indices=(consumers,), benchmark=150.))

    for i in goods
        @production(m, Y[i], 0, 1, [Output(PC[i], supply[i])], [Input(PF[:l], factor[i,:l]), Input(PF[:k], factor[i,:k])])
    end
    
    add!(m, Production(U, 0., 1.0, [Output(PU, 150)], [Input(PC[i], supply[i], [Tax(0.,C[:ra])], :($(pricepci[i])*1.)) for i in goods]))
    # add!(m, Production(U, 0., 1.0, [Output(PU, 150)], [
    #     Input(
    #         Nest(
    #             :PCi,
    #              1.,
    #               150.,
    #               [
    #                 Input(PC[i], supply[i], [Tax(0.,C[:ra])], :($(pricepci[i])*1.)) for i in goods
    #                 ]
    #                 ), 150
    #                 )
    #                                                 ]
    # ))

    @demand(m, C[:ra], 1., [Demand(PU, 150)], [Endowment(PF[:l], :(70 * $(endow[:l]))), Endowment(PF[:k], :(80. * $(endow[:k])))])

solve!(m, cumulative_iteration_limit=0)

set_value(endow[:l], get_value(endow[:l])*1.1)
set_value(C[:ra], 157.)
set_fixed!(C[:ra], true)
solve!(m)

set_fixed!(C[:ra], false)
set_fixed!(PC[:x], true)
solve!(m)

set_fixed!(PC[:x], false)
set_fixed!(PF[:l], true)
solve!(m)

set_value(pricepci[:x] , 2.)
solve!(m)






# m = Model()
# endow  = add!(m, Parameter(:endow, value=1.))
# esub_x = add!(m, Parameter(:esub_x, value=1.))
# esub_y=add!(m, Parameter(:esub_y, value=1.))
# esub_u=add!(m, Parameter(:esub_u, value=1.))
# esub_ra=add!(m, Parameter(:esub_ra, value=1.))
# pr_U = add!(m, Parameter(:pr_U, value=1.0))
# pr_Ud=add!(m, Parameter(:pr_Ud, value=1.0))
# otax=add!(m, Parameter(:otax, value=0.))
# itax=add!(m, Parameter(:itax, value=0.))

# X = add!(m, Sector(:X))
# Y = add!(m, Sector(:Y))
# U = add!(m, Sector(:U))

# PX = add!(m, Commodity(:PX))
# PY = add!(m, Commodity(:PY))
# PU = add!(m, Commodity(:PU))
# PL = add!(m, Commodity(:PL))#, benchmark=1.2))
# PK = add!(m, Commodity(:PK))

# RA = add!(m, Consumer(:RA, benchmark=134.))

# add!(m, Production(X, 0, :(1.0 * $esub_x), [Output(PX, 80, [Tax(:($otax*1.),RA)])], [Input(PL, 30, [Tax(:($itax*1.),RA)]), Input(PK, 50)]))
# # add!(m, Production(Y, 0, :(1.0 * $esub_y), [Output(PY, 54)], [Input(PL, 20), Input(PK, 30)]))
# # add!(m, Production(Y, 0, :(1.0 * $esub_y), [Output(PY, 54)],                         [Input(PL, 20, [Tax(:($itax*1.),RA)], 1.2), Input(PK, 30)]))
# add!(m, Production(Y, 0, :(1.0 * $esub_y), [Output(PY, 54)], [Input(PL, 24,), Input(PK, 30)]))
# add!(m, Production(U, 0, :(1.0 * $esub_u), [Output(PU, 124., [Tax(0.,RA)], :($pr_U*1.))], [Input(PX, 80), Input(PY, 44)]))

# add!(m, DemandFunction(RA, :($esub_ra*1.), [Demand(PU,124., :($pr_Ud*1.)), Demand(PY,10, 1.0)], [Endowment(PL, :(54. *$endow)), Endowment(PK, 80)]))

# set_fixed!(PU,true)
# # solve!(m, cumulative_iteration_limit=0)

# set_value(endow,1.1)

# # set_value(esub_ra, 0.6)
# # set_value(pr_Ud, 3.)
# # set_value(esub_ra, .5)
# # set_value(pr_Ud,  2.)
# set_value(pr_Ud, 0.5)
# # set_value(esub_ra, 0.6)
# set_value(esub_ra, 0.0)
# # set_value(RA, 139.2024749)
# # set_fixed!(RA, true)
# solve!(m)




# m = Model()

# sigmac = add!(m, Parameter(:sigmac, value=1.)) #  Armington elasticity in final demand /0.5/
# endow = add!(m, Parameter(:endow, value=1.)) #       change in labour supply      /1/
# sigmadm = add!(m, Parameter(:sigmadm, value=1.)) #    Elasticity of substitution (D versus M) /4/
# esubkl = add!(m, Parameter(:esubkl, value=1.)) #     Elasticity of substitution (K versus L) /1/
# t_elasy = add!(m, Parameter(:t_elasy, value=0.))
# sigma = add!(m, Parameter(:sigma, value=1.)) #      Elasticity of substitution (C versus LS) /0.4/;

# Y = add!(m, Sector(:Y)) #Production
# M = add!(m, Sector(:M)) # Imports

# PX = add!(m, Commodity(:PX)) # 
# PC = add!(m, Commodity(:PC)) # 
# PM = add!(m, Commodity(:PM)) #      ! Import price index
# PL = add!(m, Commodity(:PL)) #      ! Wage rate index
# RK = add!(m, Commodity(:RK)) #      ! Rental price index
# PFX = add!(m, Commodity(:PFX)) #     ! Foreign exchange
# PD = add!(m, Commodity(:PD)) #      ! Domestic price index

# C  = add!(m, Consumer(:C, benchmark=90.))
# GOVT  = add!(m, Consumer(:GOVT, benchmark=110.))
# HH = add!(m, Consumer(:HH, benchmark=80.)) #      ! Private households

# # Comments out for nesting
# A = add!(m, Sector(:A)) # Armington composite
# PA = add!(m, Commodity(:PA)) #      ! Armington price index
# add!(m, Production(A, 0., :($sigmadm* 1.), [Output(PA, 90)], [Input(PD, 30), Input(PM, 60)]))
# # Alternates for Nested
# add!(m, DemandFunction(GOVT, 1.,  [Demand(PX,20),Demand(PA, 90)],              [Endowment(RK, 110)])) # Non-Nested
# #Nested Vesion
# # add!(m, DemandFunction(GOVT, 1.,  [Demand(PX,20),Demand(Nest(:CN,:($sigmadm*1.),90.,
# #                         [
# #                           Input(PD, 30),
# #                           Input(PM, 60)
# #                         ]
# #                                                              ),90.)],          [Endowment(RK, 110)])) # Nested

# add!(m, Production(Y, :($t_elasy*1.), :($esubkl* 1.), [Output(PFX, 130), Output(PC, 60)], [Input(RK, 110), Input(PL, 80)]))
# add!(m, Production(M, 0., 1., [Output(PX, 100)], [Input(PFX, 40), Input(PC, 60)]))
# add!(m, DemandFunction(C, :(1*$sigmac),  [Demand(PFX, 90)],              [Endowment(PM, 60),Endowment(PD, 30)]))
# add!(m, DemandFunction(HH, :(1*$sigma),  [Demand(PX, 80)], [Endowment(PL, :(80*$endow))])) #

# set_value(endow, 1.1)
# # set_fixed!(HH, true)
# # solve!(m)

# set_value(sigmac, 0.5)
# # solve!(m)

# set_value(sigmadm,4.)
# # solve!(m)

# set_value(sigma, 0.4)
# # solve!(m)

# set_value(esubkl, 1.5)
# set_fixed!(HH, false)
# set_fixed!(GOVT, true)
# # set_fixed!(C,true)
# # solve!(m)

# set_value(t_elasy, 1.)
# # set_fixed!(C,false)
# # solve!(m)

# set_value(endow, 2.)
# # solve!(m)

# set_value(sigmac, 4.)
# # solve!(m)

# set_value(sigma, 3.)
# # solve!(m)

# set_value(t_elasy,0.5)
# # solve!(m)

# set_value(sigmac, 0.1)
# # solve!(m)
# # set_lower_bound(PL, 0.0)
# set_value(esubkl, 0.)
# solve!(m) 

# solve!(m, cumulative_iteration_limit=0)
# set_fixed!(GOVT, true)
# set_value(sigmadm,4.)
# set_value(endow, 2.)
# set_value(esubkl, 1.5)
# solve!(m)
# set_value(sigma, 3.)
# set_value(t_elasy,0.5)
# set_value(sigmac, 1.)

# set_value(esubkl, 0.)
# solve!(m)
# algebraic_version(m)