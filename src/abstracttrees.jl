# This file implements the AbstractTrees interface, which in turns provides such
# functionality like walking over the Markdown trees etc.
AbstractTrees.children(node::Node) = node.children
AbstractTrees.childtype(node::Node) = typeof(node)
AbstractTrees.childrentype(node::Node) = typeof(node.children)

AbstractTrees.ParentLinks(::Type{<:Node}) = AbstractTrees.StoredParents()
AbstractTrees.parent(node::Node) = node.parent

AbstractTrees.SiblingLinks(::Type{<:Node}) = AbstractTrees.StoredSiblings()
AbstractTrees.nextsibling(node::Node) = node.next
AbstractTrees.prevsibling(node::Node) = node.previous

AbstractTrees.nodevalue(node::Node) = node.element
