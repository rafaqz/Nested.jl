module Nested

export nested 

"""
    nested(T::Type, path, expr_builder, handler=default_handler) 
Builds an arbitrary expression from each nested field in the passed in object.

Arguments:
- `T`: the type of the current object
- `P`: the type of the parent object
- `path`: a symbol or expression containing the `.` path from the original type to the current object.
- `expr_builder`: function that returns an expression given T, path and a field name or index
- `handler`: function that handles the collected expressions
"""
nested(T::Type, path, expr_builder, handler=default_handler) = 
    nested(T, Nothing, path, expr_builder, handler)
nested(T::Type, P::Type, path, expr_builder, handler) = 
    handler(T, [Expr(:..., expr_builder(T, path, fn)) for fn in fieldnames(T)])

default_handler(T, expressions) = Expr(:tuple, expressions...)

end # module
