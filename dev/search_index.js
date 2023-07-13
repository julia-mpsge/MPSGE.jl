var documenterSearchIndex = {"docs":
[{"location":"reference/#Reference-Guide","page":"Reference","title":"Reference Guide","text":"","category":"section"},{"location":"reference/","page":"Reference","title":"Reference","text":"Model\nadd!\nScalarParameter\nIndexedParameter","category":"page"},{"location":"reference/#MPSGE.add!","page":"Reference","title":"MPSGE.add!","text":"add!(m,bar)\nFunction that adds an element to the model with a name assignment\nm::Model is always the first Argument\n\n# Options\nParameter::ScalarParameter, ::IndexedParameter\nCommodity::ScalarCommodity, ::IndexedCommodity\nSector::ScalarSector, ::IndexedSector\nConsumer::ScalarConsumer, ::IndexedConsumer\nAxxConstraint::ScalarAux, ::IndexedAux\n\njulia> S = add!(m, Sector())\n````    \n    Production::Production\n    Demand::DemandFunction\n    # Example\n\njulia-repl julia> add!(m, Production())  ```\n\n\n\n\n\n","category":"function"},{"location":"#MPSGE.jl","page":"Home","title":"MPSGE.jl","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"TODO: Write documentation","category":"page"}]
}
