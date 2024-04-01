###########################
## Create JuMP Variables ##
###########################
function add_variable!(m::MPSGEModel, S::MPSGEScalarVariable; start = 1)
    jm = jump_model(m)
    jm[name(S)] = @variable(jm,base_name = string(name(S)),start=start, lower_bound = 0)
end




function add_variable!(m::MPSGEModel, S::MPSGEIndexedVariable; start = 1)

    jm = jump_model(m)
    index = S.index

    dim = length.(index)
    
    x = JuMP.@variable(jm, [1:prod(dim)], lower_bound=0, start = start)

    for (i, ind) in enumerate(Iterators.product(index...))
        new_index = join(ind,",")
        JuMP.set_name(x[i], "$(name(S))[$new_index]")
    end

    output = JuMP.Containers.DenseAxisArray(reshape(x, Tuple(dim)), index...)
    jm[name(S)] = output
    return output

end

function add_variable!(m::MPSGEModel, S::Auxiliary)
    add_variable!(m, S; start = 0)
end