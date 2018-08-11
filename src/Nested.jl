__precompile__()

module Nested

using Compat

export nested, up, down

"""
    nested(T::Type, dir::Union{Up,Down}, path::Union{Symbol,Expr}, check::Union{Symbol,Expr}, val, alt)

Builds an arbitrary expression from each nested field in the passed in object.

Arguments:
- `T`: the type of the current object
- `P`: the type of the parent object
- `path`: a symbol or expression containing the `.` path from the original type to the current object.
- `handler`: function that handles the collected expressions
"""

nested(T::Type, path, exprbuilder, handler) = nested(T, Nothing, path, exprbuilder, handler)
nested(T::Type, P::Type, path, exprbuilder, handler) = begin
    expressions = []
    for fname in fieldnames(T)
        push!(expressions, Expr(:..., exprbuilder(T, path, fname)))
    end
    handler(T, expressions)
end

up(T, expressions) = Expr(:tuple, Expr(:call, :($T.name.wrapper), expressions...))
up(T::Tuple, expressions) = Expr(:tuple, Expr(:tuple, expressions...))

down(T, expressions) = Expr(:tuple, expressions...)

end # module
