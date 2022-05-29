# This example shows how to construct a simple Markdown AST with the help of the @ast macro
using MarkdownAST: MarkdownAST, @ast, Document, Paragraph, Heading, Link

doc = @ast Document() do
    Heading(1) do
        "Example document"
    end
    Paragraph() do
        "Text "
        Link("foo/", "") do
            "link"
        end
        " and more text."
    end
end

# The AST can be written back into the standard output with the showast function.
# The print representation mirrors the @ast macro.
MarkdownAST.showast(doc)
