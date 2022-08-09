using Test
using MarkdownAST: @ast, Document, Paragraph, Strong, Heading
using AbstractTrees

@testset "AbstractTrees" begin
    n = @ast Document() do
        Heading(1) do; "header"; end
        Paragraph() do; "..."; end
        Paragraph() do
            "Foo "
            Strong() do; "bar"; end
            " baz."
        end
    end

    # We don't implement getindex() for .children currently, so we just assert
    # here that AbstractTrees falls back to the correct default here
    @test AbstractTrees.ChildIndexing(n) == AbstractTrees.NonIndexedChildren()

    ns = collect(PreOrderDFS(n))
    @test length(ns) == 10
    @test ns[1].element == Document()
    @test ns[2].element == Heading(1)
    @test ns[3].element == MarkdownAST.Text("header")
    @test ns[4].element == Paragraph()
    @test ns[5].element == MarkdownAST.Text("...")
    @test ns[6].element == Paragraph()
    @test ns[7].element == MarkdownAST.Text("Foo ")
    @test ns[8].element == Strong()
    @test ns[9].element == MarkdownAST.Text("bar")
    @test ns[10].element == MarkdownAST.Text(" baz.")

    ns = collect(PostOrderDFS(n))
    @test length(ns) == 10
    @test ns[1].element == MarkdownAST.Text("header")
    @test ns[2].element == Heading(1)
    @test ns[3].element == MarkdownAST.Text("...")
    @test ns[4].element == Paragraph()
    @test ns[5].element == MarkdownAST.Text("Foo ")
    @test ns[6].element == MarkdownAST.Text("bar")
    @test ns[7].element == Strong()
    @test ns[8].element == MarkdownAST.Text(" baz.")
    @test ns[9].element == Paragraph()
    @test ns[10].element == Document()

    # ns = collect(StatelessBFS(n))
    # @test length(ns) == 10
    # @test ns[1].element == Document()
    # @test ns[2].element == Heading(1)
    # @test ns[3].element == Paragraph()
    # @test ns[4].element == Paragraph()
    # @test ns[5].element == MarkdownAST.Text("header")
    # @test ns[6].element == MarkdownAST.Text("...")
    # @test ns[7].element == MarkdownAST.Text("Foo ")
    # @test ns[8].element == Strong()
    # @test ns[9].element == MarkdownAST.Text(" baz.")
    # @test ns[10].element == MarkdownAST.Text("bar")

    ns = collect(Leaves(n))
    @test length(ns) == 5
    @test ns[1].element == MarkdownAST.Text("header")
    @test ns[2].element == MarkdownAST.Text("...")
    @test ns[3].element == MarkdownAST.Text("Foo ")
    @test ns[4].element == MarkdownAST.Text("bar")
    @test ns[5].element == MarkdownAST.Text(" baz.")
end
