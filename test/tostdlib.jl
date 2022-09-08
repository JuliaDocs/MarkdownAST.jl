using MarkdownAST: MarkdownAST, Node, @ast, Document,
    Emph, Strong, InlineMath, Link, Code, Image,
    Paragraph, Heading, CodeBlock, BlockQuote, DisplayMath, ThematicBreak,
    List, Item, FootnoteLink, FootnoteDefinition, Admonition,
    Table, TableHeader, TableBody, TableRow, TableCell,
    JuliaValue, LineBreak, Backslash, SoftBreak,
    HTMLBlock, HTMLInline
using Markdown: Markdown
using Test

struct UnknownBlock <: MarkdownAST.AbstractBlock end

@testset "Conversion to Markdown stdlib" begin
    @test_throws ErrorException convert(Markdown.MD, @ast Paragraph())
    @test_throws ErrorException convert(Markdown.MD, @ast "...")
    @test convert(Markdown.MD, @ast Document()) isa Markdown.MD

    let ast = @ast Document() do
            UnknownBlock()
        end
        @test_throws ErrorException convert(Markdown.MD, ast)
    end

    let ast = @ast Document() do
            Heading(1) do; "heading 1"; end
            Heading(2)
            Heading(3) do; "heading 3"; end
            Heading(4) do; "heading 4"; end
            Heading(5) do; "heading 5"; end
            Heading(6) do; "heading 6"; end
        end
        md = convert(Markdown.MD, ast)
        @test md isa Markdown.MD
        @test length(md.content) == 6
        for i = 1:6
            @test md.content[i] isa Markdown.Header{i}
            if i == 2
                @test isempty(md.content[i].text)
            else
                @test md.content[i].text == ["heading $i"]
            end
        end
        @test convert(Node, md) == ast
    end

    let ast = @ast Document() do
            Paragraph() do
                "foo "
                Emph()
                Strong() do
                    Emph() do; "bar "; end
                    "baz"
                end
            end
            Paragraph()
            BlockQuote() do
                Paragraph() do; "foo"; end
            end
        end
        md = convert(Markdown.MD, ast)
        @test md isa Markdown.MD
        @test length(md.content) == 3
        @test md.content[1] isa Markdown.Paragraph
        @test md.content[2] isa Markdown.Paragraph
        @test md.content[3] isa Markdown.BlockQuote
        @test length(md.content[1].content) == 3
        @test length(md.content[3].content) == 1
        @test md.content[1].content[1] == "foo "
        @test md.content[1].content[2] isa Markdown.Italic
        @test md.content[1].content[3] isa Markdown.Bold
        @test length(md.content[1].content[3].text) == 2
        @test md.content[1].content[3].text[1] isa Markdown.Italic
        @test md.content[1].content[3].text[2] == "baz"
        @test convert(Node, md) == ast
    end

    let ast = @ast Document() do
            Heading(1) do; "Heading!"; end
            Admonition("warning", "Warning admonition !") do
                Paragraph() do; "..."; end
            end
            CodeBlock("julia", "versioninfo()")
            DisplayMath("x^2")
            ThematicBreak()
            Paragraph() do
                Code("y = f(x)")
                InlineMath("y = f(x)")
            end
        end
        md = convert(Markdown.MD, ast)
        @test ast == convert(Node, md)
    end

    # JuliaValue
    let ast = @ast Document() do
            Paragraph() do
                JuliaValue(:x, 42)
                JuliaValue(43, 43)
                JuliaValue(:y, nothing)
            end
        end
        md = convert(Markdown.MD, ast)
        # When converting to Markdown, the original expression of JuliaValue
        # gets lost.
        @test convert(Node, md) == @ast Document() do
            Paragraph() do
                JuliaValue(nothing, 42)
                JuliaValue(nothing, 43)
                JuliaValue(nothing, nothing)
            end
        end
    end

    # Footnotes
    let ast = @ast MarkdownAST.Document() do
            MarkdownAST.Paragraph() do
                "Text"
                MarkdownAST.FootnoteLink("note")
                "."
            end
            MarkdownAST.FootnoteDefinition("note") do
                MarkdownAST.Paragraph() do; "Note this"; end
            end
        end
        md = convert(Markdown.MD, ast)
        @test convert(Node, md) == ast
    end

    # Links and images
    let ast = @ast MarkdownAST.Document() do
            MarkdownAST.Paragraph() do
                MarkdownAST.Link("url", "title") do
                    MarkdownAST.Text("foo")
                    MarkdownAST.Strong() do; "bar"; end
                end
                MarkdownAST.Image("url", "title") do
                    MarkdownAST.Text("foo")
                    MarkdownAST.Strong() do; "bar"; end
                end
            end
        end
        md = convert(Markdown.MD, ast)
        # The .title attribute gets lost because Markdown does not store that information.
        # Also, the Markdown.Image element does not store the link contents as AST, but
        # just as a plain string. So when converting from MarkdownAST, we turn the internals
        # into a string with Markdown.plain().
        @test convert(Node, md) == @ast MarkdownAST.Document() do
            MarkdownAST.Paragraph() do
                MarkdownAST.Link("url", "") do
                    MarkdownAST.Text("foo")
                    MarkdownAST.Strong() do
                    MarkdownAST.Text("bar")
                    end
                end
                MarkdownAST.Image("url", "") do
                    MarkdownAST.Text("foo**bar**")
                end
            end
        end
    end

    # Lists
    let ast = @ast Document() do
            List(:ordered, true) do
                Item() do; Paragraph() do; "foo"; end; end
                Item() do; Paragraph() do; "bar"; end; end
            end
            List(:ordered, false) do
                Item() do; Paragraph() do; "foo"; end; end
                Item() do; Paragraph() do; "bar"; end; end
            end
            List(:bullet, true) do
                Item() do; Paragraph() do; "foo"; end; end
                Item() do; Paragraph() do; "bar"; end; end
            end
            List(:bullet, false) do
                Item() do; Paragraph() do; "foo"; end; end
                Item() do; Paragraph() do; "bar"; end; end
            end
        end
        md = convert(Markdown.MD, ast)
        @test convert(Node, md) == @ast Document() do
            List(:ordered, true) do
                Item() do; Paragraph() do; "foo"; end; end
                Item() do; Paragraph() do; "bar"; end; end
            end
            List(:ordered, false) do
                Item() do; Paragraph() do; "foo"; end; end
                Item() do; Paragraph() do; "bar"; end; end
            end
            List(:bullet, true) do
                Item() do; Paragraph() do; "foo"; end; end
                Item() do; Paragraph() do; "bar"; end; end
            end
            List(:bullet, false) do
                Item() do; Paragraph() do; "foo"; end; end
                Item() do; Paragraph() do; "bar"; end; end
            end
        end
    end

    # Tables
    @test MarkdownAST._invert_column_spec(:left) === :l
    @test MarkdownAST._invert_column_spec(:right) === :r
    @test MarkdownAST._invert_column_spec(:center) === :c
    @test MarkdownAST._invert_column_spec(:foo) === :f
    let ast = @ast Document() do
            Table([:left, :right, :center]) do
                TableHeader() do
                    TableRow() do
                        TableCell(:left,   true, 1) do; "1,1"; end
                        TableCell(:right,  true, 2) do; "1,2"; end
                        TableCell(:center, true, 3) do; "1,3"; end
                    end
                end
                TableBody() do
                    TableRow() do
                        TableCell(:left,   false, 1) do; "2,1"; end
                        TableCell(:right,  false, 2) do; "2,2"; end
                        TableCell(:center, false, 3) do; "2,3"; end
                    end
                    TableRow() do
                        TableCell(:left,   false, 1) do; "3,1"; end
                        TableCell(:right,  false, 2) do; "3,2"; end
                        TableCell(:center, false, 3) do; "3,3"; end
                    end
                end
            end
        end
        md = convert(Markdown.MD, ast)
        @test convert(Node, md) == ast
    end
    # TODO: should also tests tables that are problematic

    # Whitespace
    let ast = @ast MarkdownAST.Document() do
            Paragraph() do
                "foo"
                LineBreak()
                "bar"
                SoftBreak()
                Backslash()
                "baz"
            end
        end
        md = convert(Markdown.MD, ast)
        # Markdown does not have SoftBreak nor backslash nodes, so they get replaced
        # with the corresponding strings / text nodes.
        @test convert(Node, md) == @ast MarkdownAST.Document() do
            Paragraph() do
                "foo"
                LineBreak()
                "bar"
                " "
                "\\"
                "baz"
            end
        end
    end

    # HTML elements
    let ast = @ast MarkdownAST.Document() do
            HTMLBlock("<html>")
            Paragraph() do; HTMLInline("</html>"); end
        end
        md = convert(Markdown.MD, ast)
        # Markdown can't represent raw HTML, so it gets converted into Code
        # nodes instead
        @test convert(Node, md) == @ast MarkdownAST.Document() do
            CodeBlock("html", "<html>")
            Paragraph() do; Code("</html>"); end
        end
    end
end
