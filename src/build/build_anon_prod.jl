function build_anonymous_production_functions!(m::Model, jm)
    for p in m._productions
        for input in p.inputs
            if input isa Inputs
                new_sector = AnonSector(:asf)
                new_commodity = AnonCommodity(:asfP)

                
                push!(m._anon_productions, nothing)
            end
        end
    end
end
