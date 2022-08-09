# Interation over trees

The [`Node`](@ref) type implements the [AbstractTrees](https://github.com/JuliaCollections/AbstractTrees.jl) interface which provides various general tree-iteration algorithms.

Using the following MarkdownAST tree as an example:

```@setup iter
using MarkdownAST: @ast, Document, Heading, Paragraph, Strong, CodeBlock
```

```@example iter
md = @ast Document() do
    Heading(1) do; "Iteration example"; end
    Paragraph() do
        "MarkdownAST trees can be iterated over with "
        Strong() do; "AbstractTrees"; end
        "."
    end
    Paragraph() do; "The use it, load the package with"; end
    CodeBlock("julia", "using AbstractTrees")
end
nothing # hide
```

The different [AbstractTrees iterators](https://juliacollections.github.io/AbstractTrees.jl/stable/iteration/), such as `PostOrderDFS`, `PreOrderDFS`, or `Leaves`, can be used to construct iterators from the `md` variable (which is an instance of [`Node`](@ref)).
Each algorithm provides a way to iterate through the trees in a different way, as can be seen in the following examples:

```@example iter
using AbstractTrees
for node in PostOrderDFS(md)
    println(node.element)
end
```

```@example iter
for node in PreOrderDFS(md)
    println(node.element)
end
```

```@example iter
using AbstractTrees
for node in Leaves(md)
    println(node.element)
end
```
