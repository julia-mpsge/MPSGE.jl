using MPSGE
using Documenter
using Literate

DocMeta.setdocmeta!(MPSGE, :DocTestSetup, :(using MPSGE); recursive=true)


const _PAGES = [
    "Introduction" => ["index.md"],
    "Overview" => [
        "overview/introduction.md",
        "overview/variables.md",
        "overview/production.md",
        "overview/demand.md",
        "overview/constraints.md",
        "overview/optimizations.md",
    ],
    "Tutorials" => [
        "Getting Started" => [
            "Tutorials/getting_started/introduction.md", 
            "Tutorials/getting_started/first_example.md"
        ],
        "Intermediate Examples" => [
            "Tutorials/intermediate_examples/m22.md"
            ],
        "Robinson Crusoe" => [
            "Tutorials/robinson_crusoe/introduction.md",
            "Tutorials/robinson_crusoe/basic_rc.md"
            ],
    ],
    #"Cookbook" => [],
    "Mathematical Background" => ["how_it_works.md"], 
    "API Reference" => ["docs.md"],
]


literate_files = Dict(
    "basic_rc" => ( 
        input = "src/Tutorials/robinson_crusoe/basic_rc.jl",
        output = "src/Tutorials/robinson_crusoe/"
    ),
    "first_example" => ( 
        input = "src/Tutorials/getting_started/first_example.jl",
        output = "src/Tutorials/getting_started/"
    ),
    "m22" => ( 
        input = "src/Tutorials/intermediate_examples/M22.jl",
        output = "src/Tutorials/intermediate_examples/"
    )
)


for (name, paths) in literate_files
    EXAMPLE = joinpath(@__DIR__, paths.input)
    OUTPUT = joinpath(@__DIR__, paths.output)
    Literate.markdown(EXAMPLE, 
                      OUTPUT;
                      name = name)
end



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
    branch = "gh-pages",
    push_preview = true
)
