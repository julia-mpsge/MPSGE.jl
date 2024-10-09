extract_variable_ref(v::NonlinearExpr) = v.args[1]
extract_variable_ref(v::AffExpr) = collect(keys(v.terms))[1]
extract_variable_ref(v::QuadExpr) = extract_variable_ref(v.aff)

function generate_report(M::MPSGEModel)

    m = jump_model(M)
    
    out = []
    mpsge_vars = MPSGE.get_variable.(all_variables(M))
    
    for ci in all_constraints(m; include_variable_in_set_constraints = false)
        c = constraint_object(ci)
        var = extract_variable_ref(c.func[2])

        if var ∉ mpsge_vars
            continue
        end

        

        
        val = value(var)
        margin = value(c.func[1])

        push!(out,(var,val,margin))
        #mapping[extract_variable_ref(c.func[2])] = c.func[1]
    end

    df = DataFrame(out,[:var,:value,:margin])
    return df

end;