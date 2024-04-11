
Base.:+(x::MPSGE_MP.MPSGEScalarVariable, y::MPSGE_MP.MPSGEScalarVariable) = get_variable(x)+get_variable(y) 
Base.:+(x::MPSGE_MP.MPSGEScalarVariable, y::Union{Real, JuMP.VariableRef, JuMP.AffExpr, JuMP.QuadExpr, JuMP.NonlinearExpr}) = get_variable(x)+y
Base.:+(x::Union{Real, JuMP.VariableRef, JuMP.AffExpr, JuMP.QuadExpr, JuMP.NonlinearExpr}, y::MPSGE_MP.MPSGEScalarVariable) = x+get_variable(y) 

Base.:-(x::MPSGE_MP.MPSGEScalarVariable, y::MPSGE_MP.MPSGEScalarVariable) = get_variable(x)-get_variable(y) 
Base.:-(x::MPSGE_MP.MPSGEScalarVariable, y::Union{Real, JuMP.VariableRef, JuMP.AffExpr, JuMP.QuadExpr, JuMP.NonlinearExpr}) = get_variable(x)-y
Base.:-(x::Union{Real, JuMP.VariableRef, JuMP.AffExpr, JuMP.QuadExpr, JuMP.NonlinearExpr}, y::MPSGE_MP.MPSGEScalarVariable) = x-get_variable(y) 
Base.:-(x::MPSGE_MP.MPSGEScalarVariable) = -get_variable(x)

Base.:*(x::MPSGE_MP.MPSGEScalarVariable, y::MPSGE_MP.MPSGEScalarVariable) = get_variable(x)*get_variable(y) 
Base.:*(x::MPSGE_MP.MPSGEScalarVariable, y::Union{Real, JuMP.VariableRef, JuMP.AffExpr, JuMP.QuadExpr, JuMP.NonlinearExpr}) = get_variable(x)*y
Base.:*(x::Union{Real, JuMP.VariableRef, JuMP.AffExpr, JuMP.QuadExpr, JuMP.NonlinearExpr}, y::MPSGE_MP.MPSGEScalarVariable) = x*get_variable(y) 

Base.:/(x::MPSGE_MP.MPSGEScalarVariable, y::MPSGE_MP.MPSGEScalarVariable) = get_variable(x)/get_variable(y) 
Base.:/(x::MPSGE_MP.MPSGEScalarVariable, y::Union{Real, JuMP.VariableRef, JuMP.AffExpr, JuMP.QuadExpr, JuMP.NonlinearExpr}) = get_variable(x)/y
Base.:/(x::Union{Real, JuMP.VariableRef, JuMP.AffExpr, JuMP.QuadExpr, JuMP.NonlinearExpr}, y::MPSGE_MP.MPSGEScalarVariable) = x/get_variable(y) 

Base.:^(x::MPSGE_MP.MPSGEScalarVariable, y::MPSGE_MP.MPSGEScalarVariable) = get_variable(x)^get_variable(y) 
Base.:^(x::MPSGE_MP.MPSGEScalarVariable, y::Union{Real, JuMP.VariableRef, JuMP.AffExpr, JuMP.QuadExpr, JuMP.NonlinearExpr}) = get_variable(x)^y
Base.:^(x::Union{Real, JuMP.VariableRef, JuMP.AffExpr, JuMP.QuadExpr, JuMP.NonlinearExpr}, y::MPSGE_MP.MPSGEScalarVariable) = x^get_variable(y) 

Base.zero(::Type{ScalarParameter}) = 0
Base.zero(::Type{ScalarAuxiliary}) = 0
