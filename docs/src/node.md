```@meta
CurrentModule = MarkdownAST
```

# Tree node interface

The Markdown abstract syntax tree (AST) is a tree of [Markdown elements](@ref AbstractElement).
In order to avoid type instabilities when performing basic operations on a tree, such as traversin it, it is implemented by linking together instances of the [`Node`](@ref) type.
Each [`Node`](@ref) instance functions as a container for some [`AbstractElement`](@ref).

The [`Node`](@ref) type has various _properties_ that can be used to access information about the structure of the tree, but it is generally not possible to set them directly.
Changing the structure of a tree (e.g. to adding child nodes), should be done with the help of the [various functions and methods to MarkdownAST provides for mutating the tree](@ref "Mutating the tree").

```@docs
Node
Base.:(==)(::Node{T}, ::Node{T}) where T
```

## Accessing child nodes

Internally, to store the children, a node simply stores the reference to the first and the last child node, and each child stores the references to the next and previous child.
The `.children` property is implemented simply as a lazy iterator that traverses the linked list.
As such, some operations, such as determining the number of children a node has with [`length`](@ref Base.length(::NodeChildren)), can have unexpected ``O(n)`` complexity.

```@docs
haschildren
Base.eltype(::Type{NodeChildren{T}}) where T
Base.length(::NodeChildren)
Base.isempty(::NodeChildren)
#Base.first(::NodeChildren{T}) where T
#Base.last(::NodeChildren{T}) where T
```
```@autodocs
Modules = [MarkdownAST]
Filter = t -> t in [Base.first, Base.last]
```

## Mutating the tree

The following functions and methods can be used to mutate the Markdown AST trees represented using [`Node`](@ref) objects.
When using these methods, the consistency of the tree is preserved (i.e. the references between the affected nodes are correctly updated).
Changing the structure of the tree in any other way should generally be avoided, since the code that operates on trees generally assumes a consistent tree, and will likely error or behave in unexpected ways on inconsistent trees.

!!! warning "Mutating the tree while traversing"

    Mutating the structure of the tree while traversing it with some iterator (e.g. `.children` or one of the [AbstractTrees iterators](@ref "Iteration over trees")) can lead to unexpected behavior and should generally be avoided.
    Updating the `.element` of a node, on the other hand, is fine.

```@docs
unlink!
insert_before!
insert_after!
Base.push!(::NodeChildren{T}, ::T) where {T <: Node}
Base.pushfirst!(::NodeChildren{T}, ::T) where {T <: Node}
```

!!! note "Mutating the .children property"

    The choice to apparently mutate the `.children` property when adding child nodes is purely syntactic, and in reality the operation affects the parent [`Node`](@ref) object.
    Internally the `.children` iterator is simply a thin wrapper around the parent node.

## Index

```@index
Pages = ["node.md"]
```
