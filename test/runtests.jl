using MarkdownAST
using Test

@testset "MarkdownAST" begin
    @test isempty(Test.detect_ambiguities(MarkdownAST; recursive=true))

    include("markdown.jl")
    include("node.jl")
    include("invalidast.jl")
    include("stdlib.jl")
    include("abstracttrees.jl")
end
