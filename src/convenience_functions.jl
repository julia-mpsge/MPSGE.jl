value(X::MPSGEScalarVariable) = JuMP.value(get_variable(X))

fix(X::MPSGEScalarVariable, value::Real) = JuMP.fix(get_variable(X), value; force=true)

function JuMP.unfix(X::MPSGEScalarVariable) 
    JuMP.unfix(get_variable(X))
    JuMP.set_lower_bound(get_variable(X),0)
end

