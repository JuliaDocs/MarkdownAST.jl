using MarkdownAST: MarkdownAST,
    Node, haschildren, @ast,
    Document, Paragraph, BlockQuote, CodeBlock, HTMLBlock,
    NodeChildren
using Test

# Compat-ish.. startswith(prefix) was added in 1.5:
_startswith(prefix) = s -> startswith(s, prefix)

@testset "Node" begin
    # Basic constructors
    @test Node(Document()) isa Node{Nothing}
    @test_throws MethodError Node(Document(), nothing)
    @test_throws MethodError Node(Document(), 1)
    @test Node{Int}(Document(), 1) isa Node{Int}

    # Make sure that we discard the {Nothing} type parameter for the "standard"
    # node when printing:
    @test repr(Node(Document())) |> _startswith("Node(")
    # note: interpolating Int because it's an alias, and is actually 'Int64'
    @test repr(Node{Int}(Document(), 1)) |> _startswith("Node{$(Int)}(")

    # Accessing the container of the node:
    let n = Node(Document())
        @test n.element isa Document
        @test_throws TypeError n.element = 2
        n.element = MarkdownAST.Text("...")
        @test n.element isa MarkdownAST.Text
    end

    # Construct a simple tree:
    root = Node(Document())
    # Test various accessor methods on an isolated node:
    @test root.parent === nothing
    @test root.next === nothing
    @test root.next === nothing
    @test length(root.children) == 0
    @test collect(root.children) == Node[]
    @test haschildren(root) === false
    let n1 = Node(Paragraph())
        @test push!(root.children, n1) == root.children
        @test length(root.children) == 1
        @test collect(root.children) == Node[n1]
        @test haschildren(root) === true
        @test haschildren(n1) === false
        # Add another child
        n2 = Node(HTMLBlock(""))
        @test push!(root.children, n2) == root.children
        @test length(root.children) == 2
        @test collect(root.children) == Node[n1, n2]
        # Push the first child again. This should unlink it from the original
        # position.
        @test push!(root.children, n1) == root.children
        @test length(root.children) == 2
        @test collect(root.children) == Node[n2, n1]
        # Same as before, but for pushfirst!
        n3 = Node(Paragraph())
        @test pushfirst!(root.children, n3) == root.children
        @test length(root.children) == 3
        @test collect(root.children) == Node[n3, n2, n1]
        # Unlinking with pushfirst!
        @test pushfirst!(root.children, n2) == root.children
        @test length(root.children) == 3
        @test collect(root.children) == Node[n2, n3, n1]
    end

    # Constructing trees with the @ast macro
    let
        stringvar = "bar"
        containervar = CodeBlock("lang", "code()")
        tree = @ast Document() do
            Paragraph() do
                "Foo"
            end
            BlockQuote() do
                stringvar
                "Foo"
                MarkdownAST.Text(stringvar) # call expr
            end
            containervar
        end
        @test tree.element isa Document
        @test length(tree.children) == 3
        @test haschildren(tree) === true
        # Check the children:
        cs = collect(tree.children)
        # first child
        @test cs[1].element isa Paragraph
        @test length(cs[1].children) == 1
        @test cs[1].parent === tree
        @test cs[1].previous === nothing
        @test cs[1].next === cs[2]
        # second child
        @test cs[2].element isa BlockQuote
        @test length(cs[2].children) == 3
        @test cs[2].parent == tree
        @test cs[2].previous === cs[1]
        @test cs[2].next === cs[3]
        let cs = collect(cs[2].children)
            @test cs[1].element isa MarkdownAST.Text
            @test cs[2].element isa MarkdownAST.Text
            @test cs[3].element isa MarkdownAST.Text
            @test cs[1].element.text == "bar"
            @test cs[2].element.text == "Foo"
            @test cs[3].element.text == "bar"
        end
        # third child
        @test cs[3].element isa CodeBlock
        @test haschildren(cs[3]) === false
        @test length(cs[3].children) == 0
        @test cs[3].parent == tree
        @test cs[3].previous === cs[2]
        @test cs[3].next === nothing
    end
end
