value(X::MPSGEScalarVariable) = JuMP.value(get_variable(X))

fix(X::MPSGEScalarVariable, value::Real) = JuMP.fix(get_variable(X), value; force=true)

JuMP.unfix(X::MPSGEScalarVariable) = JuMP.unfix(get_variable(X))

