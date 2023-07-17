using Documenter, MPSGE

makedocs(modules=[MPSGE],
    sitename="MPSGE.jl",
    pages=[
        "Home" => "index.md",
        "Tutorial" => "tutorial.md",
        "How-to Guides" => "howtoguides.md",
        "Explanation and Discussion" => "explanation.md"
        "Reference" => "reference.md"
    ])

deploydocs(repo="github.com/anthofflab/MPSGE.jl.git")
