# MarkdownAST

[![Version][juliahub-version-img]][juliahub-version-url]
[![Documentation][docs-stable-img]][docs-stable-url]
[![GitHub Actions CI][github-actions-img]][github-actions-url]
[![CodeCov][codecov-img]][codecov-url]

A Julia package for working with Markdown documents in an [abstract syntax tree][ast-wiki] representation.
As an example, the following Markdown

```markdown
# Markdown document

Hello [world](https://example.com/)!
```

can be represented as the following tree (in the [`@ast` macro DSL][mdast-astmacro]) using MarkdownAST

```julia
using MarkdownAST: @ast, Document, Heading, Paragraph, Link
ast = @ast Document() do
    Heading(1) do
        "Markdown document"
    end
    Paragraph() do
        "Hello "
        Link("https://example.com/", "") do
            "world"
        end
        "!"
    end
end
```

and the resulting [`Node` object][mdast-node] that contains information about the whole tree can be accessed, traversed, and, if need be, modified, e.g.

```julia-repl
julia> for node in ast.children
           println("$(node.element) with $(length(node.children)) child nodes")
       end
Heading(1) with 1 child nodes
Paragraph() with 3 child nodes
```

See the [documentation][docs-stable-url] for the full descriptions of the APIs that are available.

## Credits

The core parts of this package heavily derive from the [CommonMark.jl](https://github.com/MichaelHatherly/CommonMark.jl) package.
Also, this packages does not provide a parser, and the users are encouraged to check out CommonMark.jl for that purpose.


[juliahub-version-img]: https://juliahub.com/docs/MarkdownAST/version.svg
[juliahub-version-url]: https://juliahub.com/ui/Packages/MarkdownAST/6YkiC
[github-actions-img]: https://github.com/JuliaDocs/MarkdownAST.jl/actions/workflows/CI.yml/badge.svg
[github-actions-url]: https://github.com/JuliaDocs/MarkdownAST.jl/actions/workflows/CI.yml
[docs-stable-img]: https://img.shields.io/badge/documentation-stable-blue.svg
[docs-stable-url]: https://markdownast.juliadocs.org/stable/
[codecov-img]: https://codecov.io/gh/JuliaDocs/MarkdownAST.jl/branch/main/graph/badge.svg?token=91XPUAQ2WE
[codecov-url]: https://codecov.io/gh/JuliaDocs/MarkdownAST.jl

[ast-wiki]: https://en.wikipedia.org/wiki/Abstract_syntax_tree
[mdast-astmacro]: https://markdownast.juliadocs.org/stable/astmacro/#MarkdownAST.@ast
[mdast-node]: https://markdownast.juliadocs.org/stable/node/#MarkdownAST.Node
