using MPSGE
using Documenter
using Literate

DocMeta.setdocmeta!(MPSGE, :DocTestSetup, :(using MPSGE); recursive=true)


const _PAGES = [
    "Introduction" => ["index.md"],
    "Tutorials" => [
        "Getting Started" => ["Tutorials/getting_started/introduction.md", "Tutorials/getting_started/getting_started_mpsge.md"],
        "Basic Examples" => ["Tutorials/basic_examples/m1_mpsge.md"],
        "Intermediate Examples" => ["Tutorials/intermediate_examples/M22.md"],
        "Robinson Crusoe" => ["Tutorials/robinson_crusoe/introduction.md","Tutorials/robinson_crusoe/basic_rc.md"],
    ],
    "How it works" => ["how_it_works.md"], 
    "Docstrings" => ["docs.md"],
]






Literate.markdown(
    "src/Tutorials/robinson_crusoe/basic_rc.jl", 
    "src/Tutorials/robinson_crusoe/";
    name = "basic_rc.md",
    # preprocess = replace_includes)
)



makedocs(;
    modules=[MPSGE],
    authors="Mitch Phillipson",
    sitename="MPSGE.jl",
    format=Documenter.HTML(;
        canonical="https://julia-mpsge.github.io/MPSGE.jl",
        edit_link="main",
        assets=String[],
    ),
    pages=_PAGES
)

deploydocs(;
    repo = "github.com/julia-mpsge/MPSGE.jl",
    devbranch = "main",
    branch = "gh-pages"
)

#deploydocs(
#    repo = "https://github.com/uw-windc/WiNDC.jl",
#    target = "build",
#    branch = "gh-pages",
#    versions = ["stable" => "v^", "v#.#" ],
#)