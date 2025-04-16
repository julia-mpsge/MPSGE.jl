###########
## Model ##
###########

function Base.show(io::IO,M::MPSGEModel)
    println(io, "\$Parameters:")
    for p∈raw_parameters(M)
        println(io,p)
    end

    println(io,"\n\$Sectors:")
    for s∈sectors(M)
        println(io,s)
    end

    println(io,"\n\$Commodities:")
    for s∈commodities(M)
        println(io,s)
    end
    
    println(io,"\n\$Consumers:")
    for s∈consumers(M)
        println(io,s)
    end

    println(io,"")

    for (_,p)∈M.productions
        println(io,p)
    end

    for (_,d)∈M.demands
        println(io,d)
    end

end

###############
## Variables ##
###############

function Base.show(io::IO,S::MPSGEScalarVariable)
    print(io,base_name(S))
    if !ismissing(subindex(S))
        print(io,subindex(S))
    end
end

function Base.show(io::IO, S::IndexedParameter)
    out = string(name(S), "[", join(index_names(S), ", "), "]")
    if description(S) != ""
        out *= "  --  $(description(S))"
    end

    print(io, out)
        
end

function Base.show(io::IO, S::MPSGEIndexedVariable)#This could be smarter
    print(io,S.subsectors)
end
function Base.show_nd(io::IO, S::MPSGEIndexedVariable)#This could be smarter
    print(io,S.subsectors)
end


function Base.print_array(io::IO, X::MPSGEIndexedVariable)
    return Base.print_array(io, X.subsectors)
end


#################
## Expressions ##
#################
function Base.show(io::IO, e::abstractMPSGEExpr)
    if e.head == :- && length(e.args) == 1
        print(io, "-($(e.args[1]))")
    else
        print(io, join(["($a)" for a∈e.args], " $(e.head) "))
    end
end

########################
## Production/Demands ##
########################
function Base.show(io::IO, P::Production)
    println(io,"\$Production: $(sector(P))")
    println(io,"$(output(P))")
    print(io,"$(input(P))")
end

function Base.show(io::IO,E::ScalarFinalDemand)
    print(io,"D: $(commodity(E))    Q: $(quantity(E))")
end

function Base.show(io::IO,E::ScalarEndowment)
    print(io,"E: $(commodity(E))    Q: $(quantity(E))")
end

function Base.show(io::IO, D::ScalarDemand)
    first_line = "\$Demand: $(consumer(D))"
    if elasticity(D) != 1
        first_line *= " Elasticity: $(elasticity(D))"
    end
    println(io,first_line)
    for (_,DF)∈final_demands(D), d∈DF
        println(io,"    $d")
    end
    for (_,E)∈endowments(D), e∈E
        println(io,"    $e")
    end
end


####################
## Tree Structure ##
####################
Base.show(io::IO,T::Tax) = print(io,"A:$(tax_agent(T))    T:$(tax(T))")


function Base.print_array(io::IO, X::IndexedNest)
    return Base.print_array(io, X.subsectors)
end


function Base.show(io::IO, N::ScalarNest)
    print(io, N.name)
    #if !ismissing(N.subindex)
    #    print(io, N.subindex)
    #end
end

function Base.show(io::IO, N::Netput)
    v = isa(N, Input) ? "I" : "O"
    out = "$v:$(commodity(N))    Q:$(base_quantity(N))"
    if reference_price(N) != 1
        out *= "    P:$(reference_price(N))"
    end
    for tax in taxes(N)
        out *= "    $tax"
    end
    print(io,out)
end


function node_string(N::Node; tab_level=0)
    out = ":$(N.data) = $(elasticity(N))\n"
    tab_level+=1
    for child in N.children
        out *= "  "^tab_level*"$(node_string(child;tab_level = tab_level))\n"
    end
    return out

end


function node_string(N::Netput; tab_level=0)
    return "$N"
end



function Base.show(io::IO,N::Node)
    print(io, node_string(N))
end
