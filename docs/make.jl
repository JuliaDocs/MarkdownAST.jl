using MarkdownAST, AbstractTrees
using Documenter

makedocs(
    sitename = "MarkdownAST",
    pages = [
        "Introduction" => "index.md",
        "elements.md",
        "node.md",
        "iteration.md",
        "other.md",
    ]
)

deploydocs(
    repo = "github.com/JuliaDocs/MarkdownAST.jl.git",
)
