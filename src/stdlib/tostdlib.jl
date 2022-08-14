# Conversion methods from the MarkdownAST representation to the Markdown standard library
# representation

"""
    convert(::Type{Markdown.MD}, node::Node) -> Markdown.MD

Converts a MarkdownAST representation of a Markdown document into the `Markdown` standard
library representation.

Note that the root node `node` must a [`Document`](@ref) element.
"""
function Base.convert(::Type{Markdown.MD}, node::Node)
    node.element isa Document || error("can only convert trees with Document() root element")
    return _convert_element(node)
end

_convert_element(n::Node) = _convert_element(n, n.element)
# Fallback for unknown element types
_convert_element(::Node, e::AbstractElement) =
    error("Unable to convert element of type $(typeof(e))\n  element = $(e)")

_convert_element(n::Node, ::Document) = Markdown.MD(_convert_element.(n.children))
# Block elements
_convert_element(n::Node, e::Admonition) = Markdown.Admonition(e.category, e.title, _convert_element.(n.children))
_convert_element(n::Node, ::BlockQuote) = Markdown.BlockQuote(_convert_element.(n.children))
_convert_element(::Node, e::CodeBlock) = Markdown.Code(e.info, e.code)
_convert_element(::Node, e::DisplayMath) = Markdown.LaTeX(e.math)
_convert_element(n::Node, e::FootnoteDefinition) = Markdown.Footnote(e.id, _convert_element.(n.children))
_convert_element(n::Node, e::Heading) = Markdown.Header{e.level}(_convert_element.(n.children))
_convert_element(n::Node, ::Paragraph) = Markdown.Paragraph(_convert_element.(n.children))
_convert_element(::Node, ::ThematicBreak) = Markdown.HorizontalRule()
# Inline elements
_convert_element(n::Node, ::Emph) = Markdown.Italic(_convert_element.(n.children))
_convert_element(::Node, e::Code) = Markdown.Code("", e.code)
_convert_element(::Node, e::FootnoteLink) = Markdown.Footnote(e.id, nothing)
function _convert_element(n::Node, e::Image)
    alt_text = strip(Markdown.plain(Markdown.Paragraph(_convert_element.(n.children))))
    Markdown.Image(e.destination, alt_text)
end
_convert_element(::Node, e::InlineMath) = Markdown.LaTeX(e.math)
_convert_element(::Node, e::JuliaValue) = e.ref
_convert_element(n::Node, e::Link) = Markdown.Link(_convert_element.(n.children), e.destination)
_convert_element(n::Node, ::Strong) = Markdown.Bold(_convert_element.(n.children))
_convert_element(::Node, e::Text) = e.text
# Lists
_convert_element(n::Node, e::List) = Markdown.List(
    _convert_element.(n.children),
    (e.type == :bullet) ? -1 : 1,
    !e.tight,
)
_convert_element(n::Node, ::Item) = _convert_element.(n.children)
# Tables
function _convert_element(n::Node, e::Table)
    rows = map(Iterators.flatten(thtb.children for thtb in n.children)) do row
        @assert row.element isa TableRow
        _convert_element.(row.children)
    end
    ncols = maximum(length.(rows))
    align = rpad_array!(_invert_column_spec.(e.spec), ncols, :l)
    Markdown.Table(rows, align)
end
_convert_element(n::Node, ::TableCell) = _convert_element.(n.children)
_invert_column_spec(spec::Symbol) = Symbol(first(String(spec)))
# Whitespace nodes
_convert_element(n::Node, ::LineBreak) = Markdown.LineBreak()
_convert_element(n::Node, ::SoftBreak) = " "
_convert_element(n::Node, ::Backslash) = "\\"
# Raw HTML
_convert_element(::Node, e::HTMLBlock) = Markdown.Code("html", e.html)
_convert_element(::Node, e::HTMLInline) = Markdown.Code("", e.html)
