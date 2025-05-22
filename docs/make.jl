using PlateMotionSimulator
using Documenter

DocMeta.setdocmeta!(PlateMotionSimulator, :DocTestSetup, :(using PlateMotionSimulator); recursive=true)

makedocs(;
    modules=[PlateMotionSimulator],
    authors="Felix Hilarius",
    sitename="PlateMotionSimulator.jl",
    format=Documenter.HTML(;
        canonical="https://fhilariu.github.io/PlateMotionSimulator.jl",
        edit_link="master",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/fhilariu/PlateMotionSimulator.jl",
    devbranch="master",
)
