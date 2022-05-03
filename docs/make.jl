using MarkdownAST
using Documenter

makedocs(
    sitename = "MarkdownAST",
    pages = [
        "Introduction" => "index.md",
        "elements.md",
        "node.md",
        "other.md",
    ]
)

deploydocs(
    repo = "github.com/JuliaDocs/MarkdownAST.jl.git",
)
