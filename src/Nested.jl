__precompile__()

module Nested

using Compat

export nested 

"""
    nested(T::Type, dir::Union{Up,Down}, path::Union{Symbol,Expr}, check::Union{Symbol,Expr}, val, alt)

Builds an arbitrary expression from each nested field in the passed in object.

Arguments:
- `T`: the type of the current object
- `P`: the type of the parent object
- `path`: a symbol or expression containing the `.` path from the original type to the current object.
- `handler`: function that handles the collected expressions
"""

nested(T::Type, path, expr_builder, handler=default_handler) = nested(T, Nothing, path, expr_builder, handler)
nested(T::Type, P::Type, path, expr_builder, handler) = begin
    expressions = []
    for fname in fieldnames(T)
        push!(expressions, Expr(:..., expr_builder(T, path, fname)))
    end
    handler(T, expressions)
end

default_handler(T, expressions) = Expr(:tuple, expressions...)

end # module
