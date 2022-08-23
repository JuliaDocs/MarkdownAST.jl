struct UnimplementedMethodError <: Exception
    method :: String
    extra :: String
    UnimplementedMethodError(method :: AbstractString, extra :: AbstractString = "") = new(method, extra)
end

function Base.showerror(io::IO, e::UnimplementedMethodError)
    print(io, "UnimplementedMethodError: $(e.method) not implemented")
    isempty(e.extra) || print(io, '\n', e.extra)
end
