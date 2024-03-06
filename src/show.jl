###########
## Model ##
###########

function Base.show(io::IO,M::MPSGEModel)
    println(io,"\$Sectors:")
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
    print(io,name(S))
    if !ismissing(subindex(S))
        print(io,subindex(S))
    end
end

function Base.show(io::IO,S::MPSGEIndexedVariable) #This could be smarter
    print(io,S.subsectors)
end

########################
## Production/Demands ##
########################
function Base.show(io::IO,P::ScalarProduction)
    println(io,"\$Production: $(sector(P))")
    println(io,"$(output(P))")
    print(io,"$(input(P))")
end

function Base.show(io::IO,E::ScalarDem)
    print(io,"D: $(commodity(E))    Q: $(quantity(E))")
end

function Base.show(io::IO,E::ScalarEndowment)
    print(io,"E: $(commodity(E))    Q: $(quantity(E))")
end

function Base.show(io::IO, D::ScalarDemand)
    println(io,"\$Demand: $(consumer(D))")
    for (_,d)∈D.demands
        println(io,"    $d")
    end
    for (_,e)∈D.endowments
        println(io,"    $e")
    end
end


####################
## Tree Structure ##
####################
function nest_string(N::ScalarNest; tab_level=0)
    out = ":$(name(N)) = $(elasticity(N))\n"
    tab_level+=1
    for child in N.children
        out *= "  "^tab_level*"$(nest_string(child;tab_level = tab_level))\n"
    end
    #print(io,out)
    return out
end


function nest_string(N::ScalarNetput; tab_level=0)
    if N isa ScalarInput
        v = "I"
    else
        v = "O"
    end
    out = "$v:$(commodity(N))    Q: $(base_quantity(N))"
    if N.reference_price !=1
        out *= "    P:$(reference_price(N))"
    end
    for tax in N.taxes
        out *= "    $tax"
    end
    return out
end

function Base.show(io::IO,N::ScalarNest)
    print(io, nest_string(N))
end


Base.show(io::IO,T::Tax) = print(io,"A:$(tax_agent(T))    T:$(tax(T))")
