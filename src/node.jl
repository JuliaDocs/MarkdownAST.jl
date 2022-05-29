# This file contains the implementation for the Node type, which is a simple
# linked list based implementation of a Markdown AST tree.

"""
    mutable struct Node{M}

Implements a linked list type representation of a Markdown abstract syntax tree, where each
node contains pointers to the children and parent nodes, to make it possible to easily
traverse the whole tree in any direction. Each node also contains an "element", which is an
instance of some [`AbstractElement`](@ref) subtype and can be accesses via the `.element`
property, and contains the semantic information about the node (e.g. wheter it is a list or
a paragraph).

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

In addition, there are other functions and methods that can be used to work with nodes and
trees:

* Querying information about the node: [`haschildren`](@ref)
* For accessing neighboring nodes: [`children`](@ref)
* To add new nodes as children: [`push!`](@ref), [`pushfirst!`](@ref),
  [`insert_after!`](@ref), [`insert_before!`](@ref)
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

function Base.getproperty(node::Node, name::Symbol)
    if name === :element
        getfield(node, :t)
    elseif name === :children
        children(node)
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
    # If the type metadata type is Nothing, we'll omit
    if M === Nothing
        print(io, "Node(")
        show(io, node.element)
        print(io, ")")
    else
        print(io, "Node{", M, "}(")
        show(io, node.element)
    end
    print(io, ")")
end

# Accessor functions for neighboring nodes

"""
    children(node::Node)

Returns an iterator that runs, in sequence, over all the immediate children of the node.
"""
children(node::T) where {T <: Node} = ChildrenIterator{T}(node.first_child)

# The precise types etc of the iterator of the child nodes is considered to be an
# implementation detail. It should only be constructed by calling the relevant public APIs.
# In practice, the argument to ChildrenIterator is simply the node where the iterator starts
struct ChildrenIterator{T <: Node}
    node :: Union{T, Nothing}
end
Base.eltype(::Type{ChildrenIterator{T}}) where T = T
function Base.length(it::ChildrenIterator)
    len = 0
    node = it.node
    while !isnothing(node)
        len += 1
        node = node.next
    end
    return len
end
function Base.iterate(it::ChildrenIterator{T}, state::Union{T,Nothing} = nothing) where {T <: Node}
    nextnode = isnothing(state) ? it.node : state.next
    isnothing(nextnode) ? nothing : (nextnode, nextnode)
end
function Base.last(it::ChildrenIterator)
    local lastnode
    for n in it
        lastnode = n
    end
    return lastnode
end

"""
    haschildren(node::Node) -> Bool

Returns `true` if `node` has any children nodes and `false` otherwise.
"""
haschildren(node::Node) = !isnothing(node.first_child)

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

"""
    Base.push!(node::Node, child::Node) -> Node

Adds `child` as the last child node of `node`. If `child` is part of another tree, then
it is unlinked from that tree first (see [`unlink!`](@ref)). Returns the parent node.
"""
function Base.push!(node::T, child::T) where {T <: Node}
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
    return node
end

"""
    Base.pushfirst!(node::Node, child::Node) -> Node

Adds `child` as the first child node of `node`. If `child` is part of another tree, then
it is unlinked from that tree first (see [`unlink!`](@ref)). Returns the parent node.
"""
function Base.pushfirst!(node::Node, child::Node)
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
    return node
end

"""
    insert_after!(node::Node, sibling::Node) -> Node

Inserts a new child node `sibling` as the next child after `node`. `node` must not be a root
node. If `sibling` is part of another tree, then it is unlinked from that tree first (see
[`unlink!`](@ref)). Returns the original reference node.
"""
function insert_after!(node::Node, sibling::Node)
    # Adds the sibling after this node:
    @assert !isrootnode(node)
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
    @assert !isrootnode(node)
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
