using Nested
@static if VERSION < v"0.7.0-DEV.2005"
    using Base.Test
else
    using Test
end

flatten_expr(T, path, x) = :(flatten(getfield($path, $(QuoteNode(x))))) 
flatten_inner(T) = nested(T, :t, flatten_expr, down)

flatten(x::Any) = (x,) 
flatten(x::Number) = (x,) 
@generated flatten(t) = flatten_inner(t)

struct Foo{T}
    a::T
    b::T
    c::T
end

struct NestedFoo{T1, T2}
    nf::Foo{T1}
    nb::T2
    nc::T2
end

nestedfoo = NestedFoo(Foo(1,2,3),4,5)
@test flatten(nestedfoo) == (1, 2, 3, 4, 5)
