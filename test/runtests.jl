using MarkdownAST
using Test

@testset "MarkdownAST" begin
    @test isempty(Test.detect_ambiguities(MarkdownAST; recursive=true))

    include("markdown.jl")
    include("node.jl")
    include("invalidast.jl")
    include("tools.jl")
    include("fromstdlib.jl")
    include("tostdlib.jl")
    include("abstracttrees.jl")
end
