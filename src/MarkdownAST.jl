module MarkdownAST

include("markdown.jl")
include("node.jl")
include("astmacro.jl")
include("stdlib.jl")

# Compat with older Julia versions
#
# isnothing borrowed from Compat.jl (MIT):
# https://github.com/JuliaLang/Compat.jl/blob/3ae185fa45a3091b387b67b6fd8f58f761854238/src/Compat.jl#L72-L77
#
# https://github.com/JuliaLang/julia/pull/29679
if VERSION < v"1.1.0-DEV.472"
    isnothing(::Any) = false
    isnothing(::Nothing) = true
end

end
