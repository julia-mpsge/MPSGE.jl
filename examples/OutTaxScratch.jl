using MPSGE

m = Model()
    
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
    
    RA = add!(m, Consumer(:RA, benchmark = 150.))
 
    @production(m, X, 0, :($esub_x*1.0), [Output(PX, 100., [MPSGE.Tax(:($Otax*1.0), RA)])], [Input(PL, 50.), Input(PK,50.)])
    @production(m, Y, 0, :($esub_y*1.0), [Output(PY, 50.)], [Input(PL, 20.), Input(PK,30.)])
    # @production(m, Y, 0, :($esub_y*1.0), [Output(PY, 50.,  [MPSGE.Tax(:($Otax*1.0), RA)])], [Input(PL, 20.), Input(PK,30.)])
    @production(m, U, 0, 1.0, [Output(PU, 150.)], [Input(PX, 100.), Input(PY,50.)])
   
    @demand(m, RA, 1., [Demand(PU, 150. )], [Endowment(PL, :(70. * $(endow))), Endowment(PK, 80)])

    solve!(m, cumulative_iteration_limit=0)

    # set_fixed!(PL, true)
    # set_value(endow, 1.1)
    # set_value(Otax, 0.1)
    # solve!(m)

    # set_fixed!(RA, true) # Set Consumer as the numeraire

    set_value(endow, 1.1)
    solve!(m)

    set_fixed!(PX, true)
    solve!(m)

    set_fixed!(PX, false)
    set_fixed!(PL, true)
    solve!(m)
# Just a re-set for testing, so no need to re-run model
    set_value(Otax, 0.0)
    solve!(m)

    set_value(Otax, 0.1)
    solve!(m)

    set_value(Otax, 0.2)
    solve!(m)

    set_value(Otax, 0.5)
    solve!(m)

    set_value(Otax, 0.9)
    solve!(m)
