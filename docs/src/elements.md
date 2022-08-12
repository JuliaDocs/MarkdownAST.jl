```@meta
CurrentModule = MarkdownAST
```

# Markdown AST elements

Every node in the Markdown abstract syntax tree (AST) is associated with an _element_[^1], providing semantic information to the node (e.g. that the node is a paragraph, or a inline code snippet).
In MarkdownAST, each element is an instance of some subtype of [`AbstractElement`](@ref), and may (but does not have to) have fields that contain additional information about how to interpret the element (e.g. the language tag of a code block).

```@docs
AbstractElement
```

If an element does contain some fields, it is usually a mutable type so that it would be possible to update it.

When the Markdown AST is represented using [`Node`s](@ref MarkdownAST.Node), the corresponding elements can be accessed via the `.element` field.

[^1]: This terminology mirrors how each node of the HTML DOM tree is some HTML element.

## Block and inline nodes

In the Markdown AST, the elements can, broadly, be divided into two categories: block and inline elements.
The block elements represent the main, top-level structural elements of a document (e.g. paragraphs, headings, block quotes), whereas inline elements represent components of a paragraph (e.g. bold or plain text, inline math or code snippets).
In MarkdownAST, every block and inline element is a subtype of [`AbstractBlock`](@ref) and [`AbstractInline`](@ref), respectively.

```@docs
AbstractBlock
AbstractInline
isblock
isinline
```

## Constraints on children

As the AST is a tree, nodes (or elements) can have other nodes or elements as children.
However, it does not generally make sense for a node to have arbitrary nodes as children.
For this purpose, there are methods to ensure

First, for some elements it does not make sense for them to have any children at all (i.e. they will always be _leaf_ nodes).
Whether or not an node is a _container_ node (i.e. whether or not it can have other elements as children) is determined by the [`iscontainer`](@ref) function.

```@docs
iscontainer
```

However, a more fine-grained control over the allowed child nodes is often necessary.
For example, while a paragraph can have child nodes, it does not make sense for a paragraph to have another paragraph as a child node, and in fact it should only have inline nodes as children.
Such relationships are defined by the [`can_contain`](@ref) function (e.g. for a [`Paragraph`](@ref) it only returns `true` if the child element is an [`AbstractInline`](@ref)).

```@docs
can_contain
```

Usually, the constraint is whether a container node can contain only block elements or only inline elements.

!!! note

    Sometimes it might be desireable to have even more sophisticated constraints on the elements (e.g. perhaps two elements are not allowed to directly follow each other as children of another node).
    However, it is not practical to over-complicate the APIs here, and simply restricting the child elements of another element seems to strike a good balance.

    Instead, in cases where it becomes possible to construct trees that have questionable semantics due to a weird structure that can not be restricted with [`can_contain`](@ref), the elements should carefully document how to interpret such problematic trees (e.g. how to interpret a table that has no rows and columns).

## CommonMark elements

The [CommonMark specification](https://spec.commonmark.org/) specifies a set of block and inline nodes that can be used to represent Markdown documents.

```@docs
Backslash
BlockQuote
Code
CodeBlock
Emph
FootnoteDefinition
FootnoteLink
HTMLBlock
HTMLInline
Heading
Image
Item
LineBreak
Link
List
Paragraph
SoftBreak
Strong
Text
ThematicBreak
```

## Julia extension elements

The Julia version of Markdown contains additional elements that do not exists in the CommonMark specification (such as tables or math).
However, as MarkdownAST is meant to be interoperable with the `Markdown` standard library parser, it also supports additional elements to accurately represent the Julia Flavored Markdown documents.

```@docs
Admonition
DisplayMath
InlineMath
JuliaValue
Table
TableBody
TableCell
TableHeader
TableRow
```

## Other elements

[`Document`](@ref) is the root element of a Markdown document.

```@docs
Document
```

## Index

```@index
Pages = ["elements.md"]
```
