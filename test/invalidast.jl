using MarkdownAST: MarkdownAST, @ast, Node,
    Document, Paragraph, Strong, Link, CodeBlock, HTMLBlock, Code,
    InvalidChildException, insert_after!, insert_before!
using Test

@testset "Invalid AST" begin
    # Document can only contain blocks, not inlines
    @test_throws InvalidChildException (@ast Document() do
        Link("", "")
    end)
    valid_document = @ast Document() do
        Paragraph()
    end
    node_strong = Node(Strong())
    @test_throws InvalidChildException push!(valid_document.children, node_strong)
    @test_throws InvalidChildException pushfirst!(valid_document.children, node_strong)
    @test_throws InvalidChildException insert_after!(first(valid_document.children), node_strong)
    @test_throws InvalidChildException insert_before!(first(valid_document.children), node_strong)

    # Paragraph can only contain inlines, but not blocks:
    @test_throws InvalidChildException (@ast Paragraph() do
        HTMLBlock("")
    end)
    valid_p = @ast Paragraph() do
        "..."
    end
    node_codeblock = Node(CodeBlock("", ""))
    @test_throws InvalidChildException push!(valid_p.children, node_codeblock)
    @test_throws InvalidChildException pushfirst!(valid_p.children, node_codeblock)
    @test_throws InvalidChildException insert_after!(first(valid_p.children), node_codeblock)
    @test_throws InvalidChildException insert_before!(first(valid_p.children), node_codeblock)

    # Some nodes can not have child nodes
    @test_throws InvalidChildException (@ast CodeBlock("", "") do
        "..."
    end)
    @test_throws InvalidChildException (@ast Code("...") do
        "..."
    end)
end
