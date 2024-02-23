using MPSGE_MP
using Documenter

DocMeta.setdocmeta!(MPSGE_MP, :DocTestSetup, :(using MPSGE_MP); recursive=true)

makedocs(;
    modules=[MPSGE_MP],
    authors="Mitch Phillipson",
    sitename="MPSGE_MP.jl",
    format=Documenter.HTML(;
        canonical="https://mitchphillipson.github.io/MPSGE_MP.jl",
        edit_link="master",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/mitchphillipson/MPSGE_MP.jl",
    devbranch="master",
)
