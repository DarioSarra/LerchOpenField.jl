using LerchOpenField
using Documenter

DocMeta.setdocmeta!(LerchOpenField, :DocTestSetup, :(using LerchOpenField); recursive=true)

makedocs(;
    modules=[LerchOpenField],
    authors="Dario",
    repo="https://github.com/DarioSarra/LerchOpenField.jl/blob/{commit}{path}#{line}",
    sitename="LerchOpenField.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://DarioSarra.github.io/LerchOpenField.jl",
        edit_link="main",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/DarioSarra/LerchOpenField.jl",
    devbranch="main",
)
