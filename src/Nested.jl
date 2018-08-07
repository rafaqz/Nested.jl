__precompile__()

module Nested

export Include, Exclude, nested, nested_include_all, nested_alt, nested_wrap, nested_val

# Stopgap singletons until boolean constants work, in 0.7
struct Include end
struct Exclude end

"Simple check functioon that accepts all fields"
nested_include_all(x, field) = Include()
"Simple val function that simply returns the path"
nested_val(T, P, path) = path
"Simples alt function that inserts an empty tuple if the check function fails, to later be splatted out of existence"
nested_alt(path, fname) = ()
"Simple wrap function. Wraps all struct field `check` functions in a tuple"
nested_wrap(T, expressions) = Expr(:tuple, expressions...)

"""
    nested(T, P, path, check, val, alt, wrap)

Builds an arbitrary expression built from each nested field in the passed in object.

Uses include converting a nested struct into another type, or a to list of values or
functions, and the reverse. It operates on julias abstract syntax tree (AST) and most functions it accepts
manipulate the AST or ruturn expressions, not values.

`nested` has checks to see if each field is included, which are performed
after the generated function, but still at compile time. The `check` function does this,
and its name should be passed in as a symbol or an expression.

It's a little ugly, but functions must be passed in. We can't use multiple dispatch on user
defined types as we're working inside hyperpure generated functions.

Arguments:
- `T`: the type of the current object
- `P`: the type of the parent object
- `path`: an expression containing the `.` path from the original type to the current object.
- `check`: a a symbol or expression for the function that checks if a field should be included.
- `val`: a function that returns the expression that gives the value for the field
   this function takes two arguments: struct type and fieldname.
- `alt`: alternate value if the field is not to be included
- `tuplewrap`: a function that wraps the expression returned when a tuple is parsed, maybe adding a constructor, etc.
- `structwrap`: a function that wraps the expression returned when a struct is parsed, maybe adding a constructor, etc.
"""
nested(T::Type, 
       path::Union{Symbol,Expr}, 
       check::Union{Symbol,Expr} = :nested_include_all, 
       val = nested_val, 
       alt = nested_alt, 
       tuplewrap = nested_wrap,
       structwrap = nested_wrap
      ) = nested(T, Void, path, check, val, alt, tuplewrap, structwrap)

nested(T::Type, P::Type, path, check, val, alt, tuplewrap, structwrap) = begin
    fnames = fieldnames(T)
    expressions = []
    for (i, fname) in enumerate(fnames)
        expr = :(
            if $check($T, $(Expr(:curly, :Val, QuoteNode(fnames[i])))) == Include()
                $(nested(fieldtype(T, i), T, Expr(:., path, Expr(:quote, fname)), 
                         check, val, alt, tuplewrap, structwrap))
            else
                $(alt(path, fnames[i]))
            end
        )
        push!(expressions, Expr(:..., expr))
    end
    structwrap(T, expressions)
end
nested(::Type{T}, P::Type, path, check, val, alt, tuplewrap, structwrap) where T <: Tuple = begin
    expressions = []
    for i in 1:length(T.types)
        expr = nested(fieldtype(T, i), T, Expr(:ref, path, i), check, val, alt, tuplewrap, structwrap)
        push!(expressions, Expr(:..., expr))
    end
    tuplewrap(T, expressions)
end
nested(::Type{T}, P::Type, path, check, val, args...) where T <: Number = Expr(:tuple, val(T, P, path))
nested(::Type{Any}, P::Type, path, check, val, args...) = Expr(:tuple, val(Any, P, path))

end # module
