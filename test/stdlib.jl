using MarkdownAST: MarkdownAST, Node, @ast, Document,
    Table, TableHeader, TableBody, TableRow, TableCell,
    Emph, Strong, Code, InlineMath
using Markdown: Markdown
using Test

@testset "Markdown stdlib conversion" begin
    # Helper functions
    @test MarkdownAST.rpad_array!([], 3, 0) == [0, 0, 0]
    @test MarkdownAST.rpad_array!([1], 3, 0) == [1, 0, 0]
    @test MarkdownAST.rpad_array!([1, 2], 3, 0) == [1, 2, 0]
    @test MarkdownAST.rpad_array!([1, 2, 3], 3, 0) == [1, 2, 3]
    @test MarkdownAST.rpad_array!([1, 2, 3, 4], 3, 0) == [1, 2, 3, 4]
    @test MarkdownAST.rpad_array!([], 0, 0) == []
    @test MarkdownAST.rpad_array!([], -2, 0) == []
    @test MarkdownAST.rpad_array!([1], 0, 0) == [1]
    @test MarkdownAST.rpad_array!([1], -2, 0) == [1]

    @test convert(Node, Markdown.md"""
    | Column One | Column Two | Column Three |
    |:---------- | ---------- |:------------:|
    | Row `1`    | Column `2` |              |
    | *Row* 2    | **Row** 2  | Column ``3`` |
    """) == @ast Document() do
        Table([:left, :right, :center]) do
            TableHeader() do
                TableRow() do
                    TableCell(:left, true, 1) do
                        "Column One"
                    end
                    TableCell(:right, true, 2) do
                        "Column Two"
                    end
                    TableCell(:center, true, 3) do
                        "Column Three"
                    end
                end
            end
            TableBody() do
                TableRow() do
                    TableCell(:left, false, 1) do
                        "Row "
                        Code("1")
                    end
                    TableCell(:right, false, 2) do
                        "Column "
                        Code("2")
                    end
                    TableCell(:center, false, 3)
                end
                TableRow() do
                    TableCell(:left, false, 1) do
                        Emph() do
                            "Row"
                        end
                        " 2"
                    end
                    TableCell(:right, false, 2) do
                        Strong() do
                            "Row"
                        end
                        " 2"
                    end
                    TableCell(:center, false, 3) do
                        "Column "
                        InlineMath("3")
                    end
                end
            end
        end
    end
    # TODO: tests for problematic cases
end
