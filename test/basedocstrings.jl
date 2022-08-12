# These tests depends on all _available_ standard libraries, so we can not run it as
# part of the normal test suite (we'd need to add all the standard libraries as
# dependencies to Project.toml).
using MarkdownAST
using Markdown, Pkg, Test

function list_stdlibs()
    stdlibs = Symbol[]
    for stdlib in readdir(Pkg.stdlib_dir())
        stdlib_path = joinpath(Pkg.stdlib_dir(), stdlib)
        isdir(stdlib_path) || continue
        endswith(stdlib, "_jll") && continue
        push!(stdlibs, Symbol(stdlib))
    end
    return stdlibs
end
find_submodules(m::Module) = find_submodules!(Module[], m)
function find_submodules!(submodules::Vector{Module}, m::Module)
    push!(submodules, m)
    for name in names(m, all=true)
        isdefined(m, name) || continue
        sm = getfield(m, name)
        (sm isa Module) && (sm ∉ submodules) && find_submodules!(submodules, sm)
    end
    return submodules
end
function allmodules()
    submodules = find_submodules(Base)
    for stdlib in list_stdlibs()
        Base.eval(@__MODULE__, :(import $stdlib))
        m = getfield(@__MODULE__, stdlib)
        find_submodules!(submodules, m)
    end
    return submodules
end
function moduledocstrings!(mds::Vector{Markdown.MD}, m::Module)
    docmeta = Docs.meta(m)
    for multidoc in values(docmeta)
        for docstr in values(multidoc.docs)
            @assert docstr isa Docs.DocStr
            md = Docs.parsedoc(docstr)
            @assert md isa Markdown.MD
            if length(md.content) == 1 && md.content[1] isa Markdown.MD
                md = md.content[1]
            end
            push!(mds, md)
        end
    end
    return mds
end
function alldocstrings()
    mds = Markdown.MD[]
    for m in allmodules()
        moduledocstrings!(mds, m)
    end
    return mds
end

@testset "Base docstrings" begin
    for md in alldocstrings()
        node = convert(MarkdownAST.Node, md)
        @test node isa MarkdownAST.Node
    end
end
