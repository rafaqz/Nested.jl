using Nested,
      Test

flatten_expr(T, path, x) = :(flatten(getfield($path, $(QuoteNode(x)))))
flatten_inner(T) = nested(T, :t, flatten_expr)

flatten(x::Any) = (x,)
flatten(x::Number) = (x,)
@generated flatten(t) = flatten_inner(t)

struct Foo{T1,T2,T3}
    a::T1
    b::T2
    c::T3
end

struct NestedFoo{T1,T2,T3,T4,T5}
    nf::Foo{T1,T2,T3}
    nb::T4
    nc::T5
end

nestedfoo = NestedFoo(Foo(1,2,3),4,5)
tuplefoo = Foo(6.0, 7.0, (8.0, 9.0, 10.0))
@test flatten(nestedfoo) == (1, 2, 3, 4, 5)
@test flatten((nestedfoo, tuplefoo)) == (1, 2, 3, 4, 5, 6.0, 7.0, 8.0, 9.0, 10.0)
