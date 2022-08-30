# This file contains the implementation for the Node type, which is a simple
# linked list based implementation of a Markdown AST tree.

"""
    mutable struct Node{M}

Implements a linked list type representation of a Markdown abstract syntax tree, where each
node contains pointers to the children and parent nodes, to make it possible to easily
traverse the whole tree in any direction. Each node also contains an "element", which is an
instance of some [`AbstractElement`](@ref MarkdownAST.AbstractElement) subtype, and can be
accessed via the `.element` property. The element object contains the semantic information
about the node (e.g. wheter it is a list or a paragraph).

Optionally, each node can also store additional meta information, which will be an object of
type `M` (see also the `.meta` property). By default, the node does not contain any extra
meta information and `M = Nothing`.

# Constructors

```julia
Node(element :: AbstractElement)
```

Constructs a simple standalone node (not part of any tree) without any additional metadata
(`M = Nothing`) containing the Markdown AST element `c`.

```julia
Node{M}(element :: AbstractElement, meta :: M)
```

Constructs a simple standalone node (not part of any tree) with the meta information `meta`,
containing the Markdown AST element `c`.

# Extended help

There are various properties that can be used to access the details of a node. Many of them
can not be set directly though, as that could lead to an inconsistent tree. Similarly, the
underlying fields of the struct should not be accessed directly.

- `.meta :: M`: can be used to access or set the extra meta information of the node.
- `.element :: T where {T <: AbstractElement}`: can be used to access or set the _element_
  corresponding to the node
- `.next :: Union{Node{M},Nothing}`: access the next child node after this one, with the
  value set to `nothing` if there is no next child
- `.previous :: Union{Node{M},Nothing}`: access the previous child node before this one,
  with the value set to `nothing` if there is no such node
- `.parent :: Union{Node{M},Nothing}`: access the parent node of this node, with the value
  set to `nothing` if the node does not have a parent
- `.children`: an iterable object that can be used to acces and modify the children of the
  node

The `.children` field is implemented with a wrapper type that implemements the iteration
protocol. However, the exact type information etc. is an implementation detail, and one
should only rely on the following documented APIs:

- The following methods are implemented for `.children`:
  [`length`](@ref Base.length(children::NodeChildren)),
  [`eltype`](@ref Base.eltype(::Type{NodeChildren{T}}) where T),
  [`first`](@ref Base.first(::NodeChildren)),
  [`last`](@ref Base.last(::NodeChildren)),
  [`isempty`](@ref Base.isempty(::NodeChildren))
- Appending or prepending new children to a parent node can be done with the
  [`push!`](@ref Base.push!(children::NodeChildren{T}, child::T) where {T <: Node}) and
  [`pushfirst!`](@ref Base.pushfirst!(children::NodeChildren{T}, child::T) where {T <: Node})
  methods

Other ways to work with child nodes that do not directly reference `.children` are:

- To add new children between others, the [`insert_after!`](@ref), [`insert_before!`](@ref)
  functions can be used to insert new children relative to a reference child node.
- To remove a child from a node, the [`unlink!`](@ref) function can be used on the
  corresponding child node.

In addition, there are other functions and methods that can be used to work with nodes and
trees:

* Querying information about the node: [`haschildren`](@ref)
* Removing a node from a tree: [`unlink!`](@ref)
* Two trees can be compared with the
  [`==` operator](@ref Base.:(==)(x::Node{T}, y::Node{T}) where T)
"""
mutable struct Node{M}
    t :: AbstractElement
    parent :: Union{Node{M}, Nothing}
    first_child :: Union{Node{M}, Nothing}
    last_child :: Union{Node{M}, Nothing}
    prv :: Union{Node{M}, Nothing}
    nxt :: Union{Node{M}, Nothing}
    meta :: M

    function Node{M}(element::AbstractElement, meta::M) where M
        new{M}(element, nothing, nothing, nothing, nothing, nothing, meta)
    end
end
Node(element::AbstractElement) = Node{Nothing}(element, nothing)

Base.propertynames(::Node) = (
    :element, :children, :next, :previous, :parent, :meta,
)

function Base.getproperty(node::Node{T}, name::Symbol) where T
    if name === :element
        getfield(node, :t)
    elseif name === :children
        NodeChildren(node)
    elseif name === :next
        getfield(node, :nxt)
    elseif name === :previous
        getfield(node, :prv)
    elseif name === :parent
        getfield(node, :parent)
    elseif name === :meta
        getfield(node, :meta)
    else
        # TODO: error("type Node does not have property $(name)")
        @debug "Accessing private field $(name) of Node" stacktrace()
        getfield(node, name)
    end
end

function Base.setproperty!(node::Node, name::Symbol, x)
    if name === :element
        setfield!(node, :t, x)
    elseif name === :meta
        setfield!(node, :meta, x)
    elseif name in propertynames(node)
        # TODO: error("Unable to set property $(name) for Node")
        @debug "Setting private field :$(name) of Node" stacktrace()
        setfield!(node, name, x)
    else
        # TODO: error("type Node does not have property $(name)")
        @debug "Accessing private field :$(name) of Node" stacktrace()
        setfield!(node, name, x)
    end
end

function Base.show(io::IO, node::Node{M}) where M
    print(io, "@ast ")
    M === Nothing || print(io, "$M ")
    _showast(io, node)
end
function _showast(io::IO, node::Node; indent = 0)
    prefix = ' '^(2*indent)
    print(io, prefix, node.element)
    if haschildren(node)
        println(io, " do")
        for child in node.children
            _showast(io, child; indent = indent + 1)
        end
        print(io, prefix, "end")
    end
    println(io)
end

"""
    haschildren(node::Node) -> Bool

Returns `true` if `node` has any children nodes and `false` otherwise.
"""
haschildren(node::Node) = !isnothing(getfield(node, :first_child))

"""
    unlink!(node::Node) -> Node

Isolates and removes the node from the tree by removing all of its links to its neighboring
nodes. Returns the updated node, which is now a single, isolate root node.
"""
function unlink!(node::Node)
    # Remove the node from its current tree, turning into a root node.
    # It retains all of its children, which now only exists in this new tree.

    # If there is a previous child on this level, then we just have to make sure it
    # points to the next one
    # However, if this is the first child, then we need to update the parent
    # node (if there is one; there isn't if this is a root node).
    if !isnothing(node.prv)
        node.prv.nxt = node.nxt
    elseif !isnothing(node.parent)
        node.parent.first_child = node.nxt
    end

    # Same logic as above, but checking if this is the last child or not.
    if !isnothing(node.nxt)
        node.nxt.prv = node.prv
    elseif !isnothing(node.parent)
        node.parent.last_child = node.prv
    end

    # Now that the siblings are parents are updated, the references in this node
    # can be erased.
    node.nxt, node.prv, node.parent = nothing, nothing, nothing

    # Return the updated (now root) node.
    return node
end

# The precise types etc of the iterator of the child nodes is considered to be an
# implementation detail. It should only be constructed by calling the relevant public APIs.
# In practice, the argument to ChildrenIterator is simply the node where the iterator starts
struct NodeChildren{T <: Node}
    parent :: T

    NodeChildren(parent::T) where {T <: Node} = new{T}(parent)
end
function Base.iterate(children::NodeChildren{T}, state::Union{T,Nothing} = nothing) where {T <: Node}
    nextnode = isnothing(state) ? getfield(children.parent, :first_child) : state.next
    isnothing(nextnode) ? nothing : (nextnode, nextnode)
end

"""
    eltype(node.children) = Node{M}

Returns the exact `Node` type of the tree, corresponding to the type of the elements of the
`.children` iterator.
"""
Base.eltype(::Type{NodeChildren{T}}) where T = T

"""
    length(node.children) -> Int

Returns the number of children of `node :: Node`.

As the children are stored as a linked list, this method has O(n) complexity. As such, to
check there are any children at all, it is generally preferable to use
[`isempty`](@ref Base.isempty(::NodeChildren)).
"""
function Base.length(children::NodeChildren)
    len = 0
    node = getfield(children.parent, :first_child)
    while !isnothing(node)
        len += 1
        node = node.next
    end
    return len
end

"""
    first(node.children) -> Node

Returns the first child of the `node :: Node`, or throws an error if the node has no
children.
"""
function Base.first(children::NodeChildren{T}) where T
    first_child = getfield(children.parent, :first_child)
    # Error type consistent with first(""):
    isnothing(first_child) && throw(ArgumentError("collection must be non-empty"))
    return first_child :: T
end

"""
    last(node.children) -> Node

Returns the last child of the `node :: Node`, or throws an error if the node has no
children.
"""
function Base.last(children::NodeChildren{T}) where T
    last_child = getfield(children.parent, :last_child)
    # Error type consistent with first(""):
    isnothing(last_child) && throw(ArgumentError("collection must be non-empty"))
    return last_child :: T
end

"""
    isemtpy(node.children) -> Bool

Can be called on the `.children` field of a `node :: Node` to determine whether or not the
node has any child nodes.
"""
Base.isempty(children::NodeChildren) = !haschildren(children.parent)

"""
    Base.push!(node.children, child::Node) -> Node

Adds `child` as the last child node of `node :: Node`. If `child` is part of another tree,
then it is unlinked from that tree first (see [`unlink!`](@ref)). Returns the iterator over
children.
"""
function Base.push!(children::NodeChildren{T}, child::T) where {T <: Node}
    node = children.parent
    assert_can_contain(node, child)
    # append_child
    # The child node is unlinked first
    unlink!(child)
    child.parent = node
    # If there are existing children, we need to update the current last child.
    # Otherwise, we just make sure that the first and last pointers point to this
    # child.
    if !isnothing(node.last_child)
        node.last_child.nxt = child
        child.prv = node.last_child
        node.last_child = child
    else
        node.first_child = child
        node.last_child = child
    end
    # Return the updated parent node
    return children
end
# Helful error message if the user does push!(node, child)
function Base.push!(::Node, ::Any)
    throw(UnimplementedMethodError(
        "push!(node::Node, ...)",
        "If you want to add new children to a node, use push!(node.children, ...) instead."
    ))
end

"""
    Base.pushfirst!(node.children, child::Node) -> Node

Adds `child` as the first child node of `node :: Node`. If `child` is part of another tree,
then it is unlinked from that tree first (see [`unlink!`](@ref)). Returns the iterator over
children.
"""
function Base.pushfirst!(children::NodeChildren{T}, child::T) where T
    node = children.parent
    assert_can_contain(node, child)
    # prepend_child
    # The child node is unlinked first
    unlink!(child)
    child.parent = node
    # If there are existing children, we need to update the current first child.
    # Otherwise, we just make sure that the first and last pointers point to this
    # child.
    if !isnothing(node.first_child)
        node.first_child.prv = child
        child.nxt = node.first_child
        node.first_child = child
    else
        node.first_child = child
        node.last_child = child
    end
    # Return the updated parent node
    return children
end
# Helful error message if the user does pushfirst!(node, child)
function Base.pushfirst!(::Node, ::Any)
    throw(UnimplementedMethodError(
        "pushfirst!(node::Node, ...)",
        "If you want to add new children to a node, use pushfirst!(node.children, ...) instead."
    ))
end

"""
    insert_after!(node::Node, sibling::Node) -> Node

Inserts a new child node `sibling` as the next child after `node`. `node` must not be a root
node. If `sibling` is part of another tree, then it is unlinked from that tree first (see
[`unlink!`](@ref)). Returns the original reference node.
"""
function insert_after!(node::Node, sibling::Node)
    # Adds the sibling after this node:
    isrootnode(node) && throw(ArgumentError("the reference node must not be a root node"))
    assert_can_contain(node.parent, sibling)
    # The sibling node is unlinked first:
    unlink!(sibling)
    # If there is a node after `node`, we point sibling to it:
    sibling.nxt = node.nxt
    if !isnothing(sibling.nxt)
        sibling.nxt.prv = sibling
    end
    # Create link between node and sibling
    sibling.prv = node
    node.nxt = sibling
    # The current node's parent is also the sibling's parent.
    sibling.parent = node.parent
    # If this node is the last child, we need to update the parent too.
    if isnothing(sibling.nxt)
        sibling.parent.last_child = sibling
    end
    # Return the original reference node
    return node
end

"""
    insert_before!(node::Node, sibling::Node) -> Node

Inserts a new child node `sibling` as the child right before `node`. `node` must not be a
root node. If `sibling` is part of another tree, then it is unlinked from that tree first
(see [`unlink!`](@ref)). Returns the original reference node.
"""
function insert_before!(node::T, sibling::T) where {T <: Node}
    # Fallback method for insert_before!
    isrootnode(node) && throw(ArgumentError("the reference node must not be a root node"))
    assert_can_contain(node.parent, sibling)
    # If this node is the first node, then we can prepend the sibling as a child
    # to the parent node. Otherwise, we just insert it after the previous node.
    if isnothing(node.previous)
        pushfirst!(node.parent, sibling)
    else
        insert_after!(node.previous, sibling)
    end
    return node
end

# Check if this is a root node. Next and previous should also be nothing, but this is not
# enforced. This function is currently not part of the public API.
isrootnode(node::Node) = isnothing(node.parent)

"""
    ==(x::Node, y::Node) -> Bool

Determines if two trees are equal by recursively walking through the whole tree (if need be)
and comparing each node. Parent nodes are ignored when comparing for equality (so that it
would be possible to compare subtrees). If the metadata type does not match, the two trees
are not considered equal.
"""
function Base.:(==)(x::Node{T}, y::Node{T}) where T
    x.element == y.element || return false
    x.meta == y.meta || return false
    # Finally we compare all the children (which, of course, recursively compare their
    # children). In principle, the first check could be length(x.children) == length(y.children),
    # but length() here is O(n). So we pairwise iterate through the children, comparing each
    # pair, and bailing right away if something doesn't match. However, a naive zip use
    # doesn't handle the case where the number of children is different. Hence we lazily
    # append a nothing to each iterator.
    x_children_padded = Iterators.flatten((x.children, (nothing,)))
    y_children_padded = Iterators.flatten((y.children, (nothing,)))
    for (xc, yc) in zip(x_children_padded, y_children_padded)
        xc == yc || return false
    end
    return true
end

function assert_can_contain(parent::T, child::T) where {T <: Node}
    can_contain(parent.element, child.element) && return nothing
    throw(InvalidChildException(parent.element, child.element))
end
