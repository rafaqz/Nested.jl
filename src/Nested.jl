__precompile__()

module Nested

using Unitful

export Include, Exclude, Up, Down, nested, nested_include_all, nested_alt, nested_wrap, nested_val

# Stopgap singletons until boolean constants work, in 0.7
struct Include end
struct Exclude end

struct Up end
struct Down end

"Simple check functioon that accepts all fields"
nested_include_all(x, field) = Include()
"Simple val function that simply returns the path"
nested_val(T, P, path) = path
"Simples alt function that inserts an empty tuple if the check function fails, to later be splatted out of existence"
nested_alt(path, fname) = ()

"""
    nested(T::Type, dir::Union{Up,Down}, path::Union{Symbol,Expr}, check::Union{Symbol,Expr}, val, alt)
Builds an arbitrary expression built from each nested field in the passed in object.

Arguments:
- `T`: the type of the current object
- `P`: the type of the parent object
- `path`: a symbol or expression containing the `.` path from the original type to the current object.

Optional Arguments:
- `check`: a symbol or expression for the function that checks if a field should be included.
- `val`: a function that returns the expression that gives the value for the field
   this function takes two arguments: struct type and fieldname.
- `alt`: a function that returns an alternate value if the field is not to be included
"""
nested(T::Type, 
       dir, 
       path, 
       check = :nested_include_all, 
       val = nested_val, 
       alt = nested_alt) = nested(T, Void, dir, path, check, val, alt)

nested(T::Type, P::Type, dir, path, check, val, alt) = begin
    fnames = fieldnames(T)
    expressions = []
    for (i, fname) in enumerate(fnames)
        expr = :(
            if $check($T, $(Expr(:curly, :Val, QuoteNode(fnames[i])))) == Include()
                $(nested(fieldtype(T, i), T, dir, Expr(:., path, Expr(:quote, fname)), 
                         check, val, alt))
            else
                $(alt(path, fnames[i]))
            end
        )
        push!(expressions, Expr(:..., expr))
    end
    structwrap(T, dir, expressions)
end
nested(::Type{T}, P::Type, dir, path, check, val, alt) where T <: Tuple = begin
    expressions = []
    for i in 1:length(T.types)
        expr = nested(fieldtype(T, i), T, dir, Expr(:ref, path, i), check, val, alt)
        push!(expressions, Expr(:..., expr))
    end
    tuplewrap(T, dir, expressions)
end
nested(::Type{T}, P::Type, ::Down, path, check, val, args...) where T <: Void = Expr(:tuple)
nested(::Type{T}, P::Type, ::Up, path, check, val, args...) where T <: Void = nothing 
nested(::Type{T}, P::Type, dir, path, args...) where T <: Unitful.Quantity = 
    nested(fieldtype(T, :val), P, dir, Expr(:., path, QuoteNode(:val)), args...)
nested(::Type{Any}, P::Type, dir, path, check, val, args...) = Expr(:tuple, val(Any, P, path))
nested(::Type{T}, P::Type, dir, path, check, val, args...) where T <: Number = Expr(:tuple, val(T, P, path))

tuplewrap(T, ::Up, expressions) = Expr(:tuple, Expr(:tuple, expressions...))
tuplewrap(T, ::Down, expressions) = Expr(:tuple, expressions...)
structwrap(T, ::Up, expressions) = Expr(:tuple, Expr(:call, Expr(:., Expr(:., T, QuoteNode(:name)), QuoteNode(:wrapper)), expressions...))
structwrap(T, ::Down, expressions) = Expr(:tuple, expressions...)

end # module
