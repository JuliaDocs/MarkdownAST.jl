using MarkdownAST: MarkdownAST, Node, @ast, Document,
    Emph, Strong, InlineMath, Link, Code, Image,
    Paragraph, Heading, CodeBlock, BlockQuote, DisplayMath, ThematicBreak,
    List, Item, FootnoteLink, FootnoteDefinition, Admonition,
    Table, TableHeader, TableBody, TableRow, TableCell,
    JuliaValue, LineBreak
using Markdown: Markdown
using Test

@testset "Conversion from Markdown stdlib" begin
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

    # Inline elements.
    @test convert(Node, Markdown.md"xyz") == @ast Document() do
        Paragraph() do
            "xyz"
        end
    end

    @test convert(Node, Markdown.md"**xxx** *yyy* _zzz_ `literal` ``latex``") == @ast Document() do
        Paragraph() do
            Strong() do; "xxx"; end
            " "
            Emph() do; "yyy"; end
            " "
            Emph() do; "zzz"; end
            " "
            Code("literal")
            " "
            InlineMath("latex")
        end
    end

    @test convert(Node, Markdown.md"aaa [bbb](url://) ccc ![aaa](url)") == @ast Document() do
        Paragraph() do
            "aaa "
            Link("url://", "") do; "bbb"; end
            " ccc "
            Image("url", "") do; "aaa"; end
        end
    end

    # Top-level elements
    @test convert(Node, Markdown.md"""
    p1

    # Header 1
    ## Header 2
    ### Header 3
    #### Header 4
    ##### Header 5
    ###### Header 6

    Header 1
    ========
    p2

    Header 2
    --------
    p3
    """) == @ast Document() do
        Paragraph() do; "p1"; end
        Heading(1) do; "Header 1"; end
        Heading(2) do; "Header 2"; end
        Heading(3) do; "Header 3"; end
        Heading(4) do; "Header 4"; end
        Heading(5) do; "Header 5"; end
        Heading(6) do; "Header 6"; end
        Heading(1) do; "Header 1"; end
        Paragraph() do; "p2"; end
        Heading(2) do; "Header 2"; end
        Paragraph() do; "p3"; end
    end

    @test convert(Node, Markdown.md"""
    ```
    code
    ```
    ```lang
    code
    ```
    ```math
    x^2
    ```
    """) == @ast Document() do
        CodeBlock("", "code")
        CodeBlock("lang", "code")
        DisplayMath("x^2")
    end

    @test convert(Node, Markdown.md"""
    foo

    ---

    bar
    """) == @ast Document() do
        Paragraph() do; "foo"; end
        ThematicBreak()
        Paragraph() do; "bar"; end
    end

    @test convert(Node, Markdown.md"""
    foo[^1].

    [^1]: ...
    """) == @ast Document() do
        Paragraph() do
            "foo"
            FootnoteLink("1")
            "."
        end
        FootnoteDefinition("1") do
            Paragraph() do; "..."; end
        end
    end

    @test convert(Node, Markdown.md"""
    1. aaa
    2. bbb

    * aaa
    * bbb
      - ccc
    * ddd
    """) == @ast Document() do
        List(:ordered, true) do
            Item() do; Paragraph() do; "aaa"; end; end
            Item() do; Paragraph() do; "bbb"; end; end
        end
        List(:bullet, true) do
            Item() do; Paragraph() do; "aaa"; end; end
            Item() do
                Paragraph() do; "bbb"; end
                List(:bullet, true) do
                    Item() do; Paragraph() do; "ccc"; end; end
                end
            end
            Item() do; Paragraph() do; "ddd"; end; end
        end
    end
    @test convert(Node, Markdown.md"""
    * Foo

      Bar
    * Baz
    """) == @ast Document() do
        List(:bullet, false) do
            Item() do
                Paragraph() do; "Foo"; end
                Paragraph() do; "Bar"; end
            end
            Item() do; Paragraph() do; "Baz"; end; end
        end
    end

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

    @test convert(Node, Markdown.md"""
    !!! foo "bar baz"

        xyz
    """) == @ast Document() do
        Admonition("foo", "bar baz") do
            Paragraph() do; "xyz"; end
        end
    end
    @test convert(Node, Markdown.md"""
    !!! foo

        !!! warn "FOOBAR"
            Hello World

            ```math
            x+1
            ```
    """) == @ast Document() do
        Admonition("foo", "Foo") do
            Admonition("warn", "FOOBAR") do
                Paragraph() do; "Hello World"; end
                DisplayMath("x+1")
            end
        end
    end

    # LineBreak, Backslash, SoftBreak
    @test convert(Node, Markdown.md"""
    foo\
    bar
    """) == @ast Document() do
        Paragraph() do
            "foo"
            LineBreak()
            "bar"
        end
    end
    # This would lead to a Backslash() in CommonMark, but not in Markdown
    @test convert(Node, Markdown.md"""
    foo\\\\bar
    """) == @ast Document() do
        Paragraph() do
            "foo"
            "\\"
            "\\"
            "bar"
        end
    end
    # This would lead to a SoftBreak() in CommonMark, but not in Markdown
    @test convert(Node, Markdown.md"""
    foo
    bar
    """) == @ast Document() do
        Paragraph() do
            "foo bar"
        end
    end

    # Interpolation
    z = 1//2
    @test convert(Node, Markdown.md"""
    Interpolations: $(:foo), $(z), $(abs2(z)), $(2)
    """) == @ast Document() do
        Paragraph() do
            "Interpolations: "
            JuliaValue(nothing, :foo)
            ", "
            JuliaValue(nothing, 1//2)
            ", "
            JuliaValue(nothing, 1//4)
            ", "
            JuliaValue(nothing, 2)
        end
    end
    # interpolated string values are indistinguishable from normal text nodes
    # in the standard library AST
    foo = "foo"
    @test convert(Node, Markdown.md"""
    Interpolations: $("bar"), $(foo)
    """) == @ast Document() do
        Paragraph() do
            "Interpolations: "
            "bar"
            ", "
            "foo"
        end
    end
    # It is possible to have interpolation "blocks" in the standard library
    @test convert(Node, Markdown.md"""
    Block:

    $(123)

    > $(1234)
    """) == @ast Document() do
        Paragraph() do; "Block:"; end
        Paragraph() do
            JuliaValue(nothing, 123)
        end
        BlockQuote() do
            Paragraph() do
                JuliaValue(nothing, 1234)
            end
        end
    end

    # Problematic cases, like manually crafted nodes
    #
    # It is theoretically possible to have inline nodes in block context:
    let m = Markdown.MD()
        push!(m.content, "Foo")
        push!(m.content, Markdown.Link("text", "url"))
        @test convert(Node, m) == @ast Document() do
            Paragraph() do
                "Foo"
            end
            Paragraph() do
                Link("url", "") do
                    "text"
                end
            end
        end
    end

    # Tests from the Documenter Markdown2 module
    @test convert(Node, Markdown.parse(raw"""
    $$
    f
    $$
    """)) == @ast Document() do
        Paragraph() do; JuliaValue(nothing, :$); end
        Paragraph() do; "f "; JuliaValue(nothing, :$); end
    end
    @test convert(Node, Markdown.parse(raw"""
    X $(42) Y
    """)) == @ast Document() do
        Paragraph() do
            "X "
            JuliaValue(nothing, 42)
            " Y"
        end
    end
    @test convert(Node, Markdown.md"""
    #
    """) == @ast Document() do
        Heading(1) do; ""; end
    end

    # Test conversion into nodes with custom metadata
    let md = Markdown.md"xyz"
        @test convert(Node{Nothing}, md) isa Node{Nothing}
        @test_throws MethodError convert(Node{Int}, md)
        @test convert(Node{Vector{Int}}, md) isa Node{Vector{Int}}
        @test convert(Node{Int}, md, () -> 42) isa Node{Int}
        @test_throws TypeError convert(Node{Int}, md, () -> "42") isa Node{Int}
    end
end
