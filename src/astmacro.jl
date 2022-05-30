"""
    @ast markdown-node-expression

A macro that implements a simple domain specific language to easily and explicitly construct
a Markdown AST.

The `markdown-node-expression` must be either:

1. A Markdown element (i.e. some [AbstractElement](@ref) object), such as a constructor call
   (e.g. `Paragraph()`), function call returning an element, or a variable pointing to an
   element.

2. A `do`-block, with the function call part being an element (as above), and the contents
   of the `do`-block a sequence of other node expressions, i.e.

   ```julia
   element do
       child-node-expression-1
       child-node-expression-2
       ...
   end
   ```

In practice, a simple example might look something like

```julia
@ast Document() do
    Heading(1) do
        "Top-level heading"
    end
    Paragraph() do
        "Some paragraph text"
    end
end
```

Strings are interpreted as `Text(s)` elements.
"""
macro ast(expr)
    # First, we convert the Julia AST into nested tuples, for easier parsing:
    ast = astify(expr)
    # And now we parse the tuples, to construct an expression that can actually construct
    # the Node object corresponding to this AST.
    ast_expression(ast...)
end

function astify(expr::Expr)
    # do-expressions are special, but in other cases we just assume the expression is some
    # user code that should be evaluated and it returns a container object (or a string).
    expr.head === :do || return (expr, [])
    # The following assumes we're dealing with a do-expression
    @assert expr.head === :do
    container = expr.args[1]
    # args[2] of a do-block should be a lambda function
    dobody = let expr = expr.args[2]
        @assert expr isa Expr
        @assert expr.head === :(->)
        # Make sure that there are not arguments passed for the do-synta
        @assert expr.args[1] isa Expr
        @assert expr.args[1].head === :tuple
        @assert isempty(expr.args[1].args) # TODO: informative error
        # args[2] of the do-block lambda function is the actual body of the lambda function,
        # i.e. the contents of the do-block itself
        @assert expr.args[2] isa Expr
        @assert expr.args[2].head === :block
        expr.args[2]
    end
    # Extract the children node from the do-block body
    children = Any[]
    for arg in dobody.args
        arg isa LineNumberNode && continue # metadata, can be ignored
        push!(children, astify(arg))
    end
    # We always return a (node, [children]) tuple
    return (container, children)
end
astify(arg::Symbol) = (arg, []) # variable
astify(arg::AbstractString) = (arg, []) # string literal

function ast_expression(container, children)
    parent_node_expr = container_node_expr(container)
    isempty(children) && return parent_node_expr
    # else:
    children_expr = Expr(:tuple)
    for c in children
        push!(children_expr.args, ast_expression(c...))
    end
    quote
        let n = $(parent_node_expr)
            for c in $(children_expr)
                push!(n.children, c)
            end
            n
        end
    end
end

function container_node_expr(container)
    quote
        let c = $(esc(container))
            Node(c isa AbstractString ? Text(c) : c)
        end
    end
end
