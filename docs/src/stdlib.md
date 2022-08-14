```@meta
CurrentModule = MarkdownAST
```

# Conversion to and from `Markdown` standard library

The [`Markdown` standard library](https://docs.julialang.org/en/v1/stdlib/Markdown/) in Julia provides an alternative representation of the Markdown AST.
In particular, the parser and AST there is internally used by Julia for docstrings, and is also used by some of the tooling in the Julia ecosystem that deals with Markdown.

MarkdownAST supports bi-directional conversion between the two AST representations via the `convert` function.
The conversion, however, is not perfect since there are differences in what and how the two libraries represent the Markdown AST.

## Conversion from standard library representation

Any AST that is produced by the `Markdown` standard library parser should parse into MarkdownAST AST.
However, as the data structures for the elements in `Markdown` are pretty loose in what they allow, user-crafted `Markdown` ASTs may error if it does not exactly follow the conventions of the `Markdown` parser.

```@docs
Base.convert(::Type{Node}, md::Markdown.MD)
```

Due to the differences between the Markdown representations, the following things should be kept in mind when converting from the standard library AST into MarkdownAST representation:

- The standard library parser does not have a dedicated type for representing backslashes, and instead stores them as separate single-character text nodes containing a backslash (i.e. `"\\"`).
- Soft line breaks are ignored in the standard library parser and represented with a space instead.
- Strings (or `Markdown` elements) interpolated into the standard library Markdown (e.g. in docstrings or with the `@md_str` macro) are indistinguishable from text (or corresponding Markdown) nodes in the standard library AST, and therefore will not be converted into [`JuliaValue`s](@ref JuliaValue).
- The standard library allows for block-level interpolation. These get converted into inline [`JuliaValue`s](@ref JuliaValue) wrapped in a [`Paragraph`](@ref) element.
- In case the standard library AST contains any inline nodes in block context (e.g. as children for `Markdown.MD`), the get wrapped in a [`Paragraph`](@ref) element too.
- When converting a `Markdown.Table`, the resulting table will be normalized, such as adding empty cells to rows, to make sure that all rows have the same number of cells.
- For links and images, the `.title` attribute is set to an empty string, since the standard library AST does not support parsing titles.

## Conversion to standard library representation

Any AST that contains only [the native MarkdownAST elements](@ref "Markdown AST elements") can be converted into the standard library representation.
The conversion of user-defined elements, however, is not supported and will lead to an error.

```@docs
Base.convert(::Type{Markdown.MD}, node::Node)
```

Due to the differences between the Markdown representations, the following things should be kept in mind when converting from the MarkdownAST representation into the standard library AST:

- The value from a [`JuliaValue`](@ref) element (i.e. `.ref`) gets stored directly in the AST (just like variable interpolation with docstrings and the `@md_str` macro). This means that, for example, an interpolated string or `Markdown` element would become a valid AST element, losing the information that it used to be interpolated.
- The expression information in a [`JuliaValue`](@ref) element (i.e. the `.ex` field) gets discarded.
- The `.title` attribute of [`Link`](@ref) and [`Image`](@ref) elements gets discarded.
- The standard library does not support storing the child nodes of [`Image`](@ref) elements (i.e. "alt text", `![alt text]()`) as AST, and it is instead reduced to a string with the help of the `Markdown.plain` function.
- The standard library AST does not have dedicated elements for [`SoftBreak`](@ref) and [`Backslash`](@ref), and these get converted into strings (i.e. text elements) instead.

## Index

```@index
Pages = ["stdlib.md"]
```
