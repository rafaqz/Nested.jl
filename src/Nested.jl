__precompile__()

module Nested

export Include, Exclude, nested, nested_include_all, nested_alt, nested_wrap, nested_val

# Stopgap singletons until boolean constants work, in 0.7
struct Include end
struct Exclude end

nested_include_all(x, field) = Include()
nested_val(T, P, path) = path
nested_alt(path, fname) = ()
nested_wrap(T, expressions) = Expr(:tuple, expressions...)

"""
    nested(T, P, path, check, val, alt, wrap) 

Builds an arbitrary expression relating to each nested field in the passed in object. 

This can be used for converting a nested struct into a new type, or a list of values or 
functions. It operates on julias abstract syntax tree (AST) and most functions it accepts
manipulate the AST or ruturn expressions, no values.

`nested` has checks to see if each field is included, which are performed
after the generated function, but still at compile time. 

Arguments:
- `T`: the type of the current object
- `P`: the typoe of the last parent object
- `path`: the ast path from the original type to the current object. Not sure what else to call this??
- `check`: a a symbol or expression for the function that checks if a field should be included.
- `val`: a function that returns the expression that gives the value for the field
   this function takes two arguments: struct type and fieldname.
- `alt`: alternate value if the field is not to be included
- `wrap`: a function that wraps the expression returned when a struct is parsed, maybe adding a constructor.
"""
nested(T, P, path, check=:nested_include_all, val=nested_val, alt=nested_alt, wrap=nested_wrap) = begin
    fnames = fieldnames(T)
    expressions = []
    for (i, fname) in enumerate(fnames)
        expr = :(
            if $check($T, $(Expr(:curly, :Val, QuoteNode(fnames[i])))) == Include()
                $(nested(fieldtype(T, i), T, Expr(:., path, Expr(:quote, fname)), check, val, alt, wrap))
            else
                $(alt(path, fnames[i]))
            end
        )
        push!(expressions, Expr(:..., expr))
    end
    wrap(T, expressions)
end
nested(::Type{T}, P, path, args...) where T <: Tuple = begin
    expressions = Expr(:tuple)
    for i in 1:length(T.types)
        expr = nested(fieldtype(T, i), T, Expr(:ref, path, i), args...)
        push!(expressions.args, Expr(:..., expr))
    end
    expressions
end
nested(::Type{T}, P, path, check, val, args...) where T <: Number = Expr(:tuple, val(T, P, path)) 
nested(::Type{Any}, P, path, check, val, args...) = Expr(:tuple, val(Any, P, path))

end # module
