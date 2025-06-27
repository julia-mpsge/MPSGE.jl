




macro aux_constraint(model, A, constraint)
    constr_call = :(add_aux_constraint!($(esc(model)), $(esc(A)), $(esc(constraint))))
    return :($constr_call)
end


