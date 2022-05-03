# MarkdownAST

The structure of a Markdown file can be represented as an [abstract syntax tree](https://en.wikipedia.org/wiki/Abstract_syntax_tree).
The MarkdownAST package defines a Julia interface for representing such trees to facilitate the interoperability between different packages that deal with Markdown documents in different ways.

While the primary goal is to represent Markdown documents, the tree structure, implemented by the [`Node`](@ref) type and the [`AbstractElement`](@ref MarkdownAST.AbstractElement) subtypes, is intentionally generic and can also be used to represent more general documents.
