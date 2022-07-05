using MarkdownAST
using Test

@testset "MarkdownAST" begin
    include("markdown.jl")
    include("node.jl")
    include("invalidast.jl")
    include("stdlib.jl")
end
