using MarkdownAST
using MarkdownAST: AbstractElement, AbstractBlock, AbstractInline,
    Document,
    Admonition, BlockQuote, CodeBlock, DisplayMath, FootnoteDefinition, HTMLBlock, Heading,
    Item, List, Paragraph, TableComponent, ThematicBreak,
    Code, Emph, FootnoteLink, HTMLInline, Image, InlineMath, Link, Strong, TablePipe, Text,
    iscontainer, can_contain, isblock, isinline
using Test

# To test the various can_contain etc. relationships, we'll define two pseudo-elements with
# default behaviours that we can use in the tests later on:
struct PseudoBlock <: AbstractBlock
    iscontainer :: Bool
end
MarkdownAST.iscontainer(e::PseudoBlock) = e.iscontainer
struct PseudoInline <: AbstractInline
    iscontainer :: Bool
end
MarkdownAST.iscontainer(e::PseudoInline) = e.iscontainer

@testset "Markdown AST" begin
    # Check that the pseudo-elements make sense:
    @test iscontainer(PseudoBlock(true))
    @test isblock(PseudoBlock(true))
    @test ! isinline(PseudoBlock(true))

    @test ! iscontainer(PseudoBlock(false))
    @test isblock(PseudoBlock(false))
    @test ! isinline(PseudoBlock(false))

    @test iscontainer(PseudoInline(true))
    @test ! isblock(PseudoInline(true))
    @test isinline(PseudoInline(true))

    @test ! iscontainer(PseudoInline(false))
    @test ! isblock(PseudoInline(false))
    @test isinline(PseudoInline(false))

    # Elements come in broadly five different categories:
    #
    # 1. Blocks that contain other blocks.
    # 2. Blocks that contain inlines.
    # 3. Block leafs.
    # 4. Inlines that contain inlines.
    # 5. Inline leafs.
    #
    # First, (1) blocks that contain other blocks:
    for e in [
        Document(), Admonition("category", "title"), BlockQuote(), FootnoteDefinition("id"),
    ]
        @test iscontainer(e)
        @test isblock(e)
        @test ! isinline(e)
        @test can_contain(e, PseudoBlock(false))
        @test ! can_contain(e, PseudoInline(false))
        @test can_contain(PseudoBlock(true), e)
        @test ! can_contain(PseudoInline(true), e)
    end
    # (2) blocks that contain inlines
    @test_throws Exception Heading(0)
    @test_throws Exception Heading(-100)
    @test_throws Exception Heading(7)
    @test_throws Exception Heading("100")
    @test_throws Exception Heading(6.234im)
    for e in [Heading(1), Paragraph()]
        @test iscontainer(e)
        @test isblock(e)
        @test ! isinline(e)
        @test ! can_contain(e, PseudoBlock(false))
        @test can_contain(e, PseudoInline(false))
        @test can_contain(PseudoBlock(true), e)
        @test ! can_contain(PseudoInline(true), e)
    end
    # (3) leaf blocks
    for e in [
        CodeBlock("info", "code"), DisplayMath("math"), HTMLBlock("html"), ThematicBreak()
    ]
        @test ! iscontainer(e)
        @test isblock(e)
        @test ! isinline(e)
        @test ! can_contain(e, PseudoBlock(false))
        @test ! can_contain(e, PseudoInline(false))
        @test can_contain(PseudoBlock(true), e)
        @test ! can_contain(PseudoInline(true), e)
    end

    # (4) Inlines containing inlines:
    for e in [Link("url", "title"), Image("url", "title"), Emph(), Strong()]
        @test iscontainer(e)
        @test ! isblock(e)
        @test isinline(e)
        @test ! can_contain(e, PseudoBlock(false))
        @test can_contain(e, PseudoInline(false))
        @test ! can_contain(PseudoBlock(true), e)
        @test can_contain(PseudoInline(true), e)
    end
    # (5) Inline leafs:
    for e in [
        Code("code"), FootnoteLink("id"), HTMLInline("html"), InlineMath("math"), Text("text")
    ]
        @test ! iscontainer(e)
        @test ! isblock(e)
        @test isinline(e)
        @test ! can_contain(e, PseudoBlock(false))
        @test ! can_contain(e, PseudoInline(false))
        @test ! can_contain(PseudoBlock(true), e)
        @test can_contain(PseudoInline(true), e)
    end

    # Lists are special:
    # List, Item

    # As are tables:
    # TableComponent, TablePipe
end
