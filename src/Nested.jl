module Nested

export nested 

"""
    nested(T::Type, path, expr_builder, combiner=default_combiner) 
Builds an arbitrary expression from each nested field in the passed in object.

Arguments:
- `T`: the type of the current object
- `P`: the type of the parent object
- `expr_builder`: function that returns an expression given T, path and a field name or index
- `combiner`: function that handles the collected expressions
"""
nested(T::Type, expr_builder, expr_combiner=default_combiner) = 
    nested(T, Nothing, expr_builder, expr_combiner)
nested(T::Type, P::Type, expr_builder, expr_combiner) = 
    expr_combiner(T, [Expr(:..., expr_builder(T, fn)) for fn in fieldnames(T)])

default_combiner(T, expressions) = Expr(:tuple, expressions...)

end # module
