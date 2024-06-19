using MPSGE_MP
using Documenter

DocMeta.setdocmeta!(MPSGE_MP, :DocTestSetup, :(using MPSGE_MP); recursive=true)


const _PAGES = [
    "Introduction" => ["index.md"],
    "Tutorials" => [
        "Getting Started" => ["Tutorials/getting_started/introduction.md", "Tutorials/getting_started/getting_started_mpsge.md"],
        "Basic Examples" => ["Tutorials/basic_examples/m1_mpsge.md"],
        "Intermediate Examples" => ["Tutorials/intermediate_examples/M22.md"],
    ],
    "How it works" => ["how_it_works.md"], 
    "Docstrings" => ["docs.md"],
]


makedocs(;
    modules=[MPSGE_MP],
    authors="Mitch Phillipson",
    sitename="MPSGE_MP.jl",
    format=Documenter.HTML(;
        canonical="https://mitchphillipson.github.io/MPSGE_MP.jl",
        edit_link="main",
        assets=String[],
    ),
    pages=_PAGES
)

deploydocs(;
    repo = "github.com/mitchphillipson/MPSGE_MP.jl",
    devbranch = "main",
    branch = "gh-pages"
)

#deploydocs(
#    repo = "https://github.com/uw-windc/WiNDC.jl",
#    target = "build",
#    branch = "gh-pages",
#    versions = ["stable" => "v^", "v#.#" ],
#)