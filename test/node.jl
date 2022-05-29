using MarkdownAST: MarkdownAST,
    Node, parent, next, previous, children, haschildren, @ast,
    Document, Paragraph, BlockQuote, CodeBlock, HTMLBlock
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
    @test parent(root) === nothing
    @test next(root) === nothing
    @test previous(root) === nothing
    @test length(children(root)) == 0
    @test collect(children(root)) == Node[]
    @test haschildren(root) === false
    let n1 = Node(Paragraph())
        push!(root, n1)
        @test length(children(root)) == 1
        @test collect(children(root)) == Node[n1]
        @test haschildren(root) === true
        @test haschildren(n1) === false
        # Add another child
        n2 = Node(HTMLBlock(""))
        push!(root, n2)
        @test length(children(root)) == 2
        @test collect(children(root)) == Node[n1, n2]
        # Push the first child again. This should unlink it from the original
        # position.
        push!(root, n1)
        @test length(children(root)) == 2
        @test collect(children(root)) == Node[n2, n1]
        # Same as before, but for pushfirst!
        n3 = Node(Paragraph())
        pushfirst!(root, n3)
        @test length(children(root)) == 3
        @test collect(children(root)) == Node[n3, n2, n1]
        # Unlinking with pushfirst!
        pushfirst!(root, n2)
        @test length(children(root)) == 3
        @test collect(children(root)) == Node[n2, n3, n1]
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
        @test length(children(tree)) == 3
        @test haschildren(tree) === true
        # Check the children:
        cs = collect(children(tree))
        # first child
        @test cs[1].element isa Paragraph
        @test length(children(cs[1])) == 1
        @test parent(cs[1]) === tree
        @test previous(cs[1]) === nothing
        @test next(cs[1]) === cs[2]
        # second child
        @test cs[2].element isa BlockQuote
        @test length(children(cs[2])) == 3
        @test parent(cs[2]) == tree
        @test previous(cs[2]) === cs[1]
        @test next(cs[2]) === cs[3]
        let cs = collect(children(cs[2]))
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
        @test length(children(cs[3])) == 0
        @test parent(cs[3]) == tree
        @test previous(cs[3]) === cs[2]
        @test next(cs[3]) === nothing
    end
end
