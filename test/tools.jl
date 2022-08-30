using MarkdownAST: MarkdownAST, copy_tree, tablerows, tablesize,
    Node, Table, TableHeader, TableBody, TableRow, TableCell
using Test

@testset "Tools" begin
    # copy_tree
    x0 = @ast Paragraph() do
        Link("", "") do
            "link"
        end
        "foo"
    end
    x1 = copy_tree(x0)
    @test x1 == x0
    @test x1 !== x0
    x2 = copy_tree(first(x0.children))
    @test x2.element isa Link
    x3 = copy_tree(x0) do node, element
        @test node.element === element
        if node.element isa MarkdownAST.Text
            Code(node.element.text)
        else
            deepcopy(node.element)
        end
    end
    @test x3 != x0
    @test first(x3.children).next.element isa Code

    # Table helper functions
    @test_throws ErrorException tablerows(Node(Document()))
    @test_throws ErrorException tablesize(Node(Document()))
    c = TableCell(:right, true, 0)
    table = @ast Table([]) do
        TableHeader() do
            TableRow() do; c; c; c end
        end
        TableBody() do
            TableRow()
            TableRow() do; c; end
            TableRow() do; c; c; c; c; c; c; c; end
            TableRow() do; c; c; end
        end
    end
    let rows = collect(tablerows(table))
        @test length(rows) == 5
        @test rows[1] == first(first(table.children).children)
        @test rows[2] == first(last(table.children).children)
        @test rows[3] == first(last(table.children).children).next
        @test rows[4] == first(last(table.children).children).next.next
        @test rows[5] == first(last(table.children).children).next.next.next
    end
    @test tablesize(table) == (5, 7)
    @test tablesize(table, 1) == 5
    @test tablesize(table, 2) == 7
    @test_throws ErrorException tablesize(table, 0)
    @test_throws ErrorException tablesize(table, 3)

    table = @ast Table([]) do
        TableHeader()
        TableBody() do
            TableRow()
            TableRow() do; c; end
            TableRow() do; c; c; c; c; c; c; c; end
            TableRow() do; c; c; end
        end
    end
    let rows = collect(tablerows(table))
        @test length(rows) == 4
        @test rows[1] == first(last(table.children).children)
        @test rows[2] == first(last(table.children).children).next
        @test rows[3] == first(last(table.children).children).next.next
        @test rows[4] == first(last(table.children).children).next.next.next
    end
    @test tablesize(table) == (4, 7)

    table = @ast Table([]) do
        TableHeader() do
            TableRow() do; c; c; c end
            TableRow()
            TableRow() do; c; end
            TableRow() do; c; c; c; c; c; c; c; end
            TableRow() do; c; c; end
        end
        TableBody()
    end
    let rows = collect(tablerows(table))
        @test length(rows) == 5
        @test rows[1] == first(first(table.children).children)
        @test rows[2] == first(first(table.children).children).next
        @test rows[3] == first(first(table.children).children).next.next
        @test rows[4] == first(first(table.children).children).next.next.next
        @test rows[5] == first(first(table.children).children).next.next.next.next
    end
    @test tablesize(table) == (5, 7)

    for table in [
            @ast(Table([]) do; TableHeader(); TableBody(); end),
            @ast(Table([]) do; TableHeader(); end),
            @ast(Table([]) do; TableBody(); end),
            @ast(Table([])),
        ]
        @test length(collect(tablerows(table))) == 0
        @test tablesize(table) == (0, 0)
    end
end
