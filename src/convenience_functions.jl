JuMP.value(X::MPSGEScalarVariable) = JuMP.value(get_variable(X)) #Issue if the model isn't defined

JuMP.fix(X::MPSGEScalarVariable, value::Real) = JuMP.fix(get_variable(X), value; force=true)

function JuMP.unfix(X::MPSGEScalarVariable) 
    JuMP.unfix(get_variable(X))
    JuMP.set_lower_bound(get_variable(X),0)
end


JuMP.set_start_value(X::MPSGEScalarVariable, val::Real) = JuMP.set_start_value(get_variable(X), val)
JuMP.start_value(H::ScalarConsumer) = start_value(get_variable(H))

function JuMP.set_silent(M::MPSGEModel) 
    M.silent = true
    JuMP.set_silent(jump_model(M))
end

function JuMP.unset_silent(M::MPSGEModel) 
    M.silent = false
    JuMP.unset_silent(jump_model(M))
end