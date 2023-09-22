function Base.show(io::IO, m::Model)
    println(io, "MPSGE model with $(length(m._sectors)) sectors, $(length(m._commodities)) commodities and $(length(m._consumers)) consumers.")

    if length(m._sectors) > 0
        print(io, "  Sectors: ")
        print(io, join(["$(s.name)" for s in m._sectors], ", "))
        println(io)
    end

    if length(m._commodities) > 0
        print(io, "  Commodities: ")
        print(io, join(["$(c.name)" for c in m._commodities], ", "))
        println(io)
    end

    if length(m._consumers) > 0
        print(io, "  Consumers: ")
        print(io, join(["$(c.name)" for c in m._consumers], ", "))
        println(io)
    end

    if length(m._auxs) > 0
        print(io, "  Auxs: ")
        print(io, join(["$(a.name)" for a in m._auxs], ", "))
        println(io)
    end

    if m._jump_model!==nothing
        if m._status==:Solved
            println()
            println(io, "Solution:")

            for n in JuMP.all_variables(m._jump_model)
                var_value = JuMP.is_parameter(n) ? JuMP.parameter_value(n) : JuMP.value(n)
                println(io, "  $n:\t$var_value")
            end        
        else
            println(io, "Did not solve with error: $(m._status).")
        end
    end
end



function Base.show(io::IO,S::Union{SectorRef,CommodityRef,ConsumerRef,AuxRef,ParameterRef})
    #print(io,get_full(S))
    if isnothing(S.subindex)
        return print(io,get_full(S))
    else
        names = S.subindex_names
        full_S = get_full(S)
        return print(io,"$(names)\tbm: $(full_S.benchmark[names...])")
    end

end


function _show_scalar(io::IO, S::Union{ScalarSector,ScalarCommodity,ScalarConsumer,ScalarAux},type_name::String)
    println(io,"$type_name: $(S.name)")
    desc = S.description
    if desc != ""
        println(io, "Description: $desc")
    end

    fixed = S.fixed == 0 ? "false" : "true"

    PrettyTables.pretty_table(io,hcat(S.lower_bound,S.benchmark,S.upper_bound,fixed),
                header = ["Lower Bound","Benchmark","Upper Bound","Fixed"])  
end

function Base.show(io::IO, S::ScalarSector)
    _show_scalar(io,S,"Sector")
end

function Base.show(io::IO, S::ScalarCommodity)
    _show_scalar(io,S,"Commodity")
end

function Base.show(io::IO, S::ScalarConsumer)
    _show_scalar(io,S,"Consumer")
end

function Base.show(io::IO, S::ScalarAux)
    _show_scalar(io,S,"Aux")
end


function _show_indexed(io::IO, S::Union{IndexedSector,IndexedCommodity,IndexedConsumer,IndexedAux},type_name::String)
    println(io,"$type_name: $(S.name)")
    desc = S.description
    if desc != ""
        println(io, "Description: $desc")
    end

    index = vec(collect(Iterators.product(S.indices...)))

    data = hcat(index,
                vec(S.lower_bound.data),
                vec(S.benchmark.data),
                vec(S.upper_bound.data),
                vec(S.fixed.data)
                )

    PrettyTables.pretty_table(io,data,
        header = ["Index","Lower Bound","Benchmark","Upper Bound","Fixed"]
    )
end

function Base.show(io::IO,S::IndexedSector)
    _show_indexed(io,S,"Sector")
end

function Base.show(io::IO,S::IndexedCommodity)
    _show_indexed(io,S,"Commodity")
end

function Base.show(io::IO,S::IndexedConsumer)
    _show_indexed(io,S,"Consumer")
end

function Base.show(io::IO,S::IndexedAux)
    _show_indexed(io,S,"Aux")
end


function Base.show(io::IO, P::ScalarParameter)
    println(io,"Parameter: $(P.name)")
    desc = P.description
    if desc != ""
        println(io, "Description: $desc")
    end

    println(io,"Value: $(P.value)")
end

function Base.show(io::IO, P::IndexedParameter)
    println(io,"Parameter: $(P.name)")
    desc = P.description
    if desc != ""
        println(io, "Description: $desc")
    end

    index = vec(collect(Iterators.product(P.indices...)))

    data = hcat(index,
                vec(P.value.data),
                )

    PrettyTables.pretty_table(io,data,
        header = ["Index","Value"]
    )
end



function Base.show(io::IO,P::Production)
    print(io, "Production: $(get_name(P.sector))\t")

    if P.elasticity != 0
        print(io,"s: $(P.elasticity)")
    end

    print(io,"\n\n")

    for output in P.outputs
        println(io,output)
    end

    for input in P.inputs
        println(io,input)
    end
end

function Base.show(io::IO,O::Output)
    print(io,"O: $(get_name(O.commodity))\tQ: $(O.quantity)\t")
    if O.price!=1
        print(io,"P: $(O.price)\t")
    end

    for tax in O.taxes
        print(io,tax)
    end
end


function Base.show(io::IO,I::Input)
    print(io,"I: $(get_name(I.commodity))\tQ: $(I.quantity)\t")
    if I.price!=1
        print(io,"P: $(I.price)\t")
    end

    for tax in I.taxes
        print(io,tax)
    end
end


function Base.show(io::IO,T::Tax)
    print(io,"A: $(get_name(T.agent))\tT: $(T.rate)")
end




function Base.show(io::IO,D::DemandFunction)
    print(io,"Demand: $(get_name(D.consumer))\n\n")

    for demand in D.demands
        println(io,demand)
    end

    for endowment in D.endowments
        println(io,endowment)
    end
end

function Base.show(io::IO, D::Demand)
    print(io,"D: $(get_name(D.commodity))\tQ: $(D.quantity)\t")
    if D.price !=1
        print(io,"P: $(D.price)")
    end
end

function Base.show(io::IO, E::Endowment)
    print(io,"E: $(get_name(E.commodity))\tQ: $(E.quantity)")
end
