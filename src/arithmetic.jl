const jump_types = Union{Real, JuMP.VariableRef, JuMP.AffExpr, JuMP.QuadExpr, JuMP.NonlinearExpr}

Base.:+(x::MPSGEScalarVariable, y::MPSGEScalarVariable) = get_variable(x)+get_variable(y) 
Base.:+(x::MPSGEScalarVariable, y::jump_types) = get_variable(x)+y
Base.:+(x::jump_types, y::MPSGEScalarVariable) = x+get_variable(y) 

Base.:-(x::MPSGEScalarVariable, y::MPSGEScalarVariable) = get_variable(x)-get_variable(y) 
Base.:-(x::MPSGEScalarVariable, y::jump_types) = get_variable(x)-y
Base.:-(x::jump_types, y::MPSGEScalarVariable) = x-get_variable(y) 
Base.:-(x::MPSGEScalarVariable) = -get_variable(x)

Base.:*(x::MPSGEScalarVariable, y::MPSGEScalarVariable) = get_variable(x)*get_variable(y) 
Base.:*(x::MPSGEScalarVariable, y::jump_types) = get_variable(x)*y
Base.:*(x::jump_types, y::MPSGEScalarVariable) = x*get_variable(y) 

Base.:/(x::MPSGEScalarVariable, y::MPSGEScalarVariable) = get_variable(x)/get_variable(y) 
Base.:/(x::MPSGEScalarVariable, y::jump_types) = get_variable(x)/y
Base.:/(x::jump_types, y::MPSGEScalarVariable) = x/get_variable(y) 

Base.:^(x::MPSGEScalarVariable, y::MPSGEScalarVariable) = get_variable(x)^get_variable(y) 
Base.:^(x::MPSGEScalarVariable, y::jump_types) = get_variable(x)^y
Base.:^(x::jump_types, y::MPSGEScalarVariable) = x^get_variable(y) 

Base.zero(::Type{ScalarParameter}) = 0
Base.zero(::Type{ScalarAuxiliary}) = 0
