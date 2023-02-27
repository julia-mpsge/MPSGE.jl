using Documenter, MPSGE

makedocs(modules=[MPSGE],
    sitename="MPSGE.jl",
    pages=[
        "Home" => "index.md",
        "Tutorial" => "tutorial.md",
        "User Guide" => "userguide.md",
        "Reference" => "reference.md"
    ])

deploydocs(repo="github.com/anthofflab/MPSGE.jl.git")
