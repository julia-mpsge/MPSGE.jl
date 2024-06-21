using MPSGE
using Documenter

DocMeta.setdocmeta!(MPSGE, :DocTestSetup, :(using MPSGE); recursive=true)


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
    modules=[MPSGE],
    authors="Mitch Phillipson",
    sitename="MPSGE.jl",
    format=Documenter.HTML(;
        canonical="https://mitchphillipson.github.io/MPSGE.jl",
        edit_link="main",
        assets=String[],
    ),
    pages=_PAGES
)

deploydocs(;
    repo = "github.com/mitchphillipson/MPSGE.jl",
    devbranch = "main",
    branch = "gh-pages"
)

#deploydocs(
#    repo = "https://github.com/uw-windc/WiNDC.jl",
#    target = "build",
#    branch = "gh-pages",
#    versions = ["stable" => "v^", "v#.#" ],
#)