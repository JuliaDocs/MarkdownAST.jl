using MarkdownAST, AbstractTrees
using Documenter

makedocs(
    sitename = "MarkdownAST",
    pages = [
        "Introduction" => "index.md",
        "elements.md",
        "node.md",
        "astmacro.md",
        "iteration.md",
        "other.md",
    ],
    # documentation checks
    modules = [MarkdownAST],
    checkdocs = :all,
    strict = true,
)

deploydocs(
    repo = "github.com/JuliaDocs/MarkdownAST.jl.git",
)
