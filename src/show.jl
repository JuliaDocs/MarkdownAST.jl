showast(node::Node) = showast(stdout, node)
function showast(io::IO, node::Node)
    print(io, "@ast ")
    _showast(io, node)
end
function _showast(io::IO, node::Node; indent = 0)
    prefix = ' '^(2*indent)
    print(io, prefix, node[])
    if haschildren(node)
        println(io, " do")
        for child in children(node)
            _showast(io, child; indent = indent + 1)
        end
        print(io, prefix, "end")
    end
    println(io)
end
