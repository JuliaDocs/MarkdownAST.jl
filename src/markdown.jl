# While these are not hard requirements, in general:
#
# - If a container does not contain any metadata, it should be implemented as a
#   simple non-mutable singleton (struct Foo end).
# - If a container contains some metadata (e.g. a link URL), then it should be
#   implemented as a mutable struct, so that it would be possible to manipulate
#   the container contents.

"""
    abstract type AbstractElement

A supertype of all Markdown AST element types.

User-defined elements must not directly inherit this type, but either
[`AbstractBlock`](@ref) or [`AbstractInline`](@ref) instead.

# Interface

* By default, each element is assumed to be a leaf element that can not contain other
  elements as children. An [`iscontainer`](@ref) method can be defined to override this.

* [`can_contain`](@ref) can be overridden to constrain what elements can be the direct
  children of another node. By default, inline container elements can contain any inline
  element and block container elements can contain any block element.

* Elements that are implemented as `mutable struct`s should probably implement the equality
  operator (`==`), to make sure that two different instances that are semantically the same
  would be considered equal.
"""
abstract type AbstractElement end

"""
    abstract type AbstractBlock <: AbstractElement

Supertype of all Markdown AST block types.
"""
abstract type AbstractBlock <: AbstractElement end

"""
    abstract type AbstractInline <: AbstractElement

Supertype of all Markdown AST inline types.
"""
abstract type AbstractInline <: AbstractElement end

"""
    isblock(element::AbstractElement) -> Bool

Determines if `element` is a block element (a subtype of [`AbstractBlock`](@ref)).
"""
function isblock end
isblock(::AbstractBlock) = true
isblock(::AbstractInline) = false

"""
    isinline(element::AbstractElement) -> Bool

Determines if `element` is an inline element (a subtype of [`AbstractInline`](@ref)).
"""
function isinline end
isinline(::AbstractBlock) = false
isinline(::AbstractInline) = true

"""
    iscontainer(::T) where {T <: AbstractElement} -> Bool

Determines if the particular Markdown element is a container, meaning that is can contain
child nodes. Adding child nodes to non-container (leaf) nodes is prohibited.

By default, each user-defined element is assumed to be a leaf node, and each container node
should override this method.
"""
function iscontainer end
iscontainer(::AbstractElement) = false

"""
    can_contain(parent::AbstractElement, child::AbstractElement) -> Bool

Determines if the `child` element can be a direct child of the `parent` element.

This is used to constrain the types of valid children for some elements, such as for the
elements that are only allowed to have inline child elements or to make sure that
[`List`s](@ref List) only contain [`Item`s](@ref Item).

If the `parent` element is a leaf node (`iscontainer(parent) === false`)

# Extended help

When extending `can_contain` for custom abstract classes Markdown elements, similar to the
[`AbstractBlock`](@ref) or [`AbstractInline`](@ref) elements classes, the second argument to
[`can_contain`](@ref) should always be constrained exactly to `::AbstractElement`, in order
to avoid method ambiguities. I.e. for some abstract type `AbstractT  <: AbstractElement`,
the method should be defined as

```julia
can_contain(parent::AbstractT, child::AbstractElement) = ...
```

For concrete parent types `T`, where the first argument is constrained as `parent::T` it
should then be fine to take advantage of multiple dispatch when implementing
[`can_contain`](@ref).
"""
function can_contain end
# These methods ensure that, by default, container blocks/inlines are allowed to contain
# any blocks/inlines (respectively). However, we need the isa() calls here because the
# AbstractBlock and AbstractInline are abstract types.
can_contain(parent::AbstractBlock, child::AbstractElement) = iscontainer(parent) && isa(child, AbstractBlock)
can_contain(parent::AbstractInline, child::AbstractElement) = iscontainer(parent) && isa(child, AbstractInline)
# The following method will be called if one mixes blocks and inlines (unless specifically
# overridden), and also functions as the ultimate fallback for can_contain.
can_contain(parent::AbstractElement, child::AbstractElement) = false

"""
    struct Document <: AbstractBlock

Singleton top-level element of a Markdown document.
"""
struct Document <: AbstractBlock end
iscontainer(::Document) = true

# CommonMark block containers:

# TODO: The CommonMark.jl list contains additional metadata, via the `ListData` object,
# which is also passed on to the children.
"""
    mutable struct List <: AbstractBlock

Represents a Markdown list.
The children of a `List` should only be [`Item`s](@ref Item), representing
individual list items.

# Fields

* `.type :: Symbol`: determines if this is an ordered (`:ordered`) or an unordered
  (`:bullet`) list.
* `.tight :: Bool`: determines if the list should be rendered tight or loose.

# Constructors

```julia
List(type :: Symbol, tight :: Bool)
````
"""
mutable struct List <: AbstractBlock
    type :: Symbol # TODO: change to enum?
    tight :: Bool

    function List(type::Symbol, tight::Bool)
        type === :bullet || type === :ordered || error("type must be :bullet or :ordered")
        new(type, tight)
    end
end
iscontainer(::List) = true

"""
    struct Item <: AbstractBlock

Singleton container representing the items of a [`List`](@ref).
"""
struct Item <: AbstractBlock end
iscontainer(::Item) = true
# List can only contain Item, and Item can only be contained in a List.
can_contain(::List, ::AbstractElement) = false
can_contain(::AbstractElement, ::Item) = false
can_contain(::List, ::Item) = true

"""
    struct ThematicBreak <: AbstractBlock

A singleton leaf element representing a thematic break (often rendered as a horizontal
rule).
"""
struct ThematicBreak <: AbstractBlock end

"""
    struct BlockQuote <: AbstractBlock

A singleton container element representing a block quote. It must contain other block
elements as children.
"""
struct BlockQuote <: AbstractBlock end
iscontainer(::BlockQuote) = true

"""
    mutable struct Heading <: AbstractBlock

Represents a heading of a specific level. Can only contain inline elements as children.

# Fields

* `.level :: Int`: the level of the heading, must be between `1` and `6`.

# Constructors

```julia
Heading(level :: Integer)
```
"""
mutable struct Heading <: AbstractBlock
    level :: Int
    function Heading(level :: Integer)
        1 <= level <= 6 || error("level must be 1 <= level <= 6")
        new(level)
    end
end
iscontainer(::Heading) = true
# Can only contain inline elements and not block elements:
can_contain(::Heading, ::AbstractInline) = true
can_contain(::Heading, ::AbstractBlock) = false
Base.:(==)(x::Heading, y::Heading) = (x.level == y.level)

"""
    struct Paragraph <: AbstractBlock

Singleton container representing a paragraph, containing only inline nodes.
"""
struct Paragraph <: AbstractBlock end
iscontainer(::Paragraph) = true
# Can only contain inline elements and not block elements:
can_contain(::Paragraph, ::AbstractInline) = true
can_contain(::Paragraph, ::AbstractBlock) = false

"""
    mutable struct HTMLBlock <: AbstractBlock

A leaf block representing raw HTML.
"""
mutable struct HTMLBlock <: AbstractBlock
    html :: String
end
Base.:(==)(x::HTMLBlock, y::HTMLBlock) = (x.html == y.html)

"""
    mutable struct CodeBlock <: AbstractBlock

A leaf block representing a code block.

# Fields

* `.info :: String`: code block info string (e.g. the programming language label)
* `.code :: String`: code content of the block
"""
mutable struct CodeBlock <: AbstractBlock
    info :: String
    code :: String
    # TODO: `info` shouldn't contain any backtick characters. Restrict in constructor?
end
Base.:(==)(x::CodeBlock, y::CodeBlock) = (x.info == y.info) && (x.code == y.code)

# CommonMark inline containers:

"""
    mutable struct Link <: AbstractInline

Inline element representing a link. Can contain other inline nodes, but should not contain
other [`Link`s](@ref).

# Fields

* `.destination :: String`: destination URL
* `.title :: String`: title attribute of the link

# Constructors

```julia
Link(destination::AbstractString, title::AbstractString)
```
"""
mutable struct Link <: AbstractInline
    destination :: String
    title :: String
end
iscontainer(::Link) = true
Base.:(==)(x::Link, y::Link) = (x.destination == y.destination) && (x.title == y.title)

"""
    mutable struct Image <: AbstractInline

Inline element representing a link to an image. Can contain other inline nodes that will
represent the image description.

# Fields

* `.destination :: String`: destination URL
* `.title :: String`: title attribute of the link

# Constructors

```julia
Link(destination::AbstractString, title::AbstractString)
```
"""
mutable struct Image <: AbstractInline
    destination :: String
    title :: String
end
iscontainer(::Image) = true
Base.:(==)(x::Image, y::Image) = (x.destination == y.destination) && (x.title == y.title)

"""
    mutable struct HTMLInline <: AbstractInline

Inline leaf element representing raw inline HTML.

# Fields

* `.html :: String`: inline raw HTML

# Constructors

```julia
HTMLInline(html::AbstractString)
```
"""
mutable struct HTMLInline <: AbstractInline
    html :: String
end
Base.:(==)(x::HTMLInline, y::HTMLInline) = (x.html == y.html)

"""
    struct Emph <: AbstractInline

Inline singleton element for emphasis (e.g. italic) styling.
"""
struct Emph <: AbstractInline end
iscontainer(::Emph) = true

"""
    struct Strong <: AbstractInline

Inline singleton element for strong (e.g. bold) styling.
"""
struct Strong <: AbstractInline end
iscontainer(::Strong) = true

"""
    mutable struct Code <: AbstractInline

Inline element representing an inline code span.

# Fields

* `.code :: String`: raw code

# Constructors

```julia
Code(code::AbstractString)
```
"""
mutable struct Code <: AbstractInline
    code :: String
end
Base.:(==)(x::Code, y::Code) = (x.code == y.code)

"""
    mutable struct Text <: AbstractInline

Inline leaf element representing a simply a span of text.
"""
mutable struct Text <: AbstractInline
    text :: String
end
Base.:(==)(x::Text, y::Text) = (x.text == y.text)

# Julia Markdown extensions:

"""
    mutable struct Admonition <: AbstractBlock

# Fields

* `.category :: String`: admonition category
* `.title :: String`: admonition title

# Constructors
```julia
Admonition(category :: AbstractString, title :: AbstractString)
```
"""
mutable struct Admonition <: AbstractBlock
    category :: String
    title :: String
end
iscontainer(::Admonition) = true
Base.:(==)(x::Admonition, y::Admonition) = (x.category == y.category) && (x.title == y.title)

"""
    mutable struct DisplayMath <: AbstractBlock

Leaf block representing a mathematical display equation.

# Fields

* `.math :: String`: TeX code of the display equation

# Constructors

```julia
DisplayMath(math :: AbstractString)
```
"""
mutable struct DisplayMath <: AbstractBlock
    math :: String
end
Base.:(==)(x::DisplayMath, y::DisplayMath) = (x.math == y.math)

"""
    mutable struct InlineMath <: AbstractInline

Leaf inline element representing an inline mathematical expression.

# Fields

* `.math :: String`: TeX code for the inline equation

# Constructors

```julia
InlineMath(math::String)
```
"""
mutable struct InlineMath <: AbstractInline
    math :: String
end
Base.:(==)(x::InlineMath, y::InlineMath) = (x.math == y.math)

# TODO: In CommonMark, these were actually immutable..?
# TODO: Does this have to contain block elements, or can it also contain inline elements
#       directly?
"""
    mutable struct FootnoteDefinition <: AbstractBlock

Container block representing the definition of a footnote, containing the definitions of the
footnote as children.

# Fields

* `.id :: String`: label of the footnote

# Constructors

```julia
FootnoteDefinition(id :: AbstractString)
```
"""
mutable struct FootnoteDefinition <: AbstractBlock
    id :: String
end
iscontainer(::FootnoteDefinition) = true
Base.:(==)(x::FootnoteDefinition, y::FootnoteDefinition) = (x.id == y.id)

"""
    mutable struct FootnoteLink <: AbstractInline

Inline leaf element representing a link to a footnote.

# Fields

* `.id :: String`: label of the footnote

# Constructors

```julia
FootnoteLink(id :: AbstractString)
```
"""
mutable struct FootnoteLink <: AbstractInline
    id :: String
    # TODO: Also had this field in CommonMark:
    #rule::FootnoteRule
end
Base.:(==)(x::FootnoteLink, y::FootnoteLink) = (x.id == y.id)

# Markdown tables:
abstract type TableComponent <: AbstractBlock end
iscontainer(::TableComponent) = true

"""
    mutable struct Table <: TableComponent

Container block representing a table, an extension of the CommonMark spec, and should be
interpreted as a rectangular grid of cells with a fixed number of rows and columns.

* A [`Table`](@ref) node can only contain either [`TableHeader`](@ref) or
  [`TableBody`](@ref) nodes as children.
* [`TableHeader`](@ref) and [`TableBody`](@ref) can only contain [`TableRow`](@ref)s
  as children. A [`TableHeader`](@ref) should contain only a single [`TableRow`](@ref), and
  any additional ones should be ignored.
* Each [`TableRow`](@ref) contains only [`TableCell`](@ref)s as children. The row with the
  largest number of cells determines the width (number of columns) of the table.

Since we can not constrain e.g. the number of children or in what order child nodes can
appear in a Markdown tree, it is possible to construct tables that can be difficult to
interpret. The following rules should be followed when interpreting tables:

* The decendants of a [`Table`](@ref) node should be exactly be a single
  [`TableHeader`](@ref) followed by a [`TableBody`](@ref).
  - If the first child is a [`TableBody`](@ref), the header row is assumed to be a list of
    empty cells.
  - The rows from any nodes following the first [`TableBody`](@ref) are interpreted as
    additional table body rows, even if they are contained in a [`TableHeader`](@ref).
  - A [`Table`](@ref) with no children is interpreted as a table with a single empty header
    cell.
* A [`TableHeader`](@ref) that is the first child of a [`Table`](@ref) should only contain
  one [`TableRow`](@ref).
  - If a [`TableHeader`](@ref) that is the first child of a [`Table`](@ref) contains
    additional rows, the additional rows are interpreted to be body rows.
  - If a [`TableHeader`](@ref) that is the first child of a [`Table`](@ref) is empty, it is
    assumed to represent a header row with empty cells.
* Each [`TableRow`](@ref) of a table should contain the same number of [`TableCell`](@ref).
  - Any row that has fewer cells than the longest row should be interpreted as if it is
    padded with additional empty cells.
"""
mutable struct Table <: TableComponent
    spec :: Vector{Symbol}

    function Table(spec)
        for (ncol, s) in enumerate(spec)
            s in [:left, :right, :center] && continue
            error("Invalid table specifier '$s' for column $ncol")
        end
        new(collect(spec))
    end
end
Base.:(==)(x::Table, y::Table) = (x.spec == y.spec)
can_contain(::Table, e::AbstractElement) = isa(e, TableHeader) || isa(e, TableBody)

"""
    struct TableHeader <: TableComponent

Represents the header portion of a Markdown table and should only occur as the first child
of a [`Table`](@ref) node and should only contain a single [`TableRow`](@ref) as a child.
See [`Table`](@ref) for information on how to handle other circumstances.

It can only contain [`TableRow`](@ref) elements.
"""
struct TableHeader <: TableComponent end
can_contain(::TableHeader, e::AbstractElement) = isa(e, TableRow)

"""
    struct TableBody <: TableComponent

Represents the body of a Markdown table and should only occur as the second child of a
[`Table`](@ref) node. See [`Table`](@ref) for information on how to handle other
circumstances.

It can only contain [`TableRow`](@ref) elements.
"""
struct TableBody <: TableComponent end
can_contain(::TableBody, e::AbstractElement) = isa(e, TableRow)

"""
    struct TableRow <: TableComponent

Represents a row of a Markdown table. Can only contain [`TableCell`](@ref)s as children.
"""
struct TableRow <: TableComponent end
can_contain(::TableRow, e::AbstractElement) = isa(e, TableCell)

"""
    mutable struct TableCell <: TableComponent

Represents a single cell in a Markdown table. Can contain inline nodes.

* `align :: Symbol`: declares the alignment of a cell (can be `:left`, `:right`, or
  `:center`), and should match the `.spec` field of the ancestor [`Table`](@ref)
* `header :: Bool`: `true` if the cell is part of a header row, and should only be true if
  the cell belongs to a row that is the first
* `column :: Int`: the column index of the cell, which should match its position in the
  Markdown tree

It is possible that the fields of [`TableCell`](@ref) are inconsistent with the real
structure of the Markdown tree, in which case the structure or the `.spec` field should take
precedence when interpreting the elements.
"""
mutable struct TableCell <: TableComponent
    align :: Symbol
    header :: Bool
    column :: Int
end
Base.:(==)(x::TableCell, y::TableCell) = (x.align == y.align) && (x.header == y.header) && (x.column == y.column)
can_contain(::TableCell, e::AbstractElement) = isa(e, AbstractInline)

# src/extensions/interpolation.jl:struct JuliaValue <: AbstractInline
# struct Backslash <: AbstractInline end
# struct SoftBreak <: AbstractInline end
# struct LineBreak <: AbstractInline end

struct InvalidChildException <: Exception
    parent :: AbstractElement
    child :: AbstractElement
end
