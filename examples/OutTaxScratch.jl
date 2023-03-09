using MPSGE
using MPSGE.JuMP.Containers

m = Model()
    
    consumers = [:a, :b]
    consumption = DenseAxisArray(Float64[75, 75], consumers)

    esub_x = add!(m, Parameter(:esub_x, value=1.0))    
    esub_y = add!(m, Parameter(:esub_y, value=1.0))    
    endow  = add!(m, Parameter(:endow, value=1.0))
    Otax   = add!(m, Parameter(:Otax, value = 0.0))
    
    X = add!(m, Sector(:X))
    Y = add!(m, Sector(:Y))
    U = add!(m, Sector(:U))
    
    PX = add!(m, Commodity(:PX))
    PY = add!(m, Commodity(:PY))
    PU = add!(m, Commodity(:PU))
    PL = add!(m, Commodity(:PL))
    PK = add!(m, Commodity(:PK))

    RA = add!(m, Consumer(:RA, indices=(consumers,), benchmark=75.))#(consumption)))

    
    # RAA = add!(m, Consumer(:RAA, benchmark = 75.))
    # RAB = add!(m, Consumer(:RAB, benchmark = 75.))
 
    # @production(m, X, 0, :($esub_x*1.0), [Output(PX, 100., [MPSGE.Tax(:($Otax*1.0), RAA)])], [Input(PL, 50.), Input(PK,50.)])
    @production(m, X, 0, :($esub_x*1.0), [Output(PX, 100., [MPSGE.Tax(:($Otax*1.0), RA[:a])])], [Input(PL, 50.), Input(PK,50.)])
    # @production(m, Y, 0, :($esub_y*1.0), [Output(PY, 50.)], [Input(PL, 20.), Input(PK,30.)])
    @production(m, Y, 0, :($esub_y*1.0), [Output(PY, 50.,  [MPSGE.Tax(:($Otax*1.0), RA[:b])])], [Input(PL, 20.), Input(PK,30.)])
    # @production(m, Y, 0, :($esub_y*1.0), [Output(PY, 50.,  [MPSGE.Tax(:($Otax*1.0), RAB)])], [Input(PL, 20.), Input(PK,30.)])

    @production(m, U, 0, 1.0, [Output(PU, 150.)], [Input(PX, 100.), Input(PY,50.)])

    for r in consumers
        @demand(m, RA[r], 1., [Demand(PU, 75. )], [Endowment(PL, :(35. * $(endow))), Endowment(PK, 40)])
    end
   
    # @demand(m, RAA, 1., [Demand(PU, 75. )], [Endowment(PL, :(35. * $(endow))), Endowment(PK, 40)])
    # @demand(m, RAB, 1., [Demand(PU, 75. )], [Endowment(PL, :(35. * $(endow))), Endowment(PK, 40)])

    solve!(m, cumulative_iteration_limit=0)

    # set_fixed!(RA, true) # Set Consumer as the numeraire

    set_value(endow, 1.1)
    set_fixed!(RA[:a], true)
    set_fixed!(RA[:b], true)
    solve!(m)

    
    set_fixed!(RA[:a], false)
    set_fixed!(RA[:b], false) 
    set_fixed!(PX, true)
    solve!(m)

    set_fixed!(PX, false)
    set_fixed!(PL, true)
    solve!(m)
# Just a re-set for testing, so no need to re-run model
    # set_value(Otax, 0.0)
    # solve!(m)

    set_value(Otax, 0.1)
    solve!(m)

    set_value(Otax, 0.2)
    solve!(m)

    set_value(Otax, 0.5)
    solve!(m)

    set_value(Otax, 0.9)
    solve!(m)
