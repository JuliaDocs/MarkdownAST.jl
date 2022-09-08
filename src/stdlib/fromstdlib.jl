# Conversion methods from the standard library Markdown trees:
"""
    convert(::Type{Node}, md::Markdown.MD) -> Node
    convert(::Type{Node{M}}, md::Markdown.MD, meta=M) where M -> Node{M}

Converts a standard library Markdown AST into MarkdownAST representation.

Note that it is not possible to convert subtrees, as only `MD` objects can be converted.
The result will be a tree with [`Document`](@ref) as the root element.

When the type argument passed is `Node`, the resulting tree will be constructed of objects
of the default node type `Node{Nothing}`. However, it is also possible to convert into
MarkdownAST trees that have custom metadata field of type `M`, in which case the `M` type
must have a zero-argument constructor available, which will be called whenever a new `Node`
object gets constructed.

It is also possible to use a custom function to construct the `.meta` objects via the `meta
argument, which must be a callable object with a zero-argument method, and that then gets
called every time a new node is constructed.
"""
Base.convert(::Type{Node}, md::Markdown.MD) = convert(Node{Nothing}, md)
function Base.convert(::Type{Node{M}}, md::Markdown.MD, meta=M) where M
    _convert(NodeFn{M}(meta), Document(), _convert_block, md.content)
end

struct NodeFn{M}
    meta
end
(m::NodeFn{M})(element) where M = Node{M}(element, m.meta()::M)

function _convert(nodefn::NodeFn, c::AbstractElement, child_convert_fn, md_children)
    node = nodefn(c)
    for md_child in md_children
        childnode = child_convert_fn(nodefn, md_child)
        push!(node.children, childnode)
    end
    return node
end

_convert_block(nodefn::NodeFn, block::Markdown.Paragraph) = _convert(nodefn, Paragraph(), _convert_inline, block.content)
function _convert_block(nodefn::NodeFn, block::Markdown.Header{N}) where N
    # Empty headings have just an empty String as text, so this requires special treatment:
    c = Heading(N)
    if block.text isa AbstractString
        # TODO: If isempty(block.text), should we omit adding any children?
        headingnode = nodefn(c)
        push!(headingnode.children, nodefn(Text(block.text)))
        headingnode
    else
        _convert(nodefn, c, _convert_inline, block.text)
    end
end
_convert_block(nodefn::NodeFn, b::Markdown.BlockQuote) = _convert(nodefn, BlockQuote(), _convert_block, b.content)
_convert_block(nodefn::NodeFn, ::Markdown.HorizontalRule) = nodefn(ThematicBreak())
_convert_block(nodefn::NodeFn, b::Markdown.Code) = nodefn(CodeBlock(b.language, b.code))
# Non-Commonmark extensions
_convert_block(nodefn::NodeFn, b::Markdown.Admonition) = _convert(nodefn, Admonition(b.category, b.title), _convert_block, b.content)
_convert_block(nodefn::NodeFn, b::Markdown.LaTeX) = nodefn(DisplayMath(b.formula))
_convert_block(nodefn::NodeFn, b::Markdown.Footnote) = _convert(nodefn, FootnoteDefinition(b.id), _convert_block, b.text)

function _convert_block(nodefn::NodeFn, b::Markdown.List)
    list = nodefn(List(b.ordered == -1 ? :bullet : :ordered, !b.loose))
    # TODO: should we warn if tight != all(isequal(1), length.(b.items)) ?
    for item in b.items
        push!(list.children, _convert(nodefn, Item(), _convert_block, item))
    end
    return list
end

function _convert_block(nodefn::NodeFn, b::Markdown.Table)
    # If the Markdown table is somehow empty, we'll return an empty Table node
    isempty(b.rows) && return nodefn(Table([]))
    # We assume that the width of the table is the width of the widest row
    ncols = maximum(length(row) for row in b.rows)
    # Markdown uses :l / :r / :c for the table specs. We will also pad it with `:right`
    # values (standard library's default) if need be, or drop the last ones if there are too
    # many somehow.
    spec = _convert_column_spec.(b.align)
    if ncols > length(spec)
        rpad_array!(spec, ncols, :right)
    elseif ncols < length(spec)
        spec = spec[1:ncols]
    end
    # A MD table should always contain a header. We'll split it off from the rest.
    header_row, body_rows = Iterators.peel(b.rows)
    tablenode = nodefn(Table(spec))
    headernode = nodefn(TableHeader())
    push!(headernode.children, _convert_table_row(nodefn, header_row, spec=spec, isheader = true))
    push!(tablenode.children, headernode)
    # If it doesn't have any more rows, then we don't append a TableBody
    if length(b.rows) >= 2
        bodynode = nodefn(TableBody())
        for row in body_rows
            push!(bodynode.children, _convert_table_row(nodefn, row, spec=spec, isheader = false))
        end
        push!(tablenode.children, bodynode)
    end
    return tablenode
end
function _convert_table_row(nodefn::NodeFn, row; spec, isheader)
    ncols = length(spec)
    rownode = nodefn(TableRow())
    for (i, cell) in enumerate(row)
        c = TableCell(spec[i], isheader, i)
        cellnode = _convert(nodefn, c, _convert_inline, cell)
        push!(rownode.children, cellnode)
    end
    # If need be, we pad the row with empty TableCells, to make sure that each row has the
    # same number of cells
    if length(row) < ncols
        for i in (length(row)+1):ncols
            cell = TableCell(spec[i], isheader, i)
            push!(rownode.children, nodefn(cell))
        end
    end
    return rownode
end
_convert_column_spec(s :: Symbol) = (s === :r) ? :right :
    (s === :l) ? :left : (s === :c) ? :center : begin
        @warn "Invalid table spec in Markdown table: '$s'"
        :right
    end
function rpad_array!(xs::Vector{T}, n::Integer, e::T) where {T}
    n > 0
    length(xs) >= n && return xs
    i = n - length(xs)
    while i > 0
        push!(xs, e)
        i -= 1
    end
    return xs
end

# Inline nodes:
_convert_inline(nodefn::NodeFn, s::Markdown.Bold) = _convert(nodefn, Strong(), _convert_inline, s.text)
_convert_inline(nodefn::NodeFn, s::Markdown.Italic) = _convert(nodefn, Emph(), _convert_inline, s.text)
function _convert_inline(nodefn::NodeFn, s::Markdown.Link)
    # The Base Markdown parser does not parse the title part, so we just default that to
    # an empty string.
    c = Link(s.url, "")
    if s.text isa AbstractString
        # Autolinks (the `<URL>` syntax) yield Link objects where .text is just a String
        linknode = nodefn(c)
        push!(linknode.children, nodefn(Text(s.text)))
        linknode
    else
        _convert(nodefn, c, _convert_inline, s.text)
    end
end
function _convert_inline(nodefn::NodeFn, s::Markdown.Code)
    # TODO: proper error, or perhaps a warning
    @assert isempty(s.language) "Inline code span must not have language attribute"
    nodefn(Code(s.code))
end

# The standard library parser does not handle the title, so we just default that to an empty
# string. Also, the "alt" part inside the [] bracket is parsed as a simple string, rather
# than as proper Markdown. So we just return a corresponding Text() node.
_convert_inline(nodefn::NodeFn, s::Markdown.Image) = @ast Image(s.url, "") do
    s.alt # TODO: if isempty(s.alt), should be just omit adding children here?
end
_convert_inline(nodefn::NodeFn, ::Markdown.LineBreak) = nodefn(LineBreak())
# Non-Commonmark extensions
_convert_inline(nodefn::NodeFn, s::Markdown.LaTeX) = nodefn(InlineMath(s.formula))
function _convert_inline(nodefn::NodeFn, s::Markdown.Footnote)
    @assert s.text === nothing # footnote references should not have any content, TODO: error
    nodefn(FootnoteLink(s.id))
end
_convert_inline(nodefn::NodeFn, s::AbstractString) = nodefn(Text(s))

# Fallback methods for non-Markdown types. If we find such nodes in the tree, we assume that
# they correspond to the interpolation of Julia values.
_convert_inline(nodefn::NodeFn, x) = nodefn(JuliaValue(nothing, x))
# JuliaValue is an inline node, so in a block context we surround it with a Paragraph.
# Incidentally, this would also capture any inline nodes that somehow have ended up in a
# block context.
function _convert_block(nodefn::NodeFn, x)
    p = nodefn(Paragraph())
    push!(p.children, _convert_inline(nodefn::NodeFn, x))
    return p
end
