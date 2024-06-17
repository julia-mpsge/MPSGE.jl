JuMP.value(X::MPSGEScalarVariable) = JuMP.value(get_variable(X)) #Issue if the model isn't defined

function JuMP.fix(X::MPSGEScalarVariable, value::Real) 
    M = model(X)
    if !ismissing(numeraire(M)) && X == numeraire(M)
        M.numeraire = missing
    end 
    JuMP.fix(get_variable(X), value; force=true)
    set_start_value(X, value)
end

function JuMP.unfix(X::MPSGEScalarVariable) 
    M = model(X)
    if !ismissing(numeraire(M)) && X == numeraire(M)
        M.numeraire = missing
    end 
    JuMP.unfix(get_variable(X))
    JuMP.set_lower_bound(get_variable(X),0)
end
JuMP.is_fixed(X::MPSGEScalarVariable) = JuMP.is_fixed(get_variable(X))


JuMP.set_start_value(X::MPSGEScalarVariable, val::Real) = JuMP.set_start_value(get_variable(X), val)
JuMP.start_value(H::MPSGEScalarVariable) = start_value(get_variable(H))

function JuMP.set_silent(M::MPSGEModel) 
    M.silent = true
    JuMP.set_silent(jump_model(M))
end

function JuMP.unset_silent(M::MPSGEModel) 
    M.silent = false
    JuMP.unset_silent(jump_model(M))
end